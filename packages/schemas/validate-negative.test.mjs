import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parseLessonFrontMatter, selectOneOfBranchByConstDiscriminator, validateDataAgainstSchema } from "./validate.mjs";

const schemasDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(schemasDir, "../..");
const validFixturesDir = path.join(schemasDir, "test/fixtures/valid");
const invalidFixturesDir = path.join(schemasDir, "test/fixtures/invalid");

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

test("progress export schema rejects Basic bankId with Advanced question progress", () => {
  assertSchemaRejects(
    readInvalidFixture("progress-export-v1-mixed-basic-bank-advanced-question.json"),
    "progress-export-v1.schema.json",
    "expected exactly one oneOf branch to match",
  );
});

test("progress export schema rejects Advanced bankId with Basic exam items and breakdowns", () => {
  assertSchemaRejects(
    readInvalidFixture("progress-export-v1-mixed-advanced-bank-basic-exam.json"),
    "progress-export-v1.schema.json",
    "expected exactly one oneOf branch to match",
  );
});

const basicLessonQuizWithAdvancedQuestion = {
  id: "lesson-quiz-1",
  quizId: "QZ-L-005-01-A",
  lessonId: "L-005-01",
  submittedAt: "2026-01-02T03:45:00.000Z",
  correct: 1,
  total: 1,
  percent: 100,
  officialQuestionIds: ["A-001-001-001"],
  incorrectOfficialQuestionIds: [],
  incorrectConceptCheckIds: [],
};

test("progress export schema rejects Basic lesson quizzes that reference Advanced questions", () => {
  assertSchemaRejects(
    { ...validProgressExport, lessonQuizAttempts: [basicLessonQuizWithAdvancedQuestion] },
    "progress-export-v1.schema.json",
    "expected exactly one oneOf branch to match",
  );
});

test("progress export schema rejects invalid answered-with-help fields", () => {
  assertSchemaRejects(
    readInvalidFixture("progress-export-v1-answered-with-help-non-boolean.json"),
    "progress-export-v1.schema.json",
    "$.questionProgress[0].lastAnsweredWithHelp: expected type \"boolean\"",
  );
  assertSchemaRejects(
    readInvalidFixture("progress-export-v1-recent-answered-with-help-too-long.json"),
    "progress-export-v1.schema.json",
    "$.questionProgress[0].recentAnsweredWithHelp: expected at most 5 item(s)",
  );
});

test("progress export schema rejects Advanced exports that carry lesson data", () => {
  const advancedExport = { ...validProgressExport, bankId: "advanced-2025-02-04" };
  assertSchemaRejects(
    { ...advancedExport, lessonQuizAttempts: [{ ...basicLessonQuizWithAdvancedQuestion, officialQuestionIds: ["B-005-001-001"] }] },
    "progress-export-v1.schema.json",
    "expected exactly one oneOf branch to match",
  );
  assertSchemaRejects(
    { ...advancedExport, lessonProgress: [{ lessonId: "L-005-01", readAt: "2026-01-02T03:30:00.000Z", readCount: 1 }] },
    "progress-export-v1.schema.json",
    "expected exactly one oneOf branch to match",
  );
});

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

test("generated bank categories reject a French name while verification is pending", () => {
  const categories = readValidFixture("generated-bank-categories.json");
  const index = categories.findIndex((category) => category.frenchNameStatus === "pending verification");
  assert(index >= 0, "valid categories fixture needs a pending category");
  categories[index] = { ...categories[index], name: { ...categories[index].name, fr: "Nom provisoire" } };
  assertSchemaRejects(categories, "generated-bank-categories.schema.json", `$[${index}].name.fr: expected const null, got "Nom provisoire"`);
});

test("generated bank categories require verified French names to be non-empty", () => {
  assertSchemaRejects(
    readInvalidFixture("generated-bank-categories-verified-null.json"),
    "generated-bank-categories.schema.json",
    "$[0].name.fr: expected type \"string\", got null",
  );
  assertSchemaRejects(
    readInvalidFixture("generated-bank-categories-verified-empty.json"),
    "generated-bank-categories.schema.json",
    "$[0].name.fr: expected string length >= 1",
  );
});

test("generated Advanced bank categories reject a French name when marked pending", () => {
  const categories = readProjectJson("content/generated/advanced-2025-02-04/categories.json");
  categories[0] = { ...categories[0], frenchNameStatus: "pending verification" };
  assertSchemaRejects(categories, "generated-bank-categories.schema.json", "$[0].name.fr: expected const null, got \"Théorie avancée\"");
});

