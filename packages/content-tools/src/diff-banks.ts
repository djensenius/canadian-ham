import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { isMainModule } from "./cli.ts";

const DEFAULT_REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const LANGUAGES = ["en", "fr"] as const;

type Language = typeof LANGUAGES[number];

interface LocalizedText {
  readonly en: string;
  readonly fr: string;
}

interface Answer {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: LocalizedText;
}

interface Question {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly sourceOrder: number;
  readonly text: LocalizedText;
  readonly answers: readonly Answer[];
}

interface Subsection {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly questionIds: readonly string[];
  readonly questionCount: number;
}

interface GeneratedManifest {
  readonly bankId: string;
  readonly effectiveDate?: string;
}

interface BankSummary {
  readonly directory: string;
  readonly bankId: string;
  readonly effectiveDate: string | null;
  readonly questionCount: number;
  readonly subsectionCount: number;
}

interface GeneratedBank {
  readonly summary: BankSummary;
  readonly questionsById: ReadonlyMap<string, Question>;
  readonly subsectionsById: ReadonlyMap<string, Subsection>;
}

export interface LocalizedFieldChange {
  readonly from: string;
  readonly to: string;
}

export interface QuestionTextChange {
  readonly id: string;
  readonly changes: Partial<Record<Language, LocalizedFieldChange>>;
}

export interface AnswerSnapshot {
  readonly isCorrect: boolean;
  readonly text: LocalizedText;
}

export interface AnswerChange {
  readonly id: string;
  readonly sourceIndex: number;
  readonly previous: AnswerSnapshot | null;
  readonly current: AnswerSnapshot | null;
  readonly changedFields: readonly string[];
}

export interface SubsectionCountChange {
  readonly id: string;
  readonly fromQuestionCount: number;
  readonly toQuestionCount: number;
  readonly fromQuestionIds: readonly string[];
  readonly toQuestionIds: readonly string[];
}

export interface BankDiffReport {
  readonly from: BankSummary;
  readonly to: BankSummary;
  readonly summary: {
    readonly addedQuestionCount: number;
    readonly removedQuestionCount: number;
    readonly questionTextChangeCount: number;
    readonly answerChangeCount: number;
    readonly addedSubsectionCount: number;
    readonly removedSubsectionCount: number;
    readonly subsectionCountChangeCount: number;
  };
  readonly questions: {
    readonly added: readonly string[];
    readonly removed: readonly string[];
    readonly changedText: readonly QuestionTextChange[];
    readonly changedAnswers: readonly AnswerChange[];
  };
  readonly subsections: {
    readonly added: readonly string[];
    readonly removed: readonly string[];
    readonly countChanged: readonly SubsectionCountChange[];
  };
}

function fail(message: string): never {
  throw new Error(message);
}

function asObject(value: unknown, label: string): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    fail(`${label} must be a JSON object`);
  }
  return value as Record<string, unknown>;
}

function asArray(value: unknown, label: string): readonly unknown[] {
  if (!Array.isArray(value)) {
    fail(`${label} must be a JSON array`);
  }
  return value;
}

function asString(value: unknown, label: string): string {
  if (typeof value !== "string") {
    fail(`${label} must be a string`);
  }
  return value;
}

function asOptionalString(value: unknown, label: string): string | undefined {
  if (value === undefined) {
    return undefined;
  }
  return asString(value, label);
}

function asNumber(value: unknown, label: string): number {
  if (typeof value !== "number" || !Number.isInteger(value)) {
    fail(`${label} must be an integer`);
  }
  return value;
}

function asBoolean(value: unknown, label: string): boolean {
  if (typeof value !== "boolean") {
    fail(`${label} must be a boolean`);
  }
  return value;
}

function parseLocalizedText(value: unknown, label: string): LocalizedText {
  const object = asObject(value, label);
  return {
    en: asString(object.en, `${label}.en`),
    fr: asString(object.fr, `${label}.fr`),
  };
}

function parseAnswer(value: unknown, label: string): Answer {
  const object = asObject(value, label);
  return {
    sourceIndex: asNumber(object.sourceIndex, `${label}.sourceIndex`),
    isCorrect: asBoolean(object.isCorrect, `${label}.isCorrect`),
    text: parseLocalizedText(object.text, `${label}.text`),
  };
}

function parseQuestion(value: unknown, label: string): Question {
  const object = asObject(value, label);
  return {
    id: asString(object.id, `${label}.id`),
    bankId: asString(object.bankId, `${label}.bankId`),
    categoryId: asString(object.categoryId, `${label}.categoryId`),
    subsectionId: asString(object.subsectionId, `${label}.subsectionId`),
    sourceOrder: asNumber(object.sourceOrder, `${label}.sourceOrder`),
    text: parseLocalizedText(object.text, `${label}.text`),
    answers: asArray(object.answers, `${label}.answers`).map((answer, index) => parseAnswer(answer, `${label}.answers[${index}]`)),
  };
}

