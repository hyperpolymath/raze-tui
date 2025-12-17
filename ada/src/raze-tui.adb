-- SPDX-License-Identifier: AGPL-3.0-or-later
-- RAZE-TUI Implementation

with Interfaces.C; use Interfaces.C;

package body Raze.Tui is

   ---------------------------------------------------------------------------
   -- FFI Imports from Zig Bridge
   ---------------------------------------------------------------------------

   type State_Ptr is new System.Address;

   function C_Init return State_Ptr
     with Import, Convention => C, External_Name => "raze_init";

   procedure C_Shutdown
     with Import, Convention => C, External_Name => "raze_shutdown";

   function C_Is_Running return Interfaces.C.C_bool
     with Import, Convention => C, External_Name => "raze_is_running";

   function C_Get_Width return Interfaces.C.unsigned_short
     with Import, Convention => C, External_Name => "raze_get_width";

   function C_Get_Height return Interfaces.C.unsigned_short
     with Import, Convention => C, External_Name => "raze_get_height";

   procedure C_Set_Size (W, H : Interfaces.C.unsigned_short)
     with Import, Convention => C, External_Name => "raze_set_size";

   function C_Poll_Event (E : access Event) return Interfaces.C.C_bool
     with Import, Convention => C, External_Name => "raze_poll_event";

   procedure C_Request_Quit
     with Import, Convention => C, External_Name => "raze_request_quit";

   function C_Get_Version return Interfaces.C.unsigned_long
     with Import, Convention => C, External_Name => "raze_get_version";

   ---------------------------------------------------------------------------
   -- Implementation
   ---------------------------------------------------------------------------

   procedure Initialize is
      State : State_Ptr;
   begin
      if not Initialized then
         State := C_Init;
         Initialized := State /= State_Ptr (System.Null_Address);
      end if;
   end Initialize;

   procedure Shutdown is
   begin
      if Initialized then
         C_Shutdown;
         Initialized := False;
      end if;
   end Shutdown;

   function Is_Running return Boolean is
   begin
      return Initialized and then Boolean (C_Is_Running);
   end Is_Running;

   function Width return Dimension is
   begin
      return Dimension (C_Get_Width);
   end Width;

   function Height return Dimension is
   begin
      return Dimension (C_Get_Height);
   end Height;

   procedure Set_Size (W, H : Dimension) is
   begin
      C_Set_Size (Interfaces.C.unsigned_short (W),
                  Interfaces.C.unsigned_short (H));
   end Set_Size;

   function Poll_Event return Event is
      E : aliased Event;
      Has_Event : Interfaces.C.C_bool;
   begin
      Has_Event := C_Poll_Event (E'Access);
      if Boolean (Has_Event) then
         return E;
      else
         return (Kind => Event_None, others => <>);
      end if;
   end Poll_Event;

   procedure Request_Quit is
   begin
      C_Request_Quit;
   end Request_Quit;

   function State_Version return Version_Number is
   begin
      return Version_Number (C_Get_Version);
   end State_Version;

end Raze.Tui;
