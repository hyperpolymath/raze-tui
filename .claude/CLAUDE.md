# CLAUDE.md — RAZE-TUI Project Instructions

## READ FIRST

1. Read `0-AI-MANIFEST.a2ml` — canonical file locations
2. Read `.machine_readable/6a2/STATE.a2ml` — current position, TSDM categories, what's done/next
3. Follow TSDM: **must** items first, then should, then could

## Architecture (5-layer, 5-language)

```
Idris2 ABI (src/interface/abi/)     — proves interface correctness
    ↓ generates C headers
Zig FFI (src/interface/ffi/)        — PURE pass-through, ZERO logic
    ↓ C ABI
SPARK core (src/spark/)             — proves implementation correctness
    ├── Ada (src/ada/)              — direct `with` (SPARK is Ada)
    └── Rust (src/rust/)            — extern "C" via Zig bridge
```

## Critical Rules for This Repo

- **Zig bridge = ZERO logic.** No state, no allocation, no conditionals. Only `extern fn` forwarding.
- **Rust = `#![forbid(unsafe_code)]`**. Never add unsafe blocks.
- **SPARK = `with SPARK_Mode`** on all packages. Pre/Post on every subprogram.
- **Idris2 = `%default total`**. No `believe_me`, `assert_total`, `sorry`.
- **SPDX headers** on every file, every language.
- **Run `panic-attack assail`** before every commit.
- **Check proven repo** for formally verified alternatives before writing new code.

## Build Commands

```bash
just build          # Build Zig FFI + link SPARK + Rust
just check-abi      # Type-check Idris2 ABI
just prove          # Run GNATprove on SPARK packages
just test           # Run all tests (Zig + Rust + Ada)
just run            # Run the TUI demo
```

## Language Roles

| Language | Role | Location | Editable? |
|----------|------|----------|-----------|
| Idris2 | ABI proofs | `src/interface/abi/` | Yes |
| Zig | Pure FFI bridge | `src/interface/ffi/` | Bridge only |
| SPARK | Verified core | `src/spark/` | Yes |
| Ada | Presentation | `src/ada/` | Yes |
| Rust | Consumer | `src/rust/` | Yes |

## Next Session TODO (STANDING)

1. **RSR compliance audit** — run `just validate-rsr`, fix any gaps
2. **panic-attack assail** — run and address findings
3. **proven swap-outs** — check if proven repo has verified alternatives for any SPARK packages
4. **SPARK proofs** — discharge GNATprove obligations on all SPARK packages
5. **Terminal backend** — implement ANSI rendering and raw mode in SPARK
6. **Contractiles** — fill in must/trust/dust/intend files with real checks
7. **Update STATE.a2ml** — adjust completion percentage after work

## Banned Patterns

| Pattern | Language | Why |
|---------|----------|-----|
| `believe_me` | Idris2 | Unsound — bypasses type checker |
| `assert_total` | Idris2 | Unsound — hides non-termination |
| `sorry` | Idris2/Lean | Unsound — admits unproven goals |
| `unsafe` | Rust | Forbidden by `#![forbid(unsafe_code)]` |
| `unsafeCoerce` | Haskell | Unsound — bypasses types |
| `Obj.magic` | OCaml | Unsound — bypasses types |
| `pragma Suppress` | Ada | Disables runtime checks — defeats SPARK |
