import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_EXPLANATION_ROOT = path.join(REPO_ROOT, "content/explanations");
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_QUESTION_PATH = path.join(REPO_ROOT, "content/generated/basic-2025-07-15/questions.json");
const EXPECTED_BANK_ID = "basic-2025-07-15";
const NOTE_DUPLICATE_FILE_LIMIT = 3;
const SHORT_PREFIX_MIN_LENGTH = 12;
// A repeated 6-word run across four different questions is long enough to catch
// rotating template openers while allowing normal repeated technical vocabulary.
const TEMPLATE_GRAM_SIZE = 6;
const TEMPLATE_DIFFERENT_QUESTION_LIMIT = 4;
const DISTRACTOR_NOTE_HEADER = "Why the distractors are wrong:";
const DEFAULT_TEMPLATE_ALLOWLIST_PATH = path.join(REPO_ROOT, "packages/content-tools/explanation-template-allowlist.json");
const ALLOWED_CITATION_URL_HOSTS = new Set(["ised-isde.canada.ca", "www.ised-isde.canada.ca"]);

const GENERIC_NOTE_PHRASES = [
  "does not match the principle tested here",
  "not the construction parameter being asked",
  "main effect being tested",
];

type LocalizedText = {
  en: string;
  fr: string | null;
};

type AnswerRecord = {
  sourceIndex: number;
  isCorrect: boolean;
  text: LocalizedText;
};

type QuestionRecord = {
  id: string;
  bankId: string;
  categoryId: string;
  subsectionId: string;
  answers: AnswerRecord[];
};

type CitationRecord = {
  type: string;
  id?: string;
  url?: string;
};

type ExplanationRecord = {
  id: string;
  questionId: string;
  bankId: string;
  status: string;
  body: LocalizedText;
  citations: CitationRecord[];
  licenseClass: string;
};

type LessonRecord = {
  id: string;
  covers: string[];
  filePath: string;
};

type PerChoiceNote = {
  sourceIndex: number;
  quotedChoice: string;
  body: string;
  lineNumber: number;
};

type TemplateAllowlist = {
  categorySpecific: Map<string, Set<string>>;
  global: Set<string>;
};

type TemplateGramOccurrence = {
  questionId: string;
  location: string;
};

export type ExplanationCheckOptions = {
  explanationRoot?: string;
  questionsPath?: string;
  lessonRoot?: string;
  categoryId?: string;
  moduleId?: string;
  templateAllowlistPath?: string;
};

export type ExplanationCheckReport = {
  explanationFileCount: number;
  explanationQuestionCount: number;
  perChoiceNoteCount: number;
  explainedQuestionCount: number;
  totalQuestionCount: number;
  issues: string[];
  summaryLines: string[];
};

export class ExplanationCheckError extends Error {
  report: ExplanationCheckReport;

