
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
; DASM LIBRARY
;
; Routines for disassembling instructions.
;


DASM        .block


;;-------------------------------------
;;
;; JSR DASM.Inspect
;;
;; Get info for an instruction.
;;
;; IN:      A = Instruction address lo byte.
;;          Y = Instruction address hi byte.
;;
;; OUT:     RAM.INSPECT is populated.
;;
;; SAFE:    None.
;;
Inspect     .proc
            stw a,y,RAM.INSPECT.ptr     ; Save address as result.
            stw a,y,Vr3                 ; Save address as zero page pointer.
            ldy #0                      ; Offset 0.
            lda (Vr3),y                 ; Get opcode.
            sta RAM.INSPECT.opcode      ; Save to result.
            iny                         ; Offset 1.
            lda (Vr3),y                 ; Get operand byte 1.
            sta RAM.INSPECT.data.lo     ; Save to result.
            iny                         ; Offset 2.
            lda (Vr3),y                 ; Get operand byte 2.
            sta RAM.INSPECT.data.hi     ; Save to result.
            ; Set mode field.
            lda RAM.INSPECT.opcode      ; Load opcode.
            lsr                         ; Divide by 2 for nybble pair offset.
            php                         ; Save CF = nybble index.
            tax                         ; Copy index to index register.
            lda MPU6502.AMTABLE,x       ; Get addressing mode pair.
            plp                         ; Odd nybble?
            bcs +                       ; Yes, no shift needed.
            ; Shift hi into lo nybble.
            lsr
            lsr
            lsr
            lsr
+           and #%00001111              ; Isolate lo nybble.
            sta RAM.INSPECT.mode        ; Save mode to result.
            ldy #0                      ; Initialize instruction size.

            ; Determine instruction size based on addressing mode.
            tax                         ; Get addressing mode

            ; (am_order_v2)
            cpx #MPU6502.am_aby+1       ; Absolute addressing.
            bcc word_operand

            ; Commented out intentionally:
            ; Save a few bytes since zero page and branches are the same size.
            ; cpx #MPU6502.am_zpy+1       ; Zero page addressing.
            ; bcc byte_operand

            cpx #MPU6502.am_rel+1       ; Branches.
            bcc disp_operand

            cpx #MPU6502.am_ind+1       ; Plain indirect addressing.
            bcc word_operand

            cpx #MPU6502.am_iny+1       ; Indexed indirect addressing.
            bcc byte_operand

            cpx #MPU6502.am_imp+1       ; Implied addressing.
            bcc is_implied

            cpx #MPU6502.am_imm+1       ; Immediate addressing.
            bcc byte_operand

            ; Internal error, unknown mode.
            .Escape ERROR.Bug

word_operand
            iny
byte_operand
disp_operand
            iny
is_implied
            iny

            sty RAM.INSPECT.size        ; Save size to result.

            ; Get instruction mnemonic.
            ldx RAM.INSPECT.opcode      ; Get opcode.
            lda MPU6502.OPTABLE,x       ; Get opcode declaration.
            sta RAM.INSPECT.opdecl      ; Store declaration in result.
            cmp #MPU6502.OPNODEF        ; Is it a valid instruction?
            bne if_uno                  ; Yes.
noname      ; Mnemonic is " ? "
            lda #' '
            sta RAM.INSPECT.name + 0
            sta RAM.INSPECT.name + 2
            lda #'?'
            sta RAM.INSPECT.name + 1
            rts                         ; Done.

if_uno      ora #0                      ; Is it unofficial (sighn bit)?
            bpl unpack                  ; No.
            ; Unofficial instruction, check if they are enabled.
            lda #RAM.FLAG.UNOFFICIAL    ; Unofficial feature flag.
            bit RAM.Features            ; Is it set?
            beq noname                  ; No.  Treat as undefined.
            lda RAM.INSPECT.opdecl

