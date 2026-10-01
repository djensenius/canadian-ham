import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parseLessonFrontMatter, validateDataAgainstSchema } from "./validate.mjs";

const fixturesDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "test/fixtures/valid");

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

test("generated bank manifest rejects importer contract drift", () => {
  const manifest = readValidFixture("generated-bank-manifest.json");
  assertSchemaRejects(
    { ...manifest, source: { ...manifest.source, lineEndings: "LF" } },
    "generated-bank-manifest.schema.json",
    "$.source.lineEndings: expected const \"CRLF\"",
  );
  assertSchemaRejects(
    { ...manifest, counts: { ...manifest.counts, questions: 983 } },
    "generated-bank-manifest.schema.json",
    "$.counts.questions: expected const 984",
  );
});

test("generated bank questions reject importer answer ordering and sourceOrder drift", () => {
  const [question] = readValidFixture("generated-bank-questions.json");
  assertSchemaRejects(
    [{ ...question, sourceOrder: 985 }],
    "generated-bank-questions.schema.json",
    "$[0].sourceOrder: expected number <= 984",
  );
  assertSchemaRejects(
    [{ ...question, answers: [{ ...question.answers[0], sourceIndex: 1 }, ...question.answers.slice(1)] }],
    "generated-bank-questions.schema.json",
    "$[0].answers[0].sourceIndex: expected const 0",
  );
});

test("generated bank categories reject authoritative count drift", () => {
  const categories = readValidFixture("generated-bank-categories.json");
  assertSchemaRejects(
    [{ ...categories[0], questionCount: 198 }, ...categories.slice(1)],
    "generated-bank-categories.schema.json",
    "$[0].questionCount: expected const 199",
  );
});

test("generated bank subsections reject non-importer lesson and title fields", () => {
  const [subsection] = readValidFixture("generated-bank-subsections.json");
  assertSchemaRejects(
    [{ ...subsection, lessonIds: ["L-001-01"] }],
    "generated-bank-subsections.schema.json",
    "$[0].lessonIds: expected at most 0 item(s)",
  );
  assertSchemaRejects(
    [{ ...subsection, title: { en: "Draft title", fr: null } }],
    "generated-bank-subsections.schema.json",
    "$[0].title.en: expected const null",
  );
});

function readValidFixture(fixture) {
  return JSON.parse(fs.readFileSync(path.join(fixturesDir, fixture), "utf8"));
}
