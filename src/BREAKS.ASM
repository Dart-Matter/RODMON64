
;------------------------------------------------------------------------------
;
; Copyright 1983, 2023 Rodney Rushing
;
;
; This file is part of RODMON64.
;
; RODMON64 is free software: you can redistribute it and/or modify it under the
; terms of the GNU General Public License as published by the Free Software
; Foundation, either version 3 of the License, or (at your option) any later
; version.
;
; RODMON64 is distributed in the hope that it will be useful, but WITHOUT ANY
; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
; A PARTICULAR PURPOSE. See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along with
; RODMON64. If not, see <https://www.gnu.org/licenses/>.
;


BREAKPOINTS .block


value_error .Escape ERROR.Value
syntax_error .Escape ERROR.Syntax
dup_error   .Escape ERROR.Duplicate


;---------------------------------------
;
; IMPLEMENTS THE BREAKPOINTS COMMAND.
;
;   .                   List all breakpoints.
;   ./                  Clear all breakpoints.
;   <num>.<address>     Set user breakpoint <num> (1-..9) at <address>.
;   <num>./             Delete breakpoint <num>.
;
; Handles both dumping and editing user defined breakpoints.
;
; IN:       CF = Applies to all breakpoints.
;
Handler     .proc

            bcc set_clear               ; Breakpoint number has been provided.
            ; There is no breakpoint number.
            jsr INPUT.Key               ; Get another key.
            cmp #NEWLINE        ; End of line?
            bne if_clearall             ; No, maybe it's a clear all.

            ; List all
            jsr PLATFORM.Overwrite      ; Cursor to beginning of line.
            ldx #0                      ; Breakpoint address offset.
            stx Vr0                     ; Save address offset.
list_loop   lda Vr0                     ; Get address offset.
            ; Convert to breakpoint number.
            lsr                         ; Divide by 2.
            clc                         ; Clear carry.
            adc #1                      ; Add one for 1-based number.
            cmp #10                     ; Greater than 9?
            bcc +                       ; No, show it.
            rts                         ; Done.
+           cmp #1                      ; The first breakpoint.
            beq +                       ; Doesn't need a leading newline.
            jsr PLATFORM.Newline        ; Cursor to start of next line.
+           jsr PRINT.Decimal.B         ; Print breakpoint number.
            jsr PRINT.Period            ; Print breakpoint edit token.
            ; Get breakpoint address.
            ldx Vr0                     ; Recover breakpoint address offset.
            lda RAM.BrkPts,x            ; Get breakpoint lo byte.
            inx                         ; Advance breakpoint address offset.
            ldy RAM.BrkPts,x            ; Get breakpoint hi byte.
            inx                         ; Advance breakpoint address offset.
            stx Vr0                     ; Save breakpoint address offset.
            ; Address $FFFF is reserved to mean "unassigned".
            cmp #$FF                    ; Is lo = $FF?
            bne +                       ; No.
            cpy #$FF                    ; Is hi = $FF
            beq next                     ; Yes.
+           jsr PRINT.Hex.W             ; Print breakpoint address.
next        jmp list_loop               ; Dump next breakpoint.

if_clearall cmp #"/"                    ; The "clear" character?
            bne syntax_error            ; If not, it's unexpected.
            jmp ClearAllUser            ; Clear all breakpoints. Done.

set_clear   ; A breakpoint number was specified.
            lda Arg0.hi                 ; Get breakpoint number hi.
            bne value_error             ; Must be zero, error.
            ldx Arg0.lo                 ; Get number.
            ; Convert number to breakpoint address offset.
            dex                         ; Make zero based.
            cpx # 9                     ; Zero based < 9?
            bpl value_error             ; No, bad number.
            txa
            asl                         ; x2 for breakpoint address offset.
            pha                         ; Save it.
            jsr INPUT.Number            ; Input a breakpoint address?
            bcs if_clear                ; No, maybe it's the "clear" character.
            ; Address already set in another breakpoint?
            ldw a,y,Arg0                ; Load input address.
            jsr FindBreak               ; Is it already set on another?
            bne dup_error               ; Yes, error.
            pla                         ; Restore breakpoint address offset.
            tax                         ; X = breakpoint address offset.
            ldw a,y,Arg0                ; Specified breakpoint address.
            jmp set

