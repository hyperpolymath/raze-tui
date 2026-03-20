-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Tui — Ada presentation layer implementation.
--
-- Wires together the SPARK core (Raze.State, Raze.Events) with the
-- POSIX terminal I/O layer (Raze.Posix) and the SPARK input parser
-- (Raze.Input_Parser). This is the integration point where non-SPARK
-- I/O meets SPARK-proved logic.

with Raze.State;
with Raze.Events;
with Raze.Posix;
with Raze.Terminal;
with Raze.Input_Parser;

package body Raze.Tui is

   ---------------------------------------------------------------------------
   -- Internal state
   ---------------------------------------------------------------------------

   -- Whether raw mode was successfully enabled.
   Raw_Mode_Enabled : Boolean := False;

   ---------------------------------------------------------------------------
   -- Initialization and Shutdown
   ---------------------------------------------------------------------------

   procedure Initialize is
      W, H : Interfaces.C.unsigned_short;
   begin
      -- Initialize the SPARK core.
      Raze.State.Initialize;

      -- Enable raw terminal mode.
      Raw_Mode_Enabled := Raze.Posix.Enable_Raw_Mode;

      if Raw_Mode_Enabled then
         -- Enter alternate screen buffer.
         Raze.Posix.Write_Escape (Raze.Terminal.Enter_Alt_Screen);

         -- Hide cursor.
         Raze.Posix.Write_Escape (Raze.Terminal.Cursor_Hide);

         -- Enable mouse tracking.
         Raze.Posix.Write_Escape (Raze.Terminal.Enable_Mouse);

         -- Clear screen.
         Raze.Posix.Write_Escape (Raze.Terminal.Clear_Screen);
         Raze.Posix.Write_Escape (Raze.Terminal.Cursor_Home);

         Raze.Posix.Flush_Output;

         -- Query actual terminal size and apply.
         Raze.Posix.Get_Terminal_Size (W, H);
         if W >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
            and then W <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
            and then H >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
            and then H <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
         then
            Raze.State.Set_Size (Raze.State.Dimension (W),
                                 Raze.State.Dimension (H));
         end if;
      end if;
   end Initialize;

   procedure Shutdown is
   begin
      if Raw_Mode_Enabled then
         -- Disable mouse tracking.
         Raze.Posix.Write_Escape (Raze.Terminal.Disable_Mouse);

         -- Show cursor.
         Raze.Posix.Write_Escape (Raze.Terminal.Cursor_Show);

         -- Reset attributes.
         Raze.Posix.Write_Escape (Raze.Terminal.Reset_Attrs);

         -- Leave alternate screen buffer.
         Raze.Posix.Write_Escape (Raze.Terminal.Leave_Alt_Screen);

         Raze.Posix.Flush_Output;

         -- Restore terminal settings.
         Raze.Posix.Disable_Raw_Mode;
         Raw_Mode_Enabled := False;
      end if;

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
      Buf        : Raze.Input_Parser.Input_Buffer;
      Bytes_Read : Natural;
      Result     : Raze.Input_Parser.Parse_Result;
      E          : Raze.Events.Event;
      Has_Event  : Boolean;
   begin
      -- First check for any pending event in the SPARK core.
      Raze.Events.Poll_Event (E, Has_Event);
      if Has_Event then
         return E;
      end if;

      -- If raw mode is active, read from terminal and parse.
      if Raw_Mode_Enabled then
         Raze.Posix.Read_Input (Buf, Bytes_Read);

         if Bytes_Read > 0 then
            Result := Raze.Input_Parser.Parse (Buf);

            if Result.Consumed > 0 then
               return Result.Event;
            end if;
         end if;
      end if;

      return Raze.Events.No_Event;
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
