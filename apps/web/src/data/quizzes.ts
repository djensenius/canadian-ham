import { Pcg32, shuffled, selectLessonReviewItems } from "@canadian-ham/engine-ts";

import { orderedLessons } from "./lessons";
import { subsections } from "./bank";

const rawQuizModules = import.meta.glob("../../../../content/quizzes/*.json", {
  eager: true,
  import: "default",
}) as Record<string, LessonQuiz>;

export interface NullableLocalizedText {
  readonly en: string;
  readonly fr: string | null;
}

export interface ConceptCheckChoice {
  readonly text: NullableLocalizedText;
  readonly isCorrect: boolean;
  readonly feedback?: NullableLocalizedText;
}

export interface ConceptCheck {
  readonly id: string;
  readonly prompt: NullableLocalizedText;
  readonly choices: readonly ConceptCheckChoice[];
  readonly explanation: NullableLocalizedText;
}

export interface LessonQuizRound {
  readonly sectionAnchor: string;
  readonly title: NullableLocalizedText;
  readonly officialQuestionIds: readonly string[];
}

export interface LessonQuiz {
  readonly id: string;
  readonly lessonId: string;
  readonly officialQuestionIds: readonly string[];
  readonly conceptChecks: readonly ConceptCheck[];
  readonly rounds?: readonly LessonQuizRound[];
}

export type LessonQuizItem =
  | { readonly type: "official"; readonly id: string; readonly questionId: string; readonly reviewLessonId?: string; readonly choicePermutation: readonly number[] }
  | { readonly type: "concept"; readonly id: string; readonly conceptCheck: ConceptCheck; readonly choicePermutation: readonly number[] };

export const lessonQuizzes = Object.values(rawQuizModules).sort((a, b) => a.id.localeCompare(b.id));
export const lessonQuizzesById = new Map(lessonQuizzes.map((quiz) => [quiz.id, quiz]));

export function buildLessonQuizItems(quiz: LessonQuiz, seed: string): readonly LessonQuizItem[] {
  const officialItems: LessonQuizItem[] = quiz.officialQuestionIds.map((questionId, index) => ({
    type: "official",
    id: `${quiz.id}:official:${questionId}`,
    questionId,
    choicePermutation: shuffled([0, 1, 2, 3], Pcg32.fromSeedString(`${seed}:official:${index}:${questionId}`)),
  }));
  const conceptItems: LessonQuizItem[] = quiz.conceptChecks.map((conceptCheck, index) => ({
    type: "concept",
    id: `${quiz.id}:concept:${conceptCheck.id}`,
    conceptCheck,
    choicePermutation: shuffled(conceptCheck.choices.map((_, choiceIndex) => choiceIndex), Pcg32.fromSeedString(`${seed}:concept:${index}:${conceptCheck.id}`)),
  }));
  const items = shuffled([...officialItems, ...conceptItems], Pcg32.fromSeedString(`${seed}:items:${quiz.id}`));
  // Use synchronous Basic IDs: loading question text must not change a quiz session.
  const pools = orderedLessons().map((lesson) => ({ lessonId: lesson.id, questionIds: subsections.filter((subsection) => lesson.covers.includes(subsection.id)).flatMap((subsection) => subsection.questionIds) }));
  const currentLesson = orderedLessons().find((lesson) => lesson.id === quiz.lessonId);
  const excluded = [...quiz.officialQuestionIds, ...subsections.filter((subsection) => currentLesson?.covers.includes(subsection.id)).flatMap((subsection) => subsection.questionIds)];
  const reviewItems: LessonQuizItem[] = selectLessonReviewItems(pools, quiz.lessonId, excluded, seed).map((review, index) => ({
    type: "official", id: `${quiz.id}:review:${review.questionId}`, questionId: review.questionId, reviewLessonId: review.lessonId,
    choicePermutation: shuffled([0, 1, 2, 3], Pcg32.fromSeedString(`${seed}:review-choice:${index}:${review.questionId}`)),
  }));
  // Preserve each round's relative seeded order and every choice permutation.
  return [...(quiz.rounds === undefined || quiz.conceptChecks.length > 0 ? items : quiz.rounds.flatMap((round) => items.filter((item) => item.type === "official" && round.officialQuestionIds.includes(item.questionId)))), ...reviewItems];
}

export interface LessonQuizRoundProgress {
  readonly round: LessonQuizRound;
  readonly roundIndex: number;
  readonly roundCount: number;
  readonly startIndex: number;
  readonly endIndex: number;
  readonly questionCount: number;
}

export function lessonQuizRoundProgress(quiz: LessonQuiz, items: readonly LessonQuizItem[], currentIndex: number): LessonQuizRoundProgress | undefined {
  const currentItem = items[currentIndex];
  if (currentItem?.type !== "official" || quiz.rounds === undefined || quiz.conceptChecks.length > 0) return undefined;
  const reviewIds = items.flatMap((item) => item.type === "official" && item.reviewLessonId !== undefined ? [item.questionId] : []);
  const rounds = reviewIds.length === 0 ? quiz.rounds : [...quiz.rounds, { sectionAnchor: "review", title: { en: "Review", fr: "Révision" }, officialQuestionIds: reviewIds }];
  const roundIndex = rounds.findIndex((round) => round.officialQuestionIds.includes(currentItem.questionId));
  const round = rounds[roundIndex];
  if (round === undefined) return undefined;
  const indices = items.flatMap((item, index) => item.type === "official" && round.officialQuestionIds.includes(item.questionId) ? [index] : []);
  return { round, roundIndex, roundCount: rounds.length, startIndex: indices[0]!, endIndex: indices[indices.length - 1]!, questionCount: indices.length };
}