  constructor(report: ExplanationCheckReport) {
    super("explanation check failed");
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
  return { id, covers: parseFrontMatterArray(frontMatter, "covers"), filePath };
}

async function findFiles(root: string, extension: string, current = root): Promise<string[]> {
  const entries = await readdir(current, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(current, entry.name);
    if (entry.isDirectory()) {
      files.push(...await findFiles(root, extension, entryPath));
    } else if (entry.isFile() && entry.name.endsWith(extension)) {
      files.push(entryPath);
    }
  }
  return files.sort();
}

async function loadLessons(lessonRoot: string, issues: string[]): Promise<Map<string, LessonRecord>> {
  const lessons = new Map<string, LessonRecord>();
  for (const filePath of await findFiles(lessonRoot, ".md")) {
    const markdown = await readFile(filePath, "utf8");
    const lesson = parseLessonFrontMatter(markdown, filePath);
    if (lesson === null) {
      continue;
    }
    const previousLesson = lessons.get(lesson.id);
    if (previousLesson !== undefined) {
      issues.push(`${filePath}: duplicate lesson id ${lesson.id}; first seen in ${previousLesson.filePath}`);
      continue;
    }
    lessons.set(lesson.id, lesson);
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
    if (!isRecord(item) || !isNonEmptyString(item.id) || !isNonEmptyString(item.bankId) || !isNonEmptyString(item.categoryId) || !isNonEmptyString(item.subsectionId) || !Array.isArray(item.answers)) {
      throw new Error(`${questionsPath}: question record ${index} has an invalid shape`);
    }
    const answers: AnswerRecord[] = [];
    for (const [answerIndex, answer] of item.answers.entries()) {
      if (!isRecord(answer) || typeof answer.sourceIndex !== "number" || !Number.isInteger(answer.sourceIndex) || typeof answer.isCorrect !== "boolean" || !hasLocalizedText(answer.text)) {
        throw new Error(`${questionsPath}: ${item.id} answer ${answerIndex} has an invalid shape`);
      }
      answers.push({ sourceIndex: answer.sourceIndex, isCorrect: answer.isCorrect, text: answer.text });
    }
    questions.set(item.id, { id: item.id, bankId: item.bankId, categoryId: item.categoryId, subsectionId: item.subsectionId, answers });
  }
  return questions;
}

function validateCitationUrl(url: string, citationPath: string, issues: string[]): void {
  let parsedUrl: URL;
  try {
    parsedUrl = new URL(url);
  } catch {
    issues.push(`${citationPath}: citation url must be an absolute https URL on ised-isde.canada.ca or www.ised-isde.canada.ca`);
    return;
  }
  if (parsedUrl.protocol !== "https:" || !ALLOWED_CITATION_URL_HOSTS.has(parsedUrl.host)) {
    issues.push(`${citationPath}: citation url must be an absolute https URL on ised-isde.canada.ca or www.ised-isde.canada.ca`);
  }
}

function validateCitation(value: unknown, citationPath: string, issues: string[]): CitationRecord | null {
  if (!isRecord(value)) {
    issues.push(`${citationPath}: citation must be an object`);
    return null;
  }
  if (!isNonEmptyString(value.type)) {
    issues.push(`${citationPath}: type must be a non-empty string`);
    return null;
  }
  if ((value.type === "lesson" || value.type === "question") && !isNonEmptyString(value.id)) {
    issues.push(`${citationPath}: ${value.type} citation id must be a non-empty string`);
  }
  if (value.url !== undefined && !isNonEmptyString(value.url)) {
    issues.push(`${citationPath}: citation url must be a non-empty string when present`);
  }
  if (value.type === "rbr-4" && !isNonEmptyString(value.url)) {
    issues.push(`${citationPath}: rbr-4 citation url must be a non-empty string`);
  }
  if (isNonEmptyString(value.url)) {
    validateCitationUrl(value.url, citationPath, issues);
  }
  return {
    type: value.type,
    ...(isNonEmptyString(value.id) ? { id: value.id } : {}),
    ...(isNonEmptyString(value.url) ? { url: value.url } : {}),
  };
}

function validateExplanationShape(value: unknown, filePath: string, issues: string[]): ExplanationRecord | null {
  if (!isRecord(value)) {
    issues.push(`${filePath}: explanation file must contain a JSON object`);
    return null;
  }
  const id = value.id;
  const questionId = value.questionId;
  const bankId = value.bankId;
  const status = value.status;
  const body = value.body;
  const citations = value.citations;
  const licenseClass = value.licenseClass;

  if (!isNonEmptyString(id)) {
    issues.push(`${filePath}: id must be a non-empty string`);
  }
  if (!isNonEmptyString(questionId)) {
    issues.push(`${filePath}: questionId must be a non-empty string`);
  }
  if (!isNonEmptyString(bankId)) {
    issues.push(`${filePath}: bankId must be a non-empty string`);
  }
  if (!isNonEmptyString(status)) {
    issues.push(`${filePath}: status must be a non-empty string`);
  }
  if (!hasLocalizedText(body)) {
    issues.push(`${filePath}: body must have non-empty en text and fr:null or non-empty fr text`);
  }
  if (!Array.isArray(citations)) {
    issues.push(`${filePath}: citations must be an array`);
  }
  if (!isNonEmptyString(licenseClass)) {
    issues.push(`${filePath}: licenseClass must be a non-empty string`);
  } else if (licenseClass !== "original") {
    issues.push(`${filePath}: licenseClass must be original`);
  }

  if (!isNonEmptyString(id) || !isNonEmptyString(questionId) || !isNonEmptyString(bankId) || !isNonEmptyString(status) || !hasLocalizedText(body) || !Array.isArray(citations) || !isNonEmptyString(licenseClass)) {
    return null;
  }

  if (id !== `EXP-${questionId}`) {
    issues.push(`${filePath}: id must be EXP-${questionId}`);
  }
  if (bankId !== EXPECTED_BANK_ID) {
    issues.push(`${filePath}: bankId must be ${EXPECTED_BANK_ID}`);
  }

  const parsedCitations: CitationRecord[] = [];
  for (const [index, citation] of citations.entries()) {
    const parsedCitation = validateCitation(citation, `${filePath}: citations[${index}]`, issues);
    if (parsedCitation !== null) {
      parsedCitations.push(parsedCitation);
    }
  }

  return { id, questionId, bankId, status, body, citations: parsedCitations, licenseClass };
}

function parseQuotedJsonString(raw: string): string | null {
  try {
    return JSON.parse(`"${raw}"`) as string;
  } catch {
    return null;
  }
}

function parsePerChoiceNotes(body: string, filePath: string, issues: string[]): PerChoiceNote[] {
  const notes: PerChoiceNote[] = [];
  const lines = body.split("\n");
  for (const [index, line] of lines.entries()) {
    if (!line.includes("sourceIndex")) {
      continue;
    }
    const match = line.match(/^\s*-\s*sourceIndex\s+(\d+):\s*"((?:\\.|[^"\\])*)":\s*(.*)$/u);
    if (match === null) {
      issues.push(`${filePath}:${index + 1}: per-choice note must use '- sourceIndex N: "choice text": note'`);
      continue;
    }
    const quotedChoice = parseQuotedJsonString(match[2]!);
    if (quotedChoice === null) {
      issues.push(`${filePath}:${index + 1}: quoted choice text is not a valid JSON string fragment`);
      continue;
    }
    notes.push({
      sourceIndex: Number(match[1]),
      quotedChoice,
      body: match[3]!.trim(),
      lineNumber: index + 1,
    });
  }
  return notes;
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

