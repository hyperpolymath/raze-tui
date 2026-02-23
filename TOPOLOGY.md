<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# RAZE-TUI — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              ADA/SPARK TUI              │
                        │         (Terminal Presentation)         │
                        └───────────────────┬─────────────────────┘
                                            │ Zig FFI (C ABI)
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │               ZIG BRIDGE                │
                        │    (Type conversion, memory management) │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │ RUST CORE             │  │ SYSTEM INTERFACE               │
                        │ - State Management    │  │ - Async Runtime                │
                        │ - Business Logic      │  │ - Input Events                 │
                        │ - Widget Definitions  │  │ - Terminal I/O                 │
                        └───────────────────────┘  └────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Cargo / GPRBuild     0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE LAYERS
  Rust Core                         ██████████ 100%    State/Widgets stable
  Zig Bridge                        ██████████ 100%    C ABI exports verified
  Ada TUI (SPARK)                   ██████░░░░  60%    ncurses integration refining
  FFI Interop                       ██████████ 100%    String/Type conversion verified

USER INTERFACE
  Widget Library                    ████████░░  80%    Core components stable
  Event Loop                        ██████████ 100%    Async Rust -> Ada verified
  AdaCurses Integration             ████░░░░░░  40%    Layout logic prototyping

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build/test tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  Test Suite                        ██████████ 100%    High Rust/Zig coverage

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████████░░  ~80%   Framework core stable, UI maturing
```

## Key Dependencies

```
Rust Core ────────► Zig Bridge ────────► Ada/SPARK ────────► TUI Render
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
Async Runtime ──► C ABI Header ──────► SPARK Logic ──────► ncurses
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% ( in 10% increments).
