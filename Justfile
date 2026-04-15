# SPDX-License-Identifier: PMPL-1.0-or-later
# justfile -- Build recipes for RAZE-TUI (5-language polyglot TUI)
# See: https://github.com/hyperpolymath/mustfile

# Default recipe: show available commands.
import? "contractile.just"

default:
    @just --list

# Build the SPARK core and Ada presentation layer.
build-ada:
    gprbuild -P raze_tui.gpr -XMODE=debug -j0

# Build the SPARK core in release mode.
build-ada-release:
    gprbuild -P raze_tui.gpr -XMODE=release -j0

# Build the Zig FFI bridge (links against SPARK exports).
build-zig:
    cd src/interface/ffi && zig build

# Build the Rust consumer.
build-rust:
    cd src/rust && cargo build

# Build everything (SPARK + Zig + Rust).
build: build-ada build-zig build-rust

# Type-check the Idris2 ABI specifications.
check-abi:
    idris2 --check src/interface/abi/State.idr
    idris2 --check src/interface/abi/Events.idr
    idris2 --check src/interface/abi/Widgets.idr

# Run GNATprove on SPARK packages.
prove:
    gnatprove -P raze_tui.gpr -XMODE=spark --level=2 -j0

# Run Zig bridge tests.
test-zig:
    cd src/interface/ffi && zig build test

# Run Rust tests.
test-rust:
    cd src/rust && cargo test

# Run all tests.
test: test-zig test-rust

# Format code (Rust only; Ada/Zig use editorconfig).
fmt:
    cd src/rust && cargo fmt

# Check formatting without modifying
fmt-check:
    cargo fmt --all --check
# Lint Rust code.
lint:
    cd src/rust && cargo clippy -- -D warnings

# Clean all build artifacts.
clean:
    rm -rf obj/ bin/ lib/ proof/
    rm -rf src/interface/ffi/zig-cache src/interface/ffi/zig-out
    cd src/rust && cargo clean 2>/dev/null || true
    rm -rf src/interface/abi/build/

# Run the TUI demo.
run: build-ada
    ./bin/raze_tui_main

# [AUTO-GENERATED] Multi-arch / RISC-V target.
# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# Self-diagnostic — checks dependencies, permissions, paths
doctor:
    @echo "Running diagnostics for raze-tui..."
    @echo "Checking required tools..."
    @command -v just >/dev/null 2>&1 && echo "  [OK] just" || echo "  [FAIL] just not found"
    @command -v git >/dev/null 2>&1 && echo "  [OK] git" || echo "  [FAIL] git not found"
    @echo "Checking for hardcoded paths..."
    @grep -rn '$HOME\|$ECLIPSE_DIR' --include='*.rs' --include='*.ex' --include='*.res' --include='*.gleam' --include='*.sh' . 2>/dev/null | head -5 || echo "  [OK] No hardcoded paths"
    @echo "Diagnostics complete."

# Auto-repair common issues
heal:
    @echo "Attempting auto-repair for raze-tui..."
    @echo "Fixing permissions..."
    @find . -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    @echo "Cleaning stale caches..."
    @rm -rf .cache/stale 2>/dev/null || true
    @echo "Repair complete."

# Guided tour of key features
tour:
    @echo "=== raze-tui Tour ==="
    @echo ""
    @echo "1. Project structure:"
    @ls -la
    @echo ""
    @echo "2. Available commands: just --list"
    @echo ""
    @echo "3. Read README.adoc for full overview"
    @echo "4. Read EXPLAINME.adoc for architecture decisions"
    @echo "5. Run 'just doctor' to check your setup"
    @echo ""
    @echo "Tour complete! Try 'just --list' to see all available commands."

# Open feedback channel with diagnostic context
help-me:
    @echo "=== raze-tui Help ==="
    @echo "Platform: $(uname -s) $(uname -m)"
    @echo "Shell: $SHELL"
    @echo ""
    @echo "To report an issue:"
    @echo "  https://github.com/hyperpolymath/raze-tui/issues/new"
    @echo ""
    @echo "Include the output of 'just doctor' in your report."


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"
