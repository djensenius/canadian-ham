import { farnsworthTiming, profileForName, type MorseTimingProfile } from "@canadian-ham/morse-engine";

export type WebMorseTimingProfileName = "isedParis" | "ric1Literal" | "general";

export interface WebMorsePreferences {
  readonly toneHz: number;
  readonly characterWpm: number;
  readonly effectiveWpm: number;
  readonly timingProfile: WebMorseTimingProfileName;
  readonly volume: number;
}

export const defaultMorsePreferences: WebMorsePreferences = Object.freeze({
  toneHz: 650,
  characterWpm: 15,
  effectiveWpm: 5,
  timingProfile: "isedParis",
  volume: 0.6,
});

type StoredWebMorsePreferences = Partial<WebMorsePreferences> & { readonly enabled?: unknown };

export function normalizeMorsePreferences(value: StoredWebMorsePreferences = {}): WebMorsePreferences {
  const characterWpm = clampInteger(value.characterWpm, 12, 25, defaultMorsePreferences.characterWpm);
  return {
    toneHz: clampInteger(value.toneHz, 400, 900, defaultMorsePreferences.toneHz),
    characterWpm,
    effectiveWpm: clampInteger(value.effectiveWpm, 5, characterWpm, Math.min(defaultMorsePreferences.effectiveWpm, characterWpm)),
    timingProfile: isTimingProfile(value.timingProfile) ? value.timingProfile : defaultMorsePreferences.timingProfile,
    volume: clampNumber(value.volume, 0, 1, defaultMorsePreferences.volume),
  };
}

export function morseISEDExamPreset(current: WebMorsePreferences): WebMorsePreferences {
  return normalizeMorsePreferences({ ...current, characterWpm: 12, effectiveWpm: 5, timingProfile: "isedParis" });
}

export function morseTimingFromPreferences(preferences: WebMorsePreferences): MorseTimingProfile {
  const normalized = normalizeMorsePreferences(preferences);
  if (normalized.timingProfile === "isedParis" || normalized.timingProfile === "ric1Literal") {
    return profileForName(normalized.timingProfile);
  }
  return farnsworthTiming({ characterWpm: normalized.characterWpm, effectiveWpm: normalized.effectiveWpm });
}

function isTimingProfile(value: unknown): value is WebMorseTimingProfileName {
  return value === "isedParis" || value === "ric1Literal" || value === "general";
}

function clampInteger(value: unknown, min: number, max: number, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, Math.round(value)));
}

function clampNumber(value: unknown, min: number, max: number, fallback: number): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return fallback;
  }
  return Math.max(min, Math.min(max, value));
}
