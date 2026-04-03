-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Tui — Ada presentation layer for RAZE-TUI.
--
-- This package provides the high-level Ada interface for TUI operations.
-- It delegates directly to the SPARK core packages (Raze.State, Raze.Events)
-- rather than going through the Zig FFI bridge. Ada and SPARK share the
-- same GNAT compiler and calling convention, so no FFI is needed.
--
-- Architecture:
--   Ada presentation (this package) --> SPARK core (Raze.State, Raze.Events)

with Raze.State;
with Raze.Events;

package Raze.Tui is

   ---------------------------------------------------------------------------
   -- Initialization and Shutdown
   ---------------------------------------------------------------------------

   -- Initialize the TUI system.
   -- Delegates to Raze.State.Initialize.
   procedure Initialize
     with Post => Is_Running;

   -- Shut down the TUI system and release resources.
   -- Delegates to Raze.State.Shutdown.
   procedure Shutdown
     with Post => not Is_Running;

   -- Returns True if the TUI system is currently running.
   function Is_Running return Boolean
     with Inline;

   ---------------------------------------------------------------------------
   -- Terminal Dimensions
   ---------------------------------------------------------------------------

   -- Returns the current terminal width in cells.
   function Width return Raze.State.Dimension
     with Pre => Is_Running;

   -- Returns the current terminal height in cells.
   function Height return Raze.State.Dimension
     with Pre => Is_Running;

   -- Set the terminal size (called on resize events).
   procedure Set_Size (W, H : Raze.State.Dimension)
     with Pre => Is_Running;

   ---------------------------------------------------------------------------
   -- Event Handling
   ---------------------------------------------------------------------------

   -- Poll for the next input event (non-blocking).
   -- Returns Events.No_Event if no event is available.
   function Poll_Event return Raze.Events.Event
     with Pre => Is_Running;

   -- Request the TUI to quit on the next loop iteration.
   procedure Request_Quit
     with Pre => Is_Running;

   ---------------------------------------------------------------------------
   -- Version/State Tracking
   ---------------------------------------------------------------------------

   -- Returns the current state version for change detection.
   -- Increments whenever state changes.
   function State_Version return Raze.State.Version_Number
     with Pre => Is_Running;

end Raze.Tui;
