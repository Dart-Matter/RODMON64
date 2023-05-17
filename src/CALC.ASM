
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


CALCULATE   .block


;---------------------------------------
;
; IMPLEMENTS THE CALCULATE COMMAND.
;
;   number <equals> number
;
; Shows the sum and difference of two numbers.
;
Handler     .proc

            bcs value_error             ; Error, prefix number missing.
            jsr INPUT.Number            ; Try getting second number.
            bcc calc                    ; With two numbers, do calculation.
            cmp #NEWLINE        ; End of line?
            bne value_error             ; If not, second number was bad.
            jmp CONVERT.Handler         ; Convert first number.

calc        jsr ARGS.Push               ; Allocate Arg0 for result.
            ; Arg2 + Arg1
            clc                         ; Clear carry.
            lda Arg2.lo                 ; Get first number lo.
            adc Arg1.lo                 ; Add second number lo.
            sta Arg0.lo                 ; Store result sum lo.
            lda Arg2.hi                 ; Get first number hi.
            adc Arg1.hi                 ; Add second number hi with carry.
            sta Arg0.hi                 ; Store result sum hi.
            lda #"+"                    ; Specify math operation character.
            jsr result_out              ; Show result.
            ; Arg2 - Arg1
            sec                         ; Clear borrow.
            lda Arg2.lo                 ; Get first number lo.
            sbc Arg1.lo                 ; Subtract second number lo.
            sta Arg0.lo                 ; Store result difference lo.
            lda Arg2.hi                 ; Get second number hi.
            sbc Arg1.hi                 ; Subtract second num hi with borrow.
            sta Arg0.hi                 ; Store result difference hi.
            lda #"-"                    ; Specify math operation character.

result_out  pha                         ; Save math operation character.
            jsr PLATFORM.Newline        ; Cursor to start of next line.
            jsr PRINT.Space             ; Offset from left edge of screen.
            jsr CONVERT.Print           ; Show result in all radices.
            jsr PRINT.Remark            ; Begin comment.
            pla                         ; Get math operation character.
            jmp PRINT.Char              ; Print it. Done.

value_error .Escape ERROR.Value

            .endproc ; Handler


            .endblock ; CALCULATE
