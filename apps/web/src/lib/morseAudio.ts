import { textToTimedMorse, type TimedMorseSequence } from "@canadian-ham/morse-engine";

import { morseTimingFromPreferences, normalizeMorsePreferences, type WebMorsePreferences } from "./morseSettings";

export const MORSE_AUDIO_RAMP_SECONDS = 0.005;
export const MORSE_AUDIO_START_DELAY_SECONDS = 0.02;
export const MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS = 0.005;
export const MORSE_AUDIO_CLOSE_MARGIN_SECONDS = 0.1;

export interface MorsePlaybackHandle {
  readonly durationSeconds: number;
  readonly startedAtSeconds: number;
  stop: () => void;
}

export interface MorseToneHandle {
  readonly startedAtSeconds: number;
  stop: () => void;
}

export interface WebMorseAudioContextLike {
  readonly currentTime: number;
  readonly destination: AudioNode;
  readonly state?: AudioContextState;
  readonly baseLatency?: number;
  readonly outputLatency?: number;
  createOscillator(): OscillatorNode;
  createGain(): GainNode;
  resume?(): Promise<void>;
  close?(): Promise<void>;
}

export type WebMorseAudioContextFactory = () => WebMorseAudioContextLike;

export class WebMorsePlayer {
  #context: WebMorseAudioContextLike | null = null;
  #active: MorsePlaybackHandle | null = null;
  // Set when stop() fades out live audio, so a following close() still waits for the fade and output latency.
  #drainPending = false;
  #generation = 0;

  constructor(private readonly createContext: WebMorseAudioContextFactory = defaultAudioContextFactory) {}

  get hasContext(): boolean {
    return this.#context !== null;
  }

  async playText(text: string, preferences: WebMorsePreferences): Promise<MorsePlaybackHandle> {
    const generation = ++this.#generation;
    const normalizedPreferences = normalizeMorsePreferences(preferences);
    const sequence = textToTimedMorse(text, morseTimingFromPreferences(normalizedPreferences));
    const context = this.#context ?? this.createContext();
    this.#context = context;
    if (context.state === "suspended") {
      await context.resume?.();
    }
    if (generation !== this.#generation) {
      throw new Error("Morse playback was cancelled.");
    }
    this.#active?.stop();
    if (generation !== this.#generation) {
      throw new Error("Morse playback was cancelled.");
    }
    const handle = scheduleMorseSequence(context, sequence, normalizedPreferences);
    this.#active = handle;
    return handle;
  }

  async startTone(preferences: WebMorsePreferences): Promise<MorseToneHandle> {
    const generation = ++this.#generation;
    const normalizedPreferences = normalizeMorsePreferences(preferences);
    const context = this.#context ?? this.createContext();
    this.#context = context;
    if (context.state === "suspended") {
      await context.resume?.();
    }
    if (generation !== this.#generation) {
      throw new Error("Morse playback was cancelled.");
    }
    this.#active?.stop();
    const handle = scheduleContinuousMorseTone(context, normalizedPreferences);
    this.#active = { durationSeconds: Number.POSITIVE_INFINITY, startedAtSeconds: handle.startedAtSeconds, stop: handle.stop };
    return handle;
  }

  stop(): void {
    this.#generation += 1;
    if (this.#active !== null) {
      this.#drainPending = true;
    }
    this.#active?.stop();
    this.#active = null;
  }

  async close(): Promise<void> {
    this.stop();
    const needsDrain = this.#drainPending;
    this.#drainPending = false;
    const context = this.#context;
    this.#context = null;
    if (needsDrain && context !== null) {
      await sleep(closeDelayMilliseconds(context));
    }
    await context?.close?.();
  }
}

export function scheduleContinuousMorseTone(context: WebMorseAudioContextLike, preferences: WebMorsePreferences): MorseToneHandle {
  const normalizedPreferences = normalizeMorsePreferences(preferences);
  const oscillator = context.createOscillator();
  const outputGain = context.createGain();
  const startedAtSeconds = context.currentTime;
  oscillator.type = "sine";
  oscillator.frequency.setValueAtTime(normalizedPreferences.toneHz, context.currentTime);
  outputGain.gain.setValueAtTime(0, context.currentTime);
  outputGain.gain.linearRampToValueAtTime(normalizedPreferences.volume, context.currentTime + MORSE_AUDIO_RAMP_SECONDS);
  oscillator.connect(outputGain);
  outputGain.connect(context.destination);
  oscillator.start(startedAtSeconds);
  let stopped = false;
  return {
    startedAtSeconds,
    stop: () => {
      if (stopped) return;
      stopped = true;
      const stopStartedAt = stopRampStartSeconds(context);
      const stopAt = stopStartedAt + MORSE_AUDIO_RAMP_SECONDS;
      outputGain.gain.setValueAtTime(normalizedPreferences.volume, stopStartedAt);
      outputGain.gain.linearRampToValueAtTime(0, stopAt);
      try {
        oscillator.stop(stopAt);
      } catch {
        // Some Web Audio implementations throw if stop() has already been scheduled or called.
      }
      globalThis.setTimeout(() => {
        oscillator.disconnect();
        outputGain.disconnect();
      }, stopCleanupDelayMilliseconds());
    },
  };
}

