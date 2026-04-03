// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// RAZE-TUI Zig FFI Bridge — Build Configuration
//
// Builds the pure pass-through FFI bridge that connects
// SPARK C ABI exports to Rust-consumable C ABI symbols.
// The bridge library contains ZERO logic — only extern fn forwarding.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ---------------------------------------------------------------------------
    // Static library (primary artifact, linked by Rust and Ada)
    // ---------------------------------------------------------------------------
    const lib = b.addStaticLibrary(.{
        .name = "raze_bridge",
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link against SPARK exports library (produced by gprbuild)
    lib.addLibraryPath(.{ .cwd_relative = "../../spark/lib" });
    lib.linkSystemLibrary("raze_spark");
    lib.linkLibC();

    b.installArtifact(lib);

    // ---------------------------------------------------------------------------
    // Shared library variant (for dynamic linking scenarios)
    // ---------------------------------------------------------------------------
    const shared = b.addSharedLibrary(.{
        .name = "raze_bridge",
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    shared.addLibraryPath(.{ .cwd_relative = "../../spark/lib" });
    shared.linkSystemLibrary("raze_spark");
    shared.linkLibC();

    const shared_step = b.step("shared", "Build shared library");
    shared_step.dependOn(&b.addInstallArtifact(shared, .{}).step);

    // ---------------------------------------------------------------------------
    // Unit tests
    // ---------------------------------------------------------------------------
    const tests = b.addTest(.{
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
