
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
; STRINGS
;


STRINGS     .block


banner      .null 13,"rodmon64"
about       .text "rodmon64 (c) "
            .text "1983, 2023 "
            .text "rodney rushing"
            .text NEWLINE, 0
coderng     .null NEWLINE,"mon code:    "
datarng     .null NEWLINE,"mon data:    "
ramrng      .null NEWLINE,"mon ram:     "
charmode    .null NEWLINE,"char mode:   "
petscii     .null "petscii"
petcodes    .null "poke codes"
unomode     .null NEWLINE,"unofficial:  "
bytemode    .null NEWLINE,"code bytes:  "
on          .null "on"
off         .null "off"
reghead     .null "  pc   ir  a  x  y   sp  nv?bdizc",NEWLINE
ask_sure    .null NEWLINE,"you sure? "
goq         .null NEWLINE,"[g]o? [r]ts? "

            ;
            ; ERROR STRINGS
            ;
errbase
cmd         .null "cmd"
ins         .null "ins"
mod         .null "mod"
dup         .null "dup"
bug         .null "bug"
            ; Errors below this point will also show an arrow pointing to the
            ; on the command line where the error occurred.
pointbase   = * - errbase
tst         .null "tst"
rng         .null "rng"
val         .null "val"
syn         .null "syn"
byt         .null "byt"
zpg         .null "zpg"
uno         .null "uno"
io          .null "i/o"
ver         .null "ver"


            .endblock ; STRINGS
            
