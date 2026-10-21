import assert from "node:assert/strict";
import path from "node:path";
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { afterEach, beforeEach, describe, it } from "vitest";
import { IDBFactory } from "fake-indexeddb";

import { advancedBank, bankId } from "../data/bank";
import { ProgressStore, migrateLessonQuizAttempts, migrateLessonProgressRecords, deduplicateDeviceExamAttemptsForSync, deduplicateDeviceLessonProgressForSync, deduplicateDeviceQuestionProgressForSync, defaultPreferences, validateProgressImport, type DeviceExamAttemptRecord, type DeviceLessonProgressRecord, type DeviceLessonQuizAttemptRecord, type DeviceQuestionProgressRecord, type ExamAttempt, type LessonProgressRecord, type LessonQuizAttempt, type ProgressExportV1, type ProgressSyncDeviceRows } from "./progressStore";
import type { QuestionProgressRecord } from "@canadian-ham/engine-ts";
import type { MorseCourseProgressExport } from "@canadian-ham/morse-engine";

const record: QuestionProgressRecord = {
  questionId: "B-001-001-001",
  bankId,
  attempts: 1,
  correctAttempts: 1,
  lastAttemptedAt: "2026-01-02T03:04:05.000Z",
  lastResult: "correct",
  lastAnsweredWithHelp: false,
  recentResults: [true],
  recentAnsweredWithHelp: [false],
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
    lessonIdVersion: 2,
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

const legacySplitQuizAttempt: LessonQuizAttempt = {
  id: "legacy-00504",
  quizId: "QZ-L-005-04-A",
  lessonId: "L-005-04",
  submittedAt: "2026-01-02T03:45:00.000Z",
  correct: 1,
  total: 2,
  percent: 50,
  officialQuestionIds: ["B-005-007-001", "B-005-009-003"],
  incorrectOfficialQuestionIds: ["B-005-009-003"],
  incorrectConceptCheckIds: [],
};

async function createVersion5DatabaseWithLegacyLessonRows(name: string, syncDeviceRows?: ProgressSyncDeviceRows, lessonProgress: readonly LessonProgressRecord[] = [
  { lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 2 },
  { lessonId: "L-008-02", readAt: "2026-01-03T03:30:00.000Z", readCount: 1 },
]): Promise<void> {
  const request = indexedDB.open(name, 5);
  await new Promise<void>((resolve, reject) => {
    request.onupgradeneeded = () => {
      const db = request.result;
      db.createObjectStore("questionProgress", { keyPath: "questionId" });
      const attemptStore = db.createObjectStore("examAttempts", { keyPath: "id" });
      attemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
      db.createObjectStore("preferences", { keyPath: "key" });
      db.createObjectStore("lessonProgress", { keyPath: "lessonId" });
      const quizAttemptStore = db.createObjectStore("lessonQuizAttempts", { keyPath: "id" });
      quizAttemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
      quizAttemptStore.createIndex("lessonId", "lessonId", { unique: false });
      db.createObjectStore("morseCourseProgress", { keyPath: "key" });
      db.createObjectStore("syncMetadata", { keyPath: "key" });
      for (const record of lessonProgress) request.transaction?.objectStore("lessonProgress").put(record);
      request.transaction?.objectStore("lessonQuizAttempts").put(legacySplitQuizAttempt);
      if (syncDeviceRows !== undefined) request.transaction?.objectStore("syncMetadata").put({ key: "syncDeviceRows", value: syncDeviceRows });
    };
    request.onerror = () => reject(request.error ?? new Error("Unable to create v5 test database"));
    request.onsuccess = () => {
      request.result.close();
      resolve();
    };
  });
}

async function createVersion3Database(name: string): Promise<void> {
  const request = indexedDB.open(name, 3);
  await new Promise<void>((resolve, reject) => {
    request.onupgradeneeded = () => {
      const db = request.result;
      db.createObjectStore("questionProgress", { keyPath: "questionId" });
      const attemptStore = db.createObjectStore("examAttempts", { keyPath: "id" });
      attemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
      db.createObjectStore("preferences", { keyPath: "key" });
      db.createObjectStore("lessonProgress", { keyPath: "lessonId" });
      const quizAttemptStore = db.createObjectStore("lessonQuizAttempts", { keyPath: "id" });
      quizAttemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
      quizAttemptStore.createIndex("lessonId", "lessonId", { unique: false });
    };
    request.onerror = () => reject(request.error ?? new Error("Unable to create v3 test database"));
    request.onsuccess = () => {
      request.result.close();
      resolve();
    };
  });
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
  it("deduplicates sync collisions using the shared iCloud merge fixture", () => {
    const fixture = JSON.parse(readFileSync(path.resolve(__dirname, "../../../../fixtures/progress/icloud-merge.json"), "utf8")) as {
      questionProgress: { deviceRows: DeviceQuestionProgressRecord[]; expected: QuestionProgressRecord[] };
      examAttempts: { deviceRows: DeviceExamAttemptRecord[]; expectedIdsBySubmittedAt: Record<string, string> };
      lessonProgress: { deviceRows: DeviceLessonProgressRecord[]; expected: LessonProgressRecord[] };
    };

    assert.deepEqual(deduplicateDeviceQuestionProgressForSync(fixture.questionProgress.deviceRows), fixture.questionProgress.expected);
    assert.deepEqual(deduplicateDeviceQuestionProgressForSync([...fixture.questionProgress.deviceRows].reverse()), fixture.questionProgress.expected);
    assert.deepEqual(deduplicateDeviceQuestionProgressForSync([...fixture.questionProgress.deviceRows, ...fixture.questionProgress.deviceRows]), fixture.questionProgress.expected);
    const examAttempts = deduplicateDeviceExamAttemptsForSync(fixture.examAttempts.deviceRows);
    assert.deepEqual(Object.fromEntries(examAttempts.map((attempt) => [`${attempt.bankId}|${attempt.submittedAt}`, attempt.id])), fixture.examAttempts.expectedIdsBySubmittedAt);
    assert.deepEqual(deduplicateDeviceLessonProgressForSync(fixture.lessonProgress.deviceRows), fixture.lessonProgress.expected);
    assert.deepEqual(deduplicateDeviceLessonProgressForSync([...fixture.lessonProgress.deviceRows, ...fixture.lessonProgress.deviceRows]), fixture.lessonProgress.expected);
  });

  it("does not throw while normalizing malformed sync question rows", () => {
    const malformedRows = {
      questionProgress: [{ deviceId: "iphone" }, "bad-row"],
      examAttempts: [],
      lessonProgress: [],
      lessonQuizAttempts: [],
      morseCourseProgress: [],
    };

    const validation = validateProgressImport(validExport({ syncDeviceRows: malformedRows as never }));

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.syncDeviceRows, malformedRows);
  });

  it("normalizes pre-change IndexedDB question progress rows on read", async () => {
    const { lastAnsweredWithHelp: _lastAnsweredWithHelp, recentAnsweredWithHelp: _recentAnsweredWithHelp, ...legacyRecord } = record;
    const store = createStore("legacy-indexeddb-help-fields");

    await store.putQuestionProgress(legacyRecord as QuestionProgressRecord);

    assert.deepEqual(await store.getQuestionProgress(), [record]);
  });

  it("migrates pre-split lesson progress and quiz attempts during IndexedDB upgrade", async () => {
    await createVersion5DatabaseWithLegacyLessonRows("legacy-lesson-splits");
    const store = createStore("legacy-lesson-splits");

    assert.deepEqual(await store.getLessonProgress(), [
      { lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 2 },
    ]);
    assert.deepEqual(await store.getLessonQuizAttempts(), [
      {
        id: "legacy-00504",
        quizId: "QZ-L-005-04-A",
        lessonId: "L-005-04",
        submittedAt: "2026-01-02T03:45:00.000Z",
        correct: 1,
        total: 1,
        percent: 100,
        officialQuestionIds: ["B-005-007-001"],
        incorrectOfficialQuestionIds: [],
        incorrectConceptCheckIds: [],
      },
      {
        id: "legacy-00504::QZ-L-005-05-A",
        quizId: "QZ-L-005-05-A",
        lessonId: "L-005-05",
        submittedAt: "2026-01-02T03:45:00.000Z",
        correct: 0,
        total: 1,
        percent: 0,
        officialQuestionIds: ["B-005-009-003"],
        incorrectOfficialQuestionIds: ["B-005-009-003"],
        incorrectConceptCheckIds: [],
      },
    ]);
  });

  it("migrates coherent stored device rows during the v6 upgrade and drops incoherent metadata", async () => {
    const rows: DeviceLessonProgressRecord[] = [
      { deviceId: "phone", record: { lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 5 } },
      { deviceId: "phone", record: { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 } },
      { deviceId: "tablet", record: { lessonId: "L-005-04", readAt: "2026-01-04T03:30:00.000Z", readCount: 1 } },
      { deviceId: "tablet", record: { lessonId: "L-005-05", readAt: "2026-01-05T03:30:00.000Z", readCount: 4 } },
    ];
    const syncDeviceRows: ProgressSyncDeviceRows = {
      questionProgress: [], examAttempts: [], lessonProgress: rows,
      lessonQuizAttempts: [{ deviceId: "phone", attempt: legacySplitQuizAttempt }], morseCourseProgress: [],
    };
    const rawProgress = deduplicateDeviceLessonProgressForSync(rows);
    const expected = validateProgressImport(validExport({
      lessonIdVersion: 1, questionProgress: [], examAttempts: [], lessonProgress: rawProgress,
      lessonQuizAttempts: [legacySplitQuizAttempt], morseCourseProgress: undefined, syncDeviceRows,
    }));
    assert.equal(expected.ok, true, expected.errors.join("\n"));
    for (const coherent of [true, false]) {
      const name = `v6-device-migration-${coherent}`;
      await createVersion5DatabaseWithLegacyLessonRows(name, syncDeviceRows, coherent ? rawProgress : rawProgress.map((record) => ({ ...record, readCount: 7 })));
      const exported = await createStore(name).exportData("2026-01-06T03:45:00.000Z");
      if (coherent) {
        assert.deepEqual(exported.lessonProgress, expected.data?.lessonProgress);
        assert.equal(exported.lessonProgress?.find((record) => record.lessonId === "L-005-05")?.readCount, 3);
        assert.deepEqual(exported.syncDeviceRows, expected.data?.syncDeviceRows);
        assert.deepEqual(exported.lessonQuizAttempts, expected.data?.lessonQuizAttempts);
        const reimported = createStore("v6-device-migration-reimport");
        await reimported.importData(exported);
        assert.deepEqual((await reimported.exportData(exported.exportedAt)).syncDeviceRows, exported.syncDeviceRows);
      } else {
        assert.equal(exported.syncDeviceRows, undefined);
        assert.equal(exported.lessonProgress?.find((record) => record.lessonId === "L-005-05")?.readCount, 7);
      }
      assertProgressExportMatchesSchema(exported);
    }
  });

  it("imports legacy lesson split progress into the new lesson and quiz IDs", () => {
    const validation = validateProgressImport(validExport({
      lessonIdVersion: undefined,
      lessonProgress: [
        { lessonId: "L-001-03", readAt: "2026-01-02T03:30:00.000Z", readCount: 1 },
        { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 },
      ],
      lessonQuizAttempts: [
        {
          id: "legacy-00103",
          quizId: "QZ-L-001-03-A",
          lessonId: "L-001-03",
          submittedAt: "2026-01-02T03:45:00.000Z",
          correct: 2,
          total: 2,
          percent: 100,
          officialQuestionIds: ["B-001-010-001", "B-001-014-001"],
          incorrectOfficialQuestionIds: [],
          incorrectConceptCheckIds: [],
        },
      ],
    }));

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.lessonProgress, [
      { lessonId: "L-001-03", readAt: "2026-01-02T03:30:00.000Z", readCount: 1 },
      { lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 },
    ]);
    assert.deepEqual(validation.data?.lessonQuizAttempts?.map(({ id, quizId, lessonId, officialQuestionIds }) => ({ id, quizId, lessonId, officialQuestionIds })), [
      { id: "legacy-00103", quizId: "QZ-L-001-03-A", lessonId: "L-001-03", officialQuestionIds: ["B-001-010-001"] },
      { id: "legacy-00103::QZ-L-001-05-A", quizId: "QZ-L-001-05-A", lessonId: "L-001-05", officialQuestionIds: ["B-001-014-001"] },
    ]);
    assert.equal(validation.data?.lessonIdVersion, 2);
  });

  it("remaps every historical wrong concept by text and recomputes concept-inclusive scores", () => {
    const cases = JSON.parse(readFileSync(path.resolve(import.meta.dirname, "../../../../fixtures/progress/lesson-split-quiz-migration.json"), "utf8")) as { name: string; attempt: LessonQuizAttempt; expected: LessonQuizAttempt[]; conceptDestinations: { oldId: string; newId: string | null }[] }[];
    for (const testCase of cases) {
      const result = validateProgressImport(validExport({ lessonIdVersion: 1, lessonProgress: [], lessonQuizAttempts: [testCase.attempt] }));
      assert.equal(result.ok, true, `${testCase.name}: ${result.errors}`);
      assert.deepEqual(result.data?.lessonQuizAttempts, testCase.expected, testCase.name);
      assert((result.data?.lessonQuizAttempts ?? []).reduce((sum, attempt) => sum + attempt.correct, 0) <= testCase.attempt.correct, `${testCase.name}: original correct budget`);
      for (const { oldId, newId } of testCase.conceptDestinations) {
        const attempt = { ...testCase.attempt, correct: testCase.attempt.total - 1, percent: ((testCase.attempt.total - 1) / testCase.attempt.total) * 100, incorrectConceptCheckIds: [oldId] };
        const migrated = validateProgressImport(validExport({ lessonIdVersion: 1, lessonProgress: [], lessonQuizAttempts: [attempt] }));
        assert.equal(migrated.ok, true, migrated.errors.join("\n"));
        assert.deepEqual(migrated.data?.lessonQuizAttempts, testCase.expected.map((destination) => {
          const wrong = newId?.startsWith(`${destination.quizId}-C`) ? [newId] : [];
          const correct = destination.total - wrong.length;
          return { ...destination, incorrectConceptCheckIds: wrong, correct, percent: (correct / destination.total) * 100 };
        }), `individual wrong concept ${oldId} -> ${newId ?? "dropped"}`);
      }
    }
  });

  it("includes wrong concepts first and fills only the recorded partial concept count", () => {
    const partial: LessonQuizAttempt = {
      ...lessonQuizAttempt, id: "partial", quizId: "QZ-L-005-04-A", lessonId: "L-005-04",
      officialQuestionIds: ["B-005-007-001"], incorrectOfficialQuestionIds: [],
      correct: 2, total: 2, percent: 100, incorrectConceptCheckIds: [],
    };
    assert.deepEqual(migrateLessonQuizAttempts([partial]), [partial]);
    const inconsistent = { ...partial, incorrectConceptCheckIds: ["QZ-L-005-04-A-C3"] };
    const migrated = migrateLessonQuizAttempts([inconsistent]);
    assert.equal(migrated.length, 2);
    assert.equal(migrated[0]?.total, 1);
    assert.equal(migrated[0]?.correct, 1);
    assert(migrated.reduce((sum, attempt) => sum + attempt.correct, 0) <= inconsistent.correct);
    assert.deepEqual(migrated[1]?.incorrectConceptCheckIds, ["QZ-L-005-05-A-C2"]);
    assert.equal(migrated[1]?.total, 1);
    assert.equal(migrated[1]?.correct, 0);
    const oldLocal = { ...partial, total: 1, correct: 0, percent: 0, officialQuestionIds: ["B-005-009-001"], incorrectOfficialQuestionIds: ["B-005-009-001"] };
    const moved = migrateLessonQuizAttempts([oldLocal]);
    assert.deepEqual(moved.map((attempt) => attempt.officialQuestionIds), [["B-005-009-001"]]);
    assert.equal(moved.some((attempt) => attempt.quizId === oldLocal.quizId), false);
  });

  it("requires every contributing lesson and uses the latest date and minimum read count", () => {
    const early = { lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 5 };
    const late = { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 };
    assert.deepEqual(migrateLessonProgressRecords([early]), [early]);
    assert.deepEqual(migrateLessonProgressRecords([late]), [{ ...late, lessonId: "L-005-06" }]);
    assert.deepEqual(migrateLessonProgressRecords([early, late]), [early, late, { ...late, lessonId: "L-005-06" }]);
    for (const sources of [["L-001-03", "L-001-05"], ["L-008-01", "L-008-02"]]) {
      assert.deepEqual(migrateLessonProgressRecords([{ ...early, lessonId: sources[0]! }]), sources[0] === "L-001-03" ? [{ ...early, lessonId: "L-001-03" }] : []);
      assert.deepEqual(migrateLessonProgressRecords([{ ...early, lessonId: sources[0]! }, { ...late, lessonId: sources[1]! }]), sources.map((lessonId) => ({ ...(lessonId === "L-001-03" ? early : late), lessonId })));
    }
  });

  it("merges legacy source reads per device before aggregating and falls back for incoherent rows", async () => {
    const rows: DeviceLessonProgressRecord[] = [
      { deviceId: "phone", record: { lessonId: "L-005-04", readAt: "2026-01-02T03:30:00.000Z", readCount: 5 } },
      { deviceId: "phone", record: { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 } },
      { deviceId: "tablet", record: { lessonId: "L-005-04", readAt: "2026-01-04T03:30:00.000Z", readCount: 1 } },
      { deviceId: "tablet", record: { lessonId: "L-005-05", readAt: "2026-01-05T03:30:00.000Z", readCount: 4 } },
    ];
    const raw = deduplicateDeviceLessonProgressForSync(rows);
    // Sync merge is version-neutral, including unversioned fixture rows.
    assert.deepEqual(raw.map((record) => record.lessonId), ["L-005-04", "L-005-05"]);
    assert.deepEqual(raw.map((record) => record.readCount), [6, 6]);
    const imported = validExport({ lessonIdVersion: 1, questionProgress: [], examAttempts: [], lessonProgress: raw, lessonQuizAttempts: [], syncDeviceRows: { questionProgress: [], examAttempts: [], lessonProgress: rows, lessonQuizAttempts: [], morseCourseProgress: [] } });
    const validated = validateProgressImport(imported);
    assert.equal(validated.ok, true, validated.errors.join("\n"));
    const expectedRows: DeviceLessonProgressRecord[] = [
      { deviceId: "phone", record: rows[0]!.record, lessonIdVersion: 2 },
      { deviceId: "phone", record: { ...rows[1]!.record }, lessonIdVersion: 2 },
      { deviceId: "phone", record: { ...rows[1]!.record, lessonId: "L-005-06" }, lessonIdVersion: 2 },
      { deviceId: "tablet", record: rows[2]!.record, lessonIdVersion: 2 },
      { deviceId: "tablet", record: { ...rows[3]!.record, readCount: 1 }, lessonIdVersion: 2 },
      { deviceId: "tablet", record: { ...rows[3]!.record, lessonId: "L-005-06" }, lessonIdVersion: 2 },
    ];
    assert.deepEqual(validated.data?.syncDeviceRows?.lessonProgress, expectedRows);
    assert.deepEqual(validated.data?.lessonProgress, deduplicateDeviceLessonProgressForSync(expectedRows));
    assert.equal(validated.data?.lessonProgress?.find((record) => record.lessonId === "L-005-05")?.readCount, 3);
    const incoherent = validateProgressImport({ ...imported, lessonProgress: raw.map((record) => ({ ...record, readCount: 7 })) });
    assert.equal(incoherent.ok, true);
    assert.equal(incoherent.data?.lessonProgress?.find((record) => record.lessonId === "L-005-05")?.readCount, 7);
    const store = createStore("per-device-migration");
    await store.importData(imported);
    assert.deepEqual((await store.exportData("2026-01-06T03:45:00.000Z")).syncDeviceRows?.lessonProgress, expectedRows);
  });

  it("rejects null and unsupported lesson ID versions at the top level and on both row kinds", () => {
    for (const version of [null, 3]) {
      assert.equal(validateProgressImport({ ...validExport(), lessonIdVersion: version }).ok, false);
      for (const field of ["lessonProgress", "lessonQuizAttempts"] as const) {
        const row = field === "lessonProgress" ? { record: lessonProgressRecord } : { attempt: lessonQuizAttempt };
        assert.equal(validateProgressImport({ ...validExport(), syncDeviceRows: { questionProgress: [], examAttempts: [], lessonProgress: [], lessonQuizAttempts: [], morseCourseProgress: [], [field]: [{ deviceId: "phone", ...row, lessonIdVersion: version }] } }).ok, false);
      }
    }
  });

  it("rejects invalid legacy rows before migration can merge duplicates or repair scores", async () => {
    const legacyAttempt: LessonQuizAttempt = {
      ...lessonQuizAttempt,
      id: "legacy-invalid-score",
      quizId: "QZ-L-005-04-A",
      lessonId: "L-005-04",
      correct: 2,
      total: 1,
      percent: 100,
      officialQuestionIds: ["B-005-009-003"],
      incorrectConceptCheckIds: [],
    };
    const invalidExport = validExport({
      lessonIdVersion: undefined,
      lessonProgress: [lessonProgressRecord, lessonProgressRecord],
      lessonQuizAttempts: [legacyAttempt, legacyAttempt],
    });
    const validation = validateProgressImport(invalidExport);

    assert.equal(validation.ok, false);
    assert(validation.errors.some((error) => error.includes("lessonProgress[1].lessonId duplicates")));
    assert(validation.errors.some((error) => error.includes("lessonQuizAttempts[1].id duplicates")));
    assert(validation.errors.some((error) => error.includes("lessonQuizAttempts[0].correct must not exceed total")));
    assert(validation.errors.some((error) => error.includes("lessonQuizAttempts[0].percent must match")));
    const store = createStore("invalid-legacy-rows");
    await assert.rejects(store.importData(invalidExport), /duplicates/);
    assert.deepEqual(await store.getLessonProgress(), []);
    assert.deepEqual(await store.getLessonQuizAttempts(), []);
  });

  it("validates historical quiz membership before migrating top-level and sync rows", async () => {
    const legacyAttempt: LessonQuizAttempt = {
      ...lessonQuizAttempt,
      id: "legacy-reactance",
      quizId: "QZ-L-005-04-A",
      lessonId: "L-005-04",
      correct: 0,
      total: 2,
      percent: 0,
      officialQuestionIds: ["B-005-009-003"],
      incorrectOfficialQuestionIds: ["B-005-009-003"],
      incorrectConceptCheckIds: ["QZ-L-005-04-A-C3"],
    };
    const historicalExport = validExport({ lessonIdVersion: 1, lessonQuizAttempts: [legacyAttempt] });
    const validation = validateProgressImport(historicalExport);
    assert.equal(validation.ok, true);
    assert(validation.data?.lessonQuizAttempts?.some((attempt) => attempt.quizId === "QZ-L-005-05-A" && attempt.officialQuestionIds.includes("B-005-009-003")));
    await createStore("historical-quiz-membership").importData(historicalExport);

    assert.deepEqual(validation.data?.lessonQuizAttempts, [{
      ...legacyAttempt, id: "legacy-reactance::QZ-L-005-05-A", quizId: "QZ-L-005-05-A", lessonId: "L-005-05",
      incorrectConceptCheckIds: ["QZ-L-005-05-A-C2"],
    }]);
    assert.equal(validation.data?.lessonQuizAttempts?.some((attempt) => attempt.quizId === "QZ-L-005-04-A"), false);
    assert.equal(validation.data?.lessonQuizAttempts?.reduce((sum, attempt) => sum + attempt.correct, 0), 0);

    const wrongSourceAttempt = { ...legacyAttempt, quizId: "QZ-L-005-05-A", lessonId: "L-005-05", incorrectConceptCheckIds: [] };
    const neverAskedAttempt = { ...legacyAttempt, officialQuestionIds: ["B-005-009-001"], incorrectOfficialQuestionIds: ["B-005-009-001"], incorrectConceptCheckIds: [] };
    const invalidExports = [wrongSourceAttempt, neverAskedAttempt].flatMap((invalidAttempt) => [
      validExport({ lessonIdVersion: 1, lessonQuizAttempts: [invalidAttempt] }),
      validExport({
        syncDeviceRows: {
          questionProgress: [], examAttempts: [], lessonProgress: [], morseCourseProgress: [],
          lessonQuizAttempts: [{ deviceId: "legacy-phone", attempt: invalidAttempt }],
        },
      }),
    ]);
    for (const invalidExport of invalidExports) {
      const invalid = validateProgressImport(invalidExport);
      assert.equal(invalid.ok, false);
      assert(invalid.errors.some((error) => error.includes("officialQuestionIds must belong")));
      await assert.rejects(createStore("invalid-historical-membership").importData(invalidExport), /officialQuestionIds must belong/);
    }
  });

  it("does not invent an empty destination attempt when a legacy quiz only answered retained questions", () => {
    const retainedAttempt: LessonQuizAttempt = {
      id: "legacy-ac-only",
      quizId: "QZ-L-005-04-A",
      lessonId: "L-005-04",
      submittedAt: "2026-01-02T03:45:00.000Z",
      correct: 1,
      total: 1,
      percent: 100,
      officialQuestionIds: ["B-005-007-001"],
      incorrectOfficialQuestionIds: [],
      incorrectConceptCheckIds: [],
    };
    const validation = validateProgressImport(validExport({
      lessonIdVersion: undefined,
      lessonQuizAttempts: [retainedAttempt],
      syncDeviceRows: {
        questionProgress: [],
        examAttempts: [],
        lessonProgress: [],
        lessonQuizAttempts: [{ deviceId: "legacy-phone", attempt: retainedAttempt }],
        morseCourseProgress: [],
      },
    }));

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.lessonQuizAttempts, [retainedAttempt]);
    assert.deepEqual(validation.data?.syncDeviceRows?.lessonQuizAttempts, [
      { deviceId: "legacy-phone", attempt: retainedAttempt, lessonIdVersion: 2 },
    ]);
  });

  it("leaves v2 lesson split exports unchanged", async () => {
    const v2Progress: LessonProgressRecord = { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 };
    const v2Attempt: LessonQuizAttempt = {
      id: "v2-reactance",
      quizId: "QZ-L-005-05-A",
      lessonId: "L-005-05",
      submittedAt: "2026-01-03T03:45:00.000Z",
      correct: 1,
      total: 1,
      percent: 100,
      officialQuestionIds: ["B-005-009-003"],
      incorrectOfficialQuestionIds: [],
      incorrectConceptCheckIds: [],
    };
    const validation = validateProgressImport(validExport({
      lessonIdVersion: 2,
      lessonProgress: [v2Progress],
      lessonQuizAttempts: [v2Attempt],
    }));

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.lessonProgress, [v2Progress]);
    assert.deepEqual(validation.data?.lessonQuizAttempts, [v2Attempt]);

    const store = createStore("v2-lesson-splits-unchanged");
    await store.importData(validation.data!);
    const exported = await store.exportData("2026-01-03T04:00:00.000Z");
    assert.deepEqual(exported.lessonProgress, [v2Progress]);
    assert.deepEqual(exported.lessonQuizAttempts, [v2Attempt]);
    assert.equal(exported.lessonIdVersion, 2);
  });

  it("migrates mixed legacy and v2 sync lesson rows by row version", () => {
    const legacyProgress: DeviceLessonProgressRecord = {
      deviceId: "legacy-phone",
      record: { lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 },
    };
    const currentProgress: DeviceLessonProgressRecord = {
      deviceId: "current-tablet",
      lessonIdVersion: 2,
      record: { lessonId: "L-005-05", readAt: "2026-01-04T03:30:00.000Z", readCount: 1 },
    };
    const legacyAttempt: DeviceLessonQuizAttemptRecord = {
      deviceId: "legacy-phone",
      attempt: {
        id: "legacy-00505",
        quizId: "QZ-L-005-05-A",
        lessonId: "L-005-05",
        submittedAt: "2026-01-03T03:45:00.000Z",
        correct: 1,
        total: 2,
        percent: 50,
        officialQuestionIds: ["B-005-012-001", "B-005-011-001"],
        incorrectOfficialQuestionIds: ["B-005-011-001"],
        incorrectConceptCheckIds: [],
      },
    };
    const currentAttempt: DeviceLessonQuizAttemptRecord = {
      deviceId: "current-tablet",
      lessonIdVersion: 2,
      attempt: {
        id: "current-00505",
        quizId: "QZ-L-005-05-A",
        lessonId: "L-005-05",
        submittedAt: "2026-01-04T03:45:00.000Z",
        correct: 1,
        total: 1,
        percent: 100,
        officialQuestionIds: ["B-005-009-003"],
        incorrectOfficialQuestionIds: [],
        incorrectConceptCheckIds: [],
      },
    };
    const validation = validateProgressImport(validExport({
      syncDeviceRows: {
        questionProgress: [],
        examAttempts: [],
        lessonProgress: [legacyProgress, currentProgress],
        lessonQuizAttempts: [legacyAttempt, currentAttempt],
        morseCourseProgress: [],
      },
    }));

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.syncDeviceRows?.lessonProgress, [
      currentProgress,
      { deviceId: "legacy-phone", record: { lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 }, lessonIdVersion: 2 },
    ]);
    assert.deepEqual(validation.data?.syncDeviceRows?.lessonQuizAttempts.map(({ deviceId, lessonIdVersion, attempt }) => ({ deviceId, lessonIdVersion, id: attempt.id, quizId: attempt.quizId, lessonId: attempt.lessonId, officialQuestionIds: attempt.officialQuestionIds })), [
      { deviceId: "legacy-phone", lessonIdVersion: 2, id: "legacy-00505", quizId: "QZ-L-005-05-A", lessonId: "L-005-05", officialQuestionIds: ["B-005-012-001"] },
      { deviceId: "legacy-phone", lessonIdVersion: 2, id: "legacy-00505::QZ-L-005-06-A", quizId: "QZ-L-005-06-A", lessonId: "L-005-06", officialQuestionIds: ["B-005-011-001"] },
      { deviceId: "current-tablet", lessonIdVersion: 2, id: "current-00505", quizId: "QZ-L-005-05-A", lessonId: "L-005-05", officialQuestionIds: ["B-005-009-003"] },
    ]);
  });

  it("keeps lesson ID migration idempotent when the same legacy export is imported twice", async () => {
    const legacyExport = validExport({
      lessonIdVersion: undefined,
      lessonProgress: [{ lessonId: "L-005-05", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 }],
      lessonQuizAttempts: [],
    });
    const store = createStore("legacy-lesson-splits-idempotent");

    await store.importData(legacyExport);
    const once = await store.exportData("2026-01-03T04:00:00.000Z");
    await store.importData(once);
    const twice = await store.exportData("2026-01-03T05:00:00.000Z");

    assert.deepEqual(twice.lessonProgress, once.lessonProgress);
    assert.deepEqual(twice.lessonQuizAttempts, once.lessonQuizAttempts);
    assert.deepEqual(twice.lessonProgress, [
      { lessonId: "L-005-06", readAt: "2026-01-03T03:30:00.000Z", readCount: 2 },
    ]);
  });

  it("imports older question progress and sync rows without answered-with-help fields as false", async () => {
    const { lastAnsweredWithHelp: _lastAnsweredWithHelp, recentAnsweredWithHelp: _recentAnsweredWithHelp, ...legacyRecord } = record;
    const legacyExport = validExport({
      questionProgress: [legacyRecord as QuestionProgressRecord],
      syncDeviceRows: {
        questionProgress: [{ deviceId: "iphone", record: legacyRecord as QuestionProgressRecord }],
        examAttempts: [],
        lessonProgress: [],
        lessonQuizAttempts: [],
        morseCourseProgress: [],
      },
    });

    const validation = validateProgressImport(legacyExport);
    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.questionProgress, [record]);
    assert.deepEqual(validation.data?.syncDeviceRows?.questionProgress, [{ deviceId: "iphone", record }]);

    const store = createStore("legacy-help-fields");
    await store.importData(legacyExport);
    assert.deepEqual(await store.getQuestionProgress(), [record]);
    assert.deepEqual((await store.exportData("2026-01-02T05:00:00.000Z")).syncDeviceRows?.questionProgress, [{ deviceId: "iphone", record }]);
  });

  it("preserves opaque sync device rows on import/export until progress changes", async () => {
    const syncDeviceRows: ProgressSyncDeviceRows = {
      questionProgress: [{ deviceId: "iphone", record }],
      examAttempts: [{ deviceId: "iphone", attempt }],
      lessonProgress: [{ deviceId: "iphone", record: lessonProgressRecord, lessonIdVersion: 2 }],
      lessonQuizAttempts: [],
      morseCourseProgress: [{ deviceId: "iphone", progress: morseCourseProgress }],
    };
    const store = createStore("sync-device-rows-passthrough");

    await store.importData(validExport({ syncDeviceRows }));
    const exported = await store.exportData("2026-01-02T05:00:00.000Z");

    assert.deepEqual(exported.syncDeviceRows, syncDeviceRows);
    await store.putQuestionProgress({ ...record, attempts: 2, correctAttempts: 1 });
    assert.equal((await store.exportData("2026-01-02T06:00:00.000Z")).syncDeviceRows, undefined);
  });

  it("drops imported sync device rows when exporting a different bank", async () => {
    const syncDeviceRows: ProgressSyncDeviceRows = {
      questionProgress: [{ deviceId: "iphone", record }],
      examAttempts: [{ deviceId: "iphone", attempt }],
      lessonProgress: [{ deviceId: "iphone", record: lessonProgressRecord, lessonIdVersion: 2 }],
      lessonQuizAttempts: [],
      morseCourseProgress: [],
    };
    const store = createStore("sync-device-rows-bank-switch");
    await store.importData(validExport({ syncDeviceRows }));

    const exported = await store.exportData("2026-01-02T06:00:00.000Z", advancedBank);

    assert.equal(exported.syncDeviceRows, undefined);
  });

  it("drops imported sync device rows when the main practice bulk progress path writes", async () => {
    const syncDeviceRows = {
      questionProgress: [{ deviceId: "iphone", record }],
      examAttempts: [],
      lessonProgress: [],
      lessonQuizAttempts: [],
      morseCourseProgress: [],
    };
    const store = createStore("sync-device-rows-practice-write");
    await store.importData(validExport({ syncDeviceRows }));

    await store.putQuestionProgressMany([{ ...record, attempts: 2, correctAttempts: 1 }]);

    assert.equal((await store.exportData("2026-01-02T06:00:00.000Z")).syncDeviceRows, undefined);
  });

  it("stores progress in IndexedDB and exports/imports a validated round trip", async () => {
    const first = createStore("roundtrip-a");
    await first.putQuestionProgress(record);
    await first.putLessonProgress(lessonProgressRecord);
    await first.putLessonQuizAttempt(lessonQuizAttempt);
    await first.putMorseCourseProgress(morseCourseProgress);
    const preferencesWithOutputMode = { ...defaultPreferences, practiceMode: "review-later" as const, examTimerEnabled: true, language: "fr" as const, theme: "dark" as const, morse: { ...defaultPreferences.morse, outputMode: "visualTape" as const } };
    await first.putPreferences(preferencesWithOutputMode);

    const exported = await first.exportData("2026-01-02T04:00:00.000Z");
    assert.equal(exported.bankId, bankId);
    assert.deepEqual(exported.questionProgress, [record]);
    assert.deepEqual(exported.lessonProgress, [lessonProgressRecord]);
    assert.deepEqual(exported.lessonQuizAttempts, [lessonQuizAttempt]);
    assert.deepEqual(exported.morseCourseProgress, morseCourseProgress);
    assert.deepEqual(exported.preferences, preferencesWithOutputMode);
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
    assert.deepEqual(await second.getPreferences(), preferencesWithOutputMode);
  });

  it("imports one course while keeping the other course's progress, in both directions", async () => {
    const advancedRecord: QuestionProgressRecord = { ...record, questionId: "A-001-001-001", bankId: advancedBank.bankId };
    const advancedAttempt: ExamAttempt = {
      ...attempt,
      id: "attempt-advanced-1",
      bankId: advancedBank.bankId,
      submittedAt: "2026-01-02T03:10:00.000Z",
      score: { ...attempt.score, bankId: advancedBank.bankId, honours: false },
    };

    // Exports from another device: one Advanced-only, one Basic-only with different lesson data.
    const source = createStore("cross-course-source");
    const replacementAdvanced: QuestionProgressRecord = { ...advancedRecord, attempts: 3, correctAttempts: 2 };
    await source.putQuestionProgress(replacementAdvanced);
    const advancedExport = await source.exportData("2026-01-02T04:00:00.000Z", advancedBank);
    assert.deepEqual(advancedExport.lessonProgress, []);
    const replacementLesson: LessonProgressRecord = { ...lessonProgressRecord, readCount: 7 };
    const basicSource = createStore("cross-course-basic-source");
    await basicSource.putLessonProgress(replacementLesson);
    const basicExport = await basicSource.exportData("2026-01-02T04:05:00.000Z");

    const target = createStore("cross-course-target");
    await target.putQuestionProgress(record);
    await target.putQuestionProgress(advancedRecord);
    await target.putExamAttempt(attempt);
    await target.putExamAttempt(advancedAttempt);
    await target.putLessonProgress(lessonProgressRecord);
    await target.putLessonQuizAttempt(lessonQuizAttempt);

    // Advanced import replaces Advanced records and keeps Basic progress, attempts and lessons.
    await target.importData(advancedExport);
    const sortById = <T extends { questionId: string }>(items: readonly T[]) => [...items].sort((left, right) => left.questionId.localeCompare(right.questionId));
    assert.deepEqual(sortById(await target.getQuestionProgress()), sortById([replacementAdvanced, record]));
    assert.deepEqual(await target.getExamAttempts(), [attempt]);
    assert.deepEqual(await target.getLessonProgress(), [lessonProgressRecord]);
    assert.deepEqual(await target.getLessonQuizAttempts(), [lessonQuizAttempt]);

    // Basic import replaces Basic records and lesson data and keeps Advanced progress.
    await target.importData(basicExport);
    assert.deepEqual(await target.getQuestionProgress(), [replacementAdvanced]);
    assert.deepEqual(await target.getExamAttempts(), []);
    assert.deepEqual(await target.getLessonProgress(), [replacementLesson]);
    assert.deepEqual(await target.getLessonQuizAttempts(), []);
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

  it("rejects duplicate Morse daily activity dates", () => {
    const validation = validateProgressImport(validExport({
      morseCourseProgress: {
        ...morseCourseProgress,
        dailyActivity: [
          { date: "2026-01-02", lessonsCompleted: 1 },
          { date: "2026-01-02", lessonsCompleted: 2 },
        ],
      },
    }));

    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /dailyActivity\[1\]\.date duplicates/);
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

  it("rejects unsupported and null language preferences", () => {
    for (const language of ["de", null]) {
      const invalid = validExport({ preferences: { ...defaultPreferences, language: language as never } });

      const validation = validateProgressImport(invalid);

      assert.equal(validation.ok, false);
      assert.match(validation.errors.join("\n"), /Import preferences are invalid/);
    }
  });

  it("normalises older exports without a language preference to system", () => {
    const legacy = validExport({ preferences: { ...defaultPreferences, language: undefined as never } });

    const validation = validateProgressImport(legacy);

    assert.equal(validation.ok, true);
    assert.equal(validation.data?.preferences.language, "system");
  });

  it("rejects web exports that try to import unsupported haptic output mode", () => {
    const invalid = validExport({ preferences: { ...defaultPreferences, morse: { ...defaultPreferences.morse, outputMode: "haptics" as never } } });

    const validation = validateProgressImport(invalid);

    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /Import preferences are invalid/);
  });

  it("rejects unknown Morse timing profiles and output modes before normalization", () => {
    for (const morse of [
      { ...defaultPreferences.morse, timingProfile: "future-profile" as never },
      { ...defaultPreferences.morse, outputMode: "future-output" as never },
    ]) {
      const validation = validateProgressImport(validExport({ preferences: { ...defaultPreferences, morse } }));
      assert.equal(validation.ok, false);
      assert.match(validation.errors.join("\n"), /Import preferences are invalid/);
    }
  });

  it("accepts legacy exports without lesson or Morse stores as empty older data", () => {
    const legacy = { ...validExport(), lessonProgress: undefined, lessonQuizAttempts: undefined, morseCourseProgress: undefined };

    const validation = validateProgressImport(legacy);

    assert.equal(validation.ok, true);
    assert.deepEqual(validation.data?.lessonProgress, []);
    assert.deepEqual(validation.data?.lessonQuizAttempts, []);
    assert.equal(validation.data?.morseCourseProgress, undefined);
  });

  it("rejects imports whose score bankId does not match the active bank", () => {
    const validation = validateProgressImport(validExport({
      examAttempts: [{ ...attempt, score: { ...attempt.score, bankId: "advanced-synthetic" } }],
    }));

    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /examAttempts\[0\]\.score\.bankId must be basic-2025-07-15/);
  });

  it("rejects Advanced import attempts marked with Honours", () => {
    const advancedAttempt: ExamAttempt = {
      ...attempt,
      id: "attempt-advanced-honours",
      bankId: advancedBank.bankId,
      submittedAt: "2026-01-02T03:10:00.000Z",
      items: [{ ...attempt.items[0]!, questionId: "A-001-001-001", subsectionId: "A-001-001", categoryId: "A-001" }],
      score: {
        ...attempt.score,
        bankId: advancedBank.bankId,
        honours: true,
        categoryBreakdown: [{ categoryId: "A-001", correct: 1, total: 1, percent: 100 }],
      },
    };

    const validation = validateProgressImport(validExport({
      bankId: advancedBank.bankId,
      questionProgress: [{ ...record, questionId: "A-001-001-001", bankId: advancedBank.bankId }],
      examAttempts: [advancedAttempt],
      lessonProgress: [],
      lessonQuizAttempts: [],
    }), advancedBank);

    assert.equal(validation.ok, false);
    assert.match(validation.errors.join("\n"), /examAttempts\[0\]\.score\.honours must be false for this course/);
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

  it("migrates an existing v3 IndexedDB database to v4 Morse course progress", async () => {
    await createVersion3Database("migrate-v3-v4");
    const store = createStore("migrate-v3-v4");

    assert.equal(await store.getMorseCourseProgress(), undefined);
    await store.putMorseCourseProgress(morseCourseProgress);
    assert.deepEqual(await store.getMorseCourseProgress(), morseCourseProgress);
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

describe("lesson-quiz answeredWithHelpIds", () => {
  const fixture = JSON.parse(readFileSync(path.resolve(import.meta.dirname, "../../../../fixtures/lesson-quiz-help.json"), "utf8")) as {
    attempt: LessonQuizAttempt; validHelpIds: string[][]; invalidHelpIds: unknown[];
  };
  it("round trips old and helped attempts through IndexedDB, export/import and sync rows", async () => {
    for (const ids of [undefined, ...fixture.validHelpIds]) {
      const attempt = { ...fixture.attempt, ...(ids === undefined ? {} : { answeredWithHelpIds: ids }) };
      const rows: ProgressSyncDeviceRows = { questionProgress: [], examAttempts: [], lessonProgress: [], lessonQuizAttempts: [{ deviceId: "web", lessonIdVersion: 2, attempt }], morseCourseProgress: [] };
      const data = validExport({ lessonIdVersion: 2, lessonQuizAttempts: [attempt], syncDeviceRows: rows });
      const result = validateProgressImport(data);
      assert.equal(result.ok, true, result.errors.join("\n"));
      const store = createStore(`quiz-help-${ids?.length ?? "legacy"}`);
      await store.importData(data);
      assert.deepEqual(await store.getLessonQuizAttempts(), [attempt]);
      const exported = await store.exportData("2026-01-02T05:00:00.000Z");
      assert.deepEqual(exported.lessonQuizAttempts, [attempt]);
      assert.deepEqual(exported.syncDeviceRows?.lessonQuizAttempts, rows.lessonQuizAttempts);
      assert.equal(validateProgressImport(JSON.parse(JSON.stringify(exported))).ok, true);
    }
  });
  it("rejects unsorted, duplicate, unknown and concept IDs in both import and sync attempts", () => {
    for (const ids of fixture.invalidHelpIds) {
      const attempt = { ...fixture.attempt, answeredWithHelpIds: ids } as LessonQuizAttempt;
      for (const data of [validExport({ lessonQuizAttempts: [attempt] }), validExport({ syncDeviceRows: { questionProgress: [], examAttempts: [], lessonProgress: [], lessonQuizAttempts: [{ deviceId: "web", attempt }], morseCourseProgress: [] } })]) {
        const result = validateProgressImport(data);
        assert.equal(result.ok, false);
        assert(result.errors.some((error) => error.includes("answeredWithHelpIds")));
      }
    }
  });
  it("preserves bank help IDs across lesson-ID migration and filters split attempts to their membership", () => {
    const legacy: LessonQuizAttempt = { ...fixture.attempt, quizId: "QZ-L-005-04-A", lessonId: "L-005-04", officialQuestionIds: ["B-005-007-001", "B-005-009-003"], incorrectOfficialQuestionIds: ["B-005-009-003"], answeredWithHelpIds: ["B-005-007-001", "B-005-009-003"] };
    const migrated = migrateLessonQuizAttempts([legacy]);
    assert.equal(migrated.length, 2);
    assert.deepEqual(migrated.map((attempt) => attempt.answeredWithHelpIds), [["B-005-007-001"], ["B-005-009-003"]]);
    assert.deepEqual(migrateLessonQuizAttempts([fixture.attempt]), [fixture.attempt]);
  });
});
