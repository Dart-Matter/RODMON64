
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


UNOFFICIAL  .block


;---------------------------------------
;
; IMPLEMENTS THE UNOFFICIAL INSTRUCTIONS ENABLE COMMAND.
;
On          .proc
            lda #+~0                    ; Masking no features off.
            ldx #RAM.FLAG.UNOFFICIAL    ; Turning uno on.
            bne Off.shared              ; Apply setting changes.
            .endproc


;---------------------------------------
;
; IMPLEMENTS THE UNOFFICIAL INSTRUCTIONS DISABLE COMMAND.
;
Off         .proc
            lda #~RAM.FLAG.UNOFFICIAL   ; Masking uno off.
            ldx #0                      ; Turning no features on.
shared      jmp SetFeature              ; Apply setting changes. Done.
            .endproc


            .endblock ; UNOFFICIAL
