-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Widgets — SPARK-proved widget primitives implementation.

package body Raze.Widgets
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Widget construction
   ---------------------------------------------------------------------------

   function Make_Leaf (Kind   : Widget_Kind;
                       Bounds : Rect;
                       S      : Style;
                       Parent : Natural;
                       D      : Tree_Depth) return Widget_Node is
   begin
      return Widget_Node'(Kind         => Kind,
                          Bounds       => Bounds,
                          Node_Style   => S,
                          Parent_Index => Parent,
                          Depth        => D);
   end Make_Leaf;

   function Make_Container (Kind   : Widget_Kind;
                            Bounds : Rect;
                            S      : Style;
                            Parent : Natural;
                            D      : Tree_Depth) return Widget_Node is
   begin
      return Widget_Node'(Kind         => Kind,
                          Bounds       => Bounds,
                          Node_Style   => S,
                          Parent_Index => Parent,
                          Depth        => D);
   end Make_Container;

end Raze.Widgets;
