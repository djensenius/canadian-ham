import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { ACTIVE_GENERATED_DIR } from "./active-bank.ts";
import { isMainModule } from "./cli.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_QUESTION_PATH = path.join(REPO_ROOT, ACTIVE_GENERATED_DIR, "questions.json");
const DEFAULT_QUIZ_ROOT = path.join(REPO_ROOT, "content/quizzes");
// Tuned on the accepted M4/M5/M6 lesson quizzes to catch near-restatements
// without flagging ordinary same-topic vocabulary.
const CONCEPT_OVERLAP_JACCARD_THRESHOLD = 0.88;
const CONCEPT_OVERLAP_SHARED_FIVE_GRAM_THRESHOLD = 4;
const CONCEPT_OVERLAP_SHARED_FIVE_GRAM_WITH_JACCARD_THRESHOLD = 0.82;
const CONCEPT_OVERLAP_NGRAM_SIZE = 5;

const CONTENT_STOP_WORDS = new Set([
  "a",
  "about",
  "above",
  "after",
  "again",
  "against",
  "all",
  "also",
  "am",
  "an",
  "and",
  "any",
  "are",
  "as",
  "at",
  "be",
  "because",
  "been",
  "before",
  "being",
  "below",
  "between",
  "both",
  "but",
  "by",
  "can",
  "cannot",
  "could",
  "did",
  "do",
  "does",
  "doing",
  "down",
  "during",
  "each",
  "for",
  "from",
  "had",
  "has",
  "have",
  "having",
  "how",
  "if",
  "in",
  "into",
  "is",
  "it",
  "its",
  "may",
  "more",
  "most",
  "must",
  "no",
  "not",
  "of",
  "off",
  "on",
  "once",
  "one",
  "only",
  "or",
  "other",
  "out",
  "over",
  "own",
  "same",
  "should",
  "so",
  "some",
  "such",
  "than",
  "that",
  "the",
  "their",
  "then",
  "there",
  "these",
  "this",
  "those",
  "through",
  "to",
  "too",
  "under",
  "up",
  "use",
  "used",
  "using",
  "very",
  "was",
  "we",
  "were",
  "what",
  "when",
  "where",
  "which",
  "while",
  "who",
  "why",
  "will",
  "with",
  "would",
  "you",
  "your",
]);

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

type AnswerRecord = {
  isCorrect: boolean;
  text: LocalizedText;
};

type QuestionRecord = {
  id: string;
  subsectionId: string;
  text: LocalizedText;
  answers: AnswerRecord[];
};

type LessonRecord = {
  id: string;
  moduleId: string | null;
  covers: string[];
  quizIds: string[];
  tryItLines: string[];
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
  return isRecord(value) && isNonEmptyString(value.en) && (value.fr === null || isNonEmptyString(value.fr));
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

function stripMarkdownListMarker(line: string): string {
  return line.trim().replace(/^(?:[-*+]\s+|\d+[.)]\s+)/, "").trim();
}

