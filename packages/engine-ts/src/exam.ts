import { Pcg32, RNG_ALGORITHM, shuffled } from "./rng.ts";

export interface ExamSubsectionInput {
  readonly id: string;
  readonly questionIds: readonly string[];
}

export interface QuestionRecordLike {
  readonly id: string;
  readonly categoryId: string;
  readonly subsectionId: string;
}

export interface ExamGenerationInput {
  readonly bankId: string;
  readonly seed: string;
  readonly subsections: readonly ExamSubsectionInput[];
  readonly answerSourceIndexes?: readonly number[];
  readonly requireFullMockExam?: boolean;
}

export interface GeneratedExamItem {
  readonly position: number;
  readonly questionId: string;
  readonly subsectionId: string;
  readonly categoryId: string;
  readonly choicePermutation: readonly number[];
}

export interface GeneratedExam {
  readonly bankId: string;
  readonly rng: {
    readonly algorithm: string;
    readonly seed: string;
  };
  readonly items: readonly GeneratedExamItem[];
}

export function categoryIdFromQuestionId(questionId: string): string {
  return questionId.slice(0, 5);
}

export function subsectionIdFromQuestionId(questionId: string): string {
  return questionId.slice(0, 9);
}

export function buildSubsectionsFromQuestions(questions: readonly QuestionRecordLike[]): ExamSubsectionInput[] {
  const grouped = new Map<string, string[]>();
  for (const question of questions) {
    const existing = grouped.get(question.subsectionId) ?? [];
    existing.push(question.id);
    grouped.set(question.subsectionId, existing);
  }
  return [...grouped.entries()]
    .map(([id, questionIds]) => ({ id, questionIds: questionIds.toSorted(compareOrdinal) }))
    .toSorted((a, b) => compareOrdinal(a.id, b.id));
}

export function generateExam(input: ExamGenerationInput): GeneratedExam {
  const answerSourceIndexes = input.answerSourceIndexes ?? [0, 1, 2, 3];
  if (answerSourceIndexes.length !== 4 || new Set(answerSourceIndexes).size !== 4 || !answerSourceIndexes.includes(0)) {
    throw new Error("answerSourceIndexes must contain four unique source indexes including correct source index 0");
  }

  const sortedSubsections = [...input.subsections]
    .map((subsection) => ({
      id: subsection.id,
      questionIds: [...subsection.questionIds].toSorted(compareOrdinal),
    }))
    .toSorted((a, b) => compareOrdinal(a.id, b.id));

  if (input.requireFullMockExam && sortedSubsections.length !== 100) {
    throw new Error(`full mock exam generation requires exactly 100 subsections; received ${sortedSubsections.length}`);
  }

  const uniqueSubsectionIds = new Set<string>();
  for (const subsection of sortedSubsections) {
    if (uniqueSubsectionIds.has(subsection.id)) {
      throw new Error(`duplicate subsection id ${subsection.id}`);
    }
    uniqueSubsectionIds.add(subsection.id);
    if (subsection.questionIds.length === 0) {
      throw new Error(`subsection ${subsection.id} has no questionIds`);
    }
  }

  const rng = Pcg32.fromSeedString(input.seed);
  const selected = sortedSubsections.map((subsection) => {
    const questionId = subsection.questionIds[rng.bounded(subsection.questionIds.length)];
    return {
      questionId,
      subsectionId: subsection.id,
      categoryId: categoryIdFromQuestionId(questionId),
    };
  });

  const ordered = shuffled(selected, rng);
  const items = ordered.map((item, index): GeneratedExamItem => ({
    position: index + 1,
    ...item,
    choicePermutation: shuffled(answerSourceIndexes, rng),
  }));

  return {
    bankId: input.bankId,
    rng: {
      algorithm: RNG_ALGORITHM,
      seed: input.seed,
    },
    items,
  };
}

export function categoryCounts(items: readonly Pick<GeneratedExamItem, "categoryId">[]): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const item of items) {
    counts[item.categoryId] = (counts[item.categoryId] ?? 0) + 1;
  }
  return Object.fromEntries(Object.entries(counts).toSorted(([a], [b]) => compareOrdinal(a, b)));
}

function compareOrdinal(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}
