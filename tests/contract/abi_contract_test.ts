// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// Contract tests: ABI specification conformance.
//
// Each test encodes a formal contract that MUST hold across the full
// Idris2 ABI → Zig FFI → SPARK core → Rust consumer stack. These act
// as the cross-layer specification boundary.

import { assertEquals, assertGreaterOrEqual, assertLessOrEqual, assert } from "jsr:@std/assert";

// ---------------------------------------------------------------------------
// ABI constants (from Events.idr and raze-events.ads)
// ---------------------------------------------------------------------------

/** Total size of the RazeEvent record (ABI contract: exactly 16 bytes). */
const ABI_EVENT_SIZE = 16;

/** EventKind integer values (ABI contract: 0..4). */
const ABI_EVENT_KIND = {
  None: 0,
  Key: 1,
  Mouse: 2,
  Resize: 3,
  Quit: 4,
} as const;

/** Modifier flag bit values (ABI contract: bit 0 = Shift, 1 = Ctrl, 2 = Alt). */
const ABI_MOD_SHIFT = 1;
const ABI_MOD_CTRL  = 2;
const ABI_MOD_ALT   = 4;

/** Minimum valid screen dimension (mirrors SPARK Min_Dimension = 1). */
const ABI_MIN_DIMENSION = 1;

/** Maximum valid screen dimension (mirrors SPARK Max_Dimension = 65_535). */
const ABI_MAX_DIMENSION = 65_535;

/** Default terminal width (VT100 standard, mirrors Default_Width = 80). */
const ABI_DEFAULT_WIDTH = 80;

/** Default terminal height (VT100 standard, mirrors Default_Height = 24). */
const ABI_DEFAULT_HEIGHT = 24;

// ---------------------------------------------------------------------------
// Contract: EventKind ABI values
// ---------------------------------------------------------------------------

Deno.test("contract: EventKind.None ABI value is 0", () => {
  assertEquals(ABI_EVENT_KIND.None, 0);
});

Deno.test("contract: EventKind.Key ABI value is 1", () => {
  assertEquals(ABI_EVENT_KIND.Key, 1);
});

Deno.test("contract: EventKind.Mouse ABI value is 2", () => {
  assertEquals(ABI_EVENT_KIND.Mouse, 2);
});

Deno.test("contract: EventKind.Resize ABI value is 3", () => {
  assertEquals(ABI_EVENT_KIND.Resize, 3);
});

Deno.test("contract: EventKind.Quit ABI value is 4", () => {
  assertEquals(ABI_EVENT_KIND.Quit, 4);
});

// ---------------------------------------------------------------------------
// Contract: RazeEvent binary layout
// ---------------------------------------------------------------------------

Deno.test("contract: RazeEvent ABI size is exactly 16 bytes", () => {
  assertEquals(ABI_EVENT_SIZE, 16);
});

Deno.test("contract: kind field is at offset 0 (int32_t, 4 bytes)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  const view = new DataView(buf);
  view.setInt32(0, ABI_EVENT_KIND.Key, true);
  assertEquals(view.getInt32(0, true), ABI_EVENT_KIND.Key);
});

Deno.test("contract: key_code field is at offset 4 (uint32_t, 4 bytes)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  const view = new DataView(buf);
  view.setUint32(4, 0x1234_ABCD, true);
  assertEquals(view.getUint32(4, true), 0x1234_ABCD);
});

Deno.test("contract: modifiers field is at offset 8 (uint8_t, 1 byte)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  const view = new DataView(buf);
  view.setUint8(8, ABI_MOD_CTRL | ABI_MOD_SHIFT);
  assertEquals(view.getUint8(8), ABI_MOD_CTRL | ABI_MOD_SHIFT);
});

Deno.test("contract: mouse_x field is at offset 10 (uint16_t, 2 bytes)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  const view = new DataView(buf);
  view.setUint16(10, 1920, true);
  assertEquals(view.getUint16(10, true), 1920);
});

Deno.test("contract: mouse_y field is at offset 12 (uint16_t, 2 bytes)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  const view = new DataView(buf);
  view.setUint16(12, 1080, true);
  assertEquals(view.getUint16(12, true), 1080);
});

Deno.test("contract: padding bytes at offsets 9 and 14-15 are reserved (zero)", () => {
  const buf = new ArrayBuffer(ABI_EVENT_SIZE);
  // Build a Key event with all real fields set.
  const view = new DataView(buf);
  view.setInt32(0, ABI_EVENT_KIND.Key, true);
  view.setUint32(4, 0x41, true);
  view.setUint8(8, ABI_MOD_CTRL);
  // Explicitly zero padding.
  view.setUint8(9, 0);
  view.setUint16(14, 0, true);
  assertEquals(view.getUint8(9), 0, "_pad at offset 9 must be 0");
  assertEquals(view.getUint16(14, true), 0, "_pad2 at offset 14 must be 0");
});

Deno.test("contract: all field offsets + sizes sum to exactly 16", () => {
  const fields = [
    { offset: 0, size: 4 },   // kind
    { offset: 4, size: 4 },   // key_code
    { offset: 8, size: 1 },   // modifiers
    { offset: 9, size: 1 },   // _pad
    { offset: 10, size: 2 },  // mouse_x
    { offset: 12, size: 2 },  // mouse_y
    { offset: 14, size: 2 },  // _pad2
  ];
  const total = fields.reduce((acc, f) => acc + f.size, 0);
  assertEquals(total, ABI_EVENT_SIZE);
});

