
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


MEMDUMP .block


;---------------------------------------
;
; IMPLEMENTS THE MEMORY DUMP COMMAND.
;
;   token ( start ) ( [ L ( count ) ] | end ) )
;
; Dump the byte values from a span of memory.
; 
Handler     .proc
            jsr MEMDUMP.setup           ; Setup dump type.
            jmp DUMP.CommandCore        ; Parse command line and then dump.
            .endproc

;--------------------------------------
;
; jsr MEMDUMP.Range
;
; Dumps a range or memory addresses.  This is used primarily when the memory
; edit command echos its results back.
; 
; IN:       Arg0 = End address.
;           Arg1 = Start address.
;
; OUT:      None.
;
; SAFE:     None.
;
Range       .proc
            jsr MEMDUMP.setup           ; Setup dump type
            jmp DUMP.RangeCore          ; Do start/end dump directly.
            .endproc

            ;--------------------------
            ; OUT:  Vr0 = Address of formatting routine.
            ;       Vr2 = Bytes per line.
setup       .proc
            lea a,y,DUMP.PrettyBytes    ; Select formatting routine.
            stw a,y,Vr0                 ; Set it for dump routine.
            ldx #8                      ; Number of bytes per line.
            stx Vr2                     ; Set it for dump routine.
            rts                         ; Done.
            .endproc


            .endblock ; MEMDUMP
