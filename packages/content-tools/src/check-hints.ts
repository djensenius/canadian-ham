import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { ACTIVE_BANK_ID, ACTIVE_GENERATED_DIR } from "./active-bank.ts";
import { isMainModule } from "./cli.ts";
import { loadQuestionHints, referenceSheetSectionKeys, type LoadedQuestionHint, type QuestionHint, type ReferenceSheetSectionKey } from "./hints.ts";
import { slugForHeadingText } from "./check-links.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_HINT_ROOT = path.join(REPO_ROOT, "content/hints");
const DEFAULT_QUESTION_PATH = path.join(REPO_ROOT, ACTIVE_GENERATED_DIR, "questions.json");
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const EXPECTED_BANK_ID = ACTIVE_BANK_ID;
const EXPECTED_LICENSE_CLASS = "original";
const HINT_ID_PREFIX = "HINT-";

// Leakage tuning: answer/option checks compare significant tokens after dropping
// articles and common EN/FR stop words, then flag either the whole significant
// phrase or a contiguous run from long official options. This catches partial
// leaks such as "Radiocommunication Act" or "Innovation, Science and Economic
// Development" while avoiding single glue words. Question-fragment checks scale
// the n-gram window for short questions. Numeric correct answers are checked
// separately so setup hints cannot state a computed answer value that is absent
// from the question text.
const MIN_QUESTION_FRAGMENT_GRAM_SIZE = 3;
const MAX_QUESTION_FRAGMENT_GRAM_SIZE = 6;
const DISTINCTIVE_OFFICIAL_PHRASE_GRAM_SIZE = 2;
const LONG_OFFICIAL_PHRASE_GRAM_SIZE = 3;
const STOP_WORD_TOKENS = new Set([
  "a", "about", "above", "after", "all", "an", "and", "any", "are", "as", "at", "be", "because", "before", "below", "between", "by", "can", "did", "do", "does", "down", "each", "either", "every", "for", "from", "had", "has", "have", "he", "her", "here", "his", "how", "if", "in", "into", "is", "it", "its", "many", "may", "me", "more", "most", "must", "my", "no", "not", "of", "off", "on", "one", "or", "our", "out", "over", "she", "should", "some", "than", "that", "the", "their", "them", "then", "there", "these", "they", "this", "those", "through", "to", "under", "up", "we", "what", "when", "where", "which", "while", "why", "will", "with", "within", "without", "would", "you", "your",
  "afin", "ainsi", "alors", "apres", "au", "aucun", "aucune", "aux", "avant", "avec", "c", "ca", "ce", "ceci", "cela", "celle", "celles", "celui", "ces", "cet", "cette", "ceux", "chez", "ci", "comme", "d", "dans", "de", "des", "donc", "du", "elle", "elles", "en", "entre", "est", "et", "etre", "il", "ils", "j", "je", "l", "la", "le", "les", "leur", "leurs", "lors", "lui", "m", "ma", "mais", "me", "mes", "moins", "mon", "n", "ne", "ni", "nos", "notre", "nous", "ont", "ou", "par", "pas", "pendant", "plus", "pour", "qu", "quand", "que", "quel", "quelle", "quelles", "quels", "qui", "s", "sa", "se", "ses", "si", "son", "sont", "sous", "sur", "t", "ta", "te", "tes", "tu", "un", "une", "vers", "vos", "votre", "vous",
]);
const NUMERIC_UNIT_TOKENS = new Set([
  "v", "volt", "volts", "mv", "millivolt", "millivolts", "kv", "kilovolt", "kilovolts",
  "a", "amp", "amps", "ampere", "amperes", "ma", "milliamp", "milliamps", "milliampere", "milliamperes",
  "ohm", "ohms", "kohm", "kohms", "kilohm", "kilohms", "megohm", "megohms",
  "w", "watt", "watts", "mw", "milliwatt", "milliwatts", "kw", "kilowatt", "kilowatts",
  "hz", "khz", "mhz", "ghz", "db", "dbi", "dbd", "dbm", "dbw",
  "m", "mm", "cm", "km", "metre", "metres", "meter", "meters",
  "pf", "picofarad", "picofarads", "uf", "µf", "μf", "microfarad", "microfarads", "nf", "nanofarad", "nanofarads", "f", "farad", "farads",
  "h", "mh", "uh", "µh", "μh", "henry", "henries", "millihenry", "millihenries", "microhenry", "microhenries",
  "wpm", "mots", "min", "minute", "minutes", "day", "days", "jour", "jours", "hour", "hours", "heure", "heures", "year", "years", "an", "ans", "degree", "degrees", "degre", "degres", "time", "times", "fois",
]);
const LOW_INFORMATION_TOKENS = new Set([...STOP_WORD_TOKENS, ...NUMERIC_UNIT_TOKENS]);
const REFERENCE_SHEET_WORDS = ["reference sheet", "reference material", "formula sheet", "feuille de référence", "document de référence"];
const OFFICIAL_ANSWER_ALIASES = [
  {
    officialPhrases: ["Innovation Science Economic Development Canada", "Innovation Sciences Développement économique Canada"],
    aliases: ["ISED", "ISDE"],
  },
  {
    officialPhrases: ["Radiocommunication Act", "Loi sur la radiocommunication"],
    aliases: ["Radiocommunications Act", "Loi sur les radiocommunications"],
  },
  {
    officialPhrases: ["Standards Operation Radio Stations Amateur Radio Service", "Normes relatives exploitation stations radio service radioamateur"],
    aliases: ["RBR-4"],
  },
  {
    officialPhrases: ["National Defence", "Défense nationale"],
    aliases: ["DND"],
  },
] as const;

export type LocalizedText = {
  readonly en: string;
  readonly fr: string;
};

type AnswerRecord = {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: LocalizedText;
};

type QuestionRecord = {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly text: LocalizedText;
  readonly answers: readonly AnswerRecord[];
};

type LessonRecord = {
  readonly id: string;
  readonly filePath: string;
  readonly title: string | undefined;
  readonly covers: ReadonlySet<string>;
  readonly anchors: ReadonlySet<string>;
};

export type HintCheckOptions = {
  readonly hintRoot?: string;
  readonly questionsPath?: string;
  readonly lessonRoot?: string;
  readonly categoryId?: string;
  readonly subsectionId?: string;
  readonly requireComplete?: boolean;
};

export type HintCheckReport = {
  readonly hintFileCount: number;
  readonly hintQuestionCount: number;
  readonly checkedQuestionCount: number;
  readonly issues: readonly string[];
  readonly summaryLines: readonly string[];
};

export class HintCheckError extends Error {
  readonly report: HintCheckReport;

  constructor(report: HintCheckReport) {
    super("hint check failed");
    this.report = report;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

function hasLocalizedText(value: unknown): value is LocalizedText {
  return isRecord(value) && isNonEmptyString(value.en) && isNonEmptyString(value.fr);
}

async function loadQuestions(questionsPath: string): Promise<Map<string, QuestionRecord>> {
  const raw: unknown = JSON.parse(await readFile(questionsPath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error(`${questionsPath}: expected an array of question records`);
  }
  const questions = new Map<string, QuestionRecord>();
  for (const [index, item] of raw.entries()) {
    if (!isRecord(item) || !isNonEmptyString(item.id) || !isNonEmptyString(item.bankId) || !isNonEmptyString(item.categoryId) || !isNonEmptyString(item.subsectionId) || !hasLocalizedText(item.text) || !Array.isArray(item.answers)) {
      throw new Error(`${questionsPath}: question record ${index} has an invalid shape`);
    }
    const answers: AnswerRecord[] = [];
    for (const [answerIndex, answer] of item.answers.entries()) {
      if (!isRecord(answer) || typeof answer.sourceIndex !== "number" || !Number.isInteger(answer.sourceIndex) || typeof answer.isCorrect !== "boolean" || !hasLocalizedText(answer.text)) {
        throw new Error(`${questionsPath}: ${item.id} answer ${answerIndex} has an invalid shape`);
      }
      answers.push({ sourceIndex: answer.sourceIndex, isCorrect: answer.isCorrect, text: answer.text });
    }
    questions.set(item.id, { id: item.id, bankId: item.bankId, categoryId: item.categoryId, subsectionId: item.subsectionId, text: item.text, answers });
  }
  return questions;
}

async function findMarkdownFiles(root: string, current = root): Promise<string[]> {
  let entries;
  try {
    entries = await readdir(current, { withFileTypes: true });
  } catch (error: unknown) {
    if (current === root && error instanceof Error && "code" in error && error.code === "ENOENT") {
      return [];
    }
    throw error;
  }

  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(current, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findMarkdownFiles(root, entryPath));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(entryPath);
    }
  }
  return files.sort((a, b) => a.localeCompare(b));
}

type LessonMetadata = {
  readonly id: string;
  readonly title: string | undefined;
  readonly covers: ReadonlySet<string>;
};

function frontMatterBlock(markdown: string): string | null {
  if (!markdown.startsWith("---\n")) {
    return null;
  }
  const closeIndex = markdown.indexOf("\n---", 4);
  return closeIndex === -1 ? null : markdown.slice(4, closeIndex);
}

function parseLessonMetadata(markdown: string): LessonMetadata | null {
  const frontMatter = frontMatterBlock(markdown);
  if (frontMatter === null || !/^type:\s*lesson\s*$/m.test(frontMatter)) {
    return null;
  }
  const id = /^id:\s*([A-Za-z0-9-]+)\s*$/m.exec(frontMatter)?.[1] ?? null;
  if (id === null) {
    return null;
  }
  const title = /^\s+en:\s*"?([^"\n]+)"?\s*$/m.exec(frontMatter)?.[1];
  const covers = new Set<string>();
  const coversMatch = /^covers:\s*$(?<items>(?:\n\s+-\s+[^\n]+)+)/m.exec(frontMatter);
  const coverItems = coversMatch?.groups?.items ?? "";
  for (const match of coverItems.matchAll(/^\s+-\s+([A-Z]-\d{3}-\d{3})\s*$/gm)) {
    covers.add(match[1]!);
  }
  return { id, title, covers };
}

