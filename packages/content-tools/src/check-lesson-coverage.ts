import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const DEFAULT_LESSON_ROOT = path.join(REPO_ROOT, "content/lessons");
const DEFAULT_SUBSECTIONS_PATH = path.join(REPO_ROOT, "content/generated/basic-2025-07-15/subsections.json");

type FrontMatterValue = string | number | null | string[] | Record<string, string | null>;
type FrontMatter = Record<string, FrontMatterValue>;

type LessonFrontMatter = {
  id: string;
  moduleId: string;
  categoryIds: string[];
  title: { en: string; fr: string | null };
  covers: string[];
  objectives: string[];
  prerequisites: string[];
  estimatedMinutes: number;
  quizIds: string[];
  status: "outline";
};

type ModuleFrontMatter = {
  id: string;
  categoryId: string;
  title: { en: string; fr: string | null };
  lessonIds: string[];
  status: "outline";
};

export type LessonCoverageOptions = {
  lessonRoot?: string;
  expectedSubsectionsPath?: string;
};

export type LessonCoverageReport = {
  lessonCount: number;
  moduleCount: number;
  expectedSubsectionCount: number;
  coveredSubsectionCount: number;
  missingSubsectionIds: string[];
  unknownSubsectionIds: string[];
  duplicateCoverage: { subsectionId: string; lessonIds: string[] }[];
  malformedFiles: { filePath: string; message: string }[];
  summaryLines: string[];
};

export class LessonCoverageError extends Error {
  report: LessonCoverageReport;

  constructor(report: LessonCoverageReport) {
    super("lesson coverage check failed");
    this.report = report;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function parseScalar(raw: string, filePath: string, lineNumber: number): string | number | null | string[] {
  const value = raw.trim();
  if (value === "") {
    throw new Error(`${filePath}:${lineNumber}: missing scalar value`);
  }
  if (value === "null") {
    return null;
  }
  if (value === "[]") {
    return [];
  }
  if (/^-?\d+$/.test(value)) {
    return Number(value);
  }
  if (value.startsWith("\"") || value.endsWith("\"")) {
    if (!value.startsWith("\"") || !value.endsWith("\"")) {
      throw new Error(`${filePath}:${lineNumber}: malformed quoted string`);
    }
    const parsed: unknown = JSON.parse(value);
    if (typeof parsed !== "string") {
      throw new Error(`${filePath}:${lineNumber}: quoted scalar must be a string`);
    }
    return parsed;
  }
  if (/^[A-Za-z0-9._/-]+$/.test(value)) {
    return value;
  }
  throw new Error(`${filePath}:${lineNumber}: quote scalar values containing spaces or punctuation`);
}

function parseFrontMatter(markdown: string, filePath: string): FrontMatter {
  const normalized = markdown.replace(/\r\n/g, "\n");
  const lines = normalized.split("\n");
  if (lines[0] !== "---") {
    throw new Error(`${filePath}: missing opening front matter delimiter`);
  }
  const closingIndex = lines.indexOf("---", 1);
  if (closingIndex === -1) {
    throw new Error(`${filePath}: missing closing front matter delimiter`);
  }

  const frontMatterLines = lines.slice(1, closingIndex);
  const data: FrontMatter = {};
  let currentKey: string | null = null;

  for (let index = 0; index < frontMatterLines.length; index += 1) {
    const line = frontMatterLines[index]!;
    const lineNumber = index + 2;
    if (line.trim() === "") {
      continue;
    }

    const arrayItem = line.match(/^  - (.*)$/);
    if (arrayItem) {
      if (currentKey === null || !Array.isArray(data[currentKey])) {
        throw new Error(`${filePath}:${lineNumber}: array item is not under an array key`);
      }
      const scalar = parseScalar(arrayItem[1]!, filePath, lineNumber);
      if (typeof scalar !== "string") {
        throw new Error(`${filePath}:${lineNumber}: array items must be strings`);
      }
      (data[currentKey] as string[]).push(scalar);
      continue;
    }

    const objectItem = line.match(/^  ([A-Za-z][A-Za-z0-9]*): (.*)$/);
    if (objectItem) {
      if (currentKey === null || !isRecord(data[currentKey])) {
        throw new Error(`${filePath}:${lineNumber}: object entry is not under an object key`);
      }
      const objectValue = data[currentKey] as Record<string, string | null>;
      const nestedKey = objectItem[1]!;
      if (Object.prototype.hasOwnProperty.call(objectValue, nestedKey)) {
        throw new Error(`${filePath}:${lineNumber}: duplicate nested key ${nestedKey}`);
      }
      const scalar = parseScalar(objectItem[2]!, filePath, lineNumber);
      if (typeof scalar !== "string" && scalar !== null) {
        throw new Error(`${filePath}:${lineNumber}: object values must be strings or null`);
      }
      objectValue[nestedKey] = scalar;
      continue;
    }

    if (line.startsWith(" ")) {
      throw new Error(`${filePath}:${lineNumber}: unsupported indentation`);
    }

    const topLevel = line.match(/^([A-Za-z][A-Za-z0-9]*):(.*)$/);
    if (!topLevel) {
      throw new Error(`${filePath}:${lineNumber}: expected key-value front matter line`);
    }
    const key = topLevel[1]!;
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      throw new Error(`${filePath}:${lineNumber}: duplicate key ${key}`);
    }
    const rawValue = topLevel[2]!;
    if (rawValue.trim() === "") {
      const nextLine = frontMatterLines.slice(index + 1).find((candidate) => candidate.trim() !== "");
      data[key] = nextLine?.startsWith("  - ") ? [] : {};
    } else {
      if (!rawValue.startsWith(" ")) {
        throw new Error(`${filePath}:${lineNumber}: expected a space after ':'`);
      }
      data[key] = parseScalar(rawValue, filePath, lineNumber);
    }
    currentKey = key;
  }

  return data;
}

function requireString(data: FrontMatter, key: string, filePath: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`${filePath}: front matter field ${key} must be a non-empty string`);
  }
  return value;
}

