import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
export const DEFAULT_HINT_ROOT = path.join(REPO_ROOT, "content/hints");

export const referenceSheetSectionKeys = [
  "ohms-law",
  "power",
  "series-parallel-resistance",
  "decibel-power-shortcuts",
  "wavelength-dipole-length",
  "metric-prefixes",
  "resistor-colour-code",
] as const;

export type ReferenceSheetSectionKey = typeof referenceSheetSectionKeys[number];

export type LocalizedReferenceSheetSectionLabel = {
  readonly en: string;
  readonly fr: string;
};

export const referenceSheetSectionLabels: Readonly<Record<ReferenceSheetSectionKey, LocalizedReferenceSheetSectionLabel>> = {
  "ohms-law": { en: "Ohm's law", fr: "Loi d'Ohm" },
  power: { en: "Power", fr: "Puissance" },
  "series-parallel-resistance": { en: "Series and parallel resistance", fr: "Résistance en série et en parallèle" },
  "decibel-power-shortcuts": { en: "Decibel power shortcuts", fr: "Repères de puissance en décibels" },
  "wavelength-dipole-length": { en: "Wavelength and dipole length", fr: "Longueur d'onde et longueur de dipôle" },
  "metric-prefixes": { en: "Metric prefixes", fr: "Préfixes métriques" },
  "resistor-colour-code": { en: "Four-band resistor colour code", fr: "Code de couleurs des résistances à quatre bandes" },
};

export type HintLevel = 1 | 2;

export interface QuestionHintStep {
  readonly level: HintLevel;
  readonly en: string;
  readonly fr: string;
}

export interface QuestionHint {
  readonly id: string;
  readonly questionId: string;
  readonly bankId: string;
  readonly status: string;
  readonly hints: readonly [QuestionHintStep, QuestionHintStep];
  readonly referenceSheetSection?: ReferenceSheetSectionKey | null;
  readonly licenseClass: "original";
}

export interface LoadedQuestionHint extends QuestionHint {
  readonly filePath: string;
}

export interface LoadQuestionHintsOptions {
  readonly hintRoot?: string;
}

async function findJsonFiles(root: string, current = root): Promise<string[]> {
  let entries;
  try {
    entries = await readdir(current, { withFileTypes: true });
  } catch (error: unknown) {
    if (current === root && isNodeError(error) && error.code === "ENOENT") {
      return [];
    }
    throw error;
  }

  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(current, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findJsonFiles(root, entryPath));
    } else if (entry.isFile() && entry.name.endsWith(".json")) {
      files.push(entryPath);
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

function isNodeError(error: unknown): error is NodeJS.ErrnoException {
  return error instanceof Error && "code" in error;
}

export async function loadQuestionHints(options: LoadQuestionHintsOptions = {}): Promise<readonly LoadedQuestionHint[]> {
  const hintRoot = options.hintRoot ?? DEFAULT_HINT_ROOT;
  const hints: LoadedQuestionHint[] = [];
  for (const filePath of await findJsonFiles(hintRoot)) {
    const parsed = JSON.parse(await readFile(filePath, "utf8")) as QuestionHint;
    hints.push({ ...parsed, filePath });
  }
  return hints.sort((a, b) => a.questionId.localeCompare(b.questionId) || a.id.localeCompare(b.id) || a.filePath.localeCompare(b.filePath));
}

export function questionHintsByQuestionId(hints: readonly QuestionHint[]): ReadonlyMap<string, QuestionHint> {
  return new Map(hints.map((hint) => [hint.questionId, hint]));
}

export function hintForQuestion(hints: readonly QuestionHint[], questionId: string): QuestionHint | null {
  return questionHintsByQuestionId(hints).get(questionId) ?? null;
}