function extractTryItLines(markdown: string): string[] {
  const lines = markdown.split("\n");
  const tryItLines: string[] = [];
  let inTryIt = false;
  for (const line of lines) {
    if (/^##\s+Try it\s*$/i.test(line.trim())) {
      inTryIt = true;
      continue;
    }
    if (inTryIt && /^#{1,2}\s+/.test(line.trim())) {
      inTryIt = false;
    }
    if (!inTryIt) {
      continue;
    }
    const stripped = stripMarkdownListMarker(line);
    if (stripped.length > 0) {
      tryItLines.push(stripped);
    }
  }
  return tryItLines;
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
    moduleId: parseFrontMatterString(frontMatter, "moduleId"),
    covers: parseFrontMatterArray(frontMatter, "covers"),
    quizIds: parseFrontMatterArray(frontMatter, "quizIds"),
    tryItLines: extractTryItLines(markdown),
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

async function loadLessons(lessonRoot: string, issues: string[]): Promise<Map<string, LessonRecord>> {
  const lessons = new Map<string, LessonRecord>();
  for (const filePath of await findMarkdownFiles(lessonRoot)) {
    const markdown = await readFile(filePath, "utf8");
    const lesson = parseLessonFrontMatter(markdown, filePath);
    if (lesson !== null) {
      const previousLesson = lessons.get(lesson.id);
      if (previousLesson !== undefined) {
        issues.push(`${filePath}: duplicate lesson id ${lesson.id}; first seen in ${previousLesson.filePath}`);
        continue;
      }
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
  for (const [index, item] of raw.entries()) {
    if (!isRecord(item) || !isNonEmptyString(item.id) || !isNonEmptyString(item.subsectionId) || !hasLocalizedText(item.text) || !Array.isArray(item.answers)) {
      throw new Error(`${questionsPath}: question record ${index} has an invalid shape`);
    }
    const answers: AnswerRecord[] = [];
    for (const [answerIndex, answer] of item.answers.entries()) {
      if (!isRecord(answer) || typeof answer.isCorrect !== "boolean" || !hasLocalizedText(answer.text)) {
        throw new Error(`${questionsPath}: ${item.id} answer ${answerIndex} has an invalid shape`);
      }
      answers.push({ isCorrect: answer.isCorrect, text: answer.text });
    }
    questions.set(item.id, { id: item.id, subsectionId: item.subsectionId, text: item.text, answers });
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
      issues.push(`${checkPath}: prompt must have non-empty en text and fr:null or non-empty fr text`);
    }
    if (!hasLocalizedText(check.explanation)) {
      issues.push(`${checkPath}: explanation must have non-empty en text and fr:null or non-empty fr text`);
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
        issues.push(`${choicePath}: text must have non-empty en text and fr:null or non-empty fr text`);
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

async function readQuizFiles(quizRoot: string): Promise<Array<{ filePath: string; quiz: unknown }>> {
  const entries = await readdir(quizRoot, { withFileTypes: true });
  const files: Array<{ filePath: string; quiz: unknown }> = [];
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    if (!entry.isFile() || !entry.name.endsWith(".json")) {
      continue;
    }
    const filePath = path.join(quizRoot, entry.name);
    files.push({ filePath, quiz: JSON.parse(await readFile(filePath, "utf8")) as unknown });
  }
  return files;
}

function isModuleLessonRoot(lessonRoot: string): boolean {
  return /^m\d+-/i.test(path.basename(path.resolve(lessonRoot)));
}

function moduleQuizPrefixFromLessonRoot(lessonRoot: string, lessons: Iterable<LessonRecord>): string | null {
  const rootMatch = path.basename(path.resolve(lessonRoot)).match(/^m(\d+)-/i);
  if (rootMatch !== null) {
    return `QZ-L-${rootMatch[1]!.padStart(3, "0")}-`;
  }
  for (const lesson of lessons) {
    const lessonMatch = lesson.id.match(/^L-(\d{3})-/);
    if (lessonMatch !== null) {
      return `QZ-L-${lessonMatch[1]}-`;
    }
    const moduleMatch = lesson.moduleId === null ? null : lesson.moduleId.match(/^M(\d+)$/i);
    if (moduleMatch !== null) {
      return `QZ-L-${moduleMatch[1]!.padStart(3, "0")}-`;
    }
  }
  return null;
}

function addMapValue(map: Map<string, string[]>, key: string, value: string): void {
  const existing = map.get(key);
  if (existing === undefined) {
    map.set(key, [value]);
    return;
  }
  existing.push(value);
}

function duplicateValues(values: string[]): string[] {
  const seen = new Set<string>();
  const duplicates = new Set<string>();
  for (const value of values) {
    if (seen.has(value)) {
      duplicates.add(value);
    }
    seen.add(value);
  }
  return [...duplicates].sort();
}

function normalizedText(value: string): string {
  return value
    .toLocaleLowerCase("en-CA")
    .normalize("NFKC")
    .replace(/[“”]/g, '"')
    .replace(/[‘’]/g, "'")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim()
    .replace(/\s+/g, " ");
}

function contentTokens(value: string): string[] {
  const normalized = normalizedText(value);
  if (normalized.length === 0) {
    return [];
  }
  return normalized
    .split(" ")
    .filter((token) => token.length > 1 && !CONTENT_STOP_WORDS.has(token));
}

function nGrams(tokens: string[], size: number): Set<string> {
  const grams = new Set<string>();
  for (let index = 0; index <= tokens.length - size; index += 1) {
    grams.add(tokens.slice(index, index + size).join(" "));
  }
  return grams;
}

function jaccard(left: Set<string>, right: Set<string>): number {
  if (left.size === 0 && right.size === 0) {
    return 0;
  }
  let intersectionSize = 0;
  for (const value of left) {
    if (right.has(value)) {
      intersectionSize += 1;
    }
  }
  return intersectionSize / (left.size + right.size - intersectionSize);
}

function overlapMetrics(leftText: string, rightText: string): { jaccard: number; sharedFiveGrams: number } {
  const leftTokens = contentTokens(leftText);
  const rightTokens = contentTokens(rightText);
  const leftTokenSet = new Set(leftTokens);
  const rightTokenSet = new Set(rightTokens);
  const leftFiveGrams = nGrams(leftTokens, CONCEPT_OVERLAP_NGRAM_SIZE);
  const rightFiveGrams = nGrams(rightTokens, CONCEPT_OVERLAP_NGRAM_SIZE);
  let sharedFiveGrams = 0;
  for (const gram of leftFiveGrams) {
    if (rightFiveGrams.has(gram)) {
      sharedFiveGrams += 1;
    }
  }
  return { jaccard: jaccard(leftTokenSet, rightTokenSet), sharedFiveGrams };
}

function conceptCheckText(check: ConceptCheck): string {
  const correctChoice = check.choices.find((choice) => choice.isCorrect);
  return `${check.prompt.en} ${correctChoice?.text.en ?? ""}`;
}

function officialQuestionText(question: QuestionRecord): string | null {
  const correctAnswer = question.answers.find((answer) => answer.isCorrect);
  if (correctAnswer === undefined) {
    return null;
  }
  return `${question.text.en} ${correctAnswer.text.en}`;
}

function conceptOverlapIsFlagged(metrics: { jaccard: number; sharedFiveGrams: number }): boolean {
  return metrics.jaccard >= CONCEPT_OVERLAP_JACCARD_THRESHOLD
    || metrics.sharedFiveGrams >= CONCEPT_OVERLAP_SHARED_FIVE_GRAM_THRESHOLD
    || (metrics.sharedFiveGrams >= 1 && metrics.jaccard >= CONCEPT_OVERLAP_SHARED_FIVE_GRAM_WITH_JACCARD_THRESHOLD);
}

function formatMetric(value: number): string {
  return value.toFixed(2);
}

export async function checkQuizzes(options: QuizCheckOptions = {}): Promise<QuizCheckReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTION_PATH;
  const quizRoot = options.quizRoot ?? DEFAULT_QUIZ_ROOT;
  const issues: string[] = [];
  const lessons = await loadLessons(lessonRoot, issues);
  const questions = await loadQuestions(questionsPath);
  const quizIdsReferencedByLessons = new Map<string, string[]>();
  for (const lesson of lessons.values()) {
    for (const quizId of lesson.quizIds) {
      addMapValue(quizIdsReferencedByLessons, quizId, lesson.id);
    }
    for (const duplicateQuizId of duplicateValues(lesson.quizIds)) {
      issues.push(`${lesson.filePath}: duplicate quizId ${duplicateQuizId}`);
    }
  }
  for (const [quizId, lessonIds] of quizIdsReferencedByLessons) {
    const uniqueLessonIds = [...new Set(lessonIds)];
    if (uniqueLessonIds.length > 1) {
      issues.push(`duplicate quizId ${quizId} is referenced by lessons ${uniqueLessonIds.join(", ")}`);
    }
  }
  const scopedToModuleRoot = isModuleLessonRoot(lessonRoot);
  const scopedQuizPrefix = scopedToModuleRoot ? moduleQuizPrefixFromLessonRoot(lessonRoot, lessons.values()) : null;

  let quizFileCount = 0;
  let officialQuestionCount = 0;
  let conceptCheckCount = 0;
  const seenQuizIds = new Map<string, string>();
  const seenQuizFileBasenames = new Set<string>();
  const seenConceptCheckIds = new Map<string, string>();
  const seenOfficialQuestionIds = new Map<string, string>();

  for (const { filePath, quiz: rawQuiz } of await readQuizFiles(quizRoot)) {
    const basenameId = path.basename(filePath, ".json");
    if (scopedToModuleRoot && !quizIdsReferencedByLessons.has(basenameId) && (scopedQuizPrefix === null || !basenameId.startsWith(scopedQuizPrefix))) {
      continue;
    }
    quizFileCount += 1;
    seenQuizFileBasenames.add(basenameId);
    const quiz = validateQuizShape(rawQuiz, filePath, issues);
    if (quiz === null) {
      continue;
    }
    const previousQuizFile = seenQuizIds.get(quiz.id);
    if (previousQuizFile !== undefined) {
      issues.push(`${filePath}: duplicate quiz id ${quiz.id}; first seen in ${previousQuizFile}`);
    } else {
      seenQuizIds.set(quiz.id, filePath);
    }
    if (quiz.id !== basenameId) {
      issues.push(`${filePath}: id must match file name ${basenameId}`);
    }

    for (const duplicateQuestionId of duplicateValues(quiz.officialQuestionIds)) {
      issues.push(`${filePath}: duplicate official question id ${duplicateQuestionId}`);
    }
    for (const duplicateConceptCheckId of duplicateValues(quiz.conceptChecks.map((check) => check.id))) {
      issues.push(`${filePath}: duplicate concept-check id ${duplicateConceptCheckId}`);
    }

    const lesson = lessons.get(quiz.lessonId);
    if (lesson === undefined) {
      issues.push(`${filePath}: unknown lessonId ${quiz.lessonId}`);
    }

    const expectedLessonIds = quizIdsReferencedByLessons.get(quiz.id) ?? [];
    if (expectedLessonIds.length === 0) {
      issues.push(`${filePath}: quiz id ${quiz.id} is not referenced by any lesson front matter`);
    } else if (!expectedLessonIds.includes(quiz.lessonId)) {
      issues.push(`${filePath}: quiz id ${quiz.id} is referenced by ${[...new Set(expectedLessonIds)].join(", ")}, not ${quiz.lessonId}`);
    }

    const uniqueOfficialQuestionIds = [...new Set(quiz.officialQuestionIds)];
    for (const questionId of uniqueOfficialQuestionIds) {
      const previousQuestionFile = seenOfficialQuestionIds.get(questionId);
      if (previousQuestionFile !== undefined) {
        issues.push(`${filePath}: duplicate official question id ${questionId}; first seen in ${previousQuestionFile}`);
      } else {
        seenOfficialQuestionIds.set(questionId, filePath);
      }
      const question = questions.get(questionId);
      if (question === undefined) {
        issues.push(`${filePath}: unknown official question id ${questionId}`);
        continue;
      }
      if (lesson !== undefined && !lesson.covers.includes(question.subsectionId)) {
        issues.push(`${filePath}: ${questionId} belongs to ${question.subsectionId}, which is not covered by ${quiz.lessonId}`);
      }
    }

    for (const check of quiz.conceptChecks) {
      const previousCheckFile = seenConceptCheckIds.get(check.id);
      if (previousCheckFile !== undefined) {
        issues.push(`${filePath}: duplicate concept-check id ${check.id}; first seen in ${previousCheckFile}`);
      } else {
        seenConceptCheckIds.set(check.id, filePath);
      }
    }

    for (const check of quiz.conceptChecks) {
      const checkText = conceptCheckText(check);
      for (const questionId of uniqueOfficialQuestionIds) {
        const question = questions.get(questionId);
        if (question === undefined) {
          continue;
        }
        const sourceText = officialQuestionText(question);
        if (sourceText === null) {
          continue;
        }
        const metrics = overlapMetrics(checkText, sourceText);
        if (conceptOverlapIsFlagged(metrics)) {
          issues.push(`${filePath}: CONCEPT-CHECK OVERLAP ${check.id} is too close to official question ${questionId} in the same quiz (Jaccard ${formatMetric(metrics.jaccard)}, shared ${CONCEPT_OVERLAP_NGRAM_SIZE}-grams ${metrics.sharedFiveGrams})`);
        }
      }
      if (lesson !== undefined) {
        for (const [lineIndex, tryItLine] of lesson.tryItLines.entries()) {
          const metrics = overlapMetrics(checkText, tryItLine);
          if (conceptOverlapIsFlagged(metrics)) {
            issues.push(`${filePath}: CONCEPT-CHECK OVERLAP ${check.id} is too close to ${lesson.id} Try-it line ${lineIndex + 1} (Jaccard ${formatMetric(metrics.jaccard)}, shared ${CONCEPT_OVERLAP_NGRAM_SIZE}-grams ${metrics.sharedFiveGrams})`);
          }
        }
      }
    }

    officialQuestionCount += quiz.officialQuestionIds.length;
    conceptCheckCount += quiz.conceptChecks.length;
  }

  for (const [quizId, lessonIds] of quizIdsReferencedByLessons) {
    if (!seenQuizIds.has(quizId) && !seenQuizFileBasenames.has(quizId)) {
      issues.push(`missing quiz file for ${quizId} referenced by ${[...new Set(lessonIds)].join(", ")}`);
    }
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

function lessonRootFromArgs(args: string[]): string | undefined {
  const rootArg = args.find((arg) => arg.startsWith("--lesson-root="));
  if (rootArg !== undefined) {
    return path.resolve(rootArg.slice("--lesson-root=".length));
  }
  const positional = args.find((arg) => !arg.startsWith("--"));
  return positional === undefined ? undefined : path.resolve(positional);
}

async function main(): Promise<void> {
  const report = await checkQuizzes({ lessonRoot: lessonRootFromArgs(process.argv.slice(2)) });
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (isMainModule(import.meta)) {
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
