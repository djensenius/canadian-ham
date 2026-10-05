import advancedCategoriesJson from "../../../../content/generated/advanced-2025-02-04/categories.json";
import { bankId as advancedManifestBankId, counts as advancedManifestCounts, effectiveDate as advancedManifestEffectiveDate, source as advancedManifestSource } from "../../../../content/generated/advanced-2025-02-04/manifest.json";
import advancedQuestionsJsonUrl from "../../../../content/generated/advanced-2025-02-04/questions.json?url";
import advancedSubsectionsJson from "../../../../content/generated/advanced-2025-02-04/subsections.json";
import basicCategoriesJson from "../../../../content/generated/basic-2025-07-15/categories.json";
import { bankId as basicManifestBankId, counts as basicManifestCounts, effectiveDate as basicManifestEffectiveDate, source as basicManifestSource } from "../../../../content/generated/basic-2025-07-15/manifest.json";
import basicQuestionsJsonUrl from "../../../../content/generated/basic-2025-07-15/questions.json?url";
import basicSubsectionsJson from "../../../../content/generated/basic-2025-07-15/subsections.json";
import subsectionTitlesJson from "../../../../content/subsection-titles.json";

export type Language = "en" | "fr";
export type CourseBankId = typeof BASIC_BANK_ID | typeof ADVANCED_BANK_ID;

export const BASIC_BANK_ID = "basic-2025-07-15";
export const ADVANCED_BANK_ID = "advanced-2025-02-04";
export const DEFAULT_BANK_ID: CourseBankId = BASIC_BANK_ID;

export interface LocalizedText {
  readonly en: string | null;
  readonly fr: string | null;
}

export interface Answer {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: {
    readonly en: string;
    readonly fr: string;
  };
}

export interface Question {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly sourceOrder: number;
  readonly text: {
    readonly en: string;
    readonly fr: string;
  };
  readonly answers: readonly Answer[];
}

export interface Category {
  readonly id: string;
  readonly bankId: string;
  readonly name: {
    readonly en: string;
    readonly fr: string | null;
  };
  readonly frenchNameStatus: "pending verification" | "verified";
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
  readonly title: LocalizedText;
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
  readonly source: {
    readonly path: string;
    readonly sha256: string;
    readonly url: string;
  };
}

export interface BankData {
  readonly bankId: CourseBankId;
  readonly course: "basic" | "advanced";
  readonly title: "Basic" | "Advanced";
  readonly manifest: BankManifest;
  readonly categories: readonly Category[];
  readonly subsections: readonly Subsection[];
  readonly subsectionTitles: readonly SubsectionTitle[];
  readonly categoriesById: ReadonlyMap<string, Category>;
  readonly subsectionsById: ReadonlyMap<string, Subsection>;
  readonly subsectionTitlesById: ReadonlyMap<string, SubsectionTitle>;
  readonly knownQuestionIds: ReadonlySet<string>;
  readonly knownCategoryIds: ReadonlySet<string>;
  readonly knownSubsectionIds: ReadonlySet<string>;
  readonly allQuestionCount: number;
  readonly hasLessons: boolean;
  readonly hasHonours: boolean;
  readonly mockExamQuestionCount: number;
  readonly passPercent: number;
  readonly honoursPercent: number | null;
  readonly questionsUrl: string;
}

interface ManifestImport {
  readonly bankId: string;
  readonly effectiveDate: string;
  readonly counts: BankManifest["counts"];
  readonly source: BankManifest["source"];
}

function defineManifest(imported: ManifestImport): BankManifest {
  return {
    bankId: imported.bankId,
    effectiveDate: imported.effectiveDate,
    counts: imported.counts,
    source: {
      path: imported.source.path,
      sha256: imported.source.sha256,
      url: imported.source.url,
    },
  };
}

function buildBankData(input: {
  readonly bankId: CourseBankId;
  readonly course: BankData["course"];
  readonly title: BankData["title"];
  readonly manifest: BankManifest;
  readonly categories: readonly Category[];
  readonly subsections: readonly Subsection[];
  readonly questionsUrl: string;
  readonly hasLessons: boolean;
  readonly hasHonours: boolean;
  readonly mockExamQuestionCount: number;
  readonly honoursPercent: number | null;
}): BankData {
  const subsectionTitles = input.course === "basic" ? (subsectionTitlesJson as readonly SubsectionTitle[]) : [];
  return {
    ...input,
    subsectionTitles,
    categoriesById: new Map(input.categories.map((category) => [category.id, category])),
    subsectionsById: new Map(input.subsections.map((subsection) => [subsection.id, subsection])),
    subsectionTitlesById: new Map(subsectionTitles.map((subsection) => [subsection.id, subsection])),
    knownQuestionIds: new Set(input.subsections.flatMap((subsection) => subsection.questionIds)),
    knownCategoryIds: new Set(input.categories.map((category) => category.id)),
    knownSubsectionIds: new Set(input.subsections.map((subsection) => subsection.id)),
    allQuestionCount: input.manifest.counts.questions,
    passPercent: 70,
  };
}

