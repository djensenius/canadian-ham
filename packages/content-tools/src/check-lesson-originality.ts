import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { ACTIVE_GENERATED_DIR } from "./active-bank.ts";
import { isMainModule } from "./cli.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons/m5-basic-electronics");
const ALL_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_QUESTIONS_PATH = path.join(REPO_ROOT, ACTIVE_GENERATED_DIR, "questions.json");
const DEFAULT_ALLOWLIST_PATH = path.join(REPO_ROOT, "content/lessons/originality-allowlist.json");
const FIVE_GRAM_SIZE = 5;
const SHARED_FIVE_GRAM_THRESHOLD = 5;
const SHARED_FIVE_GRAM_RATIO_THRESHOLD = 0.4;
const LONGEST_SHARED_WORD_RUN_THRESHOLD = 8;
const NUMERIC_CONTEXT_MATCH_THRESHOLD = 2;
const DIGIT_NUMBER_PATTERN_SOURCE = String.raw`(?:\d{1,3}(?:[\s\u00a0]\d{3})+(?:[,.]\d+)?|\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:[,.]\d+)?|\.\d+)`;
const DIGIT_NUMBER_PATTERN = new RegExp(String.raw`(?<![\p{L}\p{N}])${DIGIT_NUMBER_PATTERN_SOURCE}`, "gu");
const UNIT_AFTER_NUMBER_PATTERN = /^\s*(?:[-–—]\s*)?(k\s*(?:ohms?|[ΩΩω])|mega\s*hertz|kilohertz|hertz|megahertz|millihenries|millihenry|microfarads?|microfarad|milliamp(?:ere)?s?|microamp(?:ere)?s?|amperes?|amps?|farads?|ohms?|volts?|watts?|decibels?|degrees?|feet|foot|meters?|metres?|wavelengths?|(?:µ|μ|u)f|mhz|khz|kohms?|pf|ma|mh|hz|db|[avw]|[ΩΩω])/iu;

type NumericRequirement = {
  display: string;
  alternatives: string[];
};

type NumericUnitRequirement = {
  display: string;
  alternatives: string[];
  countsAsContextEvidence: boolean;
};

type UnitInfo = {
  family: string;
  multiplier?: number;
  countsAsContextEvidence: boolean;
};

// These are the reusable values that appeared in reviewed false positives: routine
// half/double/3 dB/10 dB steps, common ratios, Safety Code 6 references, and
// round arithmetic values. They suppress numeric-only matches only when the
// lesson block also lacks distinctive context words or matching number+unit pairs.
const COMMON_NUMERIC_TOKENS = new Set([
  "0.1",
  "0.2",
  "0.5",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "10",
  "20",
  "30",
  "50",
  "100",
]);

// Stop words remove function words and generic arithmetic/dB phrasing from the
// context fallback. Domain nouns such as component names remain available, and
// matching number+unit pairs provide separate context evidence for calculations.
const CONTEXT_STOP_WORDS = new Set([
  "a",
  "about",
  "above",
  "add",
  "adds",
  "all",
  "allow",
  "allowed",
  "amateur",
  "an",
  "and",
  "answer",
  "approximately",
  "approximate",
  "are",
  "as",
  "at",
  "be",
  "between",
  "by",
  "can",
  "change",
  "changed",
  "changes",
  "common",
  "compared",
  "decrease",
  "decreased",
  "decreases",
  "decibel",
  "decibels",
  "divide",
  "does",
  "each",
  "equal",
  "estimated",
  "find",
  "for",
  "from",
  "gain",
  "given",
  "has",
  "higher",
  "how",
  "if",
  "in",
  "increase",
  "increased",
  "increases",
  "is",
  "it",
  "its",
  "loss",
  "lower",
  "many",
  "minus",
  "of",
  "or",
  "original",
  "plus",
  "power",
  "ratio",
  "results",
  "roughly",
  "same",
  "signal",
  "step",
  "than",
  "that",
  "the",
  "their",
  "then",
  "these",
  "this",
  "times",
  "to",
  "total",
  "use",
  "uses",
  "using",
  "value",
  "values",
  "what",
  "when",
  "which",
  "with",
  "would",
  "you",
]);

