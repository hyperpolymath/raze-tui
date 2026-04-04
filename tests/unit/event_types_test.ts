// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// Unit tests for raze-tui event types and C ABI layout contracts.
//
// These tests specify the canonical type definitions for EventKind,
// RazeEvent, modifier flags, and WidgetKind — matching the SPARK ABI
// (`raze-events.ads`) and the Rust public types in `src/rust/src/lib.rs`.

import { assertEquals, assertNotEquals } from "jsr:@std/assert";

// ---------------------------------------------------------------------------
// EventKind enum: canonical C ABI values
// ---------------------------------------------------------------------------

/** Maps the EventKind enum to its C ABI integer representation. */
const EventKind = {
  None: 0,
  Key: 1,
  Mouse: 2,
  Resize: 3,
  Quit: 4,
} as const;

type EventKindValue = (typeof EventKind)[keyof typeof EventKind];

// ---------------------------------------------------------------------------
// Modifier bit flags (matching SPARK Mod_* and Rust modifiers::*)
// ---------------------------------------------------------------------------

const Modifiers = {
  NONE: 0,
  SHIFT: 1,
  CTRL: 2,
  ALT: 4,
  SUPER: 8,
} as const;

// ---------------------------------------------------------------------------
// WidgetKind enum (matching Idris2 widgetKindToNat ABI)
// ---------------------------------------------------------------------------

const WidgetKind = {
  None: 0,
  Label: 1,
  Input: 2,
  Button: 3,
  Panel: 4,
  List: 5,
} as const;

// ---------------------------------------------------------------------------
// RazeEvent layout: 16 bytes with defined field offsets.
//
// C ABI layout (from Events.idr and raze-events.ads):
//   kind      : offset  0, size 4 (int32_t)
//   key_code  : offset  4, size 4 (uint32_t)
//   modifiers : offset  8, size 1 (uint8_t)
//   _pad      : offset  9, size 1 (reserved, 0)
//   mouse_x   : offset 10, size 2 (uint16_t)
//   mouse_y   : offset 12, size 2 (uint16_t)
//   _pad2     : offset 14, size 2 (reserved, 0)
//   Total: 16 bytes
// ---------------------------------------------------------------------------

const EVENT_SIZE_BYTES = 16;

/** Field byte offsets within the 16-byte RazeEvent record. */
const FieldOffset = {
  kind: 0,
  key_code: 4,
  modifiers: 8,
  _pad: 9,
  mouse_x: 10,
  mouse_y: 12,
  _pad2: 14,
} as const;

/** Field sizes in bytes. */
const FieldSize = {
  kind: 4,
  key_code: 4,
  modifiers: 1,
  _pad: 1,
  mouse_x: 2,
  mouse_y: 2,
  _pad2: 2,
} as const;

// ---------------------------------------------------------------------------
// Helper: Build a 16-byte event buffer from field values.
// ---------------------------------------------------------------------------

function buildEvent(
  kind: EventKindValue,
  key_code: number,
  modifiers: number,
  mouse_x: number,
  mouse_y: number,
): Uint8Array {
  const buf = new ArrayBuffer(EVENT_SIZE_BYTES);
  const view = new DataView(buf);
  view.setInt32(FieldOffset.kind, kind, true); // little-endian
  view.setUint32(FieldOffset.key_code, key_code >>> 0, true);
  view.setUint8(FieldOffset.modifiers, modifiers & 0xFF);
  view.setUint8(FieldOffset._pad, 0);
  view.setUint16(FieldOffset.mouse_x, mouse_x & 0xFFFF, true);
  view.setUint16(FieldOffset.mouse_y, mouse_y & 0xFFFF, true);
  view.setUint16(FieldOffset._pad2, 0, true);
  return new Uint8Array(buf);
}

function parseEvent(buf: Uint8Array): {
  kind: number;
  key_code: number;
  modifiers: number;
  mouse_x: number;
  mouse_y: number;
} {
  const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  return {
    kind: view.getInt32(FieldOffset.kind, true),
    key_code: view.getUint32(FieldOffset.key_code, true),
    modifiers: view.getUint8(FieldOffset.modifiers),
    mouse_x: view.getUint16(FieldOffset.mouse_x, true),
    mouse_y: view.getUint16(FieldOffset.mouse_y, true),
  };
}

// ---------------------------------------------------------------------------
// Tests: EventKind discriminant values
// ---------------------------------------------------------------------------

Deno.test("EventKind.None == 0 (C ABI)", () => {
  assertEquals(EventKind.None, 0);
});

Deno.test("EventKind.Key == 1 (C ABI)", () => {
  assertEquals(EventKind.Key, 1);
});

Deno.test("EventKind.Mouse == 2 (C ABI)", () => {
  assertEquals(EventKind.Mouse, 2);
});

Deno.test("EventKind.Resize == 3 (C ABI)", () => {
  assertEquals(EventKind.Resize, 3);
});

Deno.test("EventKind.Quit == 4 (C ABI)", () => {
  assertEquals(EventKind.Quit, 4);
});

Deno.test("all EventKind values are in [0, 4]", () => {
  for (const v of Object.values(EventKind)) {
    assertEquals(v >= 0 && v <= 4, true, `EventKind value ${v} out of range`);
  }
});

Deno.test("EventKind variants are mutually distinct", () => {
  const vals = Object.values(EventKind);
  const unique = new Set(vals);
  assertEquals(unique.size, vals.length, "EventKind values must be unique");
});

// ---------------------------------------------------------------------------
// Tests: RazeEvent layout (16 bytes, correct field offsets)
// ---------------------------------------------------------------------------

