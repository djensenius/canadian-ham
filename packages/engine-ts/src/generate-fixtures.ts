import { realpathSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import {
  RNG_ALGORITHM,
  SYNTHETIC_ADVANCED_BANK_ID,
  applyAnswer,
  applyAnswerSequence,
  appendRecentResult,
  buildSubsectionsFromQuestions,
  categoryCounts,
  computeReadiness,
  dueCount,
  dueQuestionIds,
  firstUint32Values,
  generateExam,
  scoreExam,
  weakSubsectionIds,
  type ExamSubsectionInput,
  type QuestionProgressRecord,
  type ReadinessExamAttempt,
  type ScoreInputItem,
} from "./index.ts";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "../../..");
const bankPath = "content/generated/basic-2025-07-15/questions.json";
const bankId = "basic-2025-07-15";
const advancedBankPath = "content/generated/advanced-2025-02-04/questions.json";
const advancedSubsectionsPath = "content/generated/advanced-2025-02-04/subsections.json";
const advancedBankId = "advanced-2025-02-04";
const advancedFixtureSeed = "advanced-2025-02-04-real-bank-fixture-001";
const fixtureSeed = "fixture-seed-001";

interface QuestionJson {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
}

async function main(): Promise<void> {
  const checkMode = process.argv.includes("--check");
  const fixtures = await buildFixtures();
  let hasDrift = false;

  for (const [relativePath, value] of fixtures) {
    const targetPath = join(repoRoot, relativePath);
    const next = stableJson(value);
    if (checkMode) {
      let current = "";
      try {
        current = await readFile(targetPath, "utf8");
      } catch (error) {
        throw new Error(`fixture is missing: ${relativePath}`, { cause: error });
      }
      if (current !== next) {
        hasDrift = true;
        console.error(`fixture drift: ${relativePath}`);
      }
    } else {
      await writeFile(targetPath, next, "utf8");
      console.log(`wrote ${relativePath}`);
    }
  }

  if (hasDrift) {
    process.exitCode = 1;
  } else if (checkMode) {
    console.log("fixtures are up to date");
  }
}

async function buildFixtures(): Promise<Map<string, unknown>> {
  const questions = JSON.parse(await readFile(join(repoRoot, bankPath), "utf8")) as QuestionJson[];
  const fullSubsections = buildSubsectionsFromQuestions(questions);
  const fullExam = generateExam({
    bankId,
    seed: fixtureSeed,
    subsections: fullSubsections,
    answerSourceIndexes: [0, 1, 2, 3],
    requireFullMockExam: true,
  });
  const advancedSubsections = (JSON.parse(await readFile(join(repoRoot, advancedSubsectionsPath), "utf8")) as ExamSubsectionInput[])
    .map((subsection) => ({ id: subsection.id, questionIds: subsection.questionIds }));
  const advancedExam = generateExam({
    bankId: advancedBankId,
    seed: advancedFixtureSeed,
    subsections: advancedSubsections,
    answerSourceIndexes: [0, 1, 2, 3],
    requireFullMockExam: true,
  });

  return new Map([
    ["fixtures/engine/rng-vectors.json", buildRngVectorsFixture()],
    ["fixtures/engine/exam-generation-small.json", buildSmallExamFixture()],
    ["fixtures/engine/exam-generation-full-bank-basic-2025-07-15.json", buildFullExamFixture(fullSubsections, fullExam)],
    ["fixtures/engine/exam-generation-advanced-synthetic.json", buildAdvancedExamFixture()],
    ["fixtures/engine/exam-generation-advanced-2025-02-04.json", buildRealAdvancedExamFixture(advancedSubsections, advancedExam)],
    ["fixtures/engine/scoring.json", buildScoringFixture()],
    ["fixtures/engine/scoring-advanced-2025-02-04.json", buildRealAdvancedScoringFixture(advancedExam)],
    ["fixtures/engine/weak-subsections.json", buildWeakSubsectionsFixture()],
    ["fixtures/engine/leitner.json", buildLeitnerFixture()],
    ["fixtures/engine/readiness.json", buildReadinessFixture()],
  ]);
}

function buildRngVectorsFixture(): unknown {
  const seeds = ["fixture-seed-001", "", "Canadian ham — Basic 2025 🇨🇦"];
  return {
    schemaVersion: 1,
    kind: "rng-vectors",
    cases: seeds.map((seed) => ({
      id: `rng-vector-${slug(seed)}`,
      rng: { algorithm: RNG_ALGORITHM, seed },
      expectedOutput: { first8Uint32: firstUint32Values(seed, 8) },
    })),
  };
}

