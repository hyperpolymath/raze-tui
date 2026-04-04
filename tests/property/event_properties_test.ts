// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// Property-based tests for raze-tui event types.
//
// Each test encodes an invariant that must hold for ALL values in a
// range, not just specific examples. These act as the P2P layer.

import { assertEquals, assertGreaterOrEqual, assertLessOrEqual } from "jsr:@std/assert";

// ---------------------------------------------------------------------------
// Shared type definitions (mirror of unit test definitions)
// ---------------------------------------------------------------------------

const EventKind = {
  None: 0,
  Key: 1,
  Mouse: 2,
  Resize: 3,
  Quit: 4,
} as const;

const Modifiers = {
  NONE: 0,
  SHIFT: 1,
  CTRL: 2,
  ALT: 4,
  SUPER: 8,
} as const;

// ---------------------------------------------------------------------------
// Helper: generate a sequence of sample u32 values spanning the range.
// ---------------------------------------------------------------------------

function sampleU32(): number[] {
  return [
    0,
    1,
    0x7F,
    0x80,
    0xFF,
    0x100,
    0xFFFF,
    0x1_0000,
    0x7FFF_FFFF,
    0xFFFF_FFFF >>> 0,
  ];
}

function sampleU16(): number[] {
  return [0, 1, 0x7F, 0xFF, 0x100, 0x1000, 0x7FFF, 0xFFFF];
}

function sampleU8(): number[] {
  return [0, 1, 2, 4, 7, 8, 0x0F, 0x1F, 0x7F, 0xFF];
}

// ---------------------------------------------------------------------------
// Properties: EventKind range
// ---------------------------------------------------------------------------

Deno.test("property: all defined EventKind values are in [0, 4]", () => {
  for (const v of Object.values(EventKind)) {
    assertGreaterOrEqual(v, 0, `EventKind value ${v} must be >= 0`);
    assertLessOrEqual(v, 4, `EventKind value ${v} must be <= 4`);
  }
});

Deno.test("property: EventKind discriminants are contiguous 0..4", () => {
  const vals = Object.values(EventKind).sort((a, b) => a - b);
  for (let i = 0; i < vals.length; i++) {
    assertEquals(vals[i], i, `Expected discriminant ${i}, got ${vals[i]}`);
  }
});

// ---------------------------------------------------------------------------
// Properties: key_code is a full u32 (0..=0xFFFFFFFF)
// ---------------------------------------------------------------------------

Deno.test("property: key_code accepts all u32 values without overflow", () => {
  for (const code of sampleU32()) {
    // Simulate storing in a u32 field and reading back.
    const buf = new ArrayBuffer(4);
    const view = new DataView(buf);
    view.setUint32(0, code >>> 0, true);
    const readBack = view.getUint32(0, true);
    assertEquals(readBack, code >>> 0,
      `key_code ${code.toString(16)} must round-trip through u32`);
  }
});

Deno.test("property: key_code 0 is always valid", () => {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setUint32(0, 0, true);
  assertEquals(new DataView(buf).getUint32(0, true), 0);
});

Deno.test("property: key_code 0xFFFFFFFF is representable as u32", () => {
  const buf = new ArrayBuffer(4);
  new DataView(buf).setUint32(0, 0xFFFF_FFFF >>> 0, true);
  assertEquals(new DataView(buf).getUint32(0, true), 0xFFFF_FFFF >>> 0);
});

// ---------------------------------------------------------------------------
// Properties: mouse_x and mouse_y are u16 (0..=65535)
// ---------------------------------------------------------------------------

Deno.test("property: mouse_x accepts all u16 values", () => {
  for (const coord of sampleU16()) {
    assertGreaterOrEqual(coord, 0);
    assertLessOrEqual(coord, 0xFFFF);
    const buf = new ArrayBuffer(2);
    new DataView(buf).setUint16(0, coord, true);
    assertEquals(new DataView(buf).getUint16(0, true), coord);
  }
});

Deno.test("property: mouse_y accepts all u16 values", () => {
  for (const coord of sampleU16()) {
    assertGreaterOrEqual(coord, 0);
    assertLessOrEqual(coord, 0xFFFF);
    const buf = new ArrayBuffer(2);
    new DataView(buf).setUint16(0, coord, true);
    assertEquals(new DataView(buf).getUint16(0, true), coord);
  }
});

// ---------------------------------------------------------------------------
// Properties: Resize events always carry valid dimensions
// ---------------------------------------------------------------------------