const NUMERIC_UNIT_WORDS = new Set([
  "a",
  "amp",
  "amps",
  "ampere",
  "amperes",
  "db",
  "degree",
  "degrees",
  "f",
  "farad",
  "farads",
  "feet",
  "foot",
  "hz",
  "khz",
  "kilohertz",
  "kohm",
  "kohms",
  "ma",
  "meter",
  "meters",
  "metre",
  "metres",
  "mhz",
  "microamp",
  "microamps",
  "microfarad",
  "microfarads",
  "milliamp",
  "milliamps",
  "ohm",
  "ohms",
  "pf",
  "uf",
  "v",
  "volt",
  "volts",
  "w",
  "watt",
  "watts",
  "wavelength",
  "wavelengths",
]);

const NUMBER_WORDS = new Map<string, string>([
  ["zero", "0"],
  ["one", "1"],
  ["two", "2"],
  ["three", "3"],
  ["four", "4"],
  ["five", "5"],
  ["six", "6"],
  ["seven", "7"],
  ["eight", "8"],
  ["nine", "9"],
  ["ten", "10"],
  ["eleven", "11"],
  ["twelve", "12"],
  ["thirteen", "13"],
  ["fourteen", "14"],
  ["fifteen", "15"],
  ["sixteen", "16"],
  ["seventeen", "17"],
  ["eighteen", "18"],
  ["nineteen", "19"],
  ["twenty", "20"],
  ["twice", "2"],
  ["double", "2"],
  ["half", "0.5"],
  ["hundred", "100"],
  ["thousand", "1000"],
]);

const NUMBER_WORD_VALUES = new Map<string, number>([
  ["one", 1],
  ["two", 2],
  ["three", 3],
  ["four", 4],
  ["five", 5],
  ["six", 6],
  ["seven", 7],
  ["eight", 8],
  ["nine", 9],
  ["ten", 10],
  ["eleven", 11],
  ["twelve", 12],
  ["thirteen", 13],
  ["fourteen", 14],
  ["fifteen", 15],
  ["sixteen", 16],
  ["seventeen", 17],
  ["eighteen", 18],
  ["nineteen", 19],
  ["twenty", 20],
]);

type QuestionRecord = {
  id: string;
  subsectionId?: string;
  text: { en: string };
  answers: Array<{ isCorrect: boolean; text: { en: string } }>;
};

export type LessonOriginalityOptions = {
  lessonRoot?: string;
  questionsPath?: string;
  allowlistPath?: string;
  requireLessonFiles?: boolean;
};

export type LessonOriginalityIssue = {
  filePath: string;
  lessonId: string;
  blockHeading: string;
  questionId: string;
  issueType: "numeric-overlap" | "five-gram-overlap";
  segment: string;
  questionTokens: string[];
  answerTokens: string[];
  sharedFiveGrams: string[];
  sharedFiveGramRatio: number;
  longestSharedWordRun: number;
};

export type LessonOriginalityReport = {
  lessonFileCount: number;
  checkedQuestionCount: number;
  allowlistedBlockCount: number;
  issueCount: number;
  issues: LessonOriginalityIssue[];
  summaryLines: string[];
};

export class LessonOriginalityError extends Error {
  report: LessonOriginalityReport;

  constructor(report: LessonOriginalityReport, message = "lesson originality check failed") {
    super(message);
    this.report = report;
  }
}

type LessonMetadata = {
  id: string;
  categoryIds: Set<string>;
};

type LessonBlock = {
  heading: string;
  text: string;
};

