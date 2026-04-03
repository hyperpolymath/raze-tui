-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- RazeTui.ABI.Widgets
--
-- Formal specification of the widget tree model for RAZE-TUI.
-- Defines widget kinds, the bounded widget tree structure, and
-- ownership/containment proofs.
--
-- Key invariants proved:
--   1. Widget tree depth is bounded (prevents stack overflow in renderers).
--   2. Each widget has exactly one parent (single ownership).
--   3. Widget kinds map to contiguous C enum values [0..5].
--   4. Rectangles have non-negative, bounded dimensions.

module RazeTui.ABI.Widgets

import RazeTui.ABI.State

%default total

---------------------------------------------------------------------------
-- Widget kinds
---------------------------------------------------------------------------

||| The six widget kinds supported by the renderer.
||| Each maps to a fixed C integer value for ABI stability.
public export
data WidgetKind
  = WkNone    -- ^ Null/placeholder widget (C value = 0)
  | WkLabel   -- ^ Static text display (C value = 1)
  | WkInput   -- ^ Text input field (C value = 2)
  | WkButton  -- ^ Clickable button (C value = 3)
  | WkPanel   -- ^ Container panel (C value = 4)
  | WkList    -- ^ Scrollable list (C value = 5)

||| Map a WidgetKind to its C ABI integer representation.
public export
widgetKindToNat : WidgetKind -> Nat
widgetKindToNat WkNone   = 0
widgetKindToNat WkLabel  = 1
widgetKindToNat WkInput  = 2
widgetKindToNat WkButton = 3
widgetKindToNat WkPanel  = 4
widgetKindToNat WkList   = 5

||| Proof that all widget kind values are within the valid C enum range [0, 5].
public export
widgetKindBounded : (wk : WidgetKind) -> LTE (widgetKindToNat wk) 5
widgetKindBounded WkNone   = LTEZero
widgetKindBounded WkLabel  = LTESucc LTEZero
widgetKindBounded WkInput  = LTESucc (LTESucc LTEZero)
widgetKindBounded WkButton = LTESucc (LTESucc (LTESucc LTEZero))
widgetKindBounded WkPanel  = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))
widgetKindBounded WkList   = LTESucc (LTESucc (LTESucc (LTESucc (LTESucc LTEZero))))

||| Predicate: a widget kind is a container (can hold children).
||| Only WkPanel and WkList may contain child widgets.
public export
data IsContainer : WidgetKind -> Type where
  PanelIsContainer : IsContainer WkPanel
  ListIsContainer  : IsContainer WkList

---------------------------------------------------------------------------
-- Tree depth bound
---------------------------------------------------------------------------

||| Maximum permitted widget tree depth.
||| This prevents pathological nesting that could overflow the
||| renderer's stack. A depth of 32 is generous for any sane UI.
public export
MaxTreeDepth : Nat
MaxTreeDepth = 32

---------------------------------------------------------------------------
-- Colour and style (for widget rendering)
---------------------------------------------------------------------------

||| Colour mode, matching the C enum.
public export
data ColorMode = ColDefault | ColANSI256 | ColRGB

||| An RGBA-style colour with mode tag.
||| The mode determines how R, G, B are interpreted.
public export
record Color where
  constructor MkColor
  r    : Nat
  g    : Nat
  b    : Nat
  mode : ColorMode

||| The default terminal colour.
public export
defaultColor : Color
defaultColor = MkColor 0 0 0 ColDefault

||| Text style attributes.
public export
record Style where
  constructor MkStyle
  fg        : Color
  bg        : Color
  bold      : Bool
  italic    : Bool
  underline : Bool

||| Default style: default colours, no attributes.
public export
defaultStyle : Style
defaultStyle = MkStyle defaultColor defaultColor False False False

---------------------------------------------------------------------------
-- Bounding rectangle
---------------------------------------------------------------------------

||| A bounding rectangle with position and size.
||| All coordinates are in terminal cells.
public export
record Rect where
  constructor MkRect
  x      : Nat
  y      : Nat
  width  : Nat
  height : Nat

