import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { TextDecoder } from "node:util";

export const BANK_ID = "basic-2025-07-15";
export const BANK_EFFECTIVE_DATE = "2025-07-15";
export const IMPORTER_VERSION = "1";

export const SOURCE_DIR = "content/sources/ised/basic-2025-07-15";
export const SOURCE_TXT_PATH = `${SOURCE_DIR}/questions/amat_basic_quest_delim.txt`;
export const SOURCE_MANIFEST_PATH = `${SOURCE_DIR}/manifest.json`;
export const SOURCE_SHA256SUMS_PATH = `${SOURCE_DIR}/SHA256SUMS`;
export const HAND_CATEGORIES_PATH = "content/categories.json";
export const DOCS_EXAM_FACTS_PATH = "docs/exam-facts.md";
export const GENERATED_DIR = `content/generated/${BANK_ID}`;

export const EXPECTED_HEADERS = [
  "question_id",
  "question_english",
  "correct_answer_english",
  "incorrect_answer_1_english",
  "incorrect_answer_2_english",
  "incorrect_answer_3_english",
  "question_french",
  "correct_answer_french",
  "incorrect_answer_1_french",
  "incorrect_answer_2_french",
  "incorrect_answer_3_french",
] as const;

const EXPECTED_CATEGORY_COUNTS = new Map([
  ["B-001", { questionCount: 199, subsectionCount: 25, examQuestionCount: 25 }],
  ["B-002", { questionCount: 99, subsectionCount: 9, examQuestionCount: 9 }],
  ["B-003", { questionCount: 199, subsectionCount: 21, examQuestionCount: 21 }],
  ["B-004", { questionCount: 63, subsectionCount: 6, examQuestionCount: 6 }],
  ["B-005", { questionCount: 142, subsectionCount: 13, examQuestionCount: 13 }],
  ["B-006", { questionCount: 140, subsectionCount: 13, examQuestionCount: 13 }],
  ["B-007", { questionCount: 87, subsectionCount: 8, examQuestionCount: 8 }],
  ["B-008", { questionCount: 55, subsectionCount: 5, examQuestionCount: 5 }],
]);

export const EXPECTED_PRIVILEGE_ANSWER_TEXT = new Map([
  ["B-001-004-001", "There are no age limits"],
  ["B-001-004-005", "5 wpm"],
  ["B-001-015-003", "You must attain a mark of 80% on the Basic examination, or pass an Advanced or Morse code examination"],
  ["B-001-017-002", "2250 watts"],
  ["B-001-017-004", "560 watts"],
  ["B-001-017-005", "560 watts"],
  ["B-001-017-007", "1000 watts"],
  ["B-001-017-009", "250 watts"],
  ["B-001-017-010", "190 watts"],
]);

const ID_PATTERN = /^B-\d{3}-\d{3}-\d{3}$/;
const POSITION_DEPENDENT_PATTERNS = [
  /all of the above/i,
  /none of the above/i,
  /all of these/i,
  /none of these/i,
  /both of the above/i,
  /answers? [A-D]/i,
  /\b[A-D] (?:and|or) [A-D]\b/i,
  /choices? [A-D]/i,
];

export interface SourceRow {
  readonly lineNumber: number;
  readonly sourceOrder: number;
  readonly fields: readonly string[];
}

export interface ParseResult {
  readonly header: readonly string[];
  readonly rows: readonly SourceRow[];
}

export interface Question {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly subsectionId: string;
  readonly sourceOrder: number;
  readonly text: {
    readonly en: string;
    readonly fr: string;
  };
  readonly answers: readonly Answer[];
}

export interface Answer {
  readonly sourceIndex: number;
  readonly isCorrect: boolean;
  readonly text: {
    readonly en: string;
    readonly fr: string;
  };
}

export interface Subsection {
  readonly id: string;
  readonly bankId: string;
  readonly categoryId: string;
  readonly questionIds: readonly string[];
  readonly questionCount: number;
  readonly lessonIds: readonly string[];
  readonly title: {
    readonly en: null;
    readonly fr: null;
  };
}

export interface HandCategory {
  readonly id: string;
  readonly name: {
    readonly en: string;
    readonly fr: null;
  };
  readonly frenchNameStatus: "pending verification";
  readonly expectedQuestionCount: number;
  readonly expectedSubsectionCount: number;
  readonly examQuestionCount: number;
  readonly nameSource: string;
}

