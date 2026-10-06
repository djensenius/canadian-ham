import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  MORSE_BEACON_ACTIVE_MIX,
  MORSE_BEACON_AREA_CSS_PIXELS,
  MORSE_BEACON_RESTING_MIX,
  MORSE_DARK_ACCENT_RGB,
  MORSE_DARK_PAPER_INSET_RGB,
  MORSE_CODE_TABLE,
  MORSE_FLASH_MAX_AREA_CSS_PIXELS,
  MORSE_LIGHT_ACCENT_RGB,
  MORSE_LIGHT_PAPER_INSET_RGB,
  MorseValidationError,
  applyMorseDecodedCharacter,
  buildMorseLessonExercises,
  classifyMorseKeyDown,
  dailyStreak,
  diffMorseCopy,
  evaluateMorseBeaconFlashSafety,
  evaluateMorseFlashSafety,
  farnsworthTiming,
  generateMorseExamText,
  maxMorseFlashesPerSecond,
  mixMorseRgb,
  morseBeaconPalette,
  morseCharacterTimingFeedback,
  morseRelativeLuminance,
  morseHapticEvents,
  morseSignalEvents,
  morseTapeTokens,
  parseMorseCourseFixture,
  profileForName,
  scoreMorseCopy,
  scoreMorseSending,
  textToTimedMorse,
  validateMorseText,
  weightedCharacterCount,
  type MorseProfileName,
  type MorseSymbolKind,
  type MorseTimingProfile,
} from "../src/index.ts";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const fixturesRoot = join(repoRoot, "fixtures/morse");
const fixturePaths = await jsonFiles(fixturesRoot);
const course = parseMorseCourseFixture(JSON.parse(await readFile(join(fixturesRoot, "course.json"), "utf8")));

describe("public tables", () => {
  it("freezes the Morse code table so consumers can't change mappings at runtime", () => {
    expect(Object.isFrozen(MORSE_CODE_TABLE)).toBe(true);
  });
});

