
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
; INPUT LIBRARY
;
; The INPUT class contains routines for receiving information from the user
; including keys and formatted numbers.
;
INPUT       .block


;--------------------------------------
;
; JSR AscToInt
;
; Converts a character in the hex digit set to an integer value.
;
;  IN:      A = ASCII digit to convert.
;
;  OUT:     A = Int3eger on success, or original character on error.
;           CF = Not a digit.
;
;  SAFE:    X, Y
;
AscToInt    .proc
            cmp #"a"                    ; "A" or greater?
            bcc trydeci                 ; No, maybe decimal digit.
            cmp #"g"                    ; Greater than "F"?
            bcs +                       ; Yes, invalid digit.
            ; Translate "A".."F" to 10..15.
            sbc #"a"-11                 ; Subtract "A", add 11 (10 + borrow).
            clc                         ; Success.
+           rts                         ; Done.
trydeci     ; Maybe it's a decimal digit.
            eor #"0"                    ; "0".."9" => 0..9
            cmp #10                     ; Out of range?
            bcc done                    ; No, done.
            eor #"0"                    ; Yes, return original.
done        rts
            .endproc


;;-------------------------------------
;;
;; JSR INPUT.Key
;;
;; Reads a single character from the console.
;;
;; IN:      n/a
;;
;; OUT:     A = Character.
;;          ZF = A is newline.
;;
;; SAFE:    X.
;;
Key         .proc
            lda RAM.CharBuf             ; Is there a buffered key?
            bne +                       ; Yes, use the buffered key.
            jsr PLATFORM.CharIn         ; Get new key.
+           pha
            lda #0
            sta RAM.CharBuf
            pla
            cmp #NEWLINE        ; ZF = end of line.
            clc                         ; Success.
            rts                         ; Done.
            .endproc


;;-------------------------------------
;;
;; .INPUT.Unget <reg> (inlined)
;;
;; Puts a key at the head of key input.
;;
;; IN:      reg = register containing key.
;;
;; SAFE:    A,X,Y
;;
Unget       .macro reg
            st@1 RAM.CharBuf
            clc                         ; Success.
            .endm


;;-------------------------------------
;;
;; JSR INPUT.BaseN
;;
;; Reads a maximum 16-bit integer plus terminating character from the console.
;;
;; IN:      Y = radix
;;
;; OUT:     A = Next character
;;          X = Number of digits entered.
;;          Arg0 = 16-Bit integer value
;;          CF = Invalid number
;;          VF = Too large
;;          ZF = Zero page (hex)
;;          NF = Was negated
;;
;; SAFE:    None
;;

BaseN       .proc

            .locals
result      .SWORD ?                    ; For building result.
radix       .byte ?                     ; Numeric base.
            .endlocals

    ; Radix argument values.

Radix2      = %00000001
Radix10     = %00000010
Radix16     = %00000100

            .FRAME.Alloc                ; Allocate stack frame.
            tsx                         ; Get frame reference.
            tya                         ; Copy radix to A.
            sta radix,x                 ; Save radix to local variable.
            lda #0                      ; Load zero initializer.
            sta result.lo,x             ; Clear result lo.
            sta result.hi,x             ; Clear result hi.
            sta arg_x,x                 ; Clear position/return size.
            lda arg_st,x                ; Get input status flags.
            and #~(MPU6502.VF|MPU6502.NF|MPU6502.CF) ; Clear some result flags.
            ora #MPU6502.ZF             ; Assume zero page result.
            sta arg_st,x                ; Store result.
            ; Check for signed input.
            jsr Key                     ; Get a chracter.
            tsx                         ; Get frame erference.
            ldy #MPU6502.NF             ; Preload negate flag.
            cmp #"-"                    ; Got "negative" character.
            beq +                       ; Yes, and CF=1 will indicate key used.
            ldy #0                      ; Surely not negated.
            cmp #"+"                    ; Got "positive" character?
            beq +                       ; Yes, and CF=1 will indicate key used.
            clc                         ; Clear CF = key not used.
+           sta arg_a,x                 ; Stash key.
            tya                         ; Copy negate flag to A.
            ora arg_st,x                ; Combine with current result flags.
            sta arg_st,x                ; Write to result.
            lda arg_a,x                 ; Restore key.
            bcs +                       ; Don't put the key back if used.
            .INPUT.Unget a              ; Put the key back.
+
nextkey
            inc arg_x,x                 ; Next place.
            jsr Key                     ; Read key.
            tsx                         ; Get frame reference.
            sta arg_a,x                 ; Save key.
            tay                         ; Hold key in Y.
            lda radix,x                 ; Get radix.

