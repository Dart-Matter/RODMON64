
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
; RAM CLASS
;
; The RAM class contains all of the RAM declared specifically for use
; by the monitor, and helpers for using it.
;


RAM         .block


;-------------------------------------
;
; RAM.FLAGS
;
FLAG        .block


;;---------------------------------
;;
;; FEATURES FLAGS
;;
;; Used with RAM.Features.
;;
CODEBYTES   = %00000001     ;; Enables display of code bytes.
UNOFFICIAL  = %00000010     ;; Enables unofficial instructions.
PETSCII     = %00000100     ;; Dump characters as PETSCII not poke codes.


;----------------------------------
;
; BREAKPOINT FLAGS
;
; Used with RAM.BrkFlags.
;

; User breakpoints are active.
BRKUSER = %10000000 ; bmi/bpl

; Step breakpoints are active.
BRKSTEP = %01000000 ; bvs/bvc

            .endblock ; FLAG


;;-------------------------------------
;;
;; RAM ASSIGNMENT
;;
RetSp       .byte ?         ;; Monitor callers stack position.
OldIrq      .word ?         ;; Original system IRQ vector.
OldBrk      .word ?         ;; Original system BRK vector.
Resume      .word ?        ;; Default address to resume next command at.
Features    .byte ?         ;; Storage for feature flags.
CharBuf     .byte ?         ; One character buffer for keyboard unget.
DebugNum    .byte ?         ; Used for outputting debugging waypoints.
            .align_vector
MonBrk      .word ?         ;; Monitor BRK handler for platform to call.

;;
;; Instruction inspection results.
INSPECT     .block          ;;
ptr         .SWORD ?        ;; Memory address.
opcode      .byte  ?        ;; Opcode.
data        .SWORD ?        ;; Operand bytes.
opdecl      .byte  ?        ;; OPTABLE entry.
mode        .byte  ?        ;; Addressing mode.
size        .byte  ?        ;; Instruction size.
name        .fill  3        ;; Mnemonic.
null        .byte  ?        ;; Null terminate byte for name.
            .endblock ; INSPECT

BrkFlags    .byte ?         ;; Storage for breakpoint flags.

; Storage for breakpoint addresses.
BrkPts      .SWORD ?        ; Breakpoint 1
            .SWORD ?        ; Breakpoint 2
            .SWORD ?        ; Breakpoint 3
            .SWORD ?        ; Breakpoint 4
            .SWORD ?        ; Breakpoint 5
            .SWORD ?        ; Breakpoint 6
            .SWORD ?        ; Breakpoint 7
            .SWORD ?        ; Breakpoint 8
            .SWORD ?        ; Breakpoint 9
StepPoint1  .SWORD ?        ; Next instruction.
StepPoint2  .SWORD ?        ; Branch target.

; Storage for original instructions.
BrkSav      .byte ?         ; Breakpoint 1
            .byte ?         ; Breakpoint 2
            .byte ?         ; Breakpoint 3
            .byte ?         ; Breakpoint 4
            .byte ?         ; Breakpoint 5
            .byte ?         ; Breakpoint 6
            .byte ?         ; Breakpoint 7
            .byte ?         ; Breakpoint 8
            .byte ?         ; Breakpoint 9
BrkLen      = * - BrkSav

StepIndex1  = * - BrkSav
StepSave1   .byte ?         ; Next instruction.
StepIndex2  = * - BrkSav
StepSave2   .byte ?         ; Branch target.

;;
;; Monitor state registers.

; PC cannot be at $xxFF (cross page boundary indirect jump).
            .align_vector
REGS        .block          ;;
            .REGS_S
            .endblock

REGS_S      .segment        ;;
pc          .SWORD ?        ;;
a           .byte ?         ;;
x           .byte ?         ;;
y           .byte ?         ;;
flags       .byte ?         ;;
sp          .byte ?         ;;
            .endsegment

StrLen      .byte ?
String      .rept 16
            .byte ?
            .endrept

END         = * - 1


            .endblock ; RAM
