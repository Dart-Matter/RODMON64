
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


;;-------------------------------------
;;
;; ZERO PAGE ASSIGNMENTS
;;
            .virtual    $4B ; ..$65 = 13 words
ZpStart

Arg0        .SWORD  ?   ;; Top
Arg1        .SWORD  ?   ;;
Arg2        .SWORD  ?   ;;
Arg3        .SWORD  ?   ;;
Arg4        .SWORD  ?   ;; Bottom
ArgsLen     = * - Arg0


;;
;; Virtual registers to use for whatever.
;; Library routines try hard not to use these so they are safe
;; across calls by consumers.
Vr0         .SWORD  ?               ;;
Vr1         .SWORD  ?               ;;
Vr2         .SWORD  ?               ;;
Vr3         .SWORD  ?               ;;
Vr4         .SWORD  ?               ;;
Vr5         .SWORD  ?               ;;

;; TEMP is an unsafe temporary.  You must not make calls if you care
;; about the value that is in it across calls.
Tr6         .SWORD  ?               ;;

ZpEnd       = *
            .endvirtual


