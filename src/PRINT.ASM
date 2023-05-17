
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


;--------------------------------------
;
; Routines for displaying text and values.
;
PRINT       .block


;;-------------------------------------
;;
;; JSR PRINT.Colon
;;
;; Print a colon.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Colon       .proc
            pha
            lda #':'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Semicolon
;;
;; Print a semicolon.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Semicolon   .proc
            pha
            lda #';'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Minus
;;
;; Print a minus.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Minus       .proc
            pha
            lda #'-'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Dollar
;;
;; Print a dollar sign.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Dollar      .proc
            pha
            lda #'$'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Hash
;;
;; Print a hash.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Hash        .proc
            pha
            lda #'#'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.LParen
;;
;; Print a left parenthesis.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
LParen      .proc
            pha
            lda #'('
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.RParen
;;
;; Print a right parenthesis.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
RParen      .proc
            pha
            lda #')'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Comma
;;
;; Print a comma.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Comma       .proc
            pha
            lda #','
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Period
;;
;; Print a period.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Period      .proc
            pha
            lda #'.'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PLATFORM.Newline
;;
;; Move to start of next line.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Newline     .proc
            jmp PLATFORM.Newline
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Space
;;
;; Print a space.
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    None.
;;
Space       .proc
            pha
            lda #32
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Char
;;
;; Just a pseudonym for the kernel CHROUT function.
;;
;; IN:      A = Character to print.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Char        .proc
            pha
Internal
            .locals
            .endlocals
            .FRAME.Alloc
            jsr PLATFORM.CharOut
            .FRAME.Free
            clc
            pla
            rts
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.SpacesY
;;
;; Print multiple spaces.
;;
;; IN:      Y = number of spaces.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    None.
;;
SpacesY

count       = $101

            pha                         ; Allocate 1 byte.
            tsx                         ; X = stack frame base.
            tya                         ; Save count in A.
            sta count,x                 ;  stack variable.
-           lda #32
            jsr Char
            dec count,x
            bne -
            pla                         ; Unwind stack.
            rts


;;-------------------------------------
;;
;; JSR PRINT.Indirect
;;
;; Print the indirect preamble "($".
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Indirect    .proc
            jsr LParen
            jmp Dollar
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.IndexX
;;
;; Print ",X".
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
IndexX      .proc
            pha
            jsr Comma
            lda #'x'
            bne Char.Internal
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.IndexY
;;
;; Print ",Y".
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
IndexY      .proc
            jsr Comma
            lda #'y'
            jmp Char
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Remark
;;
;; Print " ; ".
;;
;; IN:      None.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
Remark      .proc
            jsr Space
            jsr Semicolon
            jmp Space
            .endproc


;;-------------------------------------
;;
;; JSR PRINT.Hex
;;
;; Prints a value in the argument stack as hexadecimal.
;;
;; IN:      X = Arg Wn.
;;
;; OUT:     None.
;;
;; SAFE:    X
;;
Hex         .proc
Arg         lda $00,x
            ldy $01,x


;;-------------------------------------
;;
;; JSR PRINT.Hex.W
;;
;; Prints the value in word A,Y as
;;  hexadecimal.
;;
;; IN:      A = LSB
;;          Y = MSB
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
W           pha                         ; Save lo byte.
            tya                         ; Get hi byte.
            jsr B                       ; Print byte.
            pla                         ; Restore lo byte.


;;-------------------------------------
;;
;; JSR PRINT.Hex.B
;;
;; Prints the value in byte A as hexadecimal.
;;
;; IN:      A = Byte value.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
B           pha                         ; Save byte.
            lsr                         ; Shift hi nybble into
            lsr                         ;  lo nybble position by
            lsr                         ;  shifting to the right
            lsr                         ;  4 times.
            jsr N                       ; Print lo nybble.
            pla                         ; Restore byte.


;;-------------------------------------
;;
;; JSR PRINT.Hex.N
;;
;; Prints the low nybble in byte A as hexadecimal.
;;
;; IN:      A<3:0> = Nybble value.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
N           and #$0F                    ; Isolate low nybble.
            clc                         ; Clear carry for add.
            adc #"0"                    ; Base to "0" character.
            cmp #"9"+1                  ; Decimal digit?
            bcc +                       ; Yes.
            adc #("a"-("9"+1)-1)        ; Base to "A", cancel out the carry.
+           jmp Char                    ; Print it.

            .endproc ; PRINT.Hex


;;-------------------------------------
;;
;; JSR PRINT.Binary
;;
;; Prints a value in the argument stack as binary.
;;
;; IN:      X = Arg Wn.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X
;;
Binary      .proc
Arg         lda $00,x
            ldy $01,x


;;-------------------------------------
;;
;; JSR PRINT.Binary.W
;;
;; Prints the value in word A,Y as binary.
;;
;; IN:      A = LSB
;;          Y = MSB
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
W           pha
            tya
            jsr B
            pla


