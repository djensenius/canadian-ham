import { BASIC_BANK_ID, rulesForBankId } from "./banks.ts";
import { categoryIdFromQuestionId, subsectionIdFromQuestionId } from "./exam.ts";
import { compareOrdinal } from "./ordinal.ts";

export interface ScoreInputItem {
  readonly questionId: string;
  readonly categoryId?: string;
  readonly subsectionId?: string;
  readonly selectedSourceIndex: number | null;
}

export interface CategoryBreakdownEntry {
  readonly categoryId: string;
  readonly correct: number;
  readonly total: number;
  readonly percent: number;
}

export interface ExamScore {
  readonly bankId: string;
  readonly correct: number;
  readonly total: number;
  readonly percent: number;
  readonly passed: boolean;
  readonly honours: boolean;
  readonly categoryBreakdown: readonly CategoryBreakdownEntry[];
  readonly incorrectQuestionIds: readonly string[];
  readonly weakSubsectionIds: readonly string[];
}

export interface ScoreExamOptions {
  readonly bankId?: string;
}

export function scoreExam(items: readonly ScoreInputItem[], options: ScoreExamOptions | string = {}): ExamScore {
  const bankId = typeof options === "string" ? options : options.bankId ?? BASIC_BANK_ID;
  const bankRules = rulesForBankId(bankId);
  const categoryTotals = new Map<string, { correct: number; total: number }>();
  const incorrectQuestionIds: string[] = [];
  const weakSubsectionIds = new Set<string>();
  let correct = 0;

  for (const item of items) {
    const categoryId = item.categoryId ?? categoryIdFromQuestionId(item.questionId);
    const subsectionId = item.subsectionId ?? subsectionIdFromQuestionId(item.questionId);
    const isCorrect = item.selectedSourceIndex === 0;
    if (isCorrect) {
      correct += 1;
    } else {
      incorrectQuestionIds.push(item.questionId);
      weakSubsectionIds.add(subsectionId);
    }

    const entry = categoryTotals.get(categoryId) ?? { correct: 0, total: 0 };
    entry.total += 1;
    if (isCorrect) {
      entry.correct += 1;
    }
    categoryTotals.set(categoryId, entry);
  }

  const total = items.length;
  const percent = percentFor(correct, total);
  const categoryBreakdown = [...categoryTotals.entries()]
    .toSorted(([a], [b]) => compareOrdinal(a, b))
    .map(([categoryId, value]) => ({
      categoryId,
      correct: value.correct,
      total: value.total,
      percent: percentFor(value.correct, value.total),
    }));

  return {
    bankId,
    correct,
    total,
    percent,
    passed: percent >= bankRules.passPercent,
    honours: bankRules.hasHonours && bankRules.honoursPercent !== null && percent >= bankRules.honoursPercent,
    categoryBreakdown,
    incorrectQuestionIds,
    weakSubsectionIds: [...weakSubsectionIds].toSorted(compareOrdinal),
  };
}

export function percentFor(correct: number, total: number): number {
  if (total === 0) {
    return 0;
  }
  return (correct / total) * 100;
}
