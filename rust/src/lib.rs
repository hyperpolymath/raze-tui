// SPDX-License-Identifier: AGPL-3.0-or-later
//! RAZE Core - Rust core library for the RAZE-TUI framework
//!
//! This crate provides the state management and business logic layer
//! for polyglot TUI applications using Rust, Ada, and Zig.

#![no_std]
#![forbid(unsafe_code)]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;

/// TUI State container
///
/// Holds all application state in a format safe for FFI transfer.
#[repr(C)]
pub struct TuiState {
    /// Current screen width in cells
    pub width: u16,
    /// Current screen height in cells
    pub height: u16,
    /// Whether the TUI is running
    pub running: bool,
    /// Internal state version for change detection
    pub version: u64,
}

impl TuiState {
    /// Create a new TUI state
    pub const fn new() -> Self {
        Self {
            width: 80,
            height: 24,
            running: false,
            version: 0,
        }
    }

    /// Mark state as modified
    pub fn touch(&mut self) {
        self.version = self.version.wrapping_add(1);
    }
}

impl Default for TuiState {
    fn default() -> Self {
        Self::new()
    }
}

/// Event type for input handling
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventKind {
    /// No event
    None = 0,
    /// Key press event
    Key = 1,
    /// Mouse event
    Mouse = 2,
    /// Terminal resize event
    Resize = 3,
    /// Quit request
    Quit = 4,
}

/// Input event from the terminal
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Event {
    /// Event type
    pub kind: EventKind,
    /// Key code (for Key events)
    pub key_code: u32,
    /// Modifier flags
    pub modifiers: u8,
    /// Mouse X position (for Mouse events)
    pub mouse_x: u16,
    /// Mouse Y position (for Mouse events)
    pub mouse_y: u16,
}

impl Event {
    /// Create an empty event
    pub const fn none() -> Self {
        Self {
            kind: EventKind::None,
            key_code: 0,
            modifiers: 0,
            mouse_x: 0,
            mouse_y: 0,
        }
    }

    /// Create a quit event
    pub const fn quit() -> Self {
        Self {
            kind: EventKind::Quit,
            key_code: 0,
            modifiers: 0,
            mouse_x: 0,
            mouse_y: 0,
        }
    }
}

/// Widget base type
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WidgetKind {
    /// Empty/null widget
    None = 0,
    /// Text label
    Label = 1,
    /// Text input field
    Input = 2,
    /// Button
    Button = 3,
    /// Container/panel
    Panel = 4,
    /// List view
    List = 5,
}

/// Rectangle for layout
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct Rect {
    pub x: u16,
    pub y: u16,
    pub width: u16,
    pub height: u16,
}

impl Rect {
    /// Create a new rectangle
    pub const fn new(x: u16, y: u16, width: u16, height: u16) -> Self {
        Self { x, y, width, height }
    }
}

/// Color representation (ANSI 256 or RGB)
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
    pub mode: u8, // 0 = default, 1 = ansi256, 2 = rgb
}

impl Color {
    /// Default terminal color
    pub const fn default_color() -> Self {
        Self { r: 0, g: 0, b: 0, mode: 0 }
    }

    /// ANSI 256 color
    pub const fn ansi(index: u8) -> Self {
        Self { r: index, g: 0, b: 0, mode: 1 }
    }

    /// RGB color
    pub const fn rgb(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b, mode: 2 }
    }
}

/// Style for rendering
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct Style {
    pub fg: Color,
    pub bg: Color,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_state_creation() {
        let state = TuiState::new();
        assert_eq!(state.width, 80);
        assert_eq!(state.height, 24);
        assert!(!state.running);
    }

    #[test]
    fn test_state_touch() {
        let mut state = TuiState::new();
        let v1 = state.version;
        state.touch();
        assert_eq!(state.version, v1 + 1);
    }

    #[test]
    fn test_event_creation() {
        let event = Event::none();
        assert_eq!(event.kind, EventKind::None);

        let quit = Event::quit();
        assert_eq!(quit.kind, EventKind::Quit);
    }
}
