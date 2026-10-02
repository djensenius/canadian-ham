import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { TextDecoder } from "node:util";

import { ADVANCED_BANK_ID, ADVANCED_BANK_RULES } from "./banks.ts";
import { EXPECTED_HEADERS } from "./basic-importer.ts";
import type {
  GeneratedCategory,
  GeneratedFile,
  GeneratedManifest,
  HandCategory,
  ImportedBank,
  ParseResult,
  Question,
  SourceRow,
  Subsection,
} from "./basic-importer.ts";

export const BANK_ID = ADVANCED_BANK_ID;
export const BANK_EFFECTIVE_DATE = ADVANCED_BANK_RULES.effectiveDate ?? "";
export const IMPORTER_VERSION = "1";

export const SOURCE_DIR = `content/sources/ised/${BANK_ID}`;
export const SOURCE_TXT_PATH = `${SOURCE_DIR}/questions/amat_adv_quest_delim.txt`;
export const SOURCE_MANIFEST_PATH = `${SOURCE_DIR}/manifest.json`;
export const SOURCE_SHA256SUMS_PATH = `${SOURCE_DIR}/SHA256SUMS`;
export const HAND_CATEGORIES_PATH = "content/categories-advanced.json";
export const GENERATED_DIR = `content/generated/${BANK_ID}`;

export type AdvancedSourceEncoding = "UTF-8" | "Windows-1252";

interface SourceManifestFile {
  readonly path: string;
  readonly sourceUrl?: string;
  readonly sha256: string;
  readonly bytes?: number;
  readonly encoding?: string | null;
  readonly lineEndings?: string | null;
}

interface SourceManifest {
  readonly bankEffectiveDate?: string;
  readonly files: readonly SourceManifestFile[];
}

interface DecodedSourceText {
  readonly text: string;
  readonly encoding: AdvancedSourceEncoding;
}

interface ValidationMetrics {
  readonly questionCount: number;
  readonly subsectionCount: number;
  readonly duplicateIdCount: number;
  readonly emptyLocalizedFieldCount: number;
}

const EXPECTED_CATEGORY_COUNTS = new Map(ADVANCED_BANK_RULES.categoryRules.map((category) => [category.id, {
  questionCount: category.questionCount,
  subsectionCount: category.subsectionCount,
  examQuestionCount: category.examQuestionCount,
}]));

const ID_PATTERN = new RegExp(`^${ADVANCED_BANK_RULES.questionIdPrefix}-\\d{3}-\\d{3}-\\d{3}$`);

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

function assertNoUnsupportedCsvQuotes(fields: readonly string[], lineNumber: number): void {
  for (const [fieldIndex, field] of fields.entries()) {
    if (field.includes("\"\"")) {
      fail(`line ${lineNumber}, field ${fieldIndex + 1}: field contains doubled double quotes; this looks like CSV quote escaping, which this format does not use. Verify against the official ISED file before changing the importer.`);
    }
    if (looksLikeCsvWrapper(field)) {
      fail(`line ${lineNumber}, field ${fieldIndex + 1}: field is wrapped entirely in double quotes; this looks like CSV quoting, which this format does not use. Verify against the official ISED file before changing the importer.`);
    }
  }
}

export function detectDelimitedTextEncoding(bytes: Uint8Array, label = SOURCE_TXT_PATH): DecodedSourceText {
  try {
    return {
      text: new TextDecoder("utf-8", { fatal: true }).decode(bytes),
      encoding: "UTF-8",
    };
  } catch {
    // Historical Advanced-bank copies were not valid UTF-8. Keep the fallback explicit so
    // accents are decoded deterministically if ISED republishes the legacy byte encoding.
    try {
      return {
        text: new TextDecoder("windows-1252", { fatal: true }).decode(bytes),
        encoding: "Windows-1252",
      };
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error);
      fail(`${label}: unsupported text encoding; expected UTF-8 or Windows-1252 (${detail})`);
    }
  }
}