export interface GeneratedCategory {
  readonly id: string;
  readonly bankId: string;
  readonly name: {
    readonly en: string;
    readonly fr: null;
  };
  readonly frenchNameStatus: "pending verification";
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly examQuestionCount: number;
  readonly nameSource: string;
}

export interface GeneratedManifest {
  readonly bankId: string;
  readonly certificate: string;
  readonly effectiveDate: string;
  readonly source: {
    readonly path: string;
    readonly sha256: string;
    readonly url: string;
    readonly encoding: "UTF-8";
    readonly lineEndings: "CRLF";
  };
  readonly importer: {
    readonly name: string;
    readonly version: string;
  };
  readonly counts: {
    readonly questions: number;
    readonly categories: number;
    readonly subsections: number;
  };
}

export interface ImportedBank {
  readonly questions: readonly Question[];
  readonly subsections: readonly Subsection[];
  readonly categories: readonly GeneratedCategory[];
  readonly manifest: GeneratedManifest;
}

export interface GeneratedFile {
  readonly path: string;
  readonly content: string;
}

interface SourceManifestFile {
  readonly path: string;
  readonly sourceUrl?: string;
  readonly sha256: string;
  readonly encoding?: string | null;
}

interface SourceManifest {
  readonly bankEffectiveDate?: string;
  readonly files: readonly SourceManifestFile[];
}

export interface PositionDependentIssue {
  readonly questionId: string;
  readonly sourceIndex: number;
  readonly language: "en" | "fr";
  readonly text: string;
  readonly pattern: string;
}

interface ValidationMetrics {
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly duplicateIdCount: number;
  readonly emptyLocalizedFieldCount: number;
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

function sha256Hex(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

function compareAscii(a: { readonly id: string }, b: { readonly id: string }): number {
  return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
}

function categoryIdFor(questionId: string): string {
  return questionId.slice(0, 5);
}

function subsectionIdFor(questionId: string): string {
  return questionId.slice(0, 9);
}

function assertStrictCrlf(bytes: Uint8Array, label: string): void {
  for (let index = 0; index < bytes.length; index += 1) {
    const byte = bytes[index];
    if (byte === 0x0a && (index === 0 || bytes[index - 1] !== 0x0d)) {
      fail(`${label}: bare LF at byte ${index}; expected CRLF line endings`);
    }
    if (byte === 0x0d && (index + 1 >= bytes.length || bytes[index + 1] !== 0x0a)) {
      fail(`${label}: bare CR at byte ${index}; expected CRLF line endings`);
    }
  }
}

function assertNoBom(bytes: Uint8Array, label: string): void {
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    fail(`${label}: UTF-8 BOM is not allowed`);
  }
}

function looksLikeCsvWrapper(field: string): boolean {
  if (!field.startsWith("\"") || !field.endsWith("\"") || field.length < 2) {
    return false;
  }
  return !field.slice(1, -1).includes("\"");
}

function assertNoCsvQuoteWrappers(fields: readonly string[], lineNumber: number): void {
  for (const [fieldIndex, field] of fields.entries()) {
    if (looksLikeCsvWrapper(field)) {
      fail(`line ${lineNumber}, field ${fieldIndex + 1}: quoted CSV fields are not supported; quote characters must be preserved as data`);
    }
  }
}

export function parseDelimitedQuestionBank(bytes: Uint8Array, label = SOURCE_TXT_PATH): ParseResult {
  assertNoBom(bytes, label);
  assertStrictCrlf(bytes, label);

  let text: string;
  try {
    text = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    fail(`${label}: invalid UTF-8 (${detail})`);
  }
  if (text.startsWith("\uFEFF")) {
    fail(`${label}: UTF-8 BOM is not allowed`);
  }

  const lines = text.split("\r\n");
  if (lines.at(-1) === "") {
    lines.pop();
  }
  if (lines.length === 0) {
    fail(`${label}: file is empty`);
  }

  const header = lines[0].split(";").map((name) => name.trim());
  if (header.length !== EXPECTED_HEADERS.length) {
    fail(`${label}: expected ${EXPECTED_HEADERS.length} header fields, found ${header.length}`);
  }
  for (const [index, expected] of EXPECTED_HEADERS.entries()) {
    if (header[index] !== expected) {
      fail(`${label}: header ${index + 1} expected ${expected}, found ${header[index]}`);
    }
  }

  const rows: SourceRow[] = [];
  for (let lineIndex = 1; lineIndex < lines.length; lineIndex += 1) {
    const lineNumber = lineIndex + 1;
    const fields = lines[lineIndex].split(";");
    if (fields.length !== EXPECTED_HEADERS.length) {
      fail(`${label}: line ${lineNumber} expected ${EXPECTED_HEADERS.length} fields, found ${fields.length}`);
    }
    assertNoCsvQuoteWrappers(fields, lineNumber);
    rows.push({ lineNumber, sourceOrder: lineIndex, fields });
  }

  return { header, rows };
}

function questionFromRow(row: SourceRow): Question {
  const fields = row.fields;
  const id = fields[0];
  return {
    id,
    bankId: BANK_ID,
    categoryId: categoryIdFor(id),
    subsectionId: subsectionIdFor(id),
    sourceOrder: row.sourceOrder,
    text: {
      en: fields[1],
      fr: fields[6],
    },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: fields[2], fr: fields[7] } },
      { sourceIndex: 1, isCorrect: false, text: { en: fields[3], fr: fields[8] } },
      { sourceIndex: 2, isCorrect: false, text: { en: fields[4], fr: fields[9] } },
      { sourceIndex: 3, isCorrect: false, text: { en: fields[5], fr: fields[10] } },
    ],
  };
}

