# TEST-NEEDS.md — raze-tui

<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) -->

## CRG Grade: C — ACHIEVED 2026-04-04

CRG grade target: **C**
Last updated: 2026-04-04

## Test coverage summary

### Rust (`src/rust/`) — `cargo test`

| Category | Count | Status |
|----------|-------|--------|
| Unit (EventKind discriminants, equality, copy, clone) | 10 | PASS |
| Unit (EventKind predicate helpers: is_key, is_mouse, …) | 8 | PASS |
| Unit (Event layout: size, alignment) | 2 | PASS |
| Unit (Event constructors: none, key, mouse, resize, quit) | 5 | PASS |
| Unit (modifier flags: bit isolation, combinations) | 4 | PASS |
| Unit (WidgetKind discriminants and equality) | 3 | PASS |
| Smoke (all constructors produce valid events) | 1 | PASS |
| Reflexive (EventKind eq, Event copy) | 2 | PASS |
| Contract (ABI size, modifier u8 fit, key_code max, resize layout, quit no payload) | 6 | PASS |
| Aspect / security (boundary key_code, unknown modifier bits, zero dimensions, field roundtrip) | 5 | PASS |
| **Total Rust** | **46** | **PASS** |

### Deno TypeScript (`tests/`) — `deno test tests/`

| File | Category | Count | Status |
|------|----------|-------|--------|
| `tests/unit/event_types_test.ts` | Unit | 33 | PASS |
| `tests/property/event_properties_test.ts` | P2P (property-based) | 14 | PASS |
| `tests/e2e/tui_lifecycle_test.ts` | E2E (lifecycle state machine) | 19 | PASS |
| `tests/aspect/security_test.ts` | Aspect / security | 16 | PASS |
| `tests/contract/abi_contract_test.ts` | Contract | 31 | PASS |
| **Total Deno** | | **113** | **PASS** |

### Benchmarks (`deno bench tests/bench/`)

| Benchmark | Avg time/iter | iter/s |
|-----------|--------------|--------|
| Build 1 Key event (16 bytes) | 2.0 µs | 498,500 |
| Build 1,000 Key events | 1.4 ms | 733 |
| Parse 1 Key event | 1.9 µs | 515,500 |
| Parse 1,000 events | 4.9 ms | 202 |
| Dispatch: switch on Key kind | 322 ns | 3,106,000 |
| Dispatch: 5 kinds round-robin | 49.6 ns | 20,150,000 |
| Dispatch: 1,000 events | 10.1 µs | 98,630 |
| Modifier extraction: 1 call | 25.9 ns | 38,590,000 |
| Modifier extraction: 1,000 calls | 1.3 µs | 794,900 |
| Widget layout: 1 compute | 26.3 ns | 38,020,000 |
| Widget layout: 1,000 resizes | 47.7 µs | 20,990 |
| Full pipeline: build+parse+dispatch 1,000 events | 4.9 ms | 204 |

## CRG C checklist

- [x] Unit tests — EventKind, RazeEvent, WidgetKind, modifiers
- [x] Smoke tests — all constructors produce structurally valid events
- [x] Build tests — `cargo test` (no FFI linking required for pure-type tests)
- [x] P2P (property-based) — range invariants, field boundary coverage
- [x] E2E tests — TUI lifecycle state machine (init → event loop → shutdown)
- [x] Reflexive tests — Copy + Eq self-consistency
- [x] Contract tests — ABI layout, modifier bit spec, dimension bounds, lifecycle
- [x] Aspect tests — security boundary: malformed input, no debug leak, concurrent isolation
- [x] Benchmarks baselined — 12 benchmarks across build/parse/dispatch/layout paths

## Not yet tested (requires Zig bridge linked)

- `raze_init()` / `raze_shutdown()` FFI calls
- Real terminal raw mode and ANSI rendering
- SPARK proof obligations (requires `gnatprove`)
- Zig bridge unit tests (requires `zig build test`)

## Commands

```bash
# Rust type tests (pure, no FFI)
cd src/rust && cargo test

# Deno contract + property + E2E + security tests
deno test tests/

# Benchmarks
deno bench tests/bench/
```