trybin      lsr                         ; Base-2 input requested?
            bcc trydec                  ; No, try a different radix.
            tya                         ; Copy key to working register.
            eor #"0"                    ; Convert to integer.
            cmp #2                      ; Valid binary digit?
            bcs delimit                 ; No, end of number.
            lsr                         ; Copy digit value to CF.
            rol result.lo,x             ; Shift into lo bit of result.
            rol result.hi,x             ; Shift lo carry into hi result.
            php                         ; CF=overflow, save it.
            lda arg_x,x                 ; Get digit count.
            cmp #9                      ; 9 or more digits?
            bcc +                       ; No, zeropage is possible.
binnotzp    lda #~MPU6502.ZF            ; Mask to clear zeropage flag.
            and arg_st,x                ; Clear bit in result flags.
            sta arg_st,x                ; Copy back to result flags.
+           plp                         ; Restore CF=overflow.
            bcc nextkey                 ; No overflow, do more.
            jmp oflow                   ; Overflow error.

trydec      lsr                         ; Base-10 input requested?
            bcc tryhex                  ; No, try a different radix.
            tya                         ; Copy key to working register.
            jsr AscToInt                ; Convert to integer.
            bcs delimit                 ; Invalid hex digit.
            cmp #10                     ; Valid decimal?
            bpl delimit                 ; No.
            sta arg_a,x                 ; Save value in used key.
            lda result.hi,x             ; Get current result value hi.
            tay                         ; Copy hi to Y.
            lda result.lo,x             ; Get current result value lo.
            jsr Mul10                   ; Value x10; insert new place value.
            tsx                         ; Get frame reference.
            sta result.lo,x             ; Store in result lo.
            tya                         ; Copy Y to A.
            sta result.hi,x             ; Store in result hi.
            lda arg_a,x                 ; Preload last digit value.
            bcs oflow                   ; Product too big.
            ; Add to result.  Carry is already clear.
            adc result.lo,x             ; Add to result lo.
            sta result.lo,x             ; Store in result.
            bcc +                       ; No carry resulted.
            inc result.hi,x             ; Add carry to hi result.
            beq oflow                   ; Zero hi indicates overflow.
+           ; Detect non-zeropage input.
            lda arg_x,x                 ; Get digit count.
            cmp #4                      ; 4 or more digits?
            bcs decnotzp                ; Yes, not zero page (by convention).
            lda result.hi,x             ; Hi is zero?
            beq +                       ; Yes, zero page still possible.
decnotzp    lda #~MPU6502.ZF            ; Mask to clear zeropage result flag.
            and arg_st,x                ; Clear zero page flag.
            sta arg_st,x                ; Copy back to result flags.
+           jmp nextkey                 ; Do more digits.

delimit     tsx                         ; Get frame reference.
            dec arg_x,x                 ; Were there some digits?
            beq error                   ; No.  Need digits to make a number.
            ; Put result on arg stack.
            lda result.hi,x             ; Load result hi.
            tay                         ; Copy to Y.
            lda result.lo,x             ; Load result lo.
            jsr ARGS.Push               ; Put on arg stack.
            ; Negate result if requested.
            lda arg_st,x                ; Negate flag set?
            bpl +                       ; No, result is ready.
            sec                         ; Clear borrow.
            lda #0                      ; Subtract result lo from zero.
            sbc Arg0.lo                 ; Subtract result.
            sta Arg0.lo                 ; Store back in result lo.
            lda #0                      ; Subtract result hi from zero.
            sbc Arg0.hi                 ; Subtract result with borrow.
            sta Arg0.hi                 ; Store back in result hi.
+           jmp unwind                  ; Number complete.

tryhex      lsr                         ; Base-16 input requested?
            bcc error                   ; No, unknown radix.
            tya                         ; Copy key to working register.
            jsr AscToInt                ; Convert to integer.
            bcs delimit                 ; Invalid digit.
            ldy #4                      ; Shift 0 in least significant nybble.
-           asl result.lo,x             ; Shift 0 into result lo.
            rol result.hi,x             ; Shift lo carry into result hi.
            bcs oflow                   ; Carry here indicates hex overflow.
            dey                         ; Decerement bit count.
            bne -                       ; Repeat 4 times.
            ; Set low place value.
            ora result.lo,x             ; Combine with result lo.
            sta result.lo,x             ; Store back in result lo.
            lda arg_x,x                 ; Get digit count.
            cmp #3                      ; 3 or more digits?
            bcc +                       ; No, zero page still possible.
