import assert from "node:assert/strict";
import { fireEvent, render, screen, within, cleanup, act } from "@testing-library/react";
import { afterEach, beforeEach, describe, it, vi } from "vitest";

import { defaultPreferences } from "../../lib/progressStore";
import { MorseSendingPracticeSection } from "./MorseSendingPracticeSection";

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
  stop(): void {}
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

describe("MorseSendingPracticeSection", () => {
  let now = 0;
  const coordinator = {
    register: () => () => {},
    claim: vi.fn(),
  };

  beforeEach(() => {
    vi.useFakeTimers();
    stubMorseAudioContext();
    now = 0;
    coordinator.claim.mockClear();
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("decodes straight-key keyboard timing with fake timers", async () => {
    render(<MorseSendingPracticeSection interfaceLanguage="en" preferences={defaultPreferences} playbackCoordinator={coordinator} nowMilliseconds={() => now} />);

    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;
    fireEvent.keyDown(panel, { key: " " });
    now += 100;
    fireEvent.keyUp(panel, { key: " " });
    await act(async () => {
      vi.advanceTimersByTime(1500);
    });

    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "E");
    assert.match(within(panel).getByText("Latest feedback").nextElementSibling?.textContent ?? "", /timing consistency 100%/);
    assert.equal(coordinator.claim.mock.calls.at(0)?.[0], "sending-practice");
  });

  it("accepts the eight-dot error signal while sending", async () => {
    render(<MorseSendingPracticeSection interfaceLanguage="en" preferences={defaultPreferences} playbackCoordinator={coordinator} nowMilliseconds={() => now} />);
    const panel = screen.getByRole("heading", { name: "Sending practice" }).closest("section")!;

    fireEvent.keyDown(panel, { key: " " });
    now += 100;
    fireEvent.keyUp(panel, { key: " " });
    await act(async () => { vi.advanceTimersByTime(1500); });
    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "E");

    for (let index = 0; index < 8; index += 1) {
      fireEvent.keyDown(panel, { key: " " });
      now += 100;
      fireEvent.keyUp(panel, { key: " " });
      now += 100;
    }
    await act(async () => { vi.advanceTimersByTime(1500); });

    assert.equal(within(panel).getByText("Decoded text").nextElementSibling?.textContent, "—");
    assert.match(panel.textContent ?? "", /Error signal received/);
  });

  it("grades an exam-style sending check on its own results panel", async () => {
    render(<MorseSendingPracticeSection interfaceLanguage="en" preferences={defaultPreferences} playbackCoordinator={coordinator} examDurationSeconds={180} examSeedFactory={() => "sending-test-seed"} nowMilliseconds={() => now} />);

    await act(async () => {
      fireEvent.click(screen.getByRole("button", { name: "Exam-style check" }));
    });
    await act(async () => {
      fireEvent.click(screen.getByRole("button", { name: "End and grade" }));
    });

    assert.ok(screen.getByRole("heading", { name: "Sending results" }));
    assert.match(screen.getByRole("heading", { name: "Sending results" }).parentElement?.textContent ?? "", /Exam rule: 5 or fewer errors/);
  });
});
