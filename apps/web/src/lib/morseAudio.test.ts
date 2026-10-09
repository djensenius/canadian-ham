import assert from "node:assert/strict";
import { textToTimedMorse } from "@canadian-ham/morse-engine";
import { describe, it, vi } from "vitest";

import { MORSE_AUDIO_CLOSE_MARGIN_SECONDS, MORSE_AUDIO_RAMP_SECONDS, MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS, WebMorsePlayer, scheduleMorseSequence, type WebMorseAudioContextLike } from "./morseAudio";
import { normalizeMorsePreferences } from "./morseSettings";

class MockAudioParam {
  readonly events: Array<{ readonly type: "set" | "linear" | "cancel" | "hold"; readonly value?: number; readonly time: number }> = [];
  setValueAtTime(value: number, time: number): void {
    this.events.push({ type: "set", value, time });
  }
  linearRampToValueAtTime(value: number, time: number): void {
    this.events.push({ type: "linear", value, time });
  }
  cancelScheduledValues(time: number): void {
    this.events.push({ type: "cancel", time });
  }
  cancelAndHoldAtTime(time: number): void {
    this.events.push({ type: "hold", time });
  }
}

class MockOscillatorNode {
  type: OscillatorType = "square";
  readonly frequency = new MockAudioParam();
  readonly starts: number[] = [];
  readonly stops: Array<number | undefined> = [];
  connect(): MockGainNode { return new MockGainNode(); }
  disconnect(): void {}
  start(time?: number): void { this.starts.push(time ?? 0); }
  stop(time?: number): void { this.stops.push(time); }
}

class MockGainNode {
  readonly gain = new MockAudioParam();
  connect(): void {}
  disconnect(): void {}
}

class MockAudioContext implements WebMorseAudioContextLike {
  currentTime = 10;
  destination = {} as AudioNode;
  state: AudioContextState = "suspended";
  baseLatency = 0;
  outputLatency = 0;
  readonly oscillator = new MockOscillatorNode();
  readonly gains: MockGainNode[] = [];
  resumeCount = 0;
  closeCount = 0;
  private resumePromise: Promise<void> | null = null;
  private resumeResolve: (() => void) | null = null;
  get toneGain(): MockGainNode { return this.gains[0]!; }
  get outputGain(): MockGainNode { return this.gains[1]!; }
  createOscillator(): OscillatorNode { return this.oscillator as unknown as OscillatorNode; }
  createGain(): GainNode {
    const gain = new MockGainNode();
    this.gains.push(gain);
    return gain as unknown as GainNode;
  }
  delayResume(): void {
    this.resumePromise = new Promise((resolve) => {
      this.resumeResolve = resolve;
    });
  }
  resolveResume(): void {
    this.state = "running";
    this.resumeResolve?.();
  }
  async resume(): Promise<void> {
    this.resumeCount += 1;
    if (this.resumePromise !== null) {
      await this.resumePromise;
      return;
    }
    this.state = "running";
  }
  async close(): Promise<void> {
    this.closeCount += 1;
  }
}

