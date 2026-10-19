import { dueCount, type CategoryBreakdownEntry, type QuestionProgressRecord } from "@canadian-ham/engine-ts";
import { type MorseCourseProgressExport } from "@canadian-ham/morse-engine";

import { basicBank, bankDataForId, DEFAULT_BANK_ID, isCourseBankId, type BankData, type CourseBankId, type Language } from "../data/bank";
import { defaultMorsePreferences, normalizeMorsePreferences, type WebMorsePreferences } from "./morseSettings";
import { lessonsById } from "../data/lessons";
import { lessonQuizzesById } from "../data/quizzes";

export type PracticeMode = "immediate" | "review-later";
export type ReadinessPreference = "not-enough-data" | "needs-review" | "pass-ready" | "honours-ready";
export type ThemePreference = "system" | "light" | "dark";
export type LanguagePreference = "system" | Language;

export interface WebPreferences {
  readonly practiceMode: PracticeMode;
  readonly examTimerEnabled: boolean;
  readonly language: LanguagePreference;
  readonly theme: ThemePreference;
  readonly activeBankId: CourseBankId;
  readonly morse: WebMorsePreferences;
}

export interface ExamAttemptItem {
  readonly position: number;
  readonly questionId: string;
  readonly subsectionId: string;
  readonly categoryId: string;
  readonly choicePermutation: readonly number[];
  readonly selectedSourceIndex: number | null;
  readonly isCorrect: boolean;
  readonly flagged: boolean;
}

export interface ExamAttempt {
  readonly id: string;
  readonly bankId: string;
  readonly mode: "mock-exam";
  readonly seed: string;
  readonly startedAt: string;
  readonly submittedAt: string;
  readonly timer: {
    readonly enabled: boolean;
    readonly secondsAllowed: number | null;
    readonly secondsElapsed: number;
  };
  readonly items: readonly ExamAttemptItem[];
  readonly score: {
    readonly bankId: string;
    readonly correct: number;
    readonly total: number;
    readonly percent: number;
    readonly passed: boolean;
    readonly honours: boolean;
    readonly categoryBreakdown: readonly CategoryBreakdownEntry[];
    readonly weakSubsectionIds: readonly string[];
  };
}

export interface LessonProgressRecord {
  readonly lessonId: string;
  readonly readAt: string;
  readonly readCount: number;
}

export interface LessonQuizAttempt {
  readonly id: string;
  readonly quizId: string;
  readonly lessonId: string;
  readonly submittedAt: string;
  readonly correct: number;
  readonly total: number;
  readonly percent: number;
  readonly officialQuestionIds: readonly string[];
  readonly incorrectOfficialQuestionIds: readonly string[];
  readonly incorrectConceptCheckIds: readonly string[];
}

export interface DeviceQuestionProgressRecord {
  readonly deviceId: string;
  readonly record: QuestionProgressRecord;
}

export interface DeviceExamAttemptRecord {
  readonly deviceId: string;
  readonly attempt: ExamAttempt;
}

export interface DeviceLessonProgressRecord {
  readonly deviceId: string;
  readonly record: LessonProgressRecord;
  readonly lessonIdVersion?: LessonIdVersion;
}

export interface DeviceLessonQuizAttemptRecord {
  readonly deviceId: string;
  readonly attempt: LessonQuizAttempt;
  readonly lessonIdVersion?: LessonIdVersion;
}

export interface DeviceMorseCourseProgressRecord {
  readonly deviceId: string;
  readonly progress: MorseCourseProgressExport;
}

export interface ProgressSyncDeviceRows {
  readonly questionProgress: readonly DeviceQuestionProgressRecord[];
  readonly examAttempts: readonly DeviceExamAttemptRecord[];
  readonly lessonProgress: readonly DeviceLessonProgressRecord[];
  readonly lessonQuizAttempts: readonly DeviceLessonQuizAttemptRecord[];
  readonly morseCourseProgress: readonly DeviceMorseCourseProgressRecord[];
}

type LessonIdVersion = 1 | 2;

export interface ProgressExportV1 {
  readonly schema: "canadian-ham.progress-export";
  readonly version: 1;
  readonly lessonIdVersion?: LessonIdVersion;
  readonly exportedAt: string;
  readonly bankId: string;
  readonly questionProgress: readonly QuestionProgressRecord[];
  readonly examAttempts: readonly ExamAttempt[];
  readonly lessonProgress?: readonly LessonProgressRecord[];
  readonly lessonQuizAttempts?: readonly LessonQuizAttempt[];
  readonly morseCourseProgress?: MorseCourseProgressExport;
  readonly syncDeviceRows?: ProgressSyncDeviceRows;
  readonly preferences: WebPreferences;
}

export interface ImportValidationResult {
  readonly ok: boolean;
  readonly errors: readonly string[];
  readonly data?: ProgressExportV1;
}

export const defaultPreferences: WebPreferences = {
  practiceMode: "immediate",
  examTimerEnabled: false,
  language: "system",
  theme: "system",
  activeBankId: DEFAULT_BANK_ID,
  morse: defaultMorsePreferences,
};

const CURRENT_LESSON_ID_VERSION: LessonIdVersion = 2;
const LEGACY_LESSON_ID_VERSION: LessonIdVersion = 1;
const DB_VERSION = 6;
const DEFAULT_DB_NAME = "canadian-ham-web-progress";
const PREFERENCES_KEY = "preferences";
const SYNC_DEVICE_ROWS_KEY = "syncDeviceRows";

export const lessonProgressMigrationMap: Readonly<Record<string, readonly string[]>> = Object.freeze({
  // TASK-46.10 split L-005-04 into AC/dB and reactance/resonance.
  "L-005-04": ["L-005-04", "L-005-05"],
  // TASK-46.10 moved resonance out of the old transformer/meter lesson.
  "L-005-05": ["L-005-05", "L-005-06"],
  // TASK-46.10 split M8 by receiver-side and transmitter-side faults.
  "L-008-01": ["L-008-01", "L-008-02"],
  "L-008-02": ["L-008-01", "L-008-02"],
  // TASK-46.10 moved B-001-014 third-party coverage into L-001-05.
  "L-001-03": ["L-001-03", "L-001-05"],
});

// All contributing old lessons must be read before a destination earns read credit.
const lessonProgressSources: Readonly<Record<string, readonly string[]>> = {
  "L-001-03": ["L-001-03"],
  "L-001-05": ["L-001-03", "L-001-05"],
  "L-005-04": ["L-005-04"],
  "L-005-05": ["L-005-04", "L-005-05"],
  "L-005-06": ["L-005-05"],
  "L-008-01": ["L-008-01", "L-008-02"],
  "L-008-02": ["L-008-01", "L-008-02"],
};

const lessonQuizMigrationMap: Readonly<Record<string, readonly string[]>> = Object.freeze({
  "QZ-L-005-04-A": ["QZ-L-005-04-A", "QZ-L-005-05-A"],
  "QZ-L-005-05-A": ["QZ-L-005-05-A", "QZ-L-005-06-A"],
  "QZ-L-008-01-A": ["QZ-L-008-01-A", "QZ-L-008-02-A"],
  "QZ-L-008-02-A": ["QZ-L-008-01-A", "QZ-L-008-02-A"],
  "QZ-L-001-03-A": ["QZ-L-001-03-A", "QZ-L-001-05-A"],
});

// Prefixes also preserve older local question IDs outside the sampled historical quiz.
const lessonQuizMigrationPrefixes: Readonly<Record<string, readonly string[]>> = {
  "QZ-L-001-03-A": ["B-001-010-", "B-001-011-", "B-001-012-", "B-001-013-"],
  "QZ-L-001-05-A": ["B-001-014-", "B-001-020-", "B-001-021-"],
  "QZ-L-005-04-A": ["B-005-007-", "B-005-008-"],
  "QZ-L-005-05-A": ["B-005-009-", "B-005-010-", "B-005-012-"],
  "QZ-L-005-06-A": ["B-005-011-", "B-005-013-"],
  "QZ-L-008-01-A": ["B-008-001-", "B-008-002-", "B-008-005-"],
  "QZ-L-008-02-A": ["B-008-003-", "B-008-004-"],
};

// Ordered as in 350a3b53. Null explicitly drops checks with no current equivalent.
const lessonConceptCheckMigrationMap: Readonly<Record<string, string | null>> = {
  "QZ-L-005-04-A-C1": "QZ-L-005-04-A-C1",
  "QZ-L-005-04-A-C2": "QZ-L-005-05-A-C1",
  "QZ-L-005-04-A-C3": "QZ-L-005-05-A-C2",
  "QZ-L-005-05-A-C1": "QZ-L-005-06-A-C1",
  "QZ-L-005-05-A-C2": "QZ-L-005-05-A-C3",
  "QZ-L-005-05-A-C3": "QZ-L-005-06-A-C2",
  "QZ-L-008-01-A-C1": "QZ-L-008-01-A-C1",
  "QZ-L-008-01-A-C2": "QZ-L-008-01-A-C2",
  "QZ-L-008-01-A-C3": "QZ-L-008-01-A-C3",
  "QZ-L-008-02-A-C1": "QZ-L-008-02-A-C1",
  "QZ-L-008-02-A-C2": null,
  "QZ-L-008-02-A-C3": null,
};

