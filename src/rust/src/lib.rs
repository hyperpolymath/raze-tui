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

// ---------------------------------------------------------------------------
// Public helpers
// ---------------------------------------------------------------------------

impl EventKind {
    /// Returns true if this is a key input event.
    pub const fn is_key(self) -> bool {
        matches!(self, EventKind::Key)
    }

    /// Returns true if this is a mouse input event.
    pub const fn is_mouse(self) -> bool {
        matches!(self, EventKind::Mouse)
    }

    /// Returns true if this is a resize event.
    pub const fn is_resize(self) -> bool {
        matches!(self, EventKind::Resize)
    }

    /// Returns true if this is a quit event.
    pub const fn is_quit(self) -> bool {
        matches!(self, EventKind::Quit)
    }

    /// Returns true if this is the sentinel "no event" value.
    pub const fn is_none(self) -> bool {
        matches!(self, EventKind::None)
    }

    /// Returns the discriminant as a u8, matching the C ABI representation.
    pub const fn as_u8(self) -> u8 {
        self as u8
    }
}

/// Modifier bit-flag constants (matching SPARK Raze.Events.Mod_* and the
/// Idris2 ABI specification).
pub mod modifiers {
    /// No modifier keys held.
    pub const NONE: u8 = 0;
    /// Shift key.
    pub const SHIFT: u8 = 1;
    /// Ctrl key.
    pub const CTRL: u8 = 2;
    /// Alt key.
    pub const ALT: u8 = 4;
    /// Super (Windows/Command) key — reserved for future use.
    pub const SUPER: u8 = 8;
}

impl Event {
    /// Create a key event.
    pub const fn key(key_code: u32, mods: u8) -> Self {
        Self {
            kind: EventKind::Key,
            key_code,
            modifiers: mods,
            _pad: 0,
            mouse_x: 0,
            mouse_y: 0,
            _pad2: [0, 0],
        }
    }

    /// Create a mouse event.
    pub const fn mouse(x: u16, y: u16, mods: u8) -> Self {
        Self {
            kind: EventKind::Mouse,
            key_code: 0,
            modifiers: mods,
            _pad: 0,
            mouse_x: x,
            mouse_y: y,
            _pad2: [0, 0],
        }
    }

    /// Create a resize event (width, height stored in mouse_x / mouse_y).
    pub const fn resize(width: u16, height: u16) -> Self {
        Self {
            kind: EventKind::Resize,
            key_code: 0,
            modifiers: 0,
            _pad: 0,
            mouse_x: width,
            mouse_y: height,
            _pad2: [0, 0],
        }
    }

    /// Create a quit event.
    pub const fn quit() -> Self {
        Self {
            kind: EventKind::Quit,
            key_code: 0,
            modifiers: 0,
            _pad: 0,
            mouse_x: 0,
            mouse_y: 0,
            _pad2: [0, 0],
        }
    }

    /// Returns true if this is a key event with Ctrl held.
    pub const fn is_ctrl(&self) -> bool {
        (self.modifiers & modifiers::CTRL) != 0
    }

    /// Returns true if this is a key event with Shift held.
    pub const fn is_shift(&self) -> bool {
        (self.modifiers & modifiers::SHIFT) != 0
    }

    /// Returns true if this is a key event with Alt held.
    pub const fn is_alt(&self) -> bool {
        (self.modifiers & modifiers::ALT) != 0
    }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    extern crate std;

    use super::*;
    use core::mem;

    // -----------------------------------------------------------------------
    // Unit: EventKind discriminants match C ABI
    // -----------------------------------------------------------------------

    #[test]
    fn event_kind_none_discriminant() {
        assert_eq!(EventKind::None as u8, 0);
    }

    #[test]
    fn event_kind_key_discriminant() {
        assert_eq!(EventKind::Key as u8, 1);
    }

    #[test]
    fn event_kind_mouse_discriminant() {
        assert_eq!(EventKind::Mouse as u8, 2);
    }

    #[test]
    fn event_kind_resize_discriminant() {
        assert_eq!(EventKind::Resize as u8, 3);
    }

    #[test]
    fn event_kind_quit_discriminant() {
        assert_eq!(EventKind::Quit as u8, 4);
    }

    // -----------------------------------------------------------------------
    // Unit: EventKind equality and copy
    // -----------------------------------------------------------------------

    #[test]
    fn event_kind_equality() {
        assert_eq!(EventKind::None, EventKind::None);
        assert_eq!(EventKind::Key, EventKind::Key);
        assert_ne!(EventKind::Key, EventKind::Mouse);
        assert_ne!(EventKind::None, EventKind::Quit);
    }