type AllowlistEntry = {
  lessonId: string;
  blockHeading: string;
  reason: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function normalizeNumericToken(token: string): string {
  const compact = token.replace(/[\s\u00a0]/g, "");
  const decimalNormalized = compact.includes(",") && !compact.includes(".") && !/^\d{1,3}(?:,\d{3})+$/.test(compact)
    ? compact.replace(/,/g, ".")
    : compact.replace(/,/g, "");
  const withLeadingZero = decimalNormalized.startsWith(".") ? `0${decimalNormalized}` : decimalNormalized;
  if (withLeadingZero.includes(".")) {
    const [rawInteger, rawFraction = ""] = withLeadingZero.split(".");
    const integer = rawInteger.replace(/^0+(?=\d)/, "") || "0";
    const fraction = rawFraction.replace(/0+$/, "");
    return fraction.length > 0 ? `${integer}.${fraction}` : integer;
  }
  return withLeadingZero.replace(/^0+(?=\d)/, "") || "0";
}

function normalizeScaledNumericToken(value: string, multiplier: number): string | null {
  const scaled = Number(value) * multiplier;
  if (!Number.isFinite(scaled)) {
    return null;
  }
  return normalizeNumericToken(scaled.toLocaleString("en-US", { maximumFractionDigits: 12, useGrouping: false }));
}

function unitInfoFromRaw(rawUnit: string): UnitInfo | null {
  const unit = rawUnit.toLowerCase().replace(/[\s-]/g, "").replace(/[μµ]/g, "µ").replace(/[ΩΩω]/g, "ω");
  if (unit === "uf" || unit === "µf" || unit === "microfarad" || unit === "microfarads") {
    return { family: "microfarad", countsAsContextEvidence: true };
  }
  if (unit === "farad" || unit === "farads" || unit === "pf") {
    return { family: "farad", countsAsContextEvidence: true };
  }
  if (unit === "mh" || unit === "millihenry" || unit === "millihenries") {
    return { family: "millihenry", countsAsContextEvidence: true };
  }
  if (unit === "ω" || unit === "ohm" || unit === "ohms") {
    return { family: "ohm", countsAsContextEvidence: true };
  }
  if (unit === "kohm" || unit === "kohms" || unit === "kω") {
    return { family: "ohm", multiplier: 1000, countsAsContextEvidence: true };
  }
  if (unit === "v" || unit === "volt" || unit === "volts") {
    return { family: "volt", countsAsContextEvidence: true };
  }
  if (unit === "w" || unit === "watt" || unit === "watts") {
    return { family: "watt", countsAsContextEvidence: true };
  }
  // Frequency/current conversions are taught as general metric-prefix facts in
  // lessons, and dB is a standard ratio shortcut; they normalize for numeric
  // matching but do not count as context evidence without a real scenario word.
  if (unit === "a" || unit === "amp" || unit === "amps" || unit === "ampere" || unit === "amperes") {
    return { family: "ampere", countsAsContextEvidence: false };
  }
  if (unit === "ma" || unit === "milliamp" || unit === "milliamps" || unit === "milliampere" || unit === "milliamperes") {
    return { family: "milliampere", countsAsContextEvidence: false };
  }
  if (unit === "microamp" || unit === "microamps" || unit === "microampere" || unit === "microamperes") {
    return { family: "microampere", countsAsContextEvidence: false };
  }
  if (unit === "hz" || unit === "hertz") {
    return { family: "hertz", multiplier: 1, countsAsContextEvidence: false };
  }
  if (unit === "khz" || unit === "kilohertz") {
    return { family: "hertz", multiplier: 1000, countsAsContextEvidence: false };
  }
  if (unit === "mhz" || unit === "megahertz") {
    return { family: "hertz", multiplier: 1000000, countsAsContextEvidence: false };
  }
  if (unit === "db" || unit === "decibel" || unit === "decibels") {
    return { family: "decibel", countsAsContextEvidence: false };
  }
  if (unit === "degree" || unit === "degrees") {
    return { family: "degree", countsAsContextEvidence: true };
  }
  if (unit === "foot" || unit === "feet" || unit === "meter" || unit === "meters" || unit === "metre" || unit === "metres" || unit === "wavelength" || unit === "wavelengths") {
    return { family: "length", countsAsContextEvidence: true };
  }
  return null;
}

function unitInfoAfterNumber(text: string, numberEndIndex: number): UnitInfo | null {
  const unitMatch = text.slice(numberEndIndex).match(UNIT_AFTER_NUMBER_PATTERN);
  return unitMatch === null ? null : unitInfoFromRaw(unitMatch[1]!);
}

function addNumericRequirement(requirements: Map<string, NumericRequirement>, display: string, alternatives: Iterable<string>): void {
  const normalizedAlternatives = [...new Set([display, ...alternatives].map((alternative) => normalizeNumericToken(alternative)))];
  const key = normalizedAlternatives.join("/");
  if (!requirements.has(key)) {
    requirements.set(key, { display, alternatives: normalizedAlternatives });
  }
}

function numericRequirements(text: string): NumericRequirement[] {
  const requirements = new Map<string, NumericRequirement>();
  for (const match of text.matchAll(DIGIT_NUMBER_PATTERN)) {
    const display = normalizeNumericToken(match[0]!);
    const alternatives = [display];
    const unitInfo = unitInfoAfterNumber(text, (match.index ?? 0) + match[0]!.length);
    if (unitInfo?.multiplier !== undefined) {
      const scaled = normalizeScaledNumericToken(display, unitInfo.multiplier);
      if (scaled !== null) {
        alternatives.push(scaled);
      }
    } else {
      const multiplierMatch = text.slice((match.index ?? 0) + match[0]!.length).match(/^\s*k(?![\p{L}\p{N}])/u);
      if (multiplierMatch !== null) {
        const scaled = normalizeScaledNumericToken(display, 1000);
        if (scaled !== null) {
          alternatives.push(scaled);
        }
      }
    }
    addNumericRequirement(requirements, display, alternatives);
  }

  const words = normalizeWordTokens(text);
  for (const [index, word] of words.entries()) {
    const numericWord = NUMBER_WORDS.get(word);
    if (numericWord !== undefined) {
      addNumericRequirement(requirements, numericWord, [numericWord]);
    }

    const nextWord = words[index + 1];
    const baseValue = NUMBER_WORD_VALUES.get(word);
    if (baseValue !== undefined && (nextWord === "hundred" || nextWord === "thousand")) {
      const value = String(baseValue * (nextWord === "hundred" ? 100 : 1000));
      addNumericRequirement(requirements, value, [value]);
    }
  }
  return [...requirements.values()];
}

function numericTokens(text: string): Set<string> {
  return new Set(numericRequirements(text).flatMap((requirement) => requirement.alternatives));
}

function numericUnitRequirements(text: string): NumericUnitRequirement[] {
  const requirements = new Map<string, NumericUnitRequirement>();
  for (const match of text.matchAll(DIGIT_NUMBER_PATTERN)) {
    const displayNumber = normalizeNumericToken(match[0]!);
    const unitInfo = unitInfoAfterNumber(text, (match.index ?? 0) + match[0]!.length);
    if (unitInfo === null) {
      continue;
    }
    const alternatives = [`${displayNumber}:${unitInfo.family}`];
    if (unitInfo.multiplier !== undefined) {
      const scaled = normalizeScaledNumericToken(displayNumber, unitInfo.multiplier);
      if (scaled !== null) {
        alternatives.push(`${scaled}:${unitInfo.family}`);
      }
    }
    const normalizedAlternatives = [...new Set(alternatives)];
    const key = normalizedAlternatives.join("/");
    if (!requirements.has(key)) {
      requirements.set(key, {
        display: `${displayNumber}:${unitInfo.family}`,
        alternatives: normalizedAlternatives,
        countsAsContextEvidence: unitInfo.countsAsContextEvidence,
      });
    }
  }
  return [...requirements.values()];
}

function numericUnitPairTokens(text: string): Set<string> {
  return new Set(numericUnitRequirements(text).flatMap((requirement) => requirement.alternatives));
}

function normalizeWordTokens(text: string): string[] {
  return [...text.toLowerCase().matchAll(/[\p{L}\p{N}]+/gu)].map((match) => match[0]!);
}

function contextTokenStem(token: string): string {
  if (token.length > 5 && token.endsWith("ies")) {
    return `${token.slice(0, -3)}y`;
  }
  if (token.length > 6 && token.endsWith("ing")) {
    return token.slice(0, -3);
  }
  if (token.length > 5 && token.endsWith("ed")) {
    return token.slice(0, -2);
  }
  if (token.length > 4 && token.endsWith("es")) {
    return token.slice(0, -2);
  }
  if (token.length > 3 && token.endsWith("s")) {
    return token.slice(0, -1);
  }
  return token;
}

function numericContextTokens(text: string): string[] {
  const tokens = new Set<string>();
  for (const word of normalizeWordTokens(text)) {
    if (word.length <= 2 || CONTEXT_STOP_WORDS.has(word) || NUMBER_WORDS.has(word) || NUMERIC_UNIT_WORDS.has(word) || /^\d+$/.test(word)) {
      continue;
    }
    const stemmed = contextTokenStem(word);
    if (stemmed.length > 2 && !CONTEXT_STOP_WORDS.has(stemmed) && !NUMERIC_UNIT_WORDS.has(stemmed)) {
      tokens.add(stemmed);
    }
  }
  return [...tokens].sort();
}

function fiveGramsFromWords(words: string[]): Set<string> {
  const grams = new Set<string>();
  for (let index = 0; index <= words.length - FIVE_GRAM_SIZE; index += 1) {
    grams.add(words.slice(index, index + FIVE_GRAM_SIZE).join(" "));
  }
  return grams;
}

function fiveGrams(text: string): Set<string> {
  return fiveGramsFromWords(normalizeWordTokens(text));
}

function longestSharedWordRun(left: string[], right: string[]): number {
  if (left.length === 0 || right.length === 0) {
    return 0;
  }
  const previousRow = new Array<number>(right.length + 1).fill(0);
  const currentRow = new Array<number>(right.length + 1).fill(0);
  let longest = 0;

  for (let leftIndex = 1; leftIndex <= left.length; leftIndex += 1) {
    for (let rightIndex = 1; rightIndex <= right.length; rightIndex += 1) {
      if (left[leftIndex - 1] === right[rightIndex - 1]) {
        currentRow[rightIndex] = previousRow[rightIndex - 1]! + 1;
        longest = Math.max(longest, currentRow[rightIndex]!);
      } else {
        currentRow[rightIndex] = 0;
      }
    }
    previousRow.splice(0, previousRow.length, ...currentRow);
    currentRow.fill(0);
  }

  return longest;
}

function stripFrontMatter(markdown: string): string {
  if (!markdown.startsWith("---\n")) {
    return markdown;
  }
  const closeIndex = markdown.indexOf("\n---", 4);
  return closeIndex === -1 ? markdown : markdown.slice(closeIndex + 4);
}

function parseYamlString(raw: string): string {
  const trimmed = raw.trim();
  if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
    return JSON.parse(trimmed) as string;
  }
  return trimmed;
}

