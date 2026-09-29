import type { Language } from "./bank";

const rawExplanationModules = import.meta.glob("../../../../content/explanations/**/*.json", {
  eager: true,
  import: "default",
}) as Record<string, Explanation>;

export interface ExplanationCitation {
  readonly type: string;
  readonly id?: string;
  readonly url?: string;
}

export interface Explanation {
  readonly id: string;
  readonly questionId: string;
  readonly bankId: string;
  readonly status: string;
  readonly body: {
    readonly en: string;
    readonly fr: string | null;
  };
  readonly citations: readonly ExplanationCitation[];
  readonly licenseClass: "original";
}

export interface ParsedChoiceNote {
  readonly sourceIndex: number;
  readonly note: string;
}

export const explanations = Object.values(rawExplanationModules).sort((a, b) => a.questionId.localeCompare(b.questionId));
export const explanationsByQuestionId = new Map(explanations.map((explanation) => [explanation.questionId, explanation]));

export function explanationForQuestion(questionId: string): Explanation | null {
  return explanationsByQuestionId.get(questionId) ?? null;
}

export function explanationBody(explanation: Explanation, language: Language): string {
  return explanation.body[language] ?? explanation.body.en;
}

export function parseChoiceNotes(explanation: Explanation, language: Language): readonly ParsedChoiceNote[] {
  const body = explanationBody(explanation, language);
  return [...body.matchAll(/-\s*sourceIndex\s+(\d+):\s*([\s\S]*?)(?=\n-\s*sourceIndex\s+\d+:|\n\n|$)/g)]
    .map((match) => ({ sourceIndex: Number(match[1]), note: (match[2] ?? "").trim() }))
    .filter((note) => Number.isInteger(note.sourceIndex) && note.note.length > 0);
}

export function mainExplanationText(explanation: Explanation, language: Language): string {
  return explanationBody(explanation, language)
    .replace(/Why the distractors are wrong:\s*[\s\S]*$/i, "")
    .replace(/Question\s+B-\d{3}-\d{3}-\d{3}\.\s*/i, "")
    .trim();
}