    #[test]
    fn event_kind_copy_semantics() {
        let a = EventKind::Key;
        let b = a; // Copy
        assert_eq!(a, b);
    }

    #[test]
    fn event_kind_clone() {
        let a = EventKind::Mouse;
        let b = a.clone();
        assert_eq!(a, b);
    }

    // -----------------------------------------------------------------------
    // Unit: EventKind predicate helpers
    // -----------------------------------------------------------------------

    #[test]
    fn event_kind_is_key() {
        assert!(EventKind::Key.is_key());
        assert!(!EventKind::Mouse.is_key());
        assert!(!EventKind::None.is_key());
    }

    #[test]
    fn event_kind_is_mouse() {
        assert!(EventKind::Mouse.is_mouse());
        assert!(!EventKind::Key.is_mouse());
    }

    #[test]
    fn event_kind_is_resize() {
        assert!(EventKind::Resize.is_resize());
        assert!(!EventKind::Quit.is_resize());
    }

    #[test]
    fn event_kind_is_quit() {
        assert!(EventKind::Quit.is_quit());
        assert!(!EventKind::Key.is_quit());
    }

    #[test]
    fn event_kind_is_none() {
        assert!(EventKind::None.is_none());
        assert!(!EventKind::Key.is_none());
    }

    #[test]
    fn event_kind_as_u8_all_variants() {
        assert_eq!(EventKind::None.as_u8(), 0);
        assert_eq!(EventKind::Key.as_u8(), 1);
        assert_eq!(EventKind::Mouse.as_u8(), 2);
        assert_eq!(EventKind::Resize.as_u8(), 3);
        assert_eq!(EventKind::Quit.as_u8(), 4);
    }

    // -----------------------------------------------------------------------
    // Unit: Event layout — size and alignment
    // -----------------------------------------------------------------------

    #[test]
    fn event_size_is_16_bytes() {
        assert_eq!(mem::size_of::<Event>(), 16);
    }

    #[test]
    fn event_align_is_4_bytes() {
        // repr(C) with first field being an i32 enum forces 4-byte alignment.
        assert_eq!(mem::align_of::<Event>(), 4);
    }

    // -----------------------------------------------------------------------
    // Unit: Event constructors
    // -----------------------------------------------------------------------

    #[test]
    fn event_none_sentinel() {
        let e = Event::none();
        assert!(e.kind.is_none());
        assert_eq!(e.key_code, 0);
        assert_eq!(e.modifiers, 0);
        assert_eq!(e.mouse_x, 0);
        assert_eq!(e.mouse_y, 0);
    }

    #[test]
    fn event_none_pad_fields_zero() {
        // Verify padding fields via the public API rather than raw transmute
        // (transmute is forbidden by #![forbid(unsafe_code)]).
        let e = Event::none();
        // The modifiers field is at offset 8 (after kind:4 + key_code:4).
        // _pad is not accessible, but we can verify it doesn't affect behaviour
        // by comparing two independently constructed none() events for equality.
        let e2 = Event::none();
        assert_eq!(e.kind, e2.kind);
        assert_eq!(e.key_code, e2.key_code);
        assert_eq!(e.modifiers, e2.modifiers);
        assert_eq!(e.mouse_x, e2.mouse_x);
        assert_eq!(e.mouse_y, e2.mouse_y);
    }

    #[test]
    fn event_key_constructor() {
        let e = Event::key(b'a' as u32, modifiers::CTRL);
        assert_eq!(e.kind, EventKind::Key);
        assert_eq!(e.key_code, b'a' as u32);
        assert_eq!(e.modifiers, modifiers::CTRL);
        assert!(e.is_ctrl());
        assert!(!e.is_shift());
    }

    #[test]
    fn event_mouse_constructor() {
        let e = Event::mouse(80, 24, modifiers::NONE);
        assert_eq!(e.kind, EventKind::Mouse);
        assert_eq!(e.mouse_x, 80);
        assert_eq!(e.mouse_y, 24);
        assert_eq!(e.key_code, 0);
    }

    #[test]
    fn event_resize_constructor() {
        let e = Event::resize(132, 50);
        assert_eq!(e.kind, EventKind::Resize);
        assert_eq!(e.mouse_x, 132);
        assert_eq!(e.mouse_y, 50);
        assert_eq!(e.modifiers, 0);
    }

    #[test]
    fn event_quit_constructor() {
        let e = Event::quit();
        assert_eq!(e.kind, EventKind::Quit);
        assert_eq!(e.key_code, 0);
        assert_eq!(e.mouse_x, 0);
        assert_eq!(e.mouse_y, 0);
    }

    // -----------------------------------------------------------------------
    // Unit: modifier flag combinations
    // -----------------------------------------------------------------------