function parseSubsection(value: unknown, label: string): Subsection {
  const object = asObject(value, label);
  const questionIds = asArray(object.questionIds, `${label}.questionIds`).map((questionId, index) => (
    asString(questionId, `${label}.questionIds[${index}]`)
  ));
  return {
    id: asString(object.id, `${label}.id`),
    bankId: asString(object.bankId, `${label}.bankId`),
    categoryId: asString(object.categoryId, `${label}.categoryId`),
    questionIds,
    questionCount: asNumber(object.questionCount, `${label}.questionCount`),
  };
}

function parseManifest(value: unknown, label: string): GeneratedManifest {
  const object = asObject(value, label);
  return {
    bankId: asString(object.bankId, `${label}.bankId`),
    effectiveDate: asOptionalString(object.effectiveDate, `${label}.effectiveDate`),
  };
}

async function readJsonFile(filePath: string): Promise<unknown> {
  const text = await readFile(filePath, "utf8");
  try {
    return JSON.parse(text) as unknown;
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    fail(`${filePath}: invalid JSON: ${message}`);
  }
}

function sortedIds<T extends { readonly id: string }>(items: Iterable<T>): string[] {
  return [...items].map((item) => item.id).sort();
}

function mapById<T extends { readonly id: string }>(items: readonly T[], label: string): ReadonlyMap<string, T> {
  const byId = new Map<string, T>();
  for (const item of items) {
    if (byId.has(item.id)) {
      fail(`${label}: duplicate id ${item.id}`);
    }
    byId.set(item.id, item);
  }
  return byId;
}

function sortedUnion(left: Iterable<string>, right: Iterable<string>): string[] {
  return [...new Set([...left, ...right])].sort();
}

function answerSnapshot(answer: Answer): AnswerSnapshot {
  return {
    isCorrect: answer.isCorrect,
    text: answer.text,
  };
}

function changedAnswerFields(previous: Answer | undefined, current: Answer | undefined): string[] {
  if (previous === undefined) {
    return ["added"];
  }
  if (current === undefined) {
    return ["removed"];
  }

  const fields: string[] = [];
  if (previous.isCorrect !== current.isCorrect) {
    fields.push("isCorrect");
  }
  for (const language of LANGUAGES) {
    if (previous.text[language] !== current.text[language]) {
      fields.push(`text.${language}`);
    }
  }
  return fields;
}

function answersBySourceIndex(question: Question): ReadonlyMap<number, Answer> {
  const bySourceIndex = new Map<number, Answer>();
  for (const answer of question.answers) {
    if (bySourceIndex.has(answer.sourceIndex)) {
      fail(`${question.id}: duplicate answer sourceIndex ${answer.sourceIndex}`);
    }
    bySourceIndex.set(answer.sourceIndex, answer);
  }
  return bySourceIndex;
}

function cliPathBase(): string {
  return process.env.INIT_CWD ?? process.cwd();
}

function resolveBankDirectory(directory: string): string {
  return path.isAbsolute(directory) ? directory : path.resolve(cliPathBase(), directory);
}

async function readBankDirectory(directory: string): Promise<GeneratedBank> {
  const absoluteDirectory = resolveBankDirectory(directory);
  const questionsJson = await readJsonFile(path.join(absoluteDirectory, "questions.json"));
  const subsectionsJson = await readJsonFile(path.join(absoluteDirectory, "subsections.json"));
  const manifestJson = await readJsonFile(path.join(absoluteDirectory, "manifest.json"));

  const questions = asArray(questionsJson, `${absoluteDirectory}/questions.json`).map((question, index) => (
    parseQuestion(question, `${absoluteDirectory}/questions.json[${index}]`)
  ));
  const subsections = asArray(subsectionsJson, `${absoluteDirectory}/subsections.json`).map((subsection, index) => (
    parseSubsection(subsection, `${absoluteDirectory}/subsections.json[${index}]`)
  ));
  const manifest = parseManifest(manifestJson, `${absoluteDirectory}/manifest.json`);

  return {
    summary: {
      directory: path.relative(DEFAULT_REPO_ROOT, absoluteDirectory).startsWith("..")
        ? absoluteDirectory
        : path.relative(DEFAULT_REPO_ROOT, absoluteDirectory),
      bankId: manifest.bankId,
      effectiveDate: manifest.effectiveDate ?? null,
      questionCount: questions.length,
      subsectionCount: subsections.length,
    },
    questionsById: mapById(questions, `${absoluteDirectory}/questions.json`),
    subsectionsById: mapById(subsections, `${absoluteDirectory}/subsections.json`),
  };
}

