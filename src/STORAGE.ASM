
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


;---------------------------------------
;
; IMPLEMENTS THE SAVE, LOAD< AND VERIFY COMMANDS.
;
;   token "filename" , number ( , number ( , number ( , number ) ) ) )
;
; It is anticipated that the storage function vary widely on different
; platforms, so the bulk of these functions are implemented in the platform
; code where the parameters need to be validated.
;
STORAGE     .block


SAVE        .block
Handler     .proc
            lda #IO_SAVE                ; Save operation.
            bne Core
            .endproc
            .endblock

LOAD        .block
Handler     .proc
            lda #IO_LOAD                ; Save operation.
            bne Core
            .endproc
            .endblock

VERIFY      .block
Handler     .proc
            lda #IO_VERIFY              ; Save operation.
            bne Core
            .endproc
            .endblock

Core        .proc

            ; Aliases to make code easier to read.
Operation   = Vr5
ParmCount   = Vr4

            sta Operation               ; Save operation.
            bcs +                       ; No command prefix is correct.
syntax_error .Escape ERROR.Syntax
value_error .Escape ERROR.Value
range_error .Escape ERROR.Range
io_error    .Escape ERROR.Io
verify_error .Escape ERROR.Verify

+           jsr INPUT.QString           ; Get filename.
            bcs syntax_error
            cmp #NEWLINE                ; End of line?
            beq syntax_error            ; Yes, error - expecting more.
            lda #0                      ; Parameter count after filename.
            sta ParmCount               ; Save it.

get_parms   jsr INPUT.Number            ; Get parameter.
            bcs value_error             ; Error, expected a number.
            inc ParmCount
            cmp #NEWLINE                ; End of line?
            beq apply
            lda #4                      ; Up to 4 parameters allowed.
            cmp ParmCount
            bne get_parms               ; Only have one.
            beq syntax_error

apply       lda ParmCount
            ldx Operation
            cpx #IO_SAVE
            beq save_op
            cpx #IO_LOAD
            beq load_op
            cpx #IO_VERIFY
            beq verify_op
            .Escape ERROR.Bug           ; Unexpected unknown operation.

save_op     jmp PLATFORM.Save
load_op     jmp PLATFORM.Load           ; X = IO_LOAD
verify_op   jsr PLATFORM.Verify         ; X = IO_VERIFY
            bne verify_error
            rts
            .endproc


            .endblock ; STORAGE