describe("visual, tape and haptic output mapping", () => {
  it("maps timed Morse symbols to beacon transitions, tape tokens and haptic durations", () => {
    const sequence = textToTimedMorse("ET", profileForName("isedParis"));
    const signalEvents = morseSignalEvents(sequence);
    expect(signalEvents.map((event) => ({ kind: event.kind, character: event.character, symbolKind: event.symbolKind }))).toEqual([
      { kind: "on", character: "E", symbolKind: "dot" },
      { kind: "off", character: "E", symbolKind: "dot" },
      { kind: "on", character: "T", symbolKind: "dash" },
      { kind: "off", character: "T", symbolKind: "dash" },
    ]);
    expect(signalEvents[1]!.atSeconds).toBeCloseTo(0.1, 12);
    expect(signalEvents[2]!.atSeconds).toBeCloseTo(1.505263157894737, 12);
    expect(morseTapeTokens(sequence).map((token) => token.token)).toEqual([".", "-"]);
    expect(morseTapeTokens(sequence)[1]!.revealAtSeconds).toBeCloseTo(1.505263157894737, 12);
    const hapticEvents = morseHapticEvents(sequence);
    expect(hapticEvents.map((event) => event.symbolKind)).toEqual(["dot", "dash"]);
    expect(hapticEvents[1]!.startSeconds).toBeCloseTo(1.505263157894737, 12);
    expect(hapticEvents[1]!.durationSeconds).toBeCloseTo(0.3, 12);
  });

  it("keeps the configured visual beacon below WCAG 2.2 SC 2.3.1 thresholds at Morse cadence", () => {
    const sequence = textToTimedMorse("5", profileForName("isedParis"));
    const flashesPerSecond = maxMorseFlashesPerSecond(morseSignalEvents(sequence));
    expect(flashesPerSecond).toBe(5);
    expect(MORSE_BEACON_AREA_CSS_PIXELS).toBeLessThan(MORSE_FLASH_MAX_AREA_CSS_PIXELS);
    const lightSafety = evaluateMorseBeaconFlashSafety({ palette: morseBeaconPalette({ accent: MORSE_LIGHT_ACCENT_RGB, background: MORSE_LIGHT_PAPER_INSET_RGB }), flashesPerSecond });
    const darkSafety = evaluateMorseBeaconFlashSafety({ palette: morseBeaconPalette({ accent: MORSE_DARK_ACCENT_RGB, background: MORSE_DARK_PAPER_INSET_RGB }), flashesPerSecond });
    expect(lightSafety).toMatchObject({ safe: true, reason: "below-general-threshold" });
    expect(darkSafety).toMatchObject({ safe: true, reason: "below-general-threshold" });
    expect(lightSafety.luminanceDelta).toBeLessThanOrEqual(0.07);
    expect(darkSafety.luminanceDelta).toBeLessThanOrEqual(0.07);
    expect(evaluateMorseFlashSafety({
      flashAreaCssPixels: MORSE_FLASH_MAX_AREA_CSS_PIXELS + 1,
      flashesPerSecond: 2,
      darkerRelativeLuminance: 0.2,
      lighterRelativeLuminance: 0.8,
      usesSaturatedRed: false,
    })).toMatchObject({ safe: false, reason: "area-too-large" });
    expect(evaluateMorseFlashSafety({
      flashAreaCssPixels: MORSE_BEACON_AREA_CSS_PIXELS,
      flashesPerSecond: 5,
      darkerRelativeLuminance: 0.2,
      lighterRelativeLuminance: 0.8,
      usesSaturatedRed: true,
    })).toMatchObject({ safe: false, reason: "saturated-red" });
  });

  it("matches web token colors with a luminance margin for light and dark beacon states", async () => {
    const tokensCss = await readFile(join(repoRoot, "apps/web/src/styles/tokens.css"), "utf8");
    const lightPaperInset = parseCssHexToken(tokensCss, "light", "paper-inset");
    const lightAccent = parseCssHexToken(tokensCss, "light", "accent");
    const darkPaperInset = parseCssHexToken(tokensCss, "dark", "paper-inset");
    const darkAccent = parseCssHexToken(tokensCss, "dark", "accent");
    expect(lightPaperInset).toEqual(MORSE_LIGHT_PAPER_INSET_RGB);
    expect(lightAccent).toEqual(MORSE_LIGHT_ACCENT_RGB);
    expect(darkPaperInset).toEqual(MORSE_DARK_PAPER_INSET_RGB);
    expect(darkAccent).toEqual(MORSE_DARK_ACCENT_RGB);
    for (const [accent, background] of [[lightAccent, lightPaperInset], [darkAccent, darkPaperInset]] as const) {
      const resting = mixMorseRgb(accent, background, MORSE_BEACON_RESTING_MIX);
      const active = mixMorseRgb(accent, background, MORSE_BEACON_ACTIVE_MIX);
      expect(Math.abs(morseRelativeLuminance(active) - morseRelativeLuminance(resting))).toBeLessThanOrEqual(0.07);
    }
  });
});

describe("shared fixtures/morse", () => {
  it("has fixture JSON files", () => {
    expect(fixturePaths.length).toBeGreaterThan(0);
  });

  for (const fixturePath of fixturePaths) {
    const relativePath = fixturePath.slice(repoRoot.length + 1);
    it(relativePath, async () => {
      const fixture = JSON.parse(await readFile(fixturePath, "utf8"));
      validateFixture(fixture);
    });
  }
});

async function jsonFiles(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true });
  const nested = await Promise.all(entries.map(async (entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      return jsonFiles(path);
    }
    return entry.isFile() && entry.name.endsWith(".json") ? [path] : [];
  }));
  return nested.flat().toSorted();
}