function countEmptyLocalizedFields(question: Question): number {
  const values = [
    question.text.en,
    question.text.fr,
    ...question.answers.flatMap((answer) => [answer.text.en, answer.text.fr]),
  ];
  return values.filter((value) => value.length === 0).length;
}

export function findPositionDependentAnswerIssues(questions: readonly Question[]): PositionDependentIssue[] {
  const issues: PositionDependentIssue[] = [];
  for (const question of questions) {
    for (const answer of question.answers) {
      const localized = [
        ["en", answer.text.en],
        ["fr", answer.text.fr],
      ] as const;
      for (const [language, text] of localized) {
        for (const pattern of POSITION_DEPENDENT_PATTERNS) {
          if (pattern.test(text)) {
            issues.push({
              questionId: question.id,
              sourceIndex: answer.sourceIndex,
              language,
              text,
              pattern: pattern.source,
            });
          }
        }
      }
    }
  }
  return issues;
}

function deriveSubsections(questions: readonly Question[]): Subsection[] {
  const questionIdsBySubsection = new Map<string, string[]>();
  for (const question of questions) {
    const questionIds = questionIdsBySubsection.get(question.subsectionId) ?? [];
    questionIds.push(question.id);
    questionIdsBySubsection.set(question.subsectionId, questionIds);
  }

  return [...questionIdsBySubsection.entries()]
    .sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0)
    .map(([id, questionIds]) => ({
      id,
      bankId: BANK_ID,
      categoryId: categoryIdFor(id),
      questionIds: questionIds.toSorted(),
      questionCount: questionIds.length,
      lessonIds: [],
      title: { en: null, fr: null },
    }));
}

function validateQuestions(questionsInSourceOrder: readonly Question[], subsections: readonly Subsection[]): ValidationMetrics {
  if (questionsInSourceOrder.length !== 984) {
    fail(`expected 984 questions, found ${questionsInSourceOrder.length}`);
  }
  if (questionsInSourceOrder[0]?.id !== "B-001-001-001") {
    fail(`expected first question ID B-001-001-001, found ${questionsInSourceOrder[0]?.id ?? "none"}`);
  }
  if (questionsInSourceOrder.at(-1)?.id !== "B-008-005-011") {
    fail(`expected last question ID B-008-005-011, found ${questionsInSourceOrder.at(-1)?.id ?? "none"}`);
  }

  const ids = new Set<string>();
  let duplicateIdCount = 0;
  let emptyLocalizedFieldCount = 0;
  for (const question of questionsInSourceOrder) {
    if (!ID_PATTERN.test(question.id)) {
      fail(`question ID ${question.id} does not match ${ID_PATTERN.source}`);
    }
    if (ids.has(question.id)) {
      duplicateIdCount += 1;
    }
    ids.add(question.id);
    emptyLocalizedFieldCount += countEmptyLocalizedFields(question);
  }
  if (duplicateIdCount !== 0) {
    fail(`expected 0 duplicate IDs, found ${duplicateIdCount}`);
  }
  if (emptyLocalizedFieldCount !== 0) {
    fail(`expected 0 empty English/French fields, found ${emptyLocalizedFieldCount}`);
  }
  if (subsections.length !== 100) {
    fail(`expected 100 subsections, found ${subsections.length}`);
  }
  for (const subsection of subsections) {
    if (subsection.questionCount < 4 || subsection.questionCount > 11) {
      fail(`subsection ${subsection.id} has ${subsection.questionCount} questions; expected 4 to 11`);
    }
  }

  return {
    questionCount: questionsInSourceOrder.length,
    subsectionCount: subsections.length,
    duplicateIdCount,
    emptyLocalizedFieldCount,
  };
}

