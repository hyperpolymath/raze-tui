-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Input_Parser — ANSI escape sequence parser implementation.
--
-- Pure function: no I/O, no side effects. GNATprove verifies that
-- all array accesses are within bounds and that Consumed never
-- exceeds the buffer length.

with Raze.Events; use Raze.Events;

package body Raze.Input_Parser
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Internal helpers
   ---------------------------------------------------------------------------

   -- Make a key event with optional modifiers.
   function Key_Event (Code : Interfaces.C.unsigned;
                       Mods : Raze.Events.Modifiers :=
                         Raze.Events.Mod_None) return Raze.Events.Event is
     (Raze.Events.Event'(Kind     => Raze.Events.Event_Key,
                          Key_Code => Code,
                          Mods     => Mods,
                          Mouse_X  => 0,
                          Mouse_Y  => 0));

   -- Check if a byte is a digit (0x30..0x39).
   function Is_Digit (B : Interfaces.C.unsigned_char) return Boolean is
     (B >= 16#30# and B <= 16#39#);

   -- Convert an ASCII digit byte to its numeric value.
   function Digit_Value (B : Interfaces.C.unsigned_char) return Natural is
     (Natural (B) - 16#30#)
     with Pre => Is_Digit (B);

   ---------------------------------------------------------------------------
   -- CSI sequence parser (ESC [ ...)
   ---------------------------------------------------------------------------

   -- Parse a CSI sequence starting after ESC [.
   -- Buf(Offset) is the first byte after '['.
   -- Returns the parsed event and total bytes consumed (including ESC [).
   function Parse_CSI (Buf    : Input_Buffer;
                       Offset : Positive) return Parse_Result
     with Pre  => Offset <= Buf.Length
                  and then Buf.Length <= Max_Input_Length,
          Post => Parse_CSI'Result.Consumed <= Buf.Length
   is
      Pos   : Natural := Offset;
      Param : Natural := 0;
   begin
      -- Check if we have at least one byte after ESC [.
      if Pos > Buf.Length then
         return No_Parse;
      end if;

      -- Collect optional numeric parameter.
      if Is_Digit (Buf.Bytes (Pos)) then
         while Pos <= Buf.Length and then Is_Digit (Buf.Bytes (Pos)) loop
            pragma Loop_Invariant (Pos >= Offset and Pos <= Buf.Length);
            pragma Loop_Invariant (Param <= 65_535);
            if Param <= 6553 then
               Param := Param * 10 + Digit_Value (Buf.Bytes (Pos));
            end if;
            Pos := Pos + 1;
         end loop;

         -- Need the final byte after the parameter.
         if Pos > Buf.Length then
            return No_Parse;
         end if;

         -- Tilde-terminated sequences: ESC [ <num> ~
         if Buf.Bytes (Pos) = Character'Pos ('~') then
            declare
               Code : Interfaces.C.unsigned := 0;
            begin
               case Param is
                  when 1  => Code := Key_Home;
                  when 2  => Code := Key_Insert;
                  when 3  => Code := Key_Delete;
                  when 4  => Code := Key_End;
                  when 5  => Code := Key_Page_Up;
                  when 6  => Code := Key_Page_Down;
                  when 11 => Code := Key_F1;
                  when 12 => Code := Key_F2;
                  when 13 => Code := Key_F3;
                  when 14 => Code := Key_F4;
                  when 15 => Code := Key_F5;
                  when 17 => Code := Key_F6;
                  when 18 => Code := Key_F7;
                  when 19 => Code := Key_F8;
                  when 20 => Code := Key_F9;
                  when 21 => Code := Key_F10;
                  when 23 => Code := Key_F11;
                  when 24 => Code := Key_F12;
                  when others => Code := 0;
               end case;

               if Code /= 0 then
                  return Parse_Result'(Event    => Key_Event (Code),
                                       Consumed => Pos);
               else
                  -- Unrecognised tilde sequence; consume and ignore.
                  return Parse_Result'(Event    => Raze.Events.No_Event,
                                       Consumed => Pos);
               end if;
            end;
         end if;
      end if;

      -- Single-letter final bytes (no parameter, or parameter ignored).
      case Buf.Bytes (Pos) is
         when Character'Pos ('A') =>
            return Parse_Result'(Event    => Key_Event (Key_Up),
                                 Consumed => Pos);
         when Character'Pos ('B') =>
            return Parse_Result'(Event    => Key_Event (Key_Down),
                                 Consumed => Pos);
         when Character'Pos ('C') =>
            return Parse_Result'(Event    => Key_Event (Key_Right),
                                 Consumed => Pos);
         when Character'Pos ('D') =>
            return Parse_Result'(Event    => Key_Event (Key_Left),
                                 Consumed => Pos);
         when Character'Pos ('H') =>
            return Parse_Result'(Event    => Key_Event (Key_Home),
                                 Consumed => Pos);
         when Character'Pos ('F') =>
            return Parse_Result'(Event    => Key_Event (Key_End),
                                 Consumed => Pos);
         when others =>
            -- Unrecognised CSI sequence; consume what we have.
            return Parse_Result'(Event    => Raze.Events.No_Event,
                                 Consumed => Pos);
      end case;
   end Parse_CSI;

   ---------------------------------------------------------------------------
   -- Main parse function
   ---------------------------------------------------------------------------

   function Parse (Buf : Input_Buffer) return Parse_Result is
      B : Interfaces.C.unsigned_char;
   begin
      -- Empty buffer: nothing to parse.
      if Buf.Length = 0 then
         return No_Parse;
      end if;

      B := Buf.Bytes (1);

      -- ESC (0x1B): start of escape sequence or standalone ESC key.
      if B = 16#1B# then
         -- If ESC is the only byte, it's the Escape key.
         if Buf.Length = 1 then
            return Parse_Result'(Event    => Key_Event (Key_Escape),
                                 Consumed => 1);
         end if;

         -- ESC [ ... : CSI sequence.
         if Buf.Bytes (2) = Character'Pos ('[') then
            if Buf.Length >= 3 then
               return Parse_CSI (Buf, 3);
            else
               -- Incomplete CSI sequence; wait for more data.
               return No_Parse;
            end if;
         end if;

         -- ESC + other: Alt+key.
         return Parse_Result'(
           Event    => Key_Event (Interfaces.C.unsigned (Buf.Bytes (2)),
                                  Raze.Events.Mod_Alt),
           Consumed => 2);
      end if;

      -- Ctrl+letter (0x01..0x1A, excluding Tab=0x09, Enter=0x0D, ESC=0x1B).
      if B >= 16#01# and B <= 16#1A# and B /= 16#09# and B /= 16#0D# then
         return Parse_Result'(
           Event    => Key_Event (
             Interfaces.C.unsigned (B) + Character'Pos ('a') - 1,
             Raze.Events.Mod_Ctrl),
           Consumed => 1);
      end if;

      -- Enter key (CR = 0x0D).
      if B = 16#0D# then
         return Parse_Result'(Event    => Key_Event (Key_Enter),
                              Consumed => 1);
      end if;

      -- Tab key (HT = 0x09).
      if B = 16#09# then
         return Parse_Result'(Event    => Key_Event (Key_Tab),
                              Consumed => 1);
      end if;

      -- Backspace (DEL = 0x7F).
      if B = 16#7F# then
         return Parse_Result'(Event    => Key_Event (Key_Backspace),
                              Consumed => 1);
      end if;

      -- Printable ASCII (0x20..0x7E).
      if B >= 16#20# and B <= 16#7E# then
         return Parse_Result'(
           Event    => Key_Event (Interfaces.C.unsigned (B)),
           Consumed => 1);
      end if;

      -- Unrecognised byte: consume and ignore.
      return Parse_Result'(Event    => Raze.Events.No_Event,
                           Consumed => 1);
   end Parse;

end Raze.Input_Parser;
