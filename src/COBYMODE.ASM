
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


CODEBYTES   .block


;---------------------------------------
;
; IMPLEMENTS THE CODE BYTES ON COMMAND.
;
On          .proc
            lda #+~0                    ; Turn off no flags.
            ldx #RAM.FLAG.CODEBYTES     ; Turn on code bytes flag.
            bne Off.shared              ; Always true; relative jump.
            .endproc


;---------------------------------------
;
; IMPLEMENTS THE CODE BYTES OFF COMMAND.
;
Off         .proc
            lda #~RAM.FLAG.CODEBYTES    ; Turn off code bytes flag.
            ldx #0                      ; Turn on no flags.
shared      jmp SetFeature              ; Apply to feature flags.  Done.
            .endproc


            .endblock ; CODEBYTES
