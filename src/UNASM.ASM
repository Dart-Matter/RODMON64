
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


UNASSEMBLE  .block


;---------------------------------------
;
; IMPLEMENTS THE UNASSEMBLE COMMAND.
;
; token ( start ) ( [ L ( count ) ] | end ) )
;

Handler     .proc
            lea a,y,DASM.Formatted      ; Select formatting routine.
            stw a,y,Vr0                 ; Set it for dump routine.
            ldx #16                     ; Number of bytes per line.
            stx Vr2                     ; Set it for dump routine.
            jmp DUMP.CommandCore        ; Parse command line and then dump.
            .endproc ; Handler


;--------------------------------------
;
; jsr UNASSEMBLE.One
;
; Disassemble the instruction pointed to by Arg1 and advance Arg1 by the
; instruction size.
; 
; IN:       Arg1 = Start address.
;
; OUT:      None.
;
; SAFE:     None.
;
;
One         .proc
            ldw a,y,Arg1                ; Get instruction address.
            jsr DASM.Formatted          ; Disassemble it.
            txa                         ; Save instruction size in A for add.
            ldx #Arg1                   ; Select instruction address arg.
            jsr ARGS.Add.B              ; Add size to instruction address.
            tww a,y,Arg1,RAM.Resume     ; Result is also the resume address.
            rts                         ; Done.
            .endproc


            .endblock ; UNASSEMBLE