interface StoredPreferenceRecord {
  readonly key: string;
  readonly value: WebPreferences;
}

export class ProgressStore {
  #dbPromise: Promise<IDBDatabase> | null = null;

  constructor(private readonly dbName = DEFAULT_DB_NAME) {}

  async getQuestionProgress(): Promise<QuestionProgressRecord[]> {
    return (await this.getAll<QuestionProgressRecord>("questionProgress")).map((record) => normalizeQuestionProgressRecordDefaults(record));
  }

  async putQuestionProgress(record: QuestionProgressRecord): Promise<void> {
    await this.put("questionProgress", record);
  }

  async putQuestionProgressMany(records: readonly QuestionProgressRecord[]): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["questionProgress", "syncMetadata"], "readwrite", (transaction) => {
      const store = transaction.objectStore("questionProgress");
      for (const record of records) {
        store.put(record);
      }
      transaction.objectStore("syncMetadata").delete(SYNC_DEVICE_ROWS_KEY);
    });
  }

  async getExamAttempts(): Promise<ExamAttempt[]> {
    return this.getAll<ExamAttempt>("examAttempts");
  }

  async putExamAttempt(attempt: ExamAttempt): Promise<void> {
    await this.put("examAttempts", attempt);
  }

  async getLessonProgress(): Promise<LessonProgressRecord[]> {
    return this.getAll<LessonProgressRecord>("lessonProgress");
  }

  async putLessonProgress(record: LessonProgressRecord): Promise<void> {
    await this.put("lessonProgress", record);
  }

  async getLessonQuizAttempts(): Promise<LessonQuizAttempt[]> {
    return this.getAll<LessonQuizAttempt>("lessonQuizAttempts");
  }

  async putLessonQuizAttempt(attempt: LessonQuizAttempt): Promise<void> {
    await this.put("lessonQuizAttempts", attempt);
  }

  async getMorseCourseProgress(): Promise<MorseCourseProgressExport | undefined> {
    const db = await this.open();
    const record = await requestToPromise<(MorseCourseProgressExport & { readonly key?: string }) | undefined>(
      db.transaction("morseCourseProgress", "readonly").objectStore("morseCourseProgress").get("default"),
    );
    if (record === undefined) {
      return undefined;
    }
    const { key: _key, ...progress } = record;
    return progress;
  }

  async putMorseCourseProgress(progress: MorseCourseProgressExport): Promise<void> {
    await this.put("morseCourseProgress", { ...progress, key: "default" });
  }

  async putLessonQuizAttemptWithQuestionProgress(attempt: LessonQuizAttempt, records: readonly QuestionProgressRecord[]): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["lessonQuizAttempts", "questionProgress", "syncMetadata"], "readwrite", (transaction) => {
      transaction.objectStore("lessonQuizAttempts").put(attempt);
      const questionStore = transaction.objectStore("questionProgress");
      for (const record of records) {
        questionStore.put(record);
      }
      transaction.objectStore("syncMetadata").delete(SYNC_DEVICE_ROWS_KEY);
    });
  }

  async getPreferences(): Promise<WebPreferences> {
    const db = await this.open();
    const record = await requestToPromise<StoredPreferenceRecord | undefined>(
      db.transaction("preferences", "readonly").objectStore("preferences").get(PREFERENCES_KEY),
    );
    return normalizePreferences(record?.value);
  }

  async putPreferences(preferences: WebPreferences): Promise<void> {
    await this.put("preferences", { key: PREFERENCES_KEY, value: preferences });
  }

  async exportData(exportedAt: string, bank: BankData = basicBank): Promise<ProgressExportV1> {
    const allQuestionProgress = await this.getQuestionProgress();
    const allExamAttempts = await this.getExamAttempts();
    const questionProgress = allQuestionProgress.filter((record) => record.bankId === bank.bankId);
    const examAttempts = allExamAttempts.filter((attempt) => attempt.bankId === bank.bankId);
    const lessonProgress = bank.hasLessons ? await this.getLessonProgress() : [];
    const lessonQuizAttempts = bank.hasLessons ? await this.getLessonQuizAttempts() : [];
    const morseCourseProgress = await this.getMorseCourseProgress();
    const syncDeviceRows = filterSyncDeviceRowsForExport(await this.getSyncDeviceRowsMetadata(), bank);
    return {
      schema: "canadian-ham.progress-export",
      version: 1,
      lessonIdVersion: CURRENT_LESSON_ID_VERSION,
      exportedAt,
      bankId: bank.bankId,
      questionProgress,
      examAttempts,
      lessonProgress,
      lessonQuizAttempts,
      morseCourseProgress,
      ...(syncDeviceRows === undefined ? {} : { syncDeviceRows }),
      preferences: { ...(await this.getPreferences()), activeBankId: bank.bankId },
    };
  }

  async importData(data: ProgressExportV1): Promise<void> {
    const importBank = bankDataForId(data.bankId);
    const validation = validateProgressImport(data, importBank);
    if (!validation.ok || validation.data === undefined) {
      throw new Error(validation.errors.join("\n"));
    }
    data = validation.data;
    const db = await this.open();
    const existingQuestionProgress = (await this.getQuestionProgress()).filter((record) => record.bankId !== importBank.bankId);
    const existingExamAttempts = (await this.getExamAttempts()).filter((attempt) => attempt.bankId !== importBank.bankId);
    await runTransaction(db, ["questionProgress", "examAttempts", "lessonProgress", "lessonQuizAttempts", "morseCourseProgress", "preferences", "syncMetadata"], "readwrite", (transaction) => {
      transaction.objectStore("questionProgress").clear();
      transaction.objectStore("examAttempts").clear();
      const questionStore = transaction.objectStore("questionProgress");
      const attemptStore = transaction.objectStore("examAttempts");
      const lessonStore = transaction.objectStore("lessonProgress");
      const quizAttemptStore = transaction.objectStore("lessonQuizAttempts");
      const morseCourseStore = transaction.objectStore("morseCourseProgress");
      for (const record of [...existingQuestionProgress, ...data.questionProgress]) {
        questionStore.put(normalizeQuestionProgressRecordDefaults(record));
      }
      for (const attempt of [...existingExamAttempts, ...data.examAttempts]) {
        attemptStore.put(attempt);
      }
      if (importBank.hasLessons) {
        lessonStore.clear();
        quizAttemptStore.clear();
        for (const record of data.lessonProgress ?? []) {
          lessonStore.put(record);
        }
        for (const attempt of data.lessonQuizAttempts ?? []) {
          quizAttemptStore.put(attempt);
        }
      }
      if (data.morseCourseProgress !== undefined) {
        morseCourseStore.put({ ...data.morseCourseProgress, key: "default" });
      }
      transaction.objectStore("preferences").put({ key: PREFERENCES_KEY, value: normalizePreferences({ ...data.preferences, activeBankId: importBank.bankId }) });
      if (data.syncDeviceRows === undefined) {
        transaction.objectStore("syncMetadata").delete(SYNC_DEVICE_ROWS_KEY);
      } else {
        transaction.objectStore("syncMetadata").put({ key: SYNC_DEVICE_ROWS_KEY, value: normalizeProgressSyncDeviceRows(data.syncDeviceRows) });
      }
    });
  }

  async resetAllData(): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["questionProgress", "examAttempts", "lessonProgress", "lessonQuizAttempts", "morseCourseProgress", "preferences", "syncMetadata"], "readwrite", (transaction) => {
      transaction.objectStore("questionProgress").clear();
      transaction.objectStore("examAttempts").clear();
      transaction.objectStore("lessonProgress").clear();
      transaction.objectStore("lessonQuizAttempts").clear();
      transaction.objectStore("morseCourseProgress").clear();
      transaction.objectStore("preferences").clear();
      transaction.objectStore("syncMetadata").clear();
    });
  }

  close(): void {
    if (this.#dbPromise !== null) {
      void this.#dbPromise.then((db) => db.close());
      this.#dbPromise = null;
    }
  }

  async deleteDatabase(): Promise<void> {
    this.close();
    await requestToPromise(indexedDB.deleteDatabase(this.dbName));
  }

  private async getAll<T>(storeName: string): Promise<T[]> {
    const db = await this.open();
    return requestToPromise<T[]>(db.transaction(storeName, "readonly").objectStore(storeName).getAll());
  }

  private async getSyncDeviceRowsMetadata(): Promise<ProgressSyncDeviceRows | undefined> {
    const db = await this.open();
    const record = await requestToPromise<{ readonly value: ProgressSyncDeviceRows } | undefined>(
      db.transaction("syncMetadata", "readonly").objectStore("syncMetadata").get(SYNC_DEVICE_ROWS_KEY),
    );
    return record?.value;
  }

  private async put(storeName: string, value: unknown): Promise<void> {
    const db = await this.open();
    const clearsSyncRows = ["questionProgress", "examAttempts", "lessonProgress", "lessonQuizAttempts", "morseCourseProgress"].includes(storeName);
    await runTransaction(db, clearsSyncRows ? [storeName, "syncMetadata"] : [storeName], "readwrite", (transaction) => {
      transaction.objectStore(storeName).put(value);
      if (clearsSyncRows) transaction.objectStore("syncMetadata").delete(SYNC_DEVICE_ROWS_KEY);
    });
  }

  private open(): Promise<IDBDatabase> {
    this.#dbPromise ??= new Promise<IDBDatabase>((resolve, reject) => {
      const request = indexedDB.open(this.dbName, DB_VERSION);
      request.onupgradeneeded = (event) => {
        migrateDatabase(request.result, event.oldVersion, request.transaction);
      };
      request.onblocked = () => {
        reject(new Error("Progress database upgrade is blocked by another open Canadian Ham tab. Close the other tab and try again."));
      };
      request.onerror = () => reject(request.error ?? new Error("Unable to open progress database"));
      request.onsuccess = () => {
        const db = request.result;
        db.onversionchange = () => {
          db.close();
          this.#dbPromise = null;
        };
        resolve(db);
      };
    }).catch((error: unknown) => {
      this.#dbPromise = null;
      throw error;
    });
    return this.#dbPromise;
  }
}

