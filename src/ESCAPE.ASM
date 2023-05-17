
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
; HANDLE ESCAPE CALLS
;
; Escapes are invoked by BRK followed by a command byte.
; Error commands have bit 7 set to 1.
;
EscapeHandler .proc
            ; Locate return address on stack.
            tsx                         ; Get stack pointer.
            inx                         ; Skip Y.
            inx                         ; Skip X.
            inx                         ; Skip A.
            inx                         ; Skip flags.
            txs                         ; Reset stack pointer.

            ; Compute address of BRK.
            sec                         ; Clear borrow for subtract.
            pla                         ; Get return lo.
            sbc #2                      ; BRK is two bytes before.
            sta Vr4.lo                  ; Save BRK lo.
            pla                         ; Get return hi.
            sbc #0                      ; Subtract borrow from hi.
            sta Vr4.hi                  ; Save BRK hi.
            cld                         ; Ensure BCD is off.
            cli                         ; Re-enable interrupts.

            ; Dispatch command.
            ldy #1                      ; Command byte is 1 byte after BRK.
            lda (Vr4),y                 ; Get the command byte.  Error?
            bpl +                       ; No, it's something else.
            jmp ERROR.Handler           ; Dispatch error.
+           ; Nothing else implemented yet.
            clc                         ; Disable banner.
            jmp COMMANDS.Restart        ; Restart command input.
            .endproc ; EscHandler