if_clear    cmp #"/"                    ; The "clear" character?
            bne syntax_error            ; No, unexpected.
            pla                         ; Restore breakpoint address offset.
            tax                         ; X = breakpoint address offset.
            ; Breakpoint "clear" value is $FFFF.
            lda #$FF                    ; Clear address lo = $FF.
            tay                         ; Clear address hi = $FF.
set         sta RAM.BrkPts + 0,x        ; Write address lo byte.
            tya                         ; Get address hi byte.
            sta RAM.BrkPts + 1,x        ; Write address hi byte.
            rts                         ; Done.

            .endproc ; Handler


;---------------------------------------
;
; DETERMINES IF A USER BREAKPOINT EXISTS WITH SPECIFIED ADDRESS.
;
; IN:       A = Lo byte of address.
;           Y = Hi byte of address.
;
; OUT:      X = Number if found.
;           ZF = not found
;
; SAFE:     A,Y
;
FindBreak   .proc
            sta Tr6                     ; Save address lo.
            ldx #(RAM.BrkLen + 2) * 2   ; Start at end of breakpoint list.
loop        lda Tr6                     ; Restore address lo.
            cmp RAM.BrkPts-2,x          ; Compare lo to current breakpoint lo.
            bne next                    ; Not equal, skip this breakpoint.
            tya                         ; Get address hi.
            cmp RAM.BrkPts-1,x          ; Compare hi to current breakpoint hi.
            beq found                   ; Equal, found.
next        dex                         ; Decrement breakpoint offset
            dex                         ;  by 2.
            bne loop                    ; Loop until offset is 0.
exit        lda Tr6                     ; Restore address lo.
            cpx #0                      ; Set ZF=not found.
            rts                         ; Done.

found       txa                         ; Convert breakpoint offset
            lsr                         ;  to index
            tax                         ;  in X.
            bne exit                    ; Always true.
            .endproc


;---------------------------------------
;
; APPLY/UNDO USER BREAKPOINTS
;
; Applies the user breakpoints.
;
; IN:       CF = 1 to set
;              = 0 to unset
;
ApplyAllUser .proc
            ;
            ; A tracking byte is used as follows:
            ;
            ;   ,---,-----------------.
            ;   |act|   use count     |
            ;   `---`-----------------'
            ;
            ; act = Set/unset action.
            ; use count = Count of applied breakpoints.
            ;
            lda #0                      ; Use count = 0.
            ror                         ; NF = set/unset.
            sta Vr0                     ; Save tracking.
            ldx #9 - 1                  ; Index in descending order.
            stx Vr1                     ; Save breakpoint index.
loop        ldx Vr1                     ; Load breakpoint index.
            lda Vr0                     ; Load tracking.
            asl                         ; CF = set/unset.
            jsr BREAKPOINTS.ApplyOne    ; Apply the breakpoint.
            bcs +                       ; Not applied.
            inc Vr0                     ; Increment use count.
+           dec Vr1                     ; Decrement index.
            bpl loop                    ; Loop until index goes negative.
            lda #~RAM.FLAG.BRKUSER      ; Default is breakpoints disabled.
            and RAM.BrkFlags            ; Mask off.
            asl Vr0                     ; Shift action into CF, count = x2.
            bcc +                       ; Unset if carry is clear.
            beq +                       ; If use count is 0, leave disabled.
            ora #RAM.FLAG.BRKUSER       ; Breakpoints enabled.
+           sta RAM.BrkFlags            ; Write to breakpoint flags.
            rts                         ; Done.
            .endproc


;---------------------------------------
;
; APPLY/UNDO STEP BREAKPOINTS
;
; These are handled special because they must not apply on top of user
; breakpoints, and must set the step flag for the break handler to use.
;
; IN:       CF = 1 set
;              = 0 unset
;
ApplyStep .proc
            ;
            ; A tracking byte is used as follows:
            ;
            ;   ,---,-----------------.
            ;   |act|   use count     |
            ;   `---`-----------------'
            ;
            ; act = Set/unset action.
            ; use count = Count of applied step points.
            ;
            lda #0                      ; Use count = 0.
            ror                         ; NF = set/unset.
            sta Vr0                     ; Save tracking.

            ; Set first step breakpoint.
            asl                         ; CF = set/unset
            ldx #RAM.StepIndex1         ; First step point index.
            jsr BREAKPOINTS.ApplyOne    ; Apply the step point.
            bcs +                       ; Was not set.
            inc Vr0                     ; Increment use count.
