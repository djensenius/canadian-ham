import {
  applyAnswer,
  buildSubsectionsFromQuestions,
  dueQuestionIds,
  generateExam,
  Pcg32,
  scoreExam,
  shuffled,
  weakSubsectionIds,
  type GeneratedExamItem,
  type QuestionProgressRecord,
} from "@canadian-ham/engine-ts";

import { bankId, questions, questionsById, subsections, type Question } from "../data/bank";
import type { ExamAttempt, ExamAttemptItem } from "./progressStore";

export type PracticeScope =
  | { readonly type: "all" }
  | { readonly type: "category"; readonly categoryId: string }
  | { readonly type: "subsection"; readonly subsectionId: string }
  | { readonly type: "weak" }
  | { readonly type: "due" };

export interface PracticeItem {
  readonly question: Question;
  readonly choicePermutation: readonly number[];
}

export interface PracticeSelectionInput {
  readonly scope: PracticeScope;
  readonly progress: readonly QuestionProgressRecord[];
  readonly latestExamItems?: readonly Pick<ExamAttemptItem, "questionId" | "subsectionId" | "selectedSourceIndex">[];
  readonly seed: string;
  readonly now: string;
  readonly limit?: number;
}

export function buildPracticeItems(input: PracticeSelectionInput): readonly PracticeItem[] {
  const eligible = eligibleQuestionsForScope(input.scope, input.progress, input.latestExamItems ?? [], input.now);
  const progressByQuestionId = new Map(input.progress.map((record) => [record.questionId, record]));
  const due = new Set(dueQuestionIds(input.progress, input.now));
  const weak = new Set(weakSubsectionIds(input.progress, input.latestExamItems ?? []));
  const rng = Pcg32.fromSeedString(input.seed);

  const prioritized = [...eligible]
    .map((question) => ({
      question,
      priority: due.has(question.id) ? 0 : progressByQuestionId.has(question.id) ? (weak.has(question.subsectionId) ? 2 : 3) : 1,
      tie: rng.nextUint32(),
    }))
    .sort((a, b) => a.priority - b.priority || a.tie - b.tie || a.question.id.localeCompare(b.question.id));

  return prioritized.slice(0, input.limit ?? 10).map(({ question }, index) => ({
    question,
    choicePermutation: shuffled([0, 1, 2, 3], Pcg32.fromSeedString(`${input.seed}:answer:${index}:${question.id}`)),
  }));
}

export function applyPracticeAnswer(
  records: readonly QuestionProgressRecord[],
  questionId: string,
  selectedSourceIndex: number,
  now: string,
): QuestionProgressRecord[] {
  const byQuestionId = new Map(records.map((record) => [record.questionId, record]));
  const updated = applyAnswer(byQuestionId.get(questionId), {
    questionId,
    bankId,
    isCorrect: selectedSourceIndex === 0,
    now,
  });
  byQuestionId.set(questionId, updated);
  return [...byQuestionId.values()].sort((a, b) => a.questionId.localeCompare(b.questionId));
}

export function createMockExam(seed: string): readonly GeneratedExamItem[] {
  return generateExam({
    bankId,
    seed,
    subsections: buildSubsectionsFromQuestions(questions),
    requireFullMockExam: true,
  }).items;
}

export function generatedExamQuestion(item: Pick<GeneratedExamItem, "questionId">): Question {
  const question = questionsById.get(item.questionId);
  if (question === undefined) {
    throw new Error(`Missing generated exam question ${item.questionId}`);
  }
  return question;
}

export function buildExamAttempt(input: {
  readonly seed: string;
  readonly startedAt: string;
  readonly submittedAt: string;
  readonly timerEnabled: boolean;
  readonly secondsElapsed: number;
  readonly generatedItems: readonly GeneratedExamItem[];
  readonly selectedByQuestionId: ReadonlyMap<string, number | null>;
  readonly flaggedQuestionIds: ReadonlySet<string>;
}): ExamAttempt {
  const items: ExamAttemptItem[] = input.generatedItems.map((item) => {
    const selectedSourceIndex = input.selectedByQuestionId.get(item.questionId) ?? null;
    return {
      ...item,
      selectedSourceIndex,
      isCorrect: selectedSourceIndex === 0,
      flagged: input.flaggedQuestionIds.has(item.questionId),
    };
  });
  const score = scoreExam(items);
  return {
    id: `attempt-${input.submittedAt}-local-${input.seed}`,
    bankId,
    mode: "mock-exam",
    seed: input.seed,
    startedAt: input.startedAt,
    submittedAt: input.submittedAt,
    timer: {
      enabled: input.timerEnabled,
      secondsAllowed: null,
      secondsElapsed: input.secondsElapsed,
    },
    items,
    score: {
      correct: score.correct,
      total: score.total,
      percent: score.percent,
      passed: score.passed,
      honours: score.honours,
      categoryBreakdown: score.categoryBreakdown,
      weakSubsectionIds: score.weakSubsectionIds,
    },
  };
}

function eligibleQuestionsForScope(
  scope: PracticeScope,
  progress: readonly QuestionProgressRecord[],
  latestExamItems: readonly Pick<ExamAttemptItem, "questionId" | "subsectionId" | "selectedSourceIndex">[],
  now: string,
): readonly Question[] {
  if (scope.type === "category") {
    return questions.filter((question) => question.categoryId === scope.categoryId);
  }
  if (scope.type === "subsection") {
    return questions.filter((question) => question.subsectionId === scope.subsectionId);
  }
  if (scope.type === "due") {
    const due = new Set(dueQuestionIds(progress, now));
    return questions.filter((question) => due.has(question.id));
  }
  if (scope.type === "weak") {
    const weak = new Set(weakSubsectionIds(progress, latestExamItems));
    return questions.filter((question) => weak.has(question.subsectionId));
  }
  return questions;
}

export function examCategoryCounts(items: readonly Pick<GeneratedExamItem, "categoryId">[]): readonly number[] {
  return Array.from({ length: 8 }, (_, index) => {
    const id = `B-${String(index + 1).padStart(3, "0")}`;
    return items.filter((item) => item.categoryId === id).length;
  });
}

export function allSubsectionIds(): readonly string[] {
  return subsections.map((subsection) => subsection.id);
}
