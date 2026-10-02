import { textToTimedMorse, type TimedMorseSequence } from "@canadian-ham/morse-engine";

import { morseTimingFromPreferences, normalizeMorsePreferences, type WebMorsePreferences } from "./morseSettings";

export const MORSE_AUDIO_RAMP_SECONDS = 0.005;
export const MORSE_AUDIO_START_DELAY_SECONDS = 0.02;

export interface MorsePlaybackHandle {
  readonly durationSeconds: number;
  readonly startedAtSeconds: number;
  stop: () => void;
}

export interface WebMorseAudioContextLike {
  readonly currentTime: number;
  readonly destination: AudioNode;
  readonly state?: AudioContextState;
  createOscillator(): OscillatorNode;
  createGain(): GainNode;
  resume?(): Promise<void>;
  close?(): Promise<void>;
}

export type WebMorseAudioContextFactory = () => WebMorseAudioContextLike;

export class WebMorsePlayer {
  #context: WebMorseAudioContextLike | null = null;
  #active: MorsePlaybackHandle | null = null;
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

  stop(): void {
    this.#generation += 1;
    this.#active?.stop();
    this.#active = null;
  }

  async close(): Promise<void> {
    this.stop();
    const context = this.#context;
    this.#context = null;
    await context?.close?.();
  }
}

export function scheduleMorseSequence(context: WebMorseAudioContextLike, sequence: TimedMorseSequence, preferences: WebMorsePreferences): MorsePlaybackHandle {
  const normalizedPreferences = normalizeMorsePreferences(preferences);
  const oscillator = context.createOscillator();
  const gain = context.createGain();
  const startedAtSeconds = context.currentTime + MORSE_AUDIO_START_DELAY_SECONDS;
  const volume = normalizedPreferences.volume;

  oscillator.type = "sine";
  oscillator.frequency.setValueAtTime(normalizedPreferences.toneHz, context.currentTime);
  gain.gain.setValueAtTime(0, context.currentTime);

  oscillator.connect(gain);
  gain.connect(context.destination);

  for (const symbol of sequence.symbols) {
    if (symbol.kind !== "dot" && symbol.kind !== "dash") {
      continue;
    }
    const start = startedAtSeconds + symbol.startSeconds;
    const end = start + symbol.durationSeconds;
    const ramp = Math.min(MORSE_AUDIO_RAMP_SECONDS, symbol.durationSeconds / 2);
    gain.gain.setValueAtTime(0, start);
    gain.gain.linearRampToValueAtTime(volume, start + ramp);
    gain.gain.setValueAtTime(volume, Math.max(start + ramp, end - ramp));
    gain.gain.linearRampToValueAtTime(0, end);
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
      const stopStartedAt = context.currentTime;
      const stopAt = stopStartedAt + MORSE_AUDIO_RAMP_SECONDS;
      try {
        gain.gain.cancelAndHoldAtTime?.(stopStartedAt);
        if (gain.gain.cancelAndHoldAtTime === undefined) {
          gain.gain.cancelScheduledValues(stopStartedAt);
          gain.gain.setValueAtTime(0, stopStartedAt);
        }
        gain.gain.linearRampToValueAtTime(0, stopAt);
        oscillator.stop(stopAt);
      } catch {
        // Some Web Audio implementations throw if stop() has already been scheduled or called.
      }
      globalThis.setTimeout(() => {
        oscillator.disconnect();
        gain.disconnect();
      }, Math.ceil(MORSE_AUDIO_RAMP_SECONDS * 1000) + 20);
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

declare global {
  // Safari still exposes webkitAudioContext.
  // eslint-disable-next-line no-var
  var webkitAudioContext: (typeof AudioContext) | undefined;
}