unpack      and #%01111111              ; Mask off unofficial bit.
            asl                         ; Convert name index to string offset.
            tax                         ; Copy index to index register.
            lda MPU6502.MNTABLE + 0,x   ; Get packed byte #1.
            sta Tr6                     ; Save it.
            lda MPU6502.MNTABLE + 1,x   ; Get packed byte #2.
            ldx #0                      ; Null terminator and output index.
            stx RAM.INSPECT.name + 3    ; Save to result as terminator.
            jsr up2                     ; Grab lower character.
            jsr up1                     ; Shift and grab lower.
up1         ; Shift pair right 5 bits.
            lsr Tr6
            ror
            lsr Tr6
            ror
            lsr Tr6
            ror
            lsr Tr6
            ror
            lsr Tr6
            ror
up2         ; Grab lower character.
            tay                         ; Save byte with next char.
            and #$1F                    ; Mask upper 3 bits.
            ora #$40                    ; Translate to PETSCII.
            sta RAM.INSPECT.name,x      ; Save it to result.
            inx                         ; Next output index.
            tya                         ; Restore byte with the next char.
            rts

            .endproc ; Inspect


;;-------------------------------------
;;
;; JSR DASM.Instruction
;;
;; Pretty prints an instruction.
;;
;; IN:      A = Instruction address lo byte.
;;          Y = Instruction address hi byte.
;;
;; OUT:     X = Instruction byte count.
;;
;; SAFE:    None.
;;
Instruction .proc
            jsr Inspect


;;-------------------------------------
;;
;; JSR DASM.Inspected
;;
;; Pretty prints an instruction that has already been inspected.
;;
;; IN:      None.
;;
;; OUT:     None.
;;          X = Instruction byte count.
;;
;; SAFE:    None.
;;
Inspected
            ; Print mnemonic.
            lea a,y,RAM.INSPECT.name
            jsr PRINT.String
            jsr PRINT.Space
            ; Continue if defined.
            lda RAM.INSPECT.opdecl      ; Get opcode declaration.
            cmp #MPU6502.OPNODEF        ; Defined?
            bne select_format           ; Yes.
return      ldx RAM.INSPECT.size        ; Return instruction size.
            rts

            ; Determine the instruction format based on addressing  mode.
select_format
            ldx RAM.INSPECT.mode
            txa                         ; Copy mode for later use.

            ; (am_order_v2)
            cpx #MPU6502.am_aby+1       ; Absolute addressing.
            bcc abs_hop

            cpx #MPU6502.am_zpy+1       ; Zero page addressing.
            bcc zp_hop

            cpx #MPU6502.am_rel+1       ; Branches.
            bcc relative_op

            cpx #MPU6502.am_ind+1       ; Plain indirect addressing.
            bcc ind_hop

            cpx #MPU6502.am_iny+1       ; Indexed indirect addressing.
            bcc ixy_hop

            cpx #MPU6502.am_imp+1       ; Implied addressing.
            bcc return

            cpx #MPU6502.am_imm+1       ; Immediate addressing.
            bcc imm_hop

            .Escape ERROR.Bug ; Unknown.

abs_hop     jmp absolute_op
zp_hop      jmp zp_op
ind_hop     jmp indirect_op
ixy_hop     jmp indirectxy_op
imm_hop     jmp immediate_op

            ;----------------------------------
            ;
            ; Format as branch
            ;
relative_op
            jsr PRINT.Dollar
            ; Calculate destination relative to byte after instruction.
            ldw a,y,RAM.INSPECT.ptr     ; Get PC.
            clc                         ; Never carry with lo byte.
            adc #2                      ; Add instruction size.
            bcc +                       ; No carry.
            iny                         ; Carry.
+           stw a,y,Vr2                 ; Save relative base.
            lda RAM.INSPECT.data.lo     ; Get displacement.
            bmi backward                ; It's negative direction.

            ; Handle forward branch
            ;
            ; IN:   A = Unsigned displacement.
            ;       Vr2 = Branch base address.
            ;
            ; OUT:  A,Y = Address.
            ;       Stack = Unsigned displacement.
