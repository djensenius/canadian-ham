import type { CategoryBreakdownEntry, QuestionProgressRecord } from "@canadian-ham/engine-ts";

import { bankId } from "../data/bank";

export type PracticeMode = "immediate" | "review-later";
export type ReadinessPreference = "not-enough-data" | "needs-review" | "pass-ready" | "honours-ready";

export interface WebPreferences {
  readonly practiceMode: PracticeMode;
  readonly examTimerEnabled: boolean;
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
    readonly correct: number;
    readonly total: number;
    readonly percent: number;
    readonly passed: boolean;
    readonly honours: boolean;
    readonly categoryBreakdown: readonly CategoryBreakdownEntry[];
    readonly weakSubsectionIds: readonly string[];
  };
}

export interface ProgressExportV1 {
  readonly schema: "canadian-ham.progress-export";
  readonly version: 1;
  readonly exportedAt: string;
  readonly bankId: string;
  readonly questionProgress: readonly QuestionProgressRecord[];
  readonly examAttempts: readonly ExamAttempt[];
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
};

const DB_VERSION = 1;
const DEFAULT_DB_NAME = "canadian-ham-web-progress";
const PREFERENCES_KEY = "preferences";

interface StoredPreferenceRecord {
  readonly key: string;
  readonly value: WebPreferences;
}

export class ProgressStore {
  #dbPromise: Promise<IDBDatabase> | null = null;

  constructor(private readonly dbName = DEFAULT_DB_NAME) {}

  async getQuestionProgress(): Promise<QuestionProgressRecord[]> {
    return this.getAll<QuestionProgressRecord>("questionProgress");
  }

  async putQuestionProgress(record: QuestionProgressRecord): Promise<void> {
    await this.put("questionProgress", record);
  }

  async putQuestionProgressMany(records: readonly QuestionProgressRecord[]): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["questionProgress"], "readwrite", (transaction) => {
      const store = transaction.objectStore("questionProgress");
      for (const record of records) {
        store.put(record);
      }
    });
  }

  async getExamAttempts(): Promise<ExamAttempt[]> {
    return this.getAll<ExamAttempt>("examAttempts");
  }

  async putExamAttempt(attempt: ExamAttempt): Promise<void> {
    await this.put("examAttempts", attempt);
  }

  async getPreferences(): Promise<WebPreferences> {
    const db = await this.open();
    const record = await requestToPromise<StoredPreferenceRecord | undefined>(
      db.transaction("preferences", "readonly").objectStore("preferences").get(PREFERENCES_KEY),
    );
    return { ...defaultPreferences, ...(record?.value ?? {}) };
  }

  async putPreferences(preferences: WebPreferences): Promise<void> {
    await this.put("preferences", { key: PREFERENCES_KEY, value: preferences });
  }

  async exportData(exportedAt: string): Promise<ProgressExportV1> {
    return {
      schema: "canadian-ham.progress-export",
      version: 1,
      exportedAt,
      bankId,
      questionProgress: await this.getQuestionProgress(),
      examAttempts: await this.getExamAttempts(),
      preferences: await this.getPreferences(),
    };
  }

  async importData(data: ProgressExportV1): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["questionProgress", "examAttempts", "preferences"], "readwrite", (transaction) => {
      transaction.objectStore("questionProgress").clear();
      transaction.objectStore("examAttempts").clear();
      transaction.objectStore("preferences").clear();
      const questionStore = transaction.objectStore("questionProgress");
      const attemptStore = transaction.objectStore("examAttempts");
      for (const record of data.questionProgress) {
        questionStore.put(record);
      }
      for (const attempt of data.examAttempts) {
        attemptStore.put(attempt);
      }
      transaction.objectStore("preferences").put({ key: PREFERENCES_KEY, value: { ...defaultPreferences, ...data.preferences } });
    });
  }

  async resetAllData(): Promise<void> {
    const db = await this.open();
    await runTransaction(db, ["questionProgress", "examAttempts", "preferences"], "readwrite", (transaction) => {
      transaction.objectStore("questionProgress").clear();
      transaction.objectStore("examAttempts").clear();
      transaction.objectStore("preferences").clear();
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

  private async put(storeName: string, value: unknown): Promise<void> {
    const db = await this.open();
    await runTransaction(db, [storeName], "readwrite", (transaction) => {
      transaction.objectStore(storeName).put(value);
    });
  }

  private open(): Promise<IDBDatabase> {
    this.#dbPromise ??= new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, DB_VERSION);
      request.onupgradeneeded = () => {
        const db = request.result;
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
      };
      request.onerror = () => reject(request.error ?? new Error("Unable to open progress database"));
      request.onsuccess = () => resolve(request.result);
    });
    return this.#dbPromise;
  }
}

