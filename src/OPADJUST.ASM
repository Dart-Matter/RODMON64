
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


OPADJUST     .block


;--------------------------------------
;
; IMPLEMENTS THE ADJUST ADDRESS OPERANDS COMMAND.
;
;   token , start , end , base , limit , new-base
;
; Rebases the zero-page and absolute operands in a span of memory if they
; fall within a specified range of addresses.
;
; WARNING:  This should only be used on a span of memory that conforms to the
;           following:
;           
;           1. The span only contains contiguous instructions.  No data or
;              unused bytes.  It won't be able to distinguish those from an
;              instruction.
;
;           2. Addressing operands do not contain embedded data or 
;              instructions.  These will potentially be interpreted as an
;              address and changed when not desired.
;
Handler     .proc

Offset      = Arg0
Limit       = Arg1
Base        = Arg2
End         = Arg3
InsPtr      = Arg4

            bcc syntax_error            ; Command prefix is invalid.

            ; Input and validate start/end.
            jsr INPUT.Number            ; Input start.
            bcs value_error             ; Expected a number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            jsr INPUT.Number            ; Input end.
            bcs value_error             ; Expected a number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            ldx #Arg0                   ; Select end arg.
            jsr ARGS.Compare            ; Is end <= start?
            ble range_error             ; Yes, invalid.

            ; Input and validate base/limit.
            jsr INPUT.Number            ; Input base.
            bcs value_error             ; Expected a number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            jsr INPUT.Number            ; Input limit.
            bcs value_error             ; Expected a number.
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, was expecting more.
            ldx #Arg0                   ; Select limit arg.
            jsr ARGS.Compare            ; Is limit <= base?
            ble range_error             ; Yes, invalid.

            ; Input and validate new base.
            jsr INPUT.Number            ; Input new base.
            bcs value_error             ; Expected a number.
            pha                         ; Save delimiter for later.

            ; Secret parameter: "E" = Interpret BRK as escape.
            ; This is used for relocating the monitor itself.
            ldx #0
            stx Vr5                     ; Escapes off.

.if debug
            pla                         ; Recover OPADJUST delimiter.
            cmp #NEWLINE                ; End ofline?
            beq +                       ; No, no secret paramter.
            jsr INPUT.Key               ; Get number.  We want a single "E".
            cmp #"e"                    ; "E"?
            bne syntax_error
            jsr INPUT.Key
            cmp #NEWLINE                ; End of line?
            bne syntax_error            ; No, unexpected.
.else
            pla                         ; Recover OPADJUST delimiter.
            cmp #NEWLINE                ; End ofline?
            beq +
            bne syntax_error
.endif

Internal    lda #1
            sta Vr5
            bne +

;*************************************************
                                        ;         ***
syntax_error .Escape ERROR.Syntax       ;            *
value_error .Escape ERROR.Value         ;   ERROR     *
range_error .Escape ERROR.Range         ;   ISLAND    *
zpg_error   .Escape ERROR.ZeroPage      ;            *
                                        ;         ***
;*************************************************
+
            ; Convert new base to offset.
            sec                         ; Clear borrow.
            lda Offset.lo               ; Load new base lo.
            sbc Base.lo                 ; Subtract old base lo.
            sta Offset.lo               ; Write result lo back.
            lda Offset.hi               ; Load new base hi.
            sbc Base.hi                 ; Subtract old base lo with borrow.
            sta Offset.hi               ; Write result hi back.

            ; New base must not move zero page addresses out of zero page.
            lda Base.hi                 ; Get base hi.
            bne +                       ; Base is not zero page.
            tay                         ; Save base hi to Y.
            lda Base.lo                 ; Get base lo.
            clc                         ; Clear carry for add.
            adc Offset.lo               ; Add offset.
            tya                         ; Restore base hi.
            adc Offset.hi               ; Add offset hi with carry.
            bne zpg_error               ; Error if not page zero.
            lda Limit.hi                ; Get limit hi.
            bne +                       ; Limit is not zero page.
            tay                         ; Save limit hi to Y.
            lda Limit.lo                ; Get limit lo.
            clc                         ; Clear carry for add.
            adc Offset.lo               ; Add offset lo.
            tya                         ; Restore limit hi.
            adc Offset.hi               ; Add offset hi with carry.
            bne zpg_error               ; Error if not page zero.
