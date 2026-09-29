import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_QUESTION_PATH = path.join(REPO_ROOT, "content/generated/basic-2025-07-15/questions.json");
const DEFAULT_QUIZ_ROOT = path.join(REPO_ROOT, "content/quizzes");

type LocalizedText = {
  en: string;
  fr: string | null;
};

type QuizChoice = {
  text: LocalizedText;
  isCorrect: boolean;
};

type ConceptCheck = {
  id: string;
  prompt: LocalizedText;
  choices: QuizChoice[];
  explanation: LocalizedText;
};

type LessonQuiz = {
  id: string;
  lessonId: string;
  officialQuestionIds: string[];
  conceptChecks: ConceptCheck[];
};

type QuestionRecord = {
  id: string;
  subsectionId: string;
};

type LessonRecord = {
  id: string;
  covers: string[];
  quizIds: string[];
  filePath: string;
};

export type QuizCheckOptions = {
  lessonRoot?: string;
  questionsPath?: string;
  quizRoot?: string;
};

export type QuizCheckReport = {
  quizFileCount: number;
  officialQuestionCount: number;
  conceptCheckCount: number;
  issues: string[];
  summaryLines: string[];
};

export class QuizCheckError extends Error {
  report: QuizCheckReport;

  constructor(report: QuizCheckReport) {
    super("lesson quiz check failed");
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
  return isRecord(value) && isNonEmptyString(value.en) && value.fr === null;
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

function parseFrontMatterString(frontMatter: string, key: string): string | null {
  const match = frontMatter.match(new RegExp(`^${key}:\\s*(.+)$`, "m"));
  return match ? parseYamlString(match[1]!) : null;
}

function parseLessonFrontMatter(markdown: string, filePath: string): LessonRecord | null {
  if (!markdown.startsWith("---\n")) {
    return null;
  }
  const closeIndex = markdown.indexOf("\n---", 4);
  if (closeIndex === -1) {
    return null;
  }
  const frontMatter = markdown.slice(4, closeIndex);
  if (parseFrontMatterString(frontMatter, "type") !== "lesson") {
    return null;
  }
  const id = parseFrontMatterString(frontMatter, "id");
  if (!isNonEmptyString(id)) {
    return null;
  }
  return {
    id,
    covers: parseFrontMatterArray(frontMatter, "covers"),
    quizIds: parseFrontMatterArray(frontMatter, "quizIds"),
    filePath,
  };
}

async function findMarkdownFiles(root: string, current = root): Promise<string[]> {
  const entries = await readdir(current, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(current, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findMarkdownFiles(root, entryPath));
    } else if (entry.isFile() && entry.name.endsWith(".md")) {
      files.push(entryPath);
    }
  }
  return files.sort();
}

async function loadLessons(lessonRoot: string): Promise<Map<string, LessonRecord>> {
  const lessons = new Map<string, LessonRecord>();
  for (const filePath of await findMarkdownFiles(lessonRoot)) {
    const markdown = await readFile(filePath, "utf8");
    const lesson = parseLessonFrontMatter(markdown, filePath);
    if (lesson !== null) {
      lessons.set(lesson.id, lesson);
    }
  }
  return lessons;
}

async function loadQuestions(questionsPath: string): Promise<Map<string, QuestionRecord>> {
  const raw: unknown = JSON.parse(await readFile(questionsPath, "utf8"));
  if (!Array.isArray(raw)) {
    throw new Error(`${questionsPath}: expected an array of question records`);
  }
  const questions = new Map<string, QuestionRecord>();
  for (const item of raw) {
    if (isRecord(item) && isNonEmptyString(item.id) && isNonEmptyString(item.subsectionId)) {
      questions.set(item.id, { id: item.id, subsectionId: item.subsectionId });
    }
  }
  return questions;
}

function validateQuizShape(value: unknown, filePath: string, issues: string[]): LessonQuiz | null {
  if (!isRecord(value)) {
    issues.push(`${filePath}: quiz file must contain a JSON object`);
    return null;
  }
  const id = value.id;
  const lessonId = value.lessonId;
  const officialQuestionIds = value.officialQuestionIds;
  const conceptChecks = value.conceptChecks;
  if (!isNonEmptyString(id)) {
    issues.push(`${filePath}: id must be a non-empty string`);
  }
  if (!isNonEmptyString(lessonId)) {
    issues.push(`${filePath}: lessonId must be a non-empty string`);
  }
  if (!Array.isArray(officialQuestionIds) || officialQuestionIds.some((questionId) => !isNonEmptyString(questionId))) {
    issues.push(`${filePath}: officialQuestionIds must be an array of non-empty strings`);
  }
  if (!Array.isArray(conceptChecks)) {
    issues.push(`${filePath}: conceptChecks must be an array`);
  }
  if (!isNonEmptyString(id) || !isNonEmptyString(lessonId) || !Array.isArray(officialQuestionIds) || !Array.isArray(conceptChecks)) {
    return null;
  }

  const checks: ConceptCheck[] = [];
  for (const [index, check] of conceptChecks.entries()) {
    const checkPath = `${filePath}: conceptChecks[${index}]`;
    if (!isRecord(check)) {
      issues.push(`${checkPath}: must be an object`);
      continue;
    }
    if (!isNonEmptyString(check.id)) {
      issues.push(`${checkPath}: id must be a non-empty string`);
    }
    if (!hasLocalizedText(check.prompt)) {
      issues.push(`${checkPath}: prompt must have non-empty en text and fr:null`);
    }
    if (!hasLocalizedText(check.explanation)) {
      issues.push(`${checkPath}: explanation must have non-empty en text and fr:null`);
    }
    if (!Array.isArray(check.choices) || check.choices.length < 2) {
      issues.push(`${checkPath}: choices must contain at least two choices`);
      continue;
    }
    let correctCount = 0;
    const choices: QuizChoice[] = [];
    for (const [choiceIndex, choice] of check.choices.entries()) {
      const choicePath = `${checkPath}.choices[${choiceIndex}]`;
      if (!isRecord(choice)) {
        issues.push(`${choicePath}: must be an object`);
        continue;
      }
      if (!hasLocalizedText(choice.text)) {
        issues.push(`${choicePath}: text must have non-empty en text and fr:null`);
      }
      if (typeof choice.isCorrect !== "boolean") {
        issues.push(`${choicePath}: isCorrect must be boolean`);
      } else if (choice.isCorrect) {
        correctCount += 1;
      }
      if (hasLocalizedText(choice.text) && typeof choice.isCorrect === "boolean") {
        choices.push({ text: choice.text, isCorrect: choice.isCorrect });
      }
    }
    if (correctCount !== 1) {
      issues.push(`${checkPath}: exactly one choice must have isCorrect true`);
    }
    if (isNonEmptyString(check.id) && hasLocalizedText(check.prompt) && hasLocalizedText(check.explanation) && choices.length === check.choices.length && correctCount === 1) {
      checks.push({ id: check.id, prompt: check.prompt, choices, explanation: check.explanation });
    }
  }

  return {
    id,
    lessonId,
    officialQuestionIds: officialQuestionIds.filter(isNonEmptyString),
    conceptChecks: checks,
  };
}

async function readQuizFiles(quizRoot: string): Promise<Array<{ filePath: string; quiz: LessonQuiz | null }>> {
  const entries = await readdir(quizRoot, { withFileTypes: true });
  const issues: Array<{ filePath: string; quiz: LessonQuiz | null }> = [];
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    if (!entry.isFile() || !entry.name.endsWith(".json")) {
      continue;
    }
    const filePath = path.join(quizRoot, entry.name);
    issues.push({ filePath, quiz: JSON.parse(await readFile(filePath, "utf8")) as unknown as LessonQuiz });
  }
  return issues;
}

