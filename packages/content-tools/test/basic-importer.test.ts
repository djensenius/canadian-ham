import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import {
  EXPECTED_HEADERS,
  EXPECTED_PRIVILEGE_ANSWER_TEXT,
  checkGeneratedFiles,
  findPositionDependentAnswerIssues,
  importBasicQuestionBank,
  parseDelimitedQuestionBank,
  writeGeneratedFiles,
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

const SYNTHETIC_CATEGORY_COUNTS = [
  { id: "B-001", questionCount: 199, subsectionCount: 25, examQuestionCount: 25 },
  { id: "B-002", questionCount: 99, subsectionCount: 9, examQuestionCount: 9 },
  { id: "B-003", questionCount: 199, subsectionCount: 21, examQuestionCount: 21 },
  { id: "B-004", questionCount: 63, subsectionCount: 6, examQuestionCount: 6 },
  { id: "B-005", questionCount: 142, subsectionCount: 13, examQuestionCount: 13 },
  { id: "B-006", questionCount: 140, subsectionCount: 13, examQuestionCount: 13 },
  { id: "B-007", questionCount: 87, subsectionCount: 8, examQuestionCount: 8 },
  { id: "B-008", questionCount: 55, subsectionCount: 5, examQuestionCount: 5 },
] as const;

type SyntheticRow = string[];

type SyntheticCategory = {
  id: string;
  name: { en: string; fr: string | null };
  frenchNameStatus: string;
  expectedQuestionCount: number;
  expectedSubsectionCount: number;
  examQuestionCount: number;
  nameSource: string;
};

function sha256Hex(bytes: Uint8Array): string {
  return createHash("sha256").update(bytes).digest("hex");
}

function subsectionQuestionCounts(questionCount: number, subsectionCount: number): number[] {
  const baseCount = Math.floor(questionCount / subsectionCount);
  const extraCount = questionCount % subsectionCount;
  return Array.from({ length: subsectionCount }, (_, index) => baseCount + (index < extraCount ? 1 : 0));
}

function buildSyntheticRows(): SyntheticRow[] {
  const rows: SyntheticRow[] = [];
  for (const category of SYNTHETIC_CATEGORY_COUNTS) {
    const categoryNumber = category.id.slice(2);
    const counts = subsectionQuestionCounts(category.questionCount, category.subsectionCount);
    if (category.id === "B-001") {
      while (counts[16]! < 10) {
        const donorIndex = counts.findIndex((count, index) => index !== 16 && count > 4);
        counts[donorIndex]! -= 1;
        counts[16]! += 1;
      }
    }
    for (const [subsectionIndex, questionsInSubsection] of counts.entries()) {
      const subsectionNumber = String(subsectionIndex + 1).padStart(3, "0");
      for (let questionIndex = 1; questionIndex <= questionsInSubsection; questionIndex += 1) {
        const questionNumber = String(questionIndex).padStart(3, "0");
        const id = `B-${categoryNumber}-${subsectionNumber}-${questionNumber}`;
        rows.push([
          id,
          `Question ${id}`,
          EXPECTED_PRIVILEGE_ANSWER_TEXT.get(id) ?? `Correct ${id}`,
          `Incorrect 1 ${id}`,
          `Incorrect 2 ${id}`,
          `Incorrect 3 ${id}`,
          `Question FR ${id}`,
          `Correct FR ${id}`,
          `Incorrect 1 FR ${id}`,
          `Incorrect 2 FR ${id}`,
          `Incorrect 3 FR ${id}`,
        ]);
      }
    }
  }
  return rows;
}

function syntheticExamFactsText(): string {
  const citations = [...EXPECTED_PRIVILEGE_ANSWER_TEXT.keys()].map((id) => `- ${id}`).join("\n");
  return `# Synthetic exam facts\n\n## Privileges for learning content\n\n${citations}\n\n## How to re-verify when ISED updates the bank\n`;
}

function buildSyntheticCategories(): SyntheticCategory[] {
  return SYNTHETIC_CATEGORY_COUNTS.map((category) => ({
    id: category.id,
    name: { en: `Category ${category.id}`, fr: null },
    frenchNameStatus: "pending verification",
    expectedQuestionCount: category.questionCount,
    expectedSubsectionCount: category.subsectionCount,
    examQuestionCount: category.examQuestionCount,
    nameSource: "synthetic test fixture",
  }));
}

async function writeSyntheticBankRoot(
  root: string,
  mutateRows?: (rows: SyntheticRow[]) => void,
  mutateCategories?: (categories: SyntheticCategory[]) => void,
): Promise<void> {
  const rows = buildSyntheticRows();
  mutateRows?.(rows);
  const sourceText = `${fixtureHeader()}${rows.map((row) => row.join(";")).join("\r\n")}\r\n`;
  const sourceBytes = utf8Bytes(sourceText);
  const sourceSha256 = sha256Hex(sourceBytes);
  const sourceDir = path.join(root, "content/sources/ised/basic-2025-07-15");

  await mkdir(path.join(sourceDir, "questions"), { recursive: true });
  await mkdir(path.join(root, "content"), { recursive: true });
  await mkdir(path.join(root, "docs"), { recursive: true });
  await writeFile(path.join(sourceDir, "questions/amat_basic_quest_delim.txt"), sourceBytes);
  await writeFile(path.join(sourceDir, "manifest.json"), `${JSON.stringify({
    bankEffectiveDate: "2025-07-15",
    files: [{
      path: "questions/amat_basic_quest_delim.txt",
      sourceUrl: "https://example.test/amat_basic_quest_delim.txt",
      sha256: sourceSha256,
      bytes: sourceBytes.byteLength,
      encoding: "UTF-8",
      lineEndings: "CRLF",
    }],
  }, null, 2)}\n`, "utf8");
  await writeFile(path.join(sourceDir, "SHA256SUMS"), `${sourceSha256}  questions/amat_basic_quest_delim.txt\n`, "utf8");
  const categories = buildSyntheticCategories();
  mutateCategories?.(categories);
  await writeFile(path.join(root, "content/categories.json"), `${JSON.stringify(categories, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "docs/exam-facts.md"), syntheticExamFactsText(), "utf8");
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

test("strict parser rejects BOMs, invalid UTF-8, bare newlines, bare CRs, wrong field counts, and CSV quotes", () => {
  const validRow = "B-999-001-001;Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3";
  assert.throws(
    () => parseDelimitedQuestionBank(new Uint8Array([0xef, 0xbb, 0xbf, ...utf8Bytes(`${fixtureHeader()}${validRow}\r\n`)]), "bom.txt"),
    /BOM/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(new Uint8Array([0xff]), "utf8.txt"),
    /invalid UTF-8/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${EXPECTED_HEADERS.join(";")}\n${validRow}\n`), "lf.txt"),
    /bare LF/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${validRow}\r`), "cr.txt"),
    /bare CR/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${validRow};extra\r\n`), "fields.txt"),
    /expected 11 fields, found 12/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}"B-999-001-001";Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3\r\n`), "quoted.txt"),
    /field is wrapped entirely in double quotes; this looks like CSV quoting/,
  );
  assert.throws(
    () => parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}B-999-001-001;Q;A ""quoted"" word;I1;I2;I3;QF;CF;IF1;IF2;IF3\r\n`), "doubled.txt"),
    /field contains doubled double quotes; this looks like CSV quote escaping/,
  );
});

