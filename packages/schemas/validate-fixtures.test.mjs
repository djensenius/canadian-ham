import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { validateDataAgainstSchema } from "./validate.mjs";

const fixturesDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "test/fixtures");

const fixtureCases = [
  {
    name: "common question ID definition",
    schema: "common.schema.json#/$defs/questionId",
    fixture: "common-question-id.json",
    expectedInvalidSubstring: "expected string to match",
  },
  {
    name: "generated bank manifest",
    schema: "generated-bank-manifest.schema.json",
    fixture: "generated-bank-manifest.json",
    expectedInvalidSubstring: "expected const",
  },
  {
    name: "generated bank categories",
    schema: "generated-bank-categories.schema.json",
    fixture: "generated-bank-categories.json",
    expectedInvalidSubstring: "questionCount: expected const 199",
  },
  {
    name: "generated bank questions",
    schema: "generated-bank-questions.schema.json",
    fixture: "generated-bank-questions.json",
    expectedInvalidSubstring: "sourceOrder: expected number <= 984",
  },
  {
    name: "generated bank subsections",
    schema: "generated-bank-subsections.schema.json",
    fixture: "generated-bank-subsections.json",
    expectedInvalidSubstring: "questionCount: expected number >= 4",
  },
  {
    name: "subsection titles",
    schema: "subsection-titles.schema.json",
    fixture: "subsection-titles.json",
    expectedInvalidSubstring: "expected string to match",
  },
  {
    name: "lesson module front matter",
    schema: "lesson-module-front-matter.schema.json",
    fixture: "lesson-module-front-matter.json",
    expectedInvalidSubstring: "order: expected number <= 8",
  },
  {
    name: "lesson front matter",
    schema: "lesson-front-matter.schema.json",
    fixture: "lesson-front-matter.json",
    expectedInvalidSubstring: "categoryIds: expected at least 1 item",
  },
  {
    name: "explanation",
    schema: "explanation.schema.json",
    fixture: "explanation.json",
    expectedInvalidSubstring: "licenseClass: expected const",
  },
  {
    name: "progress export v1",
    schema: "progress-export-v1.schema.json",
    fixture: "progress-export-v1.json",
    expectedInvalidSubstring: "expected canonical UTC timestamp",
  },
  {
    name: "engine fixture",
    schema: "engine-fixture.schema.json",
    fixture: "engine-fixture.json",
    expectedInvalidSubstring: "expected exactly one oneOf branch to match",
  },
];

test("progress export v1: valid legacy Basic fixture without bankId fields validates", () => {
  const data = readJsonFixture("valid", "progress-export-v1-legacy-without-bankid.json");
  assert.deepEqual(validateDataAgainstSchema(data, "progress-export-v1.schema.json"), []);
});

test("progress export v1: valid Advanced fixture validates", () => {
  const data = readJsonFixture("valid", "progress-export-v1-advanced.json");
  assert.deepEqual(validateDataAgainstSchema(data, "progress-export-v1.schema.json"), []);
});

for (const fixtureCase of fixtureCases) {
  test(`${fixtureCase.name}: valid synthetic fixture validates`, () => {
    const data = readJsonFixture("valid", fixtureCase.fixture);
    assert.deepEqual(validateDataAgainstSchema(data, fixtureCase.schema), []);
  });

  test(`${fixtureCase.name}: invalid synthetic fixture rejects`, () => {
    const data = readJsonFixture("invalid", fixtureCase.fixture);
    const errors = validateDataAgainstSchema(data, fixtureCase.schema);
    assert(errors.length > 0, `${fixtureCase.schema} accepted invalid fixture ${fixtureCase.fixture}`);
    assert(
      errors.some((error) => error.includes(fixtureCase.expectedInvalidSubstring)),
      `${fixtureCase.schema} errors did not include ${JSON.stringify(fixtureCase.expectedInvalidSubstring)}:\n${errors.join("\n")}`,
    );
  });
}

function readJsonFixture(kind, fixture) {
  return JSON.parse(fs.readFileSync(path.join(fixturesDir, kind, fixture), "utf8"));
}
