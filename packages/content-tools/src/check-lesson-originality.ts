import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons/m5-basic-electronics");
const DEFAULT_QUESTIONS_PATH = path.join(REPO_ROOT, "content/generated/basic-2025-07-15/questions.json");

type QuestionRecord = {
  id: string;
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
  questionTokens: string[];
  answerTokens: string[];
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

function normalizeToken(token: string): string {
  const noGroupingSpaces = token.replace(/(?<=\d) (?=\d{3}(?:\D|$))/g, "");
  const normalized = noGroupingSpaces.replace(/,/g, "");
  return normalized.replace(/^0+(?=\d)/, "") || "0";
}

function numericTokens(text: string): Set<string> {
  const tokens = new Set<string>();
  const pattern = /\d+(?:[,.]\d+)?(?: \d{3})*/g;
  for (const match of text.matchAll(pattern)) {
    tokens.add(normalizeToken(match[0]!));
  }
  return tokens;
}

function isDistinctiveNumericToken(token: string): boolean {
  if (token.includes(".")) {
    return true;
  }
  const value = Number(token);
  return Number.isFinite(value) && value >= 10;
}

function isDistinctiveQuestionToken(token: string): boolean {
  if (token.includes(".")) {
    return true;
  }
  const value = Number(token);
  return Number.isFinite(value) && value >= 1000;
}

function distinctiveQuestionTokens(text: string): string[] {
  return [...numericTokens(text)].filter(isDistinctiveQuestionToken);
}

function stripFrontMatter(markdown: string): string {
  if (!markdown.startsWith("---\n")) {
    return markdown;
  }
  const closeIndex = markdown.indexOf("\n---", 4);
  return closeIndex === -1 ? markdown : markdown.slice(closeIndex + 4);
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

async function loadQuestions(questionsPath: string): Promise<Array<{ id: string; questionTokens: string[]; answerTokens: string[] }>> {
  const raw: unknown = JSON.parse(await readFile(questionsPath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error(`${questionsPath}: expected an array of question records`);
  }
  const records: Array<{ id: string; questionTokens: string[]; answerTokens: string[] }> = [];
  for (const item of raw) {
    if (!isRecord(item) || typeof item.id !== "string" || !isRecord(item.text) || typeof item.text.en !== "string" || !Array.isArray(item.answers)) {
      continue;
    }
    const correctAnswer = item.answers.find((answer) => isRecord(answer) && answer.isCorrect === true && isRecord(answer.text) && typeof answer.text.en === "string") as { text: { en: string } } | undefined;
    if (correctAnswer === undefined) {
      continue;
    }
    const questionTokens = distinctiveQuestionTokens(item.text.en);
    const answerTokens = [...numericTokens(correctAnswer.text.en)].filter(isDistinctiveNumericToken);
    if (questionTokens.length > 0 && answerTokens.length > 0) {
      records.push({ id: item.id, questionTokens, answerTokens });
    }
  }
  return records;
}

export async function checkLessonOriginality(options: LessonOriginalityOptions = {}): Promise<LessonOriginalityReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTIONS_PATH;
  const questionChecks = await loadQuestions(questionsPath);
  const files = await findMarkdownFiles(lessonRoot);
  const issues: LessonOriginalityIssue[] = [];

  for (const filePath of files) {
    const markdown = stripFrontMatter(await readFile(filePath, "utf8"));
    const lessonTokens = numericTokens(markdown);
    for (const question of questionChecks) {
      const matchingQuestionTokens = question.questionTokens.filter((token) => lessonTokens.has(token));
      if (matchingQuestionTokens.length === 0) {
        continue;
      }
      const matchingAnswerTokens = question.answerTokens.filter((token) => lessonTokens.has(token));
      if (matchingAnswerTokens.length > 0) {
        issues.push({
          filePath,
          questionId: question.id,
          questionTokens: matchingQuestionTokens,
          answerTokens: matchingAnswerTokens,
        });
      }
    }
  }

  const summaryLines = [
    `Lesson files checked: ${files.length}`,
    `Official questions with numeric question/answer tokens checked: ${questionChecks.length}`,
    `Originality issues: ${issues.length}`,
  ];
  const report = {
    lessonFileCount: files.length,
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

async function main(): Promise<void> {
  const report = await checkLessonOriginality();
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error: unknown) => {
    if (error instanceof LessonOriginalityError) {
      for (const issue of error.report.issues) {
        console.error(`${issue.filePath}: reuses numeric token(s) ${issue.questionTokens.join(", ")} with correct answer token(s) ${issue.answerTokens.join(", ")} from ${issue.questionId}`);
      }
      process.exitCode = 1;
      return;
    }
    const message = error instanceof Error ? error.message : String(error);
    console.error(`check-lesson-originality: ${message}`);
    process.exitCode = 1;
  });
}
