import { Pcg32, shuffled } from "@canadian-ham/engine-ts";

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

export interface LessonQuiz {
  readonly id: string;
  readonly lessonId: string;
  readonly officialQuestionIds: readonly string[];
  readonly conceptChecks: readonly ConceptCheck[];
}

export type LessonQuizItem =
  | { readonly type: "official"; readonly id: string; readonly questionId: string; readonly choicePermutation: readonly number[] }
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
  return shuffled([...officialItems, ...conceptItems], Pcg32.fromSeedString(`${seed}:items:${quiz.id}`));
}
