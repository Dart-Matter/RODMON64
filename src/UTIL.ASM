
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
; Miscellaneous handy things.
;


;;-------------------------------------
;;
;; JSR Mul10
;;
;; Multiply by 10.
;;
;; IN:      A = lo byte
;;          Y = hi byte
;;
;; OUT:     A = lo byte
;;          Y = hi byte
;;          CF = 16-bit overflow
;;
;; SAFE:    None.
;;
            .locals
            ; No user variables; just want register shadows.
            .endlocals

Mul10       .proc

            .FRAME.Alloc                ; Allocate stack frame.
            tsx                         ; Get frame reference.

            ; n x 10 is the same as (n x 2) + (n x 8)

            ; x 2
            jsr mul2                    ; [arg_a,arg_y] x 2
            bcs done                    ; Overflow.
            lda arg_y,x                 ; Load x2 hi.
            tay                         ; Save x2 hi in Y.
            lda arg_a,x                 ; Save x2 lo in A.
            ; x 8
            jsr mul2                    ; [arg_a,arg_y] x 2 = x 4
            bcs done                    ; Overflow.
            jsr mul2                    ; [arg_a,arg_y] x 2 = x 8
            bcs done                    ; Overflow.
            ; x 2 + x 8
            adc arg_a,x                 ; x2 lo + x8 lo = x10 lo.
            sta arg_a,x                 ; Save x10 lo for return.
            tya                         ; Get x2 hi for add.
            adc arg_y,x                 ; x2 hi + x8 hi + carry = x10 hi
            sta arg_y,x                 ; Save x10 hi for return.
done        ; Carry flag contains overflow indicator.
            php                         ; Temporarily push status flags.
            pla                         ; Immediatly pop them.
            sta arg_st,x                ; Save flags for return.
            .FRAME.Free                 ; Free stack frame.
            rts                         ; Done.

mul2        asl arg_a,x                 ; lo arg x2
            rol arg_y,x                 ; hi arg x2
            rts                         ; Done.

            .endproc ; Mul10


;;-------------------------------------
;;
;; JSR SetFeature
;;
;; Set/Clear feature flags.
;;
;; IN:      A = Off mask
;;          X = On bits
;;
;; OUT:     A = New feature flags.
;;
;; SAFE:    Y.
;;
SetFeature  .proc
            and RAM.Features
            pha
            txa
            tsx
            ora $101,x
            sta RAM.Features
            pla
            rts
            .endproc


.if debug

;;-------------------------------------
;;
;; jsr DebugPoint
;;
;; Emits an auto-incrementing number to track where execution is occurring
;; for debugging.
;;
DebugPoint  .proc
            php
            pha
            txa
            pha
            tya
            pha

            jsr PRINT.Newline
            lda RAM.DebugNum
            inc RAM.DebugNum
            jsr PRINT.Decimal.B
            jsr PRINT.Colon
            tsx
            lda $103,x
            jsr PRINT.Hex.B
            jsr PRINT.Space
            tsx
            lda $102,x
            jsr PRINT.Hex.B
            jsr PRINT.Space
            tsx
            lda $101,x
            jsr PRINT.Hex.B
            jsr PRINT.Space
            jsr PRINT.Newline

            pla
            tay
            pla
            tax
            pla
            plp
            rts
            .endproc

TEST        .block
Handler     .proc
            jsr PLATFORM.Newline
            jsr INPUT.QString
            bcc +
            .Escape ERROR.Value
+           lda #0
            sta RAM.String,x
            lea a,y,RAM.String
            jmp PRINT.String
            .endproc ; Handler
            .endblock ; TEST
.endif
