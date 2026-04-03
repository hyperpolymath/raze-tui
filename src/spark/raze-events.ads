-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Events — SPARK-proved event handling.
--
-- Defines the event model (kinds, modifiers, event record) and
-- the event processing subprogram. All types use Convention => C
-- for ABI compatibility with the Zig bridge.
--
-- Corresponds to the Idris2 specification in RazeTui.ABI.Events.

with Interfaces.C; use Interfaces.C;
with Raze.State;

package Raze.Events
  with SPARK_Mode => On
is
   ---------------------------------------------------------------------------
   -- Event kinds (C ABI enum values 0..4)
   ---------------------------------------------------------------------------

   -- The five event kinds. Representation values match the Idris2 ABI
   -- specification (eventKindToNat) and the Zig bridge EventKind enum.
   type Event_Kind is
     (Event_None,
      Event_Key,
      Event_Mouse,
      Event_Resize,
      Event_Quit)
     with Convention => C,
          Size       => 32;  -- int32_t in C ABI

   for Event_Kind use
     (Event_None   => 0,
      Event_Key    => 1,
      Event_Mouse  => 2,
      Event_Resize => 3,
      Event_Quit   => 4);

   ---------------------------------------------------------------------------
   -- Modifier flags (bitmask, fits in u8)
   ---------------------------------------------------------------------------

   -- Modifier key flags. Bit 0 = Shift, Bit 1 = Ctrl, Bit 2 = Alt.
   -- Combinations are formed by bitwise OR.
   type Modifiers is new Interfaces.C.unsigned_char;

   Mod_None  : constant Modifiers := 0;
   Mod_Shift : constant Modifiers := 1;
   Mod_Ctrl  : constant Modifiers := 2;
   Mod_Alt   : constant Modifiers := 4;

   ---------------------------------------------------------------------------
   -- Event record (16 bytes, C ABI compatible)
   ---------------------------------------------------------------------------

   -- The event record. Layout matches the C ABI specification from Events.idr:
   --   kind      : offset 0, 4 bytes
   --   key_code  : offset 4, 4 bytes
   --   modifiers : offset 8, 1 byte
   --   (padding) : offset 9, 1 byte
   --   mouse_x   : offset 10, 2 bytes
   --   mouse_y   : offset 12, 2 bytes
   --   (padding) : offset 14, 2 bytes
   --   Total: 16 bytes
   type Event is record
      Kind      : Event_Kind;
      Key_Code  : Interfaces.C.unsigned;
      Mods      : Modifiers;
      Mouse_X   : Interfaces.C.unsigned_short;
      Mouse_Y   : Interfaces.C.unsigned_short;
   end record
     with Convention => C;

   -- The "no event" sentinel value.
   No_Event : constant Event :=
     (Kind     => Event_None,
      Key_Code => 0,
      Mods     => Mod_None,
      Mouse_X  => 0,
      Mouse_Y  => 0);

   ---------------------------------------------------------------------------
   -- Event polling
   ---------------------------------------------------------------------------

   -- Poll for the next input event (non-blocking).
   -- Returns No_Event if no event is available.
   -- Sets Has_Event to True if a real event was returned.
   --
   -- Precondition: the TUI system must be initialized.
   procedure Poll_Event (E         : out Event;
                         Has_Event : out Boolean)
     with Global => (Input => Raze.State.Internal_State),
          Pre    => Raze.State.Is_Initialized,
          Post   => (if not Has_Event then E = No_Event);

   -- Push an event into the pending buffer (called from Raze.Posix).
   -- This bridges the non-SPARK I/O layer and the SPARK event system.
   procedure Push_Event (E : Event)
     with SPARK_Mode => Off;

   ---------------------------------------------------------------------------
   -- Event processing
   ---------------------------------------------------------------------------

   -- Process a single event, updating the TUI state as needed.
   -- For Resize events, updates the screen dimensions in Raze.State.
   -- For Quit events, requests shutdown via Raze.State.Request_Quit.
   -- For all other events, the state is unchanged.
   --
   -- Precondition: the TUI system must be running.
   -- Postcondition: the system remains initialized (may or may not
   --   be running, depending on whether a Quit event was processed).
   procedure Process_Event (E : Event)
     with Global => (In_Out => Raze.State.Internal_State),
          Pre    => Raze.State.Is_Initialized and Raze.State.Is_Running,
          Post   => Raze.State.Is_Initialized;

end Raze.Events;
