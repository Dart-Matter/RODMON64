
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


STEP        .block


;---------------------------------------
;
; Core step implementation used primarily by walk and jump commands.
;
; IN:       A = 0 = step into
;               1 = step over
;
Core        .proc


            sta Vr0                     ; Temporarily save into/over request.
            tww a,y,RAM.REGS.pc,RAM.StepPoint1 ; Reference is current PC.
            jsr DASM.Inspect            ; Get info about the instruction.
            ldw a,y,RAM.INSPECT.data    ; Load potential word operand.
            stw a,y,Vr3                 ; Store in a pointer for jmp/jsr tests.

            ; Select the step handler.
            ldx RAM.INSPECT.opcode
            cpx #$4C ; JMP
            beq jd_hop
            cpx #$6C ; JMP (indirect)
            beq ji_hop
            cpx #$60 ; RTS
            beq step_rts
            cpx #$20 ; JSR
            beq step_jsr
            ldx RAM.INSPECT.mode

            ; (am_order_v2)
            cpx #MPU6502.am_aby+1       ; Absolute addressing.
            bcc o3_hop

            cpx #MPU6502.am_zpy+1       ; Zero page addressing.
            bcc o2_hop

            cpx #MPU6502.am_rel+1       ; Branches.
            bcc step_branch

            ; Special case above: JMP (indirect)
            ;
            ; cpx #MPU6502.am_ind+1       ; Plain indirect addressing.
            ; bcc ?

            cpx #MPU6502.am_iny+1       ; Indexed indirect addressing.
            bcc o2_hop

            cpx #MPU6502.am_imp+1       ; Implied addressing.
            bcc o1_hop

            cpx #MPU6502.am_imm+1       ; Immediate addressing.
            bcc o2_hop

            ; Unexpected, internal error.
            .Escape ERROR.Bug

jd_hop jmp step_jdirect
ji_hop jmp step_jindirect
o3_hop jmp over_3
o2_hop jmp over_2
o1_hop jmp over_1

step_rts    ; Break at the location we are about to return to.
            ldx RAM.REGS.sp             ; Get stack state.
            inx                         ; Return address is at sp+1.
            ; Store computed stack pointer for indirect access.
            txa                         ; Transfer stack lo to A.
            ldy #1                      ; Stack hi is always $01.
            stw a,y,Vr3                 ; Store as pointer.
            ; Get the return lo byte.
            ldy #0                      ; Stack offset 0.
            lda (Vr3),y                 ; Read return lo.
            tax                         ; Save lo to x.
            iny                         ; Stack offset 1.
            lda (Vr3),y                 ; Read return hi.
            tay                         ; Transfer hi to Y.
            txa                         ; Transfer lo to A.
            stw a,y,RAM.StepPoint1      ; Set return address as base.
            jmp over_1                  ; Break 1 after return address.

step_branch ; Step is relative to byte after instruction.
            clc                         ; Clear carry for add.
            lda #2                      ; Size of branch instruction.
            adc RAM.StepPoint1.lo       ; Add to instruction address lo.
            sta RAM.StepPoint1.lo       ; Store result lo.
            lda #0                      ; Add carry only to hi.
            adc RAM.StepPoint1.hi       ; Add carry to hi.
            sta RAM.StepPoint1.hi       ; Store result hi.
            ; Break at the branch target too.
            ldx #0                      ; Preload positive hi disp.
            lda RAM.INSPECT.data.lo     ; Get displacement.
            bpl +                       ; Displacement is positive.
            dex                         ; Negative displacement hi = $FF
+           clc                         ; Clear carry for add.
            ; Add base to displacement.
            adc RAM.StepPoint1.lo       ; Add base lo to displacement.
            sta RAM.StepPoint2.lo       ; Store in step point 2 lo.
            txa                         ; Get displacement hi.
            adc RAM.StepPoint1.hi       ; Add base hi to displacement.
            sta RAM.StepPoint2.hi       ; Store in step point 2 hi.
            jmp step_ready              ; Both step points ready.

step_jsr    ldx Vr0                     ; Step into (vs. over)?
            bne over_3                  ; Over, just break after instruction.
            lda RAM.INSPECT.data.hi     ; Get destination page.
            jsr PLATFORM.IsBrkPage      ; Is it breakable?
            bne over_3                  ; Not breakable, force step over.
            ; Intentional fall-thru.
step_jdirect ; Break at the address in the operand.
            ldw a,y,RAM.INSPECT.data    ; Get address from instruction.
at_address  stw a,y,RAM.StepPoint1      ; Store address as step point.
            jmp step_ready              ; Apply step point.

step_jindirect ; Dereference the operand to get the target jmp address.
            ldw a,y,RAM.INSPECT.data    ; Get address from instruction.
            stw a,y,Vr3                 ; Store it in a pointer.
            ldy #0                      ; Index to first indirect byte.
            lda (Vr3),y                 ; Read lo byte.
            tax                         ; Save lo to X.
            iny                         ; Index second indirect byte.
            lda (Vr3),y                 ; Read hi byte.
            tay                         ; Transfer hi to Y.
            txa                         ; Transfer lo to A.
            jmp at_address              ; Set step point at A,Y.

over_1      lda #1                      ; Break at instruction + 1 byte.
            bne over
over_2      lda #2                      ; Break at instruction + 2 bytes.
            bne over
over_3      lda #3                      ; Break at instruction + 3 bytes.
over        ; Add displacement to base.
            clc                         ; Clear carry for lo add.
            adc RAM.StepPoint1.lo       ; Add base lo to displacement.
            sta RAM.StepPoint1.lo       ; Store result lo.
            bcc+                        ; No carry.
            inc RAM.StepPoint1.hi       ; Carry to base hi.
+
step_ready  ; Place step points.

            ; Handle not breakable address.
            lda RAM.StepPoint1.hi       ; Get destination page.
            jsr PLATFORM.IsBrkPage      ; Is it breakable.
            beq step_apply              ; Yes, continue.
            ; Not breakable, give user an option to abort.
            lea a,y,STRINGS.goq
            jsr PRINT.String
            jsr INPUT.Key
            cmp #"r"
            bne +
            jmp step_rts
+           cmp #"g"
            beq step_go
            rts                         ; Abort.

step_apply  ; Filter out step points already set by the user breakpoints.
            ldw a,y,RAM.StepPoint1      ; Get step point 1.
            jsr BREAKPOINTS.FindBreak   ; Is it already set?
            cpx #RAM.StepIndex1         ; User index is less than step points.
            bcs +                       ; Not user breakpoint, set it.
            lda #$ff                    ; Value for clearing.
            sta RAM.StepPoint1.lo       ; Clear step point lo.
            sta RAM.StepPoint1.hi       ; Clear step point hi.
+
            ldw a,y,RAM.StepPoint2      ; Get step point 2.
            jsr BREAKPOINTS.FindBreak   ; Is it already set?
            cpx #RAM.StepIndex1         ; User index is less than step points.
            bcs +                       ; Not user breakpoint, set it.
            lda #$ff                    ; Value for clearing.
            sta RAM.StepPoint2.lo       ; Clear step point lo.
            sta RAM.StepPoint2.hi       ; Clear step point hi.
+
            ; Set the step points.
            sec                         ; Indicate set action.
            jsr BREAKPOINTS.ApplyStep   ; Apply them.

step_go     jmp GO.Handler.Execute      ; Start execution.
            .endproc ; Core


            .endblock ; STEP
