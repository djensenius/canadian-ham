import { BASIC_BANK_ID, type Language } from "./bank";

const rawHintModules = import.meta.glob("../../../../content/hints/**/*.json", {
  eager: true,
  import: "default",
}) as Record<string, QuestionHint>;

export type HintLevel = 1 | 2;

export type ReferenceSheetSectionKey =
  | "ohms-law"
  | "power"
  | "series-parallel-resistance"
  | "decibel-power-shortcuts"
  | "wavelength-dipole-length"
  | "metric-prefixes"
  | "resistor-colour-code";

export interface LocalizedHintText {
  readonly level: HintLevel;
  readonly en: string;
  readonly fr: string;
}

export interface HintLessonLink {
  readonly lessonId: string;
  readonly sectionAnchor?: string;
}

export interface QuestionHint {
  readonly id: string;
  readonly questionId: string;
  readonly bankId: string;
  readonly status: string;
  readonly hints: readonly LocalizedHintText[];
  readonly lessonLink: HintLessonLink;
  readonly singleLevelReason?: string;
  readonly referenceSheetSection?: ReferenceSheetSectionKey | null;
  readonly licenseClass: "original";
}

export const referenceSheetSectionLabels: Readonly<Record<ReferenceSheetSectionKey, Readonly<Record<Language, string>>>> = {
  "ohms-law": { en: "Ohm's law", fr: "Loi d'Ohm" },
  power: { en: "Power", fr: "Puissance" },
  "series-parallel-resistance": { en: "Series and parallel resistance", fr: "Résistance en série et en parallèle" },
  "decibel-power-shortcuts": { en: "Decibel power shortcuts", fr: "Repères de puissance en décibels" },
  "wavelength-dipole-length": { en: "Wavelength and dipole length", fr: "Longueur d'onde et longueur de dipôle" },
  "metric-prefixes": { en: "Metric prefixes", fr: "Préfixes métriques" },
  "resistor-colour-code": { en: "Four-band resistor colour code", fr: "Code de couleurs des résistances à quatre bandes" },
};

export const basicQuestionHints = Object.values(rawHintModules)
  .filter((hint) => hint.bankId === BASIC_BANK_ID)
  .sort((a, b) => a.questionId.localeCompare(b.questionId));

export const basicQuestionHintsByQuestionId = new Map(basicQuestionHints.map((hint) => [hint.questionId, hint]));

export function hintForQuestion(questionId: string, bankId: string): QuestionHint | null {
  if (bankId !== BASIC_BANK_ID) {
    return null;
  }
  return basicQuestionHintsByQuestionId.get(questionId) ?? null;
}

export function referenceSheetSectionLabel(section: ReferenceSheetSectionKey, language: Language): string {
  return referenceSheetSectionLabels[section][language];
}
