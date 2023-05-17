
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


;
; This file contains routines for using the command argument stack.
;
; The argument stack is a reserved region of memory containing a series of
; 2-byte words ascending in memory.  This is used primarly to store numbers that
; are read from the user via the screen editor.  As each number argument is
; read a push operation shifts all values through the stack and the oldest
; value is lost.  The values are shifted so that an addition pointer value
; doesn't need to be maintained.
;
;        :             :
;        :-------------:
;     +8 |    word 4   | OLDEST
;        :-------------:
;     +6 |    word 3   |        ^
;        +-------------+        |
;     +4 |    word 2   |        |
;        +-------------+        |
;     +2 |    word 1   |      push
;        +-------------+
;     +0 |    word 0   | NEWEST
;        :-------------:
;        :             :


ARGS        .block


;;-------------------------------------
;;
;; jsr ARGS.Push
;;
;; Push a value onto the argument stack.
;;
;; IN:      A = Lo byte of word to push.
;;          Y = Hi byte of word to push.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    A,X,Y
;;
Push        .proc
            pha                         ; Save new lo.
            txa
            pha                         ; Save X.
            ; Shift stack.
            ldx #ArgsLen - 3
-           lda Arg0.lo,x
            sta Arg1.lo,x
            dex
            bpl -
            pla
            tax                         ; Restore X.
            pla                         ; Restore A arg.
            ; Place new value.
            sta Arg0.lo
            sty Arg0.hi
            clc
            rts
            .endproc                    ; Push


;;-------------------------------------
;;
;; jsr Incr
;;
;; Add a byte value to an argument.
;;
;; IN:      X = Offset of the argument to increment.
;;              This can be an Arg* constant.
;;
;; OUT:     CF = 0.
;;
;; SAFE:    A,Y,X
;;
Incr        .proc
            inc $00,x
            bne +
            inc $01,x
+           clc
            rts
            .endproc


;;-------------------------------------
;;
;; jsr ARGS.Add.B
;;
;; Add a byte value to an argument.
;;
;; IN:      X = Offset of argument to increase.
;;              This can be an Arg* constant.
;;          A = Value to add.
;;
;; OUT:     CF = overflow.
;;
;; SAFE:    X
;;
Add         .proc
B
            ldy #0                      ; Assume hi = 0.


;;-------------------------------------
;;
;; jsr ARGS.Add.Arg
;;
;; Add a word value to an argument.
;;
;; IN:      X = Offset of argument to increase.
;;              This can be an Arg* constant.
;;          A = Lo byte of value to add.
;;          Y = Hi byte of value to add.
;;
;; OUT:     CF = overflow.
;;
;; SAFE:    X,Y
;;
W
            clc
            adc $00,x
            sta $00,x
            tya
            adc $01,x
            sta $01,x
            rts
            .endproc


;;-------------------------------------
;;
;; jsr ARGS.Decr
;;
;; Decrement an argument.
;;
;; IN:      X = Offset of argument to decrement.
;;              This can be an Arg* constant.
;;
;; OUT:     ZF = Result is zero.
;;          CF = 0
;;
;; SAFE:    Y
;;
Decr        .proc
            lda $00,x
            bne +
            dec $01,x
+           dec $00,x
            bne +
            lda $01,x
+           clc
            rts
            .endproc


;;-------------------------------------
;;
;; jsr ARGS.Compare
;;
;; Compare ArgN to ArgN+1.
;;
;; IN:      X = Offset of first argument to compare.
;;              This can be an Arg* constant.
;;
;; OUT:     ZF and CF are set as in compare instruction.
;;
;; SAFE:    X,Y
;;
Compare     .proc
            lda $01,x
            cmp $03,x
            bcc +
            bne +
            lda $00,x
            cmp $02,x
+           rts
            .endproc                    ;  Compare


            .endblock                   ; ARGS
