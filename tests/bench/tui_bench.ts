// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// Benchmarks for raze-tui event processing pipeline.
//
// Baselines are established for:
//   - Event buffer construction (16-byte struct fill)
//   - Event deserialization throughput (parse 16-byte ABI struct)
//   - Event kind dispatch speed (switch on kind discriminant)
//   - Modifier flag extraction (bit operations on u8)
//   - Widget layout computation (dimension arithmetic)
//   - Input buffer batch processing (N events per iteration)

// ---------------------------------------------------------------------------
// Shared constants
// ---------------------------------------------------------------------------

const EventKind = {
  None: 0,
  Key: 1,
  Mouse: 2,
  Resize: 3,
  Quit: 4,
} as const;

const EVENT_SIZE = 16;
const BATCH_SIZE = 1_000;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Build a 16-byte Key event buffer.
 * Hot path: called once per benchmark iteration in batches.
 */
function buildKeyEvent(code: number, mods: number): ArrayBuffer {
  const buf = new ArrayBuffer(EVENT_SIZE);
  const v = new DataView(buf);
  v.setInt32(0, EventKind.Key, true);
  v.setUint32(4, code >>> 0, true);
  v.setUint8(8, mods & 0xFF);
  v.setUint8(9, 0);
  v.setUint16(10, 0, true);
  v.setUint16(12, 0, true);
  v.setUint16(14, 0, true);
  return buf;
}

/**
 * Deserialize a 16-byte event buffer into component fields.
 */
function parseEvent(buf: ArrayBuffer): {
  kind: number;
  key_code: number;
  modifiers: number;
  mouse_x: number;
  mouse_y: number;
} {
  const v = new DataView(buf);
  return {
    kind: v.getInt32(0, true),
    key_code: v.getUint32(4, true),
    modifiers: v.getUint8(8),
    mouse_x: v.getUint16(10, true),
    mouse_y: v.getUint16(12, true),
  };
}

/**
 * Dispatch on event kind, returning a string handler name.
 * Models the Rust match arm or SPARK case statement.
 */
function dispatchKind(kind: number): string {
  switch (kind) {
    case EventKind.Key:    return "handle_key";
    case EventKind.Mouse:  return "handle_mouse";
    case EventKind.Resize: return "handle_resize";
    case EventKind.Quit:   return "handle_quit";
    default:               return "handle_none";
  }
}

/**
 * Extract modifier flags from a u8 modifier byte.
 */
function extractModifiers(mods: number): {
  shift: boolean;
  ctrl: boolean;
  alt: boolean;
  super_key: boolean;
} {
  return {
    shift: (mods & 1) !== 0,
    ctrl:  (mods & 2) !== 0,
    alt:   (mods & 4) !== 0,
    super_key: (mods & 8) !== 0,
  };
}

/**
 * Compute layout for a widget given terminal dimensions.
 * Models the resize event → layout recalculation path.
 */
function computeLayout(width: number, height: number, widgetCount: number): {
  cols: number;
  rows: number;
  cellWidth: number;
  cellHeight: number;
} {
  const cols = Math.max(1, Math.floor(Math.sqrt(widgetCount)));
  const rows = Math.max(1, Math.ceil(widgetCount / cols));
  return {
    cols,
    rows,
    cellWidth: Math.floor(width / cols),
    cellHeight: Math.floor(height / rows),
  };
}

// ---------------------------------------------------------------------------
// Benchmarks
// ---------------------------------------------------------------------------

Deno.bench("event buffer construction: build 1 Key event (16 bytes)", () => {
  buildKeyEvent(0x61, 0x02);
});

Deno.bench(`event buffer construction: build ${BATCH_SIZE} Key events`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    buildKeyEvent(i & 0xFF, i & 0x0F);
  }
});

Deno.bench("event deserialization: parse 1 Key event", () => {
  const buf = buildKeyEvent(0x41, 0x00);
  parseEvent(buf);
});

Deno.bench(`event deserialization: parse ${BATCH_SIZE} events`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    const buf = buildKeyEvent(i & 0x7F, i & 0x0F);
    parseEvent(buf);
  }
});

Deno.bench("event kind dispatch: switch on Key kind", () => {
  dispatchKind(EventKind.Key);
});

Deno.bench("event kind dispatch: switch on all 5 kinds (round-robin)", () => {
  for (let i = 0; i <= 4; i++) {
    dispatchKind(i);
  }
});

Deno.bench(`event kind dispatch: ${BATCH_SIZE} events round-robin`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    dispatchKind(i % 5);
  }
});

Deno.bench("modifier extraction: all 3 flags set (0x07)", () => {
  extractModifiers(0x07);
});

Deno.bench(`modifier extraction: ${BATCH_SIZE} random modifier bytes`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    extractModifiers(i & 0xFF);
  }
});

Deno.bench("widget layout: compute 1 layout (80×24, 6 widgets)", () => {
  computeLayout(80, 24, 6);
});

Deno.bench(`widget layout: ${BATCH_SIZE} resize → layout recalculations`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    computeLayout(80 + (i % 120), 24 + (i % 40), 6);
  }
});

Deno.bench(`input buffer processing: build + parse + dispatch ${BATCH_SIZE} events`, () => {
  for (let i = 0; i < BATCH_SIZE; i++) {
    const kind = i % 5;
    const buf = new ArrayBuffer(EVENT_SIZE);
    const v = new DataView(buf);
    v.setInt32(0, kind, true);
    v.setUint32(4, i >>> 0, true);
    v.setUint8(8, i & 0x0F);
    v.setUint16(10, i & 0xFFFF, true);
    v.setUint16(12, (i >> 8) & 0xFFFF, true);
    const e = parseEvent(buf);
    dispatchKind(e.kind);
    extractModifiers(e.modifiers);
  }
});
