-- SPDX-License-Identifier: AGPL-3.0-or-later
-- RAZE-TUI Ada Bindings
--
-- This package provides Ada bindings to the RAZE Zig bridge,
-- enabling Ada/SPARK TUI development with Rust core logic.

with Interfaces.C; use Interfaces.C;

package Raze is
   pragma Pure;

   ---------------------------------------------------------------------------
   -- Types matching Zig/Rust FFI
   ---------------------------------------------------------------------------

   type Dimension is new Interfaces.C.unsigned_short;
   type Version_Number is new Interfaces.C.unsigned_long;

   type Event_Kind is
     (Event_None,
      Event_Key,
      Event_Mouse,
      Event_Resize,
      Event_Quit)
     with Convention => C;

   for Event_Kind use
     (Event_None   => 0,
      Event_Key    => 1,
      Event_Mouse  => 2,
      Event_Resize => 3,
      Event_Quit   => 4);

   type Modifiers is new Interfaces.C.unsigned_char;

   Mod_None  : constant Modifiers := 0;
   Mod_Shift : constant Modifiers := 1;
   Mod_Ctrl  : constant Modifiers := 2;
   Mod_Alt   : constant Modifiers := 4;

   type Event is record
      Kind      : Event_Kind;
      Key_Code  : Interfaces.C.unsigned;
      Mods      : Modifiers;
      Mouse_X   : Dimension;
      Mouse_Y   : Dimension;
   end record
     with Convention => C;

   type Color_Mode is
     (Color_Default,
      Color_ANSI256,
      Color_RGB)
     with Convention => C;

   for Color_Mode use
     (Color_Default => 0,
      Color_ANSI256 => 1,
      Color_RGB     => 2);

   type Color is record
      R    : Interfaces.C.unsigned_char;
      G    : Interfaces.C.unsigned_char;
      B    : Interfaces.C.unsigned_char;
      Mode : Interfaces.C.unsigned_char;
   end record
     with Convention => C;

   Default_Color : constant Color := (R => 0, G => 0, B => 0, Mode => 0);

   type Style is record
      FG        : Color;
      BG        : Color;
      Bold      : Interfaces.C.C_bool;
      Italic    : Interfaces.C.C_bool;
      Underline : Interfaces.C.C_bool;
   end record
     with Convention => C;

   type Rect is record
      X      : Dimension;
      Y      : Dimension;
      Width  : Dimension;
      Height : Dimension;
   end record
     with Convention => C;

end Raze;
