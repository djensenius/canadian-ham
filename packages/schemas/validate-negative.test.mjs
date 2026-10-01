import assert from "node:assert/strict";
import test from "node:test";

import { parseLessonFrontMatter, validateDataAgainstSchema } from "./validate.mjs";

const validLessonFrontMatter = {
  type: "lesson",
  id: "L-001-01",
  moduleId: "M1",
  categoryIds: ["B-001"],
  title: { en: "Lesson title", fr: null },
  covers: ["B-001-001"],
  objectives: ["Learn the contract"],
  prerequisites: [],
  estimatedMinutes: 1,
  quizIds: [],
  status: "draft",
};

const validModuleFrontMatter = {
  type: "module",
  id: "M1",
  categoryId: "B-001",
  order: 1,
  title: { en: "Module title", fr: null },
  lessonIds: ["L-001-01"],
  status: "draft",
};

const validProgressExport = {
  schema: "canadian-ham.progress-export",
  version: 1,
  exportedAt: "2026-01-02T03:04:05.000Z",
  bankId: "basic-2025-07-15",
  questionProgress: [],
  examAttempts: [],
  preferences: { practiceMode: "immediate", examTimerEnabled: false },
};

function assertSchemaRejects(data, schemaFile, expectedMessage) {
  const errors = validateDataAgainstSchema(data, schemaFile);
  assert(errors.some((error) => error.includes(expectedMessage)), `${schemaFile} errors did not include ${JSON.stringify(expectedMessage)}: ${errors.join("\n")}`);
}

test("semantic canonical timestamps reject impossible calendar/time values", () => {
  assertSchemaRejects(
    { ...validProgressExport, exportedAt: "2026-02-31T25:61:61.000Z" },
    "progress-export-v1.schema.json",
    "expected canonical UTC timestamp",
  );
});

test("lesson arrays that content tools require to be non-empty reject []", () => {
  for (const key of ["categoryIds", "covers", "objectives"]) {
    assertSchemaRejects(
      { ...validLessonFrontMatter, [key]: [] },
      "lesson-front-matter.schema.json",
      `$.${key}: expected at least 1 item(s)`,
    );
  }
});

test("module front matter rejects out-of-range order and empty lessonIds", () => {
  assertSchemaRejects(
    { ...validModuleFrontMatter, order: 9 },
    "lesson-module-front-matter.schema.json",
    "$.order: expected number <= 8",
  );
  assertSchemaRejects(
    { ...validModuleFrontMatter, lessonIds: [] },
    "lesson-module-front-matter.schema.json",
    "$.lessonIds: expected at least 1 item(s)",
  );
});

test("front matter parser rejects non-empty scalars without a space after ':'", () => {
  assert.throws(
    () => parseLessonFrontMatter("---\ntype: lesson\nid:L-001-01\n---\n", "bad.md"),
    /expected a space after ':'/,
  );
});

test("front matter parser rejects duplicate top-level keys", () => {
  assert.throws(
    () => parseLessonFrontMatter("---\ntype: lesson\ntype: lesson\n---\n", "bad.md"),
    /duplicate key type/,
  );
});

test("front matter parser rejects duplicate nested keys", () => {
  assert.throws(
    () => parseLessonFrontMatter("---\ntitle:\n  en: \"A\"\n  en: \"B\"\n---\n", "bad.md"),
    /duplicate nested key en/,
  );
});
