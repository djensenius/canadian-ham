import { subsectionIdFromQuestionId } from "./exam.ts";
import { compareOrdinal } from "./ordinal.ts";
import { parseCanonicalUtcTimestamp, requireCanonicalUtcTimestamp } from "./timestamps.ts";

const SECONDS_PER_DAY = 86_400;
const LEITNER_INTERVALS_BY_BOX: Record<number, number> = {
  1: 1 * SECONDS_PER_DAY,
  2: 3 * SECONDS_PER_DAY,
  3: 7 * SECONDS_PER_DAY,
  4: 14 * SECONDS_PER_DAY,
  5: 30 * SECONDS_PER_DAY,
};

export interface LeitnerState {
  readonly box: number;
  readonly dueAt: string;
}

export interface QuestionProgressRecord {
  readonly questionId: string;
  readonly bankId: string;
  readonly attempts: number;
  readonly correctAttempts: number;
  readonly lastAttemptedAt: string;
  readonly lastResult: "correct" | "incorrect";
  readonly lastAnsweredWithHelp: boolean;
  readonly recentResults: readonly boolean[];
  readonly recentAnsweredWithHelp: readonly boolean[];
  readonly leitner: LeitnerState;
  readonly notes?: string | null;
}

export interface AnswerUpdate {
  readonly questionId: string;
  readonly bankId: string;
  readonly isCorrect: boolean;
  readonly now: string;
  readonly answeredWithHelp?: boolean;
}

export interface LatestExamResultItem {
  readonly questionId: string;
  readonly subsectionId?: string;
  readonly selectedSourceIndex: number | null;
}

export function applyAnswer(
  existing: QuestionProgressRecord | null | undefined,
  update: AnswerUpdate,
): QuestionProgressRecord {
  requireCanonicalUtcTimestamp(update.now, "update.now");
  const previousBox = existing?.leitner.box ?? 0;
  const answeredWithHelp = update.answeredWithHelp ?? false;
  const givesMasteryCredit = update.isCorrect && !answeredWithHelp;
  const nextBox = givesMasteryCredit ? Math.min(previousBox + 1, 5) : update.isCorrect ? previousBox : 0;
  const dueAt = givesMasteryCredit ? addUtcSeconds(update.now, LEITNER_INTERVALS_BY_BOX[nextBox]) : normalizeIso(update.now);
  return {
    questionId: update.questionId,
    bankId: update.bankId,
    attempts: (existing?.attempts ?? 0) + 1,
    correctAttempts: (existing?.correctAttempts ?? 0) + (update.isCorrect ? 1 : 0),
    lastAttemptedAt: normalizeIso(update.now),
    lastResult: update.isCorrect ? "correct" : "incorrect",
    lastAnsweredWithHelp: answeredWithHelp,
    recentResults: appendRecentResult(existing?.recentResults ?? [], update.isCorrect),
    recentAnsweredWithHelp: appendRecentResult(alignedRecentAnsweredWithHelp(existing), answeredWithHelp),
    leitner: {
      box: nextBox,
      dueAt,
    },
    notes: existing?.notes ?? null,
  };
}

export function applyAnswerSequence(
  initialRecords: readonly QuestionProgressRecord[],
  updates: readonly AnswerUpdate[],
): QuestionProgressRecord[] {
  const byQuestionId = new Map(initialRecords.map((record) => [record.questionId, record]));
  for (const update of updates) {
    byQuestionId.set(update.questionId, applyAnswer(byQuestionId.get(update.questionId), update));
  }
  return [...byQuestionId.values()].toSorted((a, b) => compareOrdinal(a.questionId, b.questionId));
}

export function appendRecentResult(existing: readonly boolean[], newest: boolean): boolean[] {
  return [...existing, newest].slice(-5);
}

function alignedRecentAnsweredWithHelp(existing: QuestionProgressRecord | null | undefined): boolean[] {
  const recentResults = existing?.recentResults ?? [];
  const source = existing?.recentAnsweredWithHelp ?? [];
  return recentResults.map((_, index) => source[index] === true);
}

export function isDue(record: Pick<QuestionProgressRecord, "leitner">, now: string): boolean {
  return parseCanonicalUtcTimestamp(record.leitner.dueAt, "record.leitner.dueAt") <= parseCanonicalUtcTimestamp(now, "now");
}

export function dueQuestionIds(records: readonly QuestionProgressRecord[], now: string): string[] {
  return records
    .filter((record) => isDue(record, now))
    .map((record) => record.questionId)
    .toSorted(compareOrdinal);
}

export function dueCount(records: readonly QuestionProgressRecord[], now: string): number {
  return dueQuestionIds(records, now).length;
}

export function weakSubsectionIds(
  records: readonly (Pick<QuestionProgressRecord, "questionId" | "recentResults"> & { readonly recentAnsweredWithHelp?: readonly boolean[] })[],
  latestExamItems: readonly LatestExamResultItem[] = [],
): string[] {
  const subsectionAttempts = new Map<string, { correct: number; total: number }>();
  for (const record of records) {
    const subsectionId = subsectionIdFromQuestionId(record.questionId);
    const current = subsectionAttempts.get(subsectionId) ?? { correct: 0, total: 0 };
    const recentAnsweredWithHelp = record.recentAnsweredWithHelp ?? [];
    for (const [index, result] of record.recentResults.entries()) {
      // A helped correct answer counts as an attempt without proficiency credit, so it can
      // never clear a weak area, even when it rolls an older failure out of the window.
      const wasHelped = recentAnsweredWithHelp[index] === true;
      current.total += 1;
      if (result && !wasHelped) {
        current.correct += 1;
      }
    }
    subsectionAttempts.set(subsectionId, current);
  }

  const weak = new Set<string>();
  for (const [subsectionId, attempts] of subsectionAttempts) {
    if (attempts.total >= 2 && attempts.correct / attempts.total < 0.7) {
      weak.add(subsectionId);
    }
  }

  for (const item of latestExamItems) {
    if (item.selectedSourceIndex !== 0) {
      weak.add(item.subsectionId ?? subsectionIdFromQuestionId(item.questionId));
    }
  }

  return [...weak].toSorted(compareOrdinal);
}

function addUtcSeconds(iso: string, seconds: number): string {
  return new Date(Date.parse(iso) + seconds * 1000).toISOString();
}

function normalizeIso(iso: string): string {
  return new Date(Date.parse(iso)).toISOString();
}