export const defaultProgressStore = new ProgressStore();

export function deduplicateQuestionProgressForSync(records: readonly QuestionProgressRecord[]): QuestionProgressRecord[] {
  return deduplicateDeviceQuestionProgressForSync(records.map((record) => ({ deviceId: "local", record })));
}

export function deduplicateDeviceQuestionProgressForSync(rows: readonly DeviceQuestionProgressRecord[]): QuestionProgressRecord[] {
  const groups = groupBy(rows, (row) => `${row.record.bankId}\u0000${row.record.questionId}`);
  return [...groups.values()]
    .map((group) => mergeDeviceQuestionProgressForSync(group))
    .sort((a, b) => codePointCompare(a.bankId, b.bankId) || codePointCompare(a.questionId, b.questionId));
}

export function mergeQuestionProgressForSync(records: readonly QuestionProgressRecord[]): QuestionProgressRecord {
  return mergeDeviceQuestionProgressForSync(records.map((record) => ({ deviceId: "local", record })));
}

export function mergeDeviceQuestionProgressForSync(rows: readonly DeviceQuestionProgressRecord[]): QuestionProgressRecord {
  if (rows.length === 0) throw new Error("Cannot merge an empty question-progress group.");
  const normalizedRows = rows.map((row) => ({ ...row, record: normalizeQuestionProgressRecordDefaults(row.record) }));
  const deviceRows = [...groupBy(normalizedRows, (row) => row.deviceId).values()].map((group) => [...group].sort(deviceQuestionProgressTieBreak).at(-1)!);
  const latest = [...deviceRows].sort(deviceQuestionProgressTieBreak).at(-1)!;
  return {
    ...latest.record,
    attempts: deviceRows.reduce((sum, row) => sum + row.record.attempts, 0),
    correctAttempts: deviceRows.reduce((sum, row) => sum + row.record.correctAttempts, 0),
    recentResults: latest.record.recentResults.slice(-5),
    recentAnsweredWithHelp: recentAnsweredWithHelpForRecord(latest.record).slice(-5),
    notes: latest.record.notes ?? undefined,
  };
}

export function deduplicateExamAttemptsForSync(attempts: readonly ExamAttempt[]): ExamAttempt[] {
  return deduplicateDeviceExamAttemptsForSync(attempts.map((attempt) => ({ deviceId: "local", attempt })));
}

export function deduplicateDeviceExamAttemptsForSync(rows: readonly DeviceExamAttemptRecord[]): ExamAttempt[] {
  return [...groupBy(rows, (row) => `${row.attempt.bankId}\u0000${row.attempt.submittedAt}`).values()]
    .map((group) => [...group].sort(deviceExamAttemptTieBreak).at(-1)!.attempt)
    .sort(examAttemptTieBreak);
}

export function deduplicateDeviceLessonProgressForSync(rows: readonly DeviceLessonProgressRecord[]): LessonProgressRecord[] {
  return [...groupBy(rows, (row) => row.record.lessonId).values()]
    .map((group) => {
      const deviceRows = [...groupBy(group, (row) => row.deviceId).values()].map((deviceGroup) => [...deviceGroup].sort(deviceLessonProgressTieBreak).at(-1)!);
      const latest = [...deviceRows].sort(deviceLessonProgressTieBreak).at(-1)!;
      return {
        lessonId: latest.record.lessonId,
        readAt: latest.record.readAt,
        readCount: deviceRows.reduce((sum, row) => sum + row.record.readCount, 0),
      };
    })
    .sort((a, b) => codePointCompare(a.lessonId, b.lessonId));
}

export function migrateLessonProgressRecords(records: readonly LessonProgressRecord[]): LessonProgressRecord[] {
  const recordsById = new Map(records.map((record) => [record.lessonId, record]));
  const destinations = new Set([...records.map((record) => record.lessonId), ...Object.keys(lessonProgressSources)]);
  return [...destinations].sort(codePointCompare).flatMap((lessonId) => {
    const sources = (lessonProgressSources[lessonId] ?? [lessonId]).map((id) => recordsById.get(id));
    if (sources.some((record) => record === undefined)) return [];
    const readSources = sources as LessonProgressRecord[];
    return [{
      lessonId,
      readAt: readSources.map((record) => record.readAt).sort(codePointCompare).at(-1)!,
      readCount: Math.min(...readSources.map((record) => record.readCount)),
    }];
  });
}

export function migrateLessonQuizAttempts(attempts: readonly LessonQuizAttempt[]): LessonQuizAttempt[] {
  const migrated = new Map<string, LessonQuizAttempt>();
  for (const attempt of attempts) {
    const targetQuizIds = lessonQuizMigrationMap[attempt.quizId];
    if (targetQuizIds === undefined) {
      migrated.set(attempt.id, attempt);
      continue;
    }
    // Partial attempts record only a count, not the IDs of correct concepts. The UI
    // asks them in order. Keep explicit wrong IDs even outside that prefix; never
    // infer a correct answer for an inconsistent historical wrong ID.
    const oldConceptIds = Object.keys(lessonConceptCheckMigrationMap).filter((id) => id.startsWith(`${attempt.quizId}-C`));
    const answeredConceptIds = new Set([
      ...oldConceptIds.slice(0, Math.max(0, attempt.total - attempt.officialQuestionIds.length)),
      ...attempt.incorrectConceptCheckIds,
    ]);
    const assignedConceptIds = oldConceptIds.filter((id) => answeredConceptIds.has(id)).flatMap((id) => lessonConceptCheckMigrationMap[id] ?? []);
    const wrongConceptIds = oldConceptIds.filter((id) => attempt.incorrectConceptCheckIds.includes(id)).flatMap((id) => lessonConceptCheckMigrationMap[id] ?? []);
    for (const quizId of targetQuizIds) {
      const quiz = lessonQuizzesById.get(quizId);
      if (quiz === undefined) continue;
      const officialQuestionIds = attempt.officialQuestionIds.filter((questionId) => lessonQuizMigrationPrefixes[quizId]!.some((prefix) => questionId.startsWith(prefix)));
      const incorrectOfficialQuestionIds = attempt.incorrectOfficialQuestionIds.filter((questionId) => officialQuestionIds.includes(questionId));
      const conceptIds = assignedConceptIds.filter((id) => id.startsWith(`${quizId}-C`));
      const incorrectConceptCheckIds = wrongConceptIds.filter((id) => conceptIds.includes(id));
      if (officialQuestionIds.length + conceptIds.length === 0 && quizId !== attempt.quizId) continue;
      const correct = officialQuestionIds.length - incorrectOfficialQuestionIds.length + conceptIds.length - incorrectConceptCheckIds.length;
      const total = Math.max(1, officialQuestionIds.length + conceptIds.length);
      const id = quizId === attempt.quizId ? attempt.id : `${attempt.id}::${quizId}`;
      migrated.set(id, {
        ...attempt,
        id,
        quizId,
        lessonId: quiz.lessonId,
        correct,
        total,
        percent: (correct / total) * 100,
        officialQuestionIds,
        incorrectOfficialQuestionIds,
        incorrectConceptCheckIds,
      });
    }
  }
  return [...migrated.values()].sort((a, b) => codePointCompare(a.submittedAt, b.submittedAt) || codePointCompare(a.id, b.id));
}

function migrateProgressSyncDeviceRowsForLessonIDs(rows: ProgressSyncDeviceRows): ProgressSyncDeviceRows {
  return {
    ...rows,
    lessonProgress: Array.isArray(rows.lessonProgress) ? migrateDeviceLessonProgressRowsForLessonIDs(rows.lessonProgress) : rows.lessonProgress,
    lessonQuizAttempts: Array.isArray(rows.lessonQuizAttempts) ? migrateDeviceLessonQuizAttemptRowsForLessonIDs(rows.lessonQuizAttempts) : rows.lessonQuizAttempts,
  };
}

function migrateDeviceLessonProgressRowsForLessonIDs(rows: readonly DeviceLessonProgressRecord[]): DeviceLessonProgressRecord[] {
  const preserved = rows.filter((row) => !isRecord(row) || !isLessonProgressRecordLike(row.record) || !isSupportedLessonIdVersion(row.lessonIdVersion) || row.lessonIdVersion === CURRENT_LESSON_ID_VERSION);
  const legacy = rows.filter((row) => !preserved.includes(row));
  return [...preserved, ...[...groupBy(legacy, (row) => row.deviceId).values()].flatMap((deviceRows) =>
    migrateLessonProgressRecords(deduplicateDeviceLessonProgressForSync(deviceRows)).map((record) => ({
      deviceId: deviceRows[0]!.deviceId,
      record,
      lessonIdVersion: CURRENT_LESSON_ID_VERSION,
    }))),
  ];
}

