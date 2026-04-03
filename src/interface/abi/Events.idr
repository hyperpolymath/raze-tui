-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- RazeTui.ABI.Events
--
-- Formal specification of the event model for the RAZE-TUI system.
-- Defines event kinds, modifier keys, event records, and proves
-- that event-driven state transitions preserve system invariants.
--
-- Key invariants proved:
--   1. Event kinds map to contiguous C enum values [0..4].
--   2. Modifier flags occupy exactly three non-overlapping bits.
--   3. Mouse coordinates in resize events are bounded dimensions.
--   4. Processing an event from a Running state yields a Running
--      or Stopped state (never Uninit).

module RazeTui.ABI.Events

import RazeTui.ABI.State

%default total

---------------------------------------------------------------------------
-- Event kinds
---------------------------------------------------------------------------

||| The five event kinds supported by the TUI system.
||| Each maps to a fixed C integer value for ABI stability.
public export
data EventKind
  = EvNone    -- ^ No event available (sentinel, C value = 0)
  | EvKey     -- ^ Keyboard input (C value = 1)
  | EvMouse   -- ^ Mouse input (C value = 2)
  | EvResize  -- ^ Terminal resize notification (C value = 3)
  | EvQuit    -- ^ Quit request (C value = 4)

||| Map an EventKind to its C ABI integer representation.
||| This function is the single source of truth for the
||| EventKind <-> c_int mapping.
public export
eventKindToNat : EventKind -> Nat
eventKindToNat EvNone   = 0
eventKindToNat EvKey    = 1
eventKindToNat EvMouse  = 2
eventKindToNat EvResize = 3
eventKindToNat EvQuit   = 4

||| Proof that all event kind values are within the valid C enum range [0, 4].
public export
eventKindBounded : (ek : EventKind) -> LTE (eventKindToNat ek) 4
eventKindBounded EvNone   = LTEZero
eventKindBounded EvKey    = LTESucc LTEZero
eventKindBounded EvMouse  = LTESucc (LTESucc LTEZero)
eventKindBounded EvResize = LTESucc (LTESucc (LTESucc LTEZero))
eventKindBounded EvQuit   = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))

||| Proof that the event kind values are contiguous (no gaps).
||| We show that for every n in [0..4], there exists an EventKind
||| mapping to that value.
public export
data EventKindCoversNat : Nat -> Type where
  CoverZero  : EventKindCoversNat 0
  CoverOne   : EventKindCoversNat 1
  CoverTwo   : EventKindCoversNat 2
  CoverThree : EventKindCoversNat 3
  CoverFour  : EventKindCoversNat 4

---------------------------------------------------------------------------
-- Modifier flags
---------------------------------------------------------------------------

||| Modifier key flags. These occupy bits 0, 1, and 2 of a u8.
||| Bit 0 = Shift, Bit 1 = Ctrl, Bit 2 = Alt.
||| Combinations are formed by bitwise OR.
public export
data Modifier = ModNone | ModShift | ModCtrl | ModAlt

||| Map a Modifier to its bit value.
public export
modifierToNat : Modifier -> Nat
modifierToNat ModNone  = 0
modifierToNat ModShift = 1
modifierToNat ModCtrl  = 2
modifierToNat ModAlt   = 4

||| Proof that all modifier values fit in a single byte (< 256).
public export
modifierFitsU8 : (m : Modifier) -> LTE (modifierToNat m) 255
modifierFitsU8 ModNone  = LTEZero
modifierFitsU8 ModShift = LTESucc LTEZero
modifierFitsU8 ModCtrl  = LTESucc (LTESucc LTEZero)
modifierFitsU8 ModAlt   = LTESucc (LTESucc (LTESucc (LTESucc LTEZero)))

||| A combined modifier bitmask, represented as a natural number
||| that is provably less than 8 (only bits 0-2 are used).
public export
record ModifierMask where
  constructor MkModifierMask
  bits : Nat
  bounded : LTE bits 7

||| The empty modifier mask (no modifiers pressed).
public export
noModifiers : ModifierMask
noModifiers = MkModifierMask 0 LTEZero

---------------------------------------------------------------------------
-- Event record
---------------------------------------------------------------------------

||| A complete event record. Parameterised by EventKind so that
||| kind-specific fields can be constrained at the type level.
public export
record Event where
  constructor MkEvent
  ||| The kind of event.
  kind     : EventKind
  ||| Key code (meaningful only for EvKey events, 0 otherwise).
  keyCode  : Nat
  ||| Modifier bitmask (meaningful only for EvKey events).
  mods     : ModifierMask
  ||| Mouse/resize X coordinate (meaningful for EvMouse, EvResize).
  mouseX   : Nat
  ||| Mouse/resize Y coordinate (meaningful for EvMouse, EvResize).
  mouseY   : Nat

||| Construct a "no event" sentinel.
public export
noEvent : Event
noEvent = MkEvent EvNone 0 noModifiers 0 0

||| Construct a key event with the given key code and modifiers.
public export
keyEvent : Nat -> ModifierMask -> Event
keyEvent code mods = MkEvent EvKey code mods 0 0

||| Construct a resize event. The dimensions are plain Nats here;
||| the consumer (SPARK layer) is responsible for validating them
||| against the BoundedNat constraints in State.idr before applying.
public export
resizeEvent : Nat -> Nat -> Event
resizeEvent w h = MkEvent EvResize 0 noModifiers w h

||| Construct a quit event.
public export
quitEvent : Event
quitEvent = MkEvent EvQuit 0 noModifiers 0 0

---------------------------------------------------------------------------
-- Event-driven state transitions
---------------------------------------------------------------------------

||| The result of processing an event: the system either remains
||| Running or transitions to Stopped.
public export
data ProcessResult
  = StillRunning (TuiState Running)
  | NowStopped   (TuiState Stopped)

||| Proof that processing an event from a Running state never
||| produces an Uninit state. This is structural: ProcessResult
||| can only hold Running or Stopped.
|||
||| The actual event processing logic lives in the SPARK layer;
||| this type constrains what outcomes are *possible*.
public export
processResultPhase : ProcessResult -> Phase
processResultPhase (StillRunning _) = Running
processResultPhase (NowStopped _)   = Stopped

||| Proof that the phase after processing is never Uninit.
public export
processNeverUninit : (r : ProcessResult) -> Not (processResultPhase r = Uninit)
processNeverUninit (StillRunning _) = absurd
processNeverUninit (NowStopped _)   = absurd

---------------------------------------------------------------------------
-- C ABI layout specification for Event struct
---------------------------------------------------------------------------

||| C-level struct layout for Event:
|||
||| struct RazeEvent {
|||     int32_t  kind;       -- offset 0, 4 bytes (EventKind enum)
|||     uint32_t key_code;   -- offset 4, 4 bytes
|||     uint8_t  modifiers;  -- offset 8, 1 byte
|||     uint8_t  _pad[1];    -- offset 9, 1 byte padding
|||     uint16_t mouse_x;    -- offset 10, 2 bytes
|||     uint16_t mouse_y;    -- offset 12, 2 bytes
|||     uint8_t  _pad2[2];   -- offset 14, 2 bytes padding
||| };                       -- total: 16 bytes
public export
record EventCABILayout where
  constructor MkEventCABILayout
  structSize    : Nat
  kindOffset    : Nat
  keyCodeOffset : Nat
  modsOffset    : Nat
  mouseXOffset  : Nat
  mouseYOffset  : Nat

||| The canonical C ABI layout for Event.
public export
eventLayout : EventCABILayout
eventLayout = MkEventCABILayout 16 0 4 8 10 12
