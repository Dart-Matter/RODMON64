
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


CHARMODE    .block


;---------------------------------------
;
; IMPLEMENTS THE PETSCII MODE SETTING COMMAND.
;
Petscii     .proc
            lda #+~0                    ; Turn off no flags.
            ldx #RAM.FLAG.PETSCII       ; Turn on PETSCII flag.
            bne Pokes.shared            ; Always true; relative jump.
            .endproc


;--------------------------------------
;
; IMPLEMENTS THE POKE CODE SETTING COMMAND.
;
Pokes       .proc
            lda #~RAM.FLAG.PETSCII      ; Turn off PETSCII flag.
            ldx #0                      ; Turn on no flags.
shared      jmp SetFeature              ; Apply to feature flags. Done.
            .endproc


            .endblock ; CHARMODE