function migrateDeviceLessonQuizAttemptRowsForLessonIDs(rows: readonly DeviceLessonQuizAttemptRecord[]): DeviceLessonQuizAttemptRecord[] {
  return rows.flatMap((row) => {
    if (!isRecord(row) || !isLessonQuizAttemptLike(row.attempt)) return [row];
    if (!isSupportedLessonIdVersion(row.lessonIdVersion)) return [row];
    if (row.lessonIdVersion === CURRENT_LESSON_ID_VERSION) return [row];
    return migrateLessonQuizAttempts([row.attempt]).map((attempt) => ({
      ...row,
      attempt,
      lessonIdVersion: CURRENT_LESSON_ID_VERSION,
    }));
  });
}

function isSupportedLessonIdVersion(value: unknown): value is LessonIdVersion | undefined {
  return value === undefined || value === LEGACY_LESSON_ID_VERSION || value === CURRENT_LESSON_ID_VERSION;
}

function filterSyncDeviceRowsForExport(rows: ProgressSyncDeviceRows | undefined, bank: BankData): ProgressSyncDeviceRows | undefined {
  if (rows === undefined) return undefined;
  if (!Array.isArray(rows.questionProgress) || !Array.isArray(rows.examAttempts) || !Array.isArray(rows.lessonProgress) || !Array.isArray(rows.morseCourseProgress)) return undefined;
  if (rows.questionProgress.some((row) => !isRecord(row) || !isRecord(row.record) || row.record.bankId !== bank.bankId)) return undefined;
  if (rows.examAttempts.some((row) => !isRecord(row) || !isRecord(row.attempt) || row.attempt.bankId !== bank.bankId)) return undefined;
  if (!bank.hasLessons && (rows.lessonProgress.length > 0 || (rows.lessonQuizAttempts?.length ?? 0) > 0)) return undefined;
  return rows;
}

function groupBy<T>(values: readonly T[], keyForValue: (value: T) => string): Map<string, T[]> {
  const groups = new Map<string, T[]>();
  for (const value of values) {
    const key = keyForValue(value);
    const group = groups.get(key);
    if (group === undefined) groups.set(key, [value]);
    else group.push(value);
  }
  return groups;
}

function deviceQuestionProgressTieBreak(a: DeviceQuestionProgressRecord, b: DeviceQuestionProgressRecord): number {
  return codePointCompare(a.record.lastAttemptedAt, b.record.lastAttemptedAt)
    || codePointCompare(a.deviceId, b.deviceId)
    || codePointCompare(a.record.leitner.dueAt, b.record.leitner.dueAt)
    || a.record.leitner.box - b.record.leitner.box
    || codePointCompare(a.record.lastResult, b.record.lastResult)
    || codePointCompare(a.record.lastAnsweredWithHelp ? "1" : "0", b.record.lastAnsweredWithHelp ? "1" : "0")
    || codePointCompare(a.record.recentResults.map((value) => (value ? "1" : "0")).join(""), b.record.recentResults.map((value) => (value ? "1" : "0")).join(""))
    || codePointCompare(recentAnsweredWithHelpForRecord(a.record).map((value) => (value ? "1" : "0")).join(""), recentAnsweredWithHelpForRecord(b.record).map((value) => (value ? "1" : "0")).join(""))
    || codePointCompare(a.record.notes ?? "", b.record.notes ?? "");
}

function examAttemptTieBreak(a: ExamAttempt, b: ExamAttempt): number {
  return codePointCompare(a.bankId, b.bankId) || codePointCompare(a.submittedAt, b.submittedAt) || codePointCompare(a.id, b.id);
}

function deviceExamAttemptTieBreak(a: DeviceExamAttemptRecord, b: DeviceExamAttemptRecord): number {
  return codePointCompare(a.attempt.bankId, b.attempt.bankId)
    || codePointCompare(a.attempt.submittedAt, b.attempt.submittedAt)
    || codePointCompare(a.deviceId, b.deviceId)
    || codePointCompare(a.attempt.startedAt, b.attempt.startedAt)
    || codePointCompare(a.attempt.id, b.attempt.id);
}

function deviceLessonProgressTieBreak(a: DeviceLessonProgressRecord, b: DeviceLessonProgressRecord): number {
  return codePointCompare(a.record.readAt, b.record.readAt)
    || codePointCompare(a.deviceId, b.deviceId)
    || a.record.readCount - b.record.readCount
    || codePointCompare(a.record.lessonId, b.record.lessonId);
}