function requireNumber(data: FrontMatter, key: string, filePath: string): number {
  const value = data[key];
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`${filePath}: front matter field ${key} must be a positive integer`);
  }
  return value;
}

function requireStringArray(data: FrontMatter, key: string, filePath: string, allowEmpty = false): string[] {
  const value = data[key];
  if (!Array.isArray(value) || (!allowEmpty && value.length === 0) || value.some((item) => typeof item !== "string" || item.length === 0)) {
    throw new Error(`${filePath}: front matter field ${key} must be ${allowEmpty ? "an" : "a non-empty"} array of strings`);
  }
  return value;
}

function requireLocalizedTitle(data: FrontMatter, filePath: string): { en: string; fr: string | null } {
  const value = data.title;
  if (!isRecord(value) || typeof value.en !== "string" || value.en.length === 0 || !(typeof value.fr === "string" || value.fr === null)) {
    throw new Error(`${filePath}: front matter field title must contain en string and fr string|null`);
  }
  return { en: value.en, fr: value.fr };
}

function validateLesson(data: FrontMatter, filePath: string): LessonFrontMatter {
  const status = requireString(data, "status", filePath);
  if (status !== "outline") {
    throw new Error(`${filePath}: lesson status must be outline`);
  }
  const lesson: LessonFrontMatter = {
    id: requireString(data, "id", filePath),
    moduleId: requireString(data, "moduleId", filePath),
    categoryIds: requireStringArray(data, "categoryIds", filePath),
    title: requireLocalizedTitle(data, filePath),
    covers: requireStringArray(data, "covers", filePath),
    objectives: requireStringArray(data, "objectives", filePath),
    prerequisites: requireStringArray(data, "prerequisites", filePath, true),
    estimatedMinutes: requireNumber(data, "estimatedMinutes", filePath),
    quizIds: requireStringArray(data, "quizIds", filePath, true),
    status,
  };
  if (!/^L-\d{3}-\d{2}$/.test(lesson.id)) {
    throw new Error(`${filePath}: lesson id must match L-000-00`);
  }
  return lesson;
}

function validateModule(data: FrontMatter, filePath: string): ModuleFrontMatter {
  const status = requireString(data, "status", filePath);
  if (status !== "outline") {
    throw new Error(`${filePath}: module status must be outline`);
  }
  return {
    id: requireString(data, "id", filePath),
    categoryId: requireString(data, "categoryId", filePath),
    title: requireLocalizedTitle(data, filePath),
    lessonIds: requireStringArray(data, "lessonIds", filePath),
    status,
  };
}

async function listMarkdownFiles(root: string): Promise<string[]> {
  const entries = await readdir(root, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const absolutePath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      files.push(...await listMarkdownFiles(absolutePath));
    } else if (entry.isFile() && entry.name.endsWith(".md") && entry.name !== "README.md") {
      files.push(absolutePath);
    }
  }
  return files.sort();
}

async function readExpectedSubsectionIds(subsectionsPath: string): Promise<string[]> {
  const parsed: unknown = JSON.parse(await readFile(subsectionsPath, "utf8"));
  if (!Array.isArray(parsed)) {
    throw new Error(`${subsectionsPath}: expected an array`);
  }
  const ids = parsed.map((entry, index) => {
    if (!isRecord(entry) || typeof entry.id !== "string") {
      throw new Error(`${subsectionsPath}: entry ${index} is missing string id`);
    }
    return entry.id;
  });
  return [...new Set(ids)].sort();
}

