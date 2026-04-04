// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// Aspect / security tests for raze-tui.
//
// Tests cover:
//   - Malformed event bytes do not crash the parser.
//   - Boundary key_code values (0, 0xFFFFFFFF) are handled gracefully.
//   - No debug output leaks to the production terminal.
//   - Concurrent-style access patterns do not produce inconsistent state.
//   - Modifier byte with all high bits set is stored without truncation loss.

import { assertEquals, assertNotEquals, assert } from "jsr:@std/assert";

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

const EventKind = {
  None: 0,
  Key: 1,
  Mouse: 2,
  Resize: 3,
  Quit: 4,
} as const;

const EVENT_SIZE = 16;
const OFFSET_KIND = 0;
const OFFSET_KEY_CODE = 4;
const OFFSET_MODIFIERS = 8;
const OFFSET_MOUSE_X = 10;
const OFFSET_MOUSE_Y = 12;

/**
 * A minimal, defensive event parser that mirrors what the Rust consumer
 * would do when receiving raw bytes from the Zig bridge.
 * Returns null if the event kind is not in the known range [0, 4].
 */
function parseEventDefensively(buf: Uint8Array): {
  kind: number;
  key_code: number;
  modifiers: number;
  mouse_x: number;
  mouse_y: number;
} | null {
  if (buf.byteLength < EVENT_SIZE) return null;
  const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  const kind = view.getInt32(OFFSET_KIND, true);
  // Reject unknown event kinds (not in [0, 4]).
  if (kind < 0 || kind > 4) return null;
  return {
    kind,
    key_code: view.getUint32(OFFSET_KEY_CODE, true),
    modifiers: view.getUint8(OFFSET_MODIFIERS),
    mouse_x: view.getUint16(OFFSET_MOUSE_X, true),
    mouse_y: view.getUint16(OFFSET_MOUSE_Y, true),
  };
}

// ---------------------------------------------------------------------------
// Security tests: malformed event bytes
// ---------------------------------------------------------------------------

Deno.test("security: too-short buffer returns null without crash", () => {
  const shortBuf = new Uint8Array(4); // only 4 bytes, need 16
  const result = parseEventDefensively(shortBuf);
  assertEquals(result, null, "Must return null for under-size buffer");
});

Deno.test("security: empty buffer returns null without crash", () => {
  const empty = new Uint8Array(0);
  assertEquals(parseEventDefensively(empty), null);
});

Deno.test("security: all-0xFF buffer with unknown kind returns null", () => {
  const buf = new Uint8Array(16).fill(0xFF);
  // kind field = 0xFFFFFFFF as int32 = -1: must be rejected.
  const result = parseEventDefensively(buf);
  assertEquals(result, null, "All-0xFF buffer has invalid kind, must be null");
});

Deno.test("security: event kind 5 (out of range) is rejected", () => {
  const buf = new Uint8Array(16);
  new DataView(buf.buffer).setInt32(0, 5, true);
  assertEquals(parseEventDefensively(buf), null);
});

Deno.test("security: event kind -1 (negative) is rejected", () => {
  const buf = new Uint8Array(16);
  new DataView(buf.buffer).setInt32(0, -1, true);
  assertEquals(parseEventDefensively(buf), null);
});

Deno.test("security: event kind 0x7FFFFFFF is rejected as out of range", () => {
  const buf = new Uint8Array(16);
  new DataView(buf.buffer).setInt32(0, 0x7FFF_FFFF, true);
  assertEquals(parseEventDefensively(buf), null);
});

// ---------------------------------------------------------------------------
// Security tests: key_code boundary handling
// ---------------------------------------------------------------------------

Deno.test("security: key_code 0xFFFFFFFF is stored and read without crash", () => {
  const buf = new Uint8Array(16);
  const view = new DataView(buf.buffer);
  view.setInt32(0, EventKind.Key, true);
  view.setUint32(4, 0xFFFF_FFFF >>> 0, true);
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null);
  assertEquals(result!.key_code, 0xFFFF_FFFF >>> 0);
});

Deno.test("security: key_code 0 is stored and read without crash", () => {
  const buf = new Uint8Array(16);
  new DataView(buf.buffer).setInt32(0, EventKind.Key, true);
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null);
  assertEquals(result!.key_code, 0);
});

// ---------------------------------------------------------------------------
// Security tests: modifier byte with high bits set
// ---------------------------------------------------------------------------