function wordTokens(value: string): string[] {
  const normalized = normalizedText(value);
  return normalized.length === 0 ? [] : normalized.split(" ");
}

function wordNGrams(tokens: string[], size: number): string[] {
  if (tokens.length < size) {
    return [];
  }
  const grams: string[] = [];
  for (let index = 0; index <= tokens.length - size; index += 1) {
    grams.push(tokens.slice(index, index + size).join(" "));
  }
  return grams;
}

function hasDistractorHeader(body: string): boolean {
  return body.split("\n").some((line) => line.trim() === DISTRACTOR_NOTE_HEADER);
}

async function loadTemplateAllowlist(filePath: string, issues: string[]): Promise<TemplateAllowlist> {
  const allowlist: TemplateAllowlist = { categorySpecific: new Map(), global: new Set() };
  let raw: unknown;
  try {
    raw = JSON.parse(await readFile(filePath, "utf8")) as unknown;
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    issues.push(`${filePath}: could not read TEMPLATE allow-list: ${message}`);
    return allowlist;
  }
  if (!isRecord(raw) || !Array.isArray(raw.word6Grams)) {
    issues.push(`${filePath}: TEMPLATE allow-list must be an object with a word6Grams array`);
    return allowlist;
  }
  for (const [index, entry] of raw.word6Grams.entries()) {
    const entryPath = `${filePath}: word6Grams[${index}]`;
    if (!isRecord(entry)) {
      issues.push(`${entryPath}: allow-list entry must be an object`);
      continue;
    }
    if (!(entry.categoryId === undefined || entry.categoryId === null || isNonEmptyString(entry.categoryId))) {
      issues.push(`${entryPath}: categoryId must be omitted, null, or a non-empty string`);
      continue;
    }
    if (!isNonEmptyString(entry.phrase)) {
      issues.push(`${entryPath}: phrase must be a non-empty string`);
      continue;
    }
    if (!isNonEmptyString(entry.reason)) {
      issues.push(`${entryPath}: reason must document why this repeated technical phrase is allowed`);
      continue;
    }
    const categoryId = isNonEmptyString(entry.categoryId) ? normalizeCategoryId(entry.categoryId) : null;
    if (isNonEmptyString(entry.categoryId) && categoryId === null) {
      issues.push(`${entryPath}: categoryId ${entry.categoryId} is not a valid B-00N or module id`);
      continue;
    }
    const grams = wordNGrams(wordTokens(entry.phrase), TEMPLATE_GRAM_SIZE);
    if (grams.length !== 1) {
      issues.push(`${entryPath}: phrase must normalize to exactly one ${TEMPLATE_GRAM_SIZE}-word phrase`);
      continue;
    }
    if (categoryId === null) {
      allowlist.global.add(grams[0]!);
    } else {
      const existing = allowlist.categorySpecific.get(categoryId) ?? new Set<string>();
      existing.add(grams[0]!);
      allowlist.categorySpecific.set(categoryId, existing);
    }
  }
  return allowlist;
}

