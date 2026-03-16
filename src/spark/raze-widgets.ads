-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Widgets — SPARK-proved widget primitives.
--
-- Defines widget kinds, bounding rectangles, colours, styles,
-- and a bounded widget tree. Corresponds to the Idris2 specification
-- in RazeTui.ABI.Widgets.
--
-- The widget tree depth is bounded to Max_Tree_Depth (32) to prevent
-- stack overflow during rendering traversal.

with Interfaces.C; use Interfaces.C;
with Raze.State;

package Raze.Widgets
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Widget kinds (C ABI enum values 0..5)
   ---------------------------------------------------------------------------

   -- The six widget kinds. Representation values match the Idris2 ABI
   -- specification (widgetKindToNat) and the Zig bridge.
   type Widget_Kind is
     (Widget_None,
      Widget_Label,
      Widget_Input,
      Widget_Button,
      Widget_Panel,
      Widget_List)
     with Convention => C,
          Size       => 32;  -- int32_t in C ABI

   for Widget_Kind use
     (Widget_None   => 0,
      Widget_Label  => 1,
      Widget_Input  => 2,
      Widget_Button => 3,
      Widget_Panel  => 4,
      Widget_List   => 5);

   -- Returns True if the widget kind is a container (can hold children).
   -- Only Panel and List are containers, matching the Idris2 IsContainer proof.
   function Is_Container (Kind : Widget_Kind) return Boolean is
     (Kind = Widget_Panel or Kind = Widget_List)
     with Inline;

   ---------------------------------------------------------------------------
   -- Tree depth bound
   ---------------------------------------------------------------------------

   -- Maximum widget tree depth, matching MaxTreeDepth in Widgets.idr.
   Max_Tree_Depth : constant := 32;

   -- Depth counter type.
   subtype Tree_Depth is Natural range 0 .. Max_Tree_Depth;

   ---------------------------------------------------------------------------
   -- Colour and style
   ---------------------------------------------------------------------------

   -- Colour mode, matching the C enum.
   type Color_Mode is
     (Color_Default,
      Color_ANSI256,
      Color_RGB)
     with Convention => C;

   for Color_Mode use
     (Color_Default => 0,
      Color_ANSI256 => 1,
      Color_RGB     => 2);

   -- An RGB colour with mode tag.
   type Color is record
      R    : Interfaces.C.unsigned_char;
      G    : Interfaces.C.unsigned_char;
      B    : Interfaces.C.unsigned_char;
      Mode : Interfaces.C.unsigned_char;  -- Color_Mode as byte
   end record
     with Convention => C;

   -- The default terminal colour (mode = 0, RGB = 0).
   Default_Color : constant Color := (R => 0, G => 0, B => 0, Mode => 0);

   -- Text style attributes.
   type Style is record
      FG        : Color;
      BG        : Color;
      Bold      : Interfaces.C.C_bool;
      Italic    : Interfaces.C.C_bool;
      Underline : Interfaces.C.C_bool;
   end record
     with Convention => C;

   -- Default style: default colours, no text attributes.
   Default_Style : constant Style :=
     (FG        => Default_Color,
      BG        => Default_Color,
      Bold      => Interfaces.C.C_bool (False),
      Italic    => Interfaces.C.C_bool (False),
      Underline => Interfaces.C.C_bool (False));

   ---------------------------------------------------------------------------
   -- Bounding rectangle
   ---------------------------------------------------------------------------

   -- A bounding rectangle in terminal cell coordinates.
   type Rect is record
      X      : Interfaces.C.unsigned_short;
      Y      : Interfaces.C.unsigned_short;
      Width  : Interfaces.C.unsigned_short;
      Height : Interfaces.C.unsigned_short;
   end record
     with Convention => C;

   -- Returns True if the rectangle fits entirely within the given
   -- screen bounds. This corresponds to the RectFitsScreen proof
   -- in Widgets.idr.
   function Rect_Fits_Screen (R            : Rect;
                              Screen_Width  : Raze.State.Dimension;
                              Screen_Height : Raze.State.Dimension) return Boolean is
     (Natural (R.X) + Natural (R.Width) <= Natural (Screen_Width)
      and then Natural (R.Y) + Natural (R.Height) <= Natural (Screen_Height))
     with Inline;

   ---------------------------------------------------------------------------
   -- Widget node (flat representation for C ABI)
   ---------------------------------------------------------------------------

   -- A single widget node in a flat (array-based) widget tree.
   -- The tree is stored as a flat array where Parent_Index links
   -- each node to its parent. Root nodes have Parent_Index = 0.
   --
   -- This flat representation avoids heap pointers and is C ABI
   -- compatible, unlike the recursive Idris2 WidgetTree type.
   type Widget_Node is record
      Kind         : Widget_Kind;
      Bounds       : Rect;
      Node_Style   : Style;
      Parent_Index : Natural;    -- Index of parent in the widget array
      Depth        : Tree_Depth; -- Depth in the tree (for bound checking)
   end record;

   -- Maximum number of widgets in a single tree.
   Max_Widgets : constant := 1024;

   -- Widget array type.
   subtype Widget_Index is Natural range 0 .. Max_Widgets;
   type Widget_Array is array (1 .. Max_Widgets) of Widget_Node;

   ---------------------------------------------------------------------------
   -- Widget tree operations
   ---------------------------------------------------------------------------

   -- Create a leaf widget node.
   -- Precondition: depth must be within the tree depth bound.
   function Make_Leaf (Kind   : Widget_Kind;
                       Bounds : Rect;
                       S      : Style;
                       Parent : Natural;
                       D      : Tree_Depth) return Widget_Node
     with Pre  => D <= Max_Tree_Depth,
          Post => Make_Leaf'Result.Depth = D
                  and then Make_Leaf'Result.Kind = Kind
                  and then Make_Leaf'Result.Parent_Index = Parent;

   -- Create a container widget node (Panel or List).
   -- Precondition: kind must be a container; depth must be valid.
   function Make_Container (Kind   : Widget_Kind;
                            Bounds : Rect;
                            S      : Style;
                            Parent : Natural;
                            D      : Tree_Depth) return Widget_Node
     with Pre  => Is_Container (Kind) and D <= Max_Tree_Depth,
          Post => Make_Container'Result.Depth = D
                  and then Make_Container'Result.Kind = Kind
                  and then Is_Container (Make_Container'Result.Kind);

end Raze.Widgets;
