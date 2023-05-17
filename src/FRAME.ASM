
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
; STACK FRAME ROUTINES
;
; This library implements helpers for implementing local stack frames.
; To add local variables to a routine follow these steps:
;
; 1. Declare the stack frame somewhere at the beginning of your routine.
;
;           .locals
;   myvar1  .byte
;   myvar2  .byte
;           .endlocals
;
;
; 2. Begin your routine code by allocating the stack frame.
;
;           .FRAME.Alloc
;
;
; 3. Access variables in code using
;     the stack pointer as a reference.
;
;           tsx
;           lda arg_a,x
;           sta myvar2,x
;
;
; 4. When exiting the routine deallocate the stack frame.
;
;           .FRAME.Free
;
;
;--------------------------------------
;
; DETAILS

;
; .FRAME.Alloc sets up a stack that looks like this:
;
;           :           :
;      ,--  +-----------+
;      |    |   arg_st  | <-- Old SP
;      |    +-----------+
;      |    |   arg_a   |
;      |    +-----------+
;      |    |   arg_x   |
;           +-----------+
;    frame  |   arg_y   |
;           +-----------+
;      |    :           : <--.
;      |    ~  locals   ~    |
;      |    :           :   base
;      |    +-----------+    |
;      |    |  baseptr  |----
;      `--  +-----------+
;           :           : <-- New SP
;
; The CPU state at the time of frame creation is automatically saved in the
; frame as the arg_* variables.  The CPU state is still the same after the
; frame is constructed, so these variables aren't required to be accessed, but
; allows you destroy the register contents and still have their original
; values available.
;
; The locals space comprises the memory for user-define variables.  Access
; these by referencing the variable name indexed by the current stack pointer.
; This only works seamlessly with the stack pointer located in the position
; resulting at frame creation.  If you want to access variables after pushing
; more data, or from within another sub-routine, you must account for the stack
; pointer movement by adding it to the effective address of the variable
; access, or by adjusting the index.
;
;           tsx
;           lda myvar1,x
;           pha
;           lda myvar2+1,x      ; +1
;  -or-
;           tsx
;           lda myvar1,x
;           pha
;           inx                 ; +1
;           lda myvar2,x
;
;  The arg_* variable are accessed in the same way as user variables.
;
; The baseptr variable should not be modified, and generally should not be used
; at all.  It is used internally when deallocating the frame to quickly reset
; the stack.  One use case for accessing the baseptr from a routine is to read
; values preceding the frame.  For example, to read the return address of a
; routine:
;
;           tsx
;           lda baseptr,x   ; Get base pointer.
;           tax             ; Set base pointer index/reference.
;           lda baseptr+5,x ; Get return address hi.
;           tay
;           lda baseptr+4,x ; Get return address lo.
;
; When the frame is freed, the stack pointer is returned to its old value and
; the CPU state is loaded from the arg_* variables.  The arg_* values should
; therefore be used to set your desired return state/values.
;


;;--------------------------------------
;;
;; Opens a frame declaration.
;;
locals      .segment                    ;;
            pc_save := *
            * = $101
baseptr     .byte ?
            .endsegment

;;-------------------------------------
;;
;; Closes a frame definition.
;;
;; These are used as both input arguments and return values.
endlocals   .segment                  ;;
arg_y       .byte ?                     ;;
arg_x       .byte ?                     ;;
arg_a       .byte ?                     ;;
arg_st      .byte ?                     ;;
            frame_top := *
            * = pc_save
            .endsegment


FRAME       .block


;--------------------------------------
;
; JSR _setframe
;
; Adjust the stack to create a frame of local variables.  This must
; only be called from FRAME.Alloc.
;
; IN:       A = Size of frame to allocate.
;
;       :           :
;       +-----------+
;       |   arg_st  | <-- (Old SP)
;       +-----------+
;       |   arg_a   |    SP + $103
;       +-----------+
;       | return hi |    SP + $102
;       +-----------+
;       | return lo |    SP + $101
;       +-----------+
;       :           : <--SP + $100
;
; OUT:      A,X,Y and flags from stack caller's original state.
;
; SAFE:     X,Y
;
;
_setframe   .proc

; Alias for temporary word.
return_target = Tr6

            pha                         ; Save frame size.
            txa                         ; Get copy of original X.
            pha                         ; Save for arg_x.
;
;       :           :
;       +-----------+
;       |   arg_st  | <-- (Old SP)
;       +-----------+
;       |   arg_a   |
;       +-----------+
;       | return hi |     SP + $104
;       +-----------+
;       | return lo |     SP + $103
;       +-----------+
;       |   size    |     SP + $102
;       +-----------+
;       |     x     |     SP + $101
;       +-----------+
;       :           : <-- SP + $100
;
            ; Save return address as jump destination.
            tsx                         ; Prepare to reference stack.
            lda $103,x                  ; Get return lo.
            clc                         ; Clear carry.
            adc #1                      ; Add 1 for PC value after return.
            sta return_target + 0       ; Save to temporary lo.
            lda $104,x                  ; Get return hi.
            adc #0                      ; Add carry.
            sta return_target + 1       ; Save to temporary hi.

            ; Set arg_y and arg_x.
            tya                         ; Get original Y.
            sta $103,x                  ; Save to arg_y.
            lda $101,x                  ; Get original X.
            sta $104,x                  ; Save to arg_x.
;
;       :           :
;       +-----------+
;       |   arg_st  | <-- (Old SP)
;       +-----------+
;       |   arg_a   |
;       +-----------+
;       |   arg_x   |     SP + $104
;       +-----------+
;       |   arg_y   |     SP + $103
;       +-----------+
;       |   size    |     SP + $102
;       +-----------+
;       |     x     |     SP + $101
;       +-----------+
;       :           : <-- SP + $100
;
            lda $102,x                  ; Get frame size.
            tay                         ; Copy size to Y.

            ; A = base.
            inx                         ; Discard stack X backup.
            inx                         ; Discard stack frmae size.
            txs                         ; Set SP to unallocated base.
;
;       :           :
;       +-----------+
;       |   arg_st  | <-- (Old SP)
;       +-----------+
;       |   arg_a   |
;       +-----------+
;       |   arg_x   |
;       +-----------+
;       |   arg_y   |
;       +-----------+
;       :           : <-- base -- SP
;
            ; 4 bytes of the frame are already on the stack, so we reduce the
            ; remaining size to allocate by 4 bytes.
            ;
            dey
            dey
            dey
            dey

            ; Allocate the remainder of the frame starting at base.
            lda #0                      ; Zero init the allocation.
-           pha                         ; Allocate and initialize 1 byte.
            dey                         ; Decrement ramining size.
            bne -                       ; Repeat until none remaining.

;       :           :
;       +-----------+
;       |   arg_st  | <-- base + $104
;       +-----------+
;       |   arg_a   |     base + $103
;       +-----------+
;       |   arg_x   |     base + $102
;       +-----------+
;       |   arg_y   |     base + $101
;       +-----------+
;       :           : <-- base + $100
;       ~  locals   ~
;       :           :
;       +-----------+
;       |  baseptr  |     SP + $101
;       +-----------+
;       :           : <-- SP + $100

            txa                         ; Save base address to A.
            tsx                         ; Get new stack pointer.
            sta $101,x                  ; Save base address to base pointer.

            tax                         ; Reference base address.
            lda @w $101+3,x             ; Get original flags from arg_st.
            pha                         ; Stash them.
            lda @w $101+2,x             ; Get original A from arg_a.
            pha                         ; Stash it.
            lda @w $101+0,x             ; Get original Y from arg_y.
            tay                         ; Restore Y.
            lda @w $101+1,x             ; Get original X from arg_x.
            tax                         ; Restore X.
            pla                         ; Restore A.
            plp                         ; Restore flags.
            jmp (return_target)         ; Return to frame consumer.
            .endproc ; _setframe


;--------------------------------------
;
; jsr _freeframe
;
; Unwinds the stack.  The stack pointer must be positioned at the location
; after a previous _setframe.
;
; SAFE:     None.
;
_freeframe  .proc

; Alias for temporary word.
return_target = Tr6

            ; Save return address as jump destination.
            clc                         ; Clear carry.
            pla                         ; Get return address lo.
            adc #1                      ; Add 1 for PC value after return.
            sta return_target + 0       ; Save to temporary lo.
            pla                         ; Get return hi.
            adc #0                      ; Add carry.
            sta return_target + 1       ; Save to temporary hi.
            pla                         ; Get base address.
            tax                         ; Copy to X.
            txs                         ; Set stack to base address.
            pla                         ; Get arg_y.
            tay                         ; Return in Y.
            pla                         ; Get arg_x.
            tax                         ; Return in X.
            pla                         ; Return arg_a in A.
            plp                         ; Return arg_st in CPU flags.
            jmp (return_target)         ; Return to frame consumer.
            .endproc


;;-------------------------------------
;;
;; FRAME.Alloc (inlined)
;;
;; Creates a standard stack frame with space for local variables.
;;
;; IN:      frametop set by .endlocals
;;
;; SAFE:    None.
;;
Alloc       .macro
            php                         ; Save CPU flags before all else.
            pha                         ; Save A so we can pass frame size.
            lda #(frame_top - $101)     ; Set A to frame size.
            jsr FRAME._setframe         ; Allocate the frame.
            .endm


;;-------------------------------------
;;
;; FRAME.Free (inlined)
;;
;; Frees a stack frame and sets the CPU state that contained in the frame.
;;
;; IN:      None.
;;
;; OUT:     A,X,Y,flags copied from arg_*.
;;
;; SAFE: None.
;;
Free        .macro
            jsr FRAME._freeframe        ; Deallocate frame and set CPU state.
            .endm


            .endblock ; FRAME
