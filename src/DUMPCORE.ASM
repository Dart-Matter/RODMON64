
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
; Routines for displaying memory contents.
;


DUMP        .block


;;-------------------------------------
;;
;; JSR DUMP.Bytes
;;
;; Dump a line of hex bytes from memory.
;;
;; IN:      A = Bytes address lo.
;;          Y = Bytes address hi.
;;          X = Number of bytes to dump.
;;
;; OUT:     None.
;;
;; SAFE:    None.
;;
Bytes       .proc
            sec                         ; Indicate byte dump.
            bcs Chars.shared
            .endproc


;;-------------------------------------
;;
;; JSR DUMP.Chars
;;
;; Dump a line of characters from memory as PETSCII or poke codes.
;;
;; IN:      A = Start address lo.
;;          Y = Start address hi.
;;          X = Number of bytes to dump.
;;
;; OUT:     None.
;;
;; SAFE:    None.
;;
Chars       .proc
            clc                         ; Indicate character dump


;--------------------------------------
;
; This function is shared for dumping both bytes or characters.
;
; IN:       A = Start address lo.
;           Y = Start address hi.
;           X = Number of bytes to dump.
;           CF = 1 = Dump hex bytes.
;                0 = Dump characters.
;
; OUT:      None.
;
; SAFE:     None.
;
shared

            .locals
count       .byte ?
index       .byte ?
type        .byte ?                     ; NF = bytes/chars
            .endlocals

            .FRAME.Alloc                ; Allocate locals.
            txa                         ; Copy count to A. Free X.
            tsx                         ; Get frame pointer.
            sta count,x                 ; Set count variable.
            ror type,x                  ; Convert CF to type (NF) flag.
            lda arg_a,x                 ; Get start lo.
            stw a,y,Vr5                 ; Store start address in zero page.
            ; Dump one byte or char.
            tsx                         ; Get frame pointer.
-           ldy index,x                 ; Next read location.
            lda (Vr5),y                 ; Read data byte.
            ldy type,x                  ; Do byte dump?
            bpl dumpchar                ; No, do char dump.
dumpbyte    jsr PRINT.Hex.B             ; Print hex byte.
            bcc +                       ; Advance
dumpchar    jsr PLATFORM.SymbolOut      ; Print char.
+           tsx                         ; Get frame pointer.
            dec count,x                 ; Decrease count.
            beq dumpdone                ; Done.
            lda type,x                  ; Is byte dump?
            bpl +                       ; Yes.
            jsr PRINT.Space             ; Bytes are separated by space.
+           tsx                         ; Get frame pointer.
            inc index,x                 ; Advance read location.
            bne -                       ; Always true; relative jump.
dumpdone    .FRAME.Free                 ; Free locals.
            clc                         ; Success always.
            rts                         ; Done.
            .endproc ; Chars


;;-------------------------------------
;;
;; JSR DUMP.PrettyBytes
;;
;; Dump a line of bytes followed by their character representation.
;;
;; IN:      A = Start address lo.
;;          Y = Start address hi.
;;
;; OUT:     X = Number of bytes dumped.
;;
;; SAFE:    None.
;;
PrettyBytes .proc

            .locals
            ; No variables.  Register backup only.
            .endlocals

LENGTH      = 8

            .FRAME.Alloc                ; Allocate locals.
            jsr PRINT.Hex.W             ; Print address.
            jsr PRINT.Colon             ; Print edit token.
            tsx                         ; Get frame pointer.
            ldy arg_y,x                 ; Get address hi.
            lda arg_a,x                 ; Get address lo.
            ldx #LENGTH                 ; Number of bytes to dump.
            jsr Bytes                   ; Print them.
            ; Separate bytes from characters.
            ldy #2                      ; 2 spaces.
            jsr PRINT.SpacesY
            ; Dump chars.
            tsx                         ; Get frame pointer.
            ldy arg_y,x                 ; Get address hi.
            lda arg_a,x                 ; Get address lo.
            ldx #LENGTH                 ; Number of characters to dump.
            jsr Chars                   ; Print them.
            .FRAME.Free                 ; Free locals.
            ldx #LENGTH                 ; Return count.
            clc                         ; Success always.
            rts                         ; Done.
            .endproc ; PrettyBytes