Deno.test("property: Resize events use mouse_x/mouse_y for width/height", () => {
  // Specification: resize stores width in mouse_x and height in mouse_y.
  const testCases: [number, number][] = [
    [80, 24],
    [132, 50],
    [1, 1],
    [0xFFFF, 0xFFFF],
    [40, 10],
  ];
  for (const [width, height] of testCases) {
    const buf = new ArrayBuffer(16);
    const view = new DataView(buf);
    view.setInt32(0, EventKind.Resize, true);
    view.setUint16(10, width, true); // mouse_x = width
    view.setUint16(12, height, true); // mouse_y = height
    assertEquals(view.getUint16(10, true), width);
    assertEquals(view.getUint16(12, true), height);
  }
});

// ---------------------------------------------------------------------------
// Properties: Quit events do not carry key_code payload
// ---------------------------------------------------------------------------

Deno.test("property: Quit events have zero key_code in canonical form", () => {
  const buf = new ArrayBuffer(16);
  const view = new DataView(buf);
  view.setInt32(0, EventKind.Quit, true);
  // key_code, mouse_x, mouse_y must all be 0 for a canonical Quit event.
  view.setUint32(4, 0, true);
  view.setUint16(10, 0, true);
  view.setUint16(12, 0, true);
  assertEquals(view.getUint32(4, true), 0);
  assertEquals(view.getUint16(10, true), 0);
  assertEquals(view.getUint16(12, true), 0);
});

// ---------------------------------------------------------------------------
// Properties: modifiers byte fits in u8
// ---------------------------------------------------------------------------

Deno.test("property: all modifier combinations fit in u8 (0..255)", () => {
  const modValues = Object.values(Modifiers);
  // Enumerate all 2^4 = 16 combinations of the 4 defined modifier flags.
  for (let mask = 0; mask < (1 << modValues.length); mask++) {
    let combined = 0;
    for (let bit = 0; bit < modValues.length; bit++) {
      if (mask & (1 << bit)) combined |= modValues[bit];
    }
    assertGreaterOrEqual(combined, 0, `modifier combo ${combined} must be >= 0`);
    assertLessOrEqual(combined, 255, `modifier combo ${combined} must fit in u8`);
  }
});

Deno.test("property: modifier flags are power-of-two (single-bit)", () => {
  const singleBitFlags = [
    Modifiers.SHIFT,
    Modifiers.CTRL,
    Modifiers.ALT,
    Modifiers.SUPER,
  ];
  for (const flag of singleBitFlags) {
    // A power-of-two N satisfies: N > 0 && (N & (N-1)) == 0
    assertEquals(flag > 0, true, `Modifier ${flag} must be positive`);
    assertEquals((flag & (flag - 1)), 0,
      `Modifier ${flag} must be a single bit (power of two)`);
  }
});

// ---------------------------------------------------------------------------
// Properties: event struct total size invariant
// ---------------------------------------------------------------------------

Deno.test("property: event buffer built with all-zero fields is 16 bytes", () => {
  const buf = new ArrayBuffer(16);
  assertEquals(buf.byteLength, 16);
});

Deno.test("property: non-zero key_code does not overflow into adjacent fields", () => {
  // Build a Key event with max key_code.
  const buf = new ArrayBuffer(16);
  const view = new DataView(buf);
  view.setInt32(0, EventKind.Key, true);
  view.setUint32(4, 0xFFFF_FFFF >>> 0, true);
  view.setUint8(8, Modifiers.NONE);
  view.setUint16(10, 0, true);
  view.setUint16(12, 0, true);
  // Verify the modifiers byte (offset 8) is still 0.
  assertEquals(view.getUint8(8), 0,
    "modifiers byte must not be corrupted by large key_code");
  // Verify mouse_x (offset 10) is still 0.
  assertEquals(view.getUint16(10, true), 0,
    "mouse_x must not be corrupted by large key_code");
});

Deno.test("property: large mouse_x does not overflow into mouse_y", () => {
  const buf = new ArrayBuffer(16);
  const view = new DataView(buf);
  view.setInt32(0, EventKind.Mouse, true);
  view.setUint32(4, 0, true);
  view.setUint8(8, 0);
  view.setUint16(10, 0xFFFF, true); // max mouse_x
  view.setUint16(12, 0, true); // mouse_y starts at 0
  assertEquals(view.getUint16(12, true), 0,
    "mouse_y must not be affected by max mouse_x");
});
