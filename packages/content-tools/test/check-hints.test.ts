import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkHints, HintCheckError, runHintCheckerSelfTest } from "../src/check-hints.ts";
import { hintForQuestion, loadQuestionHints, questionHintsByQuestionId } from "../src/hints.ts";

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-hints-test-${testName}-`));
  try {
    await mkdir(path.join(root, "content/hints/b-001"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

function question(overrides: Record<string, unknown> = {}) {
  return {
    id: "B-001-001-001",
    bankId: "basic-2025-07-15",
    categoryId: "B-001",
    subsectionId: "B-001-001",
    sourceOrder: 1,
    text: {
      en: "Which fixture control keeps the station signal steady during a long contact?",
      fr: "Quelle commande fictive garde le signal de la station stable pendant un long contact?",
    },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Frequency stabilizer", fr: "Stabilisateur de fréquence" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Loose antenna", fr: "Antenne desserrée" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Bright display", fr: "Afficheur lumineux" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Long power cord", fr: "Long cordon d'alimentation" } },
    ],
    ...overrides,
  };
}

function hint(overrides: Record<string, unknown> = {}) {
  return {
    id: "HINT-B-001-001-001",
    questionId: "B-001-001-001",
    bankId: "basic-2025-07-15",
    status: "draft",
    hints: [
      {
        level: 1,
        en: "Think about the block that controls a steady radio-frequency rhythm.",
        fr: "Pensez au bloc qui contrôle un rythme radiofréquence régulier.",
      },
      {
        level: 2,
        en: "Set aside cables and displays; focus on the part that prevents frequency drift.",
        fr: "Écartez les câbles et les afficheurs; concentrez-vous sur la partie qui évite la dérive de fréquence.",
      },
    ],
    referenceSheetSection: null,
    licenseClass: "original",
    ...overrides,
  };
}

async function writeFixture(root: string, hintRecord = hint(), questionRecords = [question()]): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questionRecords, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/hints/b-001/b-001-001-001.json"), `${JSON.stringify(hintRecord, null, 2)}\n`, "utf8");
}

test("hint loader sorts records and exposes question lookup helpers", async () => {
  await withFixture("loader", async (root) => {
    await writeFixture(root);
    await writeFile(path.join(root, "content/hints/b-001/b-001-001-002.json"), `${JSON.stringify({ ...hint(), id: "HINT-B-001-001-002", questionId: "B-001-001-002" }, null, 2)}\n`, "utf8");

    const hints = await loadQuestionHints({ hintRoot: path.join(root, "content/hints") });

    assert.deepEqual(hints.map((record) => record.questionId), ["B-001-001-001", "B-001-001-002"]);
    assert.equal(questionHintsByQuestionId(hints).get("B-001-001-001")?.id, "HINT-B-001-001-001");
    assert.equal(hintForQuestion(hints, "missing"), null);
  });
});

test("hint check accepts valid EN/FR two-step hints", async () => {
  await withFixture("valid", async (root) => {
    await writeFixture(root);

    const report = await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      requireComplete: true,
    });

    assert.equal(report.hintFileCount, 1);
    assert.equal(report.hintQuestionCount, 1);
    assert.equal(report.checkedQuestionCount, 1);
  });
});

test("hint check rejects answer and question wording leakage", async () => {
  await withFixture("leakage", async (root) => {
    await writeFixture(root, hint({
      hints: [
        { level: 1, en: "A frequency stabilizer is the idea to look for.", fr: "Cherchez l'idée du contrôle de fréquence." },
        { level: 2, en: "Ask which fixture control keeps the station signal steady during a long contact.", fr: "Concentrez-vous sur la dérive." },
      ],
    }));

    await assert.rejects(
      () => checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      }),
      (error: unknown) => error instanceof HintCheckError
        && error.report.issues.some((issue) => issue.includes("correct answer text"))
        && error.report.issues.some((issue) => issue.includes("copies a long question fragment")),
    );
  });
});

test("hint checker self-test covers checker contract", async () => {
  await runHintCheckerSelfTest();
});
