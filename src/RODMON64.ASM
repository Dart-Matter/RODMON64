
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

debug       = false
SECTION     := "header"
            .include "PLATFORM.ASM"

;                                    _
;                                   | |
;                       ___ ___   __| | ___
;                      / __/ _ \ / _` |/ _ \
;                     | (_| (_) | (_| |  __/
;                      \___\___/ \__,_|\___|
;
; The code section must produce only linear instructions otherwise data
; declarations, or instructions embedded in operands may be corrupted
; when the binary is relocated.  This section should not contain data
; or instruction embedded within operands.
;

;--------------------------------------
;
; ENTRY POINT
;
; SYS to this address to start the monitor.
;
            * = 16384 ; $4000

SECTION     := "code"
CODE_BASE

            jmp RODMON.Start


.if PLATFORMID = "C64"
            ; SYS base + 3
            jmp PLATFORM.HomeA000
.endif

;--------------------------------------
;
; MONITOR GUTS
;
            .include "TYPES.ASM"
            .include "PLATFORM.ASM"
            .include "UTIL.ASM"
            .include "FRAME.ASM"
            .include "ERROR.ASM"
            .include "ESCAPE.ASM"
            .include "ARGS.ASM"
            .include "PRINT.ASM"
            .include "INPUT.ASM"
            .include "DUMPCORE.ASM"
            .include "DASM.ASM"
            .include "BREAKS.ASM"
            .include "REGDUMP.ASM"
            .include "GO.ASM"
            .include "CALC.ASM"
            .include "UNOMODE.ASM"
            .include "COBYMODE.ASM"
            .include "CHARDUMP.ASM"
            .include "CHARMODE.ASM"
            .include "CONVERT.ASM"
            .include "UNASM.ASM"
            .include "MEMDUMP.ASM"
            .include "ASM.ASM"
            .include "MEMEDIT.ASM"
            .include "REGEDIT.ASM"
            .include "STEPCORE.ASM"
            .include "WALK.ASM"
            .include "JUMP.ASM"
            .include "COBYASM.ASM"
            .include "HUNT.ASM"
            .include "INIT.ASM"
            .include "TRANSFER.ASM"
            .include "OPADJUST.ASM"
            .include "NEWHOME.ASM"
            .include "STORAGE.ASM"
            .include "ABOUT.ASM"
            .include "COMMAND.ASM"


;--------------------------------------
;
; Entry and exit routines.
;
RODMON      .block


;--------------------------------------
;
; JMP RODMON.Start
;
; Begin monitor.
;
Start       ; The first thing to do is freeze monitor caller state so that we
            ; can return back to them if desired.  To return back jump to
            ; ExitToCaller.
            php                         ; Save status registers.
            pha                         ; Save A.
            txa                         ; Save X
            pha                         ;  on stack.
            tya                         ; Save Y
            pha                         ;  on stack.
            tsx                         ; Save stack pointer
            stx RAM.RetSp               ;  to RAM

            ; Initialize miscellaneous RAM.
            ldx #0
            stx RAM.CharBuf

            ; Initialize features.
features    = RAM.FLAG.CODEBYTES + RAM.FLAG.UNOFFICIAL + RAM.FLAG.PETSCII
            lda #features
            sta RAM.Features

            ; Initialize resume address.
            lea a,y,default_resume
            stw a,y,RAM.Resume

            ; Save zero page pointers.
            jsr PLATFORM.BackupZp

            ; Clear user and step breakpoints.
            jsr BREAKPOINTS.ClearAllUser
            jsr BREAKPOINTS.ClearStep
            jsr REGISTERS.Initialize

            ; Initialize BRK visualization.
            ldx #BRK_INIT
            jsr PLATFORM.VisualizeBrk

            ; Install BRK handlers.
            lea a,y,EscapeHandler
            jsr SetBrkHandler
            jsr PLATFORM.NormalizeBrk

            sec ; Show banner.
            jmp COMMANDS.Start


;---------------------------------------
;
; JMP RODMON.Exit
;
; Exit to original caller.
;
; Returns to the original caller of the monitor.
;
Exit        .proc
            jsr PLATFORM.RestoreZp      ; Restore zero page that we took over.
            jsr PLATFORM.RestoreBrk     ; Restore original BRK handling.
            ldx RAM.RetSp               ; Get original stack pointer.
            txs                         ; Restore stack pointer.
            pla                         ; Restore Y.
            tay
            pla                         ; Restore X.
            tax
            pla                         ; Restore A.
            plp                         ; Restore status flags.
            rts                         ; Return to monitor caller.
            .endproc


;---------------------------------------
;
; INSTALL THE ESCAPE HANDLER.
;
SetBrkHandler .proc
            sei                         ; Disable interrupts.
            stw a,y,RAM.MonBrk          ; Install new handler.
            cli                         ; Re-enable interrupts.
            rts                         ; Done.
            .endproc


            .endblock ; RODMON


CODE_SIZE   = * - CODE_BASE
CODE_END    = * - 1


;                          _       _
;                         | |     | |
;                       __| | __ _| |_ __ _
;                      / _` |/ _` | __/ _` |
;                     | (_| | (_| | || (_| |
;                      \__,_|\__,_|\__\__,_|
;
; The data section is initialized memory that may contain anything, however, it
; may not contain references to other sections.  Code must be self relocatable
; or not self-referencing (e.g. relative, referencing zero-page, or
; referencing chip registers.)
;

SECTION := "data"
DATA_BASE
            .include "COMMAND.ASM"
            .include "STRINGS.ASM"
            .include "MPU6502.ASM"
            .include "PLATFORM.ASM"
DATA_SIZE   = * - DATA_BASE
DATA_END    = * - 1

ROM_SIZE    = CODE_SIZE + DATA_SIZE

;                      _             
;                     | |            
;                     | |__  ___ ___ 
;                     | '_ \/ __/ __|
;                     | |_) \__ \__ \
;                     |_.__/|___/___/
;                                               
; The bss section is uninitialized working RAM.  Code beyond this point should
; only generate allocations of the working RAM.  There should be no actual code
; or data generated here, therefore, it will not take up space in the program
; image.  This section can be relocated by virtue of changing references in the
; previous sections; i.e. this section should not be copied when relocating
; at runtime.
;
SECTION := "bss"
            .include "PLATFORM.ASM"
            .include "RAM.ASM"
BSS_SIZE   = * - BSS_BASE
BSS_END     = * - 1

