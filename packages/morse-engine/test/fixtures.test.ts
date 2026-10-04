import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  MORSE_CODE_TABLE,
  MorseValidationError,
  farnsworthTiming,
  generateMorseExamText,
  profileForName,
  scoreMorseCopy,
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

describe("public tables", () => {
  it("freezes the Morse code table so consumers can't change mappings at runtime", () => {
    expect(Object.isFrozen(MORSE_CODE_TABLE)).toBe(true);
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
    case "morse-validation":
      validateValidationFixture(fixture);
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
  }
}

function validateValidationFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(validateMorseText(testCase.input.text), testCase.id).toEqual(testCase.expectedOutput);
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
