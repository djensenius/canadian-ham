import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import {
  EXPECTED_HEADERS,
  EXPECTED_PRIVILEGE_ANSWER_TEXT,
  findPositionDependentAnswerIssues,
  importBasicQuestionBank,
  parseDelimitedQuestionBank,
} from "../src/basic-importer.ts";
import type { Question } from "../src/basic-importer.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));

function utf8Bytes(text: string): Uint8Array {
  return new TextEncoder().encode(text);
}

function fixtureHeader(): string {
  return `${EXPECTED_HEADERS.join(";")}\r\n`;
}

function fixtureQuestion(overrides: Partial<Question> = {}): Question {
  const base: Question = {
    id: "B-999-001-001",
    bankId: "basic-2025-07-15",
    categoryId: "B-999",
    subsectionId: "B-999-001",
    sourceOrder: 1,
    text: { en: "Question", fr: "Question FR" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Correct", fr: "Correct FR" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Wrong 1", fr: "Wrong 1 FR" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Wrong 2", fr: "Wrong 2 FR" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Wrong 3", fr: "Wrong 3 FR" } },
    ],
  };
  return { ...base, ...overrides };
}

test("strict parser accepts UTF-8 CRLF semicolon rows and trims header names only", () => {
  const row = [
    "B-999-001-001",
    " English question has spaces ",
    "Correct answer",
    "Wrong 1",
    "Wrong 2",
    "Wrong 3",
    " Question française ",
    "Bonne réponse",
    "Mauvaise 1",
    "Mauvaise 2",
    "Mauvaise 3",
  ].join(";");
  const parsed = parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${row}\r\n`), "fixture.txt");

  assert.deepEqual(parsed.header, [...EXPECTED_HEADERS]);
  assert.equal(parsed.rows.length, 1);
  assert.equal(parsed.rows[0]?.fields[1], " English question has spaces ");
  assert.equal(parsed.rows[0]?.fields[6], " Question française ");
});

test("strict parser rejects BOMs, bare newlines, wrong field counts, and CSV wrappers", () => {
  const validRow = "B-999-001-001;Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3";
  assert.throws(
    () => parseDelimitedQuestionBank(new Uint8Array([0xef, 0xbb, 0xbf, ...utf8Bytes(`${fixtureHeader()}${validRow}\r\n`)]), "bom.txt"),
    /BOM/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${EXPECTED_HEADERS.join(";")}\n${validRow}\n`), "lf.txt"),
    /bare LF/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${validRow};extra\r\n`), "fields.txt"),
    /expected 11 fields, found 12/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}"B-999-001-001";Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3\r\n`), "quoted.txt"),
    /quoted CSV fields are not supported/,
  );
});