function countQuestionsByCategory(questions: readonly Question[]): Map<string, number> {
  const counts = new Map<string, number>();
  for (const question of questions) {
    counts.set(question.categoryId, (counts.get(question.categoryId) ?? 0) + 1);
  }
  return counts;
}

function countSubsectionsByCategory(subsections: readonly Subsection[]): Map<string, number> {
  const counts = new Map<string, number>();
  for (const subsection of subsections) {
    counts.set(subsection.categoryId, (counts.get(subsection.categoryId) ?? 0) + 1);
  }
  return counts;
}

function loadHandCategories(jsonText: string): HandCategory[] {
  const parsed = JSON.parse(jsonText) as unknown;
  if (!Array.isArray(parsed)) {
    fail(`${HAND_CATEGORIES_PATH} must contain a JSON array`);
  }
  return parsed.map((entry, index) => {
    const label = `${HAND_CATEGORIES_PATH}[${index}]`;
    const object = asObject(entry, label);
    const name = asObject(object.name, `${label}.name`);
    if (typeof object.id !== "string") fail(`${label}.id must be a string`);
    if (typeof name.en !== "string") fail(`${label}.name.en must be a string`);
    if (name.fr !== null) fail(`${label}.name.fr must be null until verified`);
    if (object.frenchNameStatus !== "pending verification") fail(`${label}.frenchNameStatus must be pending verification`);
    if (typeof object.expectedQuestionCount !== "number") fail(`${label}.expectedQuestionCount must be a number`);
    if (typeof object.expectedSubsectionCount !== "number") fail(`${label}.expectedSubsectionCount must be a number`);
    if (typeof object.examQuestionCount !== "number") fail(`${label}.examQuestionCount must be a number`);
    if (typeof object.nameSource !== "string") fail(`${label}.nameSource must be a string`);
    return {
      id: object.id,
      name: { en: name.en, fr: null },
      frenchNameStatus: object.frenchNameStatus,
      expectedQuestionCount: object.expectedQuestionCount,
      expectedSubsectionCount: object.expectedSubsectionCount,
      examQuestionCount: object.examQuestionCount,
      nameSource: object.nameSource,
    };
  });
}

function deriveCategories(
  handCategories: readonly HandCategory[],
  questions: readonly Question[],
  subsections: readonly Subsection[],
): GeneratedCategory[] {
  if (handCategories.length !== 8) {
    fail(`${HAND_CATEGORIES_PATH} expected 8 categories, found ${handCategories.length}`);
  }

  const questionCounts = countQuestionsByCategory(questions);
  const subsectionCounts = countSubsectionsByCategory(subsections);
  const seen = new Set<string>();
  const generated: GeneratedCategory[] = [];

  for (const category of handCategories.toSorted(compareAscii)) {
    if (seen.has(category.id)) {
      fail(`${HAND_CATEGORIES_PATH} has duplicate category ${category.id}`);
    }
    seen.add(category.id);
    const expected = EXPECTED_CATEGORY_COUNTS.get(category.id);
    if (expected === undefined) {
      fail(`${HAND_CATEGORIES_PATH} has unknown category ${category.id}`);
    }
    if (category.expectedQuestionCount !== expected.questionCount) {
      fail(`${category.id} expectedQuestionCount ${category.expectedQuestionCount} does not match authoritative count ${expected.questionCount}`);
    }
    if (category.expectedSubsectionCount !== expected.subsectionCount) {
      fail(`${category.id} expectedSubsectionCount ${category.expectedSubsectionCount} does not match authoritative count ${expected.subsectionCount}`);
    }
    if (category.examQuestionCount !== expected.examQuestionCount) {
      fail(`${category.id} examQuestionCount ${category.examQuestionCount} does not match authoritative count ${expected.examQuestionCount}`);
    }

    const actualQuestionCount = questionCounts.get(category.id) ?? 0;
    const actualSubsectionCount = subsectionCounts.get(category.id) ?? 0;
    if (actualQuestionCount !== category.expectedQuestionCount) {
      fail(`${category.id} expected ${category.expectedQuestionCount} questions, found ${actualQuestionCount}`);
    }
    if (actualSubsectionCount !== category.expectedSubsectionCount) {
      fail(`${category.id} expected ${category.expectedSubsectionCount} subsections, found ${actualSubsectionCount}`);
    }

    generated.push({
      id: category.id,
      bankId: BANK_ID,
      name: category.name,
      frenchNameStatus: category.frenchNameStatus,
      questionCount: actualQuestionCount,
      subsectionCount: actualSubsectionCount,
      examQuestionCount: category.examQuestionCount,
      nameSource: category.nameSource,
    });
  }

  return generated;
}

