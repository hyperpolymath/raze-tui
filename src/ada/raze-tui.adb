-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Tui — Ada presentation layer implementation.
--
-- All operations delegate directly to the SPARK core packages.
-- No FFI, no C imports — Ada and SPARK share the same runtime.

with Raze.State;
with Raze.Events;

package body Raze.Tui is

   ---------------------------------------------------------------------------
   -- Initialization and Shutdown
   ---------------------------------------------------------------------------

   procedure Initialize is
   begin
      Raze.State.Initialize;
   end Initialize;

   procedure Shutdown is
   begin
      if Raze.State.Is_Initialized then
         Raze.State.Shutdown;
      end if;
   end Shutdown;

   function Is_Running return Boolean is
   begin
      return Raze.State.Is_Running;
   end Is_Running;

   ---------------------------------------------------------------------------
   -- Terminal Dimensions
   ---------------------------------------------------------------------------

   function Width return Raze.State.Dimension is
   begin
      return Raze.State.Get_Width;
   end Width;

   function Height return Raze.State.Dimension is
   begin
      return Raze.State.Get_Height;
   end Height;

   procedure Set_Size (W, H : Raze.State.Dimension) is
   begin
      Raze.State.Set_Size (W, H);
   end Set_Size;

   ---------------------------------------------------------------------------
   -- Event Handling
   ---------------------------------------------------------------------------

   function Poll_Event return Raze.Events.Event is
      E         : Raze.Events.Event;
      Has_Event : Boolean;
   begin
      Raze.Events.Poll_Event (E, Has_Event);
      if Has_Event then
         return E;
      else
         return Raze.Events.No_Event;
      end if;
   end Poll_Event;

   procedure Request_Quit is
   begin
      Raze.State.Request_Quit;
   end Request_Quit;

   ---------------------------------------------------------------------------
   -- Version/State Tracking
   ---------------------------------------------------------------------------

   function State_Version return Raze.State.Version_Number is
   begin
      return Raze.State.Get_Version;
   end State_Version;

end Raze.Tui;