hexnotzp    lda #~MPU6502.ZF            ; Mask to clear zero page flag.
            and arg_st,x                ; Clear zero page flag.
            sta arg_st,x                ; Store back in result flags.
+           jmp nextkey                 ; Do another digit.

oflow       lda #MPU6502.VF             ; Prepare to set overflow.
            ora arg_st,x                ; Combine with result flags.
            sta arg_st,x                ; Store back in result flags.
error       lda #MPU6502.CF             ; Prepare to set carry.
            ora arg_st,x                ; Combine with result flags.
            sta arg_st,x                ; Store back in result flags.
unwind      .FRAME.Free                 ; Load results and free stack frame.
            rts                         ; Done.
            .endproc


;;-------------------------------------
;;
;; JSR INPUT.Char
;;
;; Reads a single character plus one additional character from the console.
;; The character value interpretation is based on the current character mode.
;;
;; IN:      None.
;;
;; OUT:     A = Next character
;;          Arg0 = character value
;;          ZF = 1 (zero page)
;;          CF = 1 (success)
;;
;; SAFE:    None
;;
Char        .proc

            jsr INPUT.Key               ; Get a key.
            cmp #NEWLINE        ; End of line?
            bne translate               ; No, translate it.
error       sec                         ; Error flag.
            rts                         ; Done.

translate   tay                         ; Save key.
            lda RAM.Features            ; Get feature flags.
            and #RAM.FLAG.PETSCII       ; In PETSCII mode?
            beq use_pokes               ; No, use poke code translation.

use_petscii tya                         ; Get saved key.  Already PETSCII.
return      ldy #0                      ; Zero extend 16-bit arg.
            jsr ARGS.Push               ; Push result arg.
            jsr INPUT.Key               ; Get next key.
            ldy #0                      ; Zero extend 16-bit return value.
            clc                         ; Success.
            rts                         ; Done.

use_pokes
            ;
            ; PETSCII	Delta   Poke
            ; ----------------------
            ; 0-31		        n/a (control codes)
            ; 32-63		0       32-63
            ; 64-95		-64     0-31
            ; 96-128	-32     64-96
            ; 129-160           n/a (control codes)
            ; 161-191   -64     97-127
            tya
            cmp #32
            bcc error
            cmp #64
            bcc sub0
            cmp #96
            bcc sub64
            cmp #129
            bcc sub32
            cmp #161
            bcc error
            cmp #192
            bcs error
sub64       sec
            sbc #32
sub32       sec
            sbc #32
sub0        jmp return

            .endproc ; Char


;;-------------------------------------
;;
;; JSR INPUT.Number
;;
;; Reads any signed radix integer plus one additional character from the
;; console.  Sign is "+" or "-".
;;
;; Radix prefixes are:
;;
;;       $ hex
;;       % binary
;;       ! decimal
;;
;; Note: As long as the input starts with a valid number, this routine will
;; succeed.  For example, !12F would result in a valid  decimal number followed
;; by "F" as the next character.
;;
;; IN:      None.
;;
;; OUT:     A = Next character
;;          Arg0 = 16-Bit integer value
;;          CF = Invalid number format
;;          ZF = Is zero page
;;
;; SAFE:    None
;;
Number      .proc
            jsr Key                     ; Get key.
            ; Fall thru.


;;-------------------------------------
;;
;; JSR INPUT.Number.Started
;;
;; Input number with first key preloaded in accumulator.
;;
;; IN:      A = first character.
;;
;; OUT:     A = Next character
;;          Arg0 = 16-Bit integer value
;;          CF = Invalid number format
;;          ZF = Is zero page
;;
;; SAFE:    Same as INPUT.Number.
;;
Started     cmp #"'"                    ; Character prefix?
            beq INPUT.Char              ; Yes, input a char.
            ldy #BaseN.Radix10          ; Preload decimal radix.
            cmp #"!"                    ; Decimal prefix?
            beq +                       ; Yes.
            ldy #BaseN.Radix2           ; Preload binary radix.
            cmp #"%"                    ; Binary prefix?
            beq +                       ; Yes.
            ldy #BaseN.Radix16          ; Preload hex radix.
            cmp #"$"                    ; Hex prefix?
            beq +                       ; Yes.
            ; Use hex anyway but put key back.
            .INPUT.Unget a              ; Put key back.
+           jmp INPUT.BaseN             ; Go input number.  Done.
            .endproc


