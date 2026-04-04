// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// E2E tests: TUI lifecycle state machine and event dispatch.
//
// The Zig bridge is NOT available in this test environment, so these tests
// use a pure-TypeScript simulation of the TUI state machine that mirrors
// the contracts defined in `raze-state.ads` and `raze-events.ads`.
//
// This exercises the state machine contract layer (init → running →
// event-dispatch → shutdown) without invoking any FFI.

import {
  assertEquals,
  assertNotEquals,
  assert,
} from "jsr:@std/assert";

// ---------------------------------------------------------------------------
// Pure-TypeScript TUI state machine (mirrors SPARK raze-state.ads contracts)
// ---------------------------------------------------------------------------

/** TUI lifecycle phases (mirrors SPARK phase transitions). */
const Phase = {
  Uninit: "Uninit",
  Running: "Running",
  Stopped: "Stopped",
} as const;

type PhaseValue = (typeof Phase)[keyof typeof Phase];

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
} as const;

/** Simulated TUI event (matches RazeEvent C ABI layout). */
interface TuiEvent {
  kind: number;
  key_code: number;
  modifiers: number;
  mouse_x: number;
  mouse_y: number;
}

/** Simulated TUI state (mirrors Raze.State internal state). */
interface TuiState {
  phase: PhaseValue;
  width: number;
  height: number;
  version: number;
  running: boolean;
}

/**
 * Simulated TUI system — a pure TypeScript model of the SPARK/Zig/Rust
 * stack, exercising the state machine contracts.
 */
class TuiSystem {
  private state: TuiState = {
    phase: Phase.Uninit,
    width: 80,
    height: 24,
    version: 0,
    running: false,
  };

  private eventQueue: TuiEvent[] = [];
  private focusIndex = 0;
  private widgetCount = 0;

  // -- Lifecycle -----------------------------------------------------------

  /** Initialize the TUI system (Uninit → Running). */
  initialize(): void {
    if (this.state.phase !== Phase.Uninit) {
      throw new Error("initialize() called on non-Uninit TUI");
    }
    this.state.phase = Phase.Running;
    this.state.running = true;
    this.state.width = 80;
    this.state.height = 24;
    this.state.version = 0;
  }

  /** Shut down the TUI system (Running → Stopped). */
  shutdown(): void {
    if (this.state.phase !== Phase.Running) {
      throw new Error("shutdown() called on non-Running TUI");
    }
    this.state.phase = Phase.Stopped;
    this.state.running = false;
  }

  isInitialized(): boolean {
    return this.state.phase === Phase.Running;
  }

  isRunning(): boolean {
    return this.state.running;
  }

  getWidth(): number { return this.state.width; }
  getHeight(): number { return this.state.height; }
  getVersion(): number { return this.state.version; }

  // -- Event queue ---------------------------------------------------------

  pushEvent(e: TuiEvent): void {
    this.eventQueue.push(e);
  }

  pollEvent(): TuiEvent | null {
    return this.eventQueue.shift() ?? null;
  }

  // -- Event processing (mirrors raze-events.adb Process_Event) -----------

  processEvent(e: TuiEvent): void {
    if (!this.isInitialized() || !this.isRunning()) {
      throw new Error("processEvent() requires initialized and running TUI");
    }
    switch (e.kind) {
      case EventKind.Resize:
        this.setSize(e.mouse_x, e.mouse_y);
        break;
      case EventKind.Quit:
        this.state.running = false;
        break;
      default:
        // Key and Mouse events leave state unchanged at this layer.
        break;
    }
  }

  // -- Widget focus --------------------------------------------------------

  registerWidgets(count: number): void {
    this.widgetCount = count;
    this.focusIndex = 0;
  }

  focusNext(): void {
    if (this.widgetCount === 0) return;
    this.focusIndex = (this.focusIndex + 1) % this.widgetCount;
  }

  focusPrev(): void {
    if (this.widgetCount === 0) return;
    this.focusIndex = (this.focusIndex - 1 + this.widgetCount) % this.widgetCount;
  }

  getFocusIndex(): number { return this.focusIndex; }

  // -- Internal helpers ----------------------------------------------------

  private setSize(w: number, h: number): void {
    this.state.width = w;
    this.state.height = h;
    this.state.version += 1;
  }

  requestQuit(): void {
    this.state.running = false;
  }
}

// ---------------------------------------------------------------------------
// Helpers: canonical event constructors
// ---------------------------------------------------------------------------

function keyEvent(code: number, mods = 0): TuiEvent {
  return { kind: EventKind.Key, key_code: code, modifiers: mods, mouse_x: 0, mouse_y: 0 };
}

function mouseEvent(x: number, y: number, mods = 0): TuiEvent {
  return { kind: EventKind.Mouse, key_code: 0, modifiers: mods, mouse_x: x, mouse_y: y };
}

function resizeEvent(width: number, height: number): TuiEvent {
  return { kind: EventKind.Resize, key_code: 0, modifiers: 0, mouse_x: width, mouse_y: height };
}

function quitEvent(): TuiEvent {
  return { kind: EventKind.Quit, key_code: 0, modifiers: 0, mouse_x: 0, mouse_y: 0 };
}

// ---------------------------------------------------------------------------
// E2E Tests: TUI lifecycle state machine
// ---------------------------------------------------------------------------

Deno.test("e2e: TUI starts in Uninit phase", () => {
  const tui = new TuiSystem();
  assertEquals(tui.isInitialized(), false);
  assertEquals(tui.isRunning(), false);
});

Deno.test("e2e: initialize() transitions Uninit → Running", () => {
  const tui = new TuiSystem();
  tui.initialize();
  assertEquals(tui.isInitialized(), true);
  assertEquals(tui.isRunning(), true);
});

