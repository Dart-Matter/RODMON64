
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


REGISTERS   .block


;---------------------------------------
;
; IMPLEMENTS THE REGISTER DUMP COMMAND
;
Handler     .proc
            jsr PLATFORM.Overwrite
            lea a,y,STRINGS.reghead     ; Address of register heading.
            jsr PRINT.String            ; Print it.

Format      ; Display formatted registers.
            lda #"*"                    ; Register edit command token.
            jsr PRINT.Char
            ldw a,y,RAM.REGS.pc
            jsr PRINT.Hex.W
            jsr PRINT.Space
            ldw a,y,RAM.OldIrq
            jsr PRINT.Hex.W
            jsr PRINT.Space
            lda RAM.REGS.a
            jsr PRINT.Hex.B
            jsr PRINT.Space
            lda RAM.REGS.x
            jsr PRINT.Hex.B
            jsr PRINT.Space
            lda RAM.REGS.y
            jsr PRINT.Hex.B
            jsr PRINT.Space
            lda RAM.REGS.sp
            ldy #$01                    ; Stack hi is always $01.
            jsr PRINT.Hex.W
            jsr PRINT.Space
            lda RAM.REGS.flags
            jsr PRINT.Binary.B
            jsr PLATFORM.Newline

            ; Disassemble PC instruction.
            jsr PRINT.Semicolon         ; Print remark command token.
            ldy #7                      ; 7 spaces to align a column 8.
            jsr PRINT.SpacesY
            ldw a,y,RAM.REGS.pc         ; Get instruction address.
            jmp DASM.Instruction        ; Disassemble it.  Done.
            .endproc ; Handler


;---------------------------------------
;
; For initializing the state RAM at monitor startup.
;
Initialize .proc

            lda #%00000000
            sta RAM.REGS.flags
            lda #$7F
            sta RAM.REGS.sp
            asl
            sta RAM.REGS.a
            sta RAM.REGS.x
            sta RAM.REGS.y
            lea a,y,default_resume
            stw a,y,RAM.REGS.pc
            rts
            .endproc ; Initialize


            .endblock ; REGISTERS
