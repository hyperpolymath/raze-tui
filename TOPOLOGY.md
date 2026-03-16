<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) -->
<!-- TOPOLOGY.md -- Project architecture map and completion dashboard -->
<!-- Last updated: 2026-03-16 -->

# RAZE-TUI -- Project Topology

## Component Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        RAZE-TUI COMPONENT MAP                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    CONSUMER LAYER (Layer 5)                     │   │
│  │                                                                 │   │
│  │  ┌─────────────────────┐       ┌─────────────────────────────┐ │   │
│  │  │  ada/src/            │       │  rust/src/                   │ │   │
│  │  │  raze_tui_main.adb  │       │  lib.rs                     │ │   │
│  │  │  (Ada entry point)  │       │  (Rust consumer crate)      │ │   │
│  │  └────────┬────────────┘       └──────────────┬──────────────┘ │   │
│  │           │ direct call                       │ C ABI call     │   │
│  └───────────┼───────────────────────────────────┼────────────────┘   │
│              │                                   │                     │
│  ┌───────────┼───────────────────────────────────┼────────────────┐   │
│  │           │     SPARK CORE (Layer 4)          │                │   │
│  │           ▼                                   │                │   │
│  │  ┌─────────────────────┐                      │                │   │
│  │  │  ada/src/            │                      │                │   │
│  │  │  raze.ads           │ ◄─ Root types        │                │   │
│  │  │  raze-tui.ads       │ ◄─ SPARK contracts   │                │   │
│  │  │  raze-tui.adb       │ ◄─ SPARK proofs      │                │   │
│  │  └────────┬────────────┘                      │                │   │
│  │           │ imports C FFI                      │                │   │
│  └───────────┼───────────────────────────────────┼────────────────┘   │
│              │                                   │                     │
│  ┌───────────┼───────────────────────────────────┼────────────────┐   │
│  │           │     ZIG FFI BRIDGE (Layer 3)      │                │   │
│  │           ▼                                   ▼                │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │  zig/src/bridge.zig                                      │  │   │
│  │  │  - C ABI exports (raze_init, raze_shutdown, ...)         │  │   │
│  │  │  - Type marshalling (Zig <-> C structs)                  │  │   │
│  │  │  - Lifetime management for non-Ada callers               │  │   │
│  │  │  - String buffer interop                                 │  │   │
│  │  │  - NO BUSINESS LOGIC                                     │  │   │
│  │  └──────────────────────────┬───────────────────────────────┘  │   │
│  │                             │ conforms to                      │   │
│  └─────────────────────────────┼──────────────────────────────────┘   │
│                                │                                       │
│  ┌─────────────────────────────┼──────────────────────────────────┐   │
│  │            GENERATED C HEADERS (Layer 2)                       │   │
│  │                             ▼                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │  generated/abi/raze_abi.h                                │  │   │
│  │  │  - Struct definitions (TuiState, Event, Rect, ...)       │  │   │
│  │  │  - Function prototypes                                   │  │   │
│  │  │  - Platform-specific guards                              │  │   │
│  │  └──────────────────────────┬───────────────────────────────┘  │   │
│  │                             │ generated from                   │   │
│  └─────────────────────────────┼──────────────────────────────────┘   │
│                                │                                       │
│  ┌─────────────────────────────┼──────────────────────────────────┐   │
│  │            IDRIS2 ABI SPECIFICATION (Layer 1)                  │   │
│  │                             ▼                                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │  src/abi/Types.idr    -- Dependent type definitions      │  │   │
│  │  │  src/abi/Layout.idr   -- Memory layout proofs            │  │   │
│  │  │  src/abi/Foreign.idr  -- FFI function declarations       │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                 INFRASTRUCTURE                                  │   │
│  │  Justfile            -- Build automation                       │   │
│  │  .machine_readable/  -- STATE.scm, META.scm, ECOSYSTEM.scm    │   │
│  │  .github/workflows/  -- CI/CD (17 workflows)                   │   │
│  │  .hypatia/           -- Neurosymbolic security scanning        │   │
│  │  hooks/              -- Git hooks                              │   │
│  └────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
                         INPUT                              OUTPUT
                           │                                  ▲
                           ▼                                  │
                   ┌───────────────┐                 ┌───────────────┐
                   │ Terminal I/O  │                 │ Terminal I/O  │
                   │ (stdin/pty)   │                 │ (stdout/pty)  │
                   └───────┬───────┘                 └───────┬───────┘
                           │                                  ▲
                           ▼                                  │
              ┌────────────────────────┐         ┌────────────────────────┐
              │ Input Parser (SPARK)   │         │ ANSI Renderer (SPARK)  │
              │ - UTF-8 decode         │         │ - Escape sequences     │
              │ - Key/mouse classify   │         │ - Double buffering     │
              │ - Event construction   │         │ - Dirty region track   │
              └────────────┬───────────┘         └────────────┬───────────┘
                           │ Event                            ▲ Cell Buffer
                           ▼                                  │
              ┌────────────────────────┐         ┌────────────────────────┐
              │ Event Dispatch (SPARK) │         │ Layout Engine (SPARK)  │
              │ - Focus management     │────────►│ - Constraint solver    │
              │ - Bubble/capture       │ State   │ - Box model            │
              │ - Handler invocation   │ Change  │ - Widget positioning   │
              └────────────┬───────────┘         └────────────┬───────────┘
                           │                                  ▲
                           ▼                                  │
              ┌────────────────────────┐         ┌────────────────────────┐
              │ State Machine (SPARK)  │────────►│ Widget Tree (SPARK)    │
              │ - TUI lifecycle        │ Rebuild │ - Immutable tree       │
              │ - Version tracking     │ Trigger │ - Diff algorithm       │
              │ - Proven transitions   │         │ - Focus chain          │
              └────────────────────────┘         └────────────────────────┘
                           ▲
                           │ via Zig C ABI
              ┌────────────────────────┐
              │ Rust Async Runtime     │
              │ - tokio/smol bridge    │
              │ - Application state    │
              │ - Background tasks     │
              └────────────────────────┘