Deno.test("security: modifier byte 0xFF is stored and read as u8 without truncation", () => {
  const buf = new Uint8Array(16);
  const view = new DataView(buf.buffer);
  view.setInt32(0, EventKind.Key, true);
  view.setUint8(8, 0xFF);
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null);
  assertEquals(result!.modifiers, 0xFF,
    "All modifier bits must be preserved (u8 field, no truncation)");
});

Deno.test("security: modifier byte 0b11110000 (unknown high bits) preserved", () => {
  const buf = new Uint8Array(16);
  const view = new DataView(buf.buffer);
  view.setInt32(0, EventKind.Key, true);
  view.setUint8(8, 0b1111_0000);
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null);
  assertEquals(result!.modifiers, 0b1111_0000);
});

// ---------------------------------------------------------------------------
// Security tests: no debug output to terminal
// ---------------------------------------------------------------------------

Deno.test("security: no console.log calls in parser (no production debug leakage)", () => {
  // Capture console output during a parse call.
  const logged: unknown[] = [];
  const originalLog = console.log;
  console.log = (...args: unknown[]) => { logged.push(args); };
  try {
    const buf = new Uint8Array(16);
    new DataView(buf.buffer).setInt32(0, EventKind.Key, true);
    parseEventDefensively(buf);
  } finally {
    console.log = originalLog;
  }
  assertEquals(logged.length, 0,
    "parseEventDefensively must not call console.log (no debug leakage)");
});

Deno.test("security: malformed input does not call console.error", () => {
  const errors: unknown[] = [];
  const originalError = console.error;
  console.error = (...args: unknown[]) => { errors.push(args); };
  try {
    const buf = new Uint8Array(16).fill(0xFF);
    parseEventDefensively(buf);
  } finally {
    console.error = originalError;
  }
  assertEquals(errors.length, 0,
    "parseEventDefensively must not call console.error on malformed input");
});

// ---------------------------------------------------------------------------
// Security tests: concurrent-style access (no shared mutable state)
// ---------------------------------------------------------------------------

Deno.test("security: two independent parsers on same buffer return equal results", () => {
  const buf = new Uint8Array(16);
  const view = new DataView(buf.buffer);
  view.setInt32(0, EventKind.Mouse, true);
  view.setUint16(10, 50, true);
  view.setUint16(12, 25, true);

  // Simulating concurrent reads: both parsers see the same data.
  const r1 = parseEventDefensively(buf);
  const r2 = parseEventDefensively(buf);
  assertNotEquals(r1, null);
  assertNotEquals(r2, null);
  assertEquals(r1!.kind, r2!.kind);
  assertEquals(r1!.mouse_x, r2!.mouse_x);
  assertEquals(r1!.mouse_y, r2!.mouse_y);
});

Deno.test("security: parsing different buffers independently does not cross-contaminate", () => {
  const buf1 = new Uint8Array(16);
  const buf2 = new Uint8Array(16);
  new DataView(buf1.buffer).setInt32(0, EventKind.Key, true);
  new DataView(buf1.buffer).setUint32(4, 0xABCD, true);
  new DataView(buf2.buffer).setInt32(0, EventKind.Mouse, true);
  new DataView(buf2.buffer).setUint16(10, 99, true);

  const r1 = parseEventDefensively(buf1);
  const r2 = parseEventDefensively(buf2);
  assertNotEquals(r1, null);
  assertNotEquals(r2, null);
  assertEquals(r1!.kind, EventKind.Key);
  assertEquals(r2!.kind, EventKind.Mouse);
  assertEquals(r1!.key_code, 0xABCD);
  assertEquals(r2!.mouse_x, 99);
  // Cross-contamination check: r1 mouse_x must not be r2's value.
  assertNotEquals(r1!.mouse_x, 99);
});

// ---------------------------------------------------------------------------
// Security tests: valid range boundary checks
// ---------------------------------------------------------------------------

Deno.test("security: EventKind.None (0) is accepted as valid", () => {
  const buf = new Uint8Array(16);
  // All zeros = kind: 0 (None), all fields 0.
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null, "EventKind.None (0) must be a valid event");
  assertEquals(result!.kind, EventKind.None);
});

Deno.test("security: EventKind.Quit (4) is accepted as valid", () => {
  const buf = new Uint8Array(16);
  new DataView(buf.buffer).setInt32(0, EventKind.Quit, true);
  const result = parseEventDefensively(buf);
  assertNotEquals(result, null);
  assertEquals(result!.kind, EventKind.Quit);
});
