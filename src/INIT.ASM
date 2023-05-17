
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


INITIALIZE  .block


;--------------------------------------
;
; IMPLEMENTS THE INITIALIZE COMMAND.
;
;   token , start , end , byte ( , byte ... )
;
; Fill memory with the specified byte pattern.
;
Handler     .proc

EndPtr      = Arg0
FillPtr     = Arg1
Pattern     = RAM.END
PatLen      = Vr0
PatIndx     = Vr1

            jsr HUNT.InputPattern       ; Input fill pattern.
            stx PatLen                  ; Save seq length for later.
            ldx #0                      ; Initialize pattern index.
            stx PatIndx                 ; Persist pattern index.

fill_next   ldx PatIndx                 ; Pattern index.
            ldy #0                      ; Index always 0.
            lda Pattern,x               ; Get pattern byte.
            sta (FillPtr),y             ; Store in destination.
            inx                         ; Next pattern byte.
            cpx PatLen                  ; Enbd of pattern?
            bne +                       ; No.
            ldx #0                      ; Restart pattern.
+
advance     stx PatIndx                 ; Save pattern index.
            jsr PLATFORM.StopKeyIn           ; Is user stopping?
            beq done                    ; Yes.
            ldx #FillPtr                ; Select destination pointer.
            jsr ARGS.Incr               ; Increment it.
            ldx #EndPtr                 ; Select end argument.
            jsr ARGS.Compare            ; Is end >= start?
            bge fill_next               ; Yes, do more.

done        rts                         ; Done.
            .endproc


            .endblock ; INITIALIZE
