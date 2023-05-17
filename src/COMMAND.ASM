
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
; Set up for command declarations.
;
.if SECTION=="data"

COMMAND_traits = *                      ; Note start of command declarations.    

            ;--------------------------------------
            ;
            ; A macro for declaring a command trait.
            ;
            ;   k = character token
            ;   f = flags
            ;
COMMAND_Trait .macro k,f
            .byte   (\k - 32) | \f
            .endm

TokenMask   = %00111111                 ; The character token for the command.
FlagMask    = %11000000                 ; Flags for parsing the command.
ImpFlag     = %00000000                 ; command only
EdtFlag     = %01000000                 ; optional + command
RngFlag     = %10000000                 ; cmd + optional

.elsif SECTION="code"

            COMMAND_jmps = *            ; Note start of jump table.
.else
            .error "Invalid SECTION!"
.endif


;--------------------------------------
;
; Generate the command declarations in the data section and the respective 
; jump table in the code section.
;
;   k = character token
;   f = flags
;

.if SECTION=="data"
            .COMMAND_Trait '.', EdtFlag
.else
            jmp BREAKPOINTS.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait '+', EdtFlag
.else
            jmp CALCULATE.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'x', ImpFlag
.else
            jmp RODMON.Exit
.endif

.if SECTION=="data"
            .COMMAND_Trait 'u', RngFlag
.else
            jmp UNASSEMBLE.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'm', RngFlag
.else
            jmp MEMDUMP.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'k', RngFlag
.else
            jmp CHARDUMP.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait '[', ImpFlag
.else
            jmp UNOFFICIAL.On
.endif

.if SECTION=="data"
            .COMMAND_Trait ']', ImpFlag
.else
            jmp UNOFFICIAL.Off
.endif

.if SECTION=="data"
            .COMMAND_Trait '(', ImpFlag
.else
            jmp CODEBYTES.On
.endif

.if SECTION=="data"
            .COMMAND_Trait ')', ImpFlag
.else
            jmp CODEBYTES.Off
.endif

.if SECTION=="data"
            .COMMAND_Trait '<', ImpFlag
.else
            jmp CHARMODE.Petscii
.endif

.if SECTION=="data"
            .COMMAND_Trait '>', ImpFlag
.else
            jmp CHARMODE.Pokes
.endif

.if SECTION=="data"
            .COMMAND_Trait 'g', RngFlag
.else
            jmp GO.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'r', ImpFlag
.else
            jmp REGISTERS.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait ' ', EdtFlag
.else
            jmp ASSEMBLE.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait ':', EdtFlag
.else
            jmp MEMEDIT.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait '*', EdtFlag
.else
            jmp REGEDIT.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'w', RngFlag
.else
            jmp WALK.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'j', RngFlag
.else
            jmp JUMP.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait '-', EdtFlag
.else
            jmp BYTEASM.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'h', EdtFlag
.else
            jmp HUNT.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'i', EdtFlag
.else
            jmp INITIALIZE.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 't', EdtFlag
.else
            jmp TRANSFER.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'o', EdtFlag
.else
            jmp OPADJUST.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 's', EdtFlag
.else
            jmp STORAGE.SAVE.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'l', EdtFlag
.else
            jmp STORAGE.LOAD.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait 'v', EdtFlag
.else
            jmp STORAGE.VERIFY.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait '?', ImpFlag
.else
            jmp ABOUT.Handler
.endif

.if SECTION=="data"
            .COMMAND_Trait ";", EdtFlag
.else
            jmp PLATFORM.Overwrite
.endif

.if SECTION=="data"
            .COMMAND_Trait "n", EdtFlag ; Left arrow
.else
            jmp HOME.Handler
.endif

.if debug
.if SECTION=="data"
            .COMMAND_Trait "#", ImpFlag
.else
            jmp TEST.Handler
.endif
.endif            

.if SECTION=="data"
    COMMAND_endtraits = * - COMMAND_traits
.else
    COMMAND_endjmps = * - COMMAND_jmps
    ; Fall-thru