function templateGramIsAllowed(allowlist: TemplateAllowlist, categoryId: string, gram: string): boolean {
  return allowlist.global.has(gram) || (allowlist.categorySpecific.get(categoryId)?.has(gram) ?? false);
}

function quotedChoiceMatches(quotedChoice: string, answerText: string): boolean {
  if (quotedChoice === answerText) {
    return true;
  }
  const ellipsisSuffix = quotedChoice.endsWith("…") ? "…" : quotedChoice.endsWith("...") ? "..." : null;
  if (ellipsisSuffix === null) {
    return false;
  }
  const prefix = quotedChoice.slice(0, -ellipsisSuffix.length).trimEnd();
  return prefix.length >= SHORT_PREFIX_MIN_LENGTH && answerText.startsWith(prefix);
}

function noteIsGeneric(noteBody: string): string | null {
  const normalized = normalizedText(noteBody);
  for (const phrase of GENERIC_NOTE_PHRASES) {
    if (normalized.includes(normalizedText(phrase))) {
      return phrase;
    }
  }
  return null;
}

function addMapValue(map: Map<string, Set<string>>, key: string, value: string): void {
  const existing = map.get(key);
  if (existing === undefined) {
    map.set(key, new Set([value]));
    return;
  }
  existing.add(value);
}

function normalizeCategoryId(raw: string): string | null {
  const trimmed = raw.trim().toUpperCase();
  const categoryMatch = trimmed.match(/^B-(\d{3})$/);
  if (categoryMatch !== null) {
    return `B-${categoryMatch[1]}`;
  }
  const numericMatch = trimmed.match(/^(?:M)?(\d{1,3})(?:\b|-.+)?$/);
  if (numericMatch !== null) {
    return `B-${numericMatch[1]!.padStart(3, "0")}`;
  }
  return null;
}