```

## Dependency Graph

```
Build-time dependencies (arrows point from dependent to dependency):

  Idris2 ABI (src/abi/*.idr)
       │
       │ generates
       ▼
  C Headers (generated/abi/*.h)
       │
       ├──────────────────────────┐
       │                          │
       ▼                          ▼
  Zig Bridge                 Ada/SPARK Core
  (zig/src/bridge.zig)      (ada/src/*.ads, *.adb)
       │                          │
       │                          │ direct Ada import
       │                          ▼
       │                     Ada Presentation
       │                     (ada/src/raze_tui_main.adb)
       │
       │ links as C library
       ▼
  Rust Consumer
  (rust/src/lib.rs)


Runtime call graph:

  Ada main ──direct──► SPARK Core ◄──Zig C ABI── Rust consumer
                            │
                            ▼
                       Terminal I/O
```

## Formal Verification Coverage

```
COMPONENT                          VERIFIED BY     PROOF TECHNIQUE
─────────────────────────────────  ──────────────  ─────────────────────────
INTERFACE LAYER
  Type definitions                 Idris2          Dependent types
  Memory layouts                   Idris2          Compile-time size proofs
  ABI compatibility                Idris2          Version-indexed types
  Function signatures              Idris2          Dependent function types

IMPLEMENTATION LAYER
  State machine transitions        SPARK           Pre/Post contracts
  Absence of runtime errors        SPARK           Flow analysis + proofs
  Data flow integrity              SPARK           Global/Depends contracts
  Layout constraint solving        SPARK           Loop invariants + termination
  Input parsing correctness        SPARK           Pre/Post + type invariants
  Buffer bounds safety             SPARK           Range checks + proofs

BRIDGE LAYER
  Type marshalling                 Zig comptime    Compile-time type checks
  Memory lifetime                  Zig             Allocator discipline

CONSUMER LAYER
  Rust type safety                 Rust compiler   Borrow checker + no_std
  No unsafe code                   Rust compiler   forbid(unsafe_code)
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
ABI & VERIFICATION
  Idris2 ABI Specification         ░░░░░░░░░░   0%    Phase 1 -- planned
  Generated C Headers              ░░░░░░░░░░   0%    Depends on Idris2 ABI
  SPARK Proof Coverage             ██░░░░░░░░  20%    Pre/Post on public APIs

CORE LAYERS
  Zig FFI Bridge                   ██████████ 100%    C ABI exports, string interop
  SPARK/Ada Core                   ██████░░░░  60%    Contracts written, proofs pending
  Rust Consumer                    ██████████ 100%    no_std types, events, widgets

TERMINAL BACKEND
  Input Parsing                    ░░░░░░░░░░   0%    Phase 2
  ANSI Rendering                   ░░░░░░░░░░   0%    Phase 2
  Raw Mode / Signals               ░░░░░░░░░░   0%    Phase 2

WIDGET SYSTEM
  Layout Engine                    ░░░░░░░░░░   0%    Phase 3
  Core Widgets                     ░░░░░░░░░░   0%    Phase 3
  Widget Tree / Diff               ░░░░░░░░░░   0%    Phase 3

INFRASTRUCTURE
  CI/CD Pipeline                   ██████████ 100%    17 workflows, SHA-pinned
  .machine_readable/               ██████████ 100%    STATE tracking active
  Test Suite                       ██████████ 100%    Rust + Zig coverage

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████░░░░░░  ~40%   Phase 1 restructure in progress
```

## Build Dependency Chain

```
Step  Tool       Input                          Output
────  ─────────  ─────────────────────────────  ──────────────────────────────
 1    idris2     src/abi/*.idr                  generated/abi/raze_abi.h
 2    zig build  zig/src/bridge.zig +           libraze_bridge.a (static lib)
                 generated/abi/raze_abi.h
 3    gnatprove  ada/src/*.ads, *.adb           SPARK proof results (.mlw)
 4    gprbuild   ada/src/*.ads, *.adb +         raze_tui (executable) or
                 libraze_bridge.a               libraze_ada.a (library)
 5    cargo      rust/src/lib.rs +              libraze_core.rlib or
                 libraze_bridge.a               consumer binary
```

## Module Relationships

| Module | Language | Depends On | Provides |
|--------|----------|------------|----------|
| `src/abi/Types.idr` | Idris2 | -- | Type definitions with proofs |
| `src/abi/Layout.idr` | Idris2 | Types.idr | Memory layout proofs |
| `src/abi/Foreign.idr` | Idris2 | Types.idr, Layout.idr | FFI signatures |
| `generated/abi/raze_abi.h` | C | Foreign.idr (generated) | C struct/function decls |
| `zig/src/bridge.zig` | Zig | raze_abi.h | C ABI exports, lifetime mgmt |
| `ada/src/raze.ads` | Ada | raze_abi.h | Root package, FFI type bindings |
| `ada/src/raze-tui.ads` | SPARK | raze.ads | TUI interface, contracts |
| `ada/src/raze-tui.adb` | SPARK | raze-tui.ads, bridge.zig | Proven implementation |
| `ada/src/raze_tui_main.adb` | Ada | raze-tui.ads | Entry point |
| `rust/src/lib.rs` | Rust | bridge.zig (C ABI) | Consumer crate |

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagrams
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