;;-------------------------------------
;;
;; JSR DUMP.PrettyChars
;;
;; Dump a line of characters.
;;
;; IN:      A = Start address lo.
;;          Y = Start address hi.
;;
;; OUT:     X = Number of bytes dumped.
;;
;; SAFE:    None.
;;
PrettyChars .proc

            .locals
            ; No variables.  Register backup only.
            .endlocals

LENGTH      = 32

            .FRAME.Alloc                ; Allocate locals.
            jsr PRINT.Hex.W             ; Print address.
            jsr PLATFORM.QuoteOut       ; Print edit token.
            tsx                         ; Get frame pointer.
            ldy arg_y,x                 ; Get address hi.
            lda arg_a,x                 ; Get address lo.
            ldx #LENGTH                 ; Number of chars to dump.
            jsr Chars                   ; Print them.
            .FRAME.Free                 ; Free locals.
            ldx #LENGTH                 ; Return count.
            clc                         ; Success always.
            rts                         ; Done.
            .endproc ; PrettyChars


;--------------------------------------
;
; jsr DUMP.CommandCore
;
; A shared core implementation for dump commands.
;
; IN:       Vr0 = Address of formatting routine.
;           Vr2 = Bytes per line.
;
; OUT:      X = Number of bytes dumped.
;
; SAFE:     None.
;
CommandCore jsr INPUT.Span              ; Input standard range format.
            bcs value_error             ; Input bad.
            ; Select the output control.
try_lines   lea a,y,line_ctrl           ; Preload line loop control.
            cpx #SPAN_LINES             ; By line count?
            beq set_ctrl                ; Yes.
try_range   cpx #SPAN_RANGE             ; By range?
            beq RangeCore               ; No.  Unknown span type.
            ; Intentional fall-thru
bug_error   .Escape ERROR.Bug
value_error .Escape ERROR.Value

;--------------------------------------
;
; jsr DUMP.RangeCore
;
; A shared core implementation for dump commands.
;
; IN:       Vr0 = Address of formatting routine.
;           Vr2 = Bytes per line.
;           Args0 = End address.
;           Args1 = Start address.
;
; OUT:      X = Number of bytes dumped.
;
; SAFE:     None.
;
RangeCore   lea a,y,range_ctrl          ; Load range loop control.    

set_ctrl    stw a,y,Vr1                 ; Store the loop control routine.
            jsr PLATFORM.Overwrite      ; Perpare to overwrite command.
            bcc begin_dump              ; Relative jump. CF = 0 always.

;--------------------------------------
;
; Shared dump loop.
;

            ; Aliases to make code easier to read.
CurrArg     = Arg1
CountArg    = Arg0
EndArg      = Arg0

loop        jsr PLATFORM.StopKeyIn      ; User stopping?
            beq done                    ; Yes, abort immediately.
            jsr PRINT.Newline           ; Advance output to next line.
            
begin_dump  jsr lineout                 ; Dump one line.
            jmp (Vr1)                   ; Go to selected loop control.

line_ctrl   ldx #CountArg               ; Select line count arg.
            jsr ARGS.Decr               ; Decerement line count.
            bne loop                    ; Repeat while count is not 0.
done        rts                         ; Done.

range_ctrl  ldx #EndArg                 ; Select end arg.
            jsr ARGS.Compare            ; Compare end - start?
            bge loop                    ; Repeat while end is greater or equal.
            rts                         ; Done.

dump        jmp (Vr0)                   ; Used effectively for jsr (indirect)
                                        ; to formatted output routine.

lineout     ldw a,y,CurrArg             ; Get source address.
            ldx Vr2                     ; Number of bytes per line (if used).
            jsr dump                    ; Dump the data to the screen.
            txa                         ; A = number of bytes dumped for add.
            ldx #CurrArg                ; Select start arg.
            jsr ARGS.Add.B              ; Add number of bytes dumped to start.
            tww a,a,CurrArg,RAM.Resume  ; Update resume address.
            rts                         ; Return to loop.


            .endblock ; DUMP
