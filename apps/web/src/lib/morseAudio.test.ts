import assert from "node:assert/strict";
import { textToTimedMorse } from "@canadian-ham/morse-engine";
import { describe, it } from "vitest";

import { MORSE_AUDIO_RAMP_SECONDS, WebMorsePlayer, scheduleMorseSequence, type WebMorseAudioContextLike } from "./morseAudio";
import { normalizeMorsePreferences } from "./morseSettings";

class MockAudioParam {
  readonly events: Array<{ readonly type: "set" | "linear"; readonly value: number; readonly time: number }> = [];
  setValueAtTime(value: number, time: number): void {
    this.events.push({ type: "set", value, time });
  }
  linearRampToValueAtTime(value: number, time: number): void {
    this.events.push({ type: "linear", value, time });
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
  readonly oscillator = new MockOscillatorNode();
  readonly gain = new MockGainNode();
  resumeCount = 0;
  createOscillator(): OscillatorNode { return this.oscillator as unknown as OscillatorNode; }
  createGain(): GainNode { return this.gain as unknown as GainNode; }
  async resume(): Promise<void> {
    this.resumeCount += 1;
    this.state = "running";
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
    assert.deepEqual(context.gain.gain.events.slice(1, 5), [
      { type: "set", value: 0, time: 10.02 },
      { type: "linear", value: 0.4, time: 10.02 + MORSE_AUDIO_RAMP_SECONDS },
      { type: "set", value: 0.4, time: 10.02 + 0.1 - MORSE_AUDIO_RAMP_SECONDS },
      { type: "linear", value: 0, time: 10.12 },
    ]);
  });
});
