// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// RAZE-TUI Zig FFI Bridge — Pure Pass-Through Layer
//
// This module is a PURE BRIDGE with ZERO logic. Every exported function
// simply forwards its arguments to the corresponding SPARK C ABI export
// and returns the result unchanged.
//
// Architecture:
//   Rust consumer --> (extern "C") --> this bridge --> (extern "C") --> SPARK exports
//
// Rules:
//   - NO state variables.
//   - NO heap allocation.
//   - NO control flow beyond direct forwarding.
//   - NO type conversion or validation (SPARK owns all logic).
//   - Every function is a single-line delegation to a SPARK extern.
//
// The SPARK exports are declared in raze-exports.ads with pragma Export
// and are linked via the raze_spark static library.

// ============================================================================
// SPARK C ABI Imports (from raze-exports.ads)
// ============================================================================

/// Opaque pointer to the SPARK-managed TUI state.
/// The actual layout is defined in raze-state.ads; consumers must
/// treat this as opaque.
const RazeStatePtr = ?*anyopaque;

// -- SPARK exported functions (linked from libraze_spark.a) --

extern "C" fn spark_raze_init() RazeStatePtr;
extern "C" fn spark_raze_shutdown() void;
extern "C" fn spark_raze_is_running() bool;
extern "C" fn spark_raze_get_width() u16;
extern "C" fn spark_raze_get_height() u16;
extern "C" fn spark_raze_set_size(width: u16, height: u16) void;
extern "C" fn spark_raze_poll_event(event: *RazeEvent) bool;
extern "C" fn spark_raze_request_quit() void;
extern "C" fn spark_raze_get_version() u64;

// ============================================================================
// C ABI Type Definitions (must match SPARK and Idris2 ABI specs)
// ============================================================================

/// Event kind enum, matching the C ABI layout from Events.idr.
/// Values: none=0, key=1, mouse=2, resize=3, quit=4.
pub const EventKind = enum(c_int) {
    none = 0,
    key = 1,
    mouse = 2,
    resize = 3,
    quit = 4,
};

/// Event record, matching the C ABI layout (16 bytes total).
/// Field offsets: kind=0, key_code=4, modifiers=8, mouse_x=10, mouse_y=12.
pub const RazeEvent = extern struct {
    kind: EventKind,
    key_code: u32,
    modifiers: u8,
    _pad: u8 = 0,
    mouse_x: u16,
    mouse_y: u16,
    _pad2: [2]u8 = .{ 0, 0 },
};

// ============================================================================
// FFI Exports (consumed by Rust via extern "C")
// ============================================================================
// Each function is a direct pass-through with no logic whatsoever.

/// Initialize the TUI system.
/// Delegates to SPARK: spark_raze_init.
/// Returns an opaque state pointer, or null on failure.
export fn raze_init() callconv(.C) RazeStatePtr {
    return spark_raze_init();
}

/// Shut down the TUI system and release all resources.
/// Delegates to SPARK: spark_raze_shutdown.
export fn raze_shutdown() callconv(.C) void {
    spark_raze_shutdown();
}

/// Query whether the TUI system is currently running.
/// Delegates to SPARK: spark_raze_is_running.
export fn raze_is_running() callconv(.C) bool {
    return spark_raze_is_running();
}

/// Get the current terminal width in cells.
/// Delegates to SPARK: spark_raze_get_width.
export fn raze_get_width() callconv(.C) u16 {
    return spark_raze_get_width();
}

/// Get the current terminal height in cells.
/// Delegates to SPARK: spark_raze_get_height.
export fn raze_get_height() callconv(.C) u16 {
    return spark_raze_get_height();
}

/// Set the terminal dimensions (e.g., on a resize event).
/// Delegates to SPARK: spark_raze_set_size.
export fn raze_set_size(width: u16, height: u16) callconv(.C) void {
    spark_raze_set_size(width, height);
}

/// Poll for the next input event (non-blocking).
/// Writes the event into the provided pointer. Returns true if
/// an event was available, false otherwise.
/// Delegates to SPARK: spark_raze_poll_event.
export fn raze_poll_event(event: *RazeEvent) callconv(.C) bool {
    return spark_raze_poll_event(event);
}

/// Request the TUI to shut down on the next loop iteration.
/// Delegates to SPARK: spark_raze_request_quit.
export fn raze_request_quit() callconv(.C) void {
    spark_raze_request_quit();
}

/// Get the current state version for change detection.
/// The version is monotonically non-decreasing.
/// Delegates to SPARK: spark_raze_get_version.
export fn raze_get_version() callconv(.C) u64 {
    return spark_raze_get_version();
}

// ============================================================================
// Compile-time verification
// ============================================================================

comptime {
    // Verify that RazeEvent has the expected C ABI size (16 bytes).
    if (@sizeOf(RazeEvent) != 16) {
        @compileError("RazeEvent size mismatch: expected 16 bytes for C ABI compatibility");
    }
}