function buildSmallExamFixture(): unknown {
  const input = {
    subsections: [
      { id: "B-001-001", questionIds: ["B-001-001-004", "B-001-001-003", "B-001-001-002", "B-001-001-001"] },
      { id: "B-001-002", questionIds: ["B-001-002-004", "B-001-002-003", "B-001-002-002", "B-001-002-001"] },
      { id: "B-002-001", questionIds: ["B-002-001-004", "B-002-001-003", "B-002-001-002", "B-002-001-001"] },
    ],
    answerSourceIndexes: [0, 1, 2, 3],
  };
  const generated = generateExam({ bankId, seed: fixtureSeed, ...input });
  return {
    schemaVersion: 1,
    kind: "exam-generation",
    id: "exam-generation-small-fixture-001",
    bankId,
    rng: { algorithm: RNG_ALGORITHM, seed: fixtureSeed },
    input,
    expectedOutput: {
      items: generated.items,
      examQuestionCount: 3,
      oneQuestionPerInputSubsection: true,
      choicePermutationDefinition: "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer",
      categoryCounts: categoryCounts(generated.items),
    },
  };
}

function buildAdvancedExamFixture(): unknown {
  const subsections = buildAdvancedSubsections();
  const generated = generateExam({
    bankId: SYNTHETIC_ADVANCED_BANK_ID,
    seed: fixtureSeed,
    subsections,
    answerSourceIndexes: [0, 1, 2, 3],
    requireFullMockExam: true,
  });
  return {
    schemaVersion: 1,
    kind: "exam-generation",
    id: "exam-generation-advanced-synthetic-fixture-001",
    bankId: SYNTHETIC_ADVANCED_BANK_ID,
    rng: { algorithm: RNG_ALGORITHM, seed: fixtureSeed },
    input: {
      subsections,
      answerSourceIndexes: [0, 1, 2, 3],
      requireFullMockExam: true,
    },
    expectedOutput: {
      items: generated.items,
      examQuestionCount: 50,
      oneQuestionPerInputSubsection: true,
      choicePermutationDefinition: "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer",
      categoryCounts: {
        "A-001": 5,
        "A-002": 12,
        "A-003": 6,
        "A-004": 4,
        "A-005": 9,
        "A-006": 5,
        "A-007": 9,
      },
    },
  };
}

function buildFullExamFixture(subsections: ReturnType<typeof buildSubsectionsFromQuestions>, generated: ReturnType<typeof generateExam>): unknown {
  return {
    schemaVersion: 1,
    kind: "exam-generation",
    id: "exam-generation-full-bank-basic-2025-07-15-fixture-001",
    bankId,
    rng: { algorithm: RNG_ALGORITHM, seed: fixtureSeed },
    input: {
      sourceQuestionBankPath: bankPath,
      subsections,
      answerSourceIndexes: [0, 1, 2, 3],
      requireFullMockExam: true,
    },
    expectedOutput: {
      items: generated.items,
      examQuestionCount: 100,
      oneQuestionPerInputSubsection: true,
      choicePermutationDefinition: "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer",
      categoryCounts: {
        "B-001": 25,
        "B-002": 9,
        "B-003": 21,
        "B-004": 6,
        "B-005": 13,
        "B-006": 13,
        "B-007": 8,
        "B-008": 5,
      },
    },
  };
}

function buildRealAdvancedExamFixture(subsections: readonly ExamSubsectionInput[], generated: ReturnType<typeof generateExam>): unknown {
  return {
    schemaVersion: 1,
    kind: "exam-generation",
    id: "exam-generation-advanced-2025-02-04-real-bank-001",
    bankId: advancedBankId,
    rng: { algorithm: RNG_ALGORITHM, seed: advancedFixtureSeed },
    input: {
      sourceQuestionBankPath: advancedBankPath,
      subsections,
      answerSourceIndexes: [0, 1, 2, 3],
      requireFullMockExam: true,
    },
    expectedOutput: {
      items: generated.items,
      examQuestionCount: 50,
      oneQuestionPerInputSubsection: true,
      choicePermutationDefinition: "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer",
      categoryCounts: {
        "A-001": 5,
        "A-002": 12,
        "A-003": 6,
        "A-004": 4,
        "A-005": 9,
        "A-006": 5,
        "A-007": 9,
      },
    },
  };
}

