
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


MEMEDIT     .block

value_error .Escape ERROR.Value

;---------------------------------------
;
; IMPLEMENTS THE MEMORY EDIT COMMAND.
;
;   ( address ) <colon> byte ( , byte ... )
;
; Change the contents of memory.
;
Handler     .proc

            ldw a,y,Arg0                ; Get start arg.
            stw a,y,Vr2                 ; Stash for dump later.
            stw a,y,Vr3                 ; Working copy.
            ; Read first input value.
            jsr INPUT.Number            ; Input value.
            bcs value_error             ; Neede a valid value.

put_values  pha                         ; Stash delimiter
            php                         ; Stash zero page flag.
            ldy #0                      ; First byte.
            lda Arg0.lo                 ; Get arg lo.
            sta (Vr3),y                 ; Write to memory.
            plp                         ; Was input azero page value?
            beq +                       ; Yes, done with this value.
            iny                         ; Second byte.
            lda Arg0.hi                 ; Get arg hi.
            sta (Vr3),y                 ; Write to memory.
+           iny                         ; Number of bytes written.
            tya                         ; Prepare for addition.
            clc                         ; Clear math carry.
            adc Vr3.lo                  ; Add address lo.
            sta Vr3.lo                  ; Write back to address lo.
            bcc +                       ; No carry.
            inc Vr3.hi                  ; Carry to address hi.
+           pla                         ; Get delimiter
            cmp #NEWLINE        ; End of line?
            beq me_dump                 ; Yes, echo memory.
            jsr INPUT.Number            ; Input another data value.
            bcc put_values              ; Valid number, put it.
            cmp #SPACE                  ; Space after delimiter (double space)?
            bne value_error             ; No, unexpected input.

me_dump     jsr PLATFORM.Overwrite      ; Prepare to overwrite command.
            tww a,a,Vr2,Arg1            ; Set dump start address.
            tww a,a,Vr3,Arg0            ; Set dump end address.
            ldx #Arg0                   ; Select end address.
            jsr ARGS.Decr               ; End is one beyond; decrement it.
            jmp MEMDUMP.Range           ; Dump it.

            .endproc ; Handler


            .endblock ; MEMEDIT