export async function buildBankDiffReport(fromDirectory: string, toDirectory: string): Promise<BankDiffReport> {
  const [fromBank, toBank] = await Promise.all([
    readBankDirectory(fromDirectory),
    readBankDirectory(toDirectory),
  ]);

  const fromQuestionIds = new Set(fromBank.questionsById.keys());
  const toQuestionIds = new Set(toBank.questionsById.keys());
  const addedQuestions = [...toQuestionIds].filter((id) => !fromQuestionIds.has(id)).sort();
  const removedQuestions = [...fromQuestionIds].filter((id) => !toQuestionIds.has(id)).sort();
  const changedText: QuestionTextChange[] = [];
  const changedAnswers: AnswerChange[] = [];

  for (const id of sortedUnion(fromQuestionIds, toQuestionIds)) {
    const previous = fromBank.questionsById.get(id);
    const current = toBank.questionsById.get(id);
    if (previous === undefined || current === undefined) {
      continue;
    }

    const textChanges: Partial<Record<Language, LocalizedFieldChange>> = {};
    for (const language of LANGUAGES) {
      if (previous.text[language] !== current.text[language]) {
        textChanges[language] = { from: previous.text[language], to: current.text[language] };
      }
    }
    if (Object.keys(textChanges).length > 0) {
      changedText.push({ id, changes: textChanges });
    }

    const previousAnswers = answersBySourceIndex(previous);
    const currentAnswers = answersBySourceIndex(current);
    for (const sourceIndex of sortedUnion(
      [...previousAnswers.keys()].map(String),
      [...currentAnswers.keys()].map(String),
    ).map((value) => Number.parseInt(value, 10))) {
      const previousAnswer = previousAnswers.get(sourceIndex);
      const currentAnswer = currentAnswers.get(sourceIndex);
      const changedFields = changedAnswerFields(previousAnswer, currentAnswer);
      if (changedFields.length > 0) {
        changedAnswers.push({
          id,
          sourceIndex,
          previous: previousAnswer === undefined ? null : answerSnapshot(previousAnswer),
          current: currentAnswer === undefined ? null : answerSnapshot(currentAnswer),
          changedFields,
        });
      }
    }
  }

  const fromSubsectionIds = new Set(fromBank.subsectionsById.keys());
  const toSubsectionIds = new Set(toBank.subsectionsById.keys());
  const addedSubsections = [...toSubsectionIds].filter((id) => !fromSubsectionIds.has(id)).sort();
  const removedSubsections = [...fromSubsectionIds].filter((id) => !toSubsectionIds.has(id)).sort();
  const countChanged: SubsectionCountChange[] = [];
  for (const id of sortedUnion(fromSubsectionIds, toSubsectionIds)) {
    const previous = fromBank.subsectionsById.get(id);
    const current = toBank.subsectionsById.get(id);
    if (previous === undefined || current === undefined) {
      continue;
    }
    if (previous.questionCount !== current.questionCount) {
      countChanged.push({
        id,
        fromQuestionCount: previous.questionCount,
        toQuestionCount: current.questionCount,
        fromQuestionIds: [...previous.questionIds],
        toQuestionIds: [...current.questionIds],
      });
    }
  }

  return {
    from: fromBank.summary,
    to: toBank.summary,
    summary: {
      addedQuestionCount: addedQuestions.length,
      removedQuestionCount: removedQuestions.length,
      questionTextChangeCount: changedText.length,
      answerChangeCount: changedAnswers.length,
      addedSubsectionCount: addedSubsections.length,
      removedSubsectionCount: removedSubsections.length,
      subsectionCountChangeCount: countChanged.length,
    },
    questions: {
      added: addedQuestions,
      removed: removedQuestions,
      changedText,
      changedAnswers,
    },
    subsections: {
      added: addedSubsections,
      removed: removedSubsections,
      countChanged,
    },
  };
}

function formatQuoted(value: string): string {
  return JSON.stringify(value);
}

function appendIdList(lines: string[], title: string, ids: readonly string[]): void {
  lines.push(`## ${title}`);
  if (ids.length === 0) {
    lines.push("- none", "");
    return;
  }
  for (const id of ids) {
    lines.push(`- ${id}`);
  }
  lines.push("");
}