COMMANDS    .block


;;-------------------------------------
;;
;; JSR COMMANDS.Start
;;
;; IN:      CF = Show banner.
;;

;
; This is the return address that should be used to come back to the
; command input processor.
;
Return      = * - 1
            clc                         ; No banner.
Start       php                         ; Save banner settings.
            jsr PLATFORM.TerminalReset
            plp                         ; Restore banner setting.
            bcc Restart                 ; Skip banner.
            ; Show banner.
            lea a,y,STRINGS.banner
            jsr PRINT.String

;;-------------------------------------
;;
;; JSR COMMANDS.Restart
;;
;; This routines accepts initial user input and dispatches control to an
;; appropriate command handler.
;;
;; If the command is declared with EdtFlag CF indicates that the command is
;; being invoked without a leading number.
;;
Restart

            ; Set call stack for monitor exit.
            ldx RAM.RetSp
            txs
            ; Push default return address.
            lea y,a,Return              ; Note the non-typical y,a assignment.
            pha
            tya
            pha
            jsr PLATFORM.Newline           ; Start at beginning of next line.
            ; Preload a key to trigger border reset.
            jsr INPUT.Key
            ; Reset visual alert.
            ldx #BRK_RESET
            jsr PLATFORM.VisualizeBrk
            ; Start command parsing.
            jsr INPUT.Number.Started    ; Get number using previous key.
            php                         ; Save CF=no leading number.
            bcc +
            pha                         ; Stash key.
            ldw a,y,RAM.Resume          ; Get resume address
            jsr ARGS.Push               ; Store as first argument.
            pla                         ; Recover key.
+           sec                         ; Clear borrow.
            sbc #32                     ; Convert ASCII to command index.
            sta Vr0                     ; Save command index.
            ldy #COMMAND_endtraits      ; End of table for reverse search.
find        dey                         ; Descend to next command.
            lda COMMAND_traits,y        ; Get command declaration.
            tax                         ; Copy it.
            and #TokenMask              ; Get token.
            cmp Vr0                     ; Compare to input token.
            beq dispatch                ; Found command.
            iny                         ; Set ZF
            dey                         ;  from current offset.
            bne find                    ; Not zero, do another.

            ; Unknown command.
error       .Escape ERROR.Command

dispatch    ; Dispatch command to handler.
            txa                         ; Copy command declaration.
            and #FlagMask               ; Isolate command type.
            cmp #ImpFlag                ; Implied type?
            beq implied                 ; Yes.
            cmp #RngFlag                ; Range type?
            beq ranged                  ; Yes.
            cmp #EdtFlag                ; Edit type?
            bne error                   ; No, unexpected.

edit        ; Edit command format.
            plp                         ; Restore CF=no prefix.
            jmp invoke                  ; Invoke handler.

ranged      ; Range command format.
            plp                         ; Restore CF=no prefix.
            bcc error                   ; Error to have prefix.
            bcs invoke                  ; Invoke handler.


implied     ; Implied command format.
            plp                         ; Restore CF=no prefix.
            bcc error                   ; Prefix is invalid.
            jsr INPUT.Key               ; Get key.
            cmp #NEWLINE        ; End of line?
            bne error                   ; No, expected end of line.

invoke      ; Invoke the command handler through the stack.
            php                         ; Save flags
            ; Compute offset to command jmp.
            sty Tr6                     ; Index x1.
            tya
            asl                         ; Index x2 (CF=0).
            adc Tr6                     ; x2 + x1 = x3.
            sta Vr0.lo                  ; Stash x3.
            
            lea a,y,COMMAND_jmps        ; Get command jmp list base.
            clc                         ; Clear carry for math.
            adc Vr0.lo                  ; Add offset.
            sta Vr0.lo                  ; Store command vector lo byte.
            bcc +                       ; Skip if no carry.
            iny                         ; Carry.
+           sty Vr0.hi                  ; Store command vectro hi byte.
            plp
            jmp (Vr0)


            .endblock ; COMMANDS


.endif      ; code