;;-------------------------------------
;;
;; JSR PRINT.Hex.B
;;
;; Prints the value in byte A as hexadecimal.
;;
;; IN:      A = Byte value.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    X,Y
;;
B           ldx #8
-           asl
            pha
            lda #0
            rol
            jsr PRINT.Hex.N
            pla
            dex
            bne -
            rts

            .endproc ; Binary


;;-------------------------------------
;;
;; JSR PRINT.Decimal
;;
;; Prints a value in the argument stack as decimal.
;;
;; IN:      X = Arg Wn.
;;
;; OUT:     None.
;;
;; SAFE:    None.
;;

Decimal     .proc
Arg         lda $00,x
            ldy $01,x
            clc
            bcc W


;;-------------------------------------
;;
;; JSR PRINT.Decimal.B
;;
;; Prints the value in byte A as
;;  decimal.
;;
;; IN:
;;  A = Byte value.
;;
;; OUT: None.
;;
;; SAFE: None.
;;
B           ldy #0
            ; Fall-thru


;;-------------------------------------
;;
;; JSR PRINT.Decimal.W
;;
;; Prints the value in word A,Y as decimal.
;;
;; IN:      A = LSB
;;          Y = MSB
;;
;; OUT:     None.
;;
;; SAFE:    None.
;;
W
            .locals
acc24       .fill 3 ; 24-bit accumulator
shift       .SWORD ?
            .endlocals

            .FRAME.Alloc                ; Allocate stack frame.

            ; Build BCD representation.
            tsx                         ; Get frame reference.
            ldy #16                     ; Going to shift 16-bits.
            ; Shift bit 15 into carry.
-           asl arg_a,x                 ; Shift lo left.
            rol arg_y,x                 ; Shift CF into hi, bit 15 into CF.
            sei                         ; Disable interrupts while in BCD mode.
            sed                         ; Set BCD mode.
            ; Accunulator = Accumulator x 2 + CF.
            lda acc24 + 0,x
            adc acc24 + 0,x
            sta acc24 + 0,x
            lda acc24 + 1,x
            adc acc24 + 1,x
            sta acc24 + 1,x
            lda acc24 + 2,x
            adc acc24 + 2,x
            sta acc24 + 2,x
            cld                         ; Clear BCD mode.
            cli                         ; Re-enable interrupts.
            dey                         ; Decrement bit count.
            bne -                       ; Repeat until bit count is 0.

            ; At this point, 5 BCD digits have been shifted in from the right
            ; with an undefined sixth digit at the most significant position.
            jsr getmsn                  ; Discard 6th BCD digit.

            ; Printing the decimal number.
            ldy #5                      ; Print 5 digits max.
            ; Skip leading zeros.
-           jsr getmsn                  ; Get next (left) digit.
            bne digout                  ; it has a non-zero value.
            dey                         ; Decrement digit count.
            bne -                       ; Repat while digits remain.
            ; The digits were all zero.
            lda #0                      ; Value is zero.
            iny                         ; Just print one digit.

digout      ; y = Count of remaining digits to print.
            jsr PRINT.Hex.N             ; Print digit.
            jsr getmsn                  ; Get next digit.
            dey                         ; Decrement digit count.
            bne digout                  ; Repeat until reaming digits is 0.

            .FRAME.Free                 ; Deallocate frame.
            clc                         ; Success always.
            rts                         ; Done.

            ; Shift out and return the most significant nybble.
            ;
            ; OUT:  A = Nybble value.
            ;       X = Frame pointer.
            ;
            ; SAFE: X,Y
getmsn      tya                         ; Save Y to stack.
            pha
frame_adj   = 3                         ; Stack save + return address.
            ldy #4                      ; Shift out 4 bits.
            tsx
-           asl acc24 + frame_adj + 0,x
            rol acc24 + frame_adj + 1,x
            rol acc24 + frame_adj + 2,x
            rol                         ; Into A.
            dey                         ; More bits to shift?
            bne -                       ; Yes.
            tax                         ; Protect nybble.
            pla                         ; Recover Y value.
            tay                         ; Copy it to Y.
            txa                         ; Copy nybble back to A.
            and #$0F                    ; Isolate nybble.
            rts                         ; Done.

            .endproc ; Decimal

;;-------------------------------------
;;
;; JSR PRINT.String
;;
;; Prints a null terminated string.
;;
;; IN:      A = String pointer lo byte.
;;          Y = String pointer hi byte.
;;
;; SAFE:    None.
;;
String      .proc
            stw a,y,Vr5                 ; Pointerize string address.
            ldy #0                      ; Begin at character index 0.
-           lda (Vr5),y                 ; Load character; null?
            beq +                       ; Yes, end of string.
            jsr PRINT.Char              ; Print character.
            iny                         ; Next character.
            bne -                       ; Max 256 characters.
+           clc                         ; Success always.
            rts                         ; Done.
            .endproc ; String


            .endblock ; PRINT
