
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


HOME      .block

newbss      = Vr0                       ; New bss location.
newcode     = Vr1                       ; New monitor code/data start.
newendcode  = Vr2                       ; New monitor code/data end.

;--------------------------------------
;
; IMPLEMENTS THE HOME COMMAND.
;
;   token destination
;
; Creates a copy of the monitor at the specified base address.
; The monitor consists of three sections of information.  The CODE section
; contains only a contiguous region of machine language instructions.  The
; DATA section contains constant (read-only) data.  The BSS section defines a
; region of working RAM that is allocated when the monitor starts and is not 
; part of the monitor program image.  The CODE and DATA sections are 
; theoretically ROMable. This command provides two options for homing the 
; monitor to a new location:
;
; 1. All three sections located consecutively.  This is the easiest option.
;
;       :             :
;       :-------------:
;       |     CODE    |
;       :-------------:
;       |     DATA    |
;       +-------------+
;       |     BSS     |
;       +-------------+
;       :             :
;
; 2. BSS separate from consecutive CODE and DATA.  This is used when putting
;    the monitor in ROM.
;
;       :             :          :             :
;       :-------------:          :-------------:
;       |     CODE    |          |     BSS     |
;       :-------------:          +-------------+
;       |     DATA    |                 .
;       +-------------+                 .
;              .          -or-          .
;              .                 +-------------+
;              .                 |     CODE    |
;       +-------------+          +-------------+
;       |     BSS     |          |     DATA    |
;       +-------------+          +-------------+
;       :             :          :             :
;
;
Handler     .proc

            ; Aliases to make code more readable.
            bcc syntax_error            ; Command prefix not permitted.
            ; Input and validate new code/data address.
get_codhome jsr INPUT.Number            ; Input new code start.
            bcs value_error             ; Error, required number not input.
            pha
            tww a,y,Arg0,newcode        ; Copy new base to variable.
            ; Calculate default BSS.
            jsr default_bss
            pla                         ; Restore last key.
            cmp #NEWLINE                ; End of line?
            beq +                       ; Yes, default BSS.
get_newbss  jsr INPUT.Number            ; Input user BSS base.
            bcs value_error             ; Error, not a number.
            cmp #NEWLINE                ; End of line?
            bne syntax_error            ; No. Error, expecting nothing else.
            ldw a,y,Arg0                ; Get input BSS value.
            stw a,y,newbss              ; Store user BSS in variable.
            
            ; Nothing should be homed below page 2.
+           ldy newcode+1               ; Get new code base hi.
            cpy #2                      ; Compare hi to 2.
            blt range_error             ; Error, below page 2 is not allowed.
            ldy newbss+1                ; Get new BSS base hi.
            cpy #2                      ; Compare hi to 2.
            bge +                       ; Page 2 or above is allowed.
            ; Intentional fall-thru     ; Error, below page 2 is not allowed.
            ;   .
            ;   .
            ;   .
;*************************************************
                                        ;         ***
range_error .Escape ERROR.Range         ;   ERROR    *
syntax_error .Escape ERROR.Syntax       ;   ISLAND    *
value_error .Escape ERROR.Value         ;            *
                                        ;         ***
;*************************************************

+           ; Prompt to verify user really wants to do this.
            lea a,y,STRINGS.ask_sure
            jsr PRINT.String
            jsr INPUT.Key
            cmp #"y"
            beq +
            rts
+
            ;---------------------------
            ;
            ; newcode = new home base (CODE+DATA)
            ; newbss = new BSS base
Do
            ; Copy code and data sections.
            jsr PRINT.Newline
            lda #"1"
            jsr PRINT.Char
            
            lea a,y,CODE_BASE           ; Get current code/data base.
            jsr ARGS.Push               ; Transfer arg 1 is source start.
            lea a,y,DATA_END            ; Get current code/data end.
            jsr ARGS.Push               ; Transfer arg 2 is source end.
            ldw a,y,newcode             ; Get new home address.
            jsr ARGS.Push               ; Transfer arg 3 is destination.
.if debug
            jsr PRINT.Newline
            lda #'t'
            jsr PRINT.Char
            jsr PRINT.Space
            ldw a,y,Arg2
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg1
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg0
            jsr PRINT.Hex.W
            jsr PRINT.Newline
.endif
            jsr TRANSFER.Handler.Internal ; Copy monitor code and data.
    
            ; Setup code and data relocation args.
            lda #"2"
            jsr PRINT.Char

            ldw a,y,newcode             ; New code/data home.
            jsr ARGS.Push               ; New base arg 1 is code scan start.
            jsr ARGS.Push               ; Copy new home for calculation.
            lea a,y,CODE_SIZE-1         ; Get code section size.
            ldx #Arg0                   ; Select copy of new home.
            jsr ARGS.Add.W              ; New base arg 2 = new code end.
            tww a,y,Arg0,newendcode     ; Copy new code end for 2nd scan later.    
            lea a,y,CODE_BASE           ; Current code base.
            jsr ARGS.Push               ; New base arg 3 is operand base.
            lea a,y,DATA_END            ; Current data end.
            jsr ARGS.Push               ; New base arg 4 is operand limit.
            ldw a,y,newcode             ; New code/data base.
            jsr ARGS.Push               ; New base arg 5 is new base.
.if debug
            lda #'n'
            jsr PRINT.Char
            jsr PRINT.Space
            ldw a,y,Arg4
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg3
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg2
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg1
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg0
            jsr PRINT.Hex.W
            jsr PRINT.Newline
.endif
            jsr OPADJUST.Handler.Internal ; Relocate code/data operands.

            ; Setup BSS relocation args.
            lda #"3"
            jsr PRINT.Char

            ldw a,y,newcode             ; New code/data home.
            jsr ARGS.Push               ; New base arg 1 is code scan start.
            ldw a,y,newendcode          ; New code/data end.
            jsr ARGS.Push               ; New base arg 1 is code scan end.
            lea a,y,BSS_BASE            ; Current BSS begin.
            jsr ARGS.Push               ; New base arg 3 is operand base.
            lea a,y,BSS_END             ; Current BSS end.
            jsr ARGS.Push               ; New base arg 4 is operand limit.
            ldw a,y,newbss              ; New BSS base.
            jsr ARGS.Push               ; New base arg 5 is new base.
.if debug
            lda #'n'
            jsr PRINT.Char
            jsr PRINT.Space
            ldw a,y,Arg4
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg3
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg2
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg1
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,Arg0
            jsr PRINT.Hex.W
            jsr PRINT.Newline
.endif
            jsr OPADJUST.Handler.Internal ; Relocate BSS operands.

+           rts                         ; Done.
            .endproc ; Handler

default_bss .proc
            clc                         ; Clear carry for math.
            adc #<ROM_SIZE              ; Add base lo + CODE/DATA size lo.
            sta newbss                  ; Store in variable lo.
            tya                         ; Get base hi.
            adc #>ROM_SIZE              ; Add base hi + CODE/DATA size hi.
            sta newbss+1                ; Store in variable hi.
            rts
            .endproc ; default_bss

            .endblock ; HOME
