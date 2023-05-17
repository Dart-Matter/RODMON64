
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

            .include "C64.ASM"

;--------------------------------------
;
; Zero page locattions (required)
;
; The monitor needs zero page for various things; the usage is not important
; to the platform.  Declare them in the global scope using the following
; pattern:
;
;           .virtual    <zero-page base address>
; <name>    .<type>
;               .
;               .
;               .
;           .endvirtual
;
; This can be done multiple times if the available zero page addresses are not
; contiguous.  The required values and types are:
;
;   Virtual registers to use for whatever.  Library routines try hard not to 
;   use these so they are safe across calls by consumers.
;
;       Vr0         .SWORD  ?
;       Vr1         .SWORD  ?
;       Vr2         .SWORD  ?
;       Vr3         .SWORD  ?
;       Vr4         .SWORD  ?
;       Vr5         .SWORD  ?
;
;   TEMP is an unsafe temporary location.  You must not make calls if you care
;   about the value that is in this across calls.
;
;       Tr6         .SWORD  ?
;
;   The command argument stack.
;
;       Arg0        .SWORD  ?
;       Arg1        .SWORD  ?
;       Arg2        .SWORD  ?
;       Arg3        .SWORD  ?
;       Arg4        .SWORD  ?

;--------------------------------------
;
; BSS_BASE = Start of working RAM.
;

;--------------------------------------
;
; jsr PLATFORM.BackupZp (optional)
;
; Backup the contents of declared zero page locations.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     A,X,Y
;

;--------------------------------------
;
; jsr PLATFORM.RestoreZp (optional)
;
; Restore the contents of declared zero page locations.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     A,X,Y
;

;--------------------------------------
;
; jsr PLATFORM.CharOut (required)
;
; Print an ASCII terminal character.
;
; IN:       A = Character to print.
;
; OUT:      CF = 0 (success).
;
; SAFE:     A,X,Y
;

;--------------------------------------
;
; jsr PLATFORM.SymbolOut (required)
;
; Output a visible character representing either terminal or alternate code.
;
; This routine is used when dumping characters from memory, so it must not
; issue control commands or result in any side effects.  A code point is any
; value 0 to 255.
;
; Terminal is whatever ASCII like encoding is used natively by the platform;
; this is characterset used by the monitor command interface.  Control codes
; must be represented by a visible character.  Preferably these characters
; will be distinguishable as the respective control code using special
; characters and/or display attributes.
;
; Alternate code is another mapping supported by the platform such as the video
; character generator encoding.  Unused code points are preferably
; distinguished using special display attribute.
;
; IN:       A = Character to dump.
;
; OUT:      CF = 0 (success).
;
; SAFE:     None.
;

;--------------------------------------
;
; jsr PLATFORM.QuoteOut (required)
;
; Print a quote character.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     A,X,Y
;

;-------------------------------------
;
; jsr PLATFORM.Newline (required)
;
; Move output position to start of next line.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     X,Y
;

;-------------------------------------
;
; jsr PLATFORM.Overwrite (required)
;
; Move output position to overwrite command line.  If this is not practical to
; do, defer to PLATFORM.Newline or emit nothing if already at the beginning of
; the next line.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     X,Y
;

;--------------------------------------
;
; jsr PLATFORM.CharIn (required)
;
; Wait for and read an ASCII terminal character.
; Returns NEWLINE when end of line input is reached.
;
; IN:       None.
;
; OUT:      A = character
;           CF = 0 (success).
;
; SAFE:     X,Y
;

;--------------------------------------
;
; jsr PLATFORM.StopKeyIn (required)
;
; Indicates if the run/stop key is pressed.
;
; IN:       None.
;
; OUT:      ZF = 1 (beq) : Stop key is pressed.
;                0 (bne) : Stop key not pressed.
;           CF = 0.
;
; SAFE:     A,X,Y
;

;---------------------------------------
;
; jsr PLATFORM.NormalizeBrk (required)
;
; Does whatever is need to invoke the platform BRK handler with a common
; monitor defined state.   Example variations are hooking the IRQ to produce
; a BRK callout, or hooking an existing BRK vector.
;
; The common state is a "user" stack containing the following:
;
;       :           :
;       +-----------+
;       | return hi |     SP + $106
;       +-----------+
;       | return lo |     SP + $105
;       +-----------+
;       |  status   |     SP + $104
;       +-----------+
;       |accumulator|     SP + $103
;       +-----------+
;       |     x     |     SP + $102
;       +-----------+
;       |     y     |     SP + $101
;       +-----------+
;       :           : <-- SP + $100
;
; and CPU registers contain their respective values.
;
; RODMON should set RAM.MonBrk before calling this.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     None.
;

;---------------------------------------
;
; jsr PLATFORM.LoadPriEncName (required)
;
; Gets the name of the primary terminal character encoding, e.g. "ASCII".
;
; IN:       None.
;
; OUT:      X = Name string address lo.
;           Y = Name string address hi.
;           CF = 0.
;
; SAFE:     A
;

;---------------------------------------
;
; jsr PLATFORM.LoadAltEncName (required)
;
; Gets the name of the alternate character encoding, e.g. "FRAME BUFFER".
;
; IN:       None.
;
; OUT:      X = Name string address lo.
;           Y = Name string address hi.
;           CF = 0.
;
; SAFE:     A
;

;---------------------------------------
;
; jsr PLATFORM.IsBrkPage
;
; Tests if a breakpoint can be set on the specified page.
;
; IN:       X = Page number.
;
; OUT:      ZF = Is breakable.
;

;---------------------------------------
;
; jsr PLATFORM.RestoreBrk (required)
;
; Undo platform BRK normalization such that interrupts and breaks behave as
; before starting the monitor.  This is called when exiting the monitor.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     X.
;

;---------------------------------------
;
; jsr PLATFORM.Save (required)
;
; Saves data to a device.
;
; If anything goes wrong the routine escapes with an appropriate error.
;
; IN:       A = number of Args specified by user.
;           X = IO_SAVE
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
; OUT:      CF = 0.
;
; SAFE:     None.
;

;---------------------------------------
;
; jsr PLATFORM.Load (required)
;
; Loads data from a device.
;
; If anything goes wrong the routine escapes with an appropriate error.
;
; IN:       A = number of Args specified by user.
;           X = IO_LOAD
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
; OUT:      CF = 0.
;
; SAFE:     None.
;

;---------------------------------------
;
; jsr PLATFORM.Verify (required)
;
; Compares data in memory with a file.
;
; If anything goes wrong the routine escapes with an appropriate error.
;
; IN:       A = number of Args specified by user.
;           X = IO_VERIFY
;           RAM.String = Filename.
;           RAM.StrLen = Filename length.
;
; OUT:      ZF = memory and file match.
;           CF = 0.
;
; SAFE:     None.
;

;---------------------------------------
;
; jsr PLATFORM.VisualizeBrk (optional)
;
; Shows a visual indicator of the type of BRK that was hit during execution.
; The intention here is to alert the user from afar while they are waiting for
; their code to run while eating lunch that something has been encountered.
; Just rts if not implemented.
;
; IN:       X = BRK type.
;
; OUT:      CF = 0.
;
; SAFE:     A,X,Y.
;

;---------------------------------------
;
; jsr PLATFORM.TerminalReset (optional)
;
; Prepares the terminal for input/output.  This is intended for cases where
; the monitor is entered, either explicitly or through a breakpoint, and the
; terminal communication may be in an unknown state.
;
; IN:       None.
;
; OUT:      CF = 0.
;
; SAFE:     A,X,Y.
;