export function parseAdvancedDelimitedQuestionBank(bytes: Uint8Array, label = SOURCE_TXT_PATH): ParseResult & { readonly encoding: AdvancedSourceEncoding } {
  assertNoBom(bytes, label);
  assertStrictCrlf(bytes, label);

  const decoded = detectDelimitedTextEncoding(bytes, label);
  const text = decoded.text;
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
    assertNoUnsupportedCsvQuotes(fields, lineNumber);
    rows.push({ lineNumber, sourceOrder: lineIndex, fields });
  }

  return { header, rows, encoding: decoded.encoding };
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
  if (questionsInSourceOrder.length !== ADVANCED_BANK_RULES.questionCount) {
    fail(`expected ${ADVANCED_BANK_RULES.questionCount} questions, found ${questionsInSourceOrder.length}`);
  }
  if (questionsInSourceOrder[0]?.id !== "A-001-001-001") {
    fail(`expected first question ID A-001-001-001, found ${questionsInSourceOrder[0]?.id ?? "none"}`);
  }
  if (questionsInSourceOrder.at(-1)?.id !== "A-007-009-011") {
    fail(`expected last question ID A-007-009-011, found ${questionsInSourceOrder.at(-1)?.id ?? "none"}`);
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
  if (subsections.length !== ADVANCED_BANK_RULES.subsectionCount) {
    fail(`expected ${ADVANCED_BANK_RULES.subsectionCount} subsections, found ${subsections.length}`);
  }
  for (const subsection of subsections) {
    if (subsection.questionCount < 10 || subsection.questionCount > 11) {
      fail(`subsection ${subsection.id} has ${subsection.questionCount} questions; expected 10 to 11`);
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
    if (name.fr !== null && (typeof name.fr !== "string" || name.fr.length === 0)) fail(`${label}.name.fr must be null or a non-empty string`);
    if (object.frenchNameStatus !== "pending verification" && object.frenchNameStatus !== "verified") fail(`${label}.frenchNameStatus must be pending verification or verified`);
    if (object.frenchNameStatus === "pending verification" && name.fr !== null) fail(`${label}.name.fr must be null while frenchNameStatus is pending verification`);
    if (object.frenchNameStatus === "verified" && name.fr === null) fail(`${label}.name.fr must be a string when frenchNameStatus is verified`);
    if (typeof object.expectedQuestionCount !== "number") fail(`${label}.expectedQuestionCount must be a number`);
    if (typeof object.expectedSubsectionCount !== "number") fail(`${label}.expectedSubsectionCount must be a number`);
    if (typeof object.examQuestionCount !== "number") fail(`${label}.examQuestionCount must be a number`);
    if (typeof object.nameSource !== "string") fail(`${label}.nameSource must be a string`);
    return {
      id: object.id,
      name: { en: name.en, fr: name.fr },
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
  if (handCategories.length !== ADVANCED_BANK_RULES.categoryCount) {
    fail(`${HAND_CATEGORIES_PATH} expected ${ADVANCED_BANK_RULES.categoryCount} categories, found ${handCategories.length}`);
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

function validateSourceManifest(sourceManifest: SourceManifest, sourceSha256: string, sourceByteCount: number, detectedEncoding: AdvancedSourceEncoding): SourceManifestFile {
  const sourceRelativePath = "questions/amat_adv_quest_delim.txt";
  const sourceFile = sourceManifest.files.find((file) => file.path === sourceRelativePath);
  if (sourceFile === undefined) {
    fail(`${SOURCE_MANIFEST_PATH}: missing ${sourceRelativePath}`);
  }
  if (sourceFile.sha256 !== sourceSha256) {
    fail(`${SOURCE_TXT_PATH}: SHA-256 mismatch against manifest.json; expected ${sourceFile.sha256}, found ${sourceSha256}`);
  }
  if (sourceFile.encoding !== detectedEncoding) {
    fail(`${SOURCE_MANIFEST_PATH}: ${sourceRelativePath} encoding expected ${detectedEncoding}, found ${sourceFile.encoding ?? "missing"}`);
  }
  if (sourceFile.lineEndings !== "CRLF") {
    fail(`${SOURCE_MANIFEST_PATH}: ${sourceRelativePath} lineEndings expected CRLF, found ${sourceFile.lineEndings ?? "missing"}`);
  }
  if (sourceFile.bytes !== sourceByteCount) {
    fail(`${SOURCE_MANIFEST_PATH}: ${sourceRelativePath} bytes expected ${sourceByteCount}, found ${sourceFile.bytes ?? "missing"}`);
  }
  if (sourceManifest.bankEffectiveDate !== BANK_EFFECTIVE_DATE) {
    fail(`${SOURCE_MANIFEST_PATH}: expected bankEffectiveDate ${BANK_EFFECTIVE_DATE}, found ${sourceManifest.bankEffectiveDate ?? "missing"}`);
  }
  return sourceFile;
}

async function validateSha256Sums(rootDir: string, sourceManifest: SourceManifest, sha256SumsText: string): Promise<void> {
  const manifestFiles = new Map(sourceManifest.files.map((file) => [file.path, file]));
  const seenPaths = new Set<string>();
  const lines = sha256SumsText.split(/\r?\n/).filter((line) => line.length > 0);

  for (const [index, line] of lines.entries()) {
    const match = /^(?<sha256>[a-f0-9]{64})  (?<relativePath>.+)$/u.exec(line);
    if (match?.groups === undefined) {
      fail(`${SOURCE_SHA256SUMS_PATH}: line ${index + 1} must be '<sha256>  <path>'`);
    }
    const relativePath = match.groups.relativePath;
    if (seenPaths.has(relativePath)) {
      fail(`${SOURCE_SHA256SUMS_PATH}: duplicate checksum line for ${relativePath}`);
    }
    seenPaths.add(relativePath);

    const manifestFile = manifestFiles.get(relativePath);
    if (manifestFile === undefined) {
      fail(`${SOURCE_SHA256SUMS_PATH}: ${relativePath} is not listed in ${SOURCE_MANIFEST_PATH}`);
    }
    if (match.groups.sha256 !== manifestFile.sha256) {
      fail(`${SOURCE_SHA256SUMS_PATH}: ${relativePath} expected manifest SHA-256 ${manifestFile.sha256}, found ${match.groups.sha256}`);
    }

    const bytes = await readFile(path.join(rootDir, SOURCE_DIR, relativePath));
    const actualSha256 = sha256Hex(bytes);
    if (actualSha256 !== match.groups.sha256) {
      fail(`${SOURCE_DIR}/${relativePath}: SHA-256 mismatch against ${SOURCE_SHA256SUMS_PATH}; expected ${match.groups.sha256}, found ${actualSha256}`);
    }
  }

  for (const manifestFile of sourceManifest.files) {
    if (!seenPaths.has(manifestFile.path)) {
      fail(`${SOURCE_SHA256SUMS_PATH}: missing line for ${manifestFile.path}`);
    }
  }
}

export async function importAdvancedQuestionBank(rootDir = process.cwd()): Promise<ImportedBank> {
  const sourceBytes = await readFile(path.join(rootDir, SOURCE_TXT_PATH));
  const sourceSha256 = sha256Hex(sourceBytes);
  const parseResult = parseAdvancedDelimitedQuestionBank(sourceBytes);

  const [sourceManifestText, sha256SumsText] = await Promise.all([
    readFile(path.join(rootDir, SOURCE_MANIFEST_PATH), "utf8"),
    readFile(path.join(rootDir, SOURCE_SHA256SUMS_PATH), "utf8"),
  ]);

  const sourceManifest = JSON.parse(sourceManifestText) as SourceManifest;
  const sourceFile = validateSourceManifest(sourceManifest, sourceSha256, sourceBytes.byteLength, parseResult.encoding);
  await validateSha256Sums(rootDir, sourceManifest, sha256SumsText);

  const handCategoriesText = await readFile(path.join(rootDir, HAND_CATEGORIES_PATH), "utf8");

  const questionsInSourceOrder = parseResult.rows.map(questionFromRow);
  const questions = questionsInSourceOrder.toSorted(compareAscii);
  const subsections = deriveSubsections(questions);
  const metrics = validateQuestions(questionsInSourceOrder, subsections);

  const handCategories = loadHandCategories(handCategoriesText);
  const categories = deriveCategories(handCategories, questions, subsections);

  const manifest: GeneratedManifest = {
    bankId: BANK_ID,
    certificate: ADVANCED_BANK_RULES.certificate,
    effectiveDate: BANK_EFFECTIVE_DATE,
    source: {
      path: SOURCE_TXT_PATH,
      sha256: sourceSha256,
      url: sourceFile.sourceUrl ?? "https://apc-cap.ic.gc.ca/datafiles/amat_adv_quest.zip#amat_adv_quest_delim.txt",
      encoding: parseResult.encoding,
      lineEndings: "CRLF",
    },
    importer: {
      name: "packages/content-tools/src/import-advanced.ts",
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

export async function buildAdvancedGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const bank = await importAdvancedQuestionBank(rootDir);
  return [
    { path: `${GENERATED_DIR}/questions.json`, content: jsonFileContent(bank.questions) },
    { path: `${GENERATED_DIR}/subsections.json`, content: jsonFileContent(bank.subsections) },
    { path: `${GENERATED_DIR}/categories.json`, content: jsonFileContent(bank.categories) },
    { path: `${GENERATED_DIR}/manifest.json`, content: jsonFileContent(bank.manifest) },
  ];
}

export async function writeAdvancedGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const files = await buildAdvancedGeneratedFiles(rootDir);
  for (const file of files) {
    const destination = path.join(rootDir, file.path);
    await mkdir(path.dirname(destination), { recursive: true });
    await writeFile(destination, file.content, "utf8");
  }
  return files;
}

export async function checkAdvancedGeneratedFiles(rootDir = process.cwd()): Promise<GeneratedFile[]> {
  const files = await buildAdvancedGeneratedFiles(rootDir);
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
