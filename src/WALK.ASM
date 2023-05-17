
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


WALK        .block


syntax_error .Escape ERROR.Syntax

;--------------------------------------
;
; IMPLEMENTS THE WALK (STEP INTO) COMMAND.
;
Handler     .proc

            lda #0                      ; Select "step into" operation.
shared      ; The following code shared with step over command.
            pha                         ; Save step type.
            jsr INPUT.Number            ; User provided start address?
            tay                         ; Save last key.
            pla                         ; Restore step type.
            bcs tailchk                 ; No user start.
            tww x,x,Arg0,RAM.REGS.pc    ; Copy user addres to PC state RAM.
tailchk     ; Not expecting anything else on the command line.
            cpy #NEWLINE        ; End of line?
            bne syntax_error            ; No, unexpected.
go_step     jmp STEP.Core               ; Execute a step.
            .endproc


            .endblock ; WALK