+

work        ldw a,y,InsPtr              ; Get current instruction address.
            jsr DASM.Inspect            ; Inspect instruction.

            ; Secret parameter: If it's a BRK treat it like a branch.
            lda Vr5                     ; Secret parameter?
            beq +                       ; No
            lda RAM.INSPECT.opcode      ; Get opcode.  IS it BRK?
            bne +                       ; No it's not BRK.
            lda #2                      ; Make the instruction size 2.
            sta RAM.INSPECT.size        ; Fake it in the inspection data.
            bne next                    ; Advance to next instruction.
+
            ldx RAM.INSPECT.mode
            ; Mode

            ; (am_order_v2)
            cpx #MPU6502.am_aby+1       ; Absolute addressing.
            bcc word_operand

            cpx #MPU6502.am_zpy+1       ; Zero page addressing.
            bcc byte_operand

            cpx #MPU6502.am_rel+1       ; Branches. Not applicable.
            bcc next

            cpx #MPU6502.am_ind+1       ; Plain indirect addressing.
            bcc word_operand

            cpx #MPU6502.am_iny+1       ; Indexed indirect addressing.
            bcc byte_operand

            ; Implied and immediate don't have address operands.
            ;
            ; cpx #MPU6502.am_imp+1       ; Implied addressing.
            ; bcc is_implied
            ;
            ; cpx #MPU6502.am_imm+1       ; Immediate addressing.
            ; bcc byte_operand

next        lda RAM.INSPECT.size        ; Get instruction size.
            ldx #InsPtr                 ; Select instruction address arg.
            jsr ARGS.Add.B              ; Add size to address.
            ldx #End                    ; Select range end.
            jsr ARGS.Compare            ; Is end >= start?
            bge work                    ; Yes, do another.
            rts                         ; Done.

byte_operand
            lda Base.hi                 ; Is base zero page?
            bne next                    ; No, operand must be out of range.
            lda RAM.INSPECT.data.lo     ; Get operand byte.
            cmp Base.lo                 ; Is operand < base?
            blt next                    ; Yes, out of range.
            cmp Limit.lo                ; Is operand >= limit?
            bgt next                    ; Yes, out of range.
            ; Apply offset & write.
            ldy #1                      ; Operand is at instruction offset 1.
            clc                         ; Clear carry for add.
            adc Offset.lo               ; Apply offset.
            sta (InsPtr),y              ; Write over original.
            jmp next                    ; Do another.

word_operand
            ; Is operand below the base?
            lda RAM.INSPECT.data.hi     ; Get operand hi.
            cmp Base.hi                 ; Is operand hi < base hi?
            blt next                    ; Yes, out of range.
            bgt +                       ; If operand > base proceed to limit.
            lda RAM.INSPECT.data.lo     ; Get operand lo.
            cmp Base.lo                 ; Is operand lo < base lo?
            blt next                    ; Yes, out of range.
+           ; Is operand above the limit?
            lda RAM.INSPECT.data.hi     ; Get operand hi.
            tax                         ; Stash operand hi in X for later.
            cmp Limit.hi                ; Is operand hi > limit hi?
            bgt next                    ; Yes, out of range.
            blt +                       ; If operand < limit proceed to apply.
            lda RAM.INSPECT.data.lo     ; Get operand lo.
            cmp Limit.lo                ; Is operand lo > limit lo?
            bgt next                    ; Yes, out of range.
            ; Apply offset & write.
+           ldy #1                      ; Operand begins 1 byte after opcode.
            clc                         ; Clear carry for add.
            lda RAM.INSPECT.data.lo     ; Get operand lo.
            adc Offset.lo               ; Apply offset lo.
            sta (InsPtr),y              ; Write over original lo.
            iny                         ; Locate high byte of operand.
            txa                         ; Restore hi.
            adc Offset.hi               ; Apply offset hi with carry.
            sta (InsPtr),y              ; Write over original hi.
            jmp next                    ; Do another.

            .endproc ; Handler


            .endblock ; OPADJUST