+
            ; Set second step breakpoint.
            lda Vr0                     ; Get tracking for action bit.
            asl                         ; CF = set/unset
            ldx #RAM.StepIndex2         ; Second step point index.
            jsr BREAKPOINTS.ApplyOne    ; Apply the step point.
            bcs +                       ; Was not set.
            inc Vr0                     ; Increment use count.
+
            lda #~RAM.FLAG.BRKSTEP      ; Default is step points disabled.
            and RAM.BrkFlags            ; Mask steps off.
            asl Vr0                     ; Shift action into CF, count = x2.
            bcc +                       ; Unset if carry is clear.
            beq +                       ; Neither step point is used.
            ora #RAM.FLAG.BRKSTEP       ; Step points enabled.
+           sta RAM.BrkFlags            ; Write to breakpoint flags.
            rts                         ; Done.
            .endproc


;---------------------------------------
;
; SET OR UNDO A BREAKPOINT
;
; IN:       X = Breakpoint index
;           CF = set, else unset
;
; OUT:      CF = 0 = success, 1 = not handled.
;
ApplyOne .proc
            php                         ; Save CF, set/unset.
            txa                         ; Copy index to A.
            pha                         ; Save breakpoint index.
            asl                         ; Convert index to word offset.
            tax                         ; Copy offset to index register.
            lda RAM.BrkPts+1,x          ; Load breakpoint hi.
            tay                         ; Copy hi to Y.
            lda RAM.BrkPts,x            ; Load breapoint lo.
            ; Ignore if point = $FFFF.
            cmp #$ff                    ; lo = $FF?
            bne apply                   ; No, apply breakpoint.
            cpy #$ff                    ; hi = $FF?
            bne apply                   ; No, apply breakpoint.
            pla                         ; Discard breakpoint index.
            pla                         ; Discard action arg.
            sec                         ; CF = not handled.
            rts                         ; Done.
apply
            stw a,y,Vr3                 ; Store as pointer.
            ldy #0                      ; Y = 0 index & BRK opcode.
            pla                         ; Restore breakpoint index.
            tax                         ; Copy to index register.
            lda RAM.BrkSav,x            ; Preload original opcode.
            plp                         ; Restore CF set/unset flag.
            bcc put_opcode              ; Do unset.
            lda (Vr3),y                 ; Read opcode from execution memory.
            sta RAM.BrkSav,x            ; Save it.
            ; If this is the same address as PC, don't place the breakpoint
            ; otherwise it will immediately breakpoint without executing the
            ; original instruction.
            ldx RAM.REGS.pc.lo          ; Get PC lo.
            cpx Vr3 + 0                 ; Matches breakpoint?
            bne put_brk                 ; No, place breakpoint.
            ldx RAM.REGS.pc.hi          ; Get PC hi.
            cpx Vr3 + 1                 ; Matches breakpoint?
            beq skip_brk                ; Both match, skip this breakpoint.
put_brk     tya                         ; Y is 0, A = Y = 0 = BRK opcode.
put_opcode  sta (Vr3),y                 ; Place opcode in execution memory.
skip_brk    clc                         ; CF = success.
            rts                         ; Done.
            .endproc


;---------------------------------------
;
; CLEAR ALL USER BREAKPOINTS
;
ClearAllUser .proc
            ldx #0                      ; Start with breakpoint mem offset 0.
            ldy #RAM.BrkLen             ; Breakpoint loop counter.
            lda #$FF                    ; Fill value.
bpcu_loop   sta RAM.BrkPts,x            ; Write breakpoint lo.
            inx                         ; Advance memory offset.
            sta RAM.BrkPts,x            ; Write breakpoint hi.
            inx                         ; Advance memory offset.
            dey                         ; Decrement counter.  Done?
            bne bpcu_loop               ; No, do next one.
            rts                         ; Done.
            .endproc


