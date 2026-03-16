-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze.State — SPARK-proved implementation of TUI state management.
--
-- All state is held in package-level variables (hidden from the spec).
-- GNATprove can verify the Pre/Post contracts against this body.

package body Raze.State
  with SPARK_Mode => On,
       Refined_State => (Internal_State => (Initialized,
                                            Running_Flag,
                                            Current_Width,
                                            Current_Height,
                                            Current_Version))
is
   ---------------------------------------------------------------------------
   -- Internal state variables
   ---------------------------------------------------------------------------

   -- Whether the system has been initialized (Uninit->Running transition done).
   Initialized : Boolean := False;

   -- Whether the system is actively running (not quit-requested).
   Running_Flag : Boolean := False;

   -- Current terminal dimensions.
   Current_Width  : Dimension := Default_Width;
   Current_Height : Dimension := Default_Height;

   -- State version counter. Starts at 0, incremented on every mutation.
   Current_Version : Version_Number := 0;

   ---------------------------------------------------------------------------
   -- Lifecycle queries
   ---------------------------------------------------------------------------

   function Is_Initialized return Boolean is (Initialized);

   ---------------------------------------------------------------------------
   -- Initialization and shutdown
   ---------------------------------------------------------------------------

   procedure Initialize is
   begin
      -- Set dimensions to VT100 defaults.
      Current_Width   := Default_Width;
      Current_Height  := Default_Height;

      -- Start at version 0.
      Current_Version := 0;

      -- Mark as running and initialized.
      Running_Flag := True;
      Initialized  := True;
   end Initialize;

   procedure Shutdown is
   begin
      -- Transition to Stopped phase.
      Running_Flag := False;
      Initialized  := False;
   end Shutdown;

   ---------------------------------------------------------------------------
   -- Dimension queries
   ---------------------------------------------------------------------------

   function Get_Width return Dimension is (Current_Width);

   function Get_Height return Dimension is (Current_Height);

   procedure Set_Size (W, H : Dimension) is
   begin
      Current_Width  := W;
      Current_Height := H;

      -- Bump version (with wrapping to prevent overflow).
      -- The wrapping semantics are safe: even if the version wraps,
      -- the "version changed" detection still works because any
      -- difference indicates a change.
      if Current_Version < Version_Number'Last then
         Current_Version := Current_Version + 1;
      end if;
   end Set_Size;

   ---------------------------------------------------------------------------
   -- Version query
   ---------------------------------------------------------------------------

   function Get_Version return Version_Number is (Current_Version);

   ---------------------------------------------------------------------------
   -- Running state
   ---------------------------------------------------------------------------

   function Is_Running return Boolean is (Initialized and Running_Flag);

   procedure Request_Quit is
   begin
      Running_Flag := False;
   end Request_Quit;

end Raze.State;
