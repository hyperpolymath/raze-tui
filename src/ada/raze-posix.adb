-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Posix — POSIX terminal I/O wrapper implementation.
--
-- Uses pragma Import to call C library functions directly.
-- This is the ONLY file in the project that touches POSIX calls.

with System;
with Interfaces.C; use Interfaces.C; use type Interfaces.C.int;
with Raze.Terminal;
with Raze.Input_Parser;

package body Raze.Posix is

   ---------------------------------------------------------------------------
   -- C types and constants
   ---------------------------------------------------------------------------

   -- termios structure size varies by platform; we use an opaque buffer
   -- large enough for Linux (60 bytes) and macOS (72 bytes).
   Termios_Size : constant := 128;
   type Termios_Buffer is array (1 .. Termios_Size) of Interfaces.C.unsigned_char;

   -- File descriptors.
   STDIN_FD  : constant := 0;
   STDOUT_FD : constant := 1;

   -- tcsetattr actions.
   TCSAFLUSH : constant := 2;

   -- ioctl request for terminal size (Linux).
   TIOCGWINSZ : constant := 16#5413#;

   -- winsize structure (matches Linux/macOS struct winsize).
   type Winsize is record
      WS_Row    : Interfaces.C.unsigned_short;
      WS_Col    : Interfaces.C.unsigned_short;
      WS_Xpixel : Interfaces.C.unsigned_short;
      WS_Ypixel : Interfaces.C.unsigned_short;
   end record
     with Convention => C;

   -- termios flag constants (Linux values).
   -- These are combined to configure raw mode.
   ECHO_FLAG    : constant := 16#0008#;  -- ECHO
   ICANON_FLAG  : constant := 16#0002#;  -- ICANON
   ISIG_FLAG    : constant := 16#0001#;  -- ISIG
   IEXTEN_FLAG  : constant := 16#8000#;  -- IEXTEN
   IXON_FLAG    : constant := 16#0400#;  -- IXON
   ICRNL_FLAG   : constant := 16#0100#;  -- ICRNL
   OPOST_FLAG   : constant := 16#0001#;  -- OPOST

   -- fcntl constants for non-blocking I/O.
   F_GETFL     : constant := 3;
   F_SETFL     : constant := 4;
   O_NONBLOCK  : constant := 16#0800#;

   ---------------------------------------------------------------------------
   -- Imported C functions
   ---------------------------------------------------------------------------

   function C_tcgetattr (FD : int; Termios : System.Address) return int
     with Import, Convention => C, External_Name => "tcgetattr";

   function C_tcsetattr (FD : int; Action : int;
                         Termios : System.Address) return int
     with Import, Convention => C, External_Name => "tcsetattr";

   function C_ioctl (FD : int; Request : unsigned_long;
                     Arg : System.Address) return int
     with Import, Convention => C, External_Name => "ioctl";

   function C_read (FD : int; Buf : System.Address;
                    Count : size_t) return Interfaces.C.ptrdiff_t
     with Import, Convention => C, External_Name => "read";

   function C_write (FD : int; Buf : System.Address;
                     Count : size_t) return Interfaces.C.ptrdiff_t
     with Import, Convention => C, External_Name => "write";

   function C_fcntl_get (FD : int; Cmd : int) return int
     with Import, Convention => C, External_Name => "fcntl";

   function C_fcntl_set (FD : int; Cmd : int; Arg : int) return int
     with Import, Convention => C, External_Name => "fcntl";

   function C_isatty (FD : int) return int
     with Import, Convention => C, External_Name => "isatty";

   procedure C_fflush (Stream : System.Address)
     with Import, Convention => C, External_Name => "fflush";

   -- stdout FILE* pointer.
   Stdout_Ptr : System.Address
     with Import, Convention => C, External_Name => "stdout";

   ---------------------------------------------------------------------------
   -- Module state
   ---------------------------------------------------------------------------

   -- Saved termios for restoration on disable.
   Original_Termios : Termios_Buffer := (others => 0);
   Raw_Mode_Active  : Boolean := False;
   Original_Flags   : int := 0;

   ---------------------------------------------------------------------------
   -- Raw mode
   ---------------------------------------------------------------------------

   function Enable_Raw_Mode return Boolean is
      Raw     : Termios_Buffer;
      Result  : int;
      Flags   : int;
   begin
      -- Check if stdin is a terminal.
      if C_isatty (STDIN_FD) = 0 then
         return False;
      end if;

      -- Save original termios.
      Result := C_tcgetattr (STDIN_FD, Original_Termios'Address);
      if Result /= 0 then
         return False;
      end if;

      -- Copy original to working buffer.
      Raw := Original_Termios;

      -- Modify the termios structure for raw mode.
      -- We manipulate the flag fields at known offsets in the buffer.
      -- Linux termios layout (all 32-bit fields):
      --   offset 0:  c_iflag
      --   offset 4:  c_oflag
      --   offset 8:  c_cflag
      --   offset 12: c_lflag
      --
      -- We clear specific bits in each flag field by writing back
      -- the modified bytes. This is the most portable approach that
      -- avoids importing the full termios record definition.

      -- For simplicity and portability, we use the cfmakeraw approach:
      -- Clear ECHO, ICANON, ISIG, IEXTEN from c_lflag (offset 12).
      declare
         LFlag : Interfaces.C.unsigned := 0;
      begin
         LFlag := Interfaces.C.unsigned (Raw (13)) * 256 +
                  Interfaces.C.unsigned (Raw (14)) * 65536 +
                  Interfaces.C.unsigned (Raw (15)) * 16777216 +
                  Interfaces.C.unsigned (Raw (16)) * 0 +
                  Interfaces.C.unsigned (Raw (13));
         -- This byte-manipulation approach is fragile. Use a simpler method:
         -- Just set raw mode by calling tcsetattr after zeroing the right bits.
         null;
      end;

      -- Apply raw termios. We'll use the raw buffer directly since
      -- the C library will interpret the structure correctly.
      -- For a robust implementation, clear the relevant flag bits.
      -- Given the complexity of byte manipulation, we take the pragmatic
      -- approach: modify the copy in-place at known Linux offsets.

      -- c_iflag (offset 0, 4 bytes little-endian): clear IXON | ICRNL
      Raw (1) := Raw (1) and not Interfaces.C.unsigned_char (IXON_FLAG mod 256);
      Raw (2) := Raw (2) and not Interfaces.C.unsigned_char (IXON_FLAG / 256 mod 256);
      Raw (1) := Raw (1) and not Interfaces.C.unsigned_char (ICRNL_FLAG mod 256);
      Raw (2) := Raw (2) and not Interfaces.C.unsigned_char (ICRNL_FLAG / 256 mod 256);

      -- c_oflag (offset 4, 4 bytes): clear OPOST
      Raw (5) := Raw (5) and not Interfaces.C.unsigned_char (OPOST_FLAG mod 256);

      -- c_lflag (offset 12, 4 bytes): clear ECHO | ICANON | ISIG | IEXTEN
      Raw (13) := Raw (13) and not Interfaces.C.unsigned_char (ECHO_FLAG mod 256);
      Raw (13) := Raw (13) and not Interfaces.C.unsigned_char (ICANON_FLAG mod 256);
      Raw (13) := Raw (13) and not Interfaces.C.unsigned_char (ISIG_FLAG mod 256);
      Raw (14) := Raw (14) and not Interfaces.C.unsigned_char (IEXTEN_FLAG / 256 mod 256);

      -- Set VMIN = 0, VTIME = 1 (100ms timeout) for non-blocking-ish reads.
      -- c_cc array starts at offset 17 on Linux. VMIN = index 6, VTIME = index 5.
      -- Actual offsets: c_cc starts at byte 17, so VMIN = 17+6 = 23, VTIME = 17+5 = 22.
      if Termios_Size >= 24 then
         Raw (23) := 0;  -- VMIN = 0
         Raw (22) := 1;  -- VTIME = 1 (100ms)
      end if;

      Result := C_tcsetattr (STDIN_FD, TCSAFLUSH, Raw'Address);
      if Result /= 0 then
         return False;
      end if;

      -- Save original fcntl flags and set non-blocking.
      Original_Flags := C_fcntl_get (STDIN_FD, F_GETFL);
      Flags := C_fcntl_set (STDIN_FD, F_SETFL,
                            int (unsigned (Original_Flags) or unsigned (O_NONBLOCK)));
      pragma Unreferenced (Flags);

      Raw_Mode_Active := True;
      return True;
   end Enable_Raw_Mode;

   procedure Disable_Raw_Mode is
      Result : int;
      Flags  : int;
   begin
      if not Raw_Mode_Active then
         return;
      end if;

      -- Restore original termios.
      Result := C_tcsetattr (STDIN_FD, TCSAFLUSH, Original_Termios'Address);
      pragma Unreferenced (Result);

      -- Restore original fcntl flags.
      Flags := C_fcntl_set (STDIN_FD, F_SETFL, Original_Flags);
      pragma Unreferenced (Flags);

      Raw_Mode_Active := False;
   end Disable_Raw_Mode;

   ---------------------------------------------------------------------------
   -- Terminal size
   ---------------------------------------------------------------------------

   procedure Get_Terminal_Size (Width  : out Interfaces.C.unsigned_short;
                                Height : out Interfaces.C.unsigned_short) is
      WS     : Winsize := (0, 0, 0, 0);
      Result : int;
   begin
      Result := C_ioctl (STDOUT_FD, unsigned_long (TIOCGWINSZ), WS'Address);
      if Result = 0 and WS.WS_Col > 0 and WS.WS_Row > 0 then
         Width  := WS.WS_Col;
         Height := WS.WS_Row;
      else
         -- Fallback to VT100 defaults.
         Width  := 80;
         Height := 24;
      end if;
   end Get_Terminal_Size;

   ---------------------------------------------------------------------------
   -- Non-blocking byte read
   ---------------------------------------------------------------------------

   procedure Read_Input (Buf       : out Raze.Input_Parser.Input_Buffer;
                         Bytes_Read : out Natural) is
      Raw_Buf : Raze.Input_Parser.Input_Bytes := (others => 0);
      N       : Interfaces.C.ptrdiff_t;
   begin
      Buf := Raze.Input_Parser.Empty_Input;
      Bytes_Read := 0;

      N := C_read (STDIN_FD, Raw_Buf'Address,
                   size_t (Raze.Input_Parser.Max_Input_Length));

      if N > 0 then
         Bytes_Read := Natural (N);
         if Bytes_Read > Raze.Input_Parser.Max_Input_Length then
            Bytes_Read := Raze.Input_Parser.Max_Input_Length;
         end if;

         Buf.Bytes := Raw_Buf;
         Buf.Length := Bytes_Read;
      end if;
   end Read_Input;

   ---------------------------------------------------------------------------
   -- Terminal output
   ---------------------------------------------------------------------------

   procedure Write_Escape (Seq : Raze.Terminal.Escape_Seq) is
      N : Interfaces.C.ptrdiff_t;
   begin
      if Seq.Length > 0 then
         N := C_write (STDOUT_FD, Seq.Bytes'Address, size_t (Seq.Length));
         pragma Unreferenced (N);
      end if;
   end Write_Escape;

   procedure Write_Str (S : String) is
      N : Interfaces.C.ptrdiff_t;
   begin
      if S'Length > 0 then
         N := C_write (STDOUT_FD, S (S'First)'Address, size_t (S'Length));
         pragma Unreferenced (N);
      end if;
   end Write_Str;

   procedure Flush_Output is
   begin
      C_fflush (Stdout_Ptr);
   end Flush_Output;

end Raze.Posix;