export const basicBank = buildBankData({
  bankId: BASIC_BANK_ID,
  course: "basic",
  title: "Basic",
  manifest: defineManifest({ bankId: basicManifestBankId, effectiveDate: basicManifestEffectiveDate, counts: basicManifestCounts, source: basicManifestSource }),
  categories: basicCategoriesJson as readonly Category[],
  subsections: basicSubsectionsJson as readonly Subsection[],
  questionsUrl: basicQuestionsJsonUrl,
  hasLessons: true,
  hasHonours: true,
  mockExamQuestionCount: 100,
  honoursPercent: 80,
});

export const advancedBank = buildBankData({
  bankId: ADVANCED_BANK_ID,
  course: "advanced",
  title: "Advanced",
  manifest: defineManifest({ bankId: advancedManifestBankId, effectiveDate: advancedManifestEffectiveDate, counts: advancedManifestCounts, source: advancedManifestSource }),
  categories: advancedCategoriesJson as readonly Category[],
  subsections: advancedSubsectionsJson as readonly Subsection[],
  questionsUrl: advancedQuestionsJsonUrl,
  hasLessons: false,
  hasHonours: false,
  mockExamQuestionCount: 50,
  honoursPercent: null,
});

export const bankCatalog = [basicBank, advancedBank] as const;
export const bankCatalogById = new Map<CourseBankId, BankData>(bankCatalog.map((bank) => [bank.bankId, bank]));

export function isCourseBankId(value: unknown): value is CourseBankId {
  return value === BASIC_BANK_ID || value === ADVANCED_BANK_ID;
}

export function bankDataForId(bankId: string | undefined | null): BankData {
  return bankCatalogById.get(isCourseBankId(bankId) ? bankId : DEFAULT_BANK_ID) ?? basicBank;
}

export function courseName(bank: Pick<BankData, "course">): "Basic" | "Advanced" {
  return bank.course === "advanced" ? "Advanced" : "Basic";
}

// Backwards-compatible Basic exports for tests and modules that have not opted into course selection.
export const manifest = basicBank.manifest;
export const categories = basicBank.categories;
export const subsections = basicBank.subsections;
export const subsectionTitles = basicBank.subsectionTitles;
export const allQuestionCount = basicBank.allQuestionCount;
export const bankId = basicBank.bankId;
export const categoriesById = basicBank.categoriesById;
export const subsectionsById = basicBank.subsectionsById;
export const subsectionTitlesById = basicBank.subsectionTitlesById;
export const knownQuestionIds = basicBank.knownQuestionIds;

const questionsPromises = new Map<CourseBankId, Promise<readonly Question[]>>();

export function loadQuestions(courseBankId: CourseBankId = DEFAULT_BANK_ID): Promise<readonly Question[]> {
  const bank = bankDataForId(courseBankId);
  const cached = questionsPromises.get(bank.bankId);
  if (cached !== undefined) {
    return cached;
  }
  const promise = loadQuestionsFromAsset(bank);
  questionsPromises.set(bank.bankId, promise);
  return promise;
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

export function subsectionTitle(subsectionId: string, bank: BankData = basicBank): string {
  const authored = bank.subsectionsById.get(subsectionId)?.title.en;
  if (authored !== null && authored !== undefined && authored.length > 0) {
    return authored;
  }
  return bank.subsectionTitlesById.get(subsectionId)?.title.en ?? subsectionId;
}

export interface LocalizedCategoryName {
  readonly text: string;
  readonly language: Language;
}

export function localizedCategoryNameWithLanguage(category: Category, language: Language): LocalizedCategoryName {
  const localizedName = category.name[language];
  return localizedName === null
    ? { text: category.name.en, language: "en" }
    : { text: localizedName, language };
}

export function localizedCategoryName(category: Category, language: Language): string {
  return localizedCategoryNameWithLanguage(category, language).text;
}

export function categoryNameWithLanguage(categoryId: string, language: Language = "en", bank: BankData = basicBank): LocalizedCategoryName {
  const category = bank.categoriesById.get(categoryId);
  return category === undefined ? { text: categoryId, language: "en" } : localizedCategoryNameWithLanguage(category, language);
}

export function categoryName(categoryId: string, language: Language = "en", bank: BankData = basicBank): string {
  return categoryNameWithLanguage(categoryId, language, bank).text;
}

async function loadQuestionsFromAsset(bank: BankData): Promise<readonly Question[]> {
  if (import.meta.env.MODE === "test") {
    if (bank.bankId === ADVANCED_BANK_ID) {
      const module = await import("../../../../content/generated/advanced-2025-02-04/questions.json");
      return module.default as readonly Question[];
    }
    const module = await import("../../../../content/generated/basic-2025-07-15/questions.json");
    return module.default as readonly Question[];
  }

  return loadQuestionsFromUrl(bank.questionsUrl);
}

export async function loadQuestionsFromUrl(assetUrl: string): Promise<readonly Question[]> {
  const response = await fetch(assetUrl);
  if (!response.ok) {
    throw new Error(`Unable to load bundled question bank (${response.status} ${response.statusText}).`);
  }
  return await response.json() as readonly Question[];
}
