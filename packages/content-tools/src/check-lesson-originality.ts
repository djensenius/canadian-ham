import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons/m5-basic-electronics");
const ALL_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_QUESTIONS_PATH = path.join(REPO_ROOT, "content/generated/basic-2025-07-15/questions.json");
const FIVE_GRAM_SIZE = 5;
// Tuned on the current lesson corpus: a few shared 5-grams can be a generic
// formula or definition phrase, but five shared 5-grams in the same
// paragraph/list item catches bank-style stem-plus-answer restatements.
const SHARED_FIVE_GRAM_THRESHOLD = 5;

type QuestionRecord = {
  id: string;
  subsectionId?: string;
  text: { en: string };
  answers: Array<{ isCorrect: boolean; text: { en: string } }>;
};

export type LessonOriginalityOptions = {
  lessonRoot?: string;
  questionsPath?: string;
};

export type LessonOriginalityIssue = {
  filePath: string;
  questionId: string;
  issueType: "numeric-overlap" | "five-gram-overlap";
  segment: string;
  questionTokens: string[];
  answerTokens: string[];
  sharedFiveGrams: string[];
};

export type LessonOriginalityReport = {
  lessonFileCount: number;
  checkedQuestionCount: number;
  issueCount: number;
  issues: LessonOriginalityIssue[];
  summaryLines: string[];
};

export class LessonOriginalityError extends Error {
  report: LessonOriginalityReport;

  constructor(report: LessonOriginalityReport) {
    super("lesson originality check failed");
    this.report = report;
  }
}

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
  const digitPattern = /(?<![\p{L}])(?:\d+(?:[\s\u00a0,]\d{3})+|\d+)(?:\.\d+)?(?![\p{L}])|(?<![\p{L}])\.\d+(?![\p{L}])/gu;
  for (const match of text.matchAll(digitPattern)) {
    tokens.add(normalizeNumericToken(match[0]!));
  }
  return tokens;
}

function normalizeWordTokens(text: string): string[] {
  return [...text.toLowerCase().matchAll(/[\p{L}\p{N}]+/gu)].map((match) => match[0]!);
}

function fiveGrams(text: string): Set<string> {
  const words = normalizeWordTokens(text);
  const grams = new Set<string>();
  for (let index = 0; index <= words.length - FIVE_GRAM_SIZE; index += 1) {
    grams.add(words.slice(index, index + FIVE_GRAM_SIZE).join(" "));
  }
  return grams;
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

function isLessonMarkdown(markdown: string, filePath: string): boolean {
  if (path.basename(filePath).toLowerCase() === "readme.md") {
    return false;
  }
  const frontMatterText = frontMatter(markdown);
  return frontMatterText === null || frontMatterString(frontMatterText, "type") === "lesson";
}

function lessonCoveredSubsections(markdown: string): Set<string> {
  const frontMatterText = frontMatter(markdown);
  return frontMatterText === null ? new Set() : new Set(parseFrontMatterArray(frontMatterText, "covers"));
}

function lessonSegments(markdown: string): string[] {
  const body = stripFrontMatter(markdown).replace(/\r\n/g, "\n");
  const segments: string[] = [];
  const paragraphLines: string[] = [];

  function flushParagraph(): void {
    const segment = paragraphLines.join(" ").trim();
    if (segment.length > 0) {
      segments.push(segment);
    }
    paragraphLines.length = 0;
  }

  for (const line of body.split("\n")) {
    const trimmed = line.trim();
    if (trimmed.length === 0) {
      flushParagraph();
      continue;
    }
    if (trimmed.startsWith("|")) {
      flushParagraph();
      segments.push(trimmed);
      continue;
    }
    const listItem = trimmed.match(/^(?:[-*+] |\d+[.)] )(.*)$/);
    if (listItem) {
      flushParagraph();
      segments.push(listItem[1]!.trim());
      continue;
    }
    paragraphLines.push(trimmed);
  }
  flushParagraph();
  return segments;
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
  questionTokens: string[];
  answerTokens: string[];
  sourceFiveGrams: Set<string>;
};

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
    records.push({
      id: question.id,
      subsectionId: typeof question.subsectionId === "string" ? question.subsectionId : "",
      questionTokens: [...numericTokens(question.text.en)].sort(),
      answerTokens: [...numericTokens(correctAnswer.text.en)].sort(),
      sourceFiveGrams: fiveGrams(`${question.text.en} ${correctAnswer.text.en}`),
    });
  }
  return records;
}

