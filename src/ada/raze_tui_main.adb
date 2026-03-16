-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- RAZE-TUI Demo Application
--
-- Entry point for the TUI demo. Uses the Ada presentation layer
-- (Raze.Tui), which delegates to the SPARK-proved core.

with Ada.Text_IO; use Ada.Text_IO;
with Raze.Tui;
with Raze.State;
with Raze.Events;

procedure Raze_Tui_Main is
   use Raze.Events;
   E : Event;
begin
   Put_Line ("RAZE-TUI Demo");
   Put_Line ("=============");

   -- Initialize TUI (delegates to SPARK core).
   Raze.Tui.Initialize;

   if not Raze.Tui.Is_Running then
      Put_Line ("Error: Failed to initialize TUI");
      return;
   end if;

   Put_Line ("Terminal size:" &
             Raze.Tui.Width'Image & "x" &
             Raze.Tui.Height'Image);

   -- Main event loop.
   while Raze.Tui.Is_Running loop
      E := Raze.Tui.Poll_Event;

      case E.Kind is
         when Event_Key =>
            Put_Line ("Key pressed: " & E.Key_Code'Image);

         when Event_Quit =>
            Put_Line ("Quit requested");
            exit;

         when Event_Resize =>
            Put_Line ("Resize:" &
                      E.Mouse_X'Image & "x" & E.Mouse_Y'Image);
            -- Clamp and apply via the presentation layer.
            if E.Mouse_X >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
               and then E.Mouse_X <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
               and then E.Mouse_Y >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
               and then E.Mouse_Y <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
            then
               Raze.Tui.Set_Size (Raze.State.Dimension (E.Mouse_X),
                                  Raze.State.Dimension (E.Mouse_Y));
            end if;

         when others =>
            null;
      end case;
   end loop;

   -- Cleanup.
   Raze.Tui.Shutdown;
   Put_Line ("Goodbye!");

end Raze_Tui_Main;
