
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


ASSEMBLE    .block


;--------------------------------------
;
; IMPLEMENTS THE ASSEMBLE COMMAND.
;
;   ( address ) <space> instruction ( ; comment )
;
; Assembles a single instruction into memory then echos it back by
; disassembling it.
;
; IN:       CF = Resume from previous command.
;
Handler     .proc

            bcc getname                 ; Address specified, do assembly.
            jsr skip_spaces             ; Ignore spaces.
            cmp #";"                    ; Comment?
            beq ignore                  ; Yes, ignore this command.
            cmp #NEWLINE        ; End of line?
            bne resume                  ; No, continue with resume address.
ignore      rts                         ; Ignore this command.

resume      .INPUT.Unget a              ; Requeue key after spaces.

asmArg0     ; Special entrypoint for codebyte assemble.

getname     ; Read next 3 characters into a 2-byte packed build buffer.
            ;  _______________________________
            ; | |  char3  |  char2  |  char1  |
            ; |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|
            ; |               |               |
            lda #3                      ; 3 characters per mnemonic.
            sta Vr1                     ; Store in loop counter.
            ; Clear name build buffer.
            lda #0
            sta Vr2.lo
            sta Vr2.hi
            ; Skip to first character of instruction.
            jsr skip_spaces             ; Ignore spaces.
            bne namescan                ; Always true.

nameloop    ; Read next key.
            jsr INPUT.Key

namescan    ; Try reading key into build buffer.
            cmp #"a"                    ; Lowest allowed key.
            bcc ins_error               ; < "A" is invalid.
            cmp #"z"+1                  ; Highest allowed key.
            bcs ins_error               ; > "Z" is invalid.
            ; Valid key, pack into build buffer.
            ldx #5                      ; 5 bits per character.
-           lsr                         ; Shift low bit into carry.
            ror Vr2.lo                  ; Shift carry into hi bit of buffer.
            ror Vr2.hi
            dex                         ; Decrement bit count.
            bne -                       ; More bits to do.
            dec Vr1                     ; Need another char?
            bne nameloop                ; Yes.
            ; Shift a 0 into the unofficial bit of the build buffer.
            clc                         ; 0 bit.
            ror Vr2.lo                  ; Shift into hi bit of buffer.
            ror Vr2.hi
            ; Scan is complete.
            jsr find_name               ; Is the mnemonic valid?
            bne ins_error               ; No, error.
            bcc ins_good                ; Yes, an official instruction.
            ; Unofficial instruction. Is unofficial feature enabled?
            lda #RAM.FLAG.UNOFFICIAL    ; Unofficial bit flag.
            bit RAM.Features            ; And it with feature bits.
            beq uno_error               ; Not enabled, so error.
ins_good    ; Mnemonic is valid.
            stx Vr1                     ; save mnemonic index.
            jsr skip_spaces             ; Skip to operand field.
            ; Detect implied addressing.
            cmp #NEWLINE        ; End of line?
            beq implied                 ; Yes, assume implied addressing.
            cmp #";"                    ; Comment?
            beq implied                 ; Yes, assume implied addressing.
            ; Parse more modes.
+           cmp #"#"                    ; Immediate prefix?
            beq immediate               ; Yes, assume immediate addressing.
            cmp #"("                    ; Indirect opening parenthesis?
            beq indirect_any            ; Yes, assume indirect addressing.
            bne direct_any              ; Otherwise assume direct addressing.

ins_error   .Escape ERROR.Instruction
uno_error   .Escape ERROR.Unofficial

            ;----------------------------------
            ;
            ; IMPLIED ADDRESSING MODE
            ;
implied
            ; Put key back to be processed
            ;  as tralining line input.
            .INPUT.Unget a
            jsr ARGS.Push ; Push fake operand.
            ; Set mode and finish.
            lda #MPU6502.am_imp
            jmp trailing

            ;----------------------------------
            ;
            ; ABSOLUTE AND ZERO PAGE ADDRESSING MODES WITH OR WITHOUT INDEX.
            ;
direct_any
            ; Assume operand is absolute mode.
            ldx #MPU6502.am_abs         ; Absolute mode bit flag.
            stx Vr0                     ; Save as base addressing mode.
            ; Need an address operand.
            jsr INPUT.Number.Started    ; Input number with first key in A.
            bcs value_error             ; It isn't a valid number.
            bne +                       ; It is absolute.
            ; It's zero page, so save that.
            ldx #MPU6502.am_zp          ; Zero page mode bit flag.
            stx Vr0                     ; Save as base addressing mode.
