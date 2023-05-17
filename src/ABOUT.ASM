
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


ABOUT       .block


;--------------------------------------
;
; IMPLEMENTS THE ABOUT COMMAND.
;
Handler     .proc

            ; Copyright.
            jsr PLATFORM.Overwrite
            lea a,y,STRINGS.about
            jsr PRINT.String

            ; Code range.
            lea a,y,STRINGS.coderng
            jsr PRINT.String
            lea a,y,CODE_BASE
            jsr PRINT.Hex.W
            jsr PRINT.Minus
            lea a,y,CODE_END
            jsr PRINT.Hex.W
            jsr PRINT.Space
            jsr PRINT.LParen
            lda #"!"
            jsr PRINT.Char
            lea a,y,CODE_SIZE
            jsr PRINT.Decimal.W
            jsr PRINT.RParen
            
            ; Data range.
            lea a,y,STRINGS.datarng
            jsr PRINT.String
            lea a,y,DATA_BASE
            jsr PRINT.Hex.W
            jsr PRINT.Minus
            lea a,y,DATA_END
            jsr PRINT.Hex.W
            jsr PRINT.Space
            jsr PRINT.LParen
            lda #"!"
            jsr PRINT.Char
            lea a,y,DATA_SIZE
            jsr PRINT.Decimal.W
            jsr PRINT.RParen

            ; RAM range.
            lea a,y,STRINGS.ramrng
            jsr PRINT.String
            lea a,y,BSS_BASE
            jsr PRINT.Hex.W
            jsr PRINT.Minus
            lea a,y,BSS_END
            jsr PRINT.Hex.W
            jsr PRINT.Space
            jsr PRINT.LParen
            lda #"!"
            jsr PRINT.Char
            lea a,y,BSS_SIZE
            jsr PRINT.Decimal.W
            jsr PRINT.RParen

            ; Character mode.
            lea a,y,STRINGS.charmode
            jsr PRINT.String
            jsr PLATFORM.LoadPriEncName
            lda #RAM.FLAG.PETSCII
            bit RAM.Features
            bne +
            jsr PLATFORM.LoadAltEncName
+           txa
            jsr PRINT.String

            ; Unofficial mode.
            lea a,y,STRINGS.unomode
            jsr PRINT.String
            lea x,y,STRINGS.on
            lda #RAM.FLAG.UNOFFICIAL
            bit RAM.Features
            bne +
            lea x,y,STRINGS.off
+           txa
            jsr PRINT.String

            ; Code byte mode.
            lea a,y,STRINGS.bytemode
            jsr PRINT.String
            lea x,y,STRINGS.on
            lda #RAM.FLAG.CODEBYTES
            bit RAM.Features
            bne +
            lea x,y,STRINGS.off
+           txa
            jmp PRINT.String
            .endproc                    ; Handler

            
            .endblock                   ; ABOUT