Deno.test("e2e: shutdown() transitions Running → Stopped", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.shutdown();
  assertEquals(tui.isInitialized(), false);
  assertEquals(tui.isRunning(), false);
});

Deno.test("e2e: initial dimensions are 80×24 (VT100 defaults)", () => {
  const tui = new TuiSystem();
  tui.initialize();
  assertEquals(tui.getWidth(), 80);
  assertEquals(tui.getHeight(), 24);
});

Deno.test("e2e: initial version is 0", () => {
  const tui = new TuiSystem();
  tui.initialize();
  assertEquals(tui.getVersion(), 0);
});

// ---------------------------------------------------------------------------
// E2E Tests: Key event dispatch
// ---------------------------------------------------------------------------

Deno.test("e2e: key event dispatched → state unchanged (key handled by consumer)", () => {
  const tui = new TuiSystem();
  tui.initialize();
  const versionBefore = tui.getVersion();
  tui.processEvent(keyEvent(0x61, Modifiers.NONE));
  // Key events do not mutate dimensions or version.
  assertEquals(tui.getVersion(), versionBefore);
  assertEquals(tui.getWidth(), 80);
  assertEquals(tui.isRunning(), true);
});

Deno.test("e2e: Ctrl+C key event does not auto-quit (must go through quit event)", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.processEvent(keyEvent(0x63, Modifiers.CTRL));
  // Ctrl+C alone does not quit — must be explicit quit event.
  assertEquals(tui.isRunning(), true);
});

// ---------------------------------------------------------------------------
// E2E Tests: Resize event → layout recalculation
// ---------------------------------------------------------------------------

Deno.test("e2e: Resize event updates dimensions", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.processEvent(resizeEvent(132, 50));
  assertEquals(tui.getWidth(), 132);
  assertEquals(tui.getHeight(), 50);
});

Deno.test("e2e: Resize event increments version", () => {
  const tui = new TuiSystem();
  tui.initialize();
  const before = tui.getVersion();
  tui.processEvent(resizeEvent(100, 40));
  assertEquals(tui.getVersion(), before + 1);
});

Deno.test("e2e: multiple resize events increment version monotonically", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.processEvent(resizeEvent(80, 24));
  tui.processEvent(resizeEvent(132, 50));
  tui.processEvent(resizeEvent(40, 10));
  assertEquals(tui.getVersion(), 3);
});

// ---------------------------------------------------------------------------
// E2E Tests: Event loop (push → poll → process)
// ---------------------------------------------------------------------------

Deno.test("e2e: push → poll → process key event", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.pushEvent(keyEvent(0x41, Modifiers.NONE));
  const e = tui.pollEvent();
  assertNotEquals(e, null);
  assertEquals(e!.kind, EventKind.Key);
  assertEquals(e!.key_code, 0x41);
  tui.processEvent(e!);
  assertEquals(tui.isRunning(), true);
});

Deno.test("e2e: event queue drains in FIFO order", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.pushEvent(keyEvent(1));
  tui.pushEvent(keyEvent(2));
  tui.pushEvent(keyEvent(3));
  assertEquals(tui.pollEvent()?.key_code, 1);
  assertEquals(tui.pollEvent()?.key_code, 2);
  assertEquals(tui.pollEvent()?.key_code, 3);
  assertEquals(tui.pollEvent(), null);
});

Deno.test("e2e: Quit event via queue stops the event loop", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.pushEvent(keyEvent(0x61));
  tui.pushEvent(quitEvent());

  let processed = 0;
  while (tui.isRunning()) {
    const e = tui.pollEvent();
    if (!e) break;
    tui.processEvent(e);
    processed++;
  }
  assertEquals(processed, 2);
  assertEquals(tui.isRunning(), false);
});

// ---------------------------------------------------------------------------
// E2E Tests: Widget focus cycle (Tab / Shift-Tab navigation)
// ---------------------------------------------------------------------------

Deno.test("e2e: widget focus starts at index 0", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.registerWidgets(3);
  assertEquals(tui.getFocusIndex(), 0);
});

Deno.test("e2e: Tab cycles focus forward", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.registerWidgets(3);
  tui.focusNext();
  assertEquals(tui.getFocusIndex(), 1);
  tui.focusNext();
  assertEquals(tui.getFocusIndex(), 2);
});

Deno.test("e2e: Tab wraps from last widget to first", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.registerWidgets(3);
  tui.focusNext();
  tui.focusNext();
  tui.focusNext();
  assertEquals(tui.getFocusIndex(), 0);
});

Deno.test("e2e: Shift-Tab cycles focus backward", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.registerWidgets(3);
  tui.focusNext(); // 0 → 1
  tui.focusPrev(); // 1 → 0
  assertEquals(tui.getFocusIndex(), 0);
});

Deno.test("e2e: Shift-Tab wraps from first widget to last", () => {
  const tui = new TuiSystem();
  tui.initialize();
  tui.registerWidgets(3);
  tui.focusPrev(); // 0 → 2 (wrap)
  assertEquals(tui.getFocusIndex(), 2);
});

Deno.test("e2e: full init→event-loop→shutdown sequence", () => {
  const tui = new TuiSystem();
  tui.initialize();
  assert(tui.isInitialized(), "must be initialized");
  assert(tui.isRunning(), "must be running");

  tui.processEvent(keyEvent(0x61, Modifiers.NONE));
  tui.processEvent(resizeEvent(100, 40));
  assertEquals(tui.getWidth(), 100);
  assertEquals(tui.getHeight(), 40);

  tui.processEvent(quitEvent());
  assertEquals(tui.isRunning(), false);
  assertEquals(tui.isInitialized(), true); // still initialized, just not running

  tui.shutdown();
  assertEquals(tui.isInitialized(), false);
});
