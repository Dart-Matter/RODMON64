
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


REGEDIT     .block


;---------------------------------------
;
; IMPLEMENTS THE REGISTER EDIT COMMAND.
;
;   token pc , irq , acc , x , y , sp , flags
;
; Edits the register state that is used when executing machine language.
;
Handler     .proc

            .locals
regs        .RAM.REGS_S
regsize     = * - regs
counter     .byte ?
            .endlocals

            bcc syntax_error            ; Must not have a prefix number.
            .FRAME.Alloc                ; Allocate stack variables.
            ; Initialize shadow copy of state.
            tsx                         ; Get frame reference.
            ldy #0                      ; Zero the load index.
-           lda RAM.REGS,y              ; Load a byte.
            sta regs,x                  ; Copy the byte.
            inx                         ; Increment frame reference.
            iny                         ; Increment load index.
            cpy #regsize                ; Copied all register data?
            bne -                       ; No, keep going.

            ; Input PC.
            jsr reg_input               ; Input value.
            tsx                         ; Get frame reference.
            sta pc.lo,x                 ; Store lo in shadow.
            tya                         ; Copy hi to A.
            sta pc.hi,x                 ; Store hi in shadow.
            bvs write                   ; Commit if end of line.

            ; Input IRQ.
            jsr reg_input               ; Input value and ignore it.
            bvs write                   ; Commit if end of line.

            ; Input A, X, Y.
            lda #3                      ; Loop 3 times, once per register.
            sta Vr0                     ; Save counter.
            tsx                         ; Get frame reference.
-           stx Vr1                     ; Save current frame reference.
            jsr reg_input               ; Input a value.
            bne byte_error              ; Expected a byte sized value.
            ldx Vr1                     ; Restore frame reference.
            sta a,x                     ; Store value in shadow.
            bvs write                   ; Commit if end of line.
            inx                         ; Increment frame reference.
            dec Vr0                     ; Decrement counter.
            bne -                       ; Repeat until counter is 0.

            ; Input stack pointer.
            jsr reg_input               ; Input value.
            dey                         ; Hi must be $01.
            bne range_error             ; Value was not $01.
            tsx                         ; Get frame reference.
            sta sp,x                    ; Store value in shadow.
            bvs write                   ; Commit if end of line.

            ; Input status flags.
            ldy #INPUT.BaseN.Radix2     ; Select binary input.
            jsr INPUT.BaseN             ; Input value.
            bcs value_error             ; Input was not valid binary.
            cmp #NEWLINE        ; End of line?
            bne syntax_error            ; No. Expected end of line.
            cpx #8                      ; Was number 8 digits long?
            bne syntax_error            ; No. Need exactly 8 digits.
            tsx                         ; Get frame reference.
            lda Arg0.lo                 ; Get value.
            sta flags,x                 ; Store value in shadow.

write       ; Done with input.  Copy shadow/results to state RAM.
            tsx                         ; Get frame reference.
            ldy #0                      ; Zero the write index.
-           lda regs,x                  ; Load shadow byte.
            sta RAM.REGS,y              ; Write to state byte.
            inx                         ; Increment frame reference.
            iny                         ; Increment write index.
            cpy #regsize                ; Copied all register data?
            bne -                       ; No, keep going.
            jsr PLATFORM.Overwrite            ; Cursor to beginning of line.
            .FRAME.Free                 ; Deallocate frame.
            jmp REGISTERS.Handler.Format ; Echo the state RAM.

value_error .Escape ERROR.Value
range_error .Escape ERROR.Range
syntax_error .Escape ERROR.Syntax
byte_error  .Escape ERROR.Byte

            ; Input a number, escape on error.
            ;
            ; OUT:  A,Y = Value.
            ;       VF =  End of line.
reg_input   jsr INPUT.Number            ; Input a number.
            bcs value_error             ; Value must be valid.
            clv                         ; Preload VF = not end of line.
            cmp #NEWLINE        ; End of line?
            bne +                       ; No.
            bit reg_done                ; Yes, set overflow flag.
+           ldw a,y,Arg0                ; Load input value for return.
reg_done    rts ; Opcode & VF bit.

            .endproc ; Handler


            .endblock ; REGEDIT