function parseFrontMatterArray(frontMatter: string, key: string): string[] {
  const lines = frontMatter.split("\n");
  const values: string[] = [];
  let inTarget = false;
  for (const line of lines) {
    if (line.startsWith(`${key}:`)) {
      const inline = line.slice(key.length + 1).trim();
      if (inline === "[]") {
        return [];
      }
      inTarget = inline.length === 0;
      continue;
    }
    if (inTarget) {
      const item = line.match(/^  - (.+)$/);
      if (item) {
        values.push(parseYamlString(item[1]!));
        continue;
      }
      if (!line.startsWith(" ") && line.trim().length > 0) {
        break;
      }
    }
  }
  return values;
}

function frontMatter(markdown: string): string | null {
  if (!markdown.startsWith("---\n")) {
    return null;
  }
  const closeIndex = markdown.indexOf("\n---", 4);
  return closeIndex === -1 ? null : markdown.slice(4, closeIndex);
}

function frontMatterString(frontMatterText: string, key: string): string | null {
  const match = frontMatterText.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  return match ? parseYamlString(match[1]!) : null;
}

function lessonMetadata(markdown: string): LessonMetadata {
  const frontMatterText = frontMatter(markdown);
  if (frontMatterText === null) {
    return { id: "", categoryIds: new Set() };
  }
  return {
    id: frontMatterString(frontMatterText, "id") ?? "",
    categoryIds: new Set(parseFrontMatterArray(frontMatterText, "categoryIds")),
  };
}