export function renderBankDiffReport(report: BankDiffReport): string {
  const lines: string[] = [];
  lines.push(`# Bank diff: ${report.from.bankId} -> ${report.to.bankId}`);
  lines.push("");
  lines.push("## Inputs");
  lines.push(`- From: ${report.from.directory} (${report.from.questionCount} questions, ${report.from.subsectionCount} subsections)`);
  lines.push(`- To: ${report.to.directory} (${report.to.questionCount} questions, ${report.to.subsectionCount} subsections)`);
  lines.push("");
  lines.push("## Summary");
  lines.push(`- Question IDs added: ${report.summary.addedQuestionCount}`);
  lines.push(`- Question IDs removed: ${report.summary.removedQuestionCount}`);
  lines.push(`- Question text changes: ${report.summary.questionTextChangeCount}`);
  lines.push(`- Answer changes: ${report.summary.answerChangeCount}`);
  lines.push(`- Subsections added: ${report.summary.addedSubsectionCount}`);
  lines.push(`- Subsections removed: ${report.summary.removedSubsectionCount}`);
  lines.push(`- Subsection question-count changes: ${report.summary.subsectionCountChangeCount}`);
  lines.push("");

  appendIdList(lines, "Added question IDs", report.questions.added);
  appendIdList(lines, "Removed question IDs", report.questions.removed);

  lines.push("## EN/FR question text changes");
  if (report.questions.changedText.length === 0) {
    lines.push("- none", "");
  } else {
    for (const change of report.questions.changedText) {
      lines.push(`### ${change.id}`);
      for (const language of LANGUAGES) {
        const localizedChange = change.changes[language];
        if (localizedChange !== undefined) {
          lines.push(`- ${language.toUpperCase()} from: ${formatQuoted(localizedChange.from)}`);
          lines.push(`- ${language.toUpperCase()} to: ${formatQuoted(localizedChange.to)}`);
        }
      }
      lines.push("");
    }
  }

  lines.push("## Answer changes");
  if (report.questions.changedAnswers.length === 0) {
    lines.push("- none", "");
  } else {
    for (const change of report.questions.changedAnswers) {
      lines.push(`### ${change.id} answer sourceIndex ${change.sourceIndex}`);
      lines.push(`- Changed fields: ${change.changedFields.join(", ")}`);
      if (change.previous === null) {
        lines.push("- Previous: none");
      } else {
        lines.push(`- Previous correct: ${change.previous.isCorrect}`);
        lines.push(`- Previous EN: ${formatQuoted(change.previous.text.en)}`);
        lines.push(`- Previous FR: ${formatQuoted(change.previous.text.fr)}`);
      }
      if (change.current === null) {
        lines.push("- Current: none");
      } else {
        lines.push(`- Current correct: ${change.current.isCorrect}`);
        lines.push(`- Current EN: ${formatQuoted(change.current.text.en)}`);
        lines.push(`- Current FR: ${formatQuoted(change.current.text.fr)}`);
      }
      lines.push("");
    }
  }

  lines.push("## Subsection counts");
  appendIdList(lines, "Added subsections", report.subsections.added);
  appendIdList(lines, "Removed subsections", report.subsections.removed);
  lines.push("## Subsection question-count changes");
  if (report.subsections.countChanged.length === 0) {
    lines.push("- none", "");
  } else {
    for (const change of report.subsections.countChanged) {
      lines.push(`- ${change.id}: ${change.fromQuestionCount} -> ${change.toQuestionCount}`);
      lines.push(`  - from question IDs: ${change.fromQuestionIds.join(", ")}`);
      lines.push(`  - to question IDs: ${change.toQuestionIds.join(", ")}`);
    }
    lines.push("");
  }

  return `${lines.join("\n").trimEnd()}\n`;
}

function usage(): string {
  return "usage: node packages/content-tools/src/diff-banks.ts [--json] <old-generated-bank-dir> <new-generated-bank-dir>";
}

type CliOptions = {
  readonly json: boolean;
  readonly directories: readonly [string, string];
};

function parseCliArgs(rawArgs: readonly string[]): CliOptions {
  const args = rawArgs[0] === "--" ? rawArgs.slice(1) : rawArgs;
  let json = false;
  const directories: string[] = [];
  for (const arg of args) {
    if (arg === "--json") {
      json = true;
    } else {
      directories.push(arg);
    }
  }

  if (directories.length !== 2) {
    throw new Error(usage());
  }

  return { json, directories: [directories[0]!, directories[1]!] };
}

export async function main(rawArgs = process.argv.slice(2), output: NodeJS.WritableStream = process.stdout): Promise<void> {
  const options = parseCliArgs(rawArgs);
  const report = await buildBankDiffReport(options.directories[0], options.directories[1]);
  if (options.json) {
    output.write(`${JSON.stringify(report, null, 2)}\n`);
  } else {
    output.write(renderBankDiffReport(report));
  }
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`diff-banks: ${message}`);
    process.exitCode = 1;
  });
}