+           ; Determine if input is indexed.
            cmp #","                    ; Encountered comma?
            bne direct                  ; No, just plain direct.
            ; X or Y?
            jsr INPUT.Key               ; Read a key.
            tay                         ; Save key to Y.
            lda Vr0                     ; Get base addressing mode.
            cpy #"x"                    ; Index X?
            beq direct_x                ; Yes, add addressing mode X bit.
            cpy #"y"                    ; Index Y?
            beq direct_y                ; Yes, add addressing mode Y bit.
            jmp syntax_error            ; Not X or Y is an error.

direct      .INPUT.Unget a              ; Put the "not comma" key back.
            lda Vr0                     ; Get addressing mode.
            jmp trailing                ; Fihish line input.

direct_y    ora #MPU6502.Y              ; Add Y addressing mode qualifier.
            bne trailing                ; Always; finish line input.

direct_x    ora #MPU6502.X              ; Add X addressing mode qualifier.
            bne trailing                ; Always; finish line input.

            ; Jump table placed here so it is accessible from other routine
            ; locations by relative branches.

syntax_error .Escape ERROR.Syntax
byte_error  .Escape ERROR.Byte
value_error .Escape ERROR.Value
mode_error  .Escape ERROR.Mode
range_error .Escape ERROR.Range
zpg_error   .Escape ERROR.ZeroPage

            ;----------------------------------
            ;
            ; IMMEDIATE ADDRESSING MODE
            ;
immediate
            ; Need a 1 byte value operand.
            jsr INPUT.Number            ; Read from screen.
            bcs value_error             ; Didn't find a number.
            ; A 1-byte sign extended value will have a hi byte of $00 or $FF.
            ldy Arg0.hi                 ; Get hi byte.
            beq imm_inrange             ; Hi byte is $00.
            iny                         ; $FF + 1 will equal $00.
            bne value_error             ; It wasn't $FF, so out of range.
imm_inrange .INPUT.Unget a              ; Put the delimiter key back.
            lda #MPU6502.am_imm         ; Set addressing mode.
            jmp trailing                ; Fihish line input.

            ;----------------------------------
            ;
            ; INDIRECT ADDRESSING MODE
            ;
indirect_any
            ; Need an address operand.
            jsr INPUT.Number            ; Read from screen.
            bcs value_error             ; Didn't find a number.
+           cmp #","                    ; Followed by a comma?
            beq indirect_x              ; Yes, check for X.
            cmp #")"                    ; Encountered right parenthesis?
            bne syntax_error            ; No, invalid syntax.
            jsr INPUT.Key               ; Read key after parenthesis.
            cmp #","                    ; Is it a comma?
            beq indirect_y              ; Yes, check for Y.

indirect    ; Parsed non-indexed indirect operand.
            .INPUT.Unget a              ; Put the key back for later.
            lda #MPU6502.am_ind         ; Set indirect addressing mode.
            jmp trailing                ; Finish line input.

indirect_y  ; Expecting (zero-page),Y addressing mode.
            lda Arg0.hi ; Hi = 0?       ; Operand hi must be 0.
            bne zpg_error               ; Not zero page, error.
            jsr INPUT.Key               ; Get next key.
            cmp #"y"                    ; Is it the expected "Y"?
            bne syntax_error            ; No, bad syntax.
            lda #MPU6502.am_iny         ; Set indirect Y addressing mode.
            jmp trailing                ; Fihish line input.

indirect_x  ; Expecting (zero-page,X) addressing mode.
            lda Arg0.hi ; Hi = 0?       ; Operand hi must be 0.
            bne zpg_error               ; Not zero page, error.
            jsr INPUT.Key               ; Get next key.
            cmp #"x"                    ; Is it "X"?
            bne syntax_error            ; No, bad syntax.
            jsr INPUT.Key               ; Get another key.
            cmp #")"                    ; Is it right parenthesis?
            bne syntax_error            ; No, bad syntax.
            lda #MPU6502.am_inx         ; Set indirect X addressing mode.
            jmp trailing                ; Fihish line input.

