const rawLessonModules = import.meta.glob("../../../../content/lessons/**/*.md", {
  eager: true,
  query: "?raw",
  import: "default",
}) as Record<string, string>;

export type LessonStatus = "draft" | "outline";

export interface LocalizedNullableText {
  readonly en: string;
  readonly fr: string | null;
}

export interface ModuleMeta {
  readonly type: "module";
  readonly id: string;
  readonly categoryId: string;
  readonly order: number;
  readonly title: LocalizedNullableText;
  readonly lessonIds: readonly string[];
  readonly status: LessonStatus;
  readonly body: string;
  readonly path: string;
}

export interface LessonMeta {
  readonly type: "lesson";
  readonly id: string;
  readonly moduleId: string;
  readonly categoryIds: readonly string[];
  readonly title: LocalizedNullableText;
  readonly covers: readonly string[];
  readonly objectives: readonly string[];
  readonly prerequisites: readonly string[];
  readonly estimatedMinutes: number;
  readonly quizIds: readonly string[];
  readonly status: LessonStatus;
  readonly body: string;
  readonly path: string;
}

interface ParsedDocument {
  readonly frontMatter: string;
  readonly body: string;
}

const parsedDocuments = Object.entries(rawLessonModules)
  .filter(([, raw]) => raw.replace(/^\uFEFF/, "").startsWith("---\n"))
  .map(([path, raw]) => ({ path, ...splitFrontMatter(raw) }));

export const modules = parsedDocuments
  .filter((document) => readString(document.frontMatter, "type") === "module")
  .map((document) => parseModule(document.path, document.frontMatter, document.body))
  .sort((a, b) => a.order - b.order || a.id.localeCompare(b.id));

export const lessons = parsedDocuments
  .filter((document) => readString(document.frontMatter, "type") === "lesson")
  .map((document) => parseLesson(document.path, document.frontMatter, document.body))
  .sort((a, b) => a.id.localeCompare(b.id));

export const modulesById = new Map(modules.map((module) => [module.id, module]));
export const lessonsById = new Map(lessons.map((lesson) => [lesson.id, lesson]));
export const lessonsByModuleId = new Map(modules.map((module) => [module.id, module.lessonIds.map((lessonId) => lessonsById.get(lessonId)).filter(isLesson)]));

export function orderedLessons(): readonly LessonMeta[] {
  return modules.flatMap((module) => lessonsByModuleId.get(module.id) ?? []);
}

export function lessonNeighbors(lessonId: string): { readonly previous: LessonMeta | null; readonly next: LessonMeta | null } {
  const ordered = orderedLessons();
  const index = ordered.findIndex((lesson) => lesson.id === lessonId);
  return {
    previous: index > 0 ? ordered[index - 1]! : null,
    next: index >= 0 && index < ordered.length - 1 ? ordered[index + 1]! : null,
  };
}

function isLesson(value: LessonMeta | undefined): value is LessonMeta {
  return value !== undefined;
}

function splitFrontMatter(raw: string): ParsedDocument {
  const normalized = raw.replace(/\r\n/g, "\n");
  const match = /^---\n([\s\S]*?)\n---\n?([\s\S]*)$/.exec(normalized);
  if (match === null) {
    throw new Error("Lesson Markdown file is missing YAML front matter.");
  }
  return { frontMatter: match[1]!, body: match[2]!.trim() };
}

function parseModule(path: string, frontMatter: string, body: string): ModuleMeta {
  return {
    type: "module",
    id: required(readString(frontMatter, "id"), `${path} id`),
    categoryId: required(readString(frontMatter, "categoryId"), `${path} categoryId`),
    order: Number(required(readString(frontMatter, "order"), `${path} order`)),
    title: readLocalized(frontMatter, "title"),
    lessonIds: readStringArray(frontMatter, "lessonIds"),
    status: readStatus(frontMatter),
    body,
    path,
  };
}

function parseLesson(path: string, frontMatter: string, body: string): LessonMeta {
  return {
    type: "lesson",
    id: required(readString(frontMatter, "id"), `${path} id`),
    moduleId: required(readString(frontMatter, "moduleId"), `${path} moduleId`),
    categoryIds: readStringArray(frontMatter, "categoryIds"),
    title: readLocalized(frontMatter, "title"),
    covers: readStringArray(frontMatter, "covers"),
    objectives: readStringArray(frontMatter, "objectives"),
    prerequisites: readStringArray(frontMatter, "prerequisites"),
    estimatedMinutes: Number(required(readString(frontMatter, "estimatedMinutes"), `${path} estimatedMinutes`)),
    quizIds: readStringArray(frontMatter, "quizIds"),
    status: readStatus(frontMatter),
    body,
    path,
  };
}

function readStatus(frontMatter: string): LessonStatus {
  const status = readString(frontMatter, "status");
  return status === "draft" ? "draft" : "outline";
}

function readLocalized(frontMatter: string, key: string): LocalizedNullableText {
  const block = readIndentedBlock(frontMatter, key);
  return {
    en: required(readString(block, "en"), `${key}.en`),
    fr: readString(block, "fr"),
  };
}

function readStringArray(frontMatter: string, key: string): readonly string[] {
  const block = readIndentedBlock(frontMatter, key);
  if (block.trim() === "[]") {
    return [];
  }
  return block.split("\n")
    .map((line) => /^\s*-\s+(.+?)\s*$/.exec(line)?.[1])
    .filter((value): value is string => value !== undefined)
    .map(unquote)
    .filter((value): value is string => value !== null);
}

function readString(source: string, key: string): string | null {
  const match = new RegExp(`^${escapeRegExp(key)}:\\s*(.+?)\\s*$`, "m").exec(source);
  if (match === null) {
    return null;
  }
  return unquote(match[1]!);
}

function readIndentedBlock(frontMatter: string, key: string): string {
  const lines = frontMatter.split("\n");
  const start = lines.findIndex((line) => line.trim() === `${key}:`);
  if (start === -1) {
    return "";
  }
  const block: string[] = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    const line = lines[index] ?? "";
    if (/^\S/.test(line)) {
      break;
    }
    block.push(line.replace(/^  /, ""));
  }
  return block.join("\n");
}

function required(value: string | null, label: string): string {
  if (value === null || value === "") {
    throw new Error(`Missing required lesson metadata: ${label}`);
  }
  return value;
}

function unquote(value: string): string | null {
  const trimmed = value.trim();
  if (trimmed === "null") {
    return null;
  }
  const quoteMatch = /^"([\s\S]*)"$/.exec(trimmed);
  return quoteMatch?.[1] ?? trimmed;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