function codePointCompare(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

export function serializeProgressExport(data: ProgressExportV1): string {
  return `${JSON.stringify(data, null, 2)}\n`;
}

function migrateDatabase(db: IDBDatabase, oldVersion: number, transaction: IDBTransaction | null): void {
  if (oldVersion < 1) {
    if (!db.objectStoreNames.contains("questionProgress")) {
      db.createObjectStore("questionProgress", { keyPath: "questionId" });
    }
    if (!db.objectStoreNames.contains("examAttempts")) {
      const store = db.createObjectStore("examAttempts", { keyPath: "id" });
      store.createIndex("submittedAt", "submittedAt", { unique: false });
    }
    if (!db.objectStoreNames.contains("preferences")) {
      db.createObjectStore("preferences", { keyPath: "key" });
    }
  }

  if (oldVersion < 2 && transaction !== null && db.objectStoreNames.contains("examAttempts")) {
    const attemptStore = transaction.objectStore("examAttempts");
    if (!attemptStore.indexNames.contains("submittedAt")) {
      attemptStore.createIndex("submittedAt", "submittedAt", { unique: false });
    }
  }

  if (oldVersion < 3) {
    if (!db.objectStoreNames.contains("lessonProgress")) {
      db.createObjectStore("lessonProgress", { keyPath: "lessonId" });
    }
    if (!db.objectStoreNames.contains("lessonQuizAttempts")) {
      const store = db.createObjectStore("lessonQuizAttempts", { keyPath: "id" });
      store.createIndex("submittedAt", "submittedAt", { unique: false });
      store.createIndex("lessonId", "lessonId", { unique: false });
    }
  }

  if (oldVersion < 4) {
    if (!db.objectStoreNames.contains("morseCourseProgress")) {
      db.createObjectStore("morseCourseProgress", { keyPath: "key" });
    }
  }

  if (oldVersion < 5) {
    if (!db.objectStoreNames.contains("syncMetadata")) {
      db.createObjectStore("syncMetadata", { keyPath: "key" });
    }
  }

  if (oldVersion < 6 && transaction !== null) {
    migrateLessonStoresForTask4610(transaction);
  }
}

function migrateLessonStoresForTask4610(transaction: IDBTransaction): void {
  if (transaction.objectStoreNames.contains("lessonProgress")) {
    const lessonStore = transaction.objectStore("lessonProgress");
    const request = lessonStore.getAll();
    request.onsuccess = () => {
      lessonStore.clear();
      for (const record of migrateLessonProgressRecords(request.result.filter(isLessonProgressRecordLike))) {
        lessonStore.put(record);
      }
    };
  }
  if (transaction.objectStoreNames.contains("lessonQuizAttempts")) {
    const quizStore = transaction.objectStore("lessonQuizAttempts");
    const request = quizStore.getAll();
    request.onsuccess = () => {
      quizStore.clear();
      for (const attempt of migrateLessonQuizAttempts(request.result.filter(isLessonQuizAttemptLike))) {
        quizStore.put(attempt);
      }
    };
  }
}

export function validateProgressImport(raw: unknown, bank: BankData = basicBank): ImportValidationResult {
  const errors: string[] = [];
  if (!isRecord(raw)) {
    return { ok: false, errors: ["Import file must be a JSON object."] };
  }
  if (raw.schema !== "canadian-ham.progress-export") {
    errors.push("Import file schema is not canadian-ham.progress-export.");
  }
  if (raw.version !== 1) {
    errors.push("Import file version must be 1.");
  }
  if (raw.lessonIdVersion !== undefined && !isSupportedLessonIdVersion(raw.lessonIdVersion)) {
    errors.push("Import lessonIdVersion must be 1 or 2 when present.");
  }
  if (raw.bankId !== undefined && raw.bankId !== bank.bankId) {
    errors.push(`Import bankId must be ${bank.bankId}.`);
  }
  if (typeof raw.exportedAt !== "string") {
    errors.push("Import exportedAt must be a canonical UTC timestamp string.");
  } else {
    pushCanonicalTimestampError(errors, raw.exportedAt, "exportedAt");
  }
  if (!Array.isArray(raw.questionProgress)) {
    errors.push("Import questionProgress must be an array.");
  }
  if (!Array.isArray(raw.examAttempts)) {
    errors.push("Import examAttempts must be an array.");
  }
  if (raw.lessonProgress !== undefined && !Array.isArray(raw.lessonProgress)) {
    errors.push("Import lessonProgress must be an array when present.");
  }
  if (raw.lessonQuizAttempts !== undefined && !Array.isArray(raw.lessonQuizAttempts)) {
    errors.push("Import lessonQuizAttempts must be an array when present.");
  }
  if (raw.morseCourseProgress !== undefined) {
    errors.push(...validateMorseCourseProgress(raw.morseCourseProgress));
  }
  if (!isPreferences(raw.preferences)) {
    errors.push("Import preferences are invalid.");
  }
  if (isRecord(raw.syncDeviceRows)) {
    errors.push(...validateSyncDeviceLessonRows(raw.syncDeviceRows, bank));
  }

  const questionProgress = Array.isArray(raw.questionProgress) ? raw.questionProgress : [];
  for (const [index, record] of questionProgress.entries()) {
    errors.push(...validateQuestionProgressRecord(record, index, bank));
  }

  const examAttempts = Array.isArray(raw.examAttempts) ? raw.examAttempts : [];
  const submittedAtValues = new Set<string>();
  for (const [index, attempt] of examAttempts.entries()) {
    errors.push(...validateExamAttempt(attempt, index, bank));
    if (isRecord(attempt) && typeof attempt.submittedAt === "string") {
      if (submittedAtValues.has(attempt.submittedAt)) {
        errors.push(`Import examAttempts[${index}].submittedAt duplicates another exam attempt.`);
      }
      submittedAtValues.add(attempt.submittedAt);
    }
  }

  const rawLessonProgress = Array.isArray(raw.lessonProgress) ? raw.lessonProgress : [];
  const rawLessonQuizAttempts = Array.isArray(raw.lessonQuizAttempts) ? raw.lessonQuizAttempts : [];
  const migratesTopLevelLessonRows = (raw.lessonIdVersion ?? LEGACY_LESSON_ID_VERSION) === LEGACY_LESSON_ID_VERSION;
  errors.push(...validateLessonImportRows(rawLessonProgress, rawLessonQuizAttempts, bank, migratesTopLevelLessonRows));
  if (errors.length > 0) {
    return { ok: false, errors };
  }

  let lessonProgress = migratesTopLevelLessonRows
    ? migrateLessonProgressRecords(rawLessonProgress as LessonProgressRecord[])
    : rawLessonProgress as LessonProgressRecord[];
  const lessonQuizAttempts = migratesTopLevelLessonRows
    ? migrateLessonQuizAttempts(rawLessonQuizAttempts as LessonQuizAttempt[])
    : rawLessonQuizAttempts as LessonQuizAttempt[];
  const syncDeviceRows = isRecord(raw.syncDeviceRows)
    ? migrateProgressSyncDeviceRowsForLessonIDs(raw.syncDeviceRows as unknown as ProgressSyncDeviceRows)
    : undefined;
  if (migratesTopLevelLessonRows && syncDeviceRows !== undefined && isRecord(raw.syncDeviceRows)) {
    const rawRows = (raw.syncDeviceRows as unknown as ProgressSyncDeviceRows).lessonProgress;
    const mergedRaw = deduplicateDeviceLessonProgressForSync(rawRows);
    const sortedRaw = [...rawLessonProgress as LessonProgressRecord[]].sort((a, b) => codePointCompare(a.lessonId, b.lessonId));
    if (mergedRaw.length === sortedRaw.length && mergedRaw.every((record, index) => record.lessonId === sortedRaw[index]!.lessonId && record.readAt === sortedRaw[index]!.readAt && record.readCount === sortedRaw[index]!.readCount)) {
      lessonProgress = deduplicateDeviceLessonProgressForSync(syncDeviceRows.lessonProgress);
    }
  }
  errors.push(...validateLessonImportRows(lessonProgress, lessonQuizAttempts, bank, false));
  if (syncDeviceRows !== undefined) {
    errors.push(...validateSyncDeviceLessonRows(syncDeviceRows as unknown as Record<string, unknown>, bank));
  }
  if (errors.length > 0) {
    return { ok: false, errors };
  }

  return {
    ok: true,
    errors: [],
    data: {
      schema: "canadian-ham.progress-export",
      version: 1,
      lessonIdVersion: CURRENT_LESSON_ID_VERSION,
      exportedAt: raw.exportedAt as string,
      bankId: bank.bankId,
      questionProgress: questionProgress.map((record) => normalizeQuestionProgressRecord(record, bank)) as QuestionProgressRecord[],
      examAttempts: examAttempts.map((attempt) => normalizeExamAttempt(attempt, bank)) as ExamAttempt[],
      lessonProgress: lessonProgress as LessonProgressRecord[],
      lessonQuizAttempts: lessonQuizAttempts as LessonQuizAttempt[],
      morseCourseProgress: raw.morseCourseProgress as MorseCourseProgressExport | undefined,
      ...(syncDeviceRows === undefined ? {} : { syncDeviceRows: normalizeProgressSyncDeviceRows(syncDeviceRows) }),
      preferences: normalizePreferences(raw.preferences),
    },
  };
}

function validateLessonImportRows(progress: readonly unknown[], attempts: readonly unknown[], bank: BankData, legacyLessonIds: boolean): string[] {
  const errors: string[] = [];
  const lessonProgressIds = new Set<string>();
  for (const [index, record] of progress.entries()) {
    errors.push(...validateLessonProgressRecord(record, index));
    if (isRecord(record) && typeof record.lessonId === "string") {
      if (lessonProgressIds.has(record.lessonId)) {
        errors.push(`Import lessonProgress[${index}].lessonId duplicates another lesson progress record.`);
      }
      lessonProgressIds.add(record.lessonId);
    }
  }
  const lessonQuizAttemptIds = new Set<string>();
  for (const [index, attempt] of attempts.entries()) {
    errors.push(...validateLessonQuizAttempt(attempt, index, bank, legacyLessonIds));
    if (isRecord(attempt) && typeof attempt.id === "string") {
      if (lessonQuizAttemptIds.has(attempt.id)) {
        errors.push(`Import lessonQuizAttempts[${index}].id duplicates another lesson quiz attempt.`);
      }
      lessonQuizAttemptIds.add(attempt.id);
    }
  }
  return errors;
}

function validateSyncDeviceLessonRows(value: Record<string, unknown>, bank: BankData): string[] {
  const errors: string[] = [];
  const lessonProgress = Array.isArray(value.lessonProgress) ? value.lessonProgress : [];
  for (const [index, row] of lessonProgress.entries()) {
    const prefix = `Import syncDeviceRows.lessonProgress[${index}]`;
    if (!isRecord(row)) {
      errors.push(`${prefix} must be an object.`);
      continue;
    }
    if (!isSupportedLessonIdVersion(row.lessonIdVersion)) {
      errors.push(`${prefix}.lessonIdVersion must be 1 or 2 when present.`);
    }
    errors.push(...validateLessonProgressRecord(row.record, index).map((error) => error.replace(`Import lessonProgress[${index}]`, `${prefix}.record`)));
  }
  const lessonQuizAttempts = Array.isArray(value.lessonQuizAttempts) ? value.lessonQuizAttempts : [];
  for (const [index, row] of lessonQuizAttempts.entries()) {
    const prefix = `Import syncDeviceRows.lessonQuizAttempts[${index}]`;
    if (!isRecord(row)) {
      errors.push(`${prefix} must be an object.`);
      continue;
    }
    if (!isSupportedLessonIdVersion(row.lessonIdVersion)) {
      errors.push(`${prefix}.lessonIdVersion must be 1 or 2 when present.`);
    }
    const legacyLessonIds = (row.lessonIdVersion ?? LEGACY_LESSON_ID_VERSION) === LEGACY_LESSON_ID_VERSION;
    errors.push(...validateLessonQuizAttempt(row.attempt, index, bank, legacyLessonIds).map((error) => error.replace(`Import lessonQuizAttempts[${index}]`, `${prefix}.attempt`)));
  }
  return errors;
}

function validateMorseCourseProgress(value: unknown): string[] {
  const prefix = "Import morseCourseProgress";
  const errors: string[] = [];
  if (!isRecord(value)) {
    return [`${prefix} must be an object when present.`];
  }
  if (typeof value.courseId !== "string" || value.courseId.length === 0) {
    errors.push(`${prefix}.courseId must be a non-empty string.`);
  }
  if (!Array.isArray(value.lessonProgress)) {
    errors.push(`${prefix}.lessonProgress must be an array.`);
  } else {
    const lessonIds = new Set<string>();
    value.lessonProgress.forEach((record, index) => {
      const recordPrefix = `${prefix}.lessonProgress[${index}]`;
      if (!isRecord(record)) {
        errors.push(`${recordPrefix} must be an object.`);
        return;
      }
      if (typeof record.lessonId !== "string" || !/^koch-\d{3}$/.test(record.lessonId)) {
        errors.push(`${recordPrefix}.lessonId must be a known Morse lesson ID.`);
      } else if (lessonIds.has(record.lessonId)) {
        errors.push(`${recordPrefix}.lessonId duplicates another Morse lesson record.`);
      }
      if (typeof record.lessonId === "string") lessonIds.add(record.lessonId);
      if (!isPositiveInteger(record.attempts)) errors.push(`${recordPrefix}.attempts must be a positive integer.`);
      if (!isRatio(record.bestAccuracy)) errors.push(`${recordPrefix}.bestAccuracy must be a number between 0 and 1.`);
      if (!isRatio(record.lastAccuracy)) errors.push(`${recordPrefix}.lastAccuracy must be a number between 0 and 1.`);
      if (typeof record.lastAttemptedAt !== "string") errors.push(`${recordPrefix}.lastAttemptedAt must be a canonical UTC timestamp string.`);
      else pushCanonicalTimestampError(errors, record.lastAttemptedAt, `${recordPrefix}.lastAttemptedAt`);
      if (record.completedAt !== undefined) {
        if (typeof record.completedAt !== "string") errors.push(`${recordPrefix}.completedAt must be a canonical UTC timestamp string.`);
        else pushCanonicalTimestampError(errors, record.completedAt, `${recordPrefix}.completedAt`);
      }
    });
  }
  if (!Array.isArray(value.characterStats)) {
    errors.push(`${prefix}.characterStats must be an array.`);
  } else {
    const characters = new Set<string>();
    value.characterStats.forEach((record, index) => {
      const recordPrefix = `${prefix}.characterStats[${index}]`;
      if (!isRecord(record)) {
        errors.push(`${recordPrefix} must be an object.`);
        return;
      }
      if (typeof record.character !== "string" || record.character.length !== 1) errors.push(`${recordPrefix}.character must be a single Morse character.`);
      else if (characters.has(record.character)) errors.push(`${recordPrefix}.character duplicates another character stat.`);
      if (typeof record.character === "string") characters.add(record.character);
      if (!isNonNegativeInteger(record.attempts)) errors.push(`${recordPrefix}.attempts must be a non-negative integer.`);
      if (!isNonNegativeInteger(record.correctAttempts)) errors.push(`${recordPrefix}.correctAttempts must be a non-negative integer.`);
      if (typeof record.attempts === "number" && typeof record.correctAttempts === "number" && record.correctAttempts > record.attempts) errors.push(`${recordPrefix}.correctAttempts must not exceed attempts.`);
      if (!Array.isArray(record.recentResults) || !record.recentResults.every((result) => typeof result === "boolean") || record.recentResults.length > 20) errors.push(`${recordPrefix}.recentResults must be an array of up to 20 booleans.`);
      if (typeof record.lastPracticedAt !== "string") errors.push(`${recordPrefix}.lastPracticedAt must be a canonical UTC timestamp string.`);
      else pushCanonicalTimestampError(errors, record.lastPracticedAt, `${recordPrefix}.lastPracticedAt`);
    });
  }
  if (!Array.isArray(value.dailyActivity)) {
    errors.push(`${prefix}.dailyActivity must be an array.`);
  } else {
    const dates = new Set<string>();
    value.dailyActivity.forEach((record, index) => {
      const recordPrefix = `${prefix}.dailyActivity[${index}]`;
      if (!isRecord(record)) {
        errors.push(`${recordPrefix} must be an object.`);
        return;
      }
      if (typeof record.date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(record.date)) errors.push(`${recordPrefix}.date must be YYYY-MM-DD.`);
      else if (dates.has(record.date)) errors.push(`${recordPrefix}.date duplicates another daily activity record.`);
      if (typeof record.date === "string") dates.add(record.date);
      if (!isNonNegativeInteger(record.lessonsCompleted)) errors.push(`${recordPrefix}.lessonsCompleted must be a non-negative integer.`);
    });
  }
  return errors;
}

function normalizeQuestionProgressRecord(record: unknown, bank: BankData): unknown {
  return isRecord(record) ? normalizeQuestionProgressRecordDefaults({ ...record, bankId: record.bankId ?? bank.bankId }) : record;
}

function normalizeQuestionProgressRecordDefaults(record: QuestionProgressRecord): QuestionProgressRecord;
function normalizeQuestionProgressRecordDefaults(record: Record<string, unknown>): Record<string, unknown>;
function normalizeQuestionProgressRecordDefaults(record: QuestionProgressRecord | Record<string, unknown>): QuestionProgressRecord | Record<string, unknown> {
  if (!Array.isArray(record.recentResults)) {
    return {
      ...record,
      lastAnsweredWithHelp: record.lastAnsweredWithHelp === true,
      recentAnsweredWithHelp: [],
    };
  }
  return {
    ...record,
    lastAnsweredWithHelp: record.lastAnsweredWithHelp === true,
    recentAnsweredWithHelp: recentAnsweredWithHelpForRecord(record),
  };
}

function recentAnsweredWithHelpForRecord(record: Pick<QuestionProgressRecord, "recentResults" | "recentAnsweredWithHelp"> | Record<string, unknown>): boolean[] {
  const recentResults = Array.isArray(record.recentResults) ? record.recentResults : [];
  const source = Array.isArray(record.recentAnsweredWithHelp) ? record.recentAnsweredWithHelp : [];
  return recentResults.map((_, index) => source[index] === true);
}

function normalizeProgressSyncDeviceRows(rows: ProgressSyncDeviceRows): ProgressSyncDeviceRows {
  if (!Array.isArray(rows.questionProgress)) {
    return rows;
  }
  return {
    ...rows,
    questionProgress: rows.questionProgress.map((row) => (
      isRecord(row) && isRecord(row.record)
        ? { ...row, record: normalizeQuestionProgressRecordDefaults(row.record) }
        : row
    )) as DeviceQuestionProgressRecord[],
  };
}

function normalizeExamAttempt(attempt: unknown, bank: BankData): unknown {
  if (!isRecord(attempt)) {
    return attempt;
  }
  const score = isRecord(attempt.score) ? { ...attempt.score, bankId: attempt.score.bankId ?? bank.bankId } : attempt.score;
  return { ...attempt, bankId: attempt.bankId ?? bank.bankId, score };
}

function requestToPromise<T>(request: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    request.onerror = () => reject(request.error ?? new Error("IndexedDB request failed"));
    request.onsuccess = () => resolve(request.result);
  });
}

