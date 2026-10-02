import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { EXPECTED_HEADERS } from "../src/basic-importer.ts";
import {
  importAdvancedQuestionBank,
  parseAdvancedDelimitedQuestionBank,
} from "../src/advanced-importer.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));

function windows1252Bytes(text: string): Uint8Array {
  return Buffer.from(text, "latin1");
}

test("Advanced parser explicitly detects Windows-1252 legacy input when UTF-8 decoding fails", () => {
  const row = [
    "A-999-001-001",
    "Question",
    "Correct",
    "Wrong 1",
    "Wrong 2",
    "Wrong 3",
    "Question française",
    "Bonne réponse",
    "Mauvaise réponse 1",
    "Mauvaise réponse 2",
    "Mauvaise réponse 3",
  ].join(";");
  const parsed = parseAdvancedDelimitedQuestionBank(
    windows1252Bytes(`${EXPECTED_HEADERS.join(";")}\r\n${row}\r\n`),
    "windows-1252-fixture.txt",
  );

  assert.equal(parsed.encoding, "Windows-1252");
  assert.deepEqual(parsed.header, [...EXPECTED_HEADERS]);
  assert.equal(parsed.rows[0]?.fields[6], "Question française");
  assert.equal(parsed.rows[0]?.fields[7], "Bonne réponse");
});

test("imports and validates the committed Advanced 2025-02-04 source bank", async () => {
  const bank = await importAdvancedQuestionBank(REPO_ROOT);

  assert.equal(bank.manifest.bankId, "advanced-2025-02-04");
  assert.equal(bank.manifest.effectiveDate, "2025-02-04");
  assert.equal(bank.manifest.source.encoding, "UTF-8");
  assert.equal(bank.questions.length, 549);
  assert.equal(bank.subsections.length, 50);
  assert.equal(bank.categories.length, 7);
  assert.equal(bank.questions[0]?.id, "A-001-001-001");
  assert.equal(bank.questions.at(-1)?.id, "A-007-009-011");
  assert.equal(new Set(bank.questions.map((question) => question.id)).size, 549);
  assert.equal(
    bank.questions.flatMap((question) => [
      question.text.en,
      question.text.fr,
      ...question.answers.flatMap((answer) => [answer.text.en, answer.text.fr]),
    ]).filter((value) => value.length === 0).length,
    0,
  );
  assert.deepEqual(
    bank.categories.map((category) => [category.id, category.questionCount, category.subsectionCount, category.examQuestionCount]),
    [
      ["A-001", 54, 5, 5],
      ["A-002", 132, 12, 12],
      ["A-003", 66, 6, 6],
      ["A-004", 44, 4, 4],
      ["A-005", 99, 9, 9],
      ["A-006", 55, 5, 5],
      ["A-007", 99, 9, 9],
    ],
  );
  assert.deepEqual(
    bank.categories.map((category) => [category.id, category.name.fr, category.frenchNameStatus]),
    [
      ["A-001", null, "pending verification"],
      ["A-002", null, "pending verification"],
      ["A-003", null, "pending verification"],
      ["A-004", null, "pending verification"],
      ["A-005", null, "pending verification"],
      ["A-006", null, "pending verification"],
      ["A-007", null, "pending verification"],
    ],
  );
  for (const subsection of bank.subsections) {
    assert.ok(subsection.questionCount >= 10, `${subsection.id} has too few questions`);
    assert.ok(subsection.questionCount <= 11, `${subsection.id} has too many questions`);
  }
});