test("parser preserves literal quote characters that are part of source wording", () => {
  const row = [
    "B-999-001-001",
    "Question",
    "Sporadic \"E\"",
    "\"CQ, CQ, CQ\" followed by the call sign of the desired station",
    "\"A\" has half the resistance of \"B\"",
    "Wrong 3",
    "Question FR",
    "La résistance \"A\" a une valeur deux fois moins élevée que celle de \"B\"",
    "Wrong 1 FR",
    "Wrong 2 FR",
    "Wrong 3 FR",
  ].join(";");
  const parsed = parseDelimitedQuestionBank(utf8Bytes(`${fixtureHeader()}${row}\r\n`), "quotes.txt");

  assert.equal(parsed.rows[0]?.fields[2], "Sporadic \"E\"");
  assert.equal(parsed.rows[0]?.fields[3], "\"CQ, CQ, CQ\" followed by the call sign of the desired station");
  assert.equal(parsed.rows[0]?.fields[4], "\"A\" has half the resistance of \"B\"");
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

test("checksum mismatch against SHA256SUMS fails before parsing", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-importer-"));
  try {
    const sourceDir = path.join(root, "content/sources/ised/basic-2025-07-15");
    const sourceText = `${fixtureHeader()}B-999-001-001;Q;C;I1;I2;I3;QF;CF;IF1;IF2;IF3\r\n`;
    const sourceBytes = utf8Bytes(sourceText);
    const sourceSha256 = sha256Hex(sourceBytes);
    await mkdir(path.join(sourceDir, "questions"), { recursive: true });
    await writeFile(path.join(sourceDir, "questions/amat_basic_quest_delim.txt"), sourceBytes);
    await writeFile(path.join(sourceDir, "manifest.json"), JSON.stringify({
      bankEffectiveDate: "2025-07-15",
      files: [{
        path: "questions/amat_basic_quest_delim.txt",
        sha256: sourceSha256,
        bytes: sourceBytes.byteLength,
        encoding: "UTF-8",
        lineEndings: "CRLF",
      }],
    }), "utf8");
    await writeFile(path.join(sourceDir, "SHA256SUMS"), "0000000000000000000000000000000000000000000000000000000000000000  questions/amat_basic_quest_delim.txt\n", "utf8");

    await assert.rejects(
      () => importBasicQuestionBank(root),
      /SHA256SUMS: missing line/,
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
  assert.deepEqual(
    bank.categories.map((category) => [category.id, category.name.fr, category.frenchNameStatus]),
    [
      ["B-001", "Règlements et politiques", "verified"],
      ["B-002", "Exploitation et procédures", "verified"],
      ["B-003", "Montage d'une station, pratique et sécurité", "verified"],
      ["B-004", "Composants des circuits", "verified"],
      ["B-005", "Éléments et théorie de l'électronique", "verified"],
      ["B-006", "Descentes d'antenne et systèmes d'antenne", "verified"],
      ["B-007", "Propagation des ondes radioélectriques", "verified"],
      ["B-008", "Brouillage et suppression", "verified"],
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
  const flaggedEnglishAndFrench = fixtureQuestion({
    id: "B-999-001-002",
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "All of the above", fr: "Toutes ces réponses" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "A and B", fr: "A et B" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Answer C", fr: "Réponse D" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Choice D", fr: "Aucune de ces réponses" } },
    ],
  });
  const flaggedFrenchOnly = fixtureQuestion({
    id: "B-999-001-004",
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Correct", fr: "Toutes les réponses ci-dessus" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Wrong 1", fr: "Aucune des réponses ci-dessus" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Wrong 2", fr: "A ou B" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Wrong 3", fr: "Wrong 3 FR" } },
    ],
  });
  const notFlagged = fixtureQuestion({
    id: "B-999-001-003",
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "the answer does", fr: "Les deux" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "answers a call", fr: "Wrong 1 FR" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "choice between", fr: "Wrong 2 FR" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "a and b", fr: "Wrong 3 FR" } },
    ],
  });

  const issues = findPositionDependentAnswerIssues([flaggedEnglishAndFrench, flaggedFrenchOnly, notFlagged]);
  assert.equal(issues.length, 11);
  assert.deepEqual(new Set(issues.map((issue) => issue.questionId)), new Set(["B-999-001-002", "B-999-001-004"]));
});