function runTransaction(
  db: IDBDatabase,
  storeNames: string[],
  mode: IDBTransactionMode,
  work: (transaction: IDBTransaction) => void,
): Promise<void> {
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(storeNames, mode);
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error ?? new Error("IndexedDB transaction failed"));
    transaction.onabort = () => reject(transaction.error ?? new Error("IndexedDB transaction aborted"));
    work(transaction);
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isLessonProgressRecordLike(value: unknown): value is LessonProgressRecord {
  return isRecord(value)
    && typeof value.lessonId === "string"
    && typeof value.readAt === "string"
    && isPositiveInteger(value.readCount);
}

function isLessonQuizAttemptLike(value: unknown): value is LessonQuizAttempt {
  return isRecord(value)
    && typeof value.id === "string"
    && typeof value.quizId === "string"
    && typeof value.lessonId === "string"
    && typeof value.submittedAt === "string"
    && isNonNegativeInteger(value.correct)
    && isPositiveInteger(value.total)
    && isNonNegativeFiniteNumber(value.percent)
    && Array.isArray(value.officialQuestionIds)
    && value.officialQuestionIds.every((id) => typeof id === "string")
    && Array.isArray(value.incorrectOfficialQuestionIds)
    && value.incorrectOfficialQuestionIds.every((id) => typeof id === "string")
    && Array.isArray(value.incorrectConceptCheckIds)
    && value.incorrectConceptCheckIds.every((id) => typeof id === "string");
}

function normalizePreferences(value: unknown): WebPreferences {
  if (!isRecord(value)) {
    return defaultPreferences;
  }
  return {
    practiceMode: value.practiceMode === "review-later" ? "review-later" : "immediate",
    examTimerEnabled: typeof value.examTimerEnabled === "boolean" ? value.examTimerEnabled : defaultPreferences.examTimerEnabled,
    language: value.language === "en" || value.language === "fr" || value.language === "system" ? value.language : defaultPreferences.language,
    theme: value.theme === "light" || value.theme === "dark" || value.theme === "system" ? value.theme : defaultPreferences.theme,
    activeBankId: isCourseBankId(value.activeBankId) ? value.activeBankId : defaultPreferences.activeBankId,
    morse: normalizeMorsePreferences(isRecord(value.morse) ? value.morse : undefined),
  };
}

function isPreferences(value: unknown): value is WebPreferences {
  return isRecord(value)
    && (value.practiceMode === "immediate" || value.practiceMode === "review-later")
    && typeof value.examTimerEnabled === "boolean"
    && (value.language === undefined || value.language === "system" || value.language === "en" || value.language === "fr")
    && (value.theme === undefined || value.theme === "system" || value.theme === "light" || value.theme === "dark")
    && (value.activeBankId === undefined || isCourseBankId(value.activeBankId))
    && (value.morse === undefined || isMorsePreferences(value.morse));
}

function isMorsePreferences(value: unknown): value is WebMorsePreferences {
  return isRecord(value)
    && (value.enabled === undefined || typeof value.enabled === "boolean")
    && (value.toneHz === undefined || typeof value.toneHz === "number")
    && (value.characterWpm === undefined || typeof value.characterWpm === "number")
    && (value.effectiveWpm === undefined || typeof value.effectiveWpm === "number")
    && (value.timingProfile === undefined || value.timingProfile === "isedParis" || value.timingProfile === "ric1Literal" || value.timingProfile === "general")
    && (value.volume === undefined || typeof value.volume === "number")
    && (value.outputMode === undefined || value.outputMode === "audio" || value.outputMode === "visualBeacon" || value.outputMode === "visualTape");
}

