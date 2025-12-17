// SPDX-License-Identifier: AGPL-3.0-or-later
//! RAZE Bridge - Zig FFI layer between Rust core and Ada TUI
//!
//! This module provides C ABI exports for Ada consumption and handles
//! type conversion between Rust and Ada representations.

const std = @import("std");

// Re-export Rust types with C ABI
// These must match the #[repr(C)] structs in Rust

pub const TuiState = extern struct {
    width: u16,
    height: u16,
    running: bool,
    version: u64,
};

pub const EventKind = enum(c_int) {
    none = 0,
    key = 1,
    mouse = 2,
    resize = 3,
    quit = 4,
};

pub const Event = extern struct {
    kind: EventKind,
    key_code: u32,
    modifiers: u8,
    mouse_x: u16,
    mouse_y: u16,
};

pub const Rect = extern struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

pub const Color = extern struct {
    r: u8,
    g: u8,
    b: u8,
    mode: u8,
};

pub const Style = extern struct {
    fg: Color,
    bg: Color,
    bold: bool,
    italic: bool,
    underline: bool,
};

// Global state (managed by Zig, passed to Rust)
var global_state: ?*TuiState = null;
var allocator: std.mem.Allocator = std.heap.page_allocator;

// ============================================================================
// FFI Exports for Ada
// ============================================================================

/// Initialize the TUI system
/// Returns: Pointer to TuiState or null on failure
export fn raze_init() callconv(.C) ?*TuiState {
    if (global_state != null) {
        return global_state;
    }

    const state = allocator.create(TuiState) catch return null;
    state.* = TuiState{
        .width = 80,
        .height = 24,
        .running = true,
        .version = 0,
    };

    global_state = state;
    return state;
}

/// Shutdown the TUI system
export fn raze_shutdown() callconv(.C) void {
    if (global_state) |state| {
        state.running = false;
        allocator.destroy(state);
        global_state = null;
    }
}

/// Check if TUI is running
export fn raze_is_running() callconv(.C) bool {
    if (global_state) |state| {
        return state.running;
    }
    return false;
}

/// Get current terminal width
export fn raze_get_width() callconv(.C) u16 {
    if (global_state) |state| {
        return state.width;
    }
    return 0;
}

/// Get current terminal height
export fn raze_get_height() callconv(.C) u16 {
    if (global_state) |state| {
        return state.height;
    }
    return 0;
}

/// Set terminal dimensions (called on resize)
export fn raze_set_size(width: u16, height: u16) callconv(.C) void {
    if (global_state) |state| {
        state.width = width;
        state.height = height;
        state.version +%= 1;
    }
}

/// Poll for next event (non-blocking)
export fn raze_poll_event(event: *Event) callconv(.C) bool {
    // TODO: Implement actual event polling from terminal
    event.* = Event{
        .kind = .none,
        .key_code = 0,
        .modifiers = 0,
        .mouse_x = 0,
        .mouse_y = 0,
    };
    return false;
}

/// Request quit
export fn raze_request_quit() callconv(.C) void {
    if (global_state) |state| {
        state.running = false;
    }
}

/// Get state version (for change detection)
export fn raze_get_version() callconv(.C) u64 {
    if (global_state) |state| {
        return state.version;
    }
    return 0;
}

// ============================================================================
// String handling for Ada interop
// ============================================================================

/// String buffer for Ada interop
pub const StringBuffer = extern struct {
    data: [*]u8,
    len: usize,
    capacity: usize,
};

/// Allocate a string buffer
export fn raze_string_alloc(capacity: usize) callconv(.C) ?*StringBuffer {
    const buf = allocator.create(StringBuffer) catch return null;
    const data = allocator.alloc(u8, capacity) catch {
        allocator.destroy(buf);
        return null;
    };

    buf.* = StringBuffer{
        .data = data.ptr,
        .len = 0,
        .capacity = capacity,
    };

    return buf;
}

/// Free a string buffer
export fn raze_string_free(buf: ?*StringBuffer) callconv(.C) void {
    if (buf) |b| {
        allocator.free(b.data[0..b.capacity]);
        allocator.destroy(b);
    }
}

// ============================================================================
// Tests
// ============================================================================

test "init and shutdown" {
    const state = raze_init();
    try std.testing.expect(state != null);
    try std.testing.expect(raze_is_running());

    raze_shutdown();
    try std.testing.expect(!raze_is_running());
}

test "dimensions" {
    _ = raze_init();
    defer raze_shutdown();

    raze_set_size(120, 40);
    try std.testing.expectEqual(@as(u16, 120), raze_get_width());
    try std.testing.expectEqual(@as(u16, 40), raze_get_height());
}
