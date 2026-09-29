import { percentFor, type CategoryBreakdownEntry } from "./scoring.ts";
import { parseCanonicalUtcTimestamp, requireCanonicalUtcTimestamp } from "./timestamps.ts";

export type ReadinessState = "not-enough-data" | "needs-review" | "pass-ready" | "honours-ready";

export interface ReadinessExamAttempt {
  readonly submittedAt: string;
  readonly score: {
    readonly correct: number;
    readonly total: number;
    readonly percent?: number;
  };
  readonly categoryBreakdown: readonly CategoryBreakdownEntry[];
}

export interface ReadinessInput {
  readonly completedExams: readonly ReadinessExamAttempt[];
  readonly dueReviewCount: number;
}

export interface ReadinessResult {
  readonly state: ReadinessState;
  readonly consideredExamCount: number;
  readonly consideredSubmittedAt: readonly string[];
  readonly reasons: readonly ReadinessReason[];
}

export type ReadinessReason =
  | { readonly type: "not-enough-exams"; readonly completedExamCount: number }
  | { readonly type: "weak-categories"; readonly categoryIds: readonly string[] }
  | { readonly type: "due-review"; readonly dueReviewCount: number }
  | { readonly type: "exam-threshold"; readonly threshold: 70 | 80; readonly countAtOrAbove: number };

export function computeReadiness(input: ReadinessInput): ReadinessResult {
  assertUniqueSubmittedAt(input.completedExams);
  const completed = [...input.completedExams].toSorted(
    (a, b) => parseCanonicalUtcTimestamp(b.submittedAt, "submittedAt") - parseCanonicalUtcTimestamp(a.submittedAt, "submittedAt"),
  );
  if (completed.length < 2) {
    return {
      state: "not-enough-data",
      consideredExamCount: completed.length,
      consideredSubmittedAt: completed.map((attempt) => attempt.submittedAt),
      reasons: [{ type: "not-enough-exams", completedExamCount: completed.length }],
    };
  }

  const considered = completed.slice(0, 3);
  const weakCategories = aggregateWeakCategories(considered);
  if (weakCategories.length > 0) {
    return {
      state: "needs-review",
      consideredExamCount: considered.length,
      consideredSubmittedAt: considered.map((attempt) => attempt.submittedAt),
      reasons: [{ type: "weak-categories", categoryIds: weakCategories }],
    };
  }

  if (input.dueReviewCount >= 5) {
    return {
      state: "needs-review",
      consideredExamCount: considered.length,
      consideredSubmittedAt: considered.map((attempt) => attempt.submittedAt),
      reasons: [{ type: "due-review", dueReviewCount: input.dueReviewCount }],
    };
  }

  const honoursCount = considered.filter((attempt) => scorePercent(attempt) >= 80).length;
  if (honoursCount >= 2) {
    return {
      state: "honours-ready",
      consideredExamCount: considered.length,
      consideredSubmittedAt: considered.map((attempt) => attempt.submittedAt),
      reasons: [{ type: "exam-threshold", threshold: 80, countAtOrAbove: honoursCount }],
    };
  }

  const passCount = considered.filter((attempt) => scorePercent(attempt) >= 70).length;
  if (passCount >= 2) {
    return {
      state: "pass-ready",
      consideredExamCount: considered.length,
      consideredSubmittedAt: considered.map((attempt) => attempt.submittedAt),
      reasons: [{ type: "exam-threshold", threshold: 70, countAtOrAbove: passCount }],
    };
  }

  return {
    state: "needs-review",
    consideredExamCount: considered.length,
    consideredSubmittedAt: considered.map((attempt) => attempt.submittedAt),
    reasons: [],
  };
}

function assertUniqueSubmittedAt(attempts: readonly ReadinessExamAttempt[]): void {
  const seen = new Set<string>();
  for (const attempt of attempts) {
    requireCanonicalUtcTimestamp(attempt.submittedAt, "submittedAt");
    if (seen.has(attempt.submittedAt)) {
      throw new Error(`completedExams must not contain duplicate submittedAt timestamp ${attempt.submittedAt}`);
    }
    seen.add(attempt.submittedAt);
  }
}

function aggregateWeakCategories(attempts: readonly ReadinessExamAttempt[]): string[] {
  const aggregate = new Map<string, { correct: number; total: number }>();
  for (const attempt of attempts) {
    for (const category of attempt.categoryBreakdown) {
      const current = aggregate.get(category.categoryId) ?? { correct: 0, total: 0 };
      current.correct += category.correct;
      current.total += category.total;
      aggregate.set(category.categoryId, current);
    }
  }

  return [...aggregate.entries()]
    .filter(([, value]) => value.total > 0 && percentFor(value.correct, value.total) < 70)
    .map(([categoryId]) => categoryId)
    .toSorted(compareOrdinal);
}

function scorePercent(attempt: ReadinessExamAttempt): number {
  return attempt.score.percent ?? percentFor(attempt.score.correct, attempt.score.total);
}

function compareOrdinal(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