function extractPrivilegeCitationIds(examFactsText: string): string[] {
  const privilegeSection = examFactsText
    .split("## Privileges for learning content")[1]
    ?.split("## How to re-verify when ISED updates the bank")[0];
  if (privilegeSection === undefined) {
    fail(`${DOCS_EXAM_FACTS_PATH}: missing Privileges for learning content section`);
  }
  return [...new Set(privilegeSection.match(/B-\d{3}-\d{3}-\d{3}/g) ?? [])].toSorted();
}

function validatePrivilegeCitationsFromDocs(examFactsText: string): void {
  const citedIds = extractPrivilegeCitationIds(examFactsText);
  const expectedIds = [...EXPECTED_PRIVILEGE_ANSWER_TEXT.keys()].toSorted();
  if (JSON.stringify(citedIds) !== JSON.stringify(expectedIds)) {
    fail(`${DOCS_EXAM_FACTS_PATH}: privilege citation IDs ${JSON.stringify(citedIds)} do not match expected IDs ${JSON.stringify(expectedIds)}`);
  }
}

function validatePrivilegeAnswers(questions: readonly Question[]): void {
  const questionsById = new Map(questions.map((question) => [question.id, question]));
  for (const [questionId, expectedText] of EXPECTED_PRIVILEGE_ANSWER_TEXT.entries()) {
    const question = questionsById.get(questionId);
    if (question === undefined) {
      fail(`privilege citation ${questionId} is missing from imported questions`);
    }
    const actualText = question.answers[0]?.text.en;
    if (actualText !== expectedText) {
      fail(`privilege citation ${questionId} expected English correct answer ${JSON.stringify(expectedText)}, found ${JSON.stringify(actualText)}`);
    }
  }
}

function validatePositionDependentLint(questions: readonly Question[]): void {
  const issues = findPositionDependentAnswerIssues(questions);
  if (issues.length > 0) {
    const formatted = issues
      .map((issue) => `${issue.questionId} answer ${issue.sourceIndex} ${issue.language}: ${JSON.stringify(issue.text)} matched /${issue.pattern}/i`)
      .join("\n");
    fail(`position-dependent answer lint found ${issues.length} issue(s):\n${formatted}`);
  }
}

function validateSourceManifest(sourceManifest: SourceManifest, sourceSha256: string): SourceManifestFile {
  const sourceRelativePath = "questions/amat_basic_quest_delim.txt";
  const sourceFile = sourceManifest.files.find((file) => file.path === sourceRelativePath);
  if (sourceFile === undefined) {
    fail(`${SOURCE_MANIFEST_PATH}: missing ${sourceRelativePath}`);
  }
  if (sourceFile.sha256 !== sourceSha256) {
    fail(`${SOURCE_TXT_PATH}: SHA-256 mismatch against manifest.json; expected ${sourceFile.sha256}, found ${sourceSha256}`);
  }
  if (sourceManifest.bankEffectiveDate !== BANK_EFFECTIVE_DATE) {
    fail(`${SOURCE_MANIFEST_PATH}: expected bankEffectiveDate ${BANK_EFFECTIVE_DATE}, found ${sourceManifest.bankEffectiveDate ?? "missing"}`);
  }
  return sourceFile;
}

