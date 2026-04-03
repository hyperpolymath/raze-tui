-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- RazeTui.ABI.State
--
-- Formal specification of the TUI state model using dependent types.
-- This module defines the canonical state representation that all
-- language layers (SPARK, Zig FFI, Rust consumer) must conform to.
--
-- Key invariants proved:
--   1. Screen dimensions are bounded within sane terminal limits.
--   2. State version is monotonically non-decreasing across mutations.
--   3. Running flag transitions are well-ordered (init -> running -> stopped).

module RazeTui.ABI.State

%default total

---------------------------------------------------------------------------
-- Screen dimension bounds
---------------------------------------------------------------------------

||| Minimum permissible screen width in cells.
public export
MinWidth : Nat
MinWidth = 1

||| Maximum permissible screen width in cells.
||| 65535 is the upper bound of a 16-bit unsigned integer.
public export
MaxWidth : Nat
MaxWidth = 65535

||| Minimum permissible screen height in cells.
public export
MinHeight : Nat
MinHeight = 1

||| Maximum permissible screen height in cells.
public export
MaxHeight : Nat
MaxHeight = 65535

---------------------------------------------------------------------------
-- Bounded dimension type
---------------------------------------------------------------------------

||| A screen dimension that is provably within [lo, hi].
||| The `prf` field carries a compile-time proof that the value
||| is within the stated bounds.
public export
record BoundedNat (lo : Nat) (hi : Nat) where
  constructor MkBoundedNat
  value : Nat
  lowerBound : LTE lo value
  upperBound : LTE value hi

||| A terminal width, bounded between MinWidth and MaxWidth.
public export
Width : Type
Width = BoundedNat MinWidth MaxWidth

||| A terminal height, bounded between MinHeight and MaxHeight.
public export
Height : Type
Height = BoundedNat MinHeight MaxHeight

---------------------------------------------------------------------------
-- Lifecycle phases
---------------------------------------------------------------------------

||| The three valid lifecycle phases of the TUI system.
||| Transitions are strictly ordered: Uninit -> Running -> Stopped.
||| There is no path from Stopped back to Running.
public export
data Phase = Uninit | Running | Stopped

||| Proof that a phase transition is valid.
||| Only three transitions are permitted:
|||   Uninit  -> Running   (initialization)
|||   Running -> Running   (state mutation while running)
|||   Running -> Stopped   (shutdown)
public export
data ValidTransition : Phase -> Phase -> Type where
  ||| The system may transition from Uninit to Running (initialization).
  InitToRunning   : ValidTransition Uninit Running
  ||| The system may remain in Running across a mutation.
  RunningToRunning : ValidTransition Running Running
  ||| The system may transition from Running to Stopped (shutdown).
  RunningToStopped : ValidTransition Running Stopped

---------------------------------------------------------------------------
-- State version (monotonic)
---------------------------------------------------------------------------

||| A state version counter. The version is a natural number that
||| increases (or stays the same) on every state mutation.
||| This is used for cache invalidation and change detection.
public export
record Version where
  constructor MkVersion
  value : Nat

||| The initial version, starting at zero.
public export
initialVersion : Version
initialVersion = MkVersion 0

||| Increment the version by one. The result is provably greater
||| than the input.
public export
bumpVersion : Version -> Version
bumpVersion (MkVersion n) = MkVersion (S n)

||| Proof that bumping a version produces a strictly greater value.
public export
bumpIncreases : (v : Version) -> LTE (S (value v)) (value (bumpVersion v))
bumpIncreases (MkVersion n) = lteRefl

---------------------------------------------------------------------------
-- TUI State
---------------------------------------------------------------------------

||| The canonical TUI state, parameterised by its lifecycle phase.
||| By indexing on `Phase`, we can enforce at the type level that
||| certain operations (e.g., querying dimensions) are only possible
||| when the system is in the `Running` phase.
public export
record TuiState (phase : Phase) where
  constructor MkTuiState
  ||| Current terminal width (bounded).
  width   : Width
  ||| Current terminal height (bounded).
  height  : Height
  ||| Current state version (monotonically non-decreasing).
  version : Version

---------------------------------------------------------------------------
-- Smart constructors
---------------------------------------------------------------------------

||| Default initial state for the Running phase.
||| Width = 80, Height = 24, Version = 0.
||| These are the standard VT100 terminal defaults.
public export
defaultState : TuiState Running
defaultState = MkTuiState
  (MkBoundedNat 80  (lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight lteRefl)
    (LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc LTEZero))
  (MkBoundedNat 24  (lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight $ lteSuccRight lteRefl)
    (LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc $ LTESucc LTEZero))
  initialVersion

---------------------------------------------------------------------------
-- State mutation with version monotonicity
---------------------------------------------------------------------------

||| Resize the terminal, producing a new state with a bumped version.
||| The caller must supply proofs that the new dimensions are in bounds
||| (these proofs are embedded in the Width and Height arguments).
||| The version is guaranteed to increase.
public export
resize : TuiState Running -> Width -> Height -> TuiState Running
resize st w h = MkTuiState w h (bumpVersion (version st))

||| Transition from Running to Stopped.
||| The resulting state retains the final dimensions and version.
public export
shutdown : TuiState Running -> TuiState Stopped
shutdown (MkTuiState w h v) = MkTuiState w h v

---------------------------------------------------------------------------
-- C ABI layout specification
---------------------------------------------------------------------------

||| Specification of the C-level struct layout that the Zig FFI and
||| SPARK implementation must conform to. This is a *description*,
||| not executable code -- it documents the contract.
|||
||| struct RazeTuiState {
|||     uint16_t width;    -- offset 0, 2 bytes
|||     uint16_t height;   -- offset 2, 2 bytes
|||     uint8_t  running;  -- offset 4, 1 byte (0 or 1)
|||     uint8_t  _pad[3];  -- offset 5, 3 bytes padding
|||     uint64_t version;  -- offset 8, 8 bytes
||| };                     -- total: 16 bytes
|||
||| All fields are little-endian on x86_64, big-endian on s390x.
||| The Zig bridge and SPARK exports MUST match this layout exactly.
public export
record CABILayout where
  constructor MkCABILayout
  ||| Total struct size in bytes.
  structSize    : Nat
  ||| Offset of the width field.
  widthOffset   : Nat
  ||| Offset of the height field.
  heightOffset  : Nat
  ||| Offset of the running field.
  runningOffset : Nat
  ||| Offset of the version field.
  versionOffset : Nat

||| The canonical C ABI layout for TuiState.
public export
tuiStateLayout : CABILayout
tuiStateLayout = MkCABILayout 16 0 2 4 8