function isLessonMarkdown(markdown: string, filePath: string): boolean {
  if (path.basename(filePath).toLowerCase() === "readme.md") {
    return false;
  }
  const frontMatterText = frontMatter(markdown);
  return frontMatterText === null || frontMatterString(frontMatterText, "type") === "lesson";
}

function normalizeBlockLine(line: string): string {
  const trimmed = line.trim();
  const listItem = trimmed.match(/^(?:[-*+] |\d+[.)] )(.*)$/);
  return listItem ? listItem[1]!.trim() : trimmed;
}

function lessonBlocks(markdown: string): LessonBlock[] {
  const body = stripFrontMatter(markdown).replace(/\r\n/g, "\n");
  const blocks: LessonBlock[] = [];
  let currentHeading = "";
  let currentLines: string[] = [];

  function flushBlock(): void {
    const text = currentLines.map(normalizeBlockLine).filter((line) => line.length > 0).join(" ").trim();
    if (text.length > 0) {
      blocks.push({ heading: currentHeading, text });
    }
    currentLines = [];
  }

  for (const line of body.split("\n")) {
    const heading = line.match(/^(#{1,3})\s+(.+)$/);
    if (heading) {
      flushBlock();
      currentHeading = heading[2]!.trim();
      currentLines = [currentHeading];
      continue;
    }
    currentLines.push(line);
  }
  flushBlock();
  return blocks;
}

async function findMarkdownFiles(root: string): Promise<string[]> {
  const entries = await readdir(root, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findMarkdownFiles(entryPath));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(entryPath);
    }
  }
  return files.sort();
}