function buildRealAdvancedScoringFixture(generated: ReturnType<typeof generateExam>): unknown {
  const items = generated.items.map((item, index) => ({
    questionId: item.questionId,
    categoryId: item.categoryId,
    subsectionId: item.subsectionId,
    selectedSourceIndex: index < 40 ? 0 : 1,
  }));
  return {
    schemaVersion: 1,
    kind: "scoring",
    cases: [
      {
        id: "scoring-advanced-2025-02-04-80-percent-no-honours",
        input: { bankId: advancedBankId, items },
        expectedOutput: scoreExam(items, { bankId: advancedBankId }),
      },
    ],
  };
}

function buildScoringFixture(): unknown {
  const boundaryScores = [0, 69, 70, 79, 80, 100];
  const cases = boundaryScores.map((correctCount) => {
    const items = makeBoundaryItems(correctCount);
    return {
      id: `scoring-boundary-${correctCount}`,
      input: { bankId, items },
      expectedOutput: scoreExam(items, { bankId }),
    };
  });

  const unansweredItems: ScoreInputItem[] = [
    { questionId: "B-001-001-001", categoryId: "B-001", subsectionId: "B-001-001", selectedSourceIndex: 0 },
    { questionId: "B-001-001-002", categoryId: "B-001", subsectionId: "B-001-001", selectedSourceIndex: null },
    { questionId: "B-002-001-001", categoryId: "B-002", subsectionId: "B-002-001", selectedSourceIndex: 0 },
    { questionId: "B-002-001-002", categoryId: "B-002", subsectionId: "B-002-001", selectedSourceIndex: 2 },
    { questionId: "B-003-001-001", categoryId: "B-003", subsectionId: "B-003-001", selectedSourceIndex: null },
    { questionId: "B-003-001-002", categoryId: "B-003", subsectionId: "B-003-001", selectedSourceIndex: 0 },
  ];
  cases.push({
    id: "scoring-unanswered-and-category-breakdown",
    input: { bankId, items: unansweredItems },
    expectedOutput: scoreExam(unansweredItems, { bankId }),
  });

  const advancedItems = makeAdvancedBoundaryItems(40);
  cases.push({
    id: "scoring-advanced-has-no-honours-at-eighty-percent",
    input: { bankId: SYNTHETIC_ADVANCED_BANK_ID, items: advancedItems },
    expectedOutput: scoreExam(advancedItems, { bankId: SYNTHETIC_ADVANCED_BANK_ID }),
  });

  return {
    schemaVersion: 1,
    kind: "scoring",
    cases,
  };
}

function buildWeakSubsectionsFixture(): unknown {
  const records = [
    makeProgress("B-001-001-001", [true, false]),
    makeProgress("B-001-002-001", [true, true, false]),
    makeProgress("B-001-003-001", [true, true, false, true]),
    makeProgress("B-001-004-001", [false]),
  ];
  const latestExamItems = [
    { questionId: "B-001-005-001", subsectionId: "B-001-005", selectedSourceIndex: 1 },
    { questionId: "B-001-006-001", subsectionId: "B-001-006", selectedSourceIndex: null },
    { questionId: "B-001-007-001", subsectionId: "B-001-007", selectedSourceIndex: 0 },
  ];
  const pooledWeakRecords = [makeProgress("B-001-008-001", [false]), makeProgress("B-001-008-002", [true])];
  const pooledExactlySeventyRecords = [
    makeProgress("B-001-009-001", [true, true, true, true, true]),
    makeProgress("B-001-009-002", [true, true, false, false, false]),
  ];
  const pooledSingleAttemptRecords = [makeProgress("B-001-010-001", [false])];

  return {
    schemaVersion: 1,
    kind: "weak-subsections",
    recentResultCases: [
      {
        id: "recent-results-append-truncates-to-five-oldest-to-newest",
        input: { existing: [true, false, true, false, true], newest: false },
        expectedOutput: { recentResults: appendRecentResult([true, false, true, false, true], false) },
      },
    ],
    cases: [
      {
        id: "weak-subsections-threshold-and-latest-exam-misses",
        input: { records, latestExamItems },
        expectedOutput: { weakSubsectionIds: weakSubsectionIds(records, latestExamItems) },
      },
      {
        id: "weak-subsections-pooled-records-below-seventy-are-weak",
        input: { records: pooledWeakRecords, latestExamItems: [] },
        expectedOutput: { weakSubsectionIds: weakSubsectionIds(pooledWeakRecords) },
      },
      {
        id: "weak-subsections-pooled-records-at-exactly-seventy-are-not-weak",
        input: { records: pooledExactlySeventyRecords, latestExamItems: [] },
        expectedOutput: { weakSubsectionIds: weakSubsectionIds(pooledExactlySeventyRecords) },
      },
      {
        id: "weak-subsections-pooled-single-attempt-is-not-weak",
        input: { records: pooledSingleAttemptRecords, latestExamItems: [] },
        expectedOutput: { weakSubsectionIds: weakSubsectionIds(pooledSingleAttemptRecords) },
      },
    ],
  };
}