;---------------------------------------
;
; CLEAR STEP BREAKPOINTS
;
ClearStep   .proc
            lda #$ff                    ; Fill value.
            sta RAM.StepPoint1.lo       ; Store step point 1 lo.
            sta RAM.StepPoint1.hi       ; Store step point 1 hi.
            sta RAM.StepPoint2.lo       ; Store step point 2 lo.
            sta RAM.StepPoint2.hi       ; Store step point 2 hi.
            rts                         ; Done.
            .endproc


            .endblock ; BREAKPOINTS


;---------------------------------------
;
; ADD THE BREAKPOINT HANDLER
;
HookBrk     .proc
            sei
            lea a,y,BrkHandler          ; Copy breakpoint handler address.
            stw a,y,RAM.MonBrk
            cli
            rts
            .endproc


;---------------------------------------
;
; REMOVE THE BREAKPOINT HANDLER
;
UnhookBrk   .proc
            sei
            lea a,y,EscapeHandler       ; Copy breakpoint handler address.
            stw a,y,RAM.MonBrk
            cli
            rts
            .endproc


;---------------------------------------
;
; HANDLE BREAK INTERRUPTS DURING EXECUTION
;
;
BrkHandler  .proc
            ; Save CPU state.
            pla                         ; Pull Y saved by kernel.
            sta RAM.REGS.y              ; Save it to our state.
            pla                         ; Pull X saved by kernel.
            sta RAM.REGS.x              ; Save it to our state.
            pla                         ; Pull A saved by kernel.
            sta RAM.REGS.a              ; Save it to monitor state.
            ; Determine stack pointer at BRK.
            tsx                         ; Get current stack pointer.
            inx                         ; Back up over status.
            inx                         ; Backup over return address lo.
            inx                         ; Backup over return address hi.
            stx RAM.REGS.sp             ; Save to monitor state.
            pla                         ; Get CPU flags saved by kernel.
            sta RAM.REGS.flags          ; Save it to monitor state.
            ; Get the BRK instruction address.
            pla                         ; Get interrupt return lo.
            sec                         ; Clear borrow.
            sbc #2                      ; Backup to the BRK instruction.
            sta RAM.REGS.pc.lo          ; Save it to monitor state.
            pla                         ; Get interrupt return hi.
            sbc #0                      ; Borrow if applicable.
            sta RAM.REGS.pc.hi          ; Save it to monitor state.

            cld                         ; Ensure BCD is off.
            jsr UnhookBrk               ; Remove handler and enable interrupts.
            jsr PLATFORM.BackupZp       ; Protect data in pointer region.

            ; Determine BRK type and request platform visual indicator.
            ldw a,y,RAM.REGS.pc         ; Get monitor state PC.
            jsr BREAKPOINTS.FindBreak   ; Search for matching breakpoint.
            txa
            ldx #BRK_CODE               ; Preload "code" BRK.
            cmp #0                      ; Breakpoint or step point found?
            beq visualize               ; No, visualize.
            ldx #BRK_USER               ; Preload "breakpoint" color.
            cmp #RAM.BrkLen             ; User breakpoint?
            bcc visualize               ; Yes, visualize.
            ldx #BRK_STEP
visualize   jsr PLATFORM.VisualizeBrk   ; Indicate BRK type to user.

            ; If user breakpoints unset them.
            bit RAM.BrkFlags            ; Test breakpoints bit 7.
            bpl +                       ; Not set.
            clc                         ; Action is unset.
            jsr BREAKPOINTS.ApplyAllUser
+
            ; If step points unset them.
            bit RAM.BrkFlags            ; Test step points bit 6.
            bvc +                       ; Not set.
            clc                         ; Action is unset.
            jsr BREAKPOINTS.ApplyStep
            ; Clear step points.
            jsr BREAKPOINTS.ClearStep
+
            ; Display monitor state as if "registers" command.
            jsr PLATFORM.TerminalReset
            jsr REGISTERS.Handler
            clc                         ; Restart with no banner.
            jmp COMMANDS.Restart        ; Begin command input.

            .endproc ; BrkHandler