Deno.test("RazeEvent total size is 16 bytes", () => {
  const buf = buildEvent(EventKind.None, 0, 0, 0, 0);
  assertEquals(buf.byteLength, 16);
});

Deno.test("RazeEvent kind field at offset 0, size 4", () => {
  assertEquals(FieldOffset.kind, 0);
  assertEquals(FieldSize.kind, 4);
});

Deno.test("RazeEvent key_code field at offset 4, size 4", () => {
  assertEquals(FieldOffset.key_code, 4);
  assertEquals(FieldSize.key_code, 4);
});

Deno.test("RazeEvent modifiers field at offset 8, size 1", () => {
  assertEquals(FieldOffset.modifiers, 8);
  assertEquals(FieldSize.modifiers, 1);
});

Deno.test("RazeEvent mouse_x field at offset 10, size 2", () => {
  assertEquals(FieldOffset.mouse_x, 10);
  assertEquals(FieldSize.mouse_x, 2);
});

Deno.test("RazeEvent mouse_y field at offset 12, size 2", () => {
  assertEquals(FieldOffset.mouse_y, 12);
  assertEquals(FieldSize.mouse_y, 2);
});

Deno.test("RazeEvent field layout sums to 16 bytes", () => {
  const total = Object.values(FieldSize).reduce((a, b) => a + b, 0);
  assertEquals(total, 16);
});

// ---------------------------------------------------------------------------
// Tests: Event kind discrimination via binary layout
// ---------------------------------------------------------------------------

Deno.test("Key event: kind field reads back as EventKind.Key", () => {
  const buf = buildEvent(EventKind.Key, 0x61, Modifiers.NONE, 0, 0);
  const e = parseEvent(buf);
  assertEquals(e.kind, EventKind.Key);
  assertEquals(e.key_code, 0x61);
});

Deno.test("Mouse event: kind field reads back as EventKind.Mouse", () => {
  const buf = buildEvent(EventKind.Mouse, 0, Modifiers.NONE, 80, 24);
  const e = parseEvent(buf);
  assertEquals(e.kind, EventKind.Mouse);
  assertEquals(e.mouse_x, 80);
  assertEquals(e.mouse_y, 24);
});

Deno.test("Resize event: dimensions stored in mouse_x / mouse_y", () => {
  const buf = buildEvent(EventKind.Resize, 0, 0, 132, 50);
  const e = parseEvent(buf);
  assertEquals(e.kind, EventKind.Resize);
  assertEquals(e.mouse_x, 132);
  assertEquals(e.mouse_y, 50);
});

Deno.test("Quit event: key_code and mouse fields are zero", () => {
  const buf = buildEvent(EventKind.Quit, 0, 0, 0, 0);
  const e = parseEvent(buf);
  assertEquals(e.kind, EventKind.Quit);
  assertEquals(e.key_code, 0);
  assertEquals(e.mouse_x, 0);
  assertEquals(e.mouse_y, 0);
});

// ---------------------------------------------------------------------------
// Tests: modifier flags
// ---------------------------------------------------------------------------

Deno.test("Modifier.SHIFT is bit 0 (value 1)", () => {
  assertEquals(Modifiers.SHIFT, 1);
});

Deno.test("Modifier.CTRL is bit 1 (value 2)", () => {
  assertEquals(Modifiers.CTRL, 2);
});

Deno.test("Modifier.ALT is bit 2 (value 4)", () => {
  assertEquals(Modifiers.ALT, 4);
});

Deno.test("Modifier.SUPER is bit 3 (value 8)", () => {
  assertEquals(Modifiers.SUPER, 8);
});

Deno.test("modifier flags are mutually exclusive bits", () => {
  assertEquals(Modifiers.SHIFT & Modifiers.CTRL, 0);
  assertEquals(Modifiers.CTRL & Modifiers.ALT, 0);
  assertEquals(Modifiers.SHIFT & Modifiers.ALT, 0);
  assertEquals(Modifiers.SUPER & Modifiers.SHIFT, 0);
});

Deno.test("all modifier flags combined fit in u8", () => {
  const all = Modifiers.SHIFT | Modifiers.CTRL | Modifiers.ALT | Modifiers.SUPER;
  assertEquals(all <= 255, true, `Combined modifiers ${all} must fit in u8`);
});

Deno.test("Ctrl+Shift combination: both bits set", () => {
  const mods = Modifiers.CTRL | Modifiers.SHIFT;
  assertEquals((mods & Modifiers.CTRL) !== 0, true);
  assertEquals((mods & Modifiers.SHIFT) !== 0, true);
  assertEquals((mods & Modifiers.ALT) !== 0, false);
});

// ---------------------------------------------------------------------------
// Tests: WidgetKind discriminants
// ---------------------------------------------------------------------------

Deno.test("WidgetKind.None == 0", () => assertEquals(WidgetKind.None, 0));
Deno.test("WidgetKind.Label == 1", () => assertEquals(WidgetKind.Label, 1));
Deno.test("WidgetKind.Input == 2", () => assertEquals(WidgetKind.Input, 2));
Deno.test("WidgetKind.Button == 3", () => assertEquals(WidgetKind.Button, 3));
Deno.test("WidgetKind.Panel == 4", () => assertEquals(WidgetKind.Panel, 4));
Deno.test("WidgetKind.List == 5", () => assertEquals(WidgetKind.List, 5));

Deno.test("WidgetKind has exactly 6 variants", () => {
  assertEquals(Object.keys(WidgetKind).length, 6);
});

Deno.test("WidgetKind values are mutually distinct", () => {
  const vals = Object.values(WidgetKind);
  const unique = new Set(vals);
  assertEquals(unique.size, vals.length);
});
