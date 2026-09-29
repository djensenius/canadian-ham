import categoriesJson from "../../../../content/generated/basic-2025-07-15/categories.json";
import manifestJson from "../../../../content/generated/basic-2025-07-15/manifest.json";
import questionsJsonUrl from "../../../../content/generated/basic-2025-07-15/questions.json?url";
import subsectionsJson from "../../../../content/generated/basic-2025-07-15/subsections.json";
import subsectionTitlesJson from "../../../../content/subsection-titles.json";

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

export interface SubsectionTitle {
  readonly id: string;
  readonly title: {
    readonly en: string;
    readonly fr: string | null;
  };
  readonly status: string;
}

export interface BankManifest {
  readonly bankId: string;
  readonly effectiveDate: string;
  readonly counts: {
    readonly questions: number;
    readonly categories: number;
    readonly subsections: number;
  };
}

export const manifest = manifestJson as BankManifest;
export const categories = categoriesJson as readonly Category[];
export const subsections = subsectionsJson as readonly Subsection[];
export const subsectionTitles = subsectionTitlesJson as readonly SubsectionTitle[];

export const allQuestionCount = manifest.counts.questions;
export const bankId = manifest.bankId;

export const categoriesById = new Map(categories.map((category) => [category.id, category]));
export const subsectionsById = new Map(subsections.map((subsection) => [subsection.id, subsection]));
export const subsectionTitlesById = new Map(subsectionTitles.map((subsection) => [subsection.id, subsection]));
export const knownQuestionIds = new Set(subsections.flatMap((subsection) => subsection.questionIds));

let questionsPromise: Promise<readonly Question[]> | null = null;

export function loadQuestions(): Promise<readonly Question[]> {
  questionsPromise ??= loadQuestionsFromAsset();
  return questionsPromise;
}

export function questionsById(questions: readonly Question[]): ReadonlyMap<string, Question> {
  return new Map(questions.map((question) => [question.id, question]));
}

export function questionsForCategory(questions: readonly Question[], categoryId: string): readonly Question[] {
  return questions.filter((question) => question.categoryId === categoryId);
}

export function questionsForSubsection(questions: readonly Question[], subsectionId: string): readonly Question[] {
  return questions.filter((question) => question.subsectionId === subsectionId);
}

export function subsectionTitle(subsectionId: string): string {
  return subsectionTitlesById.get(subsectionId)?.title.en ?? subsectionId;
}

export function categoryName(categoryId: string): string {
  return categoriesById.get(categoryId)?.name.en ?? categoryId;
}

async function loadQuestionsFromAsset(): Promise<readonly Question[]> {
  if (import.meta.env.MODE === "test") {
    const module = await import("../../../../content/generated/basic-2025-07-15/questions.json");
    return module.default as readonly Question[];
  }

  return loadQuestionsFromUrl(questionsJsonUrl);
}

export async function loadQuestionsFromUrl(assetUrl: string): Promise<readonly Question[]> {
  const response = await fetch(assetUrl);
  if (!response.ok) {
    throw new Error(`Unable to load bundled question bank (${response.status} ${response.statusText}).`);
  }
  return await response.json() as readonly Question[];
}
