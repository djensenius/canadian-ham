import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { morseISEDExamPreset, morseTimingFromPreferences, normalizeMorsePreferences } from "./morseSettings";

describe("Morse trainer settings", () => {
  it("defaults the preview off and clamps local settings", () => {
    const settings = normalizeMorsePreferences({ enabled: true, toneHz: 1200, characterWpm: 26, effectiveWpm: 30, volume: 2, timingProfile: "general" });

    assert.equal(normalizeMorsePreferences().enabled, false);
    assert.deepEqual(settings, {
      enabled: true,
      toneHz: 900,
      characterWpm: 25,
      effectiveWpm: 25,
      timingProfile: "general",
      volume: 1,
    });
  });

  it("applies the ISED exam preset at 12/5 with PARIS-calibrated timing", () => {
    const preset = morseISEDExamPreset(normalizeMorsePreferences({ characterWpm: 20, effectiveWpm: 20, timingProfile: "ric1Literal" }));
    const timing = morseTimingFromPreferences(preset);

    assert.equal(preset.characterWpm, 12);
    assert.equal(preset.effectiveWpm, 5);
    assert.equal(preset.timingProfile, "isedParis");
    assert.equal(timing.characterWpm, 12);
    assert.equal(timing.effectiveWpm, 5);
    assert.ok(Math.abs(timing.interCharacterGapSeconds - 1.4052631579) < 1e-9);
  });

  it("uses RIC-1 literal spacing from the selected character dot length", () => {
    const timing = morseTimingFromPreferences(normalizeMorsePreferences({ characterWpm: 12, effectiveWpm: 5, timingProfile: "ric1Literal" }));

    assert.ok(Math.abs(timing.dotSeconds - 0.1) < 1e-12);
    assert.ok(Math.abs(timing.interCharacterGapSeconds - 0.7) < 1e-12);
    assert.ok(Math.abs(timing.wordGapSeconds - 1.7) < 1e-12);
  });
});