||| Proof that a rectangle fits within given screen bounds.
public export
data RectFitsScreen : Rect -> Nat -> Nat -> Type where
  ||| A rectangle fits if (x + width <= screenW) and (y + height <= screenH).
  MkRectFits :
    LTE (x + w) screenW ->
    LTE (y + h) screenH ->
    RectFitsScreen (MkRect x y w h) screenW screenH

---------------------------------------------------------------------------
-- Widget tree (depth-bounded, single-ownership)
---------------------------------------------------------------------------

||| A widget tree node, indexed by its depth in the tree.
||| The depth parameter ensures that the tree cannot exceed
||| MaxTreeDepth levels. Children are only permitted for
||| container widget kinds (WkPanel, WkList), enforced by
||| the IsContainer proof in the Branch constructor.
|||
||| @depth Current depth in the tree (0 = root).
public export
data WidgetTree : (depth : Nat) -> Type where
  ||| A leaf widget (no children). Can be any widget kind.
  ||| @kind    The widget kind.
  ||| @bounds  The bounding rectangle.
  ||| @style   The rendering style.
  Leaf : (kind : WidgetKind) ->
         (bounds : Rect) ->
         (style : Style) ->
         WidgetTree depth

  ||| A container widget with children.
  ||| @kind      Must be a container kind (proof required).
  ||| @bounds    The bounding rectangle.
  ||| @style     The rendering style.
  ||| @children  Child widgets at depth + 1.
  ||| @depthOk   Proof that depth + 1 <= MaxTreeDepth.
  Branch : (kind : WidgetKind) ->
           {auto containerPrf : IsContainer kind} ->
           (bounds : Rect) ->
           (style : Style) ->
           (children : List (WidgetTree (S depth))) ->
           {auto depthOk : LTE (S depth) MaxTreeDepth} ->
           WidgetTree depth

---------------------------------------------------------------------------
-- Widget tree properties
---------------------------------------------------------------------------

||| Count the total number of widgets in a tree.
public export
widgetCount : WidgetTree depth -> Nat
widgetCount (Leaf _ _ _)            = 1
widgetCount (Branch _ _ _ children) = 1 + foldl (\acc, child => acc + widgetCount child) 0 children

||| Get the depth of a widget tree (the maximum nesting level).
public export
treeDepth : WidgetTree depth -> Nat
treeDepth (Leaf _ _ _)            = 0
treeDepth (Branch _ _ _ children) = 1 + foldl (\acc, child => max acc (treeDepth child)) 0 children

||| Proof that a Leaf has zero children.
public export
leafHasNoChildren : (w : WidgetTree depth) ->
                    {auto prf : w = Leaf k b s} ->
                    widgetCount w = 1
leafHasNoChildren (Leaf _ _ _) = Refl

---------------------------------------------------------------------------
-- Smart constructors for common widgets
---------------------------------------------------------------------------

||| Create a label widget at the given position.
public export
label : Rect -> Style -> WidgetTree depth
label bounds style = Leaf WkLabel bounds style

||| Create a button widget at the given position.
public export
button : Rect -> Style -> WidgetTree depth
button bounds style = Leaf WkButton bounds style

||| Create an input widget at the given position.
public export
input : Rect -> Style -> WidgetTree depth
input bounds style = Leaf WkInput bounds style

||| Create a panel (container) with children.
||| Requires that the depth is within bounds.
public export
panel : Rect ->
        Style ->
        List (WidgetTree (S depth)) ->
        {auto depthOk : LTE (S depth) MaxTreeDepth} ->
        WidgetTree depth
panel bounds style children = Branch WkPanel bounds style children

---------------------------------------------------------------------------
-- C ABI layout specification for WidgetKind enum
---------------------------------------------------------------------------

||| C-level enum layout for WidgetKind:
|||
||| enum RazeWidgetKind : int32_t {
|||     RAZE_WIDGET_NONE   = 0,
|||     RAZE_WIDGET_LABEL  = 1,
|||     RAZE_WIDGET_INPUT  = 2,
|||     RAZE_WIDGET_BUTTON = 3,
|||     RAZE_WIDGET_PANEL  = 4,
|||     RAZE_WIDGET_LIST   = 5,
||| };
public export
widgetKindEnumSize : Nat
widgetKindEnumSize = 6