export function scheduleMorseSequence(context: WebMorseAudioContextLike, sequence: TimedMorseSequence, preferences: WebMorsePreferences): MorsePlaybackHandle {
  const normalizedPreferences = normalizeMorsePreferences(preferences);
  const oscillator = context.createOscillator();
  const toneGain = context.createGain();
  const outputGain = context.createGain();
  const startedAtSeconds = context.currentTime + MORSE_AUDIO_START_DELAY_SECONDS;
  const volume = normalizedPreferences.volume;

  oscillator.type = "sine";
  oscillator.frequency.setValueAtTime(normalizedPreferences.toneHz, context.currentTime);
  toneGain.gain.setValueAtTime(0, context.currentTime);
  outputGain.gain.setValueAtTime(1, context.currentTime);

  oscillator.connect(toneGain);
  toneGain.connect(outputGain);
  outputGain.connect(context.destination);

  for (const symbol of sequence.symbols) {
    if (symbol.kind !== "dot" && symbol.kind !== "dash") {
      continue;
    }
    const start = startedAtSeconds + symbol.startSeconds;
    const end = start + symbol.durationSeconds;
    const ramp = Math.min(MORSE_AUDIO_RAMP_SECONDS, symbol.durationSeconds / 2);
    toneGain.gain.setValueAtTime(0, start);
    toneGain.gain.linearRampToValueAtTime(volume, start + ramp);
    toneGain.gain.setValueAtTime(volume, Math.max(start + ramp, end - ramp));
    toneGain.gain.linearRampToValueAtTime(0, end);
  }

  oscillator.start(startedAtSeconds);
  oscillator.stop(startedAtSeconds + sequence.totalDurationSeconds + MORSE_AUDIO_RAMP_SECONDS);

  let stopped = false;
  return {
    durationSeconds: sequence.totalDurationSeconds,
    startedAtSeconds,
    stop: () => {
      if (stopped) {
        return;
      }
      stopped = true;
      const stopStartedAt = stopRampStartSeconds(context);
      const stopAt = stopStartedAt + MORSE_AUDIO_RAMP_SECONDS;
      try {
        outputGain.gain.setValueAtTime(1, stopStartedAt);
        outputGain.gain.linearRampToValueAtTime(0, stopAt);
        oscillator.stop(stopAt);
      } catch {
        // Some Web Audio implementations throw if stop() has already been scheduled or called.
      }
      globalThis.setTimeout(() => {
        oscillator.disconnect();
        toneGain.disconnect();
        outputGain.disconnect();
      }, stopCleanupDelayMilliseconds());
    },
  };
}

function defaultAudioContextFactory(): WebMorseAudioContextLike {
  const AudioContextCtor = globalThis.AudioContext ?? globalThis.webkitAudioContext;
  if (AudioContextCtor === undefined) {
    throw new Error("Web Audio is not available in this browser.");
  }
  return new AudioContextCtor();
}

function stopRampStartSeconds(context: WebMorseAudioContextLike): number {
  return context.currentTime + MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS;
}

function stopCleanupDelayMilliseconds(): number {
  return Math.ceil((MORSE_AUDIO_STOP_SCHEDULE_LEAD_SECONDS + MORSE_AUDIO_RAMP_SECONDS) * 1000) + 20;
}

function closeDelayMilliseconds(context: WebMorseAudioContextLike | null): number {
  return Math.ceil((MORSE_AUDIO_RAMP_SECONDS + audioContextLatencySeconds(context) + MORSE_AUDIO_CLOSE_MARGIN_SECONDS) * 1000);
}

function audioContextLatencySeconds(context: WebMorseAudioContextLike | null): number {
  return nonNegativeFiniteSeconds(context?.baseLatency) + nonNegativeFiniteSeconds(context?.outputLatency);
}

function nonNegativeFiniteSeconds(value: number | undefined): number {
  return value !== undefined && Number.isFinite(value) && value > 0 ? value : 0;
}

function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => globalThis.setTimeout(resolve, milliseconds));
}

declare global {
  // Safari still exposes webkitAudioContext.
  // eslint-disable-next-line no-var
  var webkitAudioContext: (typeof AudioContext) | undefined;
}