forward     tay                         ; Copy displacement to Y.
            pha                         ; Save displacement for later.
            lda #"+"                    ; Sign for forward branch.
            pha                         ; Save sign character for later.
            tya                         ; Put displacement in A again.
            ldy Vr2.hi                  ; Load base hi.
            clc                         ; Never carry with lo byte.
            adc Vr2.lo                  ; Add base lo to displacement.
            bcc print_relative          ; No carry.
            iny                         ; Carry to hi byte.
            jmp print_relative          ; Print it.

            ; Handle backward branch
            ;
            ; IN:   A = Unsigned displacement.
            ;       Vr2 = Branch base address.
            ;
            ; OUT:  A,Y = Address.
            ;       Stack = Unsigned displacement.
backward    tax                         ; Copy displavement to X.
            clc                         ; Don't want carry.
            eor #$FF                    ; Negate displacement.
            adc #1                      ; Then add 1 = 2's compliment
            pha                         ; Save displacement for later.
            lda #"-"                    ; Sign for backward branch.
            pha                         ; Save sign character for later.
            txa                         ; Put displacement in A again.
            clc                         ; Never carry with lo byte.
            adc Vr2.lo                  ; Add negative displacement to base lo.
            tax                         ; Save to X.
            lda Vr2.hi                  ; Get base hi.
            adc #$FF                    ; Add sign extended displayment hi.
            tay                         ; Save hi in Y.
            txa                         ; Restore lo to A.
+
            ; Print branch destionation and comment.
            ;
            ; A,Y = Destination address.
            ; Stack = Unsigned displacement.
print_relative
            stw a,y,Vr3                 ; Save destination for remark.
            jsr PRINT.Hex.W             ; Print destionation address.
            ; Begin remark.
            ldy #2
            jsr PRINT.SpacesY
            jsr PRINT.Remark
            ; Print sign (direction) character.
            pla                         ; Restore sign character.
            jsr PRINT.Char              ; Print it.
            ; Print displacement.
            pla                         ; Restore unsigned displacement.
            jsr PRINT.Decimal.B         ; Print it.
            jsr PRINT.Space
            ; Peek at destination instruction and print it.
            jmp peek_instruction

            ;----------------------------------
            ;
            ; Format as immediate
            ;
immediate_op
            jsr PRINT.Hash
            jsr PRINT.Dollar
            lda RAM.INSPECT.data.lo     ; Get operand.
            pha                         ; Save for remark.
            jsr PRINT.Hex.B             ; Print value.
            ldy #3                      ; 3 spaces to align remark.
            jsr PRINT.SpacesY
            pla                         ; Restore operand.
            sec                         ; Decimal remark format.
            jsr byte_remark             ; Dump operand for remark.
            jmp return                  ; Done.

            ;----------------------------------
            ;
            ; Format as indirect
            ;
indirect_op
            jsr PRINT.Indirect
            tww a,y,RAM.INSPECT.data,Vr3 ; Copy operand for peek later.
            ; Print formatted operand
            jsr PRINT.Hex.W
            jsr PRINT.RParen
            jsr PRINT.Remark
            jsr PRINT.Dollar
            ; Peek target address for effect jump destination.
            ldy #0                      ; First byte.
            lda (Vr3),y                 ; Peek target address for lo.
            pha                         ; Save lo.
            iny                         ; Second byte.
            lda (Vr3),y                 ; Peek target address + 1 for hi.
            tay                         ; Copy hi to Y.
            pla                         ; Restore lo to A.
            stw a,y,Vr3                 ; Save effective address for remark.
            jsr PRINT.Hex.W             ; Print effective address.
            jsr PRINT.Space
            ; Peek at destination instruction and print it.
            jmp peek_instruction

            ;----------------------------------
            ;
            ; Format as indirect indexed
            ;
