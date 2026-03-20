-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Input_Parser — SPARK-proved ANSI escape sequence parser.
--
-- This package takes raw byte buffers (read from stdin by the
-- non-SPARK Raze.Posix layer) and parses them into Raze.Events.Event
-- records. The parser is a pure function: no I/O, no global state,
-- fully provable.
--
-- Supported sequences:
--   * Single printable characters → Event_Key (key_code = char value)
--   * ESC [ A/B/C/D → Arrow keys (Up/Down/Right/Left)
--   * ESC [ 1 ~ .. ESC [ 6 ~ → Home/Insert/Delete/End/PgUp/PgDn
--   * ESC [ <params> M/m → SGR mouse events
--   * Ctrl+<letter> → Event_Key with Mod_Ctrl
--   * ESC alone → Event_Key (key_code = 27)

with Interfaces.C; use Interfaces.C;
with Raze.Events;

package Raze.Input_Parser
  with SPARK_Mode => On,
       Pure
is
   ---------------------------------------------------------------------------
   -- Input buffer type
   ---------------------------------------------------------------------------

   -- Maximum input buffer size. Escape sequences are at most ~20 bytes;
   -- 32 provides headroom for SGR mouse sequences.
   Max_Input_Length : constant := 32;

   subtype Input_Index is Natural range 0 .. Max_Input_Length;
   type Input_Bytes is array (1 .. Max_Input_Length) of Interfaces.C.unsigned_char;

   type Input_Buffer is record
      Bytes  : Input_Bytes;
      Length : Input_Index;
   end record;

   -- The empty input buffer.
   Empty_Input : constant Input_Buffer :=
     (Bytes  => (others => 0),
      Length => 0);

   ---------------------------------------------------------------------------
   -- Parse result
   ---------------------------------------------------------------------------

   -- After parsing, we know the event and how many bytes were consumed.
   type Parse_Result is record
      Event    : Raze.Events.Event;
      Consumed : Input_Index;
   end record;

   -- Sentinel: no parse possible (insufficient data or unrecognised sequence).
   No_Parse : constant Parse_Result :=
     (Event    => Raze.Events.No_Event,
      Consumed => 0);

   ---------------------------------------------------------------------------
   -- Key code constants for special keys
   ---------------------------------------------------------------------------

   -- Arrow keys (codes chosen to be outside printable ASCII range).
   Key_Up    : constant := 16#1001#;
   Key_Down  : constant := 16#1002#;
   Key_Right : constant := 16#1003#;
   Key_Left  : constant := 16#1004#;

   -- Navigation keys.
   Key_Home      : constant := 16#1010#;
   Key_Insert    : constant := 16#1011#;
   Key_Delete    : constant := 16#1012#;
   Key_End       : constant := 16#1013#;
   Key_Page_Up   : constant := 16#1014#;
   Key_Page_Down : constant := 16#1015#;

   -- Function keys (F1–F12).
   Key_F1  : constant := 16#1020#;
   Key_F2  : constant := 16#1021#;
   Key_F3  : constant := 16#1022#;
   Key_F4  : constant := 16#1023#;
   Key_F5  : constant := 16#1024#;
   Key_F6  : constant := 16#1025#;
   Key_F7  : constant := 16#1026#;
   Key_F8  : constant := 16#1027#;
   Key_F9  : constant := 16#1028#;
   Key_F10 : constant := 16#1029#;
   Key_F11 : constant := 16#102A#;
   Key_F12 : constant := 16#102B#;

   -- Special keys.
   Key_Escape    : constant := 16#001B#;  -- ESC
   Key_Enter     : constant := 16#000D#;  -- CR
   Key_Tab       : constant := 16#0009#;  -- HT
   Key_Backspace : constant := 16#007F#;  -- DEL

   ---------------------------------------------------------------------------
   -- Main parse function
   ---------------------------------------------------------------------------

   -- Parse the first event from an input buffer.
   -- Returns the parsed event and how many bytes were consumed.
   -- If no event can be parsed (empty buffer or incomplete sequence),
   -- returns No_Parse.
   --
   -- Precondition: buffer length must be valid.
   -- Postcondition: consumed bytes never exceed buffer length.
   function Parse (Buf : Input_Buffer) return Parse_Result
     with Pre  => Buf.Length <= Max_Input_Length,
          Post => Parse'Result.Consumed <= Buf.Length;

end Raze.Input_Parser;