function sharedValues(left: Iterable<string>, right: Set<string>): string[] {
  return [...left].filter((value) => right.has(value)).sort();
}

export async function checkLessonOriginality(options: LessonOriginalityOptions = {}): Promise<LessonOriginalityReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTIONS_PATH;
  const questionChecks = await loadQuestions(questionsPath);
  const files = await findMarkdownFiles(lessonRoot);
  const issues: LessonOriginalityIssue[] = [];
  let checkedFileCount = 0;

  for (const filePath of files) {
    const markdown = await readFile(filePath, "utf8");
    if (!isLessonMarkdown(markdown, filePath)) {
      continue;
    }
    checkedFileCount += 1;
    const coveredSubsections = lessonCoveredSubsections(markdown);
    const checksForFile = coveredSubsections.size === 0
      ? questionChecks
      : questionChecks.filter((question) => coveredSubsections.has(question.subsectionId));
    for (const segment of lessonSegments(markdown)) {
      const segmentNumericTokens = numericTokens(segment);
      const segmentFiveGrams = fiveGrams(segment);
      for (const question of checksForFile) {
        if (question.questionTokens.length > 0 && question.answerTokens.length > 0) {
          const matchingQuestionTokens = question.questionTokens.filter((token) => segmentNumericTokens.has(token));
          const matchingAnswerTokens = question.answerTokens.filter((token) => segmentNumericTokens.has(token));
          if (matchingQuestionTokens.length === question.questionTokens.length && matchingAnswerTokens.length === question.answerTokens.length) {
            issues.push({
              filePath,
              questionId: question.id,
              issueType: "numeric-overlap",
              segment,
              questionTokens: matchingQuestionTokens,
              answerTokens: matchingAnswerTokens,
              sharedFiveGrams: [],
            });
          }
        }

        const sharedFiveGrams = sharedValues(question.sourceFiveGrams, segmentFiveGrams);
        if (sharedFiveGrams.length >= SHARED_FIVE_GRAM_THRESHOLD) {
          issues.push({
            filePath,
            questionId: question.id,
            issueType: "five-gram-overlap",
            segment,
            questionTokens: [],
            answerTokens: [],
            sharedFiveGrams,
          });
        }
      }
    }
  }

  const summaryLines = [
    `Lesson files checked: ${checkedFileCount}`,
    `Official questions checked: ${questionChecks.length}`,
    `Near-verbatim threshold: ${SHARED_FIVE_GRAM_THRESHOLD} shared word ${FIVE_GRAM_SIZE}-grams in one paragraph/list item`,
    `Originality issues: ${issues.length}`,
  ];
  const report = {
    lessonFileCount: checkedFileCount,
    checkedQuestionCount: questionChecks.length,
    issueCount: issues.length,
    issues,
    summaryLines,
  };
  if (issues.length > 0) {
    throw new LessonOriginalityError(report);
  }
  return report;
}

function lessonRootFromArgs(args: string[]): string | undefined {
  const rootArg = args.find((arg) => arg.startsWith("--lesson-root="));
  if (rootArg !== undefined) {
    return path.resolve(rootArg.slice("--lesson-root=".length));
  }
  if (args.includes("--all")) {
    return ALL_LESSON_ROOT;
  }
  const positional = args.find((arg) => !arg.startsWith("--"));
  return positional === undefined ? undefined : path.resolve(positional);
}

async function main(): Promise<void> {
  const report = await checkLessonOriginality({ lessonRoot: lessonRootFromArgs(process.argv.slice(2)) });
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error: unknown) => {
    if (error instanceof LessonOriginalityError) {
      for (const issue of error.report.issues) {
        if (issue.issueType === "numeric-overlap") {
          console.error(`${issue.filePath}: paragraph/list item reuses all numeric token(s) ${issue.questionTokens.join(", ")} with correct answer token(s) ${issue.answerTokens.join(", ")} from ${issue.questionId}`);
        } else {
          console.error(`${issue.filePath}: paragraph/list item shares ${issue.sharedFiveGrams.length} word ${FIVE_GRAM_SIZE}-grams with ${issue.questionId}: ${issue.sharedFiveGrams.slice(0, 3).join(" | ")}`);
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