function buildLeitnerFixture(): unknown {
  const now = "2026-01-02T00:00:00.000Z";
  const existingBox1DueFuture = makeLeitnerRecord("B-006-004-007", 1, "2026-01-10T00:00:00.000Z");
  const existingBox2 = makeLeitnerRecord("B-006-004-012", 2, "2026-01-05T00:00:00.000Z");
  const existingBox3 = makeLeitnerRecord("B-006-004-008", 3, "2026-01-09T00:00:00.000Z");
  const existingBox4 = makeLeitnerRecord("B-006-004-013", 4, "2026-01-16T00:00:00.000Z");
  const existingBox5 = makeLeitnerRecord("B-006-004-009", 5, "2026-01-20T00:00:00.000Z");

  const answerCases = [
    {
      id: "leitner-unseen-correct-uses-virtual-box-zero-and-promotes-to-box-one",
      input: { existing: null, update: { questionId: "B-006-004-001", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(null, { questionId: "B-006-004-001", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-correct-before-due-still-promotes-and-uses-three-day-box-two-interval",
      input: { existing: existingBox1DueFuture, update: { questionId: "B-006-004-007", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(existingBox1DueFuture, { questionId: "B-006-004-007", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-correct-promotes-box-two-to-three-with-seven-day-interval",
      input: { existing: existingBox2, update: { questionId: "B-006-004-012", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(existingBox2, { questionId: "B-006-004-012", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-correct-promotes-box-three-to-four-with-fourteen-day-interval",
      input: { existing: existingBox3, update: { questionId: "B-006-004-008", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(existingBox3, { questionId: "B-006-004-008", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-correct-promotes-box-four-to-five-with-thirty-day-interval",
      input: { existing: existingBox4, update: { questionId: "B-006-004-013", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(existingBox4, { questionId: "B-006-004-013", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-correct-caps-at-box-five-with-thirty-day-interval",
      input: { existing: existingBox5, update: { questionId: "B-006-004-009", bankId, isCorrect: true, now } },
      expectedOutput: { record: applyAnswer(existingBox5, { questionId: "B-006-004-009", bankId, isCorrect: true, now }) },
    },
    {
      id: "leitner-incorrect-resets-to-box-zero-and-is-due-immediately",
      input: { existing: existingBox3, update: { questionId: "B-006-004-008", bankId, isCorrect: false, now } },
      expectedOutput: { record: applyAnswer(existingBox3, { questionId: "B-006-004-008", bankId, isCorrect: false, now }) },
    },
  ];

  const sequenceUpdates = [
    { questionId: "B-006-004-010", bankId, isCorrect: true, now: "2026-01-02T00:00:00.000Z" },
    { questionId: "B-006-004-010", bankId, isCorrect: false, now: "2026-01-02T01:00:00.000Z" },
    { questionId: "B-006-004-011", bankId, isCorrect: false, now: "2026-01-02T01:05:00.000Z" },
  ];
  const dueRecords = [
    { ...makeProgress("B-006-004-001", [false]), leitner: { box: 0, dueAt: "2026-01-02T00:00:00.000Z" } },
    { ...makeProgress("B-006-004-002", [true]), leitner: { box: 1, dueAt: "2026-01-01T00:00:00.000Z" } },
    { ...makeProgress("B-006-004-003", [true]), leitner: { box: 1, dueAt: "2026-01-03T00:00:00.000Z" } },
  ];

  return {
    schemaVersion: 1,
    kind: "leitner",
    answerCases,
    sequenceCases: [
      {
        id: "leitner-repeated-session-answers-apply-in-order",
        input: { initialRecords: [], updates: sequenceUpdates },
        expectedOutput: { records: applyAnswerSequence([], sequenceUpdates) },
      },
    ],
    dueCases: [
      {
        id: "leitner-new-user-with-zero-progress-records-has-due-count-zero",
        input: { records: [], now },
        expectedOutput: { dueQuestionIds: dueQuestionIds([], now), dueCount: dueCount([], now) },
      },
      {
        id: "leitner-due-count-includes-records-due-at-or-before-now-only",
        input: { records: dueRecords, now },
        expectedOutput: { dueQuestionIds: dueQuestionIds(dueRecords, now), dueCount: dueCount(dueRecords, now) },
      },
    ],
  };
}

function buildReadinessFixture(): unknown {
  const cases = [
    makeReadinessCase("readiness-new-user-not-enough-data-and-due-count-zero", [], 0),
    makeReadinessCase("readiness-one-exam-not-enough-data", [makeAttempt("2026-01-03T00:00:00.000Z", 95)], 0),
    makeReadinessCase(
      "readiness-last-three-aggregation-ignores-older-exam-and-sorts-shuffled-input",
      [
        makeAttempt("2026-01-04T00:00:00.000Z", 81),
        makeAttempt("2026-01-02T00:00:00.000Z", 40, { "B-001": { correct: 0, total: 10 } }),
        makeAttempt("2026-01-05T00:00:00.000Z", 82),
        makeAttempt("2026-01-03T00:00:00.000Z", 72),
      ],
      0,
    ),
    makeReadinessCase(
      "readiness-category-weakness-precedes-due-review",
      [
        makeAttempt("2026-01-05T00:00:00.000Z", 95, { "B-003": { correct: 6, total: 10 } }),
        makeAttempt("2026-01-04T00:00:00.000Z", 95, { "B-003": { correct: 7, total: 10 } }),
      ],
      5,
    ),
    makeReadinessCase(
      "readiness-due-review-precedes-pass-or-honours-ready",
      [makeAttempt("2026-01-05T00:00:00.000Z", 90), makeAttempt("2026-01-04T00:00:00.000Z", 88)],
      5,
    ),
    makeReadinessCase(
      "readiness-due-review-count-four-still-allows-honours-ready",
      [makeAttempt("2026-01-05T00:00:00.000Z", 90), makeAttempt("2026-01-04T00:00:00.000Z", 88)],
      4,
    ),
    makeReadinessCase(
      "readiness-honours-ready-with-two-of-last-three-at-or-above-eighty",
      [makeAttempt("2026-01-05T00:00:00.000Z", 83), makeAttempt("2026-01-04T00:00:00.000Z", 79), makeAttempt("2026-01-03T00:00:00.000Z", 80)],
      0,
    ),
    makeReadinessCase(
      "readiness-pass-ready-with-two-of-last-three-at-or-above-seventy",
      [makeAttempt("2026-01-05T00:00:00.000Z", 75), makeAttempt("2026-01-04T00:00:00.000Z", 79), makeAttempt("2026-01-03T00:00:00.000Z", 65)],
      0,
    ),
    makeReadinessCase(
      "readiness-needs-review-when-exam-thresholds-not-met",
      [makeAttempt("2026-01-05T00:00:00.000Z", 69), makeAttempt("2026-01-04T00:00:00.000Z", 65)],
      0,
    ),
    makeReadinessCase(
      "readiness-advanced-suppresses-honours-ready-at-eighty-percent",
      [makeAdvancedAttempt("2026-01-05T00:00:00.000Z", 45), makeAdvancedAttempt("2026-01-04T00:00:00.000Z", 40)],
      0,
      SYNTHETIC_ADVANCED_BANK_ID,
    ),
  ];

  return {
    schemaVersion: 1,
    kind: "readiness",
    cases,
  };
}

function buildAdvancedSubsections(): ReturnType<typeof buildSubsectionsFromQuestions> {
  const categorySubsectionCounts = [
    ["A-001", 5],
    ["A-002", 12],
    ["A-003", 6],
    ["A-004", 4],
    ["A-005", 9],
    ["A-006", 5],
    ["A-007", 9],
  ] as const;
  const questions: QuestionJson[] = [];
  for (const [categoryId, subsectionCount] of categorySubsectionCounts) {
    for (let subsectionIndex = 1; subsectionIndex <= subsectionCount; subsectionIndex += 1) {
      const subsectionId = `${categoryId}-${String(subsectionIndex).padStart(3, "0")}`;
      for (let questionIndex = 1; questionIndex <= 2; questionIndex += 1) {
        questions.push({
          id: `${subsectionId}-${String(questionIndex).padStart(3, "0")}`,
          bankId: SYNTHETIC_ADVANCED_BANK_ID,
          categoryId,
          subsectionId,
        });
      }
    }
  }
  return buildSubsectionsFromQuestions(questions);
}

function makeBoundaryItems(correctCount: number): ScoreInputItem[] {
  const categoryCountsById = [
    ["B-001", 25],
    ["B-002", 9],
    ["B-003", 21],
    ["B-004", 6],
    ["B-005", 13],
    ["B-006", 13],
    ["B-007", 8],
    ["B-008", 5],
  ] as const;
  const items: ScoreInputItem[] = [];
  for (const [categoryId, count] of categoryCountsById) {
    for (let index = 1; index <= count; index += 1) {
      const questionId = `${categoryId}-001-${String(index).padStart(3, "0")}`;
      items.push({
        questionId,
        categoryId,
        subsectionId: `${categoryId}-001`,
        selectedSourceIndex: items.length < correctCount ? 0 : 1,
      });
    }
  }
  return items;
}

function makeAdvancedBoundaryItems(correctCount: number): ScoreInputItem[] {
  return buildAdvancedSubsections().map((subsection, index) => ({
    questionId: subsection.questionIds[0]!,
    categoryId: subsection.id.slice(0, 5),
    subsectionId: subsection.id,
    selectedSourceIndex: index < correctCount ? 0 : 1,
  }));
}

function makeProgress(questionId: string, recentResults: readonly boolean[]): QuestionProgressRecord {
  const correctAttempts = recentResults.filter(Boolean).length;
  const lastCorrect = recentResults.at(-1) ?? false;
  return {
    questionId,
    bankId,
    attempts: recentResults.length,
    correctAttempts,
    lastAttemptedAt: "2026-01-01T00:00:00.000Z",
    lastResult: lastCorrect ? "correct" : "incorrect",
    recentResults,
    leitner: {
      box: lastCorrect ? 1 : 0,
      dueAt: lastCorrect ? "2026-01-02T00:00:00.000Z" : "2026-01-01T00:00:00.000Z",
    },
    notes: null,
  };
}

function makeLeitnerRecord(questionId: string, box: 1 | 2 | 3 | 4 | 5, dueAt: string): QuestionProgressRecord {
  const recentResults = Array.from({ length: box }, () => true);
  return {
    ...makeProgress(questionId, recentResults),
    attempts: box,
    correctAttempts: box,
    lastAttemptedAt: "2026-01-01T00:00:00.000Z",
    lastResult: "correct",
    leitner: { box, dueAt },
  };
}

function makeAttempt(
  submittedAt: string,
  correct: number,
  categoryOverrides: Record<string, { correct: number; total: number }> = {},
): ReadinessExamAttempt {
  const categories = ["B-001", "B-002", "B-003", "B-004", "B-005", "B-006", "B-007", "B-008"];
  const categoryBreakdown = categories.map((categoryId) => {
    const value = categoryOverrides[categoryId] ?? { correct: 9, total: 10 };
    return {
      categoryId,
      correct: value.correct,
      total: value.total,
      percent: (value.correct / value.total) * 100,
    };
  });
  return {
    submittedAt,
    score: { correct, total: 100, percent: correct },
    categoryBreakdown,
  };
}

function makeAdvancedAttempt(submittedAt: string, correct: number): ReadinessExamAttempt {
  const categoryBreakdown = ["A-001", "A-002", "A-003", "A-004", "A-005", "A-006", "A-007"].map((categoryId) => ({
    categoryId,
    correct: 8,
    total: 10,
    percent: 80,
  }));
  return {
    submittedAt,
    score: { correct, total: 50, percent: (correct / 50) * 100 },
    categoryBreakdown,
  };
}

function makeReadinessCase(id: string, completedExams: readonly ReadinessExamAttempt[], dueReviewCount: number, readinessBankId = bankId): unknown {
  const input = { bankId: readinessBankId, completedExams, dueReviewCount };
  return { id, input, expectedOutput: computeReadiness(input) };
}

function slug(value: string): string {
  return value === "" ? "empty-string" : value.toLowerCase().replace(/[^a-z0-9]+/gu, "-").replace(/^-|-$/gu, "");
}

function stableJson(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

function isMainModule(): boolean {
  const metaWithMain = import.meta as ImportMeta & { readonly main?: unknown };
  if ("main" in metaWithMain) {
    return metaWithMain.main === true;
  }
  if (process.argv[1] === undefined) {
    return false;
  }
  try {
    return import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
}

if (isMainModule()) {
  await main();
}