test("import fails on duplicate IDs, empty French fields, and position-dependent lint", async () => {
  const cases = [
    {
      name: "duplicate IDs",
      mutateRows: (rows: SyntheticRow[]) => {
        rows[1]![0] = rows[0]![0]!;
      },
      expected: /expected 0 duplicate IDs, found 1/,
    },
    {
      name: "empty French",
      mutateRows: (rows: SyntheticRow[]) => {
        rows[0]![6] = "";
      },
      expected: /expected 0 empty English\/French fields, found 1/,
    },
    {
      name: "position-dependent lint",
      mutateRows: (rows: SyntheticRow[]) => {
        rows[0]![2] = "Answers A";
      },
      expected: /position-dependent answer lint found 1 issue/,
    },
  ] as const;

  for (const fixtureCase of cases) {
    const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-importer-${fixtureCase.name.replace(/\W/g, "-")}-`));
    try {
      await writeSyntheticBankRoot(root, fixtureCase.mutateRows);
      await assert.rejects(
        () => importBasicQuestionBank(root),
        fixtureCase.expected,
      );
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  }
});

test("import fails with clear errors for invalid category French-name status combinations", async () => {
  const cases = [
    {
      name: "pending-with-name",
      mutateCategories: (categories: SyntheticCategory[]) => {
        categories[0]!.name.fr = "Nom en attente";
      },
      expected: /content\/categories\.json\[0\]\.name\.fr must be null while frenchNameStatus is pending verification/,
    },
    {
      name: "verified-with-null",
      mutateCategories: (categories: SyntheticCategory[]) => {
        categories[0]!.frenchNameStatus = "verified";
      },
      expected: /content\/categories\.json\[0\]\.name\.fr must be a string when frenchNameStatus is verified/,
    },
    {
      name: "empty-string",
      mutateCategories: (categories: SyntheticCategory[]) => {
        categories[0]!.name.fr = "";
      },
      expected: /content\/categories\.json\[0\]\.name\.fr must be null or a non-empty string/,
    },
    {
      name: "unknown-status",
      mutateCategories: (categories: SyntheticCategory[]) => {
        categories[0]!.frenchNameStatus = "machine translated";
      },
      expected: /content\/categories\.json\[0\]\.frenchNameStatus must be pending verification or verified/,
    },
  ] as const;

  for (const fixtureCase of cases) {
    const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-importer-${fixtureCase.name}-`));
    try {
      await writeSyntheticBankRoot(root, undefined, fixtureCase.mutateCategories);
      await assert.rejects(
        () => importBasicQuestionBank(root),
        fixtureCase.expected,
      );
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  }
});

test("check mode detects drift in generated output without touching committed generated files", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-importer-check-"));
  try {
    await writeSyntheticBankRoot(root);
    await writeGeneratedFiles(root);
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/categories.json"), "[]\n", "utf8");

    await assert.rejects(
      () => checkGeneratedFiles(root),
      /generated output is not up to date:[\s\S]*categories\.json: differs from regenerated output/,
    );
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