test("generated Advanced bank categories require verified French names to be non-empty", () => {
  const categories = readProjectJson("content/generated/advanced-2025-02-04/categories.json");
  assertSchemaRejects(
    [{ ...categories[0], name: { ...categories[0].name, fr: null } }, ...categories.slice(1)],
    "generated-bank-categories.schema.json",
    "$[0].name.fr: expected type \"string\", got null",
  );
  assertSchemaRejects(
    [{ ...categories[0], name: { ...categories[0].name, fr: "" } }, ...categories.slice(1)],
    "generated-bank-categories.schema.json",
    "$[0].name.fr: expected string length >= 1",
  );
});

test("generated bank categories reject duplicate and reordered category IDs", () => {
  assertSchemaRejects(
    readInvalidFixture("generated-bank-categories-duplicate-id.json"),
    "generated-bank-categories.schema.json",
    "$[1].id: expected const \"B-002\"",
  );
  assertSchemaRejects(
    readInvalidFixture("generated-bank-categories-reordered.json"),
    "generated-bank-categories.schema.json",
    "$[0].id: expected const \"B-001\"",
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

test("hint schema rejects each ladder constraint independently", () => {
  const hint = readValidFixture("hint.json");
  assertSchemaRejects(
    { ...hint, hints: [{ ...hint.hints[0], level: 2 }, hint.hints[1]] },
    "hint.schema.json",
    "$.hints[0].level: expected const 1",
  );
  assertSchemaRejects(
    { ...hint, hints: [hint.hints[0]] },
    "hint.schema.json",
    "expected exactly one oneOf branch to match",
  );
  assertSchemaRejects(
    { ...hint, hints: [] },
    "hint.schema.json",
    "$.hints: expected at least 1 item(s)",
  );
  assertSchemaRejects(
    { ...hint, singleLevelReason: "Only for one-level hints." },
    "hint.schema.json",
    "expected exactly one oneOf branch to match",
  );
  assertSchemaRejects(
    { ...hint, lessonLink: { sectionAnchor: "how-these-rules-fit-together" } },
    "hint.schema.json",
    "$.lessonLink: missing required property lessonId",
  );
  assertSchemaRejects(
    { ...hint, lessonLink: { lessonId: "NOT-A-LESSON" } },
    "hint.schema.json",
    "$.lessonLink.lessonId: expected string to match",
  );
  assertSchemaRejects(
    { ...hint, referenceSheetSection: "unknown-section" },
    "hint.schema.json",
    "$.referenceSheetSection: expected one of",
  );
  assertSchemaRejects(
    { ...hint, licenseClass: "copied" },
    "hint.schema.json",
    "$.licenseClass: expected const",
  );
});

function readValidFixture(fixture) {
  return JSON.parse(fs.readFileSync(path.join(validFixturesDir, fixture), "utf8"));
}

function readInvalidFixture(fixture) {
  return JSON.parse(fs.readFileSync(path.join(invalidFixturesDir, fixture), "utf8"));
}

function readProjectJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(projectRoot, relativePath), "utf8"));
}

test("oneOf discriminator shortcut applies only to a required const property in every branch", () => {
  const a = { type: "object", required: ["kind"], properties: { kind: { const: "a" }, n: { type: "number" } } };
  const b = { type: "object", required: ["kind"], properties: { kind: { const: "b" }, n: { type: "string" } } };
  assert.equal(selectOneOfBranchByConstDiscriminator([a, b], { kind: "b", n: "x" }), b);

  // Not required in every branch: no shortcut, so plain oneOf evaluation applies.
  const looseA = { type: "object", properties: { kind: { const: "a" } } };
  const looseB = { type: "object", required: ["kind"], properties: { kind: { const: "b" } } };
  assert.equal(selectOneOfBranchByConstDiscriminator([looseA, looseB], { kind: "a" }), null);

  // Const in only one branch: no shortcut.
  const noConst = { type: "object", required: ["kind"], properties: { kind: { type: "string" } } };
  assert.equal(selectOneOfBranchByConstDiscriminator([a, noConst], { kind: "a" }), null);
});

test("lesson-quiz help IDs are optional sorted unique official subsets in attempts and sync rows", () => {
  const fixture = JSON.parse(fs.readFileSync(path.join(projectRoot, "fixtures/lesson-quiz-help.json"), "utf8"));
  for (const ids of [undefined, ...fixture.validHelpIds, ...fixture.invalidHelpIds]) {
    const attempt = { ...fixture.attempt, ...(ids === undefined ? {} : { answeredWithHelpIds: ids }) };
    const exports = [
      { ...validProgressExport, lessonQuizAttempts: [attempt] },
      { ...validProgressExport, syncDeviceRows: { questionProgress: [], examAttempts: [], lessonProgress: [], lessonQuizAttempts: [{ deviceId: "web", attempt }], morseCourseProgress: [] } },
    ];
    for (const data of exports) {
      const errors = validateDataAgainstSchema(data, "progress-export-v1.schema.json");
      assert.equal(errors.length === 0, ids === undefined || fixture.validHelpIds.includes(ids), errors.join("\n"));
    }
  }
});