export const slugForLessonHeading = slugForHeadingText;

function markdownLines(text: string): Array<{ line: string; lineNumber: number }> {
  const lines: Array<{ line: string; lineNumber: number }> = [];
  let lineNumber = 1;
  for (const line of text.split(/\r?\n/)) {
    lines.push({ line, lineNumber });
    lineNumber += 1;
  }
  return lines;
}

function stripInlineMarkdown(value: string): string {
  return value
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/__([^_]+)__/g, "$1")
    .replace(/\*([^\s*](?:[^*]*[^\s*])?)\*/g, "$1")
    .replace(/(^|[^\w])_([^\s_](?:[^\s_]*[^\s_])?)_(?=$|[^\w])/g, "$1$2")
    .replace(/\\([\\`*_[\]{}()#+\-.!|])/g, "$1");
}

function addAnchor(anchors: Set<string>, seen: Map<string, number>, headingText: string): void {
  const baseSlug = slugForLessonHeading(headingText);
  if (baseSlug.length === 0) {
    return;
  }
  const previousCount = seen.get(baseSlug) ?? 0;
  seen.set(baseSlug, previousCount + 1);
  anchors.add(previousCount === 0 ? baseSlug : `${baseSlug}-${previousCount}`);
}

function fencedCodeEndIndex(lines: readonly { readonly line: string; readonly lineNumber: number }[], startIndex: number): number | null {
  if (!/^ {0,3}```(?:[ \t]*([^`\s]+))?[ \t]*$/.test(lines[startIndex]?.line ?? "")) {
    return null;
  }
  for (let index = startIndex + 1; index < lines.length; index += 1) {
    if (/^ {0,3}```[ \t]*$/.test(lines[index]?.line ?? "")) {
      return index;
    }
  }
  return null;
}

export function lessonReaderHeadingAnchors(markdown: string, title?: string): Set<string> {
  const anchors = new Set<string>();
  const seen = new Map<string, number>();
  const lines = markdownLines(markdown);

  for (let index = 0; index < lines.length; index += 1) {
    const fenceEndIndex = fencedCodeEndIndex(lines, index);
    if (fenceEndIndex !== null) {
      index = fenceEndIndex;
      continue;
    }

    const heading = /^(#{1,6})\s+(.+?)\s*#*\s*$/.exec(lines[index]?.line ?? "");
    if (heading === null) {
      continue;
    }
    const depth = heading[1]!.length;
    const text = stripInlineMarkdown(heading[2]?.trim() ?? "").trim();
    if (text.length === 0 || /^illustration brief$/iu.test(text)) {
      continue;
    }
    if (depth === 1 && title !== undefined && text === title) {
      continue;
    }
    addAnchor(anchors, seen, text);
  }
  return anchors;
}

async function loadLessons(lessonRoot: string, issues: string[]): Promise<Map<string, LessonRecord>> {
  const lessons = new Map<string, LessonRecord>();
  for (const filePath of await findMarkdownFiles(lessonRoot)) {
    const markdown = await readFile(filePath, "utf8");
    const metadata = parseLessonMetadata(markdown);
    if (metadata === null) {
      continue;
    }
    const previous = lessons.get(metadata.id);
    if (previous !== undefined) {
      issues.push(`${filePath}: duplicate lesson id ${metadata.id}; first seen in ${previous.filePath}`);
      continue;
    }
    lessons.set(metadata.id, {
      id: metadata.id,
      filePath,
      title: metadata.title,
      covers: metadata.covers,
      anchors: lessonReaderHeadingAnchors(markdown, metadata.title),
    });
  }
  return lessons;
}

function normalizeText(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/\p{Diacritic}/gu, "")
    .replace(/[’‘`]/g, "'")
    .replace(/[×]/g, "x")
    .replace(/[ΩΩ]/g, " ohm ")
    .toLowerCase();
}

function tokens(value: string): string[] {
  return normalizeText(value).match(/[\p{L}\p{N}]+/gu) ?? [];
}

function officialSignificantTokens(value: string): string[] {
  return tokens(value).filter((token) => !isOfficialLowInformationToken(token));
}

function questionSignificantTokens(value: string): string[] {
  return tokens(value).filter((token) => !isQuestionLowInformationToken(token));
}

function isOfficialLowInformationToken(token: string): boolean {
  return /^\d+(?:\.\d+)?$/u.test(token) || token.length <= 1 || STOP_WORD_TOKENS.has(token) || NUMERIC_UNIT_TOKENS.has(token);
}

function isQuestionLowInformationToken(token: string): boolean {
  return /^\d+(?:\.\d+)?$/u.test(token) || token.length <= 1 || LOW_INFORMATION_TOKENS.has(token);
}

function containsTokenPhrase(haystackTokens: readonly string[], needleTokens: readonly string[]): boolean {
  if (needleTokens.length === 0 || haystackTokens.length < needleTokens.length) {
    return false;
  }
  for (let start = 0; start <= haystackTokens.length - needleTokens.length; start += 1) {
    let matches = true;
    for (let offset = 0; offset < needleTokens.length; offset += 1) {
      if (haystackTokens[start + offset] !== needleTokens[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

function shouldCheckOfficialPhrase(officialText: string): boolean {
  return officialSignificantTokens(officialText).length > 0;
}

type OfficialPhraseLeakageContext = {
  readonly questionText: string;
  readonly answerTexts: readonly string[];
};

function phraseKey(value: readonly string[]): string {
  return value.join(" ");
}

function officialCandidatePhrases(officialTokens: readonly string[], includeDistinctiveTwoWordRuns: boolean): string[][] {
  if (officialTokens.length === 0) {
    return [];
  }
  if (officialTokens.length === 1) {
    return [[officialTokens[0]!]];
  }
  const candidates = new Map<string, string[]>();
  const addCandidate = (candidate: readonly string[]): void => {
    if (candidate.length > 0) {
      candidates.set(phraseKey(candidate), [...candidate]);
    }
  };

  addCandidate(officialTokens);
  if (officialTokens.length >= LONG_OFFICIAL_PHRASE_GRAM_SIZE) {
    const gramSizes = includeDistinctiveTwoWordRuns ? [DISTINCTIVE_OFFICIAL_PHRASE_GRAM_SIZE, LONG_OFFICIAL_PHRASE_GRAM_SIZE] : [LONG_OFFICIAL_PHRASE_GRAM_SIZE];
    for (const gramSize of gramSizes) {
      for (const gram of ngrams(officialTokens, gramSize)) {
        addCandidate(gram.split(" "));
      }
    }
  }
  return [...candidates.values()];
}

function answerPhraseCounts(answerTexts: readonly string[], includeDistinctiveTwoWordRuns: boolean): Map<string, number> {
  const counts = new Map<string, number>();
  const tokenizedAnswers = answerTexts.map((answerText) => officialSignificantTokens(answerText));
  const candidateKeys = new Set<string>();
  for (const answerTokens of tokenizedAnswers) {
    for (const answerPhrase of officialCandidatePhrases(answerTokens, includeDistinctiveTwoWordRuns)) {
      candidateKeys.add(phraseKey(answerPhrase));
    }
  }
  for (const candidateKey of candidateKeys) {
    const candidate = candidateKey.split(" ");
    counts.set(candidateKey, tokenizedAnswers.filter((answerTokens) => containsTokenPhrase(answerTokens, candidate)).length);
  }
  return counts;
}

function distinctiveOfficialCandidatePhrases(officialText: string, context: OfficialPhraseLeakageContext, includeDistinctiveTwoWordRuns: boolean): string[][] {
  const questionTokens = questionSignificantTokens(context.questionText);
  const officialTokens = officialSignificantTokens(officialText);
  const officialFullPhraseKey = phraseKey(officialTokens);
  const phraseCounts = answerPhraseCounts(context.answerTexts, includeDistinctiveTwoWordRuns);
  return officialCandidatePhrases(officialTokens, includeDistinctiveTwoWordRuns).filter((candidate) => {
    if (containsTokenPhrase(questionTokens, candidate)) {
      return false;
    }
    if (includeDistinctiveTwoWordRuns && phraseKey(candidate) === officialFullPhraseKey) {
      return true;
    }
    return (phraseCounts.get(phraseKey(candidate)) ?? 0) < 2;
  });
}

function checkOfficialPhraseLeakage(hintText: string, officialText: string, context: OfficialPhraseLeakageContext, includeDistinctiveTwoWordRuns: boolean): boolean {
  if (!shouldCheckOfficialPhrase(officialText)) {
    return false;
  }
  const hintTokens = officialSignificantTokens(hintText);
  return distinctiveOfficialCandidatePhrases(officialText, context, includeDistinctiveTwoWordRuns).some((candidate) => containsTokenPhrase(hintTokens, candidate));
}

function aliasSignificantTokens(value: string): string[] {
  return tokens(value).filter((token) => token.length > 1 && !STOP_WORD_TOKENS.has(token));
}

function findOfficialAliasLeakage(hintText: string, questionText: string, officialText: string): string | null {
  const officialTokens = officialSignificantTokens(officialText);
  const hintTokens = aliasSignificantTokens(hintText);
  const questionTokens = aliasSignificantTokens(questionText);
  for (const aliasGroup of OFFICIAL_ANSWER_ALIASES) {
    const applies = aliasGroup.officialPhrases.some((officialPhrase) => containsTokenPhrase(officialTokens, officialSignificantTokens(officialPhrase)));
    if (!applies) {
      continue;
    }
    for (const alias of aliasGroup.aliases) {
      const aliasTokens = aliasSignificantTokens(alias);
      if (!containsTokenPhrase(questionTokens, aliasTokens) && containsTokenPhrase(hintTokens, aliasTokens)) {
        return alias;
      }
    }
  }
  return null;
}

function ngrams(values: readonly string[], size: number): string[] {
  if (values.length < size) {
    return [];
  }
  const result: string[] = [];
  for (let index = 0; index <= values.length - size; index += 1) {
    result.push(values.slice(index, index + size).join(" "));
  }
  return result;
}

function questionFragmentGramSize(significantTokenCount: number): number | null {
  if (significantTokenCount < MIN_QUESTION_FRAGMENT_GRAM_SIZE) {
    return null;
  }
  return Math.min(MAX_QUESTION_FRAGMENT_GRAM_SIZE, Math.max(MIN_QUESTION_FRAGMENT_GRAM_SIZE, significantTokenCount - 1));
}

function findQuestionFragmentLeakage(hintText: string, questionText: string): string | null {
  const questionTokens = questionSignificantTokens(questionText);
  const gramSize = questionFragmentGramSize(questionTokens.length);
  if (gramSize === null) {
    return null;
  }
  const hintGrams = new Set(ngrams(questionSignificantTokens(hintText), gramSize));
  if (hintGrams.size === 0) {
    return null;
  }
  for (const gram of ngrams(questionTokens, gramSize)) {
    if (hintGrams.has(gram)) {
      return gram;
    }
  }
  return null;
}

type NumericValue = {
  readonly number: string;
  readonly text: string;
  readonly hasAttachedContext: boolean;
};

const NUMERIC_UNIT_PATTERN = [
  "millivolts?", "kilovolts?", "volts?", "mv", "kv", "v",
  "milliamperes?", "milliamps?", "amperes?", "amps?", "ma",
  "megohms?", "kilohms?", "kohms?", "ohms?",
  "milliwatts?", "kilowatts?", "watts?", "mw", "kw", "w",
  "ghz", "mhz", "khz", "hz", "dbi", "dbd", "dbm", "dbw", "db",
  "kilometres?", "kilometers?", "metres?", "meters?", "km", "cm", "mm",
  "microfarads?", "picofarads?", "nanofarads?", "farads?", "µf", "μf", "uf", "pf", "nf", "f",
  "microhenries", "microhenrys", "millihenries", "millihenrys", "henries", "henrys", "µh", "μh", "uh", "mh",
  "mots/min", "wpm", "minutes?", "days?", "jours?", "hours?", "heures?", "years?", "ans?", "degrés", "degres", "degrees?", "fois", "times?",
  "a", "h", "m",
].join("|");

function numericValuePattern(language: "en" | "fr"): RegExp {
  const groupedSeparator = language === "en" ? "[ ,\\u00a0]" : "[ \\u00a0]";
  return new RegExp(`(?<![\\p{L}\\p{N}.,])(?<currencyBefore>[$])?\\s*(?<number>(?:\\d{1,3}(?:${groupedSeparator}\\d{3})+|\\d+(?!${groupedSeparator}\\d))(?:\\.\\d+)?)(?:[\\s-]*(?<unit>${NUMERIC_UNIT_PATTERN}))?(?:\\s*(?<percent>%))?(?:\\s*(?<currencyAfter>[$]))?(?![\\p{L}\\p{N}]|\\.\\d)`, "giu");
}

function canonicalNumber(value: string): string {
  const compact = value.replace(/[ ,\u00a0]/g, "");
  const [integer = "0", fraction] = compact.split(".");
  const normalizedInteger = integer.replace(/^0+(?=\d)/u, "") || "0";
  if (fraction === undefined) {
    return normalizedInteger;
  }
  const normalizedFraction = fraction.replace(/0+$/u, "");
  return normalizedFraction.length === 0 ? normalizedInteger : `${normalizedInteger}.${normalizedFraction}`;
}

function normalizeNumericText(value: string, language: "en" | "fr"): string {
  const normalized = normalizeText(value);
  return language === "fr" ? normalized.replace(/(\d),(\d)/gu, "$1.$2") : normalized;
}

function numericValues(value: string, language: "en" | "fr"): NumericValue[] {
  const normalized = normalizeNumericText(value, language);
  const values: NumericValue[] = [];
  const seen = new Set<string>();
  for (const match of normalized.matchAll(numericValuePattern(language))) {
    const number = canonicalNumber(match.groups?.number ?? match[0]);
    if (seen.has(number)) {
      continue;
    }
    seen.add(number);
    values.push({
      number,
      text: match[0].trim(),
      hasAttachedContext: (match.groups?.unit ?? match.groups?.currencyBefore ?? match.groups?.currencyAfter ?? match.groups?.percent) !== undefined,
    });
  }
  return values;
}

function tokenOptionCounts(answerTexts: readonly string[]): Map<string, number> {
  const counts = new Map<string, number>();
  for (const answerText of answerTexts) {
    for (const token of new Set(officialSignificantTokens(answerText))) {
      counts.set(token, (counts.get(token) ?? 0) + 1);
    }
  }
  return counts;
}

function answerHasCheckableNumericValue(answerText: string, questionText: string, answerTexts: readonly string[], language: "en" | "fr"): boolean {
  if (numericValues(answerText, language).length === 0) {
    return false;
  }
  const questionTokens = new Set(questionSignificantTokens(questionText));
  const optionTokenCounts = tokenOptionCounts(answerTexts);
  return officialSignificantTokens(answerText).every((token) => questionTokens.has(token) || (optionTokenCounts.get(token) ?? 0) >= 2);
}

function numericValueOptionCounts(answerTexts: readonly string[], language: "en" | "fr"): Map<string, number> {
  const counts = new Map<string, number>();
  for (const answerText of answerTexts) {
    const optionValues = new Set(numericValues(answerText, language).map((value) => value.number));
    for (const optionValue of optionValues) {
      counts.set(optionValue, (counts.get(optionValue) ?? 0) + 1);
    }
  }
  return counts;
}

function findCorrectNumericAnswerLeakage(hintText: string, questionText: string, answerText: string, answerTexts: readonly string[], language: "en" | "fr"): NumericValue | null {
  const answerValues = numericValues(answerText, language);
  if (answerValues.length === 0) {
    return null;
  }
  const answerIsNumericallyCheckable = answerHasCheckableNumericValue(answerText, questionText, answerTexts, language);
  const optionCounts = numericValueOptionCounts(answerTexts, language);
  const questionNumbers = new Set(numericValues(questionText, language).map((value) => value.number));
  const hintNumbers = new Set(numericValues(hintText, language).map((value) => value.number));
  for (const answerValue of answerValues) {
    if (!answerIsNumericallyCheckable && !answerValue.hasAttachedContext) {
      continue;
    }
    if ((optionCounts.get(answerValue.number) ?? 0) >= 2) {
      continue;
    }
    if (!questionNumbers.has(answerValue.number) && hintNumbers.has(answerValue.number)) {
      return answerValue;
    }
  }
  return null;
}

function validateHintShape(hint: LoadedQuestionHint, relativePath: string, issues: string[]): boolean {
  const issueCount = issues.length;
  if (!isNonEmptyString(hint.id)) {
    issues.push(`${relativePath}: id must be a non-empty string`);
  }
  if (!isNonEmptyString(hint.questionId)) {
    issues.push(`${relativePath}: questionId must be a non-empty string`);
  }
  if (hint.id !== `${HINT_ID_PREFIX}${hint.questionId}`) {
    issues.push(`${relativePath}: id must be ${HINT_ID_PREFIX}${hint.questionId}`);
  }
  if (hint.bankId !== EXPECTED_BANK_ID) {
    issues.push(`${relativePath}: bankId must be ${EXPECTED_BANK_ID}`);
  }
  if (!isNonEmptyString(hint.status)) {
    issues.push(`${relativePath}: status must be a non-empty string`);
  }
  if (hint.licenseClass !== EXPECTED_LICENSE_CLASS) {
    issues.push(`${relativePath}: licenseClass must be ${EXPECTED_LICENSE_CLASS}`);
  }
  if (!Array.isArray(hint.hints) || hint.hints.length < 1 || hint.hints.length > 2) {
    issues.push(`${relativePath}: hints must contain one or two entries`);
    return false;
  }
  if (hint.hints.length === 1 && !isNonEmptyString(hint.singleLevelReason)) {
    issues.push(`${relativePath}: singleLevelReason must be non-empty when only one hint level is present`);
  }
  if (hint.hints.length === 2 && hint.singleLevelReason !== undefined) {
    issues.push(`${relativePath}: singleLevelReason is only allowed for one-level hints`);
  }
  for (const [index, step] of hint.hints.entries()) {
    const expectedLevel = index + 1;
    const label = `${relativePath}: hints[${index}]`;
    if (!isRecord(step)) {
      issues.push(`${label} must be an object`);
      continue;
    }
    if (step.level !== expectedLevel) {
      issues.push(`${label}.level must be ${expectedLevel}`);
    }
    if (!isNonEmptyString(step.en)) {
      issues.push(`${label}.en must be non-empty`);
    }
    if (!isNonEmptyString(step.fr)) {
      issues.push(`${label}.fr must be non-empty`);
    }
  }
  if (!isRecord(hint.lessonLink)) {
    issues.push(`${relativePath}: lessonLink must be an object`);
  } else {
    if (!isNonEmptyString(hint.lessonLink.lessonId)) {
      issues.push(`${relativePath}: lessonLink.lessonId must be non-empty`);
    }
    if (hint.lessonLink.sectionAnchor !== undefined && !isNonEmptyString(hint.lessonLink.sectionAnchor)) {
      issues.push(`${relativePath}: lessonLink.sectionAnchor must be non-empty when present`);
    }
  }
  if (hint.referenceSheetSection !== undefined && hint.referenceSheetSection !== null && !(referenceSheetSectionKeys as readonly string[]).includes(hint.referenceSheetSection)) {
    issues.push(`${relativePath}: referenceSheetSection must be one of ${referenceSheetSectionKeys.join(", ")} or null`);
  }
  return issues.length === issueCount;
}

function validateHintLocation(hint: LoadedQuestionHint, relativePath: string, question: QuestionRecord | undefined, issues: string[]): void {
  if (question === undefined) {
    return;
  }
  const expectedCategory = question.categoryId.toLowerCase();
  const expectedFile = path.join(expectedCategory, `${hint.questionId.toLowerCase()}.json`).split(path.sep).join("/");
  const normalizedPath = relativePath.split(path.sep).join("/");
  if (!normalizedPath.endsWith(expectedFile)) {
    issues.push(`${relativePath}: expected location to end with ${expectedFile}`);
  }
}

function validateHintLessonLink(hint: LoadedQuestionHint, relativePath: string, question: QuestionRecord, lessonsById: ReadonlyMap<string, LessonRecord>, issues: string[]): void {
  if (!isRecord(hint.lessonLink) || !isNonEmptyString(hint.lessonLink.lessonId)) {
    return;
  }
  const lesson = lessonsById.get(hint.lessonLink.lessonId);
  if (lesson === undefined) {
    issues.push(`${relativePath}: lessonLink.lessonId ${hint.lessonLink.lessonId} is not an existing lesson`);
    return;
  }
  if (!lesson.covers.has(question.subsectionId)) {
    issues.push(`${relativePath}: lessonLink.lessonId ${hint.lessonLink.lessonId} does not cover ${question.subsectionId}`);
  }
  if (hint.lessonLink.sectionAnchor !== undefined && isNonEmptyString(hint.lessonLink.sectionAnchor) && !lesson.anchors.has(hint.lessonLink.sectionAnchor)) {
    issues.push(`${relativePath}: lessonLink.sectionAnchor ${hint.lessonLink.sectionAnchor} does not exist in ${path.relative(REPO_ROOT, lesson.filePath).split(path.sep).join("/")}`);
  }
}

function validHintStepsForLeakage(hint: LoadedQuestionHint): QuestionHint["hints"][number][] {
  if (!Array.isArray(hint.hints)) {
    return [];
  }
  return hint.hints.filter((step): step is QuestionHint["hints"][number] => isRecord(step) && (step.level === 1 || step.level === 2) && isNonEmptyString(step.en) && isNonEmptyString(step.fr));
}

function validateHintLeakage(hint: LoadedQuestionHint, relativePath: string, question: QuestionRecord, issues: string[]): void {
  for (const step of validHintStepsForLeakage(hint)) {
    for (const language of ["en", "fr"] as const) {
      const hintText = step[language];
      const label = `${relativePath}: level ${step.level} ${language}`;
      const answerTexts = question.answers.map((answer) => answer.text[language]);
      const leakageContext = { questionText: question.text[language], answerTexts };
      if (REFERENCE_SHEET_WORDS.some((word) => normalizeText(hintText).includes(normalizeText(word)))) {
        issues.push(`${label}: reference-sheet pointer text belongs in UI metadata, not hint prose`);
      }
      const questionFragment = findQuestionFragmentLeakage(hintText, question.text[language]);
      if (questionFragment !== null) {
        issues.push(`${label}: copies a long question fragment (${JSON.stringify(questionFragment)})`);
      }
      for (const answer of question.answers) {
        const answerText = answer.text[language];
        const kind = answer.isCorrect ? "correct answer" : `answer option sourceIndex ${answer.sourceIndex}`;
        if (answer.isCorrect) {
          const numericLeak = findCorrectNumericAnswerLeakage(hintText, question.text[language], answerText, answerTexts, language);
          if (numericLeak !== null) {
            issues.push(`${label}: contains correct answer numeric value ${JSON.stringify(numericLeak.text)} from ${JSON.stringify(answerText)}`);
          }
        }
        if (checkOfficialPhraseLeakage(hintText, answerText, leakageContext, answer.isCorrect)) {
          issues.push(`${label}: contains ${kind} text ${JSON.stringify(answerText)}`);
        }
        const aliasLeak = findOfficialAliasLeakage(hintText, question.text[language], answerText);
        if (aliasLeak !== null) {
          issues.push(`${label}: contains ${kind} alias ${JSON.stringify(aliasLeak)} for ${JSON.stringify(answerText)}`);
        }
      }
    }
  }
}

function filteredQuestions(questions: Iterable<QuestionRecord>, options: HintCheckOptions): QuestionRecord[] {
  return [...questions]
    .filter((question) => options.categoryId === undefined || question.categoryId === options.categoryId)
    .filter((question) => options.subsectionId === undefined || question.subsectionId === options.subsectionId)
    .sort((a, b) => a.id.localeCompare(b.id));
}

function filteredHints(hints: readonly LoadedQuestionHint[], questionsById: ReadonlyMap<string, QuestionRecord>, options: HintCheckOptions): LoadedQuestionHint[] {
  return hints.filter((hint) => {
    const question = questionsById.get(hint.questionId);
    if (question === undefined) {
      return true;
    }
    if (options.categoryId !== undefined && question.categoryId !== options.categoryId) {
      return false;
    }
    return !(options.subsectionId !== undefined && question.subsectionId !== options.subsectionId);
  });
}

function filterDescription(options: HintCheckOptions): string {
  const filters: string[] = [];
  if (options.categoryId !== undefined) {
    filters.push(`category ${options.categoryId}`);
  }
  if (options.subsectionId !== undefined) {
    filters.push(`subsection ${options.subsectionId}`);
  }
  return filters.join(" and ");
}

export async function checkHints(options: HintCheckOptions = {}): Promise<HintCheckReport> {
  const hintRoot = options.hintRoot ?? DEFAULT_HINT_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTION_PATH;
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const issues: string[] = [];
  const questionsById = await loadQuestions(questionsPath);
  const lessonsById = await loadLessons(lessonRoot, issues);
  const selectedQuestions = filteredQuestions(questionsById.values(), options);
  if ((options.categoryId !== undefined || options.subsectionId !== undefined) && selectedQuestions.length === 0) {
    issues.push(`filters matched no active Basic questions: ${filterDescription(options)}`);
  }
  const selectedQuestionIds = new Set(selectedQuestions.map((question) => question.id));
  const allHints = await loadQuestionHints({ hintRoot });
  const hints = filteredHints(allHints, questionsById, options);
  const hintsByQuestionId = new Map<string, LoadedQuestionHint>();

  for (const hint of hints) {
    const relativePath = path.relative(hintRoot, hint.filePath).split(path.sep).join("/");
    const shapeIsValid = validateHintShape(hint, relativePath, issues);
    if (!isNonEmptyString(hint.questionId)) {
      continue;
    }
    const previous = hintsByQuestionId.get(hint.questionId);
    if (previous !== undefined) {
      issues.push(`${relativePath}: duplicate hint for ${hint.questionId}; first seen in ${path.relative(hintRoot, previous.filePath).split(path.sep).join("/")}`);
    } else {
      hintsByQuestionId.set(hint.questionId, hint);
    }
    const question = questionsById.get(hint.questionId);
    if (question === undefined) {
      issues.push(`${relativePath}: questionId ${hint.questionId} is not in the active question bank`);
      continue;
    }
    if (!selectedQuestionIds.has(question.id)) {
      continue;
    }
    validateHintLocation(hint, relativePath, question, issues);
    validateHintLessonLink(hint, relativePath, question, lessonsById, issues);
    if (shapeIsValid || validHintStepsForLeakage(hint).length > 0) {
      validateHintLeakage(hint, relativePath, question, issues);
    }
  }

  if (options.requireComplete === true) {
    for (const question of selectedQuestions) {
      if (!hintsByQuestionId.has(question.id)) {
        issues.push(`${question.id}: missing hint file`);
      }
    }
  }

  const report: HintCheckReport = {
    hintFileCount: hints.length,
    hintQuestionCount: hintsByQuestionId.size,
    checkedQuestionCount: selectedQuestions.length,
    issues,
    summaryLines: [
      `check-hints: checked ${hints.length} hint file(s) for ${selectedQuestions.length} active Basic question(s)`,
      options.requireComplete === true ? "check-hints: completeness requirement enabled" : "check-hints: completeness requirement disabled",
    ],
  };
  if (issues.length > 0) {
    throw new HintCheckError(report);
  }
  return report;
}

type MutableHintCheckOptions = {
  hintRoot?: string;
  questionsPath?: string;
  lessonRoot?: string;
  categoryId?: string;
  subsectionId?: string;
  requireComplete?: boolean;
};

function parseArgs(argv: readonly string[]): HintCheckOptions & { readonly selfTest: boolean } {
  const options: MutableHintCheckOptions & { selfTest: boolean } = { selfTest: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index]!;
    if (arg === "--") {
      continue;
    } else if (arg === "--self-test") {
      options.selfTest = true;
    } else if (arg === "--category") {
      options.categoryId = requireValue(argv, ++index, arg);
    } else if (arg === "--subsection") {
      options.subsectionId = requireValue(argv, ++index, arg);
    } else if (arg === "--require-complete") {
      options.requireComplete = true;
    } else if (arg === "--hint-root") {
      options.hintRoot = path.resolve(process.cwd(), requireValue(argv, ++index, arg));
    } else if (arg === "--questions") {
      options.questionsPath = path.resolve(process.cwd(), requireValue(argv, ++index, arg));
    } else if (arg === "--lesson-root") {
      options.lessonRoot = path.resolve(process.cwd(), requireValue(argv, ++index, arg));
    } else {
      throw new Error(`unknown argument ${arg}`);
    }
  }
  return { selfTest: options.selfTest, hintRoot: options.hintRoot, questionsPath: options.questionsPath, lessonRoot: options.lessonRoot, categoryId: options.categoryId, subsectionId: options.subsectionId, requireComplete: options.requireComplete };
}

function requireValue(argv: readonly string[], index: number, flag: string): string {
  const value = argv[index];
  if (value === undefined || value.startsWith("--")) {
    throw new Error(`${flag} requires a value`);
  }
  return value;
}

function question(overrides: Partial<QuestionRecord> = {}): QuestionRecord {
  return {
    id: "B-001-001-001",
    bankId: EXPECTED_BANK_ID,
    categoryId: "B-001",
    subsectionId: "B-001-001",
    text: {
      en: "Which part of a fixture station keeps the signal stable during a long contact?",
      fr: "Quelle partie d'une station fictive garde le signal stable pendant un long contact?",
    },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Stable oscillator", fr: "Oscillateur stable" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Loose antenna", fr: "Antenne desserrée" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Bright display", fr: "Afficheur lumineux" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Long power cord", fr: "Long cordon d'alimentation" } },
    ],
    ...overrides,
  };
}

function hint(overrides: Partial<QuestionHint> = {}): QuestionHint {
  return {
    id: "HINT-B-001-001-001",
    questionId: "B-001-001-001",
    bankId: EXPECTED_BANK_ID,
    status: "draft",
    hints: [
      {
        level: 1,
        en: "Think about the circuit block that sets a steady radio-frequency rhythm.",
        fr: "Pensez au bloc de circuit qui fixe un rythme radiofréquence régulier.",
      },
      {
        level: 2,
        en: "Frequency stays stable when one circuit block sets the radio-frequency rhythm instead of drifting.",
        fr: "La fréquence reste stable quand un bloc de circuit fixe le rythme radiofréquence au lieu de dériver.",
      },
    ],
    lessonLink: { lessonId: "L-001-01", sectionAnchor: "shared-setup" },
    referenceSheetSection: null,
    licenseClass: "original",
    ...overrides,
  };
}

async function withSelfTestFixture(name: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-hints-${name}-`));
  try {
    await mkdir(path.join(root, "content/hints/b-001"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m1-regulations-policies"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function writeSelfTestFixture(root: string, hintRecord: QuestionHint, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questions, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/hints/b-001/b-001-001-001.json"), `${JSON.stringify(hintRecord, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/lessons/m1-regulations-policies/l-001-01.md"), `---\ntype: lesson\nid: L-001-01\ntitle:\n  en: "Fixture Lesson"\ncovers:\n  - B-001-001\n---\n# Fixture Lesson\n\n## Shared setup\n\nA fixture lesson section.\n`, "utf8");
}


async function assertSelfTestAccepts(name: string, hintRecord: QuestionHint, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await withSelfTestFixture(name, async (root) => {
    await writeSelfTestFixture(root, hintRecord, questions);
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });
  });
}

async function assertSelfTestRejects(name: string, hintRecord: QuestionHint, expectedIssue: string, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await withSelfTestFixture(name, async (root) => {
    await writeSelfTestFixture(root, hintRecord, questions);
    try {
      await checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
        requireComplete: true,
      });
    } catch (error: unknown) {
      if (error instanceof HintCheckError && error.report.issues.some((issue) => issue.includes(expectedIssue))) {
        return;
      }
      throw error;
    }
    throw new Error(`${name}: expected hint check to reject ${expectedIssue}`);
  });
}

async function assertSelfTestRejectsWithOptions(name: string, options: HintCheckOptions, expectedIssue: string, questions: readonly QuestionRecord[] = [question()]): Promise<void> {
  await withSelfTestFixture(name, async (root) => {
    await writeSelfTestFixture(root, hint(), questions);
    try {
      await checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
        ...options,
      });
    } catch (error: unknown) {
      if (error instanceof HintCheckError && error.report.issues.some((issue) => issue.includes(expectedIssue))) {
        return;
      }
      throw error;
    }
    throw new Error(`${name}: expected hint check to reject ${expectedIssue}`);
  });
}

