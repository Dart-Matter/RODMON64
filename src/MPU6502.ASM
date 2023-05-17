
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
; Contains 6502 architecture definitions.
;
MPU6502     .block


; Constants
STACK       = $100      ; Bottom of stack.
CF          = %00000001 ; Carry status bit.
ZF          = %00000010 ; Zero status bit.
IF          = %00000100 ; IRQ status bit.
DF          = %00001000 ; BCD status bit.
BF          = %00010000 ; BRK status bit.
VF          = %01000000 ; Overflow status.
NF          = %10000000 ; Minus status bit.


;--------------------------------------
;
; The following defines the available assembler mnemonics.
;

.comment
        ______________________________________________________________________

        IMPORTANT: This macro requires a modified 64tass.exe that allows the
        tasm @ references to work for substitution inside quotes without using
        the tasm-compatible switch.  It has the following change in macro.c:

                case '@':
            if (1) { // (arguments.tasmcomp) {  <--- i.e. Always
                /* text parameter reference */
        ______________________________________________________________________

        Each mnemonic is declared as a packed string and a flag to designate
        undocumented instructions.
                 _______________________________
                |u|  char3  |  char2  |  char1  |     E=Undocumented mnemonic
                |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
                |               |               |

        u = Unofficial instruction (0 or 1)
        cn = Characters (a..z)

.endcomment

UNOFFICIAL  = %10000000

;
; This is the magic macro that encodes the declaration.
;
MNEMONIC    .segment  undocumented, mnemonic
mn_@2       = (* - MNTABLE) / 2
            .byte   ((@1&1) * UNOFFICIAL) | (("@2"[2] & %011111) * 4) | (("@2"[1] & %011111) / 8)
            .byte   (("@2"[1] & %0111) * 32) | ("@2"[0] & %011111)
            .endm

;
; The declarations.
;
MNTABLE
            #MNEMONIC 0, adc
            #MNEMONIC 0, and
            #MNEMONIC 0, asl
            #MNEMONIC 0, bcc
            #MNEMONIC 0, bcs
            #MNEMONIC 0, beq
            #MNEMONIC 0, bit
            #MNEMONIC 0, bmi
            #MNEMONIC 0, bne
            #MNEMONIC 0, bpl
            #MNEMONIC 0, brk
            #MNEMONIC 0, bvc
            #MNEMONIC 0, bvs
            #MNEMONIC 0, clc
            #MNEMONIC 0, cld
            #MNEMONIC 0, cli
            #MNEMONIC 0, clv
            #MNEMONIC 0, cmp
            #MNEMONIC 0, cpx
            #MNEMONIC 0, cpy
            #MNEMONIC 0, dec
            #MNEMONIC 0, dex
            #MNEMONIC 0, dey
            #MNEMONIC 0, eor
            #MNEMONIC 0, inc
            #MNEMONIC 0, inx
            #MNEMONIC 0, iny
            #MNEMONIC 0, jmp
            #MNEMONIC 0, jsr
            #MNEMONIC 0, lda
            #MNEMONIC 0, ldx
            #MNEMONIC 0, ldy
            #MNEMONIC 0, lsr
            #MNEMONIC 0, nop
            #MNEMONIC 0, ora
            #MNEMONIC 0, pha
            #MNEMONIC 0, php
            #MNEMONIC 0, pla
            #MNEMONIC 0, plp
            #MNEMONIC 0, rol
            #MNEMONIC 0, ror
            #MNEMONIC 0, rti
            #MNEMONIC 0, rts
            #MNEMONIC 0, sbc
            #MNEMONIC 0, sec
            #MNEMONIC 0, sed
            #MNEMONIC 0, sei
            #MNEMONIC 0, sta
            #MNEMONIC 0, stx
            #MNEMONIC 0, sty
            #MNEMONIC 0, tax
            #MNEMONIC 0, tay
            #MNEMONIC 0, tsx
            #MNEMONIC 0, txa
            #MNEMONIC 0, txs
            #MNEMONIC 0, tya

            ; Undocumented 6510 instructions.
            ; *NOTE: AND operand MSB+1 may not happen.

            #MNEMONIC 1, ans    ; AND SP with op then load into A,X,SP (las/lar)
            #MNEMONIC 1, arr    ; AND then ROR
            #MNEMONIC 1, asc    ; AND then set carry from bit 7
            #MNEMONIC 1, asr    ; AND then LSR
            #MNEMONIC 1, axs    ; AND X with A then subtract operand
            #MNEMONIC 1, dcp    ; DEC then CMP
            #MNEMONIC 1, isc    ; INC then SBC
            #MNEMONIC 1, jam    ; Freeze CPU
            #MNEMONIC 1, lax    ; LDA then LDX
            #MNEMONIC 1, nap    ; Sleep (alternate NOP)
            #MNEMONIC 1, rla    ; ROL then AND
            #MNEMONIC 1, rra    ; ROR then ADC
            #MNEMONIC 1, sax    ; Store A AND X
            #MNEMONIC 1, sbn    ; SBC then NOP
            #MNEMONIC 1, sha    ; Store A AND X AND operand MSB+1*
            #MNEMONIC 1, shs    ; Transfer A AND X to SP then store SP AND operand MSB+1*
            #MNEMONIC 1, shx    ; Store X AND operand MSB+1*
            #MNEMONIC 1, shy    ; Store Y AND operand MSB+1*
            #MNEMONIC 1, slo    ; ASL then ORA
            #MNEMONIC 1, sre    ; LSR then EOR
            .byte 0 ; end of list

;
; Every opcode declared with mnemonic and flag indicating if it is undocumented.
;
.comment
        _______________
       |E|mnemonic idx | E=Undocumented instruction
       |_|_|_|_|_|_|_|_|

.endcomment

OPCODE      .segment unofficial, mn_index
            .byte   ((@1&1) * UNOFFICIAL) | (mn_@2 & ~UNOFFICIAL)
            .endm

; Indicates that an opcode is neither a valid nor undocumented instruction.
OPNODEF     = $FF

OPNONE      .macro
            .byte OPNODEF
            .endm

;
; The declarations.
;
OPTABLE
            ; 0x
            #OPCODE 0, brk
            #OPCODE 0, ora
            #OPCODE 1, jam
            #OPCODE 1, slo
            #OPCODE 1, nap
            #OPCODE 0, ora
            #OPCODE 0, asl
            #OPCODE 1, slo

            #OPCODE 0, php
            #OPCODE 0, ora
            #OPCODE 0, asl
            #OPCODE 1, asc
            #OPCODE 1, nap
            #OPCODE 0, ora
            #OPCODE 0, asl
            #OPCODE 1, slo

            ; 1x
            #OPCODE 0, bpl
            #OPCODE 0, ora
            #OPCODE 1, jam
            #OPCODE 1, slo
            #OPCODE 1, nap
            #OPCODE 0, ora
            #OPCODE 0, asl
            #OPCODE 1, slo

            #OPCODE 0, clc
            #OPCODE 0, ora
            #OPCODE 1, nap
            #OPCODE 1, slo
            #OPCODE 1, nap
            #OPCODE 0, ora
            #OPCODE 0, asl
            #OPCODE 1, slo

            ; 2x
            #OPCODE 0, jsr
            #OPCODE 0, and
            #OPCODE 1, jam
            #OPCODE 1, rla
            #OPCODE 0, bit
            #OPCODE 0, and
            #OPCODE 0, rol
            #OPCODE 1, rla

            #OPCODE 0, plp
            #OPCODE 0, and
            #OPCODE 0, rol
            #OPCODE 1, asc
            #OPCODE 0, bit
            #OPCODE 0, and
            #OPCODE 0, rol
            #OPCODE 1, rla

            ; 3x
            #OPCODE 0, bmi
            #OPCODE 0, and
            #OPCODE 1, jam
            #OPCODE 1, rla
            #OPCODE 1, nap
            #OPCODE 0, and
            #OPCODE 0, rol
            #OPCODE 1, rla

            #OPCODE 0, sec
            #OPCODE 0, and
            #OPCODE 1, nap
            #OPCODE 1, rla
            #OPCODE 1, nap
            #OPCODE 0, and
            #OPCODE 0, rol
            #OPCODE 1, rla

            ; 4x
            #OPCODE 0, rti
            #OPCODE 0, eor
            #OPCODE 1, jam
            #OPCODE 1, sre
            #OPCODE 1, nap
            #OPCODE 0, eor
            #OPCODE 0, lsr
            #OPCODE 1, sre

            #OPCODE 0, pha
            #OPCODE 0, eor
            #OPCODE 0, lsr
            #OPCODE 1, asr
            #OPCODE 0, jmp
            #OPCODE 0, eor
            #OPCODE 0, lsr
            #OPCODE 1, sre

            ; 5x
            #OPCODE 0, bvc
            #OPCODE 0, eor
            #OPCODE 1, jam
            #OPCODE 1, sre
            #OPCODE 1, nap
            #OPCODE 0, eor
            #OPCODE 0, lsr
            #OPCODE 1, sre

            #OPCODE 0, cli
            #OPCODE 0, eor
            #OPCODE 1, nap
            #OPCODE 1, sre
            #OPCODE 1, nap
            #OPCODE 0, eor
            #OPCODE 0, lsr
            #OPCODE 1, sre

            ; 6x
            #OPCODE 0, rts
            #OPCODE 0, adc
            #OPCODE 1, jam
            #OPCODE 1, rra
            #OPCODE 1, nap
            #OPCODE 0, adc
            #OPCODE 0, ror
            #OPCODE 1, rra

            #OPCODE 0, pla
            #OPCODE 0, adc
            #OPCODE 0, ror
            #OPCODE 1, arr
            #OPCODE 0, jmp
            #OPCODE 0, adc
            #OPCODE 0, ror
            #OPCODE 1, rra

            ; 7x
            #OPCODE 0, bvs
            #OPCODE 0, adc
            #OPCODE 1, jam
            #OPCODE 1, rra
            #OPCODE 1, nap
            #OPCODE 0, adc
            #OPCODE 0, ror
            #OPCODE 1, rra

            #OPCODE 0, sei
            #OPCODE 0, adc
            #OPCODE 1, nap
            #OPCODE 1, rra
            #OPCODE 1, nap
            #OPCODE 0, adc
            #OPCODE 0, ror
            #OPCODE 1, rra

            ; 8x
            #OPCODE 1, nap
            #OPCODE 0, sta
            #OPCODE 1, nap
            #OPCODE 1, sax
            #OPCODE 0, sty
            #OPCODE 0, sta
            #OPCODE 0, stx
            #OPCODE 1, sax

            #OPCODE 0, dey
            #OPCODE 1, nap
            #OPCODE 0, txa
            #OPNONE
            #OPCODE 0, sty
            #OPCODE 0, sta
            #OPCODE 0, stx
            #OPCODE 1, sax

            ; 9x
            #OPCODE 0, bcc
            #OPCODE 0, sta
            #OPCODE 1, jam
            #OPCODE 1, sha
            #OPCODE 0, sty
            #OPCODE 0, sta
            #OPCODE 0, stx
            #OPCODE 1, sax

            #OPCODE 0, tya
            #OPCODE 0, sta
            #OPCODE 0, txs
            #OPCODE 1, shs
            #OPCODE 1, shy
            #OPCODE 0, sta
            #OPCODE 1, shx
            #OPCODE 1, sha

            ; Ax
            #OPCODE 0, ldy
            #OPCODE 0, lda
            #OPCODE 0, ldx
            #OPCODE 1, lax
            #OPCODE 0, ldy
            #OPCODE 0, lda
            #OPCODE 0, ldx
            #OPCODE 1, lax

            #OPCODE 0, tay
            #OPCODE 0, lda
            #OPCODE 0, tax
            #OPNONE
            #OPCODE 0, ldy
            #OPCODE 0, lda
            #OPCODE 0, ldx
            #OPCODE 1, lax

            ; Bx
            #OPCODE 0, bcs
            #OPCODE 0, lda
            #OPCODE 1, jam
            #OPCODE 1, lax
            #OPCODE 0, ldy
            #OPCODE 0, lda
            #OPCODE 0, ldx
            #OPCODE 1, lax

            #OPCODE 0, clv
            #OPCODE 0, lda
            #OPCODE 0, tsx
            #OPCODE 1, ans
            #OPCODE 0, ldy
            #OPCODE 0, lda
            #OPCODE 0, ldx
            #OPCODE 1, lax

            ; Cx
            #OPCODE 0, cpy
            #OPCODE 0, cmp
            #OPCODE 1, nap
            #OPCODE 1, dcp
            #OPCODE 0, cpy
            #OPCODE 0, cmp
            #OPCODE 0, dec
            #OPCODE 1, dcp

            #OPCODE 0, iny
            #OPCODE 0, cmp
            #OPCODE 0, dex
            #OPCODE 1, axs
            #OPCODE 0, cpy
            #OPCODE 0, cmp
            #OPCODE 0, dec
            #OPCODE 1, dcp

            ; Dx
            #OPCODE 0, bne
            #OPCODE 0, cmp
            #OPCODE 1, jam
            #OPCODE 1, dcp
            #OPCODE 1, nap
            #OPCODE 0, cmp
            #OPCODE 0, dec
            #OPCODE 1, dcp

            #OPCODE 0, cld
            #OPCODE 0, cmp
            #OPCODE 1, nap
            #OPCODE 1, dcp
            #OPCODE 1, nap
            #OPCODE 0, cmp
            #OPCODE 0, dec
            #OPCODE 1, dcp

            ; Ex
            #OPCODE 0, cpx
            #OPCODE 0, sbc
            #OPCODE 1, nap
            #OPCODE 1, isc
            #OPCODE 0, cpx
            #OPCODE 0, sbc
            #OPCODE 0, inc
            #OPCODE 1, isc

            #OPCODE 0, inx
            #OPCODE 0, sbc
            #OPCODE 0, nop
            #OPCODE 1, sbn
            #OPCODE 0, cpx
            #OPCODE 0, sbc
            #OPCODE 0, inc
            #OPCODE 1, isc

            ; Fx
            #OPCODE 0, beq
            #OPCODE 0, sbc
            #OPCODE 1, jam
            #OPCODE 1, isc
            #OPCODE 1, nap
            #OPCODE 0, sbc
            #OPCODE 0, inc
            #OPCODE 1, isc

            #OPCODE 0, sed
            #OPCODE 0, sbc
            #OPCODE 1, nap
            #OPCODE 1, isc
            #OPCODE 1, nap
            #OPCODE 0, sbc
            #OPCODE 0, inc
            #OPCODE 1, isc

;
; Every opcode declared by addressing mode.
;
.comment
         _______________
        |  odd  | even  |     Two instructions per byte
        |_|_|_|_|_|_|_|_|

;-----------------------


        0 . . . = Addressed
        . 1 . . = Zero Page
        . . 1 . = Y
        . . . 1 = X
        . 0 1 1 =   <unused>
        . 1 1 1 = Relative

        1 0 . . = Indirect
        . . 0 0 = ()
        . . 0 1 = (),Y
        . . 1 0 = (,X)
        . . 1 1 =   <unused>

        1 1 . . = Special cases
        . . 0 0 = Implied
        . . 0 1 = Immediate
        . . 1 0 =   <unused>
        . . 1 1 = undefined


.endcomment

; am_order_v2
;
; If you mess with this table, search the source code for "am_order" and
; check for any borken dependencies like order or bit usage.
;

X           = %0001
Y           = %0010
MASKXY      = %11111100

am_abs      = %0000         ; 0
am_abx      = am_abs + X    ; 1
am_aby      = am_abs + Y    ; 2
                            ; 3
am_zp       = %0100         ; 4
am_zpx      = am_zp + X     ; 5
am_zpy      = am_zp + Y     ; 6
am_rel      = %0111         ; 7
am_ind      = %1000         ; 8
am_inx      = am_ind + X    ; 9
am_iny      = am_ind + Y    ; A
                            ; B
am_imp      = %1100         ; C
am_imm      = %1101         ; D
                            ; E
am_none     = %1111         ; F

AMODE       .segment even, odd
            .byte   (\even * 16) | \odd
            .endm

AMTABLE
;   A table that defines the addressing modes for every opcode including
;   invalid and undocumented.

            ; 0x
            #AMODE  am_imp, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; 1x
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_abx, am_abx

            ; 2x
            #AMODE  am_abs, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; 3x
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_abx, am_abx

            ; 4x
            #AMODE  am_imp, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; 5x
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abs, am_abx
            #AMODE  am_abx, am_abx

            ; 6x
            #AMODE  am_imp, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_ind, am_abs
            #AMODE  am_abs, am_abs

            ; 7x
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_abx, am_abx

            ; 8x
            #AMODE  am_imp, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; 9x
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpy, am_zpy
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_aby, am_aby

            ; Ax
            #AMODE  am_imm, am_inx
            #AMODE  am_imm, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; Bx
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpy, am_zpy
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_aby, am_aby

            ; Cx
            #AMODE  am_imm, am_inx
            #AMODE  am_imp, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; Dx
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_abx, am_abx

            ; Ex
            #AMODE  am_imm, am_inx
            #AMODE  am_imm, am_inx
            #AMODE  am_zp, am_zp
            #AMODE  am_zp, am_zp
            #AMODE  am_imp, am_imm
            #AMODE  am_imp, am_imm
            #AMODE  am_abs, am_abs
            #AMODE  am_abs, am_abs

            ; Fx
            #AMODE  am_rel, am_iny
            #AMODE  am_imp, am_iny
            #AMODE  am_zpx, am_zpx
            #AMODE  am_zpx, am_zpx
            #AMODE  am_imp, am_aby
            #AMODE  am_imp, am_aby
            #AMODE  am_abx, am_abx
            #AMODE  am_abx, am_abx


            .endblock ; MPU6502