export async function checkQuizzes(options: QuizCheckOptions = {}): Promise<QuizCheckReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTION_PATH;
  const quizRoot = options.quizRoot ?? DEFAULT_QUIZ_ROOT;
  const lessons = await loadLessons(lessonRoot);
  const questions = await loadQuestions(questionsPath);
  const issues: string[] = [];
  const quizIdsReferencedByLessons = new Map<string, string>();
  for (const lesson of lessons.values()) {
    for (const quizId of lesson.quizIds) {
      quizIdsReferencedByLessons.set(quizId, lesson.id);
    }
  }

  let quizFileCount = 0;
  let officialQuestionCount = 0;
  let conceptCheckCount = 0;
  const seenQuizIds = new Set<string>();

  for (const { filePath, quiz: rawQuiz } of await readQuizFiles(quizRoot)) {
    quizFileCount += 1;
    const basenameId = path.basename(filePath, ".json");
    const quiz = validateQuizShape(rawQuiz, filePath, issues);
    if (quiz === null) {
      continue;
    }
    seenQuizIds.add(quiz.id);
    if (quiz.id !== basenameId) {
      issues.push(`${filePath}: id must match file name ${basenameId}`);
    }
    const lesson = lessons.get(quiz.lessonId);
    if (lesson === undefined) {
      issues.push(`${filePath}: unknown lessonId ${quiz.lessonId}`);
    } else {
      const expectedLessonId = quizIdsReferencedByLessons.get(quiz.id);
      if (expectedLessonId === undefined) {
        issues.push(`${filePath}: quiz id ${quiz.id} is not referenced by any lesson front matter`);
      } else if (expectedLessonId !== quiz.lessonId) {
        issues.push(`${filePath}: quiz id ${quiz.id} is referenced by ${expectedLessonId}, not ${quiz.lessonId}`);
      }
      for (const questionId of quiz.officialQuestionIds) {
        const question = questions.get(questionId);
        if (question === undefined) {
          issues.push(`${filePath}: unknown official question id ${questionId}`);
          continue;
        }
        if (!lesson.covers.includes(question.subsectionId)) {
          issues.push(`${filePath}: ${questionId} belongs to ${question.subsectionId}, which is not covered by ${quiz.lessonId}`);
        }
      }
    }
    officialQuestionCount += quiz.officialQuestionIds.length;
    conceptCheckCount += quiz.conceptChecks.length;
  }

  const summaryLines = [
    `Quiz files verified: ${quizFileCount}`,
    `Official question references verified: ${officialQuestionCount}`,
    `Concept checks verified: ${conceptCheckCount}`,
  ];
  const report = { quizFileCount, officialQuestionCount, conceptCheckCount, issues, summaryLines };
  if (issues.length > 0) {
    throw new QuizCheckError(report);
  }
  return report;
}

async function main(): Promise<void> {
  const report = await checkQuizzes();
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error: unknown) => {
    if (error instanceof QuizCheckError) {
      for (const issue of error.report.issues) {
        console.error(issue);
      }
      process.exitCode = 1;
      return;
    }
    const message = error instanceof Error ? error.message : String(error);
    console.error(`check-quizzes: ${message}`);
    process.exitCode = 1;
  });
}
