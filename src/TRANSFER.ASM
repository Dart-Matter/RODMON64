
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


TRANSFER    .block


value_error .Escape ERROR.Value
range_error .Escape ERROR.Range
syntax_error .Escape ERROR.Syntax


;--------------------------------------
;
; IMPLEMENTS THE TRANSFER COMMAND.
;
;   token start end destination
;
Handler     .proc

            ; Input and validate the start and end parameter.
            jsr INPUT.Number            ; Input start address.
            bcs value_error             ; Invalid, but required.
            cmp #NEWLINE        ; End of line?
            beq syntax_error            ; Yes, expected more.
            jsr INPUT.Number            ; Input end address.
            bcs value_error             ; Invalid, but required.
            cmp #NEWLINE        ; End of line?
            beq syntax_error            ; Yes, expected more.
            ldx #Arg0                   ; Select end arg.
            jsr ARGS.Compare            ; Is end > start?
            ble range_error             ; No, invalid range.

            ; Destination is required.
            jsr INPUT.Number            ; Input destination address.
            bcs value_error             ; Error, no number.

Internal
; Aliases to make code below more readable.
DestPtr     = Arg0                      ; Destinatlon address.
EndPtr      = Arg1                      ; End address.
SrcPtr      = Arg2                      ; Start address.

            ; If destination is in the middle of the source range and the copy
            ; is perform by starting low and ascending through memory, the
            ; operation will corrupt the source by writing to parts of the
            ; source that have not yet been copied.  In this case the copy
            ; should start at the end and descend through memory.
            ;
            ; Select descending copy any time destination is greater
            ; than start.
            lda DestPtr.hi              ; Get destination page.
            cmp SrcPtr.hi               ; Compare destination to start.
            bgt descending_copy         ; d > s, use descending copy.
            blt ascending_copy          ; d < s, use ascending copy.
            lda DestPtr.lo              ; Get destination address lo.
            cmp SrcPtr.lo               ; Compare destination to start.
            ble ascending_copy          ; d <= s, use ascending copy.

descending_copy
            ; Calculate destination end by adding source length to destination.
            ldw a,y,EndPtr              ; Get end address.
            sec                         ; Clear borrow.
            sbc SrcPtr.lo               ; Subtract start lo.
            tax                         ; Save lo to X.
            tya                         ; Get start hi.
            sbc SrcPtr.hi               ; Subtract start hi.
            tay                         ; Save hi to Y.
            txa                         ; Restore lo to A.
            ; Add length (A,Y) to destination.
            ldx #DestPtr                ; Select destination arg.
            jsr ARGS.Add.W              ; Add length (A,Y) to it.
            ; Copy.
-           ldx #0                      ; No index/offset.
            lda (EndPtr,x)              ; Read source byte.
            sta (DestPtr,x)             ; Write destination byte.
            ldx #DestPtr                ; Select destination arg.
            jsr ARGS.Decr               ; Decrement it.
            ldx #EndPtr                 ; Select source end arg.
            jsr ARGS.Decr               ; Decrement it.
            jsr ARGS.Compare            ; Is end >= start?
            bge -                       ; Yes, keep going.
            blt done                    ; Done.

ascending_copy
-           ldx #0                      ; No index/offset.
            lda (SrcPtr,x)              ; Read source byte.
            sta (DestPtr,x)             ; Write destination byte.
            ldx #DestPtr                ; Select destination arg.
            jsr ARGS.Incr               ; Increment it.
            ldx #SrcPtr                 ; Select source start arg.
            jsr ARGS.Incr               ; Increment it.
            ldx #EndPtr                 ; Select end arg.
            jsr ARGS.Compare            ; Is end >= start?
            bge -                       ; Yes, keep going.

done        rts                         ; Done.
            .endproc ; Handler


            .endblock ; INITIALIZE
