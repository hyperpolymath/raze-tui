// SPDX-License-Identifier: AGPL-3.0-or-later

//! RAZE Core — Rust High-Assurance TUI Framework.
//!
//! This crate provides the state management and event system for the RAZE-TUI 
//! ecosystem. It is designed for "Polyglot TUIs" where the UI logic can be 
//! implemented in Rust, Ada, or Zig.
//!
//! CONSTRAINTS:
//! - `#![no_std]`: Suitable for bare-metal or restricted environments.
//! - `#![forbid(unsafe_code)]`: Enforces strict memory safety in the Rust layer.
//! - `#[repr(C)]`: Ensures ABI stability for cross-language FFI calls.

#![no_std]
#![forbid(unsafe_code)]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;

/// STATE CONTAINER: Holds the global application state.
/// This structure is the primary shared memory object between languages.
#[repr(C)]
pub struct TuiState {
    pub width: u16,   // Screen width in cells
    pub height: u16,  // Screen height in cells
    pub running: bool,
    pub version: u64, // Incremented on every mutation for cache invalidation
}

/// EVENT MODEL: Represents an input or system event.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Event {
    pub kind: EventKind,
    pub key_code: u32,
    pub modifiers: u8,
    pub mouse_x: u16,
    pub mouse_y: u16,
}

/// EVENT CLASSIFICATION: Supported interaction types.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EventKind {
    None = 0,
    Key = 1,
    Mouse = 2,
    Resize = 3,
    Quit = 4,
}

/// WIDGET INVENTORY: Predefined UI components supported by the renderer.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WidgetKind {
    None = 0,
    Label = 1,
    Input = 2,
    Button = 3,
    Panel = 4,
    List = 5,
}
