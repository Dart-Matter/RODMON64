
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


HUNT        .block


value_error .Escape ERROR.Value
byte_error  .Escape ERROR.Byte
syntax_error .Escape ERROR.Syntax


;--------------------------------------
;
; IMPLEMENTS THE HUNT COMMAND.
;
;   token , start , end , byte ( , byte ... )
;
; Search memory for the specified byte pattern.
;
Handler     .proc


            jsr InputPattern

EndPtr      = Arg0
CmpPtr      = Arg1
Pattern     = RAM.END
PatEnd      = Vr0
NumFound    = Vr1
PERLINE     = 8                         ; Results per line (2^n).

            dex                         ; Convert length to last index.
            stx PatEnd                  ; Stash index.
            lda #0                      ; Initialize find count.
            sta NumFound                ; Stash count.

compare_pattern
            ldy PatEnd                  ; Get start index.
-           lda (CmpPtr),y              ; Get memory byte.
            cmp Pattern,y               ; Compare to sequence byte.
            bne advance                 ; Mismatch.
            dey                         ; Next pattern byte.
            bpl -                       ; Until all of pattern compared.
            ; Found sequence in memory.
            lda #PERLINE - 1            ; Convert count to modulo mask.
            bit NumFound                ; Modulo = 0?.
            bne +                       ; No, space byte out.
            lda #NEWLINE                ; New row.
            bne ++
+           lda #" "                    ; Space.
+           jsr PRINT.Char              ; Print it.
            inc NumFound                ; Increment count.
            ; Display result.
            ldw a,y,CmpPtr              ; Current memory address.
            jsr PRINT.Hex.W             ; Print it.

advance     jsr PLATFORM.StopKeyIn           ; Is user stopping?
            beq done                    ; Yes.
            ldx #CmpPtr                 ; Select start argument.
            jsr ARGS.Incr               ; Increment for next pattern compare.
            ldx #EndPtr                 ; Select end argument.
            jsr ARGS.Compare            ; Is end >= start.
            bge compare_pattern         ; Yes, do mode.

done        rts                         ; Done.
            .endproc ; Handler


;--------------------------------------
;
; Input information for applying a pattern to a range of memory.
;
;  <start> <end> <byte> (<byte>...)
;
; OUT:      Arg0 = Range start.
;           Arg1 = Range end.
;           X = Pattern length.
;           RAM.END = Pattern start.
;           CF = Error.
;
InputPattern .proc

            jsr INPUT.Number            ; Input start.
            bcs value_error             ; Invalid number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            tww a,a,Arg0,Vr3            ; Save start for later.
            jsr INPUT.Number            ; Input end.
            bcs value_error             ; Invalid number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            tww a,a,Arg0,Vr5            ; Save end for later.

            ; Build search pattern.
            ldx #0                      ; Init store index.
-           stx Handler.PatEnd          ; Save for later.
            jsr INPUT.Number            ; Input a pattern byte.
            bcs value_error             ; Error, not number.
            bne byte_error              ; Error, not a byte value.
            tay                         ; Save delimiter in Y.
            ldx Handler.PatEnd          ; Get store index.
            lda Arg0.lo                 ; Get pattern byte.
            sta Handler.Pattern,x       ; Add to pattern buffer.
            inx                         ; Next buffer index.
            cpy #NEWLINE                ; End of line?
            bne -                       ; No, try more input.
            tww a,a,Vr3,Arg1            ; Copy start to Arg1.
            tww a,a,Vr5,Arg0            ; Copy end to Arg0.
            clc                         ; Success.
            rts                         ; Done.
            .endproc


            .endblock ; HUNT