function validateFixture(fixture: any): void {
  expect(fixture.schemaVersion).toBe(1);
  switch (fixture.kind) {
    case "morse-timing":
      validateTimingFixture(fixture);
      break;
    case "morse-word-weighting":
      validateWordWeightingFixture(fixture);
      break;
    case "morse-scoring":
      validateScoringFixture(fixture);
      break;
    case "morse-copy-exam":
      validateCopyExamFixture(fixture);
      break;
    case "morse-copy-diff":
      validateCopyDiffFixture(fixture);
      break;
    case "morse-validation":
      validateValidationFixture(fixture);
      break;
    case "morse-course":
      // The dedicated course test validates the full 40-lesson shape.
      break;
    case "morse-course-exercises":
      validateCourseExercisesFixture(fixture);
      break;
    case "morse-course-streak":
      validateCourseStreakFixture(fixture);
      break;
    case "morse-sending":
      validateSendingFixture(fixture);
      break;
    default:
      throw new Error(`unsupported fixture kind: ${fixture.kind}`);
  }
}

function validateTimingFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    if (testCase.expectedError !== undefined) {
      expectFixtureError(() => {
        const profile = profileFromFixture(testCase.input.profile);
        textToTimedMorse(testCase.input.text, profile);
      }, testCase.expectedError, testCase.id);
      continue;
    }

    const profile = profileFromFixture(testCase.input.profile);
    const sequence = textToTimedMorse(testCase.input.text, profile);
    expect(sequence.normalizedText, testCase.id).toBe(testCase.expectedOutput.normalizedText);
    expect(round(sequence.totalDurationSeconds, 9), testCase.id).toBeCloseTo(testCase.expectedOutput.totalDurationSeconds, 9);
    expect(round(sequence.profile.effectiveWpm, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.effectiveWpm, 12);
    expect(round(sequence.profile.dotSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.dot, 12);
    expect(round(sequence.profile.dashSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.dash, 12);
    expect(round(sequence.profile.intraCharacterGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.intraCharacterGap, 12);
    expect(round(sequence.profile.interCharacterGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.interCharacterGap, 12);
    expect(round(sequence.profile.wordGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.wordGap, 12);
    expect(symbolCounts(sequence.symbols), testCase.id).toEqual(testCase.expectedOutput.symbolCounts);
    expect(sequence.symbols.at(-1)?.kind ?? null, testCase.id).toBe(testCase.expectedOutput.lastSymbolKind);
    if (testCase.expectedOutput.symbols !== undefined) {
      expectSymbols(sequence.symbols, testCase.expectedOutput.symbols, testCase.id);
    }
  }
}

function validateWordWeightingFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    if (testCase.expectedError !== undefined) {
      expectFixtureError(() => weightedCharacterCount(testCase.input.text), testCase.expectedError, testCase.id);
      continue;
    }

    expect(weightedCharacterCount(testCase.input.text), testCase.id).toEqual({
      weightedCharacters: testCase.expectedOutput.weightedCharacters,
      unweightedCharacters: testCase.expectedOutput.unweightedCharacters,
    });
  }
}

function validateScoringFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    if (testCase.expectedError !== undefined) {
      expectFixtureError(() => scoreMorseCopy(testCase.input.expected, testCase.input.received), testCase.expectedError, testCase.id);
      continue;
    }

    expect(scoreMorseCopy(testCase.input.expected, testCase.input.received), testCase.id).toEqual(testCase.expectedOutput);
  }
}

function validateCopyExamFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    const profile = profileFromFixture(testCase.input.profile);
    const generated = generateMorseExamText({
      seed: testCase.input.seed,
      profile,
      minWeightedCharacters: testCase.input.minWeightedCharacters,
      minDurationSeconds: testCase.input.minDurationSeconds,
    });
    const validation = validateMorseText(generated.text);
    expect(validation.valid, testCase.id).toBe(true);
    expect(generated.weightedCharacters, testCase.id).toBeGreaterThanOrEqual(testCase.expectedOutput.minWeightedCharacters);
    expect(generated.durationSeconds, testCase.id).toBeGreaterThanOrEqual(testCase.expectedOutput.minDurationSeconds);
    expect(generated.normalizedText, testCase.id).toBe(textToTimedMorse(generated.text, profile).normalizedText);
    expect(round(generated.durationSeconds, 9), testCase.id).toBeCloseTo(textToTimedMorse(generated.text, profile).totalDurationSeconds, 9);
    if (testCase.expectedOutput.text !== undefined) {
      expect(generated.text, testCase.id).toBe(testCase.expectedOutput.text);
    }
    if (testCase.expectedOutput.normalizedText !== undefined) {
      expect(generated.normalizedText, testCase.id).toBe(testCase.expectedOutput.normalizedText);
    }
    if (testCase.expectedOutput.weightedCharacters !== undefined) {
      expect(generated.weightedCharacters, testCase.id).toBe(testCase.expectedOutput.weightedCharacters);
    }
    if (testCase.expectedOutput.unweightedCharacters !== undefined) {
      expect(generated.unweightedCharacters, testCase.id).toBe(testCase.expectedOutput.unweightedCharacters);
    }
    if (testCase.expectedOutput.durationSeconds !== undefined) {
      expect(round(generated.durationSeconds, 9), testCase.id).toBeCloseTo(testCase.expectedOutput.durationSeconds, 9);
    }
  }
}

function validateCopyDiffFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    if (testCase.expectedError !== undefined) {
      expectFixtureError(() => diffMorseCopy(testCase.input.expected, testCase.input.received), testCase.expectedError, testCase.id);
      continue;
    }

    expect(diffMorseCopy(testCase.input.expected, testCase.input.received), testCase.id).toEqual(testCase.expectedOutput);
  }
}

function validateValidationFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(validateMorseText(testCase.input.text), testCase.id).toEqual(testCase.expectedOutput);
  }
}

function validateCourseExercisesFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    const lesson = course.lessons.find((entry) => entry.id === testCase.input.lessonId);
    expect(lesson, testCase.id).toBeDefined();
    expect(buildMorseLessonExercises({ lesson: lesson!, seed: testCase.input.seed }), testCase.id).toEqual(testCase.expectedOutput.exercises);
  }
}

function validateCourseStreakFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(dailyStreak(testCase.input.activity, testCase.input.todayIso), testCase.id).toBe(testCase.expectedOutput.streak);
  }
}

function validateSendingFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    if (testCase.input.expected !== undefined) {
      const score = scoreMorseSending(testCase.input.expected, testCase.input.sent, testCase.input.completedWithinTime);
      expect(score.diff.score.errors, testCase.id).toBe(testCase.expectedOutput.errors);
      expect(score.passed, testCase.id).toBe(testCase.expectedOutput.passed);
      expect(score.markPercent, testCase.id).toBe(testCase.expectedOutput.markPercent);
      continue;
    }

    const profile = profileFromFixture(testCase.input.profile);
    const samples = testCase.input.durationsSeconds.map((duration: number) => classifyMorseKeyDown(duration, profile));
    const feedback = morseCharacterTimingFeedback(samples);
    expect(feedback.elements, testCase.id).toBe(testCase.expectedOutput.elements);
    expect(feedback.decoded, testCase.id).toEqual(testCase.expectedOutput.decoded);
    expect(feedback.timingConsistencyPercent, testCase.id).toBe(testCase.expectedOutput.timingConsistencyPercent);
    expect(feedback.averageRatioToExpected, testCase.id).toBeCloseTo(testCase.expectedOutput.averageRatioToExpected, 12);
    if (testCase.expectedOutput.dotDashRatio === null) {
      expect(feedback.dotDashRatio, testCase.id).toBeNull();
    } else {
      expect(feedback.dotDashRatio ?? Number.NaN, testCase.id).toBeCloseTo(testCase.expectedOutput.dotDashRatio, 12);
    }
    if (testCase.expectedOutput.appliedText !== undefined) {
      expect(applyMorseDecodedCharacter(testCase.input.applyToText, feedback.decoded), testCase.id).toBe(testCase.expectedOutput.appliedText);
    }
  }
}