trailing    ; Parse the remainder of a valid assembly input line.  It Should
            ; be a comment, blanks, or end of line.
            sta Vr0                     ; Save addressing mode.
            jsr skip_spaces             ; Skip blanks.
            cmp #";"                    ; Next key is start of comment?
            beq parsed_ok               ; Yes, line looks ok.
            cmp #NEWLINE                ; End of line?
            bne syntax_error            ; No, garbage found.

parsed_ok   jsr find_opcode             ; Look for matching instruction.
            bne mode_error              ; Not found.
            stx Vr1                     ; Found, save opcode.

            ;
            ; We have everything we need to poke memory.
            ;
            ;  Vr0 = Addressing mode (for instruction size.)
            ;  Vr1 = Opcode.
            ;  Arg0 = Operand (if applicable.)
            ;  Arg1 = Instruction address.
            ;
            jsr put_instruction         ; Poke memory.
            bcs range_error             ; Relative operand was invalid.
            ; Echo the result back.
            jsr PLATFORM.Overwrite      ; Move cursor to start of same line.
            jmp UNASSEMBLE.One          ; Disassemble.

            .endproc ; Handler


;--------------------------------------
;
; INPUT AND SKIP ALL SPACES.
;
; OUT:      A = next non space character
;           ZF = 0
;
; SAFE:     None.
;
skip_spaces .proc
-           jsr INPUT.Key               ; Get a key.
            cmp #32                     ; Is it a space?
            beq -                       ; Yes, input another key.
            rts                         ; Done.
            .endproc


;--------------------------------------
;
; LOCATE A MNEMONIC.
;
; IN:       Vr2 = Mnemonic
;
; OUT:      ZF = Valid
;           CF = Unofficial
;           X = Mnenonic index
;
; SAFE:     None.
;
find_name .proc
            ldx #0                      ; Initialize table search offset.
loop        lda MPU6502.MNTABLE,x       ; Retrieve packed byte 1 to compare.
            bne compare                 ; Not end of table.
invalid     ; A = 0; end of table. Return "not valid".
            adc #1                      ; Clear ZF.
            rts                         ; Done.

compare     tay                         ; Save for "unofficial" bit.
            and #$7f                    ; Clear "unofficial" bit.
            cmp Vr2.lo                  ; Packed byte 1 matches?
            bne next                    ; No, try next table entry.
            lda MPU6502.MNTABLE+1,x     ; Retrieve packed byte 2.
            cmp Vr2.hi                  ; Packed byte 2 matches?
            bne next                    ; No, try next table entry.
            ; Mnemonic found.  Check addressing mode.
            txa                         ; Convert offset to
            lsr                         ;  index.
            tax                         ; Save index to X.
            tya                         ; Restore "unofficial" bit.
            and #MPU6502.UNOFFICIAL     ; Isolate it.
            asl                         ; Shift it into carry and set ZF.
            rts                         ; Done.

next        inx                         ; Next packed mnemonic offset;
            inx                         ;  2-bytes each.
            bne loop                    ; Always loop, except...
            beq invalid                 ;  if there's a bug.
            .endproc ; find_name


;--------------------------------------
;
; FIND AN INSTRUCTION OPCODE.
;
; IN:       Vr0 = addressing mode
;           Vr1 = mnemonic index
;
; OUT:      ZF = success
;           X = opcode
;
; SAFE:     None.
;
; NOTE: There is some fuzzy matching that occurs:
;
; Relative mode instructions *look* like absolute mode, and they arrive here
; as absolute mode.  So, if the addressing mode is absolute but there is no
; equivalent instruction, we will try relative mode.  Yes, that means branch
; instructions always make one useless pass through the table in order to
; determine there is not absolute mode branch instruction.
;
; If the input mode is zero page but there is no equivalent instruction, we
; will try coercing it to absolute mode.
;
find_opcode .proc
            ldx #0                      ; Initialize table search index.