function validateQuestionProgressRecord(value: unknown, index: number, bank: BankData): string[] {
  const prefix = `Import questionProgress[${index}]`;
  const errors: string[] = [];
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  if (typeof value.questionId !== "string" || !bank.knownQuestionIds.has(value.questionId)) {
    errors.push(`${prefix}.questionId must be a known question ID.`);
  }
  if (value.bankId !== undefined && value.bankId !== bank.bankId) {
    errors.push(`${prefix}.bankId must be ${bank.bankId}.`);
  }
  if (!isNonNegativeInteger(value.attempts)) {
    errors.push(`${prefix}.attempts must be a non-negative integer.`);
  }
  if (!isNonNegativeInteger(value.correctAttempts)) {
    errors.push(`${prefix}.correctAttempts must be a non-negative integer.`);
  }
  if (typeof value.lastAttemptedAt !== "string") {
    errors.push(`${prefix}.lastAttemptedAt must be a canonical UTC timestamp string.`);
  } else {
    pushCanonicalTimestampError(errors, value.lastAttemptedAt, `${prefix}.lastAttemptedAt`);
  }
  if (value.lastResult !== "correct" && value.lastResult !== "incorrect") {
    errors.push(`${prefix}.lastResult must be correct or incorrect.`);
  }
  if (!Array.isArray(value.recentResults) || !value.recentResults.every((result) => typeof result === "boolean") || value.recentResults.length > 5) {
    errors.push(`${prefix}.recentResults must be an array of up to five booleans.`);
  }
  if (value.lastAnsweredWithHelp !== undefined && typeof value.lastAnsweredWithHelp !== "boolean") {
    errors.push(`${prefix}.lastAnsweredWithHelp must be a boolean when present.`);
  }
  if (value.recentAnsweredWithHelp !== undefined && (!Array.isArray(value.recentAnsweredWithHelp) || !value.recentAnsweredWithHelp.every((result) => typeof result === "boolean") || value.recentAnsweredWithHelp.length > 5)) {
    errors.push(`${prefix}.recentAnsweredWithHelp must be an array of up to five booleans when present.`);
  }
  if (Array.isArray(value.recentResults) && Array.isArray(value.recentAnsweredWithHelp) && value.recentAnsweredWithHelp.length !== value.recentResults.length) {
    errors.push(`${prefix}.recentAnsweredWithHelp must have the same length as recentResults when present.`);
  }
  if (!isRecord(value.leitner)) {
    errors.push(`${prefix}.leitner must be an object.`);
  } else {
    const box = value.leitner.box;
    if (!Number.isInteger(box) || typeof box !== "number" || box < 0 || box > 5) {
      errors.push(`${prefix}.leitner.box must be an integer between 0 and 5.`);
    }
    if (typeof value.leitner.dueAt !== "string") {
      errors.push(`${prefix}.leitner.dueAt must be a canonical UTC timestamp string.`);
    } else {
      pushCanonicalTimestampError(errors, value.leitner.dueAt, `${prefix}.leitner.dueAt`);
    }
  }
  return errors;
}

function validateLessonProgressRecord(value: unknown, index: number): string[] {
  const prefix = `Import lessonProgress[${index}]`;
  const errors: string[] = [];
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  if (typeof value.lessonId !== "string" || !lessonsById.has(value.lessonId)) {
    errors.push(`${prefix}.lessonId must be a known lesson ID.`);
  }
  if (typeof value.readAt !== "string") {
    errors.push(`${prefix}.readAt must be a canonical UTC timestamp string.`);
  } else {
    pushCanonicalTimestampError(errors, value.readAt, `${prefix}.readAt`);
  }
  if (!isPositiveInteger(value.readCount)) {
    errors.push(`${prefix}.readCount must be a positive integer.`);
  }
  return errors;
}

// Version-1 membership before TASK-46.10, from content/quizzes at 350a3b53658c64f12e89c0b48d6b97c7c3040e88.
const legacyLessonQuizMembership: Readonly<Record<string, { readonly officialQuestionIds: readonly string[]; readonly conceptCheckIds: readonly string[] }>> = {
  "QZ-L-005-04-A": { officialQuestionIds: ["B-005-007-001", "B-005-007-005", "B-005-007-009", "B-005-008-003", "B-005-008-004", "B-005-008-005", "B-005-008-009", "B-005-008-011", "B-005-009-003", "B-005-009-011", "B-005-010-001", "B-005-010-009"], conceptCheckIds: ["QZ-L-005-04-A-C1", "QZ-L-005-04-A-C2", "QZ-L-005-04-A-C3"] },
  "QZ-L-005-05-A": { officialQuestionIds: ["B-005-011-001", "B-005-011-002", "B-005-011-004", "B-005-011-008", "B-005-012-001", "B-005-012-006", "B-005-012-008", "B-005-012-011", "B-005-013-001", "B-005-013-005", "B-005-013-006", "B-005-013-007", "B-005-013-010"], conceptCheckIds: ["QZ-L-005-05-A-C1", "QZ-L-005-05-A-C2", "QZ-L-005-05-A-C3"] },
  "QZ-L-008-01-A": { officialQuestionIds: ["B-008-001-001", "B-008-001-004", "B-008-001-006", "B-008-001-011", "B-008-002-001", "B-008-002-005", "B-008-002-011", "B-008-003-005"], conceptCheckIds: ["QZ-L-008-01-A-C1", "QZ-L-008-01-A-C2", "QZ-L-008-01-A-C3"] },
  "QZ-L-008-02-A": { officialQuestionIds: ["B-008-004-002", "B-008-004-005", "B-008-004-006", "B-008-004-008", "B-008-004-010", "B-008-005-002", "B-008-005-007", "B-008-005-009"], conceptCheckIds: ["QZ-L-008-02-A-C1", "QZ-L-008-02-A-C2", "QZ-L-008-02-A-C3"] },
  "QZ-L-001-03-A": { officialQuestionIds: ["B-001-010-001", "B-001-010-002", "B-001-010-003", "B-001-010-004", "B-001-010-005", "B-001-010-006", "B-001-010-007", "B-001-010-008", "B-001-010-009", "B-001-010-010", "B-001-011-001", "B-001-011-002", "B-001-011-003", "B-001-011-004", "B-001-011-005", "B-001-011-006", "B-001-011-007", "B-001-011-008", "B-001-011-009", "B-001-011-010", "B-001-012-001", "B-001-012-002", "B-001-012-003", "B-001-012-004", "B-001-013-001", "B-001-013-002", "B-001-013-003", "B-001-013-004", "B-001-013-005", "B-001-013-006", "B-001-013-007", "B-001-013-008", "B-001-013-009", "B-001-013-010", "B-001-013-011", "B-001-014-001", "B-001-014-002", "B-001-014-003", "B-001-014-004", "B-001-014-005", "B-001-014-006", "B-001-014-007", "B-001-014-008", "B-001-014-009", "B-001-014-010", "B-001-014-011"], conceptCheckIds: [] },
};

function validateLessonQuizAttempt(value: unknown, index: number, bank: BankData, legacyLessonIds = false): string[] {
  const prefix = `Import lessonQuizAttempts[${index}]`;
  const errors: string[] = [];
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  const quiz = typeof value.quizId === "string" ? lessonQuizzesById.get(value.quizId) : undefined;
  const legacyMembership = legacyLessonIds && typeof value.quizId === "string" ? legacyLessonQuizMembership[value.quizId] : undefined;
  if (typeof value.id !== "string" || value.id.length === 0) {
    errors.push(`${prefix}.id must be a non-empty string.`);
  }
  if (quiz === undefined) {
    errors.push(`${prefix}.quizId must be a known lesson quiz ID.`);
  }
  if (typeof value.lessonId !== "string" || !lessonsById.has(value.lessonId) || (quiz !== undefined && value.lessonId !== quiz.lessonId)) {
    errors.push(`${prefix}.lessonId must match the known lesson quiz.`);
  }
  if (typeof value.submittedAt !== "string") {
    errors.push(`${prefix}.submittedAt must be a canonical UTC timestamp string.`);
  } else {
    pushCanonicalTimestampError(errors, value.submittedAt, `${prefix}.submittedAt`);
  }
  if (!isNonNegativeInteger(value.correct)) {
    errors.push(`${prefix}.correct must be a non-negative integer.`);
  }
  if (!isPositiveInteger(value.total)) {
    errors.push(`${prefix}.total must be a positive integer.`);
  }
  if (!isNonNegativeFiniteNumber(value.percent) || (typeof value.percent === "number" && value.percent > 100)) {
    errors.push(`${prefix}.percent must be a number between 0 and 100.`);
  }
  if (typeof value.correct === "number" && typeof value.total === "number" && value.correct > value.total) {
    errors.push(`${prefix}.correct must not exceed total.`);
  }
  if (isNonNegativeInteger(value.correct) && isPositiveInteger(value.total) && isNonNegativeFiniteNumber(value.percent)) {
    const expectedPercent = (value.correct / value.total) * 100;
    if (Math.abs(value.percent - expectedPercent) > 1e-9) {
      errors.push(`${prefix}.percent must match correct divided by total.`);
    }
  }
  if (!isKnownQuestionIdArray(value.officialQuestionIds, bank)) {
    errors.push(`${prefix}.officialQuestionIds must contain known question IDs.`);
  } else if (quiz !== undefined && !value.officialQuestionIds.every((id) => legacyMembership === undefined
    ? quiz.officialQuestionIds.includes(id)
    : legacyMembership.officialQuestionIds.includes(id))) {
    errors.push(`${prefix}.officialQuestionIds must belong to the lesson quiz.`);
  }
  if (!isKnownQuestionIdArray(value.incorrectOfficialQuestionIds, bank)) {
    errors.push(`${prefix}.incorrectOfficialQuestionIds must contain known question IDs.`);
  } else if (Array.isArray(value.officialQuestionIds) && value.officialQuestionIds.every((id) => typeof id === "string")) {
    const officialQuestionIds = new Set(value.officialQuestionIds);
    if (!value.incorrectOfficialQuestionIds.every((id) => officialQuestionIds.has(id))) {
      errors.push(`${prefix}.incorrectOfficialQuestionIds must be a subset of officialQuestionIds.`);
    }
  }
  if (!Array.isArray(value.incorrectConceptCheckIds) || !value.incorrectConceptCheckIds.every((id) => typeof id === "string" && (quiz === undefined || (legacyMembership === undefined
    ? quiz.conceptChecks.some((conceptCheck) => conceptCheck.id === id)
    : legacyMembership.conceptCheckIds.includes(id))))) {
    errors.push(`${prefix}.incorrectConceptCheckIds must contain known concept check IDs for the quiz.`);
  }
  return errors;
}

