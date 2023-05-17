
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


JUMP        .block


;---------------------------------------
;
; IMPLEMENTS THE JUMP (STEP OVER) COMMAND.
;
;   token ( , start )
;
; Step-over the instruction at the specified address or PC.
;
Handler     .proc
            lda #1                      ; Select "step over".
            jmp WALK.Handler.shared     ; Jump to shared walk/jump code.
            .endproc


            .endblock ; JUMP
