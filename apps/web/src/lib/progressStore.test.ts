import assert from "node:assert/strict";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { afterEach, beforeEach, describe, it } from "vitest";
import { IDBFactory } from "fake-indexeddb";

import { bankId } from "../data/bank";
import { ProgressStore, defaultPreferences, validateProgressImport, type ExamAttempt, type LessonProgressRecord, type LessonQuizAttempt, type ProgressExportV1 } from "./progressStore";
import type { QuestionProgressRecord } from "@canadian-ham/engine-ts";
import type { MorseCourseProgressExport } from "@canadian-ham/morse-engine";

const record: QuestionProgressRecord = {
  questionId: "B-001-001-001",
  bankId,
  attempts: 1,
  correctAttempts: 1,
  lastAttemptedAt: "2026-01-02T03:04:05.000Z",
  lastResult: "correct",
  recentResults: [true],
  leitner: { box: 1, dueAt: "2026-01-03T03:04:05.000Z" },
  notes: null,
};

const lessonProgressRecord: LessonProgressRecord = {
  lessonId: "L-005-01",
  readAt: "2026-01-02T03:30:00.000Z",
  readCount: 2,
};

const lessonQuizAttempt: LessonQuizAttempt = {
  id: "lesson-quiz-1",
  quizId: "QZ-L-005-01-A",
  lessonId: "L-005-01",
  submittedAt: "2026-01-02T03:45:00.000Z",
  correct: 9,
  total: 11,
  percent: 81.81818181818183,
  officialQuestionIds: ["B-005-001-001"],
  incorrectOfficialQuestionIds: [],
  incorrectConceptCheckIds: ["QZ-L-005-01-A-C1"],
};

const morseCourseProgress: MorseCourseProgressExport = {
  courseId: "ised-koch-g4fon-v1",
  lessonProgress: [{
    lessonId: "koch-001",
    attempts: 1,
    bestAccuracy: 1,
    lastAccuracy: 1,
    lastAttemptedAt: "2026-01-02T03:50:00.000Z",
    completedAt: "2026-01-02T03:50:00.000Z",
  }],
  characterStats: [{
    character: "K",
    attempts: 1,
    correctAttempts: 1,
    recentResults: [true],
    lastPracticedAt: "2026-01-02T03:50:00.000Z",
  }],
  dailyActivity: [{ date: "2026-01-02", lessonsCompleted: 1 }],
};

const attempt: ExamAttempt = {
  id: "attempt-1",
  bankId,
  mode: "mock-exam",
  seed: "seed-1",
  startedAt: "2026-01-02T02:00:00.000Z",
  submittedAt: "2026-01-02T03:00:00.000Z",
  timer: { enabled: false, secondsAllowed: null, secondsElapsed: 0 },
  items: [{
    position: 1,
    questionId: "B-001-001-001",
    subsectionId: "B-001-001",
    categoryId: "B-001",
    choicePermutation: [0, 1, 2, 3],
    selectedSourceIndex: 0,
    isCorrect: true,
    flagged: false,
  }],
  score: {
    bankId,
    correct: 1,
    total: 1,
    percent: 100,
    passed: true,
    honours: true,
    categoryBreakdown: [{ categoryId: "B-001", correct: 1, total: 1, percent: 100 }],
    weakSubsectionIds: [],
  },
};

function validExport(overrides: Partial<ProgressExportV1> = {}): ProgressExportV1 {
  return {
    schema: "canadian-ham.progress-export",
    version: 1,
    exportedAt: "2026-01-02T04:00:00.000Z",
    bankId,
    questionProgress: [record],
    examAttempts: [attempt],
    lessonProgress: [lessonProgressRecord],
    lessonQuizAttempts: [lessonQuizAttempt],
    morseCourseProgress,
    preferences: defaultPreferences,
    ...overrides,
  };
}

let stores: ProgressStore[] = [];

beforeEach(() => {
  Object.defineProperty(globalThis, "indexedDB", { value: new IDBFactory(), configurable: true });
  stores = [];
});

afterEach(async () => {
  for (const store of stores) {
    await store.deleteDatabase();
  }
});

function createStore(name: string): ProgressStore {
  const store = new ProgressStore(name);
  stores.push(store);
  return store;
}

function assertProgressExportMatchesSchema(exported: ProgressExportV1): void {
  const validatorPath = path.resolve(process.cwd(), "../../packages/schemas/validate-stdin.mjs");
  const result = spawnSync(process.execPath, [validatorPath, "progress-export-v1.schema.json"], {
    input: JSON.stringify(exported),
    encoding: "utf8",
  });
  assert.equal(result.status, 0, `${result.stdout}${result.stderr}`);
  assert.match(result.stdout, /Schema validation passed for stdin against progress-export-v1\.schema\.json/);
}

