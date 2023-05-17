
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
; Commodore 64 specific definitions.
;

.if SECTION="header"
PLATFORMID  = "C64"
.endif



;        _______ _ __ ___  _ __   __ _  __ _  ___
;       |_  / _ \ '__/ _ \| '_ \ / _` |/ _` |/ _ \
;        / /  __/ | | (_) | |_) | (_| | (_| |  __/
;       /___\___|_|  \___/| .__/ \__,_|\__, |\___|
;                         | |           __/ |
;                         |_|          |___/
;
; The zero page assignments don't produce code or data.  They are conditionally
; assembled in a section simply so they are defined only once.

.if SECTION="data"

            .virtual    $4B ; ..$65 = 13 words
ZpStart64
Arg0        .SWORD  ?                   ;; Top
Arg1        .SWORD  ?                   ;;
Arg2        .SWORD  ?                   ;;
Arg3        .SWORD  ?                   ;;
Arg4        .SWORD  ?                   ;; Bottom
ArgsLen     = * - Arg0

Vr0         .SWORD  ?                   ;;
Vr1         .SWORD  ?                   ;;
Vr2         .SWORD  ?                   ;;
Vr3         .SWORD  ?                   ;;
Vr4         .SWORD  ?                   ;;
Vr5         .SWORD  ?                   ;;
Tr6         .SWORD  ?                   ;;
ZpEnd64
            .endvirtual

.endif ; zeropage

;                                    _
;                                   | |
;                       ___ ___   __| | ___
;                      / __/ _ \ / _` |/ _ \
;                     | (_| (_) | (_| |  __/
;                      \___\___/ \__,_|\___|
;
.if SECTION="code"

PLATFORM    .block


;--------------------------------------
;
; Commodore 64 Internals.  Do not access these from the monitor proper.  Only
; access them from Commodore 64 platform code (this file.)
;
C64         .block

;--------------------------------------
;
; RAM LOCATIONS
;
TEMP        = $22     ; We use for indirect.
STATUS      = $90     ; Kernel I/O status.
STKEY       = $91     ; Stop key = 127
CURCOL      = $D3
QMODE       = $D4     ; Quote mode output.
IRQVEC      = $314    ; KERNEL IRQ vector
BRKVEC      = $316    ; KERNEL BRK vector
NMIVEC      = $318    ; KERNEL NMI vector


;--------------------------------------
;
; ROM ROUTINES
;
SETNAM      = $FFBD
SETLFS      = $FFBA
OPEN        = $FFC0
CLOSE       = $FFC3
SAVE        = $FFD8
LOAD        = $FFD5
CLRCHN      = $FFCC
GETIN       = $FFE4
CHRIN       = $FFCF
CHROUT      = $FFD2
CHKOUT      = $FFC9
CHKIN       = $FFC6
READST      = $FFB7
BASIC64     = $E39D


;--------------------------------------
;
; VIC II REGISTERS AND VALUES
;
VICII       .block

BLACK       = 0
WHITE       = 1
RED         = 2
CYAN        = 3
PURPLE      = 4
GREEN       = 5
BLUE        = 6
YELLOW      = 7
ORANGE      = 8
BROWN       = 9
LTRED       = 1
DKGREY      = 1
GREY        = 1
LTGREEN     = 1
LTBLUE      = 1
LTGREY      = 1

Border      = $D020 ; Color

            .endblock ; VICII


;--------------------------------------
;
; SPECIAL CHARACTER CODES
;
PETSCII     .block

NEWLINE     = 13
DOWN        = 17
RVSON       = 18
SPACE       = 32
UP          = 145
RVSOFF      = 146
LEFT        = 157
TOPLEFTHALF = 169
UPARROW     = $5E
QUOTE       = $22

            .endblock ; PETSCII


;--------------------------------------
;
; 6510 I/O PORT
;
DDR         = $00
DAT         = $01
LORAM       = %00000001
HIRAM       = %00000010
CHAREN      = %00000100
CASS_WRITE  = %00001000
CASS_SENSE  = %00010000
CASS_MOTOR  = %00100000


;--------------------------------------
;
; jsr DUMP.PokeToPet
;
; Translate a poke code to PETSCII derivative.
;
; IN:       A = Poke code.
;
; OUT:      A = PETSCII code.
;           CF = Display in reverse mode.
;
; SAFE:     X,Y
;
PokeToPet   .proc

            ; Poke codes with bit 7 set are reverse mode.
            asl                         ; Shift reverse bit into CF.
            php                         ; Save reverse bit.
            lsr                         ; Clear reverse bit.
            cmp #32                     ; If alpha/symbol code
            bcc add64                   ;  translate.
            cmp #64                     ; If numeric/symbol
            bcc return                  ;  ok as is.
            cmp #97                     ; If graphic
            bcc add32                   ;  translate.
            ; else (97..127) add 64
            clc                         ; Clear carry and fall thru.
add64       adc #64                     ; CF is already clear.
            bcc return                  ; Always true; relative jump.
add32       adc #32                     ; CF is already clear.
return      plp ; Restore CF = reverse mode.
            rts

            .endproc ; PokeToPet


;--------------------------------------
;
; jsr QuotedCharOut
;
; Print a PETSCII character in quote mode.
;
; IN:      A = Character to print.
;
; OUT:     CF = 0.
;
; SAFE:    X,Y
;
QuotedCharOut .proc
            pha
            lda #1                      ; Quote mode on.
            sta C64.QMODE
            pla
            jsr PRINT.Char
            lsr C64.QMODE               ; Quote mode off.
            clc
            rts
            .endproc


;--------------------------------------
;
; jsr PLATFORM.RvsCharOut
;
; Print a reverse terminal ASCII character (32-90).
;
; IN:       A = Character to print.
;
; OUT:      CF = 0 (success).
;
; SAFE:     A,X,Y
;
RvsCharOut  .proc
            .locals
            .endlocals
            .FRAME.Alloc
            lda #PETSCII.RVSON
            jsr C64.CHROUT
            lda arg_a
            jsr C64.CHROUT
            lda #0                      ; Quote mode off.
            sta C64.QMODE
            lda #PETSCII.RVSOFF
            jsr C64.CHROUT
            .FRAME.Free
            clc
            rts
            .endproc


;--------------------------------------
;
; BRK handler
;
; Normalizes a BRK interrupt to a common monitor state.
;
;       :           :
;       +-----------+
;       | return hi |     SP + $106
;       +-----------+
;       | return lo |     SP + $105
;       +-----------+
;       |  status   |     SP + $104
;       +-----------+
;       |accumulator|     SP + $103
;       +-----------+
;       |     x     |     SP + $102
;       +-----------+
;       |     y     |     SP + $101
;       +-----------+
;       :           : <-- SP + $100
;
; and CPU registers contain their respective values.
;
; The C64 already has this stack state.  We only need to load the registers.
;
BrkNormalizer .proc
            tsx
            lda $104,x                  ; Preparing to load status.
            pha
            lda $103,x                  ; Preparing to load A.
            pha
            lda $101,x                  ; Loading Y.
            tay
            lda $102,x                  ; Loading X.
            tax
            pla                         ; Load A.
            plp                         ; Load status.
            jmp (RAM.MonBrk)
            .endproc


            .endblock ; C64

;--------------------------------------
;
; Relocate monitor to BASIC ROM home and turn off BASIC ROM.
;
HomeA000    .proc
base        = $A000

            lda C64.DAT
            and #~C64.LORAM             ; Turn BASIC ROM off.
            sta C64.DAT                 ; Control port.
            lea a,y,base                ; Relocation target.
            stw a,y,HOME.newcode        ; Store in new base variable.
            jsr HOME.default_bss        ; Compute default new BSS variable.
            jsr HOME.Handler.Do         ; Perform relocate.
            jsr base                    ; Start it.
            ; Upon return...
            lda C64.DAT
            ora #C64.LORAM              ; Turn BASIC ROM back on.
            sta C64.DAT
            rts
            .endproc


;                                  _     _ _
;                                 | |   | (_)
;                      _ __  _   _| |__ | |_  ___
;                     | '_ \| | | | '_ \| | |/ __|
;                     | |_) | |_| | |_) | | | (__
;                     | .__/ \__,_|_.__/|_|_|\___|
;                     | |
;                     |_|
;
; This is the platform interface that will be called by the monitor.
;

;---------------------------------------
;
; jsr IsBrkPage
;
; IN:       A = Page number.
;
; OUT:      ZF = Is breakable.
;
IsBrkPage   .proc
            cmp #$c0                    ; Establish CF = (A >= $C000).
            lda #1                      ; Clear ZF = not breakable.
            bcs +                       ; Greator or equal, so not breakable.
            lsr                         ; Set ZF.
+           rts                         ; Done.
            .endproc

;--------------------------------------
BackupZp    .proc
            pha
            ldx #ZpEnd64 - ZpStart64 - 1
-           lda ZpStart64,x
            sta C64_BSS.ZpBackup,x
            dex
            bpl -
            pla
            rts
            .endproc

;--------------------------------------
RestoreZp   .proc
            pha
            ldx #ZpEnd64 - ZpStart64 - 1
-           lda C64_BSS.ZpBackup,x
            sta ZpStart64,x
            dex
            bpl -
            pla
            rts
            .endproc

;--------------------------------------
CharOut     .proc
            jsr C64.CHROUT
            clc
            rts
            .endproc

;--------------------------------------
SymbolOut   .proc
            .locals
            .endlocals
            .FRAME.Alloc
            tay                         ; Save character.
            lda RAM.Features            ; Retrieve feature flags.
            and #RAM.FLAG.PETSCII       ; In PETSCII character mode?
            beq use_pokes               ; No, source is poke code.

use_petscii ; Source is PETSCII.
            tya                         ; Get original character.
            and #$7F                    ; Ignore high bit.
            cmp #NEWLINE                ; Is it carriage return?
            bne +                       ; No, print in quote mode.
            tya                         ; Get original character.
            clc                         ; Clear carry.
            adc #"m"-13                 ; Translate to "M".
            jsr C64.RvsCharOut          ; Print in reverse.
            bcc done
+           tya                         ; Get original character.
quote_mode  jsr C64.QuotedCharOut       ; Print it in quote mode.
            bcc done

use_pokes   ; Source is poke code.
            tya                         ; Get original character.
            jsr C64.PokeToPet           ; Convert poke to PETSCII.
            bcc quote_mode              ; Print normal.
            jsr C64.RvsCharOut          ; Print in reverse. Done.
done        .FRAME.Free
            clc                         ; Always succes.
            rts                         ; Done.
            .endproc

;--------------------------------------
QuoteOut    .proc
            pha                         ; Protect A.
            lda #'"'                    ; Quote character.
            jsr CharOut                 ; Show it; this starts quote mode.
            lda #0                      ; Quote mode off value.
            sta C64.QMODE               ; Quote mode off.
            pla                         ; Restore A
            clc                         ; Always success.
            rts                         ; Done.
            .endproc

;-------------------------------------
Newline     .proc
            pha                         ; Protect A.
            lda #NEWLINE                ; Newline character.
            jsr C64.CHROUT              ; Show it.
            pla                         ; Restore A
            clc                         ; Always success.
            rts                         ; Done.
            .endproc

;-------------------------------------
Overwrite   .proc
            lda #NEWLINE                ; Move to beginning of next line.
            jsr CharOut                 ; Do it.
            lda #C64.PETSCII.UP         ; Then move up.
            bne CharOut                 ; Do it.
            .endproc

;--------------------------------------
CharIn      .proc
            .locals                     ; Protect all registers using frame.
            .endlocals
            .FRAME.Alloc
            jsr C64.CHRIN               ; Input one key.
            tsx                         ; Get frame reference.
            sta arg_a,x                 ; Save key in return A.
            .FRAME.Free                 ; Restore registers.
            clc                         ; Always success.
            rts                         ; Done.
            .endproc

;--------------------------------------
StopKeyIn   .proc
            pha                         ; Protect A.
            lda #128                    ; 128 to add.
            clc                         ; Clear carry for math.
            adc C64.STKEY               ; Add 128 to stop key value.
            sta Tr6                     ; Save sum.
            pla                         ; Restore A.
            ; If the stop key was pressed, C64.STKEY was 127.
            ; By adding 128 it will be 255.
            ; We can then test this by incrementing which would result in 0.
            inc Tr6                     ; If Tr6=255 then ZF=1
            clc                         ; Success.
            rts                         ; Done.
            .endproc

;---------------------------------------
NormalizeBrk .proc
            sei                         ; Disable interrupts.
            ldw a,y,C64.BRKVEC          ; Get existing (kernel) handler.
            stw a,y,RAM.OldBrk          ; Save it.
            lea a,y,C64.BrkNormalizer   ; Get normalizer.
            stw a,y,C64.BRKVEC          ; Install it.
            cli                         ; Enable interrupts.
            clc
            rts                         ; Done.
            .endproc

;---------------------------------------
RestoreBrk  .proc
            sei                         ; Disable interrupts.
            ldw a,y,RAM.OldBrk          ; Get original (kernel) handler.
            stw a,y,C64.BRKVEC          ; Install it.
            cli                         ; Enable interrupts.
            clc
            rts                         ; Done.
            .endproc

;---------------------------------------
VisualizeBrk .proc
            sta Tr6                     ; Protect A
            lda C64_BSS.OldColor        ; Preload "normal" border.
            cpx #BRK_RESET              ; Reset requested?
            beq setcolor                ; Yes, set "normal" border.
            lda C64.VICII.Border        ; Get current border.
            sta C64_BSS.OldColor        ; Save it as "normal".
            cpx #BRK_STEP               ; User is stepping?
            beq +                       ; Yes, no border change.
            cpx #BRK_INIT               ; Initialization requested?
            beq +                       ; Yes, done.
            lda #C64.VICII.YELLOW       ; User breakpoint border.
            cpx #BRK_USER               ; Hit a user breakpoint?
            beq setcolor                ; Yes, set user breakpoint border.
            lda #C64.VICII.RED          ; Anything else shows fire border.
setcolor    sta C64.VICII.Border        ; Change border.
+           lda Tr6                     ; Restore A.
            clc
            rts                         ; Done.
            .endproc

;---------------------------------------
TerminalReset .proc
            ; Save all registers.
            pha
            txa
            pha
            tya
            pha
            ldx #0                      ; Keyboard channel.
            jsr C64.CHKIN               ; Select for input.
            ldx #3                      ; Screen channel.
            jsr C64.CHKOUT              ; Select for output.
            ; Restore all registers.
            pla
            tay
            pla
            tax
            pla
            clc
            rts
            .endproc

range_error .Escape ERROR.Range
syntax_error .Escape ERROR.Syntax
io_error    .Escape ERROR.Io

;---------------------------------------
;
; jsr PLATFORM.Save (required)
;
;   "filename" , device , start , end
;
; Saves data to a device.
;
; IN:       A = number of args supplied.
;           Arg0 = Memory end address.
;           Arg1 = Memory start address.
;           Arg2 = Device number.
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
; OUT:      CF = success.
;
; SAFE:     None.
;

;---------------------------------------
Save        .proc

            cmp #3                      ; 3 args required.
            bne syntax_error            ; Didn't have 3 args.
            lda Arg2.hi                 ; Get device address hi.
            bne range_error             ; Error, hi must be 0 for device num.
            lda Arg2.lo                 ; Get device address lo.
            cmp #1
            bcc range_error             ; Error, device should be at least 1.

            lea x,y,RAM.String          ; Filename address.
            lda RAM.StrLen              ; Length of filename.
            jsr C64.SETNAM              ; Call kernel to set filename.
            lda Arg2.lo                 ; Get primary address (device number).
            ldy #$FF                    ; No secondary address.
            tax                         ; Copy device number to file number.
            jsr C64.SETLFS              ; Call kernel to set I/O addresses.
            lda #Arg1                   ; Start address (zero page).
            ldw x,y,Arg0                ; End address.
            ; Increment end address by 1.
            inx                         ; Increment lo.
            bne +                       ; No wrap, no carry.
            iny                         ; Carry to hi.
+           jsr C64.SAVE                ; Perform the save.
            lda C64.STATUS              ; Get status.
            pha                         ; Save for later.
            lda #0                      ; Reset filename to null.
            jsr C64.SETNAM              ; Call kernel to set it.
            pla                         ; Restore status.
            bmi io_error                ; Status bit 7 indicated error.
            clc
            rts                         ; Done.

            .endproc

            ; a,x = device number
check_devnum .proc
            cpx #0
            bne range_error             ; Error, hi must be 0 for device num.
            cmp #1
            bcc range_error             ; Error, device should be at least 1.
            rts
            .endproc

;---------------------------------------
;
; jsr PLATFORM.Verify (required)
;
; Compares data in memory with a file.
;
; If anything goes wrong the routine escapes with an appropriate error.
;
; IN:       A = number of Args specified by user.
;           X = IO_VERIFY
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
; OUT:      ZF = memory and file match.
;           CF = 0.
;
; SAFE:     None.
;
Verify      .proc
            cmp #1                      ; 1 arg - native
            bne syntax_error
            .endproc
            ; Intentional fall-thru.

;---------------------------------------
;
; jsr PLATFORM.Load (required)
;
;   "filename" , device ( , start , end  )
;
; Loads data from a device.
;
; IN:       A = number of args supplied.
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
;           1 arg = native target:
;               Arg0 = Device number.
;
;           2 args = relocated target:
;               Arg0 = Memory start address.
;               Arg1 = Device number.
;
; OUT:      CF = success.
;
; SAFE:     None.
;

;---------------------------------------
Load        .proc

            cmp #1                      ; 1 arg - native
            beq +
            cmp #2                      ; 2 args - relocated
            bne syntax_error            ; Neither form was used.

+           sta Vr0                     ; Stash arg count.
            stx Vr1                     ; Stash operation.
            ; Preload for native I/O addressing.
            ldw a,x,Arg0                ; Device for native load.
            ldy #1                      ; Secondary address for native.
            dec Vr0                     ; Convert arg count to ZF=native.
            beq +                       ; It's native, skip relocated init.
            ; Initialize relocated I/O addressing.
            ldw a,x,Arg1                ; Device for relocated load.
            ldy #0                      ; Secondary address for relocated.

+           jsr check_devnum            ; Validate device number.
            tax                         ; Copy device number to file number.
            jsr C64.SETLFS              ; Call kernel to set I/O addresses.
            lea x,y,RAM.String          ; Filename address.
            lda RAM.StrLen              ; Length of filename.
            jsr C64.SETNAM              ; Call kernel to set filename.
            lda Vr0                     ; Native load?
            beq +                       ; Yes, skip address initialize.
+           ; Select Load or Verify
            lda #0                      ; Assume load.
            ldx Vr1
            cpx #IO_LOAD                ; Is it load?
            beq +                       ; Yes.
            lda #1                      ; No, it's verify.
+           ldw x,y,Arg0                ; Load address (ignored for native).
            jsr C64.LOAD                ; Perform the load.
            lda C64.STATUS              ; Get status.
            and #$B3                    ; Magic - See prog ref BASIC STATUS.
            pha                         ; Save for later.
            lda #0                      ; Reset filename to null.
            jsr C64.SETNAM              ; Call kernel to set it.
            pla                         ; Restore status.
            bmi io_error                ; Status bit 7 indicated error.
            and #$30                    ; More magic - set ZF=ok.
            clc
            rts                         ; Done.

range_error .Escape ERROR.Range
syntax_error .Escape ERROR.Syntax
io_error    .Escape ERROR.Io
            .endproc
;---------------------------------------
LoadPriEncName .proc
            lea x,y,C64_DATA.PetsciiName
            clc
            rts
            .endproc

;---------------------------------------
LoadAltEncName .proc
            lea x,y,C64_DATA.PokesName
            clc
            rts
            .endproc


            .endblock ; PLATFORM


;                          _       _
;                         | |     | |
;                       __| | __ _| |_ __ _
;                      / _` |/ _` | __/ _` |
;                     | (_| | (_| | || (_| |
;                      \__,_|\__,_|\__\__,_|
;
; Platform specific onstant data.
;
.elsif SECTION="data"

C64_DATA    .block
PetsciiName .null "petscii"
PokesName   .null "poke codes"
            .endblock ; DATA

;                      _
;                     | |
;                     | |__  ___ ___
;                     | '_ \/ __/ __|
;                     | |_) \__ \__ \
;                     |_.__/|___/___/
;
; RAM reserved for platform specific usage.
;
.elsif SECTION="bss"

BSS_BASE

C64_BSS     .block
OldColor    .byte ?         ; Original border color.
; Used to backup zero page address that we commandeer.
ZpBackup    .rept ZpEnd64-ZpStart64
            .byte ?
            .endrept
            .endblock ; BSS

.endif ; SECTION