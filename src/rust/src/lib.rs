// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)

//! RAZE Core -- Rust consumer for the SPARK-proved TUI framework.
//!
//! This crate provides safe Rust wrappers around the C ABI functions
//! exported by the Zig FFI bridge (which in turn delegates to the
//! SPARK-proved core). All state management and event handling logic
//! lives in the SPARK layer; this crate is purely a consumer.
//!
//! # Architecture
//!
//! ```text
//! Rust (this crate) --> extern "C" --> Zig bridge --> SPARK core
//! ```
//!
//! # Safety
//!
//! This crate uses `#![forbid(unsafe_code)]`. All FFI calls are made
//! through safe wrapper functions that validate preconditions before
//! calling into the C ABI. The actual `extern "C"` declarations live
//! in a private `ffi` module that is not exported.
//!
//! # No-std support
//!
//! This crate is `#![no_std]` compatible. It does not allocate heap
//! memory and has no runtime dependencies beyond the linked Zig bridge.

#![no_std]
#![forbid(unsafe_code)]

/// FFI declarations for the Zig bridge C ABI.
///
/// These functions correspond to the exports in
/// `src/interface/ffi/src/bridge.zig`, which delegate to the SPARK
/// C exports in `src/spark/raze-exports.ads`.
///
/// SAFETY NOTE: Although these are `extern "C"` declarations, the
/// containing module is private and all public access goes through
/// safe wrappers that enforce preconditions.
mod ffi {
    /// Opaque state pointer returned by `raze_init`.
    /// Non-null indicates successful initialization.
    pub type StatePtr = *mut core::ffi::c_void;

    /// Event kind enum, matching the C ABI (int32_t).
    #[repr(C)]
    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub enum EventKind {
        /// No event available (sentinel).
        None = 0,
        /// Keyboard input event.
        Key = 1,
        /// Mouse input event.
        Mouse = 2,
        /// Terminal resize notification.
        Resize = 3,
        /// Quit request.
        Quit = 4,
    }

    /// Event record, matching the C ABI layout (16 bytes).
    #[repr(C)]
    #[derive(Debug, Clone, Copy)]
    pub struct RazeEvent {
        pub kind: EventKind,
        pub key_code: u32,
        pub modifiers: u8,
        pub _pad: u8,
        pub mouse_x: u16,
        pub mouse_y: u16,
        pub _pad2: [u8; 2],
    }

    extern "C" {
        /// Initialize the TUI system. Returns non-null on success.
        pub fn raze_init() -> StatePtr;

        /// Shut down the TUI system.
        pub fn raze_shutdown();

        /// Query whether the TUI is running.
        pub fn raze_is_running() -> bool;

        /// Get terminal width in cells.
        pub fn raze_get_width() -> u16;

        /// Get terminal height in cells.
        pub fn raze_get_height() -> u16;

        /// Set terminal dimensions.
        pub fn raze_set_size(width: u16, height: u16);

        /// Poll for next event (non-blocking).
        /// Returns true if an event was written to `event`.
        pub fn raze_poll_event(event: *mut RazeEvent) -> bool;

        /// Request quit.
        pub fn raze_request_quit();

        /// Get state version for change detection.
        pub fn raze_get_version() -> u64;
    }
}

// ---------------------------------------------------------------------------
// Public re-exports of C ABI types
// ---------------------------------------------------------------------------

/// Event classification, matching the SPARK/Idris2 ABI.
///
/// Each variant maps to a fixed integer value:
/// - `None` = 0 (no event available)
/// - `Key` = 1 (keyboard input)
/// - `Mouse` = 2 (mouse input)
/// - `Resize` = 3 (terminal resize)
/// - `Quit` = 4 (quit request)
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventKind {
    /// No event available (sentinel value).
    None = 0,
    /// Keyboard input event.
    Key = 1,
    /// Mouse input event.
    Mouse = 2,
    /// Terminal resize notification.
    Resize = 3,
    /// Quit request from the user or system.
    Quit = 4,
}

/// A TUI input event.
///
/// Layout matches the C ABI specification from `Events.idr`:
/// 16 bytes total, with padding for alignment.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Event {
    /// The kind of event.
    pub kind: EventKind,
    /// Key code (meaningful only for `EventKind::Key`).
    pub key_code: u32,
    /// Modifier bitmask (Shift=1, Ctrl=2, Alt=4).
    pub modifiers: u8,
    /// Padding byte (reserved, always 0).
    _pad: u8,
    /// Mouse X coordinate or new width (for Resize events).
    pub mouse_x: u16,
    /// Mouse Y coordinate or new height (for Resize events).
    pub mouse_y: u16,
    /// Padding bytes (reserved, always 0).
    _pad2: [u8; 2],
}

impl Event {
    /// Create a "no event" sentinel.
    pub const fn none() -> Self {
        Self {
            kind: EventKind::None,
            key_code: 0,
            modifiers: 0,
            _pad: 0,
            mouse_x: 0,
            mouse_y: 0,
            _pad2: [0, 0],
        }
    }
}

/// Widget kinds supported by the renderer.
///
/// Each variant maps to a fixed integer value matching the
/// Idris2 ABI specification (`widgetKindToNat`).
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WidgetKind {
    /// Null/placeholder widget.
    None = 0,
    /// Static text label.
    Label = 1,
    /// Text input field.
    Input = 2,
    /// Clickable button.
    Button = 3,
    /// Container panel (can hold children).
    Panel = 4,
    /// Scrollable list (can hold children).
    List = 5,
}

// ---------------------------------------------------------------------------
// Compile-time layout verification
// ---------------------------------------------------------------------------

// Ensure the Event struct matches the C ABI size (16 bytes).
const _: () = {
    assert!(core::mem::size_of::<Event>() == 16, "Event must be 16 bytes for C ABI");
};
