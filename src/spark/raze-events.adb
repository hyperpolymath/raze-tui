-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Events — SPARK-proved event handling implementation.

with Raze.State;

package body Raze.Events
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Event polling
   ---------------------------------------------------------------------------

   -- Pending event buffer. When the input parser produces an event,
   -- it is stored here for the next Poll_Event call. This allows
   -- the non-SPARK Posix layer to push events into the SPARK core.
   Pending       : Event   := No_Event;
   Pending_Valid : Boolean := False;

   procedure Push_Event (E : Event)
     with SPARK_Mode => Off  -- Called from non-SPARK Ada code
   is
   begin
      Pending       := E;
      Pending_Valid := True;
   end Push_Event;

   procedure Poll_Event (E         : out Event;
                         Has_Event : out Boolean) is
   begin
      if Pending_Valid then
         E             := Pending;
         Has_Event     := True;
         Pending       := No_Event;
         Pending_Valid := False;
      else
         E         := No_Event;
         Has_Event := False;
      end if;
   end Poll_Event;

   ---------------------------------------------------------------------------
   -- Event processing
   ---------------------------------------------------------------------------

   procedure Process_Event (E : Event) is
   begin
      case E.Kind is
         when Event_Quit =>
            -- Transition to the "quit requested" state.
            Raze.State.Request_Quit;

         when Event_Resize =>
            -- Update dimensions if the new values are within the
            -- valid Dimension range. Values outside the range are
            -- clamped to the nearest bound.
            declare
               W : Raze.State.Dimension;
               H : Raze.State.Dimension;
            begin
               -- Clamp width to valid range.
               if E.Mouse_X < Interfaces.C.unsigned_short (Raze.State.Min_Dimension) then
                  W := Raze.State.Dimension (Raze.State.Min_Dimension);
               elsif E.Mouse_X > Interfaces.C.unsigned_short (Raze.State.Max_Dimension) then
                  W := Raze.State.Dimension (Raze.State.Max_Dimension);
               else
                  W := Raze.State.Dimension (E.Mouse_X);
               end if;

               -- Clamp height to valid range.
               if E.Mouse_Y < Interfaces.C.unsigned_short (Raze.State.Min_Dimension) then
                  H := Raze.State.Dimension (Raze.State.Min_Dimension);
               elsif E.Mouse_Y > Interfaces.C.unsigned_short (Raze.State.Max_Dimension) then
                  H := Raze.State.Dimension (Raze.State.Max_Dimension);
               else
                  H := Raze.State.Dimension (E.Mouse_Y);
               end if;

               Raze.State.Set_Size (W, H);
            end;

         when Event_Key | Event_Mouse | Event_None =>
            -- No state change for key, mouse, or no-op events.
            null;
      end case;
   end Process_Event;

end Raze.Events;
