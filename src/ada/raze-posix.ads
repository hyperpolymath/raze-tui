-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Posix — POSIX terminal I/O wrapper (non-SPARK).
--
-- This package wraps POSIX system calls for terminal raw mode,
-- non-blocking reads, writes, and SIGWINCH handling. It is
-- intentionally NOT SPARK_Mode because POSIX FFI is inherently
-- impure and unverifiable.
--
-- The Raze architecture keeps this layer as thin as possible:
--   * Raw mode enable/disable (tcgetattr/tcsetattr)
--   * Non-blocking byte read (read with O_NONBLOCK)
--   * Byte buffer write (write to stdout)
--   * Terminal size query (ioctl TIOCGWINSZ)
--
-- All business logic is in the SPARK-proved packages.

with Interfaces.C; use Interfaces.C;
with Raze.Terminal;
with Raze.Input_Parser;

package Raze.Posix is

   ---------------------------------------------------------------------------
   -- Raw mode
   ---------------------------------------------------------------------------

   -- Enable raw terminal mode. Saves the original termios settings
   -- and configures stdin for character-at-a-time input with no echo.
   -- Returns True on success, False on failure (e.g. not a terminal).
   function Enable_Raw_Mode return Boolean;

   -- Restore the original terminal settings saved by Enable_Raw_Mode.
   -- Safe to call even if Enable_Raw_Mode was never called.
   procedure Disable_Raw_Mode;

   ---------------------------------------------------------------------------
   -- Terminal size
   ---------------------------------------------------------------------------

   -- Query the terminal dimensions via ioctl(TIOCGWINSZ).
   -- On failure, returns the defaults (80x24).
   procedure Get_Terminal_Size (Width  : out Interfaces.C.unsigned_short;
                                Height : out Interfaces.C.unsigned_short);

   ---------------------------------------------------------------------------
   -- Non-blocking byte read
   ---------------------------------------------------------------------------

   -- Attempt to read bytes from stdin into an Input_Buffer.
   -- Returns the number of bytes actually read (0 if none available).
   -- The read is non-blocking.
   procedure Read_Input (Buf       : out Raze.Input_Parser.Input_Buffer;
                         Bytes_Read : out Natural);

   ---------------------------------------------------------------------------
   -- Terminal output
   ---------------------------------------------------------------------------

   -- Write an escape sequence to stdout.
   procedure Write_Escape (Seq : Raze.Terminal.Escape_Seq);

   -- Write a raw string to stdout.
   procedure Write_Str (S : String);

   -- Flush stdout.
   procedure Flush_Output;

end Raze.Posix;