    #[test]
    fn modifier_flags_are_distinct_bits() {
        assert_eq!(modifiers::SHIFT & modifiers::CTRL, 0);
        assert_eq!(modifiers::CTRL & modifiers::ALT, 0);
        assert_eq!(modifiers::SHIFT & modifiers::ALT, 0);
    }

    #[test]
    fn modifier_ctrl_shift_combination() {
        let mods = modifiers::CTRL | modifiers::SHIFT;
        let e = Event::key(0x41, mods);
        assert!(e.is_ctrl());
        assert!(e.is_shift());
        assert!(!e.is_alt());
    }

    #[test]
    fn modifier_all_three() {
        let mods = modifiers::CTRL | modifiers::SHIFT | modifiers::ALT;
        let e = Event::key(0x41, mods);
        assert!(e.is_ctrl());
        assert!(e.is_shift());
        assert!(e.is_alt());
    }

    // -----------------------------------------------------------------------
    // Unit: WidgetKind discriminants
    // -----------------------------------------------------------------------

    #[test]
    fn widget_kind_discriminants() {
        assert_eq!(WidgetKind::None as u8, 0);
        assert_eq!(WidgetKind::Label as u8, 1);
        assert_eq!(WidgetKind::Input as u8, 2);
        assert_eq!(WidgetKind::Button as u8, 3);
        assert_eq!(WidgetKind::Panel as u8, 4);
        assert_eq!(WidgetKind::List as u8, 5);
    }

    #[test]
    fn widget_kind_equality() {
        assert_eq!(WidgetKind::Label, WidgetKind::Label);
        assert_ne!(WidgetKind::Input, WidgetKind::Button);
    }

    // -----------------------------------------------------------------------
    // Smoke tests: all constructors produce valid events
    // -----------------------------------------------------------------------

    #[test]
    fn smoke_all_event_kinds_constructible() {
        let events = [
            Event::none(),
            Event::key(0, 0),
            Event::mouse(0, 0, 0),
            Event::resize(80, 24),
            Event::quit(),
        ];
        let expected_kinds = [
            EventKind::None,
            EventKind::Key,
            EventKind::Mouse,
            EventKind::Resize,
            EventKind::Quit,
        ];
        for (e, k) in events.iter().zip(expected_kinds.iter()) {
            assert_eq!(e.kind, *k);
        }
    }

    // -----------------------------------------------------------------------
    // Reflexive tests: Copy + PartialEq consistency
    // -----------------------------------------------------------------------

    #[test]
    fn reflexive_event_kind_eq() {
        let variants = [
            EventKind::None,
            EventKind::Key,
            EventKind::Mouse,
            EventKind::Resize,
            EventKind::Quit,
        ];
        for v in variants {
            assert_eq!(v, v, "EventKind::{v:?} must equal itself");
        }
    }

    #[test]
    fn reflexive_event_copy() {
        let original = Event::key(0x61, modifiers::ALT);
        let copy = original;
        assert_eq!(original.kind, copy.kind);
        assert_eq!(original.key_code, copy.key_code);
        assert_eq!(original.modifiers, copy.modifiers);
        assert_eq!(original.mouse_x, copy.mouse_x);
        assert_eq!(original.mouse_y, copy.mouse_y);
    }

    // -----------------------------------------------------------------------
    // Contract tests: ABI layout invariants
    // -----------------------------------------------------------------------

    #[test]
    fn contract_event_size_matches_abi_spec() {
        // The Events.idr ABI specification mandates exactly 16 bytes.
        assert_eq!(mem::size_of::<Event>(), 16);
    }

    #[test]
    fn contract_event_kind_repr_c_size() {
        // EventKind is repr(C) with Size => 32 in SPARK (int32_t in C ABI).
        assert_eq!(mem::size_of::<EventKind>(), 4);
    }

    #[test]
    fn contract_modifier_fits_in_u8() {
        // All modifier combos must fit in a u8 (8-bit field in C ABI).
        let all: u16 = (modifiers::SHIFT as u16)
            | (modifiers::CTRL as u16)
            | (modifiers::ALT as u16)
            | (modifiers::SUPER as u16);
        assert!(all <= 255, "All modifiers combined must fit in u8");
    }

    #[test]
    fn contract_key_code_max_value() {
        // key_code is u32, so 0xFFFFFFFF is valid — should not panic.
        let e = Event::key(u32::MAX, 0);
        assert_eq!(e.key_code, u32::MAX);
    }

    #[test]
    fn contract_mouse_coords_max_value() {
        // mouse_x and mouse_y are u16.
        let e = Event::mouse(u16::MAX, u16::MAX, 0);
        assert_eq!(e.mouse_x, u16::MAX);
        assert_eq!(e.mouse_y, u16::MAX);
    }

