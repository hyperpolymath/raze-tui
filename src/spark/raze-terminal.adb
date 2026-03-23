-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Terminal — ANSI escape sequence generation implementation.
--
-- All functions construct byte arrays without performing I/O.
-- GNATprove verifies that all array indices stay within bounds.

package body Raze.Terminal
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Internal helpers
   ---------------------------------------------------------------------------

   -- The ASCII escape character (0x1B).
   ESC : constant Interfaces.C.char := Interfaces.C.char'Val (16#1B#);

   -- Convert a character literal to Interfaces.C.char.
   function C (Ch : Character) return Interfaces.C.char is
     (Interfaces.C.char'Val (Character'Pos (Ch)))
     with Inline;

   -- Build a fixed-string escape sequence from up to 12 characters.
   -- This avoids heap allocation and keeps everything on the stack.
   type Fixed_Str is array (1 .. 12) of Interfaces.C.char;

   function Make_Fixed (S : String) return Escape_Seq
     with Pre => S'Length <= Max_Escape_Length
   is
      Result : Escape_Seq := Empty_Seq;
   begin
      Result.Length := S'Length;
      for I in S'Range loop
         Result.Bytes (I - S'First + 1) := C (S (I));
      end loop;
      return Result;
   end Make_Fixed;

   -- Append a single char to an escape sequence.
   procedure Append_Char (Seq : in out Escape_Seq;
                          Ch  : Interfaces.C.char)
     with Pre  => Seq.Length < Max_Escape_Length,
          Post => Seq.Length = Seq.Length'Old + 1
   is
   begin
      Seq.Length := Seq.Length + 1;
      Seq.Bytes (Seq.Length) := Ch;
   end Append_Char;

   -- Append a decimal number (0..65535) to an escape sequence.
   -- Writes at most 5 digits. Precondition ensures room.
   procedure Append_Num (Seq : in out Escape_Seq;
                         N   : Natural)
     with Pre  => Seq.Length + 5 <= Max_Escape_Length
                  and then N <= 65_535,
          Post => Seq.Length >= Seq.Length'Old
                  and then Seq.Length <= Seq.Length'Old + 5
   is
      Digit_Buf : array (1 .. 5) of Natural;
      Count  : Natural := 0;
      Val    : Natural := N;
   begin
      if Val = 0 then
         Append_Char (Seq, C ('0'));
         return;
      end if;

      -- Extract digits in reverse order.
      while Val > 0 and Count < 5 loop
         Count := Count + 1;
         Digit_Buf (Count) := Val mod 10;
         Val := Val / 10;
      end loop;

      -- Emit digits in forward order.
      for I in reverse 1 .. Count loop
         pragma Loop_Invariant (Seq.Length < Max_Escape_Length);
         Append_Char (Seq, C (Character'Val (Digit_Buf (I) + Character'Pos ('0'))));
      end loop;
   end Append_Num;

   ---------------------------------------------------------------------------
   -- Cursor movement
   ---------------------------------------------------------------------------

   function Cursor_To (Row, Col : Raze.State.Dimension) return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));

      -- Row number
      Append_Num (Seq, Natural (Row));

      -- Separator
      Append_Char (Seq, C (';'));

      -- Column number
      Append_Num (Seq, Natural (Col));

      -- Final byte
      Append_Char (Seq, C ('H'));

      return Seq;
   end Cursor_To;

   function Cursor_Home return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('H'));
      return Seq;
   end Cursor_Home;

   function Cursor_Hide return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('2'));
      Append_Char (Seq, C ('5'));
      Append_Char (Seq, C ('l'));
      return Seq;
   end Cursor_Hide;

   function Cursor_Show return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('2'));
      Append_Char (Seq, C ('5'));
      Append_Char (Seq, C ('h'));
      return Seq;
   end Cursor_Show;

   ---------------------------------------------------------------------------
   -- Screen clearing
   ---------------------------------------------------------------------------

   function Clear_Screen return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('2'));
      Append_Char (Seq, C ('J'));
      return Seq;
   end Clear_Screen;

   function Clear_Line return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('K'));
      return Seq;
   end Clear_Line;

   ---------------------------------------------------------------------------
   -- Text attributes (SGR)
   ---------------------------------------------------------------------------

   function Reset_Attrs return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Reset_Attrs;

   function Set_Bold return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Set_Bold;

   function Set_Italic return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('3'));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Set_Italic;

   function Set_Underline return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('4'));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Set_Underline;

   function Set_FG_RGB (R, G, B : Interfaces.C.unsigned_char) return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ 38 ; 2 ; R ; G ; B m
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('3'));
      Append_Char (Seq, C ('8'));
      Append_Char (Seq, C (';'));
      Append_Char (Seq, C ('2'));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (R));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (G));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (B));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Set_FG_RGB;

   function Set_BG_RGB (R, G, B : Interfaces.C.unsigned_char) return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ 48 ; 2 ; R ; G ; B m
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('4'));
      Append_Char (Seq, C ('8'));
      Append_Char (Seq, C (';'));
      Append_Char (Seq, C ('2'));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (R));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (G));
      Append_Char (Seq, C (';'));
      Append_Num (Seq, Natural (B));
      Append_Char (Seq, C ('m'));
      return Seq;
   end Set_BG_RGB;

   function Apply_Style (S : Raze.Widgets.Style) return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- Reset first to avoid attribute accumulation.
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('0'));

      -- Bold?
      if Boolean (S.Bold) then
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('1'));
      end if;

      -- Italic?
      if Boolean (S.Italic) then
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('3'));
      end if;

      -- Underline?
      if Boolean (S.Underline) then
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('4'));
      end if;

      -- Foreground RGB (only if not default mode = 0).
      if S.FG.Mode /= 0 then
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('3'));
         Append_Char (Seq, C ('8'));
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('2'));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.FG.R));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.FG.G));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.FG.B));
      end if;

      -- Background RGB (only if not default mode = 0).
      if S.BG.Mode /= 0 then
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('4'));
         Append_Char (Seq, C ('8'));
         Append_Char (Seq, C (';'));
         Append_Char (Seq, C ('2'));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.BG.R));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.BG.G));
         Append_Char (Seq, C (';'));
         Append_Num (Seq, Natural (S.BG.B));
      end if;

      -- Close SGR.
      Append_Char (Seq, C ('m'));

      return Seq;
   end Apply_Style;

   ---------------------------------------------------------------------------
   -- Alternate screen buffer
   ---------------------------------------------------------------------------

   function Enter_Alt_Screen return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ ? 1049 h
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('4'));
      Append_Char (Seq, C ('9'));
      Append_Char (Seq, C ('h'));
      return Seq;
   end Enter_Alt_Screen;

   function Leave_Alt_Screen return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ ? 1049 l
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('4'));
      Append_Char (Seq, C ('9'));
      Append_Char (Seq, C ('l'));
      return Seq;
   end Leave_Alt_Screen;

   ---------------------------------------------------------------------------
   -- Mouse tracking
   ---------------------------------------------------------------------------

   function Enable_Mouse return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ ? 1006 h  (SGR mouse mode)
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('6'));
      Append_Char (Seq, C ('h'));
      -- ESC [ ? 1003 h  (any-event tracking)
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('3'));
      Append_Char (Seq, C ('h'));
      return Seq;
   end Enable_Mouse;

   function Disable_Mouse return Escape_Seq is
      Seq : Escape_Seq := Empty_Seq;
   begin
      -- ESC [ ? 1003 l
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('3'));
      Append_Char (Seq, C ('l'));
      -- ESC [ ? 1006 l
      Append_Char (Seq, ESC);
      Append_Char (Seq, C ('['));
      Append_Char (Seq, C ('?'));
      Append_Char (Seq, C ('1'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('0'));
      Append_Char (Seq, C ('6'));
      Append_Char (Seq, C ('l'));
      return Seq;
   end Disable_Mouse;

end Raze.Terminal;