type QuestionCheck = {
  id: string;
  subsectionId: string;
  categoryId: string;
  questionNumberRequirements: NumericRequirement[];
  answerNumberRequirements: NumericRequirement[];
  numericUnitRequirements: NumericUnitRequirement[];
  numericContextTokens: string[];
  sourceWords: string[];
  sourceFiveGrams: Set<string>;
};

function categoryIdFromSubsection(subsectionId: string): string {
  const parts = subsectionId.split("-");
  return parts.length >= 2 ? `${parts[0]}-${parts[1]}` : "";
}

async function loadQuestions(questionsPath: string): Promise<QuestionCheck[]> {
  const raw: unknown = JSON.parse(await readFile(questionsPath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error(`${questionsPath}: expected an array of question records`);
  }
  const records: QuestionCheck[] = [];
  for (const item of raw) {
    if (!isRecord(item) || typeof item.id !== "string" || !isRecord(item.text) || typeof item.text.en !== "string" || !Array.isArray(item.answers)) {
      continue;
    }
    const question = item as QuestionRecord;
    const correctAnswer = question.answers.find((answer) => isRecord(answer) && answer.isCorrect === true && isRecord(answer.text) && typeof answer.text.en === "string");
    if (correctAnswer === undefined) {
      continue;
    }
    const sourceText = `${question.text.en} ${correctAnswer.text.en}`;
    const subsectionId = typeof question.subsectionId === "string" ? question.subsectionId : "";
    const sourceWords = normalizeWordTokens(sourceText);
    records.push({
      id: question.id,
      subsectionId,
      categoryId: categoryIdFromSubsection(subsectionId),
      questionNumberRequirements: numericRequirements(question.text.en),
      answerNumberRequirements: numericRequirements(correctAnswer.text.en),
      numericUnitRequirements: numericUnitRequirements(sourceText),
      numericContextTokens: numericContextTokens(question.text.en),
      sourceWords,
      sourceFiveGrams: fiveGramsFromWords(sourceWords),
    });
  }
  return records;
}

async function loadAllowlist(allowlistPath: string): Promise<Map<string, AllowlistEntry>> {
  let raw: string;
  try {
    raw = await readFile(allowlistPath, "utf8");
  } catch (error: unknown) {
    if (isRecord(error) && error.code === "ENOENT") {
      return new Map();
    }
    throw error;
  }

  const parsed: unknown = JSON.parse(raw);
  if (!Array.isArray(parsed)) {
    throw new Error(`${allowlistPath}: expected an array of allow-list entries`);
  }
  const entries = new Map<string, AllowlistEntry>();
  for (const [index, item] of parsed.entries()) {
    if (!isRecord(item) || typeof item.lessonId !== "string" || item.lessonId.trim().length === 0 || typeof item.blockHeading !== "string" || item.blockHeading.trim().length === 0 || typeof item.reason !== "string" || item.reason.trim().length === 0) {
      throw new Error(`${allowlistPath}: entry ${index} must include non-empty lessonId, blockHeading, and reason`);
    }
    const entry = {
      lessonId: item.lessonId.trim(),
      blockHeading: item.blockHeading.trim(),
      reason: item.reason.trim(),
    };
    entries.set(allowlistKey(entry.lessonId, entry.blockHeading), entry);
  }
  return entries;
}

function allowlistKey(lessonId: string, blockHeading: string): string {
  return `${lessonId}\u0000${blockHeading}`;
}

function sharedValues(left: Iterable<string>, right: Set<string>): string[] {
  return [...left].filter((value) => right.has(value)).sort();
}

function matchingNumericRequirementTokens(requirements: readonly NumericRequirement[], blockNumericTokens: Set<string>): string[] | null {
  const matches: string[] = [];
  for (const requirement of requirements) {
    const matchedAlternative = requirement.alternatives.find((alternative) => blockNumericTokens.has(alternative));
    if (matchedAlternative === undefined) {
      return null;
    }
    matches.push(matchedAlternative);
  }
  return matches;
}

function matchedNumericUnitEvidenceCount(question: QuestionCheck, blockNumericUnitPairs: Set<string>): number {
  let count = 0;
  for (const requirement of question.numericUnitRequirements) {
    if (requirement.countsAsContextEvidence && requirement.alternatives.some((alternative) => blockNumericUnitPairs.has(alternative))) {
      count += 1;
    }
  }
  return count;
}

function hasDistinctiveNumericQuestionEvidence(question: QuestionCheck, matchingQuestionTokens: readonly string[], matchingAnswerTokens: readonly string[], blockContextTokens: Set<string>, blockNumericUnitPairs: Set<string>): boolean {
  if (matchingQuestionTokens.some((token, index) => !COMMON_NUMERIC_TOKENS.has(token) && !COMMON_NUMERIC_TOKENS.has(question.questionNumberRequirements[index]?.display ?? token))) {
    return true;
  }

  const sharedContextTokens = sharedValues(question.numericContextTokens, blockContextTokens);
  const contextEvidenceCount = sharedContextTokens.length + matchedNumericUnitEvidenceCount(question, blockNumericUnitPairs);
  if (matchingAnswerTokens.some((token, index) => !COMMON_NUMERIC_TOKENS.has(token) && !COMMON_NUMERIC_TOKENS.has(question.answerNumberRequirements[index]?.display ?? token)) && contextEvidenceCount >= 1) {
    return true;
  }
  return contextEvidenceCount >= NUMERIC_CONTEXT_MATCH_THRESHOLD;
}

export async function checkLessonOriginality(options: LessonOriginalityOptions = {}): Promise<LessonOriginalityReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTIONS_PATH;
  const allowlistPath = options.allowlistPath ?? DEFAULT_ALLOWLIST_PATH;
  const requireLessonFiles = options.requireLessonFiles ?? false;
  const questionChecks = await loadQuestions(questionsPath);
  const allowlist = await loadAllowlist(allowlistPath);
  const files = await findMarkdownFiles(lessonRoot);
  const issues: LessonOriginalityIssue[] = [];
  const allowlistedBlocks = new Set<string>();
  let checkedFileCount = 0;

  for (const filePath of files) {
    const markdown = await readFile(filePath, "utf8");
    if (!isLessonMarkdown(markdown, filePath)) {
      continue;
    }
    checkedFileCount += 1;
    const metadata = lessonMetadata(markdown);
    const numericChecksForFile = metadata.categoryIds.size === 0
      ? questionChecks
      : questionChecks.filter((question) => metadata.categoryIds.has(question.categoryId));

    for (const block of lessonBlocks(markdown)) {
      const blockAllowlistKey = allowlistKey(metadata.id, block.heading);
      if (allowlist.has(blockAllowlistKey)) {
        allowlistedBlocks.add(blockAllowlistKey);
        continue;
      }

      const blockNumericTokens = numericTokens(block.text);
      const blockNumericUnitPairs = numericUnitPairTokens(block.text);
      const blockContextTokens = new Set(numericContextTokens(block.text));
      const blockWords = normalizeWordTokens(block.text);
      const blockFiveGrams = fiveGramsFromWords(blockWords);

      for (const question of numericChecksForFile) {
        if (question.questionNumberRequirements.length > 0 && question.answerNumberRequirements.length > 0) {
          const matchingQuestionTokens = matchingNumericRequirementTokens(question.questionNumberRequirements, blockNumericTokens);
          const matchingAnswerTokens = matchingNumericRequirementTokens(question.answerNumberRequirements, blockNumericTokens);
          if (
            matchingQuestionTokens !== null
            && matchingAnswerTokens !== null
            && hasDistinctiveNumericQuestionEvidence(question, matchingQuestionTokens, matchingAnswerTokens, blockContextTokens, blockNumericUnitPairs)
          ) {
            issues.push({
              filePath,
              lessonId: metadata.id,
              blockHeading: block.heading,
              questionId: question.id,
              issueType: "numeric-overlap",
              segment: block.text,
              questionTokens: matchingQuestionTokens,
              answerTokens: matchingAnswerTokens,
              sharedFiveGrams: [],
              sharedFiveGramRatio: 0,
              longestSharedWordRun: 0,
            });
          }
        }
      }

      for (const question of questionChecks) {
        const sharedFiveGrams = sharedValues(question.sourceFiveGrams, blockFiveGrams);
        const sharedFiveGramRatio = question.sourceFiveGrams.size === 0 ? 0 : sharedFiveGrams.length / question.sourceFiveGrams.size;
        const longestRun = longestSharedWordRun(question.sourceWords, blockWords);
        if (sharedFiveGrams.length >= SHARED_FIVE_GRAM_THRESHOLD || sharedFiveGramRatio >= SHARED_FIVE_GRAM_RATIO_THRESHOLD || longestRun >= LONGEST_SHARED_WORD_RUN_THRESHOLD) {
          issues.push({
            filePath,
            lessonId: metadata.id,
            blockHeading: block.heading,
            questionId: question.id,
            issueType: "five-gram-overlap",
            segment: block.text,
            questionTokens: [],
            answerTokens: [],
            sharedFiveGrams,
            sharedFiveGramRatio,
            longestSharedWordRun: longestRun,
          });
        }
      }
    }
  }

  const summaryLines = [
    `Lesson files checked: ${checkedFileCount}`,
    `Official questions checked: ${questionChecks.length}`,
    `Numeric originality window: one #/##/### heading block, scoped by lesson categoryIds; keyed answers require a distinctive question number, matching number+unit evidence, or ${NUMERIC_CONTEXT_MATCH_THRESHOLD} distinctive context words`,
    `Near-verbatim threshold: ${SHARED_FIVE_GRAM_THRESHOLD} shared word ${FIVE_GRAM_SIZE}-grams, ${Math.round(SHARED_FIVE_GRAM_RATIO_THRESHOLD * 100)}% of source ${FIVE_GRAM_SIZE}-grams, or ${LONGEST_SHARED_WORD_RUN_THRESHOLD} shared words in a row, across the whole bank`,
    `Allow-listed heading blocks skipped: ${allowlistedBlocks.size}`,
    `Originality issues: ${issues.length}`,
  ];
  const report = {
    lessonFileCount: checkedFileCount,
    checkedQuestionCount: questionChecks.length,
    allowlistedBlockCount: allowlistedBlocks.size,
    issueCount: issues.length,
    issues,
    summaryLines,
  };
  if (issues.length > 0) {
    throw new LessonOriginalityError(report);
  }
  if (requireLessonFiles && checkedFileCount === 0) {
    throw new LessonOriginalityError(report, "no lesson Markdown files were checked");
  }
  return report;
}

