# RAZE-TUI Roadmap

This roadmap outlines the development plan for RAZE-TUI, a polyglot TUI framework using Rust, Zig, and Ada/SPARK.

## Current Status (v0.1.0-dev)

### Completed

- [x] **Rust Core** - Complete state management and type system
  - TuiState with dimensions, running flag, version tracking
  - Event system (Key, Mouse, Resize, Quit events)
  - Widget type enumeration (Label, Input, Button, Panel, List)
  - Color system (default, ANSI 256, RGB modes)
  - Style system (foreground, background, bold, italic, underline)
  - Rect for layout calculations
  - Full test coverage
  - `#![no_std]` + `#![forbid(unsafe_code)]` for safety

- [x] **Zig Bridge** - FFI layer complete
  - All core FFI exports with C ABI
  - State lifecycle (init, shutdown, is_running)
  - Dimension management (get/set width/height)
  - Event polling infrastructure
  - String buffer interop for Ada
  - Version tracking for change detection
  - Unit tests passing

- [x] **Ada TUI** - FFI bindings complete
  - All C function imports
  - Ada wrapper procedures/functions
  - SPARK contract annotations (Pre/Post conditions)
  - Type-safe dimension and version handling

- [x] **CI/CD Pipeline**
  - GitHub Actions workflow for all three languages
  - Pinned action versions (SHA hashes) for supply chain security
  - Multi-stage build (Rust -> Zig -> Ada)
  - GitLab/Bitbucket mirroring

- [x] **Security & Governance**
  - Comprehensive SECURITY.md policy
  - Provenance tracking (.well-known/provenance.json)
  - Dual license (MIT OR AGPL-3.0-or-later)
  - AI training consent requirements

---

## Phase 1: Terminal Backend

### 1.1 Terminal Detection & Initialization
- [ ] Detect terminal capabilities (colors, Unicode support)
- [ ] Raw mode handling in Zig
- [ ] Alternate screen buffer support
- [ ] Signal handling (SIGWINCH for resize, SIGINT/SIGTERM)

### 1.2 Input Handling
- [ ] Keyboard input parsing (standard keys, function keys, modifiers)
- [ ] Mouse input support (clicks, scroll, movement)
- [ ] Paste detection (bracketed paste mode)
- [ ] UTF-8 input handling

### 1.3 Output Rendering
- [ ] ANSI escape sequence generation
- [ ] Double buffering for flicker-free updates
- [ ] Dirty region tracking (minimal redraws)
- [ ] Unicode/grapheme cluster support

---

## Phase 2: Widget System

### 2.1 Layout Engine
- [ ] Flexbox-style layout constraints
- [ ] Absolute positioning
- [ ] Percentage-based sizing
- [ ] Min/max constraints
- [ ] Margin and padding

### 2.2 Core Widgets
- [ ] Label (static text, word wrap, alignment)
- [ ] Input (single-line text input, cursor, selection)
- [ ] Button (focusable, click handling)
- [ ] Panel (bordered container, title)
- [ ] List (scrollable, selectable items)

### 2.3 Advanced Widgets
- [ ] Table (columns, sorting, selection)
- [ ] Tree (expandable nodes)
- [ ] Tabs (tabbed interface)
- [ ] Progress bar
- [ ] Scrollbar
- [ ] Modal dialogs

---

## Phase 3: Event System

### 3.1 Event Dispatch
- [ ] Bubble/capture event phases
- [ ] Focus management
- [ ] Tab navigation
- [ ] Event handlers in Ada

### 3.2 Async Integration
- [ ] Tokio integration for Rust async
- [ ] Timer events
- [ ] Background task spawning
- [ ] Channel-based communication

---

## Phase 4: SPARK Verification

### 4.1 Proof Annotations
- [ ] Preconditions for all public APIs
- [ ] Postconditions for state changes
- [ ] Loop invariants where applicable
- [ ] Data flow contracts

### 4.2 Verification Targets
- [ ] Prove absence of runtime errors
- [ ] Prove memory safety properties
- [ ] Prove state machine correctness
- [ ] Document proof limitations

---

## Phase 5: Polish & Release

### 5.1 Documentation
- [ ] API reference (all three languages)
- [ ] Architecture guide
- [ ] Tutorial: Building a simple TUI app
- [ ] Examples directory

### 5.2 Testing
- [ ] Integration tests across FFI boundary
- [ ] Property-based testing (Rust)
- [ ] Fuzzing for input parsing
- [ ] Performance benchmarks

### 5.3 Packaging
- [ ] Cargo publish (raze-core)
- [ ] Zig package manager support
- [ ] Alire package (Ada)
- [ ] Release binaries

---

## Future Considerations

- **Accessibility**: Screen reader support, high contrast themes
- **Theming**: User-configurable color schemes
- **i18n**: Internationalization and RTL support
- **Alternative backends**: Windows Console API, terminfo
- **GUI target**: Optional graphical backend using same widget tree

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Priority areas:
1. Terminal backend implementation
2. Widget implementations
3. SPARK proof annotations
4. Documentation and examples

---

*Last updated: 2025-12-17*
