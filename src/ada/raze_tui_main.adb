-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- RAZE-TUI Demo Application
--
-- Entry point for the TUI demo. Uses the Ada presentation layer
-- (Raze.Tui), which delegates to the SPARK-proved core. The demo
-- enters the alternate screen, displays terminal size, and responds
-- to keyboard/mouse events until the user presses 'q' or Ctrl+C.

with Interfaces.C;
with Raze.Tui;
with Raze.State;
with Raze.Events;
with Raze.Posix;
with Raze.Terminal;
with Raze.Input_Parser;

procedure Raze_Tui_Main is
   use Raze.Events;
   E : Event;
begin
   -- Initialize TUI (SPARK core + raw mode + alt screen).
   Raze.Tui.Initialize;

   if not Raze.Tui.Is_Running then
      -- If raw mode failed (e.g. not a terminal), fall back to text output.
      Raze.Posix.Write_Str ("Error: Failed to initialize TUI (not a terminal?)" & ASCII.LF);
      return;
   end if;

   -- Display initial info in the alternate screen.
   Raze.Posix.Write_Escape (Raze.Terminal.Cursor_To (1, 1));
   Raze.Posix.Write_Escape (Raze.Terminal.Set_Bold);
   Raze.Posix.Write_Str ("RAZE-TUI Demo");
   Raze.Posix.Write_Escape (Raze.Terminal.Reset_Attrs);

   Raze.Posix.Write_Escape (Raze.Terminal.Cursor_To (2, 1));
   Raze.Posix.Write_Str ("Terminal:" &
                          Raze.Tui.Width'Image & "x" &
                          Raze.Tui.Height'Image);

   Raze.Posix.Write_Escape (Raze.Terminal.Cursor_To (3, 1));
   Raze.Posix.Write_Str ("Press 'q' to quit, type to see key codes.");

   Raze.Posix.Write_Escape (Raze.Terminal.Cursor_To (5, 1));
   Raze.Posix.Flush_Output;

   -- Main event loop.
   while Raze.Tui.Is_Running loop
      E := Raze.Tui.Poll_Event;

      case E.Kind is
         when Event_Key =>
            -- Check for quit key ('q' = 0x71).
            if E.Key_Code = Character'Pos ('q') and E.Mods = Mod_None then
               exit;
            end if;

            -- Check for Ctrl+C.
            if E.Key_Code = Character'Pos ('c') and E.Mods = Mod_Ctrl then
               exit;
            end if;

            -- Display key info.
            Raze.Posix.Write_Escape (Raze.Terminal.Clear_Line);
            Raze.Posix.Write_Str ("Key:" & E.Key_Code'Image &
                                  " Mods:" & E.Mods'Image);
            Raze.Posix.Write_Str (ASCII.CR & ASCII.LF);
            Raze.Posix.Flush_Output;

         when Event_Quit =>
            exit;

         when Event_Resize =>
            -- Update dimensions.
            if E.Mouse_X >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
               and then E.Mouse_X <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
               and then E.Mouse_Y >= Interfaces.C.unsigned_short (Raze.State.Min_Dimension)
               and then E.Mouse_Y <= Interfaces.C.unsigned_short (Raze.State.Max_Dimension)
            then
               Raze.Tui.Set_Size (Raze.State.Dimension (E.Mouse_X),
                                  Raze.State.Dimension (E.Mouse_Y));
            end if;

            -- Redraw size info.
            Raze.Posix.Write_Escape (Raze.Terminal.Cursor_To (2, 1));
            Raze.Posix.Write_Escape (Raze.Terminal.Clear_Line);
            Raze.Posix.Write_Str ("Terminal:" &
                                  Raze.Tui.Width'Image & "x" &
                                  Raze.Tui.Height'Image);
            Raze.Posix.Flush_Output;

         when others =>
            null;
      end case;
   end loop;

   -- Cleanup: restore terminal, leave alt screen.
   Raze.Tui.Shutdown;

end Raze_Tui_Main;
