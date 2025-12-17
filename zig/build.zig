// SPDX-License-Identifier: AGPL-3.0-or-later
//! RAZE-TUI Zig Bridge build configuration
//!
//! Builds the FFI bridge between Rust core and Ada TUI.

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Static library for Ada linking
    const lib = b.addStaticLibrary(.{
        .name = "raze_bridge",
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link against Rust core library
    lib.addLibraryPath(.{ .cwd_relative = "../rust/target/release" });
    lib.linkSystemLibrary("raze_core");
    lib.linkLibC();

    b.installArtifact(lib);

    // Shared library variant
    const shared = b.addSharedLibrary(.{
        .name = "raze_bridge",
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    shared.addLibraryPath(.{ .cwd_relative = "../rust/target/release" });
    shared.linkSystemLibrary("raze_core");
    shared.linkLibC();

    const shared_step = b.step("shared", "Build shared library");
    shared_step.dependOn(&b.addInstallArtifact(shared, .{}).step);

    // Generate C header for Ada bindings
    const header_step = b.step("header", "Generate C header");
    _ = header_step;
    // TODO: Generate header from exported symbols

    // Unit tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/bridge.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