function filtersFromOptions(options: ExplanationCheckOptions): { categoryId: string | null } {
  const categoryFromCategory = options.categoryId === undefined ? null : normalizeCategoryId(options.categoryId);
  if (options.categoryId !== undefined && categoryFromCategory === null) {
    throw new Error(`invalid category filter ${options.categoryId}`);
  }
  const categoryFromModule = options.moduleId === undefined ? null : normalizeCategoryId(options.moduleId);
  if (options.moduleId !== undefined && categoryFromModule === null) {
    throw new Error(`invalid module filter ${options.moduleId}`);
  }
  if (categoryFromCategory !== null && categoryFromModule !== null && categoryFromCategory !== categoryFromModule) {
    throw new Error(`category filter ${categoryFromCategory} conflicts with module filter ${categoryFromModule}`);
  }
  return { categoryId: categoryFromCategory ?? categoryFromModule };
}

function fileMatchesFilter(explanationRoot: string, filePath: string, categoryId: string | null): boolean {
  if (categoryId === null) {
    return true;
  }
  const relativePath = path.relative(explanationRoot, filePath);
  const [categoryDirectory] = relativePath.split(path.sep);
  return categoryDirectory?.toUpperCase() === categoryId;
}

function recordMatchesFilter(record: ExplanationRecord, question: QuestionRecord | undefined, categoryId: string | null): boolean {
  if (categoryId === null) {
    return true;
  }
  const recordCategoryId = question?.categoryId ?? record.questionId.slice(0, 5).toUpperCase();
  return recordCategoryId === categoryId;
}

function addTemplateGramOccurrence(
  occurrences: Map<string, Map<string, TemplateGramOccurrence[]>>,
  categoryId: string,
  gram: string,
  occurrence: TemplateGramOccurrence,
): void {
  const categoryOccurrences = occurrences.get(categoryId) ?? new Map<string, TemplateGramOccurrence[]>();
  const gramOccurrences = categoryOccurrences.get(gram) ?? [];
  gramOccurrences.push(occurrence);
  categoryOccurrences.set(gram, gramOccurrences);
  occurrences.set(categoryId, categoryOccurrences);
}

