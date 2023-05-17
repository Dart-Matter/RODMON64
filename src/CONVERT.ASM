
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


CONVERT     .block


;---------------------------------------
;
; IMPLEMENTS THE CONVERT COMMAND.
;
;   number <equals>
;
; Displays a number in all radices.
;
Handler     .proc
            jsr PLATFORM.Overwrite
            jsr PRINT.Space
            jmp Print
            .endproc

Print       .proc
            ; Decimal
            lda #'!'
            jsr PRINT.Char
            ldx #Arg0
            jsr PRINT.Decimal.Arg
            jsr PRINT.Space

            ; Hex
            jsr PRINT.Dollar
            ldx #Arg0
            jsr PRINT.Hex.Arg
            jsr PRINT.Space

            ; Binary
            lda #'%'
            jsr PRINT.Char
            ldx #Arg0
            jmp PRINT.Binary.Arg
            .endproc


            .endblock ; CONVERT
