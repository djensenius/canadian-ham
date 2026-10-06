import assert from "node:assert/strict";
import { act, cleanup, fireEvent, render, screen, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, it, vi } from "vitest";

import { defaultPreferences, type WebPreferences } from "../../lib/progressStore";
import { MorseSendingPracticeSection } from "./MorseSendingPracticeSection";

let oscillatorStopCalls = 0;

class MockMorseAudioParam {
  setValueAtTime(): this { return this; }
  linearRampToValueAtTime(): this { return this; }
}

class MockMorseAudioNode {
  connect(): AudioNode { return this as unknown as AudioNode; }
  disconnect(): void {}
}

class MockMorseOscillatorNode extends MockMorseAudioNode {
  type: OscillatorType = "sine";
  readonly frequency = new MockMorseAudioParam();
  start(): void {}
  stop(): void { oscillatorStopCalls += 1; }
}

class MockMorseGainNode extends MockMorseAudioNode {
  readonly gain = new MockMorseAudioParam();
}

function stubMorseAudioContext(): void {
  class MockMorseAudioContext {
    readonly currentTime = 0;
    readonly destination = new MockMorseAudioNode() as unknown as AudioDestinationNode;
    readonly state: AudioContextState = "running";
    createOscillator(): OscillatorNode { return new MockMorseOscillatorNode() as unknown as OscillatorNode; }
    createGain(): GainNode { return new MockMorseGainNode() as unknown as GainNode; }
    async resume(): Promise<void> {}
    async close(): Promise<void> {}
  }
  vi.stubGlobal("AudioContext", MockMorseAudioContext);
  vi.stubGlobal("webkitAudioContext", undefined);
}

function fastPreferences(): WebPreferences {
  return {
    ...defaultPreferences,
    morse: { ...defaultPreferences.morse, timingProfile: "general", characterWpm: 25, effectiveWpm: 25 },
  };
}

