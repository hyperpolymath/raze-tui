# SPDX-License-Identifier: PMPL-1.0-or-later
# justfile -- Build recipes for RAZE-TUI (5-language polyglot TUI)
# See: https://github.com/hyperpolymath/mustfile

# Default recipe: show available commands.
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
build-riscv:
    @echo "Building for RISC-V..."
    cd src/rust && cross build --target riscv64gc-unknown-linux-gnu