function validateSha256Sums(sha256SumsText: string, sourceSha256: string): void {
  const sourceRelativePath = "questions/amat_basic_quest_delim.txt";
  const expectedLine = `${sourceSha256}  ${sourceRelativePath}`;
  const lines = sha256SumsText.split(/\r?\n/).filter((line) => line.length > 0);
  if (!lines.includes(expectedLine)) {
    fail(`${SOURCE_SHA256SUMS_PATH}: missing line ${expectedLine}`);
  }
}

export async function importBasicQuestionBank(rootDir = process.cwd()): Promise<ImportedBank> {
  const sourceBytes = await readFile(path.join(rootDir, SOURCE_TXT_PATH));
  const sourceSha256 = sha256Hex(sourceBytes);

  const [sourceManifestText, sha256SumsText] = await Promise.all([
    readFile(path.join(rootDir, SOURCE_MANIFEST_PATH), "utf8"),
    readFile(path.join(rootDir, SOURCE_SHA256SUMS_PATH), "utf8"),
  ]);

  const sourceManifest = JSON.parse(sourceManifestText) as SourceManifest;
  const sourceFile = validateSourceManifest(sourceManifest, sourceSha256);
  validateSha256Sums(sha256SumsText, sourceSha256);

  const [handCategoriesText, examFactsText] = await Promise.all([
    readFile(path.join(rootDir, HAND_CATEGORIES_PATH), "utf8"),
    readFile(path.join(rootDir, DOCS_EXAM_FACTS_PATH), "utf8"),
  ]);

  const parseResult = parseDelimitedQuestionBank(sourceBytes);
  const questionsInSourceOrder = parseResult.rows.map(questionFromRow);
  const questions = questionsInSourceOrder.toSorted(compareAscii);
  const subsections = deriveSubsections(questions);
  const metrics = validateQuestions(questionsInSourceOrder, subsections);
  validatePrivilegeCitationsFromDocs(examFactsText);
  validatePrivilegeAnswers(questions);
  validatePositionDependentLint(questions);

  const handCategories = loadHandCategories(handCategoriesText);
  const categories = deriveCategories(handCategories, questions, subsections);

  const manifest: GeneratedManifest = {
    bankId: BANK_ID,
    certificate: "canadian-amateur-basic",
    effectiveDate: BANK_EFFECTIVE_DATE,
    source: {
      path: SOURCE_TXT_PATH,
      sha256: sourceSha256,
      url: sourceFile.sourceUrl ?? "https://apc-cap.ic.gc.ca/datafiles/amat_basic_quest.zip#amat_basic_quest_delim.txt",
      encoding: "UTF-8",
      lineEndings: "CRLF",
    },
    importer: {
      name: "packages/content-tools/src/import-basic.ts",
      version: IMPORTER_VERSION,
    },
    counts: {
      questions: metrics.questionCount,
      categories: categories.length,
      subsections: metrics.subsectionCount,
    },
  };

  return { questions, subsections, categories, manifest };
}

function jsonFileContent(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

export async function buildGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const bank = await importBasicQuestionBank(rootDir);
  return [
    { path: `${GENERATED_DIR}/questions.json`, content: jsonFileContent(bank.questions) },
    { path: `${GENERATED_DIR}/subsections.json`, content: jsonFileContent(bank.subsections) },
    { path: `${GENERATED_DIR}/categories.json`, content: jsonFileContent(bank.categories) },
    { path: `${GENERATED_DIR}/manifest.json`, content: jsonFileContent(bank.manifest) },
  ];
}

export async function writeGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const files = await buildGeneratedFiles(rootDir);
  for (const file of files) {
    const destination = path.join(rootDir, file.path);
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, file.content, "utf8");
  }
  return files;
}

export async function checkGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const files = await buildGeneratedFiles(rootDir);
  const mismatches: string[] = [];
  for (const file of files) {
    const destination = path.join(rootDir, file.path);
    let existing: string;
    try {
      existing = await readFile(destination, "utf8");
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      mismatches.push(`${file.path}: cannot read committed output (${detail})`);
      continue;
    }
    if (existing !== file.content) {
      mismatches.push(`${file.path}: differs from regenerated output`);
    }
  }
  if (mismatches.length > 0) {
    fail(`generated output is not up to date:\n${mismatches.join("\n")}`);
  }
  return files;
}
