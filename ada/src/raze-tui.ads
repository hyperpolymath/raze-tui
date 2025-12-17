-- SPDX-License-Identifier: AGPL-3.0-or-later
-- RAZE-TUI Main Package
--
-- High-level Ada interface for TUI operations.

with Raze;

package Raze.Tui is

   ---------------------------------------------------------------------------
   -- Initialization and Shutdown
   ---------------------------------------------------------------------------

   procedure Initialize
     with Post => Is_Running;
   -- Initialize the TUI system.
   -- Must be called before any other TUI operations.

   procedure Shutdown
     with Post => not Is_Running;
   -- Shutdown the TUI system and release resources.

   function Is_Running return Boolean
     with Inline;
   -- Returns True if the TUI system is currently running.

   ---------------------------------------------------------------------------
   -- Terminal Dimensions
   ---------------------------------------------------------------------------

   function Width return Dimension
     with Pre => Is_Running;
   -- Returns the current terminal width in cells.

   function Height return Dimension
     with Pre => Is_Running;
   -- Returns the current terminal height in cells.

   procedure Set_Size (W, H : Dimension)
     with Pre => Is_Running;
   -- Set the terminal size (called on resize events).

   ---------------------------------------------------------------------------
   -- Event Handling
   ---------------------------------------------------------------------------

   function Poll_Event return Event
     with Pre => Is_Running;
   -- Poll for the next input event (non-blocking).
   -- Returns Event_None if no event is available.

   procedure Request_Quit
     with Pre => Is_Running;
   -- Request the TUI to quit on the next loop iteration.

   ---------------------------------------------------------------------------
   -- Version/State Tracking
   ---------------------------------------------------------------------------

   function State_Version return Version_Number
     with Pre => Is_Running;
   -- Returns the current state version for change detection.
   -- Increments whenever state changes.

private

   Initialized : Boolean := False;

end Raze.Tui;