indirectxy_op
            pha                         ; Save addressing mode.
            jsr PRINT.Indirect          ; Begin formatting.
            ; Set pointer for dereference.
            ldy #0                      ; Zero page hi always 0.
            lda RAM.INSPECT.data.lo     ; Get zero page address.
            stw a,y,Vr3                 ; Save it.
            jsr PRINT.Hex.B             ; Print as byte value.
            ; Which index register?
            ; (am_order_v2)
            pla                         ; Restore addressing mode
            and #MPU6502.Y              ; Y index?
            bne indirect_y              ; Yes.

indirect_x  ; Add ,X)
            jsr PRINT.IndexX
            jsr PRINT.RParen
            ; Prepare to peek for comment.
            lda RAM.REGS.x              ; Get index.
            clc                         ; No carry.
            adc Vr3.lo                  ; Add index to target address.
            sta Vr3.lo                  ; Save it.
            bcc+                        ; No carry.
            inc Vr3.hi                  ; Carry.
+           lda #0                      ; No post peek index.
            pha                         ; Save post index.
            beq indirect_comment        ; Always true; relative jump.

indirect_y  ; Add ),Y
            jsr PRINT.RParen
            jsr PRINT.IndexY
            ; Prepare to peek for comment.
            lda RAM.REGS.y              ; Post index.
            pha                         ; Save post-index.

            ; Print remark.
            ;
            ; IN:   Vr3 = pre-index address
            ;       stack = post-index.
indirect_comment
            ; Peek pre-indexed pointer.
            ldy #0                      ; First byte index.
            lda (Vr3),y                 ; Peek target address for lo.
            tax                         ; Save it.
            iny                         ; Second byte index.
            lda (Vr3),y                 ; Peek target address +1 for hi.
            stw x,a,Vr3                 ; Save to zero page.
            pla                         ; Get post-index.
            tay                         ; Copy to post-index register.
            lda (Vr3),y                 ; Peek effect destination address.
            clc                         ; Hexadecimal remark format.
            jsr byte_remark             ; Dump result in remark.
            jmp return                  ; Done.

            ;----------------------------------
            ;
            ; Format as zero page
            ;
zp_op       pha                         ; Save addressing mode for index.
            jsr PRINT.Dollar
            ldy #0                      ; Zero page address hi always 0.
            lda RAM.INSPECT.data        ; Get zero page address lo.
            stw a,y,Vr3                 ; Save for peek in remark.
            jsr PRINT.Hex.B             ; Print operand.
            jmp azp_xy                  ; Apply indexing if needed.

            ;----------------------------------
            ;
            ; Format as absolute
            ;
absolute_op pha                         ; Save addressing mode for index.
            jsr PRINT.Dollar
            ldw a,y,RAM.INSPECT.data    ; Get address operand.
            stw a,y,Vr3                 ; Save for peek later.
            jsr PRINT.Hex.W             ; Print address operand.

            ;
            ; Shared absolute/zeropage formatting. Determine if indexed.
            ;
azp_xy      pla                         ; Peek at addressing mode.
            pha                         ; (put it back)
            and #~MPU6502.MASKXY        ; am_order_v2
            cmp #MPU6502.Y              ; Y index?
            beq azp_y                   ; Yes.
            cmp #MPU6502.X              ; X index?
            beq azp_x                   ; Yes.

azp_plain   ; Print spaces instead of index.
            ldy #2
            jsr PRINT.SpacesY
            ldy #0
            jmp azp_rem

azp_x       ; Print ",X" and get X state.
            jsr PRINT.IndexX
            ldy RAM.REGS.x
            jmp azp_rem

azp_y       ; Print ",Y" and get Y state.
            jsr PRINT.IndexY
            ldy RAM.REGS.y

azp_rem     ; Append remark for absolute/zero page addressing mode.
            ;
            ; Y = offset of byte to read.
            ; Stack = mode.
            ; Zero page needs two more spaces.
            ;
            ; am_order_v2:
            pla                         ; Get addressing mode.
            and #MPU6502.MASKXY         ; Get base mode; mask off index.
            tax                         ; Copy base mode to X.
            tya                         ; Copy read offset to A.
            pha                         ; Save read offset.
            cpx #MPU6502.am_zp          ; Zero page addressing?
            bne +                       ; No.
            ldy #2                      ; Add 2 spaces for zero page.
            jsr PRINT.SpacesY