;;---------------------------------------
;;
;; JSR INPUT.Span
;;
;; Parses these parameter formats specifying on what memory to apply a command.
;;
;;   <none>        (resume 1 page)
;;   start         (start 1 line)
;;   start L       (start 1 screen)
;;   start L count (start count lines)
;;   L             (resume 1 screen)
;;   L count       (resume count lines)
;;   start end     (start to end)
;;
;; The result is one of:
;;
;;          1. Error
;;          2. Start address and line count.
;;          3. Start address and end address (range).
;;
;; IN:      None.
;;
;; OUT:     X = Span type:
;;              1 = By Line count.
;;              2 = By range.
;;          CF = Error
;;          ZF = resuming (no start provided)
;;          Arg0 = first count
;;          Arg1 = first last
;;
;; SAFE:    None.
;;
Span        .proc

            .virtual 0
            ; Enum.  This order matters.
TYPE_ERROR  .byte ?
TYPE_LINES  .byte ?
TYPE_STARTEND .byte ?
            .endv

PAGE_LENGTH = 12 ; Half screen.
SCREEN_LENGTH = 23

            lda #0                      ; Assume resume = false..
            jsr ARGS.Push               ; Use arg to store start flag.
            jsr INPUT.Number            ; Get a number.
            bcc +                       ; Got one, it must be start.
            ; Resuming.
            pha                         ; Save last key.
            ldw a,y,RAM.Resume          ; Get resume address.
            jsr ARGS.Push               ; Put on arg stack as start address.
            dec Arg1                    ; Set resume flag to many true's.
            pla                         ; Restore last key.

+           cmp #"l"                    ; Is it the "L" token?
            bne rng_end                 ; No, maybe it's the end address.
            jsr INPUT.Number            ; Get line count.
            bcc +                       ; Valid number.
            cmp #NEWLINE                ; End of line?
            bne rng_err                 ; No, unexpected stuff after token.
            lda #SCREEN_LENGTH          ; Parameterless "L" is one screen.
            ldy #0                      ; Length hi always 0.
            beq rng_alines              ; Exit with line count in a,y.
+           ; Count was specified.
            cmp #NEWLINE                ; End of line?
            bne rng_err                 ; No, unexpected stuff after count.
            jmp rng_lines               ; Exit with line count arg.


rng_end     ; Maybe end address.
            cmp #NEWLINE                ; End of line?
            beq +                       ; Yes, no end address.
            jsr INPUT.Number            ; Get end address.
            bcs rng_err                 ; Wasn't a number. Unexpected.
            cmp #NEWLINE                ; End of line?
            bne rng_err                 ; Garbage after end.
            ldx #TYPE_STARTEND          ; Return start/end type.
            lsr Arg1                    ; Set ZF = resume flag.
            clc                         ; CF = Success.
            rts                         ; Done.

+           ; Just start or no parameters.
            lsr Arg1                    ; Have start?
            beq +                       ; Yes, show one line.
            ; No parameters.  Show a page.
            lda #PAGE_LENGTH            ; Load count.
            ldy #0                      ; Sign extend word with 0.
            beq rng_alines              ; Always true; relative jump.
+           ; Just start.
            lda #1                      ; One line.
            ldy #0                      ; Sign extend word with 0.
            beq rng_alines              ; Always true; relative jump.

rng_err     ldx #TYPE_ERROR             ; Invalidate range type.
            sec                         ; CF = Error
            rts                         ; Done.

rng_alines  jsr ARGS.Push               ; Push count on arg stack.
rng_lines   ldx #TYPE_LINES             ; Return line count type.
            lsr Arg2                    ; Set ZF = resume flag.
            clc                         ; CF = Success.
            rts                         ; Done.
            .endproc ; Range


;;---------------------------------------
;;
;; JSR INPUT.QString
;;
;; Reads a quoted string of up to 16 characters into RAM.String.
;;
QString     .proc

            ldx #0                      ; Initlialize string buffer index.
            jsr INPUT.Key               ; Read a character.
            cmp #QUOTE                  ; Is it a (opening) quote character?
            beq next                    ; Yes, continue.
error       sec                         ; No, return error.
            rts

getmore     sta RAM.String,x            ; Write to input buffer.
            inx                         ; Advance to next character.
next        jsr INPUT.Key               ; Get a character.
            beq error                   ; End of line in middle of string.
            cpx #16                     ; Do we have max characters already?
            beq finish                  ; Yes, expecting close quote.
            cmp #QUOTE                  ; End of string?
            bne getmore                 ; No, get more string.
success     stx RAM.StrLen
            jsr INPUT.Key               ; Read a delimiter.
            clc                         ; Success.
            rts
finish      cmp #QUOTE
            bne error
            beq success
            .endproc ; QString


            .endblock ; INPUT
