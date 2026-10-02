import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import {
  RNG_ALGORITHM,
  applyAnswer,
  applyAnswerSequence,
  appendRecentResult,
  categoryCounts,
  computeReadiness,
  dueCount,
  dueQuestionIds,
  firstUint32Values,
  generateExam,
  scoreExam,
  weakSubsectionIds,
} from "../src/index.ts";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const fixturesRoot = join(repoRoot, "fixtures/engine");

const fixturePaths = await jsonFiles(fixturesRoot);

test("every fixtures/engine/**/*.json engine fixture matches the TypeScript engine", async (t) => {
  assert.ok(fixturePaths.length > 0, "expected at least one fixture JSON file");
  for (const fixturePath of fixturePaths) {
    const relativePath = fixturePath.slice(repoRoot.length + 1);
    const fixture = JSON.parse(await readFile(fixturePath, "utf8"));
    await t.test(relativePath, () => validateFixture(fixture));
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
  assert.equal(fixture.schemaVersion, 1);
  switch (fixture.kind) {
    case "rng-vectors":
      validateRngVectors(fixture);
      break;
    case "exam-generation":
      validateExamGeneration(fixture);
      break;
    case "scoring":
      validateScoring(fixture);
      break;
    case "weak-subsections":
      validateWeakSubsections(fixture);
      break;
    case "leitner":
      validateLeitner(fixture);
      break;
    case "readiness":
      validateReadiness(fixture);
      break;
    default:
      throw new Error(`unsupported fixture kind: ${fixture.kind}`);
  }
}

function validateRngVectors(fixture: any): void {
  for (const vector of fixture.cases) {
    assert.equal(vector.rng.algorithm, RNG_ALGORITHM);
    assert.deepEqual(firstUint32Values(vector.rng.seed, 8), vector.expectedOutput.first8Uint32, vector.id);
  }
}

function validateExamGeneration(fixture: any): void {
  assert.equal(fixture.rng.algorithm, RNG_ALGORITHM);
  const generated = generateExam({
    bankId: fixture.bankId,
    seed: fixture.rng.seed,
    subsections: fixture.input.subsections,
    answerSourceIndexes: fixture.input.answerSourceIndexes,
    requireFullMockExam: fixture.input.requireFullMockExam ?? false,
  });

  assert.deepEqual(generated.items, fixture.expectedOutput.items, fixture.id);
  assert.equal(generated.items.length, fixture.expectedOutput.examQuestionCount);
  assert.deepEqual(categoryCounts(generated.items), fixture.expectedOutput.categoryCounts);

  const inputSubsectionIds = new Set(fixture.input.subsections.map((subsection: any) => subsection.id));
  const outputSubsectionIds = new Set(generated.items.map((item) => item.subsectionId));
  if (fixture.expectedOutput.oneQuestionPerInputSubsection) {
    assert.equal(outputSubsectionIds.size, inputSubsectionIds.size);
    assert.deepEqual([...outputSubsectionIds].toSorted(), [...inputSubsectionIds].toSorted());
  }

  for (const item of generated.items) {
    assert.deepEqual([...item.choicePermutation].toSorted(), [0, 1, 2, 3]);
  }
}

function validateScoring(fixture: any): void {
  for (const testCase of fixture.cases) {
    assert.deepEqual(scoreExam(testCase.input.items, { bankId: testCase.input.bankId }), testCase.expectedOutput, testCase.id);
  }
}

function validateWeakSubsections(fixture: any): void {
  for (const testCase of fixture.recentResultCases) {
    assert.deepEqual(
      { recentResults: appendRecentResult(testCase.input.existing, testCase.input.newest) },
      testCase.expectedOutput,
      testCase.id,
    );
  }
  for (const testCase of fixture.cases) {
    assert.deepEqual(
      { weakSubsectionIds: weakSubsectionIds(testCase.input.records, testCase.input.latestExamItems) },
      testCase.expectedOutput,
      testCase.id,
    );
  }
}

function validateLeitner(fixture: any): void {
  for (const testCase of fixture.answerCases) {
    assert.deepEqual(
      { record: applyAnswer(testCase.input.existing, testCase.input.update) },
      testCase.expectedOutput,
      testCase.id,
    );
  }
  for (const testCase of fixture.sequenceCases) {
    assert.deepEqual(
      { records: applyAnswerSequence(testCase.input.initialRecords, testCase.input.updates) },
      testCase.expectedOutput,
      testCase.id,
    );
  }
  for (const testCase of fixture.dueCases) {
    assert.deepEqual(
      {
        dueQuestionIds: dueQuestionIds(testCase.input.records, testCase.input.now),
        dueCount: dueCount(testCase.input.records, testCase.input.now),
      },
      testCase.expectedOutput,
      testCase.id,
    );
  }
}

function validateReadiness(fixture: any): void {
  for (const testCase of fixture.cases) {
    assert.deepEqual(computeReadiness(testCase.input), testCase.expectedOutput, testCase.id);
  }
}
