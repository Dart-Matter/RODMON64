
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


GO          .block


value_error .Escape ERROR.Value
syntax_error .Escape ERROR.Syntax


;--------------------------------------
;
; IMPLEMENTS THE GO COMMAND.
;
;   token , ( start ) ( <comma> break-address )
;
; Executes machine language at specified address or PC with optional
; temporary breakpoint.
;
Handler     .proc

            jsr INPUT.Number            ; Start address specified?
            bcs +                       ; No.
            tww x,x,Arg0,RAM.REGS.pc    ; Store address in PC state.
+           cmp #NEWLINE                ; End of line?
            beq Execute                 ; Yes, go execute now.
            jsr INPUT.Number            ; Break address specified?
            bcs value_error             ; No, unexpected input.
            cmp #NEWLINE                ; End of line?
            bne syntax_error            ; No, unexpected input.
            tww x,x,Arg0,RAM.StepPoint1 ; Set temporary step point.
            tww x,x,Arg1,Arg0           ; Move start address back to Arg 0.
            sec                         ; Specify step point enable.
            jsr BREAKPOINTS.ApplyStep   ; Apply step points.

Execute     sec                         ; Specify breakpoints enable.
            jsr BREAKPOINTS.ApplyAllUser ; Apply breakpoints.
            jsr PLATFORM.RestoreZp      ; Restore zero page pointers.
            jsr HookBrk                 ; Enable break handler.
            ; Load registers from state.
            ldx RAM.REGS.sp             ; Get stack pointer.
            txs                         ; Set it.
            lda RAM.REGS.flags          ; Get status flags.
            pha                         ; Stage status flags.
            lda RAM.REGS.a              ; Set A.
            ldx RAM.REGS.x              ; Set X.
            ldy RAM.REGS.y              ; Set Y.
            plp                         ; Load status
            jmp (RAM.REGS.pc)           ; Jump to start address.
            .endproc


            .endblock ; GO
