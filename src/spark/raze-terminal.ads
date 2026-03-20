-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Terminal — SPARK-proved ANSI escape sequence generation.
--
-- This package provides pure functions that generate ANSI escape
-- sequences as byte arrays. No I/O is performed here; the caller
-- (Raze.Tui or the Zig bridge) writes the resulting bytes to the
-- terminal file descriptor.
--
-- All functions are pure, total, and side-effect-free. GNATprove
-- can verify bounds on all array indices and output lengths.
--
-- Reference: ECMA-48 (ISO/IEC 6429) — Control Functions for
-- Coded Character Sets.

with Interfaces.C; use Interfaces.C;
with Raze.State;
with Raze.Widgets;

package Raze.Terminal
  with SPARK_Mode => On,
       Pure
is
   ---------------------------------------------------------------------------
   -- Output buffer type
   ---------------------------------------------------------------------------

   -- Maximum escape sequence length. The longest sequence we generate
   -- is an SGR with full RGB foreground + background + attributes,
   -- which is about 48 bytes. 64 provides comfortable headroom.
   Max_Escape_Length : constant := 64;

   -- An escape sequence buffer with a used-length field.
   -- Bytes(1..Length) contains the sequence; rest is undefined.
   subtype Escape_Index is Natural range 0 .. Max_Escape_Length;
   type Escape_Bytes is array (1 .. Max_Escape_Length) of Interfaces.C.char;

   type Escape_Seq is record
      Bytes  : Escape_Bytes;
      Length : Escape_Index;
   end record;

   -- The empty (zero-length) escape sequence.
   Empty_Seq : constant Escape_Seq :=
     (Bytes  => (others => Interfaces.C.char'Val (0)),
      Length => 0);

   ---------------------------------------------------------------------------
   -- Cursor movement (CSI sequences)
   ---------------------------------------------------------------------------

   -- Move cursor to row R, column C (1-based, as per ANSI convention).
   -- Generates: ESC [ R ; C H
   function Cursor_To (Row, Col : Raze.State.Dimension) return Escape_Seq
     with Post => Cursor_To'Result.Length <= Max_Escape_Length;

   -- Move cursor to the home position (1,1).
   -- Generates: ESC [ H
   function Cursor_Home return Escape_Seq
     with Post => Cursor_Home'Result.Length <= Max_Escape_Length;

   -- Hide cursor.
   -- Generates: ESC [ ? 25 l
   function Cursor_Hide return Escape_Seq
     with Post => Cursor_Hide'Result.Length <= Max_Escape_Length;

   -- Show cursor.
   -- Generates: ESC [ ? 25 h
   function Cursor_Show return Escape_Seq
     with Post => Cursor_Show'Result.Length <= Max_Escape_Length;

   ---------------------------------------------------------------------------
   -- Screen clearing
   ---------------------------------------------------------------------------

   -- Clear the entire screen.
   -- Generates: ESC [ 2 J
   function Clear_Screen return Escape_Seq
     with Post => Clear_Screen'Result.Length <= Max_Escape_Length;

   -- Clear from cursor to end of line.
   -- Generates: ESC [ K
   function Clear_Line return Escape_Seq
     with Post => Clear_Line'Result.Length <= Max_Escape_Length;

   ---------------------------------------------------------------------------
   -- Text attributes (SGR — Select Graphic Rendition)
   ---------------------------------------------------------------------------

   -- Reset all attributes to defaults.
   -- Generates: ESC [ 0 m
   function Reset_Attrs return Escape_Seq
     with Post => Reset_Attrs'Result.Length <= Max_Escape_Length;

   -- Set bold attribute.
   -- Generates: ESC [ 1 m
   function Set_Bold return Escape_Seq
     with Post => Set_Bold'Result.Length <= Max_Escape_Length;

   -- Set italic attribute.
   -- Generates: ESC [ 3 m
   function Set_Italic return Escape_Seq
     with Post => Set_Italic'Result.Length <= Max_Escape_Length;

   -- Set underline attribute.
   -- Generates: ESC [ 4 m
   function Set_Underline return Escape_Seq
     with Post => Set_Underline'Result.Length <= Max_Escape_Length;

   -- Set foreground colour (RGB true colour).
   -- Generates: ESC [ 38 ; 2 ; R ; G ; B m
   function Set_FG_RGB (R, G, B : Interfaces.C.unsigned_char) return Escape_Seq
     with Post => Set_FG_RGB'Result.Length <= Max_Escape_Length;

   -- Set background colour (RGB true colour).
   -- Generates: ESC [ 48 ; 2 ; R ; G ; B m
   function Set_BG_RGB (R, G, B : Interfaces.C.unsigned_char) return Escape_Seq
     with Post => Set_BG_RGB'Result.Length <= Max_Escape_Length;

   -- Apply a full widget style (foreground, background, bold, italic, underline).
   -- Emits a reset followed by the necessary SGR sequences.
   function Apply_Style (S : Raze.Widgets.Style) return Escape_Seq
     with Post => Apply_Style'Result.Length <= Max_Escape_Length;

   ---------------------------------------------------------------------------
   -- Alternate screen buffer
   ---------------------------------------------------------------------------

   -- Enter the alternate screen buffer.
   -- Generates: ESC [ ? 1049 h
   function Enter_Alt_Screen return Escape_Seq
     with Post => Enter_Alt_Screen'Result.Length <= Max_Escape_Length;

   -- Leave the alternate screen buffer (restores original content).
   -- Generates: ESC [ ? 1049 l
   function Leave_Alt_Screen return Escape_Seq
     with Post => Leave_Alt_Screen'Result.Length <= Max_Escape_Length;

   ---------------------------------------------------------------------------
   -- Mouse tracking
   ---------------------------------------------------------------------------

   -- Enable SGR mouse tracking (button events + motion).
   -- Generates: ESC [ ? 1006 h  ESC [ ? 1003 h
   function Enable_Mouse return Escape_Seq
     with Post => Enable_Mouse'Result.Length <= Max_Escape_Length;

   -- Disable mouse tracking.
   -- Generates: ESC [ ? 1003 l  ESC [ ? 1006 l
   function Disable_Mouse return Escape_Seq
     with Post => Disable_Mouse'Result.Length <= Max_Escape_Length;

end Raze.Terminal;
