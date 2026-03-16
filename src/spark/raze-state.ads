-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.State — SPARK-proved TUI state management.
--
-- This package is the formally verified core of the RAZE-TUI state model.
-- Every subprogram carries Pre/Post contracts that correspond to the
-- dependent type proofs in RazeTui.ABI.State (Idris2).
--
-- Invariants maintained:
--   * Width  is always in [1, 65535] when initialized.
--   * Height is always in [1, 65535] when initialized.
--   * Version is monotonically non-decreasing (increments on mutation).
--   * Phase transitions follow Init -> Running -> Stopped (never backward).

with Interfaces.C; use Interfaces.C;

package Raze.State
  with SPARK_Mode     => On,
       Abstract_State => Internal_State
is
   ---------------------------------------------------------------------------
   -- Constants (matching Idris2 ABI bounds)
   ---------------------------------------------------------------------------

   -- Minimum and maximum screen dimensions.
   -- These correspond to MinWidth/MaxWidth/MinHeight/MaxHeight in State.idr.
   Min_Dimension : constant := 1;
   Max_Dimension : constant := 65_535;

   ---------------------------------------------------------------------------
   -- Types
   ---------------------------------------------------------------------------

   -- A screen dimension, bounded between Min_Dimension and Max_Dimension.
   subtype Dimension is Interfaces.C.unsigned_short
     range Interfaces.C.unsigned_short (Min_Dimension) ..
           Interfaces.C.unsigned_short (Max_Dimension);

   -- State version counter (unsigned 64-bit, matching Idris2 Version).
   subtype Version_Number is Interfaces.C.unsigned_long;

   -- The default terminal dimensions (VT100 standard: 80x24).
   Default_Width  : constant Dimension := 80;
   Default_Height : constant Dimension := 24;

   ---------------------------------------------------------------------------
   -- Lifecycle queries
   ---------------------------------------------------------------------------

   -- Returns True if the TUI system has been successfully initialized
   -- and is currently in the Running phase.
   function Is_Initialized return Boolean
     with Global => Internal_State;

   ---------------------------------------------------------------------------
   -- Initialization and shutdown
   ---------------------------------------------------------------------------

   -- Initialize the TUI system.
   -- Transitions from Uninit to Running.
   -- After this call, Is_Initialized returns True.
   -- Width and Height are set to VT100 defaults (80x24).
   -- Version starts at 0.
   procedure Initialize
     with Global => (In_Out => Internal_State),
          Post   => Is_Initialized;

   -- Shut down the TUI system.
   -- Transitions from Running to Stopped.
   -- After this call, Is_Initialized returns False.
   procedure Shutdown
     with Global => (In_Out => Internal_State),
          Pre    => Is_Initialized,
          Post   => not Is_Initialized;

   ---------------------------------------------------------------------------
   -- Dimension queries (require Running phase)
   ---------------------------------------------------------------------------

   -- Returns the current terminal width in cells.
   function Get_Width return Dimension
     with Global => Internal_State,
          Pre    => Is_Initialized;

   -- Returns the current terminal height in cells.
   function Get_Height return Dimension
     with Global => Internal_State,
          Pre    => Is_Initialized;

   -- Set the terminal dimensions. Bumps the version counter.
   -- The new dimensions must be within the valid range (enforced by
   -- the Dimension subtype).
   procedure Set_Size (W, H : Dimension)
     with Global => (In_Out => Internal_State),
          Pre    => Is_Initialized,
          Post   => Is_Initialized
                    and then Get_Width = W
                    and then Get_Height = H;

   ---------------------------------------------------------------------------
   -- Version query (for change detection / cache invalidation)
   ---------------------------------------------------------------------------

   -- Returns the current state version.
   -- This value is monotonically non-decreasing.
   function Get_Version return Version_Number
     with Global => Internal_State,
          Pre    => Is_Initialized;

   ---------------------------------------------------------------------------
   -- Running state query
   ---------------------------------------------------------------------------

   -- Returns True if the system is running (not quit-requested).
   function Is_Running return Boolean
     with Global => Internal_State;

   -- Request the system to quit. Sets the running flag to False.
   -- The state remains initialized but the event loop should exit.
   procedure Request_Quit
     with Global => (In_Out => Internal_State),
          Pre    => Is_Initialized,
          Post   => Is_Initialized and then not Is_Running;

end Raze.State;