export const defaultProgressStore = new ProgressStore();

export function serializeProgressExport(data: ProgressExportV1): string {
  return `${JSON.stringify(data, null, 2)}\n`;
}

export function validateProgressImport(raw: unknown): ImportValidationResult {
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
  if (raw.bankId !== bankId) {
    errors.push(`Import bankId must be ${bankId}.`);
  }
  if (typeof raw.exportedAt !== "string" || Number.isNaN(Date.parse(raw.exportedAt))) {
    errors.push("Import exportedAt must be an ISO timestamp string.");
  }
  if (!Array.isArray(raw.questionProgress)) {
    errors.push("Import questionProgress must be an array.");
  }
  if (!Array.isArray(raw.examAttempts)) {
    errors.push("Import examAttempts must be an array.");
  }
  if (!isPreferences(raw.preferences)) {
    errors.push("Import preferences are invalid.");
  }

  const questionProgress = Array.isArray(raw.questionProgress) ? raw.questionProgress : [];
  for (const [index, record] of questionProgress.entries()) {
    if (!isQuestionProgressRecord(record)) {
      errors.push(`Invalid questionProgress record at index ${index}.`);
      break;
    }
  }

  const examAttempts = Array.isArray(raw.examAttempts) ? raw.examAttempts : [];
  for (const [index, attempt] of examAttempts.entries()) {
    if (!isExamAttempt(attempt)) {
      errors.push(`Invalid examAttempts record at index ${index}.`);
      break;
    }
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
      exportedAt: raw.exportedAt as string,
      bankId,
      questionProgress: questionProgress as QuestionProgressRecord[],
      examAttempts: examAttempts as ExamAttempt[],
      preferences: { ...defaultPreferences, ...(raw.preferences as WebPreferences) },
    },
  };
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

function isPreferences(value: unknown): value is WebPreferences {
  return isRecord(value)
    && (value.practiceMode === "immediate" || value.practiceMode === "review-later")
    && typeof value.examTimerEnabled === "boolean";
}

function isQuestionProgressRecord(value: unknown): value is QuestionProgressRecord {
  if (!isRecord(value) || !isRecord(value.leitner)) {
    return false;
  }
  return typeof value.questionId === "string"
    && value.bankId === bankId
    && Number.isInteger(value.attempts)
    && Number.isInteger(value.correctAttempts)
    && typeof value.lastAttemptedAt === "string"
    && (value.lastResult === "correct" || value.lastResult === "incorrect")
    && Array.isArray(value.recentResults)
    && value.recentResults.every((result) => typeof result === "boolean")
    && Number.isInteger(value.leitner.box)
    && typeof value.leitner.dueAt === "string";
}

function isExamAttempt(value: unknown): value is ExamAttempt {
  if (!isRecord(value) || !isRecord(value.timer) || !isRecord(value.score) || !Array.isArray(value.items)) {
    return false;
  }
  return typeof value.id === "string"
    && value.bankId === bankId
    && value.mode === "mock-exam"
    && typeof value.seed === "string"
    && typeof value.startedAt === "string"
    && typeof value.submittedAt === "string"
    && typeof value.timer.enabled === "boolean"
    && (typeof value.timer.secondsAllowed === "number" || value.timer.secondsAllowed === null)
    && typeof value.timer.secondsElapsed === "number"
    && Number.isInteger(value.score.correct)
    && Number.isInteger(value.score.total)
    && typeof value.score.percent === "number"
    && typeof value.score.passed === "boolean"
    && typeof value.score.honours === "boolean"
    && Array.isArray(value.score.categoryBreakdown)
    && Array.isArray(value.score.weakSubsectionIds)
    && value.items.every(isExamAttemptItem);
}

function isExamAttemptItem(value: unknown): value is ExamAttemptItem {
  if (!isRecord(value)) {
    return false;
  }
  return Number.isInteger(value.position)
    && typeof value.questionId === "string"
    && typeof value.subsectionId === "string"
    && typeof value.categoryId === "string"
    && Array.isArray(value.choicePermutation)
    && value.choicePermutation.every((entry) => Number.isInteger(entry))
    && (Number.isInteger(value.selectedSourceIndex) || value.selectedSourceIndex === null)
    && typeof value.isCorrect === "boolean"
    && typeof value.flagged === "boolean";
}