function profileFromFixture(input: { readonly name?: MorseProfileName; readonly characterWpm?: number | "NaN"; readonly effectiveWpm?: number | "NaN" }): MorseTimingProfile {
  if (input.name !== undefined) {
    return profileForName(input.name);
  }
  if (input.characterWpm === undefined || input.effectiveWpm === undefined) {
    throw new Error("fixture profile must name a profile or provide characterWpm/effectiveWpm");
  }
  return farnsworthTiming({ characterWpm: fixtureNumber(input.characterWpm), effectiveWpm: fixtureNumber(input.effectiveWpm) });
}

function fixtureNumber(value: number | "NaN"): number {
  return value === "NaN" ? Number.NaN : value;
}

function parseCssHexToken(css: string, mode: "light" | "dark", token: string): { readonly red: number; readonly green: number; readonly blue: number } {
  const source = mode === "light"
    ? css.match(/\[data-theme="light"\]\s*\{(?<body>[\s\S]*?)\n\}/)?.groups?.body ?? ""
    : css.match(/\[data-theme="dark"\]\s*\{(?<body>[\s\S]*?)\n\}/)?.groups?.body ?? "";
  const match = source.match(new RegExp(`--ch-color-${token}:\\s*(#[0-9A-Fa-f]{6});`));
  if (match === null) {
    throw new Error(`Missing ${mode} CSS token: ${token}`);
  }
  const hex = match[1]!.slice(1);
  return {
    red: Number.parseInt(hex.slice(0, 2), 16) / 255,
    green: Number.parseInt(hex.slice(2, 4), 16) / 255,
    blue: Number.parseInt(hex.slice(4, 6), 16) / 255,
  };
}

function symbolCounts(symbols: readonly { readonly kind: MorseSymbolKind }[]): Record<MorseSymbolKind, number> {
  return {
    dot: symbols.filter((symbol) => symbol.kind === "dot").length,
    dash: symbols.filter((symbol) => symbol.kind === "dash").length,
    intraCharacterGap: symbols.filter((symbol) => symbol.kind === "intraCharacterGap").length,
    interCharacterGap: symbols.filter((symbol) => symbol.kind === "interCharacterGap").length,
    wordGap: symbols.filter((symbol) => symbol.kind === "wordGap").length,
  };
}

function expectSymbols(
  actual: readonly { readonly kind: MorseSymbolKind; readonly startSeconds: number; readonly character?: string }[],
  expected: readonly { readonly kind: MorseSymbolKind; readonly startSeconds: number; readonly character?: string }[],
  testCaseId: string,
): void {
  expect(actual.length, testCaseId).toBe(expected.length);
  actual.forEach((symbol, index) => {
    const expectedSymbol = expected[index]!;
    expect(symbol.kind, `${testCaseId} symbol ${index} kind`).toBe(expectedSymbol.kind);
    expect(symbol.character, `${testCaseId} symbol ${index} character`).toBe(expectedSymbol.character);
    expect(round(symbol.startSeconds, 12), `${testCaseId} symbol ${index} startSeconds`).toBeCloseTo(expectedSymbol.startSeconds, 12);
  });
}

function expectFixtureError(action: () => unknown, expectedError: any, testCaseId: string): void {
  try {
    action();
  } catch (error) {
    if (expectedError.type === "invalidCharacters") {
      expect(error, testCaseId).toBeInstanceOf(MorseValidationError);
      expect((error as MorseValidationError).invalidCharacters, testCaseId).toEqual(expectedError.invalidCharacters);
      return;
    }
    if (expectedError.type === "invalidSpeed") {
      expect(error, testCaseId).toBeInstanceOf(RangeError);
      expect((error as Error).message, testCaseId).toContain(expectedError.messageContains);
      return;
    }
    throw new Error(`unsupported expected error type: ${expectedError.type}`);
  }
  throw new Error(`${testCaseId} should have thrown ${expectedError.type}`);
}

function round(value: number, places: number): number {
  const factor = 10 ** places;
  return Math.round(value * factor) / factor;
}