describe("WebMorsePlayer", () => {
  it("does not create or resume AudioContext until play is called from the user gesture handler", async () => {
    let created = 0;
    const context = new MockAudioContext();
    const player = new WebMorsePlayer(() => {
      created += 1;
      return context;
    });

    assert.equal(player.hasContext, false);
    assert.equal(created, 0);

    await player.playText("E", normalizeMorsePreferences());

    assert.equal(player.hasContext, true);
    assert.equal(created, 1);
    assert.equal(context.resumeCount, 1);
  });

  it("schedules oscillator start times and 5 ms gain ramps from the Morse timing engine", () => {
    const context = new MockAudioContext();
    context.state = "running";
    const sequence = textToTimedMorse("E", {
      characterWpm: 12,
      effectiveWpm: 5,
      dotSeconds: 0.1,
      dashSeconds: 0.3,
      intraCharacterGapSeconds: 0.1,
      interCharacterGapSeconds: 0.7,
      wordGapSeconds: 1.7,
    });

    const handle = scheduleMorseSequence(context, sequence, normalizeMorsePreferences({ toneHz: 700, volume: 0.4 }));

    assert.equal(handle.startedAtSeconds, 10.02);
    assert.deepEqual(context.oscillator.starts, [10.02]);
    assert.equal(context.oscillator.frequency.events[0]?.value, 700);
    assert.deepEqual(context.toneGain.gain.events.slice(1, 5), [
      { type: "set", value: 0, time: 10.02 },
      { type: "linear", value: 0.4, time: 10.02 + MORSE_AUDIO_RAMP_SECONDS },
      { type: "set", value: 0.4, time: 10.02 + 0.1 - MORSE_AUDIO_RAMP_SECONDS },
      { type: "linear", value: 0, time: 10.12 },
    ]);
    assert.deepEqual(context.outputGain.gain.events, [{ type: "set", value: 1, time: 10 }]);
  });

  it("ramps the unscheduled output gain down from a lead time so stale currentTime still gets the full fade", () => {
    const context = new MockAudioContext();
    context.state = "running";
    const handle = scheduleMorseSequence(context, textToTimedMorse("E"), normalizeMorsePreferences({ volume: 0.5 }));

    handle.stop();

    const stopStart = 10 + MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS;
    assert.deepEqual(context.outputGain.gain.events.slice(-2), [
      { type: "set", value: 1, time: stopStart },
      { type: "linear", value: 0, time: stopStart + MORSE_AUDIO_RAMP_SECONDS },
    ]);
    assert.deepEqual(context.toneGain.gain.events.filter((event) => event.type === "hold" || event.type === "cancel"), []);
    assert.equal(context.oscillator.stops.at(-1), stopStart + MORSE_AUDIO_RAMP_SECONDS);
  });

  it("does not require cancelAndHoldAtTime when stopping", () => {
    const context = new MockAudioContext();
    context.state = "running";
    const handle = scheduleMorseSequence(context, textToTimedMorse("E"), normalizeMorsePreferences({ volume: 0.5 }));
    Object.defineProperty(context.outputGain.gain, "cancelAndHoldAtTime", { value: undefined, configurable: true });

    handle.stop();

    const stopStart = 10 + MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS;
    assert.deepEqual(context.outputGain.gain.events.slice(-2), [
      { type: "set", value: 1, time: stopStart },
      { type: "linear", value: 0, time: stopStart + MORSE_AUDIO_RAMP_SECONDS },
    ]);
    assert.equal(context.oscillator.stops.at(-1), stopStart + MORSE_AUDIO_RAMP_SECONDS);
  });

  it("cancels scheduling when stopped during AudioContext resume", async () => {
    const context = new MockAudioContext();
    context.delayResume();
    const player = new WebMorsePlayer(() => context);
    const playPromise = player.playText("E", normalizeMorsePreferences());

    assert.equal(context.resumeCount, 1);
    player.stop();
    context.resolveResume();

    await assert.rejects(playPromise, /cancelled/);
    assert.deepEqual(context.oscillator.starts, []);
    assert.deepEqual(context.oscillator.stops, []);
  });

  it("closes the AudioContext after the stop fade plus device latency and margin when the route leaves", async () => {
    vi.useFakeTimers();
    try {
      const context = new MockAudioContext();
      context.baseLatency = 0.03;
      context.outputLatency = 0.02;
      const player = new WebMorsePlayer(() => context);
      await player.playText("E", normalizeMorsePreferences());
      const closePromise = player.close();
      const expectedDelayMilliseconds = Math.ceil((MORSE_AUDIO_RAMP_SECONDS + context.baseLatency + context.outputLatency + MORSE_AUDIO_CLOSE_MARGIN_SECONDS) * 1000);

      await vi.advanceTimersByTimeAsync(expectedDelayMilliseconds - 1);
      assert.equal(context.closeCount, 0);
      await vi.advanceTimersByTimeAsync(1);
      await closePromise;

      assert.equal(context.closeCount, 1);
    } finally {
      vi.useRealTimers();
    }
  });

  it("still drains the fade when the output controller calls stop() before close()", async () => {
    vi.useFakeTimers();
    try {
      const context = new MockAudioContext();
      context.baseLatency = 0.03;
      context.outputLatency = 0.02;
      const player = new WebMorsePlayer(() => context);
      await player.playText("E", normalizeMorsePreferences());
      // useWebMorseOutput's close() stops first, then closes the player.
      player.stop();
      const closePromise = player.close();
      const expectedDelayMilliseconds = Math.ceil((MORSE_AUDIO_RAMP_SECONDS + context.baseLatency + context.outputLatency + MORSE_AUDIO_CLOSE_MARGIN_SECONDS) * 1000);

      await vi.advanceTimersByTimeAsync(expectedDelayMilliseconds - 1);
      assert.equal(context.closeCount, 0, "close must wait for the fade even after stop()");
      await vi.advanceTimersByTimeAsync(1);
      await closePromise;
      assert.equal(context.closeCount, 1);
    } finally {
      vi.useRealTimers();
    }
  });

  it("closes immediately when nothing has played", async () => {
    const context = new MockAudioContext();
    const player = new WebMorsePlayer(() => context);
    await player.close();
    assert.equal(context.closeCount, 0, "no context was created, so there is nothing to close");
  });
});
