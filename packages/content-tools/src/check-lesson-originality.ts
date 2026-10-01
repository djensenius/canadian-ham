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
  const cleaned = token.replace(/[\s\u00a0,]/g, "");
  const withLeadingZero = cleaned.startsWith(".") ? `0${cleaned}` : cleaned;
  if (withLeadingZero.includes(".")) {
    const [rawInteger, rawFraction = ""] = withLeadingZero.split(".");
    const integer = rawInteger.replace(/^0+(?=\d)/, "") || "0";
    const fraction = rawFraction.replace(/0+$/, "");
    return fraction.length > 0 ? `${integer}.${fraction}` : integer;
  }
  return cleaned.replace(/^0+(?=\d)/, "") || "0";
}

function numericTokens(text: string): Set<string> {
  const tokens = new Set<string>();
  const digitPattern = /(?<![\p{L}\p{N}])(?:\d+(?:[\s\u00a0,]\d{3})+|\d+)(?:\.\d+)?|(?<![\p{L}\p{N}])\.\d+/gu;
  for (const match of text.matchAll(digitPattern)) {
    tokens.add(normalizeNumericToken(match[0]!));
  }

  const words = normalizeWordTokens(text);
  for (const [index, word] of words.entries()) {
    const numericWord = NUMBER_WORDS.get(word);
    if (numericWord !== undefined) {
      tokens.add(numericWord);
    }

    const nextWord = words[index + 1];
    const baseValue = NUMBER_WORD_VALUES.get(word);
    if (baseValue !== undefined && (nextWord === "hundred" || nextWord === "thousand")) {
      tokens.add(String(baseValue * (nextWord === "hundred" ? 100 : 1000)));
    }
  }
  return tokens;
}

function normalizeWordTokens(text: string): string[] {
  return [...text.toLowerCase().matchAll(/[\p{L}\p{N}]+/gu)].map((match) => match[0]!);
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
  questionTokens: string[];
  answerTokens: string[];
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
      questionTokens: [...numericTokens(question.text.en)].sort(),
      answerTokens: [...numericTokens(correctAnswer.text.en)].sort(),
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
      const blockWords = normalizeWordTokens(block.text);
      const blockFiveGrams = fiveGramsFromWords(blockWords);

      for (const question of numericChecksForFile) {
        if (question.questionTokens.length > 0 && question.answerTokens.length > 0) {
          const matchingQuestionTokens = question.questionTokens.filter((token) => blockNumericTokens.has(token));
          const matchingAnswerTokens = question.answerTokens.filter((token) => blockNumericTokens.has(token));
          if (matchingQuestionTokens.length === question.questionTokens.length && matchingAnswerTokens.length === question.answerTokens.length) {
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
    `Numeric originality window: one #/##/### heading block, scoped by lesson categoryIds`,
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