function isKnownQuestionIdArray(value: unknown, bank: BankData): value is readonly string[] {
  return Array.isArray(value) && value.every((id) => typeof id === "string" && bank.knownQuestionIds.has(id));
}

function validateExamAttempt(value: unknown, index: number, bank: BankData): string[] {
  const prefix = `Import examAttempts[${index}]`;
  const errors: string[] = [];
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  if (typeof value.id !== "string" || value.id.length === 0) {
    errors.push(`${prefix}.id must be a non-empty string.`);
  }
  if (value.bankId !== undefined && value.bankId !== bank.bankId) {
    errors.push(`${prefix}.bankId must be ${bank.bankId}.`);
  }
  if (value.mode !== "mock-exam") {
    errors.push(`${prefix}.mode must be mock-exam.`);
  }
  if (typeof value.seed !== "string") {
    errors.push(`${prefix}.seed must be a string.`);
  }
  if (typeof value.startedAt !== "string") {
    errors.push(`${prefix}.startedAt must be a canonical UTC timestamp string.`);
  } else {
    pushCanonicalTimestampError(errors, value.startedAt, `${prefix}.startedAt`);
  }
  if (typeof value.submittedAt !== "string") {
    errors.push(`${prefix}.submittedAt must be a canonical UTC timestamp string.`);
  } else {
    pushCanonicalTimestampError(errors, value.submittedAt, `${prefix}.submittedAt`);
  }
  errors.push(...validateTimer(value.timer, `${prefix}.timer`));
  errors.push(...validateScore(value.score, `${prefix}.score`, bank));
  if (!Array.isArray(value.items)) {
    errors.push(`${prefix}.items must be an array.`);
  } else {
    for (const [itemIndex, item] of value.items.entries()) {
      errors.push(...validateExamAttemptItem(item, `${prefix}.items[${itemIndex}]`, bank));
    }
  }
  return errors;
}

function validateTimer(value: unknown, prefix: string): string[] {
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  const errors: string[] = [];
  if (typeof value.enabled !== "boolean") {
    errors.push(`${prefix}.enabled must be boolean.`);
  }
  if (!(value.secondsAllowed === null || isNonNegativeFiniteNumber(value.secondsAllowed))) {
    errors.push(`${prefix}.secondsAllowed must be null or a non-negative number.`);
  }
  if (!isNonNegativeFiniteNumber(value.secondsElapsed)) {
    errors.push(`${prefix}.secondsElapsed must be a non-negative number.`);
  }
  return errors;
}

function validateScore(value: unknown, prefix: string, bank: BankData): string[] {
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  const errors: string[] = [];
  if (value.bankId !== undefined && value.bankId !== bank.bankId) {
    errors.push(`${prefix}.bankId must be ${bank.bankId}.`);
  }
  if (!isNonNegativeInteger(value.correct)) {
    errors.push(`${prefix}.correct must be a non-negative integer.`);
  }
  if (!isNonNegativeInteger(value.total)) {
    errors.push(`${prefix}.total must be a non-negative integer.`);
  }
  if (!isNonNegativeFiniteNumber(value.percent)) {
    errors.push(`${prefix}.percent must be a non-negative number.`);
  }
  if (typeof value.passed !== "boolean") {
    errors.push(`${prefix}.passed must be boolean.`);
  }
  if (typeof value.honours !== "boolean") {
    errors.push(`${prefix}.honours must be boolean.`);
  } else if (!bank.hasHonours && value.honours) {
    errors.push(`${prefix}.honours must be false for this course.`);
  }
  if (!Array.isArray(value.categoryBreakdown)) {
    errors.push(`${prefix}.categoryBreakdown must be an array.`);
  } else {
    for (const [index, entry] of value.categoryBreakdown.entries()) {
      errors.push(...validateCategoryBreakdownEntry(entry, `${prefix}.categoryBreakdown[${index}]`, bank));
    }
  }
  if (!Array.isArray(value.weakSubsectionIds) || !value.weakSubsectionIds.every((id) => typeof id === "string" && bank.knownSubsectionIds.has(id))) {
    errors.push(`${prefix}.weakSubsectionIds must contain known subsection IDs.`);
  }
  return errors;
}

function validateCategoryBreakdownEntry(value: unknown, prefix: string, bank: BankData): string[] {
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  const errors: string[] = [];
  if (typeof value.categoryId !== "string" || !bank.knownCategoryIds.has(value.categoryId)) {
    errors.push(`${prefix}.categoryId must be a known category ID.`);
  }
  if (!isNonNegativeInteger(value.correct)) {
    errors.push(`${prefix}.correct must be a non-negative integer.`);
  }
  if (!isNonNegativeInteger(value.total)) {
    errors.push(`${prefix}.total must be a non-negative integer.`);
  }
  if (!isNonNegativeFiniteNumber(value.percent)) {
    errors.push(`${prefix}.percent must be a non-negative number.`);
  }
  return errors;
}

function validateExamAttemptItem(value: unknown, prefix: string, bank: BankData): string[] {
  if (!isRecord(value)) {
    return [`${prefix} must be an object.`];
  }
  const errors: string[] = [];
  const questionId = typeof value.questionId === "string" ? value.questionId : null;
  const questionIsKnown = questionId !== null && bank.knownQuestionIds.has(questionId);
  if (!questionIsKnown) {
    errors.push(`${prefix}.questionId must be a known question ID.`);
  }
  const position = value.position;
  if (!Number.isInteger(position) || typeof position !== "number" || position < 1) {
    errors.push(`${prefix}.position must be a positive integer.`);
  }
  const expectedSubsectionId = questionIsKnown ? questionId!.slice(0, 9) : null;
  const expectedCategoryId = questionIsKnown ? questionId!.slice(0, 5) : null;
  if (typeof value.subsectionId !== "string" || !bank.knownSubsectionIds.has(value.subsectionId) || (expectedSubsectionId !== null && value.subsectionId !== expectedSubsectionId)) {
    errors.push(`${prefix}.subsectionId must match the known question subsection.`);
  }
  if (typeof value.categoryId !== "string" || !bank.knownCategoryIds.has(value.categoryId) || (expectedCategoryId !== null && value.categoryId !== expectedCategoryId)) {
    errors.push(`${prefix}.categoryId must match the known question category.`);
  }
  if (!Array.isArray(value.choicePermutation) || value.choicePermutation.length !== 4 || !value.choicePermutation.every((entry) => Number.isInteger(entry) && entry >= 0 && entry <= 3) || new Set(value.choicePermutation).size !== 4) {
    errors.push(`${prefix}.choicePermutation must be a permutation of 0, 1, 2, 3.`);
  }
  const selectedSourceIndex = value.selectedSourceIndex;
  if (!(selectedSourceIndex === null || (Number.isInteger(selectedSourceIndex) && typeof selectedSourceIndex === "number" && selectedSourceIndex >= 0 && selectedSourceIndex <= 3))) {
    errors.push(`${prefix}.selectedSourceIndex must be null or an answer source index between 0 and 3.`);
  }
  if (typeof value.isCorrect !== "boolean") {
    errors.push(`${prefix}.isCorrect must be boolean.`);
  }
  if (typeof value.flagged !== "boolean") {
    errors.push(`${prefix}.flagged must be boolean.`);
  }
  return errors;
}

function pushCanonicalTimestampError(errors: string[], value: string, fieldName: string): void {
  try {
    // Route import validation through the engine's canonical timestamp parser.
    dueCount([{ questionId: "B-001-001-001", bankId: DEFAULT_BANK_ID, attempts: 0, correctAttempts: 0, lastAttemptedAt: value, lastResult: "incorrect", lastAnsweredWithHelp: false, recentResults: [], recentAnsweredWithHelp: [], leitner: { box: 0, dueAt: value } }], value);
  } catch (error) {
    errors.push(`${fieldName} must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ (${error instanceof Error ? error.message : String(error)}).`);
  }
}

function isNonNegativeInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value >= 0;
}

function isPositiveInteger(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value > 0;
}

function isNonNegativeFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0;
}

function isRatio(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 && value <= 1;
}
