-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.Exports — C ABI surface for SPARK core.
--
-- This package provides pragma Export wrappers around the SPARK
-- packages (Raze.State, Raze.Events, Raze.Widgets). These are the
-- functions that the Zig FFI bridge calls via extern "C".
--
-- Naming convention: all exports use the prefix "spark_raze_" to
-- distinguish them from the bridge-level "raze_" exports.
--
-- IMPORTANT: This package intentionally does NOT have SPARK_Mode
-- because pragma Export is not permitted in SPARK. The bodies of
-- these wrappers are trivial one-line delegations to SPARK-proved
-- subprograms, so no additional verification is needed here.

with Interfaces.C; use Interfaces.C;
with Raze.State;
with Raze.Events;
with System;

package Raze.Exports is

   ---------------------------------------------------------------------------
   -- State management exports
   ---------------------------------------------------------------------------

   -- Initialize the TUI system.
   -- Returns the address of an internal sentinel (non-null on success,
   -- null on failure). The Zig bridge treats this as an opaque pointer.
   function Spark_Raze_Init return System.Address
     with Export, Convention => C, External_Name => "spark_raze_init";

   -- Shut down the TUI system.
   procedure Spark_Raze_Shutdown
     with Export, Convention => C, External_Name => "spark_raze_shutdown";

   -- Query whether the TUI is running.
   function Spark_Raze_Is_Running return Interfaces.C.C_bool
     with Export, Convention => C, External_Name => "spark_raze_is_running";

   -- Get current terminal width.
   function Spark_Raze_Get_Width return Interfaces.C.unsigned_short
     with Export, Convention => C, External_Name => "spark_raze_get_width";

   -- Get current terminal height.
   function Spark_Raze_Get_Height return Interfaces.C.unsigned_short
     with Export, Convention => C, External_Name => "spark_raze_get_height";

   -- Set terminal dimensions.
   procedure Spark_Raze_Set_Size (W, H : Interfaces.C.unsigned_short)
     with Export, Convention => C, External_Name => "spark_raze_set_size";

   -- Poll for next event.
   -- Writes the event into the provided C struct pointer.
   -- Returns True (C_bool) if an event was available.
   function Spark_Raze_Poll_Event (E : access Raze.Events.Event)
     return Interfaces.C.C_bool
     with Export, Convention => C, External_Name => "spark_raze_poll_event";

   -- Request quit.
   procedure Spark_Raze_Request_Quit
     with Export, Convention => C, External_Name => "spark_raze_request_quit";

   -- Get state version.
   function Spark_Raze_Get_Version return Interfaces.C.unsigned_long
     with Export, Convention => C, External_Name => "spark_raze_get_version";

end Raze.Exports;
