
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
; Contains routines for error handling.
;
ERROR       .block


;--------------------------------------
;
; ERROR TOKENS
;
; Invoke these errors using
;
;   .Escape <error>
;
; These tokens are really the offset of each error string from the base of the
; error string table.
;

ERRDECL     .segment error,string_address
@1          = (STRINGS.@2 - STRINGS.errbase) | %10000000
            .endsegment

            ERRDECL Command,    cmd
            ERRDECL Instruction,ins
            ERRDECL Mode,       mod
            ERRDECL Duplicate,  dup
            ERRDECL Bug,        bug
            ERRDECL Test,       tst
            ERRDECL Range,      rng
            ERRDECL Value,      val
            ERRDECL Syntax,     syn
            ERRDECL Byte,       byt
            ERRDECL ZeroPage,   zpg
            ERRDECL Unofficial, uno
            ERRDECL Io,         io
            ERRDECL Verify,     ver


;--------------------------------------
;
; Show an arrow pointing at the last input character.
;
PointAt     .proc
; TODO: Replace this with position x spaces?
            jmp PRINT.Newline            ; Print it.
            .endproc


;--------------------------------------
;
; Called by the Escape handler when the command is an ERROR command.
;
Handler     .proc
            pha                         ; Save error id.
+           jsr PLATFORM.Newline        ; Cursor to start of next line.
            lda #"?"                    ; Print error token.
            jsr PRINT.Char
            pla                         ; Restore error id.
            and #%01111111              ; Mask off error flag to get offset.
            sta Tr6                     ; Stash string offset.
            lea a,y,STRINGS.errbase     ; Get error strings base.    
            clc                         ; Clear carry.
            adc Tr6                     ; Add offset to error base.
            bcc +
            iny
+           jsr PRINT.String            ; Print resulting error string.
            jmp COMMANDS.Restart        ; Restart command parser.
            .endproc


            .endblock ; ERROR