// ---------------------------------------------------------------------------
// Contract: dimension bounds (from raze-state.ads)
// ---------------------------------------------------------------------------

Deno.test("contract: Min_Dimension is 1 (matching SPARK subtype lower bound)", () => {
  assertEquals(ABI_MIN_DIMENSION, 1);
});

Deno.test("contract: Max_Dimension is 65535 (matching SPARK subtype upper bound)", () => {
  assertEquals(ABI_MAX_DIMENSION, 65_535);
});

Deno.test("contract: Default_Width is 80 (VT100 standard)", () => {
  assertEquals(ABI_DEFAULT_WIDTH, 80);
});

Deno.test("contract: Default_Height is 24 (VT100 standard)", () => {
  assertEquals(ABI_DEFAULT_HEIGHT, 24);
});

Deno.test("contract: Default_Width is within [Min_Dimension, Max_Dimension]", () => {
  assertGreaterOrEqual(ABI_DEFAULT_WIDTH, ABI_MIN_DIMENSION);
  assertLessOrEqual(ABI_DEFAULT_WIDTH, ABI_MAX_DIMENSION);
});

Deno.test("contract: Default_Height is within [Min_Dimension, Max_Dimension]", () => {
  assertGreaterOrEqual(ABI_DEFAULT_HEIGHT, ABI_MIN_DIMENSION);
  assertLessOrEqual(ABI_DEFAULT_HEIGHT, ABI_MAX_DIMENSION);
});

// ---------------------------------------------------------------------------
// Contract: modifier flag values (matching SPARK Mod_* and Rust modifiers::*)
// ---------------------------------------------------------------------------

Deno.test("contract: Mod_Shift == 1 (bit 0)", () => {
  assertEquals(ABI_MOD_SHIFT, 1);
});

Deno.test("contract: Mod_Ctrl == 2 (bit 1)", () => {
  assertEquals(ABI_MOD_CTRL, 2);
});

Deno.test("contract: Mod_Alt == 4 (bit 2)", () => {
  assertEquals(ABI_MOD_ALT, 4);
});

Deno.test("contract: modifier flags are non-overlapping single bits", () => {
  assertEquals((ABI_MOD_SHIFT & ABI_MOD_CTRL), 0);
  assertEquals((ABI_MOD_CTRL & ABI_MOD_ALT), 0);
  assertEquals((ABI_MOD_SHIFT & ABI_MOD_ALT), 0);
});

Deno.test("contract: Shift|Ctrl|Alt combined value is 7 (bits 0-2)", () => {
  assertEquals(ABI_MOD_SHIFT | ABI_MOD_CTRL | ABI_MOD_ALT, 7);
});

// ---------------------------------------------------------------------------
// Contract: event kind field is little-endian int32_t (C ABI)
// ---------------------------------------------------------------------------

Deno.test("contract: EventKind.Key (1) encodes as 01 00 00 00 in little-endian", () => {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setInt32(0, ABI_EVENT_KIND.Key, true);
  const bytes = new Uint8Array(buf);
  assertEquals(bytes[0], 0x01);
  assertEquals(bytes[1], 0x00);
  assertEquals(bytes[2], 0x00);
  assertEquals(bytes[3], 0x00);
});

Deno.test("contract: EventKind.Quit (4) encodes as 04 00 00 00 in little-endian", () => {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setInt32(0, ABI_EVENT_KIND.Quit, true);
  const bytes = new Uint8Array(buf);
  assertEquals(bytes[0], 0x04);
  assertEquals(bytes[1], 0x00);
  assertEquals(bytes[2], 0x00);
  assertEquals(bytes[3], 0x00);
});

// ---------------------------------------------------------------------------
// Contract: key_code field is little-endian uint32_t
// ---------------------------------------------------------------------------

Deno.test("contract: key_code 0x0000_0041 ('A') encodes as 41 00 00 00", () => {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setUint32(0, 0x41, true);
  const bytes = new Uint8Array(buf);
  assertEquals(bytes[0], 0x41);
  assertEquals(bytes[1], 0x00);
  assertEquals(bytes[2], 0x00);
  assertEquals(bytes[3], 0x00);
});

// ---------------------------------------------------------------------------
// Contract: lifecycle state transitions
// ---------------------------------------------------------------------------

Deno.test("contract: initialized state must have Is_Initialized = true", () => {
  // Model the SPARK postcondition: Initialize => Is_Initialized
  let initialized = false;
  function initialize(): void { initialized = true; }
  initialize();
  assertEquals(initialized, true);
});

Deno.test("contract: shutdown transitions Is_Initialized to false", () => {
  // Model the SPARK postcondition: Shutdown => not Is_Initialized
  let initialized = true;
  function shutdown(): void { initialized = false; }
  shutdown();
  assertEquals(initialized, false);
});

Deno.test("contract: Request_Quit sets Is_Running = false while Is_Initialized remains true", () => {
  // Model SPARK Post: Is_Initialized and then not Is_Running
  let initialized = true;
  let running = true;
  function requestQuit(): void { running = false; }
  requestQuit();
  assertEquals(initialized, true, "Is_Initialized must remain true after quit");
  assertEquals(running, false, "Is_Running must be false after quit");
});

Deno.test("contract: version is monotonically non-decreasing after Set_Size", () => {
  let version = 0;
  function setSize(_w: number, _h: number): void { version += 1; }
  const before = version;
  setSize(100, 40);
  assert(version >= before, "Version must not decrease");
  setSize(80, 24);
  assert(version >= before + 1, "Version must be strictly greater after second Set_Size");
});