test("parser preserves literal quote characters that are part of source wording", () => {
  const row = [
    "B-999-001-001",
    "Question",
    "\"A\" has half the resistance of \"B\"",
    "Wrong 1",
    "Wrong 2",
    "Wrong 3",
    "Question FR",
    "La résistance \"A\" a une valeur deux fois moins élevée que celle de \"B\"",
    "Wrong 1 FR",
    "Wrong 2 FR",
    "Wrong 3 FR",
  ].join(";");
  const parsed = parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${row}\r\n`), "quotes.txt");

  assert.equal(parsed.rows[0]?.fields[2], "\"A\" has half the resistance of \"B\"");
  assert.equal(parsed.rows[0]?.fields[7], "La résistance \"A\" a une valeur deux fois moins élevée que celle de \"B\"");
});

test("checksum mismatch against source manifest fails before parsing", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-importer-"));
  try {
    const sourceDir = path.join(root, "content/sources/ised/basic-2025-07-15");
    await mkdir(path.join(sourceDir, "questions"), { recursive: true });
    await mkdir(path.join(root, "content"), { recursive: true });
    await writeFile(path.join(sourceDir, "questions/amat_basic_quest_delim.txt"), `${fixtureHeader()}B-999-001-001;Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3\r\n`, "utf8");
    await writeFile(path.join(sourceDir, "manifest.json"), JSON.stringify({
      bankEffectiveDate: "2025-07-15",
      files: [{ path: "questions/amat_basic_quest_delim.txt", sha256: "0000000000000000000000000000000000000000000000000000000000000000" }],
    }), "utf8");
    await writeFile(path.join(sourceDir, "SHA256SUMS"), "0000000000000000000000000000000000000000000000000000000000000000  questions/amat_basic_quest_delim.txt\n", "utf8");
    await writeFile(path.join(root, "content/categories.json"), "[]\n", "utf8");

    await assert.rejects(
      () => importBasicQuestionBank(root),
      /SHA-256 mismatch against manifest\.json/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("imports and validates the committed Basic 2025 source bank", async () => {
  const bank = await importBasicQuestionBank(REPO_ROOT);

  assert.equal(bank.questions.length, 984);
  assert.equal(bank.subsections.length, 100);
  assert.equal(bank.categories.length, 8);
  assert.equal(bank.questions[0]?.id, "B-001-001-001");
  assert.equal(bank.questions.at(-1)?.id, "B-008-005-011");
  assert.equal(new Set(bank.questions.map((question) => question.id)).size, 984);
  assert.equal(
    bank.questions.flatMap((question) => [
      question.text.en,
      question.text.fr,
      ...question.answers.flatMap((answer) => [answer.text.en, answer.text.fr]),
    ]).filter((value) => value.length === 0).length,
    0,
  );
  assert.deepEqual(
    bank.categories.map((category) => [category.id, category.questionCount, category.subsectionCount]),
    [
      ["B-001", 199, 25],
      ["B-002", 99, 9],
      ["B-003", 199, 21],
      ["B-004", 63, 6],
      ["B-005", 142, 13],
      ["B-006", 140, 13],
      ["B-007", 87, 8],
      ["B-008", 55, 5],
    ],
  );
  for (const subsection of bank.subsections) {
    assert.ok(subsection.questionCount >= 4, `${subsection.id} has too few questions`);
    assert.ok(subsection.questionCount <= 11, `${subsection.id} has too many questions`);
  }
});

test("privilege citations in docs/exam-facts.md match imported correct answers", async () => {
  const [bank, examFacts] = await Promise.all([
    importBasicQuestionBank(REPO_ROOT),
    readFile(path.join(REPO_ROOT, "docs/exam-facts.md"), "utf8"),
  ]);
  const privilegeSection = examFacts.split("## Privileges for learning content")[1]?.split("## How to re-verify when ISED updates the bank")[0];
  assert.ok(privilegeSection, "exam-facts privilege section not found");
  const citedIds = [...new Set(privilegeSection.match(/B-\d{3}-\d{3}-\d{3}/g) ?? [])].toSorted();
  assert.deepEqual(citedIds, [...EXPECTED_PRIVILEGE_ANSWER_TEXT.keys()].toSorted());

  const questionsById = new Map(bank.questions.map((question) => [question.id, question]));
  for (const [questionId, expectedText] of EXPECTED_PRIVILEGE_ANSWER_TEXT.entries()) {
    assert.equal(questionsById.get(questionId)?.answers[0]?.text.en, expectedText);
  }
});

test("position-dependent answer lint flags fixed-choice wording and avoids known false positives", () => {
  const flagged = fixtureQuestion({
    id: "B-999-001-002",
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "All of the above", fr: "Correct FR" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "A and B", fr: "Wrong 1 FR" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Answer C", fr: "Wrong 2 FR" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Choice D", fr: "Wrong 3 FR" } },
    ],
  });
  const notFlagged = fixtureQuestion({
    id: "B-999-001-003",
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Both", fr: "Les deux" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "all amateur bands above 30 MHz", fr: "Wrong 1 FR" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Wrong 2", fr: "Wrong 2 FR" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Wrong 3", fr: "Wrong 3 FR" } },
    ],
  });

  const issues = findPositionDependentAnswerIssues([flagged, notFlagged]);
  assert.equal(issues.length, 4);
  assert.deepEqual(new Set(issues.map((issue) => issue.questionId)), new Set(["B-999-001-002"]));
});