async function createVersion2Database(name: string): Promise<void> {
  const request = indexedDB.open(name, 2);
  await new Promise<void>((resolve, reject) => {
    request.onupgradeneeded = () => {
      const db = request.result;
      db.createObjectStore("questionProgress", { keyPath: "questionId" });
      const attemptStore = db.createObjectStore("examAttempts", { keyPath: "id" });
      attemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
      db.createObjectStore("preferences", { keyPath: "key" });
    };
    request.onerror = () => reject(request.error ?? new Error("Unable to create v2 test database"));
    request.onsuccess = () => {
      request.result.close();
      resolve();
    };
  });
}

describe("ProgressStore", () => {
  it("stores progress in IndexedDB and exports/imports a validated round trip", async () => {
    const first = createStore("roundtrip-a");
    await first.putQuestionProgress(record);
    await first.putLessonProgress(lessonProgressRecord);
    await first.putLessonQuizAttempt(lessonQuizAttempt);
    await first.putMorseCourseProgress(morseCourseProgress);
    await first.putPreferences({ ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "dark" });

    const exported = await first.exportData("2026-01-02T04:00:00.000Z");
    assert.equal(exported.bankId, bankId);
    assert.deepEqual(exported.questionProgress, [record]);
    assert.deepEqual(exported.lessonProgress, [lessonProgressRecord]);
    assert.deepEqual(exported.lessonQuizAttempts, [lessonQuizAttempt]);
    assert.deepEqual(exported.morseCourseProgress, morseCourseProgress);
    assert.deepEqual(exported.preferences, { ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "dark" });
    assertProgressExportMatchesSchema(exported);

    const validation = validateProgressImport(JSON.parse(JSON.stringify(exported)) as unknown);
    assert.equal(validation.ok, true);
    assert.equal(validation.errors.length, 0);

    const second = createStore("roundtrip-b");
    await second.importData(validation.data!);
    assert.deepEqual(await second.getQuestionProgress(), [record]);
    assert.deepEqual(await second.getLessonProgress(), [lessonProgressRecord]);
    assert.deepEqual(await second.getLessonQuizAttempts(), [lessonQuizAttempt]);
    assert.deepEqual(await second.getMorseCourseProgress(), morseCourseProgress);
    assert.deepEqual(await second.getPreferences(), { ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "dark" });
  });

  it("rejects invalid import data with clear errors", () => {
    const validation = validateProgressImport({ schema: "wrong", version: 99, bankId: "other" });
    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /schema/);
    assert.match(validation.errors.join("\n"), /version/);
    assert.match(validation.errors.join("\n"), /bankId/);
    assert.match(validation.errors.join("\n"), /questionProgress/);
  });

  it("rejects non-canonical timestamps, duplicate submissions, unknown questions, malformed breakdowns, invalid lesson records, and invalid Leitner boxes", () => {
    const badRecord = { ...record, questionId: "B-999-999-999", lastAttemptedAt: "2026-01-02T03:04:05Z", leitner: { box: 6, dueAt: "2026-01-03T03:04:05Z" } };
    const badAttempt = {
      ...attempt,
      submittedAt: attempt.submittedAt,
      items: [{ ...attempt.items[0]!, questionId: "B-999-999-999" }],
      score: { ...attempt.score, categoryBreakdown: [{ categoryId: "B-001", correct: 1, total: 1 }] },
    };
    const validation = validateProgressImport(validExport({
      exportedAt: "2026-01-02T04:00:00Z",
      questionProgress: [badRecord as QuestionProgressRecord],
      examAttempts: [badAttempt as unknown as ExamAttempt, { ...attempt, id: "attempt-duplicate" }],
      lessonProgress: [{ ...lessonProgressRecord, lessonId: "L-999-99", readAt: "2026-01-02T03:30:00Z", readCount: 0 }],
      lessonQuizAttempts: [
        { ...lessonQuizAttempt, quizId: "QZ-NOPE", lessonId: "L-005-02", submittedAt: "2026-01-02T03:45:00Z", percent: Number.NaN, incorrectConceptCheckIds: [] },
        { ...lessonQuizAttempt, id: "lesson-quiz-bad-concept", incorrectConceptCheckIds: ["missing"] },
        { ...lessonQuizAttempt, id: "lesson-quiz-bad-subsets", correct: 1, total: 2, percent: 40, officialQuestionIds: ["B-001-001-001"], incorrectOfficialQuestionIds: ["B-005-001-001"], incorrectConceptCheckIds: [] },
      ],
    }));

    assert.equal(validation.ok, false);
    const errors = validation.errors.join("\n");
    assert.match(errors, /canonical UTC timestamp/);
    assert.match(errors, /duplicates another exam attempt/);
    assert.match(errors, /questionId must be a known question ID/);
    assert.match(errors, /categoryBreakdown\[0\]\.percent/);
    assert.match(errors, /lessonProgress\[0\]\.lessonId/);
    assert.match(errors, /readCount/);
    assert.match(errors, /lessonQuizAttempts\[0\]\.quizId/);
    assert.match(errors, /lessonQuizAttempts\[0\]\.percent/);
    assert.match(errors, /incorrectConceptCheckIds/);
    assert.match(errors, /percent must match correct divided by total/);
    assert.match(errors, /officialQuestionIds must belong to the lesson quiz/);
    assert.match(errors, /incorrectOfficialQuestionIds must be a subset of officialQuestionIds/);
    assert.match(errors, /leitner\.box/);
  });

  it("resets a failed open promise so a later IndexedDB open can succeed", async () => {
    const store = createStore("retry-open");
    const originalIndexedDB = indexedDB;
    Object.defineProperty(globalThis, "indexedDB", {
      value: { open: () => ({ set onupgradeneeded(_: unknown) {}, set onblocked(_: unknown) {}, set onerror(handler: () => void) { queueMicrotask(handler); }, set onsuccess(_: unknown) {}, get error() { return new Error("first open failed"); } }) },
      configurable: true,
    });
    await assert.rejects(() => store.getQuestionProgress(), /first open failed/);

    Object.defineProperty(globalThis, "indexedDB", { value: originalIndexedDB, configurable: true });
    assert.deepEqual(await store.getQuestionProgress(), []);
  });

  it("accepts legacy exports without lesson stores as empty v3 data", () => {
    const legacy = { ...validExport(), lessonProgress: undefined, lessonQuizAttempts: undefined };

    const validation = validateProgressImport(legacy);

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.lessonProgress, []);
    assert.deepEqual(validation.data?.lessonQuizAttempts, []);
  });

  it("rejects imports whose score bankId does not match the active bank", () => {
    const validation = validateProgressImport(validExport({
      examAttempts: [{ ...attempt, score: { ...attempt.score, bankId: "advanced-synthetic" } }],
    }));

    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /examAttempts\[0\]\.score\.bankId must be basic-2025-07-15/);
  });

  it("accepts legacy Basic exports without bankId fields and normalizes them", () => {
    const { bankId: _exportBankId, questionProgress, examAttempts, ...legacy } = validExport();
    const legacyQuestionProgress = questionProgress.map(({ bankId: _recordBankId, ...recordWithoutBankId }) => recordWithoutBankId);
    const legacyExamAttempts = examAttempts.map(({ bankId: _attemptBankId, score, ...attemptWithoutBankId }) => {
      const { bankId: _scoreBankId, ...scoreWithoutBankId } = score;
      return { ...attemptWithoutBankId, score: scoreWithoutBankId };
    });

    const validation = validateProgressImport({
      ...legacy,
      questionProgress: legacyQuestionProgress,
      examAttempts: legacyExamAttempts,
    });

    assert.equal(validation.ok, true, validation.errors.join("\n"));
    assert.equal(validation.data?.bankId, bankId);
    assert.equal(validation.data?.questionProgress[0]?.bankId, bankId);
    assert.equal(validation.data?.examAttempts[0]?.bankId, bankId);
    assert.equal(validation.data?.examAttempts[0]?.score.bankId, bankId);
  });

  it("migrates an existing v2 IndexedDB database to v3 lesson stores", async () => {
    await createVersion2Database("migrate-v2-v3");
    const store = createStore("migrate-v2-v3");

    assert.deepEqual(await store.getLessonProgress(), []);
    assert.deepEqual(await store.getLessonQuizAttempts(), []);
    await store.putLessonProgress(lessonProgressRecord);
    await store.putLessonQuizAttemptWithQuestionProgress(lessonQuizAttempt, [record]);

    assert.deepEqual(await store.getLessonProgress(), [lessonProgressRecord]);
    assert.deepEqual(await store.getLessonQuizAttempts(), [lessonQuizAttempt]);
    assert.deepEqual(await store.getQuestionProgress(), [record]);
  });

  it("resets all browser-local progress and preferences", async () => {
    const store = createStore("reset");
    await store.putQuestionProgress(record);
    await store.putLessonProgress(lessonProgressRecord);
    await store.putLessonQuizAttempt(lessonQuizAttempt);
    await store.putMorseCourseProgress(morseCourseProgress);
    await store.putPreferences({ ...defaultPreferences, practiceMode: "review-later", examTimerEnabled: true, theme: "light" });

    await store.resetAllData();

    assert.deepEqual(await store.getQuestionProgress(), []);
    assert.deepEqual(await store.getExamAttempts(), []);
    assert.deepEqual(await store.getLessonProgress(), []);
    assert.deepEqual(await store.getLessonQuizAttempts(), []);
    assert.equal(await store.getMorseCourseProgress(), undefined);
    assert.deepEqual(await store.getPreferences(), defaultPreferences);
  });
});
