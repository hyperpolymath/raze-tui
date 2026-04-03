-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Exports — C ABI wrapper implementation.
--
-- Each function is a trivial one-line delegation to the SPARK-proved
-- subprograms in Raze.State and Raze.Events. No additional logic.

with System;
with Interfaces.C; use Interfaces.C;
with Raze.State;
with Raze.Events;

package body Raze.Exports is

   -- Sentinel address returned by Init to signal success.
   -- The Zig bridge treats this as an opaque non-null pointer.
   Sentinel : aliased Integer := 1;

   ---------------------------------------------------------------------------
   -- State management wrappers
   ---------------------------------------------------------------------------

   function Spark_Raze_Init return System.Address is
   begin
      Raze.State.Initialize;
      if Raze.State.Is_Running then
         return Sentinel'Address;
      else
         return System.Null_Address;
      end if;
   end Spark_Raze_Init;

   procedure Spark_Raze_Shutdown is
   begin
      if Raze.State.Is_Initialized then
         Raze.State.Shutdown;
      end if;
   end Spark_Raze_Shutdown;

   function Spark_Raze_Is_Running return Interfaces.C.C_bool is
   begin
      return Interfaces.C.C_bool (Raze.State.Is_Running);
   end Spark_Raze_Is_Running;

   function Spark_Raze_Get_Width return Interfaces.C.unsigned_short is
   begin
      if Raze.State.Is_Initialized then
         return Interfaces.C.unsigned_short (Raze.State.Get_Width);
      else
         return 0;
      end if;
   end Spark_Raze_Get_Width;

   function Spark_Raze_Get_Height return Interfaces.C.unsigned_short is
   begin
      if Raze.State.Is_Initialized then
         return Interfaces.C.unsigned_short (Raze.State.Get_Height);
      else
         return 0;
      end if;
   end Spark_Raze_Get_Height;

   procedure Spark_Raze_Set_Size (W, H : Interfaces.C.unsigned_short) is
      Width  : Raze.State.Dimension;
      Height : Raze.State.Dimension;
   begin
      if not Raze.State.Is_Initialized then
         return;
      end if;

      -- Clamp to valid Dimension range.
      if W < Interfaces.C.unsigned_short (Raze.State.Min_Dimension) then
         Width := Raze.State.Dimension (Raze.State.Min_Dimension);
      elsif W > Interfaces.C.unsigned_short (Raze.State.Max_Dimension) then
         Width := Raze.State.Dimension (Raze.State.Max_Dimension);
      else
         Width := Raze.State.Dimension (W);
      end if;

      if H < Interfaces.C.unsigned_short (Raze.State.Min_Dimension) then
         Height := Raze.State.Dimension (Raze.State.Min_Dimension);
      elsif H > Interfaces.C.unsigned_short (Raze.State.Max_Dimension) then
         Height := Raze.State.Dimension (Raze.State.Max_Dimension);
      else
         Height := Raze.State.Dimension (H);
      end if;

      Raze.State.Set_Size (Width, Height);
   end Spark_Raze_Set_Size;

   function Spark_Raze_Poll_Event (E : access Raze.Events.Event)
     return Interfaces.C.C_bool
   is
      Evt       : Raze.Events.Event;
      Has_Event : Boolean;
   begin
      if not Raze.State.Is_Initialized then
         E.all := Raze.Events.No_Event;
         return Interfaces.C.C_bool (False);
      end if;

      Raze.Events.Poll_Event (Evt, Has_Event);
      E.all := Evt;
      return Interfaces.C.C_bool (Has_Event);
   end Spark_Raze_Poll_Event;

   procedure Spark_Raze_Request_Quit is
   begin
      if Raze.State.Is_Initialized then
         Raze.State.Request_Quit;
      end if;
   end Spark_Raze_Request_Quit;

   function Spark_Raze_Get_Version return Interfaces.C.unsigned_long is
   begin
      if Raze.State.Is_Initialized then
         return Interfaces.C.unsigned_long (Raze.State.Get_Version);
      else
         return 0;
      end if;
   end Spark_Raze_Get_Version;

end Raze.Exports;
