-- SPDX-License-Identifier: PMPL-1.0-or-later
-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
--
-- Raze — Root package for the RAZE-TUI SPARK core.
--
-- This is a Pure package that serves as the namespace root for all
-- SPARK-proved packages: Raze.State, Raze.Events, Raze.Widgets,
-- and Raze.Exports.
--
-- The types previously defined here (Dimension, Event, Color, etc.)
-- have been moved to their respective child packages to match the
-- Idris2 ABI module structure.

package Raze
  with SPARK_Mode => On
is
   pragma Preelaborate;
end Raze;