export async function checkExplanations(options: ExplanationCheckOptions = {}): Promise<ExplanationCheckReport> {
  const explanationRoot = options.explanationRoot ?? DEFAULT_EXPLANATION_ROOT;
  const questionsPath = options.questionsPath ?? DEFAULT_QUESTION_PATH;
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const { categoryId } = filtersFromOptions(options);
  const issues: string[] = [];
  const templateAllowlist = await loadTemplateAllowlist(options.templateAllowlistPath ?? DEFAULT_TEMPLATE_ALLOWLIST_PATH, issues);
  const questions = await loadQuestions(questionsPath);
  const lessons = await loadLessons(lessonRoot, issues);
  const duplicateNoteFiles = new Map<string, Set<string>>();
  const templateGramOccurrences = new Map<string, Map<string, TemplateGramOccurrence[]>>();
  const explainedQuestionIds = new Set<string>();

  let explanationFileCount = 0;
  let explanationQuestionCount = 0;
  let perChoiceNoteCount = 0;

  for (const filePath of await findFiles(explanationRoot, ".json")) {
    if (!fileMatchesFilter(explanationRoot, filePath, categoryId)) {
      continue;
    }
    const raw: unknown = JSON.parse(await readFile(filePath, "utf8"));
    const record = validateExplanationShape(raw, filePath, issues);
    if (record === null) {
      explanationFileCount += 1;
      continue;
    }
    const question = questions.get(record.questionId);
    if (!recordMatchesFilter(record, question, categoryId)) {
      continue;
    }

    explanationFileCount += 1;
    explanationQuestionCount += 1;
    explainedQuestionIds.add(record.questionId);

    const expectedBasename = `${record.questionId.toLowerCase()}.json`;
    if (path.basename(filePath) !== expectedBasename) {
      issues.push(`${filePath}: file name must be ${expectedBasename}`);
    }

    if (question === undefined) {
      issues.push(`${filePath}: unknown questionId ${record.questionId}`);
    } else {
      if (record.bankId !== question.bankId) {
        issues.push(`${filePath}: bankId ${record.bankId} does not match question bank ${question.bankId}`);
      }
      const correctAnswers = question.answers.filter((answer) => answer.isCorrect);
      if (correctAnswers.length !== 1) {
        issues.push(`${filePath}: question ${question.id} must have exactly one correct answer in the bank`);
      } else if (correctAnswers[0]!.sourceIndex !== 0) {
        issues.push(`${filePath}: question ${question.id} correct sourceIndex is ${correctAnswers[0]!.sourceIndex}, expected 0`);
      }
    }

    if (!record.citations.some((citation) => citation.type === "question" && citation.id === record.questionId)) {
      issues.push(`${filePath}: citations must include question ${record.questionId}`);
    }

    const lessonCitations = record.citations.filter((citation) => citation.type === "lesson");
    if (lessonCitations.length === 0) {
      issues.push(`${filePath}: citations must include at least one lesson`);
    }
    let citedLessonCoversQuestion = false;
    for (const citation of lessonCitations) {
      if (!isNonEmptyString(citation.id)) {
        continue;
      }
      const lesson = lessons.get(citation.id);
      if (lesson === undefined) {
        issues.push(`${filePath}: unknown lesson citation ${citation.id}`);
        continue;
      }
      if (question !== undefined && lesson.covers.includes(question.subsectionId)) {
        citedLessonCoversQuestion = true;
      }
    }
    if (question !== undefined && lessonCitations.length > 0 && !citedLessonCoversQuestion) {
      issues.push(`${filePath}: no cited lesson covers ${question.subsectionId}`);
    }

    if (!hasDistractorHeader(record.body.en)) {
      issues.push(`${filePath}: body.en must include ${JSON.stringify(DISTRACTOR_NOTE_HEADER)} before distractor notes`);
    }
    const notes = parsePerChoiceNotes(record.body.en, filePath, issues);
    if (notes.length === 0) {
      issues.push(`${filePath}: body.en must include per-choice sourceIndex notes`);
    }
    const seenSourceIndexes = new Set<number>();
    for (const note of notes) {
      perChoiceNoteCount += 1;
      if (seenSourceIndexes.has(note.sourceIndex)) {
        issues.push(`${filePath}:${note.lineNumber}: duplicate per-choice note for sourceIndex ${note.sourceIndex}`);
      }
      seenSourceIndexes.add(note.sourceIndex);
      if (note.sourceIndex === 0) {
        issues.push(`${filePath}:${note.lineNumber}: sourceIndex 0 must not appear in the distractor notes`);
      }
      const answer = question?.answers.find((candidate) => candidate.sourceIndex === note.sourceIndex);
      if (answer === undefined) {
        issues.push(`${filePath}:${note.lineNumber}: sourceIndex ${note.sourceIndex} is not present on question ${record.questionId}`);
      } else if (!quotedChoiceMatches(note.quotedChoice, answer.text.en)) {
        issues.push(`${filePath}:${note.lineNumber}: quoted choice ${JSON.stringify(note.quotedChoice)} must match ${JSON.stringify(answer.text.en)} or a documented ellipsis prefix of it`);
      }
      if (note.body.length === 0) {
        issues.push(`${filePath}:${note.lineNumber}: per-choice note body must be non-empty`);
      }
      const genericPhrase = noteIsGeneric(note.body);
      if (genericPhrase !== null) {
        issues.push(`${filePath}:${note.lineNumber}: per-choice note body uses generic filler phrase ${JSON.stringify(genericPhrase)}`);
      }
      const normalizedNote = normalizedText(note.body);
      if (normalizedNote.length > 0) {
        addMapValue(duplicateNoteFiles, normalizedNote, filePath);
      }
      if (note.sourceIndex !== 0) {
        const noteCategoryId = question?.categoryId ?? record.questionId.slice(0, 5).toUpperCase();
        for (const gram of new Set(wordNGrams(wordTokens(note.body), TEMPLATE_GRAM_SIZE))) {
          addTemplateGramOccurrence(templateGramOccurrences, noteCategoryId, gram, {
            questionId: record.questionId,
            location: `${filePath}:${note.lineNumber}`,
          });
        }
      }
    }
    if (question !== undefined) {
      for (const answer of question.answers.filter((candidate) => !candidate.isCorrect).sort((left, right) => left.sourceIndex - right.sourceIndex)) {
        if (!seenSourceIndexes.has(answer.sourceIndex)) {
          issues.push(`${filePath}: missing per-choice note for distractor sourceIndex ${answer.sourceIndex}`);
        }
      }
    }
  }

  for (const [normalizedNote, filePaths] of [...duplicateNoteFiles].sort(([left], [right]) => left.localeCompare(right))) {
    if (filePaths.size >= NOTE_DUPLICATE_FILE_LIMIT) {
      issues.push(`DUPLICATE-NOTE: note body ${JSON.stringify(normalizedNote)} appears in ${filePaths.size} files: ${[...filePaths].sort().join(", ")}`);
    }
  }

  for (const [templateCategoryId, categoryOccurrences] of [...templateGramOccurrences].sort(([left], [right]) => left.localeCompare(right))) {
    for (const [gram, occurrences] of [...categoryOccurrences].sort(([left], [right]) => left.localeCompare(right))) {
      if (templateGramIsAllowed(templateAllowlist, templateCategoryId, gram)) {
        continue;
      }
      const questionIds = [...new Set(occurrences.map((occurrence) => occurrence.questionId))].sort();
      if (questionIds.length >= TEMPLATE_DIFFERENT_QUESTION_LIMIT) {
        const locations = occurrences
          .filter((occurrence, index, all) => all.findIndex((candidate) => candidate.questionId === occurrence.questionId) === index)
          .map((occurrence) => occurrence.location)
          .sort();
        issues.push(`TEMPLATE: category ${templateCategoryId} distractor-note ${TEMPLATE_GRAM_SIZE}-gram ${JSON.stringify(gram)} appears in ${questionIds.length} different questions (${questionIds.join(", ")}): ${locations.join(", ")}`);
      }
    }
  }

  const totalQuestionCount = categoryId === null ? questions.size : [...questions.values()].filter((question) => question.categoryId === categoryId).length;
  const summaryLines = [
    `Explanation files verified: ${explanationFileCount}`,
    `Explanation question references verified: ${explanationQuestionCount}`,
    `Per-choice notes verified: ${perChoiceNoteCount}`,
    `Question explanations present: ${explainedQuestionIds.size}/${totalQuestionCount}`,
  ];
  const report = { explanationFileCount, explanationQuestionCount, perChoiceNoteCount, explainedQuestionCount: explainedQuestionIds.size, totalQuestionCount, issues, summaryLines };
  if (issues.length > 0) {
    throw new ExplanationCheckError(report);
  }
  return report;
}

function optionValue(args: string[], name: string): string | undefined {
  const equalsArg = args.find((arg) => arg.startsWith(`${name}=`));
  if (equalsArg !== undefined) {
    return equalsArg.slice(name.length + 1);
  }
  const index = args.indexOf(name);
  if (index !== -1) {
    return args[index + 1];
  }
  return undefined;
}

function optionsFromArgs(args: string[]): ExplanationCheckOptions {
  return {
    categoryId: optionValue(args, "--category"),
    moduleId: optionValue(args, "--module"),
    templateAllowlistPath: optionValue(args, "--template-allowlist"),
  };
}

async function main(): Promise<void> {
  const report = await checkExplanations(optionsFromArgs(process.argv.slice(2)));
  for (const line of report.summaryLines) {
    console.log(line);
  }
}

if (fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error: unknown) => {
    if (error instanceof ExplanationCheckError) {
      for (const issue of error.report.issues) {
        console.error(issue);
      }
      process.exitCode = 1;
      return;
    }
    const message = error instanceof Error ? error.message : String(error);
    console.error(`check-explanations: ${message}`);
    process.exitCode = 1;
  });
}