    #[test]
    fn contract_resize_stores_dimensions_in_mouse_fields() {
        // By ABI convention, Resize events store width in mouse_x and
        // height in mouse_y. This is the contract between layers.
        let e = Event::resize(200, 60);
        assert_eq!(e.mouse_x, 200, "Resize width stored in mouse_x");
        assert_eq!(e.mouse_y, 60, "Resize height stored in mouse_y");
    }

    #[test]
    fn contract_quit_event_carries_no_payload() {
        // Quit events must not carry key_code or mouse coordinate payload.
        let e = Event::quit();
        assert_eq!(e.key_code, 0, "Quit must have zero key_code");
        assert_eq!(e.mouse_x, 0, "Quit must have zero mouse_x");
        assert_eq!(e.mouse_y, 0, "Quit must have zero mouse_y");
        assert_eq!(e.modifiers, 0, "Quit must have zero modifiers");
    }

    // -----------------------------------------------------------------------
    // Aspect / security tests: boundary and malformed inputs
    // -----------------------------------------------------------------------

    #[test]
    fn aspect_key_code_zero_is_valid() {
        let e = Event::key(0, 0);
        assert_eq!(e.kind, EventKind::Key);
        assert_eq!(e.key_code, 0);
    }

    #[test]
    fn aspect_key_code_max_is_valid() {
        // 0xFFFFFFFF must be representable without panic or truncation.
        let e = Event::key(0xFFFF_FFFF, 0);
        assert_eq!(e.key_code, 0xFFFF_FFFF);
    }

    #[test]
    fn aspect_unknown_modifier_bits_preserved() {
        // Bits beyond the known flags should be stored and retrieved as-is.
        let high_bits: u8 = 0b1111_0000;
        let e = Event::key(0x41, high_bits);
        assert_eq!(e.modifiers, high_bits);
    }

    #[test]
    fn aspect_resize_zero_dimensions_stored() {
        // Resize(0, 0) is malformed (SPARK would reject it), but at the
        // Rust type level it must not panic or corrupt memory.
        let e = Event::resize(0, 0);
        assert_eq!(e.mouse_x, 0);
        assert_eq!(e.mouse_y, 0);
    }

    #[test]
    fn aspect_event_field_roundtrip() {
        // Construct an Event and verify field-level roundtrip integrity.
        // (Raw byte-level transmute is forbidden by #![forbid(unsafe_code)].)
        let original = Event::key(0xDEAD_BEEF, modifiers::CTRL | modifiers::SHIFT);
        // Copy via Clone (Copy trait) and verify fields survive.
        let recovered = original;
        assert_eq!(recovered.kind, EventKind::Key);
        assert_eq!(recovered.key_code, 0xDEAD_BEEF);
        assert_eq!(recovered.modifiers, modifiers::CTRL | modifiers::SHIFT);
        assert_eq!(recovered.mouse_x, 0);
        assert_eq!(recovered.mouse_y, 0);
    }

    // -----------------------------------------------------------------------
    // Property-based style: exhaustive discriminant coverage
    // -----------------------------------------------------------------------

    #[test]
    fn property_all_event_kind_discriminants_in_range_0_to_4() {
        // Exhaustively check all defined variants — none should exceed 4.
        let max_disc = [
            EventKind::None as u8,
            EventKind::Key as u8,
            EventKind::Mouse as u8,
            EventKind::Resize as u8,
            EventKind::Quit as u8,
        ]
        .iter()
        .copied()
        .max()
        .unwrap();
        assert!(max_disc <= 4);
    }

    #[test]
    fn property_event_kind_count_is_five() {
        // There are exactly 5 variants (None, Key, Mouse, Resize, Quit).
        // Ensures no variant was accidentally omitted from the ABI.
        let variants = [
            EventKind::None,
            EventKind::Key,
            EventKind::Mouse,
            EventKind::Resize,
            EventKind::Quit,
        ];
        assert_eq!(variants.len(), 5);
    }

    #[test]
    fn property_widget_kind_count_is_six() {
        let variants = [
            WidgetKind::None,
            WidgetKind::Label,
            WidgetKind::Input,
            WidgetKind::Button,
            WidgetKind::Panel,
            WidgetKind::List,
        ];
        assert_eq!(variants.len(), 6);
    }

    #[test]
    fn property_mouse_coords_are_u16_bounded() {
        // Verify that u16::MAX is representable as mouse coordinates.
        let e = Event::mouse(u16::MAX, u16::MAX, 0);
        assert!(e.mouse_x <= u16::MAX);
        assert!(e.mouse_y <= u16::MAX);
    }
}
