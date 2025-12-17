-- SPDX-License-Identifier: AGPL-3.0-or-later
-- RAZE-TUI Demo Application

with Ada.Text_IO; use Ada.Text_IO;
with Raze.Tui;

procedure Raze_Tui_Main is
   use Raze;
   E : Event;
begin
   Put_Line ("RAZE-TUI Demo");
   Put_Line ("=============");

   -- Initialize TUI
   Raze.Tui.Initialize;

   if not Raze.Tui.Is_Running then
      Put_Line ("Error: Failed to initialize TUI");
      return;
   end if;

   Put_Line ("Terminal size:" &
             Raze.Tui.Width'Image & "x" &
             Raze.Tui.Height'Image);

   -- Main event loop
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
            Raze.Tui.Set_Size (E.Mouse_X, E.Mouse_Y);

         when others =>
            null;
      end case;
   end loop;

   -- Cleanup
   Raze.Tui.Shutdown;
   Put_Line ("Goodbye!");

end Raze_Tui_Main;
