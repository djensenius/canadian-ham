import categoriesJson from "../../../../content/generated/basic-2025-07-15/categories.json";
import questionsJson from "../../../../content/generated/basic-2025-07-15/questions.json";
import subsectionsJson from "../../../../content/generated/basic-2025-07-15/subsections.json";

export type Language = "en" | "fr";

export interface LocalizedText {
  readonly en: string;
  readonly fr: string;
}

export interface Answer {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: LocalizedText;
}

export interface Question {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly sourceOrder: number;
  readonly text: LocalizedText;
  readonly answers: readonly Answer[];
}

export interface Category {
  readonly id: string;
  readonly bankId: string;
  readonly name: {
    readonly en: string;
    readonly fr: string | null;
  };
  readonly frenchNameStatus: "pending verification";
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly examQuestionCount: number;
  readonly nameSource: string;
}

export interface Subsection {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly questionIds: readonly string[];
  readonly questionCount: number;
  readonly lessonIds: readonly string[];
  readonly title: {
    readonly en: string | null;
    readonly fr: string | null;
  };
}

export const questions = questionsJson as readonly Question[];
export const categories = categoriesJson as readonly Category[];
export const subsections = subsectionsJson as readonly Subsection[];

export const allQuestionCount = questions.length;

export function questionsForScope(scopeId: string): readonly Question[] {
  if (scopeId === "all") {
    return questions;
  }
  return questions.filter((question) => question.categoryId === scopeId);
}
