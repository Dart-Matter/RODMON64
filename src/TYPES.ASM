
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


; -- NO CODE GENERATION IN THIS FILE --


;;-------------------------------------
;;
;; Pseudo-instruction: branch if less or equal.
;;
ble         .macro dst              ;;
            bcc \dst
            beq \dst
            .endm


;;-------------------------------------
;;
;; Pseudo-instruction: branch if greater.
;;
bgt         .macro dst              ;;
            beq cont
            bcs \dst
cont
            .endm


;;-------------------------------------
;;
;; (<label>) .SWORD <value> or ?
;;
;; Declares a word as a hi and lo byte structure to make word manipulation
;; code easier to read.
;;
SWORD       .struct value
lo          .byte <\value
hi          .byte >\value
            .ends


;;--------------------------------------
;;
;; .lea <lo-reg>, <hi-reg>, <value>
;;
;; Load effective address.
;;
lea         .macro  lo, hi, val16
_refins     bit @w \val16                  ; Relocatable address reference.
            ld@1 _refins+1
            ld@2 _refins+2
            .endm


;;--------------------------------------
;;
;; .ldw <lo-reg>, <hi-reg>, <addr>
;;
;; Load word from memory.
;;
ldw         .macro  lo, hi, addr
            ld@1 \addr
            ld@2 \addr + 1
            .endm


;;
;; .stw <lo-reg>, <hi-reg>, <addr>
;;
;; Store word in address.
;;
stw         .macro  lo,hi,addr
            st@1 \addr
            st@2 \addr + 1
            .endm


;;
;; .tww <lo-reg>, <hi-reg>, <src>, <dest>
;;
;; Copy (transfer) word in memory to another memory location.
;;
tww         .macro  lreg,hreg,src,dest
            ld@1 \src
            st@1 \dest
            ld@2 \src + 1
            st@2 \dest + 1
            .endm


align_vector .macro
.if         (* & $00ff) == $00ff
            .byte ?
.endif
            .endm

;;-------------------------------------
;;
;; .Escape <command>
;;
;; Invoke a special internal monitor function.
;;
Escape      .macro command
            brk
            .byte @1
            .endm


;-------------------------------------
;
; Default resume address for command continuation and execution.
;
default_resume = $1000


NEWLINE     = 13
QUOTE       = $22
SPACE       = 32

;-------------------------------------
;
; BRK types
;
BRK_RESET   = 0
BRK_INIT    = 1
BRK_STEP    = 2
BRK_USER    = 3
BRK_CODE    = 4

;-------------------------------------
;
; Span types
;
SPAN_LINES  = 1
SPAN_RANGE  = 2

;-------------------------------------
;
; I/O types
;
IO_SAVE   = 1
IO_LOAD   = 2
IO_VERIFY = 3