type LessonRootSelection = {
  lessonRoot?: string;
  requireLessonFiles: boolean;
};

function lessonRootFromArgs(args: string[]): LessonRootSelection {
  const rootArg = args.find((arg) => arg.startsWith("--lesson-root="));
  const requireLessonFiles = args.includes("--all");
  if (rootArg !== undefined) {
    return { lessonRoot: path.resolve(rootArg.slice("--lesson-root=".length)), requireLessonFiles };
  }
  if (requireLessonFiles) {
    return { lessonRoot: ALL_LESSON_ROOT, requireLessonFiles };
  }
  const positional = args.find((arg) => !arg.startsWith("--"));
  return { lessonRoot: positional === undefined ? undefined : path.resolve(positional), requireLessonFiles };
}

async function main(): Promise<void> {
  const lessonRootSelection = lessonRootFromArgs(process.argv.slice(2));
  const report = await checkLessonOriginality(lessonRootSelection);
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (isMainModule(import.meta)) {
  main().catch((error: unknown) => {
    if (error instanceof LessonOriginalityError) {
      if (error.report.issues.length === 0) {
        console.error(`check-lesson-originality: ${error.message}`);
      }
      for (const issue of error.report.issues) {
        if (issue.issueType === "numeric-overlap") {
          console.error(`${issue.filePath}: heading block "${issue.blockHeading}" reuses all numeric token(s) ${issue.questionTokens.join(", ")} with correct answer token(s) ${issue.answerTokens.join(", ")} from ${issue.questionId}`);
        } else {
          const ratio = Math.round(issue.sharedFiveGramRatio * 100);
          console.error(`${issue.filePath}: heading block "${issue.blockHeading}" shares ${issue.sharedFiveGrams.length} word ${FIVE_GRAM_SIZE}-grams (${ratio}%) and a ${issue.longestSharedWordRun}-word run with ${issue.questionId}: ${issue.sharedFiveGrams.slice(0, 3).join(" | ")}`);
        }
      }
      process.exitCode = 1;
      return;
    }
    const message = error instanceof Error ? error.message : String(error);
    console.error(`check-lesson-originality: ${message}`);
    process.exitCode = 1;
  });
}
