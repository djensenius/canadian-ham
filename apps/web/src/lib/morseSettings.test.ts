import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { morseISEDExamPreset, morseTimingFromPreferences, normalizeMorsePreferences } from "./morseSettings";

describe("Morse trainer settings", () => {
  it("drops the retired preview toggle flag and clamps local settings", () => {
    const settings = normalizeMorsePreferences({ enabled: true, toneHz: 1200, characterWpm: 26, effectiveWpm: 30, volume: 2, timingProfile: "general" });

    assert.deepEqual(normalizeMorsePreferences(), {
      toneHz: 650,
      characterWpm: 15,
      effectiveWpm: 5,
      timingProfile: "isedParis",
      volume: 0.6,
    });
    assert.deepEqual(settings, {
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

  it("uses fixed exam timing profiles from the Morse engine", () => {
    const ised = morseTimingFromPreferences(normalizeMorsePreferences({ characterWpm: 25, effectiveWpm: 25, timingProfile: "isedParis" }));
    const ric1 = morseTimingFromPreferences(normalizeMorsePreferences({ characterWpm: 25, effectiveWpm: 25, timingProfile: "ric1Literal" }));

    assert.equal(ised.characterWpm, 12);
    assert.equal(ised.effectiveWpm, 5);
    assert.ok(Math.abs(ised.interCharacterGapSeconds - 1.4052631579) < 1e-9);
    assert.equal(ric1.characterWpm, 12);
    assert.ok(Math.abs(ric1.effectiveWpm - (60 / 7.6)) < 1e-12);
    assert.ok(Math.abs(ric1.dotSeconds - 0.1) < 1e-12);
    assert.ok(Math.abs(ric1.interCharacterGapSeconds - 0.7) < 1e-12);
    assert.ok(Math.abs(ric1.wordGapSeconds - 1.7) < 1e-12);
  });

  it("uses the user's Farnsworth speed settings for the general profile", () => {
    const timing = morseTimingFromPreferences(normalizeMorsePreferences({ characterWpm: 20, effectiveWpm: 10, timingProfile: "general" }));

    assert.equal(timing.name, undefined);
    assert.equal(timing.characterWpm, 20);
    assert.equal(timing.effectiveWpm, 10);
    assert.ok(Math.abs(timing.dotSeconds - 0.06) < 1e-12);
  });
});