export async function checkLessonCoverage(options: LessonCoverageOptions = {}): Promise<LessonCoverageReport> {
  const lessonRoot = options.lessonRoot ?? DEFAULT_LESSON_ROOT;
  const expectedSubsectionsPath = options.expectedSubsectionsPath ?? DEFAULT_SUBSECTIONS_PATH;
  const expectedSubsectionIds = await readExpectedSubsectionIds(expectedSubsectionsPath);
  const expectedSet = new Set(expectedSubsectionIds);
  const coverage = new Map<string, string[]>();
  const malformedFiles: { filePath: string; message: string }[] = [];
  const lessonIds = new Set<string>();
  const moduleIds = new Set<string>();

  const markdownFiles = await listMarkdownFiles(lessonRoot);
  for (const filePath of markdownFiles) {
    try {
      const data = parseFrontMatter(await readFile(filePath, "utf8"), filePath);
      const type = requireString(data, "type", filePath);
      if (type === "lesson") {
        const lesson = validateLesson(data, filePath);
        if (lessonIds.has(lesson.id)) {
          throw new Error(`${filePath}: duplicate lesson id ${lesson.id}`);
        }
        lessonIds.add(lesson.id);
        for (const subsectionId of lesson.covers) {
          const lessonIdsForSubsection = coverage.get(subsectionId) ?? [];
          lessonIdsForSubsection.push(lesson.id);
          coverage.set(subsectionId, lessonIdsForSubsection);
        }
      } else if (type === "module") {
        const module = validateModule(data, filePath);
        if (moduleIds.has(module.id)) {
          throw new Error(`${filePath}: duplicate module id ${module.id}`);
        }
        moduleIds.add(module.id);
      } else {
        throw new Error(`${filePath}: front matter type must be lesson or module`);
      }
    } catch (error) {
      malformedFiles.push({ filePath, message: error instanceof Error ? error.message : String(error) });
    }
  }

  const coveredKnownSubsections = [...coverage.keys()].filter((subsectionId) => expectedSet.has(subsectionId)).sort();
  const coveredKnownSet = new Set(coveredKnownSubsections);
  const missingSubsectionIds = expectedSubsectionIds.filter((subsectionId) => !coveredKnownSet.has(subsectionId));
  const unknownSubsectionIds = [...coverage.keys()].filter((subsectionId) => !expectedSet.has(subsectionId)).sort();
  const duplicateCoverage = [...coverage.entries()]
    .filter(([, ids]) => ids.length > 1)
    .map(([subsectionId, ids]) => ({ subsectionId, lessonIds: ids.sort() }))
    .sort((left, right) => left.subsectionId.localeCompare(right.subsectionId));

  const summaryLines = [
    `Lesson coverage: ${coveredKnownSubsections.length}/${expectedSubsectionIds.length} subsections covered by ${lessonIds.size} lessons in ${moduleIds.size} modules.`,
    duplicateCoverage.length === 0
      ? "Duplicate subsection coverage: none."
      : `Duplicate subsection coverage: ${duplicateCoverage.map((entry) => `${entry.subsectionId} (${entry.lessonIds.join(", ")})`).join("; ")}.`,
  ];
  if (missingSubsectionIds.length > 0) {
    summaryLines.push(`Missing subsections: ${missingSubsectionIds.join(", ")}.`);
  }
  if (unknownSubsectionIds.length > 0) {
    summaryLines.push(`Unknown subsections: ${unknownSubsectionIds.join(", ")}.`);
  }
  if (malformedFiles.length > 0) {
    summaryLines.push(`Malformed front matter files: ${malformedFiles.map((entry) => `${entry.filePath}: ${entry.message}`).join("; ")}.`);
  }

  const report: LessonCoverageReport = {
    lessonCount: lessonIds.size,
    moduleCount: moduleIds.size,
    expectedSubsectionCount: expectedSubsectionIds.length,
    coveredSubsectionCount: coveredKnownSubsections.length,
    missingSubsectionIds,
    unknownSubsectionIds,
    duplicateCoverage,
    malformedFiles,
    summaryLines,
  };

  if (missingSubsectionIds.length > 0 || unknownSubsectionIds.length > 0 || malformedFiles.length > 0) {
    throw new LessonCoverageError(report);
  }

  return report;
}

function parseCliArgs(args: string[]): LessonCoverageOptions {
  const options: LessonCoverageOptions = {};
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index]!;
    if (arg === "--lessons") {
      const value = args[index + 1];
      if (value === undefined) {
        throw new Error("--lessons requires a path");
      }
      options.lessonRoot = path.resolve(value);
      index += 1;
    } else if (arg === "--subsections") {
      const value = args[index + 1];
      if (value === undefined) {
        throw new Error("--subsections requires a path");
      }
      options.expectedSubsectionsPath = path.resolve(value);
      index += 1;
    } else {
      throw new Error(`unknown argument ${arg}`);
    }
  }
  return options;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    const report = await checkLessonCoverage(parseCliArgs(process.argv.slice(2)));
    console.log(report.summaryLines.join("\n"));
  } catch (error) {
    if (error instanceof LessonCoverageError) {
      console.error(error.report.summaryLines.join("\n"));
      process.exitCode = 1;
    } else {
      console.error(error instanceof Error ? error.message : String(error));
      process.exitCode = 1;
    }
  }
}