describe("MorseSendingPracticeSection", () => {
  let now = 0;
  let registeredStop: (() => void) | null = null;
  const coordinator = {
    register: vi.fn((_owner: string, stop: () => void) => {
      registeredStop = stop;
      return () => { registeredStop = null; };
    }),
    claim: vi.fn(),
  };

  beforeEach(() => {
    vi.useFakeTimers();
    stubMorseAudioContext();
    now = 0;
    oscillatorStopCalls = 0;
    registeredStop = null;
    coordinator.claim.mockClear();
    coordinator.register.mockClear();
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  function renderSending(options: Partial<Parameters<typeof MorseSendingPracticeSection>[0]> = {}) {
    return render(<MorseSendingPracticeSection interfaceLanguage="en" preferences={defaultPreferences} playbackCoordinator={coordinator} nowMilliseconds={() => now} {...options} />);
  }

  async function sendStraightKey(panel: Element, durationMs: number): Promise<void> {
    fireEvent.keyDown(panel, { key: " " });
    now += durationMs;
    fireEvent.keyUp(panel, { key: " " });
    await act(async () => { vi.advanceTimersByTime(1); });
  }

  async function finalizeCharacter(): Promise<void> {
    await act(async () => { vi.advanceTimersByTime(1500); });
  }

  it("decodes straight-key keyboard timing with fake timers", async () => {
    renderSending();

    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;
    await sendStraightKey(panel, 100);
    await finalizeCharacter();

    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "E");
    assert.match(within(panel).getByText("Latest feedback").nextElementSibling?.textContent ?? "", /timing consistency 100%/);
    assert.equal(coordinator.claim.mock.calls.at(0)?.[0], "sending-practice");
  });

  it("keeps fast multi-element characters together by cancelling the pending character timer", async () => {
    renderSending({ preferences: fastPreferences() });
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;

    await sendStraightKey(panel, 48);
    await act(async () => { vi.advanceTimersByTime(100); });
    await sendStraightKey(panel, 144);
    await act(async () => { vi.advanceTimersByTime(500); });

    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "A");
    assert.match(within(panel).getByText("Latest feedback").nextElementSibling?.textContent ?? "", /dot\/dash ratio 3\.00/);
  });

  it("accepts the eight-dot error signal while sending", async () => {
    renderSending();
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;

    await sendStraightKey(panel, 100);
    await finalizeCharacter();
    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "E");

    for (let index = 0; index < 8; index += 1) {
      await sendStraightKey(panel, 100);
      now += 100;
    }
    await finalizeCharacter();

    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "—");
    assert.match(panel.textContent ?? "", /Error signal received/);
  });

  it("ignores Space from focused controls instead of hijacking button activation", () => {
    renderSending();
    const clear = screen.getByRole("button", { name: "Clear sending practice" });

    fireEvent.keyDown(clear, { key: " " });

    assert.equal(oscillatorStopCalls, 0);
    assert.equal(coordinator.claim.mock.calls.length, 0);
  });

  it("releases stuck keys on blur and when the coordinator stops sending practice", async () => {
    renderSending();
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;
    assert.equal(coordinator.register.mock.calls.at(0)?.[0], "sending-practice");

    fireEvent.keyDown(panel, { key: " " });
    now += 120;
    fireEvent.blur(panel, { relatedTarget: null });
    registeredStop?.();
    await finalizeCharacter();

    assert.ok(oscillatorStopCalls > 0, "continuous side-tone should stop on blur/coordinator release");
    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "E");
  });

  it("records paddle repeat timing using dot-plus-gap and dash-plus-gap durations", async () => {
    renderSending({ preferences: fastPreferences() });
    const dot = screen.getByRole("button", { name: "Dot paddle. Hold for repeated dots." });
    const dash = screen.getByRole("button", { name: "Dash paddle. Hold for repeated dashes." });

    await act(async () => { fireEvent.pointerDown(dot, { pointerId: 1 }); });
    await act(async () => { vi.advanceTimersByTime(100); });
    await act(async () => { fireEvent.pointerUp(dot, { pointerId: 1 }); });
    await finalizeCharacter();
    assert.match(screen.getByText("Current elements").nextElementSibling?.textContent ?? "", /—/);

    await act(async () => { fireEvent.pointerDown(dash, { pointerId: 2 }); });
    await act(async () => { vi.advanceTimersByTime(110); });
    assert.equal(screen.getByText("Current elements").nextElementSibling?.textContent, "-");
    await act(async () => { vi.advanceTimersByTime(100); });
    assert.equal(screen.getByText("Current elements").nextElementSibling?.textContent, "--");
    await act(async () => { fireEvent.pointerUp(dash, { pointerId: 2 }); });
  });

  it("passes an exam-style check when sent text is complete", async () => {
    renderSending({ examDurationSeconds: 180, examTextFactory: () => "E" });
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;

    fireEvent.click(screen.getByRole("button", { name: "Exam-style check" }));
    await sendStraightKey(panel, 100);
    fireEvent.click(screen.getByRole("button", { name: "End and grade" }));

    assert.ok(screen.getByRole("heading", { name: "Sending results" }));
    assert.match(screen.getByRole("heading", { name: "Sending results" }).parentElement?.textContent ?? "", /PASS, 100%, with 0 errors/);
  });

  it("grades timeout from current text and counts only unsent characters as missing errors", async () => {
    renderSending({ examDurationSeconds: 1, examTextFactory: () => "EE" });
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;

    fireEvent.click(screen.getByRole("button", { name: "Exam-style check" }));
    await sendStraightKey(panel, 100);
    await act(async () => { vi.advanceTimersByTime(1000); });

    assert.ok(screen.getByRole("heading", { name: "Sending results" }));
    const results = screen.getByRole("heading", { name: "Sending results" }).parentElement?.textContent ?? "";
    assert.match(results, /PASS, 100%, with 1 errors/);
    assert.match(results, /1 total errors: 0 wrong, 1 missing, 0 inserted/);
    assert.match(results, /E/);
  });
});