+           ; Display comment
            pla                         ; Recover read offset.
            ldy RAM.INSPECT.opcode      ; Get opcode.
            cpy #$20                    ; JSR ?
            beq code_remark             ; Yes.
            cpy #$4C                    ; JMP ?
            beq code_remark             ; Yes.
            tay                         ; Copy read offset back to index Y.
            lda (Vr3),y                 ; Peek data.
            clc                         ; Hexadecimal remark format.
            jsr byte_remark             ; Dump byte remark.
return_hop  jmp return                  ; Done.

code_remark jsr PRINT.Remark

peek_instruction
            lda RAM.INSPECT.size        ; Get instruction size.
            pha                         ; Save it for return.
            ldw a,y,Vr3                 ; Get address operand.
            jsr Inspect                 ; Inspect the operand target.
            lea a,y,RAM.INSPECT.name    ; Show the instruction there.
            jsr PRINT.String
            pla                         ; Get the original instruction size.
            sta RAM.INSPECT.size        ; Put it back in the inspector.
            bcc return_hop              ; Done.

byte_remark ; IN: CF = decimal, else hexadecimal.
            pha                         ; Save byte.
            pha                         ; Save byte again.
            php                         ; Save CF radix flag.
            jsr PRINT.Remark            ; Begin remark.
            plp                         ; Print decimal value?
            bcs rem_decb                ; Yes.
rem_hexb    ; Print value in hexadecimal.
            jsr PRINT.Dollar
            pla                         ; Get value (second copy).
            jsr PRINT.Hex.B
            bcc rem_char                ; Always true; relative jump.
rem_decb    ; Print value in decimal.
            lda #"!"
            jsr PRINT.Char
            pla                         ; Get value (second copy).
            jsr PRINT.Decimal.B
rem_char    ; Print character equivalent.
            jsr PRINT.Space
            lda #"'"
            jsr PRINT.Char
            pla                         ; Get value (first copy).
            jmp PLATFORM.SymbolOut      ; Dump it. Done.
            .endproc ; Instruction


;;-------------------------------------
;;
;; JSR DASM.Formatted
;;
;; Pretty prints a disassembly line of an instruction described by the
;; inspection data.
;;
;; IN:      A = Instruction address lo byte.
;;          Y = Instruction address hi byte.
;;
;; OUT:     X = Instruction byte count.
;;
;; SAFE:    None.
;;
Formatted   .proc

            jsr Inspect                 ; Get instruction info.
            ldw a,y,RAM.INSPECT.ptr     ; Get instruction address.
            jsr PRINT.Hex.W             ; Print it.
            ; Print code bytes if enabled.
            lda #RAM.FLAG.CODEBYTES     ; Code bytes flag.
            bit RAM.Features            ; Is it set?
            beq disassemble             ; No.
show_bytes  jsr PRINT.Minus             ; Print command token.
            lea a,y,RAM.INSPECT.opcode  ; Get address of instruction bytes.
            ldx RAM.INSPECT.size        ; Get size of instruction.
            jsr DUMP.Bytes              ; Dump code bytes.
            ; Print space for unused code bytes to align assembly.
            sec                         ; Clear borrow.
            lda #3                      ; Max instruction size.
            sbc RAM.INSPECT.size        ; Minus used bytes = padding length.
            sta Tr6                     ; Save padding length.
            ; x3 spaces each.
            asl                         ; x2
            sec                         ; Carry for additional separator space.
            adc Tr6                     ; x1 + x2 + 1
            tay                         ; Set number of spaces.
            jsr PRINT.SpacesY           ; Print the spaces.
disassemble jsr PRINT.Space             ; Add a space separator.
            jsr Instruction.Inspected   ; Disassemble.
            ldx RAM.INSPECT.size        ; Return instruction size.
            rts                         ; Done.
            .endproc


            .endblock ; DASM
