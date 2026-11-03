import assert from "node:assert/strict";
import { mkdtemp, cp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { EXPECTED_HEADERS } from "../src/basic-importer.ts";
import {
  importAdvancedQuestionBank,
  parseAdvancedDelimitedQuestionBank,
} from "../src/advanced-importer.ts";

const REPO_ROOT = fileURLToPath(new URL("../../../", import.meta.url));
const ADVANCED_SOURCE_RELATIVE_DIR = "content/sources/ised/advanced-2025-02-04";
const ADVANCED_SHA256SUMS_RELATIVE_PATH = `${ADVANCED_SOURCE_RELATIVE_DIR}/SHA256SUMS`;
const HAND_CATEGORIES_RELATIVE_PATH = "content/categories-advanced.json";

function windows1252Bytes(text: string): Uint8Array {
  return Buffer.from(text, "latin1");
}

async function withAdvancedImportFixture(mutator: (root: string) => Promise<void>): Promise<string> {
  const root = await mkdtemp(path.join(os.tmpdir(), "advanced-importer-"));
  await cp(path.join(REPO_ROOT, ADVANCED_SOURCE_RELATIVE_DIR), path.join(root, ADVANCED_SOURCE_RELATIVE_DIR), { recursive: true });
  await cp(path.join(REPO_ROOT, HAND_CATEGORIES_RELATIVE_PATH), path.join(root, HAND_CATEGORIES_RELATIVE_PATH));
  await mutator(root);
  return root;
}

async function assertImportRejects(mutator: (root: string) => Promise<void>, expectedMessage: RegExp): Promise<void> {
  const root = await withAdvancedImportFixture(mutator);
  try {
    await assert.rejects(() => importAdvancedQuestionBank(root), expectedMessage);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function readFixtureSha256Sums(root: string): Promise<string> {
  return readFile(path.join(root, ADVANCED_SHA256SUMS_RELATIVE_PATH), "utf8");
}

async function writeFixtureSha256Sums(root: string, text: string): Promise<void> {
  await writeFile(path.join(root, ADVANCED_SHA256SUMS_RELATIVE_PATH), text, "utf8");
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

test("Advanced SHA256SUMS rejects a malformed checksum line", async () => {
  await assertImportRejects(
    (root) => writeFixtureSha256Sums(root, "not-a-valid-sha-line\n"),
    /SHA256SUMS: line 1 must be '<sha256>  <path>'/,
  );
});

test("Advanced SHA256SUMS rejects duplicate paths", async () => {
  await assertImportRejects(async (root) => {
    const firstLine = (await readFixtureSha256Sums(root)).trimEnd().split("\n")[0]!;
    await writeFixtureSha256Sums(root, `${firstLine}\n${firstLine}\n`);
  }, /SHA256SUMS: duplicate checksum line for questions\/amat_adv_quest_delim\.txt/);
});

test("Advanced SHA256SUMS rejects paths not listed in the source manifest", async () => {
  await assertImportRejects(async (root) => {
    const original = await readFixtureSha256Sums(root);
    await writeFixtureSha256Sums(root, `${original}0000000000000000000000000000000000000000000000000000000000000000  questions/not-in-manifest.txt\n`);
  }, /SHA256SUMS: questions\/not-in-manifest\.txt is not listed in content\/sources\/ised\/advanced-2025-02-04\/manifest\.json/);
});

test("Advanced SHA256SUMS rejects checksum drift against the source manifest", async () => {
  await assertImportRejects(async (root) => {
    const lines = (await readFixtureSha256Sums(root)).trimEnd().split("\n");
    lines[0] = `0000000000000000000000000000000000000000000000000000000000000000  questions/amat_adv_quest_delim.txt`;
    await writeFixtureSha256Sums(root, `${lines.join("\n")}\n`);
  }, /SHA256SUMS: questions\/amat_adv_quest_delim\.txt expected manifest SHA-256/);
});

test("Advanced SHA256SUMS rejects a missing line for a manifest-listed file", async () => {
  await assertImportRejects(async (root) => {
    const [, ...remainingLines] = (await readFixtureSha256Sums(root)).trimEnd().split("\n");
    await writeFixtureSha256Sums(root, `${remainingLines.join("\n")}\n`);
  }, /SHA256SUMS: missing line for questions\/amat_adv_quest_delim\.txt/);
});

test("Advanced SHA256SUMS rejects a changed source file whose metadata is unchanged", async () => {
  // Only the file bytes change: SHA256SUMS and manifest.json still agree with each other,
  // so this fails only if the importer really hashes each manifest-listed file.
  await assertImportRejects(async (root) => {
    const readmePath = path.join(root, ADVANCED_SOURCE_RELATIVE_DIR, "questions", "readme_adv.txt");
    await writeFile(readmePath, Buffer.concat([await readFile(readmePath), Buffer.from("\n")]));
  }, /questions\/readme_adv\.txt: SHA-256 mismatch against/);
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
      ["A-001", "Théorie avancée", "verified"],
      ["A-002", "Notions avancées sur les composants et les circuits", "verified"],
      ["A-003", "Mesures", "verified"],
      ["A-004", "Alimentation", "verified"],
      ["A-005", "Émetteurs, modulation et traitement", "verified"],
      ["A-006", "Récepteurs", "verified"],
      ["A-007", "Descentes d'antenne - adaptation et systèmes d'antenne", "verified"],
    ],
  );
  for (const category of bank.categories) {
    assert.match(category.nameSource, /official French name verified from ISED CIR-3 §5\.3\.\d and the French Exam Generator/);
  }
  for (const subsection of bank.subsections) {
    assert.ok(subsection.questionCount >= 10, `${subsection.id} has too few questions`);
    assert.ok(subsection.questionCount <= 11, `${subsection.id} has too many questions`);
  }
});
