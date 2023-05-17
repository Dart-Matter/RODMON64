
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


CHARDUMP    .block


;---------------------------------------
;
; IMPLEMENTS THE DUMP CHARACTERS COMMAND.
;
;   token ( start ) ( [ L ( count ) ] | end ) )
;
; Dumps the characters residing at a span of memory addresses.  The
; interpretation of the memory contents is control by the current character 
; mode.
;
Handler     .proc
            lea a,y,DUMP.PrettyChars    ; Select formatting routine.
            stw a,y,Vr0                 ; Set it for dump routine.
            ldx #16                     ; Number of bytes per line.
            stx Vr2                     ; Set it for dump routine.
            jmp DUMP.CommandCore        ; Parse command line and then dump.
            .endproc ; Handler



            .endblock ; CHARDUMP
