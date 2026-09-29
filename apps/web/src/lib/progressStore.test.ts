import assert from "node:assert/strict";
import { afterEach, beforeEach, describe, it } from "vitest";
import { IDBFactory } from "fake-indexeddb";

import { bankId } from "../data/bank";
import { ProgressStore, defaultPreferences, validateProgressImport, type ExamAttempt, type ProgressExportV1 } from "./progressStore";
import type { QuestionProgressRecord } from "@canadian-ham/engine-ts";

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

describe("ProgressStore", () => {
  it("stores progress in IndexedDB and exports/imports a validated round trip", async () => {
    const first = createStore("roundtrip-a");
    await first.putQuestionProgress(record);
    await first.putPreferences({ practiceMode: "review-later", examTimerEnabled: true });

    const exported = await first.exportData("2026-01-02T04:00:00.000Z");
    assert.equal(exported.bankId, bankId);
    assert.deepEqual(exported.questionProgress, [record]);
    assert.deepEqual(exported.preferences, { practiceMode: "review-later", examTimerEnabled: true });

    const validation = validateProgressImport(JSON.parse(JSON.stringify(exported)) as unknown);
    assert.equal(validation.ok, true);
    assert.equal(validation.errors.length, 0);

    const second = createStore("roundtrip-b");
    await second.importData(validation.data!);
    assert.deepEqual(await second.getQuestionProgress(), [record]);
    assert.deepEqual(await second.getPreferences(), { practiceMode: "review-later", examTimerEnabled: true });
  });

  it("rejects invalid import data with clear errors", () => {
    const validation = validateProgressImport({ schema: "wrong", version: 99, bankId: "other" });
    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /schema/);
    assert.match(validation.errors.join("\n"), /version/);
    assert.match(validation.errors.join("\n"), /bankId/);
    assert.match(validation.errors.join("\n"), /questionProgress/);
  });

  it("rejects non-canonical timestamps, duplicate submissions, unknown questions, malformed breakdowns, and invalid Leitner boxes", () => {
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
    }));

    assert.equal(validation.ok, false);
    const errors = validation.errors.join("\n");
    assert.match(errors, /canonical UTC timestamp/);
    assert.match(errors, /duplicates another exam attempt/);
    assert.match(errors, /questionId must be a known question ID/);
    assert.match(errors, /categoryBreakdown\[0\]\.percent/);
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

  it("resets all browser-local progress and preferences", async () => {
    const store = createStore("reset");
    await store.putQuestionProgress(record);
    await store.putPreferences({ practiceMode: "review-later", examTimerEnabled: true });

    await store.resetAllData();

    assert.deepEqual(await store.getQuestionProgress(), []);
    assert.deepEqual(await store.getExamAttempts(), []);
    assert.deepEqual(await store.getPreferences(), defaultPreferences);
  });
});