loop        lda MPU6502.OPTABLE,x       ; Retrieve opcode declaration byte.
            and #~MPU6502.UNOFFICIAL    ; Ignore "unofficial" bit.
            cmp Vr1                     ; Do they match?
            bne mismatch                ; No, try next declaration.
            ; Same addressing mode to?
            ; Convert index to nybble pair
            ; index, and which nybble
            txa                         ; Convert index to nybble reference;
            lsr                         ; A = pair offset, CF=lo nybble.
            tay                         ; Y = pair offset.
            lda MPU6502.AMTABLE,y       ; Get nybble pair.
            bcs +                       ; Lo nybble already in position.
            ; Shift hi nybble into lo position.
            lsr
            lsr
            lsr
            lsr
+           and #%00001111              ; Isolate low nybble.
            cmp Vr0                     ; Compare with user's mode.
            bne mismatch                ; Not a match, try next declaration.
            rts                         ; Instruction found.

mismatch    inx                         ; Next table entry.
            bne loop                    ; Compare it.

            ; End of table.  Apply fuzziness.
            lda Vr0                     ; Get addressing mode.
            ; If absolute try relative.
            cmp #MPU6502.am_abs
            beq try_rel
            cmp #MPU6502.am_abx
            beq try_rel
            cmp #MPU6502.am_aby
            beq try_rel
            ; If zero page, try absolute.
            cmp #MPU6502.am_zp
            beq try_absolute
            cmp #MPU6502.am_zpx
            beq try_absolute
            cmp #MPU6502.am_zpy
            beq try_absolute
            ; Fuzzy fail.
            rts

try_absolute
            ; Coerce zero page to absolute.
            sec
            sbc #(MPU6502.am_zp - MPU6502.am_abs)
            bcs try_newmode             ; Should always be true.

try_rel     lda #MPU6502.am_rel

try_newmode sta Vr0
            bpl find_opcode             ; Should always be true.

            .endproc ; find_opcode


;--------------------------------------
;
; PLACE INSTRUCTION IN MEMORY.
;
; IN:       Vr0 = addressing mode
;           Vr1 = opcode
;           Arg0 = operand
;           Arg1 = target address
;
; OUT:      Y = byte count
;           CF = branch overflow
;
put_instruction .proc

            ldy #0                      ; Opcode byte offset.
            lda Vr1                     ; Get opcode.
            sta (Arg1),y                ; Poke the opcode.
            iny                         ; First operand byte offset.

            ; Determine operand type based on addressing mode.
            ldx Vr0                     ; Get addressing mode.

            ; (am_order_v2)
            cpx #MPU6502.am_aby+1       ; Absolute addressing.
            bcc word_operand

            cpx #MPU6502.am_zpy+1       ; Zero page addressing.
            bcc byte_operand

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

            ; Unexpectedly using unknown addressing mode.
            .Escape ERROR.Bug

byte_operand
            lda Arg0.lo                 ; The operand byte.
            jmp last_poke

word_operand
            lda Arg0.lo                 ; First operand byte.
            sta (Arg1),y
            iny                         ; Next address.
            lda Arg0.hi                 ; Last operand byte.
            jmp last_poke

disp_operand
            ; Reduce distance by instruction size.
            sec                         ; Clear borrow.
            lda Arg0.lo                 ; Lo of destination address.
            sbc #2                      ; Less 2.
            bcs +                       ; No borrow.
            dec Arg0.hi                 ; Borrow from hi.
+
            ; Subtract PC from destination.
            sec                         ; Clear borrow.
            sbc Arg1.lo                 ; Diff destination lo with PC.
            tax                         ; Save displacement lo byte.
            lda Arg0.hi                 ; Get destination hi byte.
            sbc Arg1.hi                 ; Diff destination hi with PC.
            sta Vr2                     ; Save displacement hi.
            ; Hi byte must be sign extended from lo bit 7.
            txa                         ; Get lo byte.
            and #$80                    ; Isolate bit 7.
            eor #$80                    ; Flip bit 7; will borrow if neg value.
            asl                         ; Move bit 7 to borrow (CF), A = 0.
            sbc #0                      ; $FF if borrow/neg, else 0.
+           cmp Vr2                     ; Compare with hi byte.
            beq +                       ; Hi byte is correct.
            sec                         ; Destination out of range; overflow.
            rts                         ; Done
+           txa                         ; Prepare to poke displacement byte.

last_poke   sta (Arg1),y                ; Poke final operand byte.
            iny                         ; Return byte count.

is_implied  clc                         ; Success.
            rts                         ; Done.

            .endproc ; put_instruction


            .endblock ; ASSEMBLE
