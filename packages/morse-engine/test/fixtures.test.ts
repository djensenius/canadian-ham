import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import {
  farnsworthTiming,
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
    case "morse-validation":
      validateValidationFixture(fixture);
      break;
    default:
      throw new Error(`unsupported fixture kind: ${fixture.kind}`);
  }
}

function validateTimingFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    const profile = profileFromFixture(testCase.input.profile);
    const sequence = textToTimedMorse(testCase.input.text, profile);
    expect(round(sequence.totalDurationSeconds, 9), testCase.id).toBeCloseTo(testCase.expectedOutput.totalDurationSeconds, 9);
    expect(round(sequence.profile.effectiveWpm, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.effectiveWpm, 12);
    expect(round(sequence.profile.dotSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.dot, 12);
    expect(round(sequence.profile.dashSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.dash, 12);
    expect(round(sequence.profile.intraCharacterGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.intraCharacterGap, 12);
    expect(round(sequence.profile.interCharacterGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.interCharacterGap, 12);
    expect(round(sequence.profile.wordGapSeconds, 12), testCase.id).toBeCloseTo(testCase.expectedOutput.durationsSeconds.wordGap, 12);
    expect(symbolCounts(sequence.symbols), testCase.id).toEqual(testCase.expectedOutput.symbolCounts);
    expect(sequence.symbols.at(-1)?.kind, testCase.id).toBe(testCase.expectedOutput.lastSymbolKind);
  }
}

function validateWordWeightingFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(weightedCharacterCount(testCase.input.text), testCase.id).toEqual({
      weightedCharacters: testCase.expectedOutput.weightedCharacters,
      unweightedCharacters: testCase.expectedOutput.unweightedCharacters,
    });
  }
}

function validateScoringFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(scoreMorseCopy(testCase.input.expected, testCase.input.received), testCase.id).toEqual(testCase.expectedOutput);
  }
}

function validateValidationFixture(fixture: any): void {
  for (const testCase of fixture.cases) {
    expect(validateMorseText(testCase.input.text), testCase.id).toEqual(testCase.expectedOutput);
  }
}

function profileFromFixture(input: { readonly name?: MorseProfileName; readonly characterWpm?: number; readonly effectiveWpm?: number }): MorseTimingProfile {
  if (input.name !== undefined) {
    return profileForName(input.name);
  }
  if (input.characterWpm === undefined || input.effectiveWpm === undefined) {
    throw new Error("fixture profile must name a profile or provide characterWpm/effectiveWpm");
  }
  return farnsworthTiming({ characterWpm: input.characterWpm, effectiveWpm: input.effectiveWpm });
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

function round(value: number, places: number): number {
  const factor = 10 ** places;
  return Math.round(value * factor) / factor;
}