export async function runHintCheckerSelfTest(): Promise<void> {
  await withSelfTestFixture("valid", async (root) => {
    await writeSelfTestFixture(root, hint());
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });
  });

  await assertSelfTestRejectsWithOptions("empty-subsection-filter", { subsectionId: "B-999-999", requireComplete: true }, "filters matched no active Basic questions");

  await assertSelfTestRejectsWithOptions("conflicting-category-subsection-filters", { categoryId: "B-002", subsectionId: "B-001-001", requireComplete: true }, "filters matched no active Basic questions");

  await assertSelfTestRejects("correct-answer", hint({ hints: [
    { level: 1, en: "Think about a stable oscillator before answering.", fr: "Pensez à un bloc de fréquence régulier avant de répondre." },
    { level: 2, en: "Choose the block that holds frequency steady.", fr: "Choisissez le bloc qui garde la fréquence stable." },
  ] }), "correct answer text");

  await assertSelfTestRejects("option", hint({ hints: [
    { level: 1, en: "Eliminate a loose antenna before choosing.", fr: "Écartez une antenne desserrée avant de choisir." },
    { level: 2, en: "Focus on frequency control, not station wiring.", fr: "Concentrez-vous sur le contrôle de fréquence, pas sur le câblage." },
  ] }), "answer option sourceIndex 1");

  await assertSelfTestRejects("question-fragment", hint({ hints: [
    { level: 1, en: "Ask what keeps the signal stable during a long contact.", fr: "Demandez-vous ce qui garde le signal stable pendant un long contact." },
    { level: 2, en: "Focus on frequency control.", fr: "Concentrez-vous sur le contrôle de fréquence." },
  ] }), "copies a long question fragment");

  await assertSelfTestRejects("missing-fr", hint({ hints: [
    { level: 1, en: "Think about the frequency-control block.", fr: "" },
    { level: 2, en: "Focus on the part that sets the rhythm.", fr: "Concentrez-vous sur la partie qui fixe le rythme." },
  ] }), "hints[0].fr must be non-empty");

  await assertSelfTestRejects("bad-reference", hint({ referenceSheetSection: "bad-section" as ReferenceSheetSectionKey }), "referenceSheetSection must be one of");

  await assertSelfTestAccepts("single-level-with-reason", hint({
    hints: [
      { level: 1, en: "Think about the broad setup before choosing.", fr: "Pensez au contexte général avant de choisir." },
    ],
    singleLevelReason: "A second hint would name the deciding document for this recall question.",
  }));

  await assertSelfTestRejects("single-level-missing-reason", hint({
    hints: [
      { level: 1, en: "Think about the broad setup before choosing.", fr: "Pensez au contexte général avant de choisir." },
    ],
  }), "singleLevelReason must be non-empty");

  await assertSelfTestRejects("two-level-with-single-level-reason", hint({ singleLevelReason: "Not needed with two levels." }), "singleLevelReason is only allowed");

  await assertSelfTestRejects("missing-lesson-link", { ...hint(), lessonLink: undefined } as unknown as QuestionHint, "lessonLink must be an object");

  await assertSelfTestRejects("unknown-lesson-link", hint({ lessonLink: { lessonId: "L-999-99" } }), "lessonLink.lessonId L-999-99 is not an existing lesson");

  await assertSelfTestRejects("unknown-lesson-anchor", hint({ lessonLink: { lessonId: "L-001-01", sectionAnchor: "missing-section" } }), "lessonLink.sectionAnchor missing-section does not exist");

  await assertSelfTestAccepts("lesson-link-without-anchor", hint({ lessonLink: { lessonId: "L-001-01" } }));

  await assertSelfTestRejects("lesson-link-case-mismatch", hint({ lessonLink: { lessonId: "L-001-01", sectionAnchor: "Shared-Setup" } }), "lessonLink.sectionAnchor Shared-Setup does not exist");

  await withSelfTestFixture("lesson-link-unrendered-heading", async (root) => {
    await writeSelfTestFixture(root, hint({ lessonLink: { lessonId: "L-001-01", sectionAnchor: "illustration-brief" } }));
    await writeFile(path.join(root, "content/lessons/m1-regulations-policies/l-001-01.md"), `---\ntype: lesson\nid: L-001-01\ntitle:\n  en: "Fixture Lesson"\ncovers:\n  - B-001-001\n---\n# Fixture Lesson\n\n## Illustration brief\n\nAlt text: Fixture.\n\nDescription: Draw a fixture.\n\n## Shared setup\n\nA fixture lesson section.\n`, "utf8");
    await assert.rejects(
      () => checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
        requireComplete: true,
      }),
      (error: unknown) => error instanceof HintCheckError
        && error.report.issues.some((issue) => issue.includes("lessonLink.sectionAnchor illustration-brief does not exist")),
    );
  });

  await assertSelfTestRejects("lesson-link-wrong-coverage", hint(), "does not cover B-001-999", [question({ subsectionId: "B-001-999" })]);

  await withSelfTestFixture("lesson-link-duplicate-anchor", async (root) => {
    await writeSelfTestFixture(root, hint({ lessonLink: { lessonId: "L-001-01", sectionAnchor: "shared-setup-1" } }));
    await writeFile(path.join(root, "content/lessons/m1-regulations-policies/l-001-01.md"), `---\ntype: lesson\nid: L-001-01\ntitle:\n  en: "Fixture Lesson"\ncovers:\n  - B-001-001\n---\n# Fixture Lesson\n\n## Shared setup\n\nFirst section.\n\n## Shared setup\n\nSecond section.\n`, "utf8");
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });
  });

  await assertSelfTestRejects("missing-en-key", hint({ hints: [
    { level: 1, fr: "Pensez au bloc de fréquence." } as unknown as QuestionHint["hints"][number],
    { level: 2, en: "Focus on the part that sets the rhythm.", fr: "Concentrez-vous sur la partie qui fixe le rythme." },
  ] }), "hints[0].en must be non-empty");

  await assertSelfTestRejects("null-fr", hint({ hints: [
    { level: 1, en: "Think about the frequency-control block.", fr: null } as unknown as QuestionHint["hints"][number],
    { level: 2, en: "Focus on the part that sets the rhythm.", fr: "Concentrez-vous sur la partie qui fixe le rythme." },
  ] }), "hints[0].fr must be non-empty");

  await assertSelfTestRejects("significant-answer-token-run-en-possessive", hint({ hints: [
    { level: 1, en: "Think about Canada's Radiocommunication Act before answering.", fr: "Pensez à la source juridique." },
    { level: 2, en: "Use the legal hierarchy.", fr: "Utilisez la hiérarchie juridique." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The Broadcasting Act", fr: "La Loi sur la radiodiffusion" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "The Radio Regulations", fr: "Le règlement radio" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "A station standard", fr: "Une norme de station" } },
  ] })]);

  await assertSelfTestRejects("significant-answer-token-run-en-start", hint({ hints: [
    { level: 1, en: "Radiocommunication Act is the phrase to remember.", fr: "Pensez à la source juridique." },
    { level: 2, en: "Use the legal hierarchy.", fr: "Utilisez la hiérarchie juridique." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The Broadcasting Act", fr: "La Loi sur la radiodiffusion" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "The Radio Regulations", fr: "Le règlement radio" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "A station standard", fr: "Une norme de station" } },
  ] })]);

  await assertSelfTestRejects("significant-answer-token-run-fr", hint({ hints: [
    { level: 1, en: "Think about the legal hierarchy.", fr: "Loi sur la radiocommunication est la phrase à retenir." },
    { level: 2, en: "Use the legal hierarchy.", fr: "Utilisez la hiérarchie juridique." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The Broadcasting Act", fr: "La Loi sur la radiodiffusion" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "The Radio Regulations", fr: "Le règlement radio" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "A station standard", fr: "Une norme de station" } },
  ] })]);

  await assertSelfTestRejects("significant-long-answer-token-run", hint({ hints: [
    { level: 1, en: "Innovation, Science and Economic Development handles this file.", fr: "Pensez au portefeuille civil." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("distinctive-two-word-answer-copy", hint({ hints: [
    { level: 1, en: "Economic Development is the phrase to remember.", fr: "Pensez au portefeuille civil." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("short-single-token-answer-copy", hint({ hints: [
    { level: 1, en: "Choose SSB after reading the setup.", fr: "Choisissez BLU après avoir lu le contexte." },
    { level: 2, en: "Use the mode clue.", fr: "Utilisez l'indice sur le mode." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "SSB", fr: "BLU" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "AM", fr: "MA" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "FM", fr: "MF" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "CW", fr: "CW" } },
  ] })]);

  await assertSelfTestAccepts("short-function-word-answer-copy", hint({ hints: [
    { level: 1, en: "The one is this.", fr: "C'est cela." },
    { level: 2, en: "That is where it is.", fr: "C'est là." },
  ] }), [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The one", fr: "C'est cela" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The other", fr: "L'autre" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "This one", fr: "Celui-ci" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "That one", fr: "Celui-là" } },
  ] })]);

  await assertSelfTestRejects("three-token-answer-two-word-run", hint({ hints: [
    { level: 1, en: "Telecommunication Union is the phrase to remember.", fr: "Pensez à l'organisme international." },
    { level: 2, en: "Use the international coordination clue.", fr: "Utilisez l'indice de coordination internationale." },
  ] }), "correct answer text", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "International Telecommunication Union", fr: "Union internationale des télécommunications" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Industry Canada", fr: "Industrie Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestAccepts("three-token-answer-two-word-run-shared-by-options", hint({ hints: [
    { level: 1, en: "Compare the Telecommunication Union role with domestic authorities.", fr: "Comparez le rôle international avec les autorités nationales." },
    { level: 2, en: "Use the difference between international coordination and domestic administration.", fr: "Utilisez la différence entre la coordination internationale et l'administration nationale." },
  ] }), [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "International Telecommunication Union", fr: "Union internationale des télécommunications" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Regional Telecommunication Union", fr: "Union régionale des télécommunications" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("answer-alias-ised", hint({ hints: [
    { level: 1, en: "ISED is the acronym to look for.", fr: "Pensez au portefeuille civil." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "correct answer alias", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("answer-alias-isde-fr", hint({ hints: [
    { level: 1, en: "Think about the civilian regulator.", fr: "ISDE est le sigle à chercher." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "correct answer alias", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("answer-alias-radiocommunications-act", hint({ hints: [
    { level: 1, en: "Radiocommunications Act is the variant to remember.", fr: "Pensez à la source juridique." },
    { level: 2, en: "Use the legal hierarchy.", fr: "Utilisez la hiérarchie juridique." },
  ] }), "correct answer alias", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The Broadcasting Act", fr: "La Loi sur la radiodiffusion" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "The Radio Regulations", fr: "Le règlement radio" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "A station standard", fr: "Une norme de station" } },
  ] })]);

  await assertSelfTestRejects("answer-alias-rbr-4", hint({ hints: [
    { level: 1, en: "RBR-4 is the document label to look for.", fr: "Pensez aux normes de station." },
    { level: 2, en: "Use the station-operation document clue.", fr: "Utilisez l'indice sur l'exploitation des stations." },
  ] }), "correct answer alias", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "The Standards for the Operation of Radio Stations in the Amateur Radio Service", fr: "Les Normes relatives à l'exploitation des stations radio du service de radioamateur" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "The Radiocommunication Regulations", fr: "Le Règlement sur la radiocommunication" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "A radio policy", fr: "Une politique radio" } },
  ] })]);

  await assertSelfTestRejects("option-alias-dnd", hint({ hints: [
    { level: 1, en: "DND is not the civilian regulator.", fr: "Pensez au portefeuille civil." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "answer option sourceIndex 3 alias", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestRejects("significant-option-token-run-fr", hint({ hints: [
    { level: 1, en: "Think about the civilian regulator.", fr: "Regardez au Centre de la sécurité des télécommunications Canada." },
    { level: 2, en: "Use the legal hierarchy.", fr: "Utilisez la hiérarchie juridique." },
  ] }), "answer option sourceIndex 2", [question({ answers: [
    { sourceIndex: 0, isCorrect: true, text: { en: "Innovation, Science and Economic Development Canada", fr: "Innovation, Sciences et Développement économique Canada" } },
    { sourceIndex: 1, isCorrect: false, text: { en: "Transport Canada", fr: "Transports Canada" } },
    { sourceIndex: 2, isCorrect: false, text: { en: "Communications Security Establishment Canada", fr: "Le Centre de la sécurité des télécommunications Canada" } },
    { sourceIndex: 3, isCorrect: false, text: { en: "National Defence", fr: "Défense nationale" } },
  ] })]);

  await assertSelfTestAccepts("option-run-copied-from-question", hint({ hints: [
    { level: 1, en: "Think about where the amateur radio service is described in the legal framework.", fr: "Pensez au niveau du cadre juridique." },
    { level: 2, en: "Use the relationship between statutes, regulations, and standards.", fr: "Utilisez le lien entre les lois, les règlements et les normes." },
  ] }), [question({
    text: { en: "Which document defines the Canadian amateur radio service?", fr: "Quel document définit le service de radioamateur au Canada?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "The Radiocommunication Regulations", fr: "Le Règlement sur la radiocommunication" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "The Radiocommunication Act", fr: "La Loi sur la radiocommunication" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "The Standards for the Operation of Radio Stations in the Amateur Radio Service", fr: "Les Normes relatives à l'exploitation des stations radio du service de radioamateur" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "The Radio Systems Policies", fr: "La Politique des systèmes radio" } },
    ],
  })]);

  await assertSelfTestAccepts("option-run-shared-by-options", hint({ hints: [
    { level: 1, en: "An azimuthal map uses a map projection centred for a purpose.", fr: "Pensez au type de projection cartographique." },
    { level: 2, en: "Use the station location context before reading the map.", fr: "Utilisez le contexte de l'emplacement de la station." },
  ] }), [question({
    text: { en: "What is an azimuthal map?", fr: "Qu'est-ce qu'une carte géographique azimutale?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "A map projection centred on a given location", fr: "Une projection cartographique centrée sur un emplacement donné" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "A map projection displaying Maidenhead grid squares", fr: "Une projection cartographique montrant des grilles" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "A map projection centred on the magnetic North Pole", fr: "Une projection cartographique centrée sur le pôle Nord magnétique" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "A map projection centred on the geographic North Pole", fr: "Une projection cartographique centrée sur le pôle Nord géographique" } },
    ],
  })]);

  await withSelfTestFixture("b-001-003-003-shared-fine", async (root) => {
    const regressionQuestion = question({
      id: "B-001-003-003",
      subsectionId: "B-001-003",
      text: {
        en: "Transmitting a false or fraudulent distress signal or message is prohibited. The person found guilty is liable to what penalty?",
        fr: "Émettre faussement ou frauduleusement un signal de détresse ou un message est interdit. Quelle est la peine encourue par une personne reconnue coupable de cette infraction?",
      },
      answers: [
        { sourceIndex: 0, isCorrect: true, text: { en: "A fine, not exceeding $5 000, or a prison term not exceeding one year, or both", fr: "Une amende maximale de 5 000 $, ou un emprisonnement maximal d'un an, ou les deux à la fois" } },
        { sourceIndex: 1, isCorrect: false, text: { en: "A fine of $10 000", fr: "Une amende de 10 000 $" } },
        { sourceIndex: 2, isCorrect: false, text: { en: "A prison term of two years", fr: "Un emprisonnement de deux ans" } },
        { sourceIndex: 3, isCorrect: false, text: { en: "A fine not exceeding $1 000", fr: "Une amende maximale de 1 000 $" } },
      ],
    });
    const regressionHint = hint({
      id: "HINT-B-001-003-003",
      questionId: "B-001-003-003",
      hints: [
        { level: 1, en: "Consider fine before choosing.", fr: "Pensez à l'amende avant de choisir." },
      ],
      lessonLink: { lessonId: "L-001-01", sectionAnchor: "shared-setup" },
      singleLevelReason: "Fixture regression uses one level to isolate shared-option wording.",
    });
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify([regressionQuestion], null, 2)}\n`, "utf8");
    await writeFile(path.join(root, "content/hints/b-001/b-001-003-003.json"), `${JSON.stringify(regressionHint, null, 2)}\n`, "utf8");
    await writeFile(path.join(root, "content/lessons/m1-regulations-policies/l-001-01.md"), `---\ntype: lesson\nid: L-001-01\ntitle:\n  en: "Fixture Lesson"\ncovers:\n  - B-001-003\n---\n# Fixture Lesson\n\n## Shared setup\n\nA fixture lesson section.\n`, "utf8");
    await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });
  });

  await assertSelfTestRejects("short-correct-answer-shared-by-options", hint({ hints: [
    { level: 1, en: "Canadian visitors need only Basic before operating.", fr: "Pensez à la compétence de visite." },
    { level: 2, en: "Use the visiting-operator privilege row.", fr: "Utilisez la ligne sur les privilèges de visite." },
  ] }), "correct answer text", [question({
    text: { en: "What Canadian qualification must a visitor hold?", fr: "Quelle compétence canadienne un visiteur doit-il détenir?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Basic", fr: "Compétence de base" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Basic with Honours", fr: "Compétence de base avec distinction" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Basic with Morse code", fr: "Compétence de base avec code Morse" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Advanced", fr: "Compétence supérieure" } },
    ],
  })]);

  await assertSelfTestRejects("short-question-fragment", hint({ hints: [
    { level: 1, en: "Ask which department administers the Radiocommunication Act.", fr: "Pensez à l'administration civile." },
    { level: 2, en: "Use the civilian regulator clue.", fr: "Utilisez l'indice de réglementation civile." },
  ] }), "copies a long question fragment", [question({
    text: { en: "Which department administers the Radiocommunication Act?", fr: "Quel ministère applique la loi radio?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Spectrum office", fr: "Bureau du spectre" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Transport office", fr: "Bureau des transports" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Military office", fr: "Bureau militaire" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Broadcast office", fr: "Bureau de diffusion" } },
    ],
  })]);

  const numericCases = [
    { name: "12-v", answer: "12 V", questionWithValue: "The question gives 12 V and asks what value to carry forward.", leakingHint: "Use 12 V as the final value." },
    { name: "1500-khz", answer: "1 500 kHz", questionWithValue: "The question gives 1 500 kHz and asks what value to carry forward.", leakingHint: "Use 1500 kHz as the final value." },
    { name: "1500-khz-en-comma", answer: "1 500 kHz", questionWithValue: "The question gives 1 500 kHz and asks what value to carry forward.", leakingHint: "Use 1,500 kHz as the final value." },
    { name: "0-5-a", answer: "0.5 A", questionWithValue: "The question gives 0.5 A and asks what value to carry forward.", leakingHint: "Use 0.5 A as the final value." },
    { name: "50-period", answer: "50", questionWithValue: "The question gives 50 and asks what value to carry forward.", leakingHint: "Use 50." },
    { name: "50-ohms", answer: "50 ohms", questionWithValue: "The question gives a 50 ohms load and asks what value to carry forward.", leakingHint: "Use 50 in the relationship." },
    { name: "5-08-metres", answer: "5.08 metres", questionWithValue: "The question gives 5.08 metres and asks what value to carry forward.", leakingHint: "The setup gives about 5.08 metres." },
    { name: "10-microfarads", answer: "10 microfarads", questionWithValue: "The question gives 10 microfarads and asks what value to carry forward.", leakingHint: "The capacitance is 10 microfarads." },
    { name: "270-kilohms", answer: "270 kilohms", questionWithValue: "The question gives 270 kilohms and asks what value to carry forward.", leakingHint: "Use 270 kilohms." },
    { name: "13-dbi", answer: "13 dBi", questionWithValue: "The question gives 13 dBi and asks what value to carry forward.", leakingHint: "The gain is 13 dBi." },
    { name: "11-years", answer: "11 years", questionWithValue: "The question gives 11 years and asks what value to carry forward.", leakingHint: "The interval is 11 years." },
    { name: "5-wpm", answer: "5 wpm", questionWithValue: "The question gives 5 wpm and asks what value to carry forward.", leakingHint: "Use 5 wpm." },
  ] as const;

  for (const numericCase of numericCases) {
    const numericQuestion = question({
      text: { en: "Fixture calculation question?", fr: "Question de calcul fictive?" },
      answers: [
        { sourceIndex: 0, isCorrect: true, text: { en: numericCase.answer, fr: numericCase.answer } },
        { sourceIndex: 1, isCorrect: false, text: { en: "Use the formula", fr: "Utilisez la formule" } },
        { sourceIndex: 2, isCorrect: false, text: { en: "Convert first", fr: "Convertissez d'abord" } },
        { sourceIndex: 3, isCorrect: false, text: { en: "Round early", fr: "Arrondissez tôt" } },
      ],
    });
    await assertSelfTestRejects(`numeric-answer-${numericCase.name}`, hint({ hints: [
      { level: 1, en: numericCase.leakingHint, fr: numericCase.leakingHint },
      { level: 2, en: "Set up the relationship before solving.", fr: "Établissez la relation avant de calculer." },
    ] }), "correct answer numeric value", [numericQuestion]);

    await withSelfTestFixture(`numeric-question-${numericCase.name}`, async (root) => {
      await writeSelfTestFixture(root, hint({ hints: [
        { level: 1, en: numericCase.leakingHint, fr: numericCase.leakingHint },
        { level: 2, en: "Set up the relationship before solving.", fr: "Établissez la relation avant de calculer." },
      ] }), [question({ ...numericQuestion, text: { en: numericCase.questionWithValue, fr: numericCase.questionWithValue } })]);
      await checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
        requireComplete: true,
      });
    });
  }

  await assertSelfTestRejects("numeric-answer-fr-mots-min", hint({ hints: [
    { level: 1, en: "Set up the Morse speed before answering.", fr: "Utilisez 5 mots/min." },
    { level: 2, en: "Keep speed separate from message content.", fr: "Gardez la vitesse distincte du contenu du message." },
  ] }), "correct answer numeric value", [question({
    text: { en: "Fixture Morse question?", fr: "Question fictive de Morse?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "5 wpm", fr: "5 mots/min" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "10 wpm", fr: "10 mots/min" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "15 wpm", fr: "15 mots/min" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "20 wpm", fr: "20 mots/min" } },
    ],
  })]);

  await assertSelfTestRejects("numeric-answer-fr-degres", hint({ hints: [
    { level: 1, en: "Set up the angle before answering.", fr: "Utilisez 180 degrés." },
    { level: 2, en: "Keep the phase relationship separate from the display shape.", fr: "Gardez la relation de phase distincte de la forme affichée." },
  ] }), "correct answer numeric value", [question({
    text: { en: "Fixture angle question?", fr: "Question fictive d'angle?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "180 degrees", fr: "180 degrés" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "90 degrees", fr: "90 degrés" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "45 degrees", fr: "45 degrés" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "0 degrees", fr: "0 degré" } },
    ],
  })]);

  await assertSelfTestRejects("numeric-answer-days-fallback", hint({ hints: [
    { level: 1, en: "Complete the update within 30 days.", fr: "Complétez la mise à jour dans les 30 jours." },
    { level: 2, en: "Use the notification timing rule.", fr: "Utilisez la règle de délai d'avis." },
  ] }), "correct answer numeric value", [question({
    text: { en: "Fixture notification question?", fr: "Question fictive d'avis?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "you must notify Innovation, Science and Economic Development Canada within 30 days of a change of mailing address", fr: "vous devez aviser Innovation, Sciences et Développement économique Canada dans les 30 jours suivant un changement d'adresse postale" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "you must notify the office within 14 days", fr: "vous devez aviser le bureau dans les 14 jours" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "you must notify the office within 60 days", fr: "vous devez aviser le bureau dans les 60 jours" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "you must notify the office within 90 days", fr: "vous devez aviser le bureau dans les 90 jours" } },
    ],
  })]);

  await assertSelfTestRejects("numeric-answer-currency-fallback", hint({ hints: [
    { level: 1, en: "The penalty can be up to $5 000.", fr: "La pénalité peut atteindre 5 000 $." },
    { level: 2, en: "Use the penalty ceiling in the rule.", fr: "Utilisez le plafond de pénalité de la règle." },
  ] }), "correct answer numeric value", [question({
    text: { en: "Fixture penalty question?", fr: "Question fictive de pénalité?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "A fine, not exceeding $5 000, or a prison term not exceeding one year, or both", fr: "Une amende maximale de 5 000 $, ou un emprisonnement maximal d'un an, ou les deux à la fois" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "A fine, not exceeding $10 000", fr: "Une amende maximale de 10 000 $" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "A fine, not exceeding $1 000", fr: "Une amende maximale de 1 000 $" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "A written warning", fr: "Un avertissement écrit" } },
    ],
  })]);

  await assertSelfTestAccepts("numeric-non-value-safety-code-6", hint({ hints: [
    { level: 1, en: "Use Safety Code 6 as the exposure framework before judging the statement.", fr: "Utilisez le Code de sécurité 6 comme cadre d'exposition avant de juger l'énoncé." },
    { level: 2, en: "Compare the statement with the exposure factors the code considers.", fr: "Comparez l'énoncé avec les facteurs d'exposition que le code considère." },
  ] }), [question({
    text: { en: "Which statement is NOT correct?", fr: "Lequel des énoncés suivants est FAUX?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Hand-held transmitters are excluded from Safety Code 6 requirements", fr: "Les émetteurs portatifs sont exemptés des exigences du Code de sécurité 6" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Antenna gain and distance influence exposure to radio energy", fr: "Le gain d'antenne et la distance influencent l'exposition à l'énergie radio" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Safety Code 6 uses different units for field strength", fr: "Le Code de sécurité 6 utilise des unités différentes pour le champ" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Safety Code 6 specifies lower limits for uncontrolled areas", fr: "Le Code de sécurité 6 stipule des limites plus basses pour les environnements non contrôlés" } },
    ],
  })]);

  await assertSelfTestRejects("document-label-answer-text", hint({ hints: [
    { level: 1, en: "RBR-4 is a document label here, not a calculation result.", fr: "RBR-4 est ici un titre de document, pas un résultat de calcul." },
    { level: 2, en: "Use the document context before deciding.", fr: "Utilisez le contexte du document avant de décider." },
  ] }), "correct answer text", [question({
    text: { en: "Which document label applies to the amateur operating standards?", fr: "Quelle étiquette de document s'applique aux normes d'exploitation radioamateur?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "RBR-4", fr: "RBR-4" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "CPC-2-0-03", fr: "CPC-2-0-03" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "RIC-3", fr: "CIR-3" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "EMCAB-2", fr: "CPCEM-2" } },
    ],
  })]);

  await assertSelfTestRejects("numeric-answer-fr-decimal-comma", hint({ hints: [
    { level: 1, en: "Set up the current relationship before calculating.", fr: "La relation donne 0,5 A avant l'arrondi." },
    { level: 2, en: "Use the current formula.", fr: "Utilisez la formule du courant." },
  ] }), "correct answer numeric value", [question({
    text: { en: "Fixture current question?", fr: "Question de courant fictive?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "0.5 A", fr: "0,5 A" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "1 A", fr: "1 A" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "5 A", fr: "5 A" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "10 A", fr: "10 A" } },
    ],
  })]);

  await assertSelfTestAccepts("numeric-answer-fr-decimal-comma-not-split", hint({ hints: [
    { level: 1, en: "Use the repeater sub-band boundary rather than a bare integer.", fr: "Ne traitez pas 500 comme une valeur indépendante." },
    { level: 2, en: "Keep the frequency as one MHz value.", fr: "Gardez la fréquence comme une seule valeur en MHz." },
  ] }), [question({
    text: { en: "Fixture frequency question?", fr: "Question de fréquence fictive?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "29.500 MHz", fr: "29,500 MHz" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "29.700 MHz", fr: "29,700 MHz" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "50 MHz", fr: "50 MHz" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "144 MHz", fr: "144 MHz" } },
    ],
  })]);
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));
  if (options.selfTest) {
    await runHintCheckerSelfTest();
    console.log("check-hints self-test: passed");
    return;
  }
  const report = await checkHints(options);
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    if (error instanceof HintCheckError) {
      console.error(`check-hints failed with ${error.report.issues.length} issue(s):`);
      for (const issue of error.report.issues.slice(0, 100)) {
        console.error(`- ${issue}`);
      }
      if (error.report.issues.length > 100) {
        console.error(`... ${error.report.issues.length - 100} more issue(s) omitted.`);
      }
    } else {
      const message = error instanceof Error ? error.message : String(error);
      console.error(message);
    }
    process.exitCode = 1;
  });
}
