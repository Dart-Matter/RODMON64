
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


BYTEASM     .block


byte_error  .Escape ERROR.Byte


;--------------------------------------
;
; IMPLEMENTS THE CODE BYTES EDIT COMMAND.
;
;   ( address ) <minus> ( byte ( , byte ( , byte ) ) ) ( instruction )
;
; A combination of memory edit and assemble commands.  Up to 3 bytes of data
; values are read and compared with the memory.  If any bytes differ with
; memory, the memory is changed to match the input as if the memory edit
; command were used.  If all bytes match or the first parameter is not a valid
; number, then the optional instruction is assembled as if the assemble command
; were used.  If the bytes match and there is no instruction then no change is
; made to memory.  After the operation has been carried out successfully,
; the memory is disassembled for visual verification.
;
Handler     .proc

            tww a,y,Arg0,Vr3            ; Save work address.
            lda #0                      ; 0 initializer.
            sta Vr0                     ; 0 mismatch count.
            sta Vr1                     ; 0 memory offset.

            ; Try editing code bytes.
eloop       jsr INPUT.Number            ; Try getting a number.
            sta Tr6                     ; Save delimiter.
            bcs end_bytes               ; Input wasn't a number.
            bne byte_error              ; Number is note a byte.
            ldy Vr1                     ; Get current memory offset.
            lda Arg0.lo                 ; Get input byte.
            sta RAM.INSPECT,y           ; Save to build buffer.
            cmp (Vr3),y                 ; Input matches resident memory byte?
            beq match                   ; Yes.
            inc Vr0                     ; Increment mismatch count.
match       iny                         ; Next memory offset.
            sty Vr1                     ; Save memory offset.
            lda Tr6                     ; Get delimiter.
            cmp #NEWLINE                ; End of line?
            beq end_bytes               ; Yes.
            cpy #3                      ; 3 bytes processed yet?
            bcc eloop                   ; No.

end_bytes   ldy Vr1                     ; Any code bytes processed?
            beq no_bytes                ; No, try assembling.
            lda Vr0                     ; Any mismatches?
            beq try_asm                 ; No, try assembling.
put_bytes   dey                         ; Convert count to count/last offset.
ploop       lda RAM.INSPECT,y           ; Read builder buffer.
            sta (Vr3),y                 ; Poke value.
            dey                         ; Decrement count.  Do more?
            bpl ploop                   ; Yes.
            tww a,a,Vr3,Arg1            ; Copy edit address to unasm arg.
            jsr PLATFORM.Overwrite      ; Cursor to start of line.
            jmp UNASSEMBLE.One          ; Disassemble and return.

no_bytes    ; No byte edit, so try assembling the entire line.
            lda Tr6                     ; Get delimiter.
            .INPUT.Unget a              ; Return it as possible mnemonic char.
try_asm     ; Try assembling the remainder of the line.
            lda Tr6                     ; Get delimter.
            cmp #NEWLINE                ; Was it end of line?
            bne do_asm                  ; No.
            rts                         ; Done.

do_asm      tww a,a,Vr3,Arg0            ; Copy edit address to asm arg.
            jmp ASSEMBLE.Handler.asmArg0 ; Assemble and return.

            .endproc ; Handler


            .endblock ; BYTEASM
