import assert from "node:assert/strict";
import { afterEach, beforeEach, describe, it } from "vitest";
import { IDBFactory } from "fake-indexeddb";

import { bankId } from "../data/bank";
import { ProgressStore, defaultPreferences, validateProgressImport } from "./progressStore";
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
