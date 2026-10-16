import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { checkHints, HintCheckError, runHintCheckerSelfTest, slugForLessonHeading } from "../src/check-hints.ts";
import { requiredReferenceSheetSections } from "../src/check-reference-sheet.ts";
import { hintForQuestion, loadQuestionHints, questionHintsByQuestionId, referenceSheetSectionKeys, referenceSheetSectionLabels } from "../src/hints.ts";

const repoRoot = fileURLToPath(new URL("../../..", import.meta.url));

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-hints-test-${testName}-`));
  try {
    await mkdir(path.join(root, "content/hints/b-001"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m1-regulations-policies"), { recursive: true });
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
        en: "Frequency stays stable when the controlling part prevents drift during the contact.",
        fr: "La fréquence reste stable quand la partie de commande évite la dérive pendant le contact.",
      },
    ],
    lessonLink: { lessonId: "L-001-01", sectionAnchor: "shared-setup" },
    referenceSheetSection: null,
    licenseClass: "original",
    ...overrides,
  };
}

async function writeFixture(root: string, hintRecord = hint(), questionRecords = [question()]): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questionRecords, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/hints/b-001/b-001-001-001.json"), `${JSON.stringify(hintRecord, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/lessons/m1-regulations-policies/l-001-01.md"), `---\ntype: lesson\nid: L-001-01\n---\n# Fixture Lesson\n\n## Shared setup\n\nA fixture lesson section.\n`, "utf8");
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

test("hint loader reports parse errors with the file path and tolerates missing sort keys", async () => {
  await withFixture("loader-errors", async (root) => {
    const hintRoot = path.join(root, "content/hints");
    const badPath = path.join(hintRoot, "b-001/bad.json");
    await writeFile(badPath, "{not-json", "utf8");
    await assert.rejects(
      () => loadQuestionHints({ hintRoot }),
      (error: unknown) => error instanceof Error && error.message.includes(badPath) && error.message.includes("failed to parse JSON"),
    );

    await writeFile(badPath, `${JSON.stringify({ id: "HINT-B-001-001-999", licenseClass: "original" })}\n`, "utf8");
    await writeFile(path.join(hintRoot, "b-001/b-001-001-001.json"), `${JSON.stringify(hint())}\n`, "utf8");

    const hints = await loadQuestionHints({ hintRoot });
    assert.equal(hints.length, 2);
    assert.equal(hints.at(-1)?.questionId, "B-001-001-001");
  });
});

test("reference-sheet section keys stay aligned between schema, labels, and sheet headings", async () => {
  const schemaPath = path.join(repoRoot, "packages/schemas/hint.schema.json");
  const schema = JSON.parse(await readFile(schemaPath, "utf8")) as { properties: { referenceSheetSection: { enum: unknown[] } } };
  const schemaKeys = schema.properties.referenceSheetSection.enum.filter((value): value is string => typeof value === "string");

  assert.deepEqual(schemaKeys, [...referenceSheetSectionKeys]);
  assert.deepEqual(Object.keys(referenceSheetSectionLabels).sort(), [...referenceSheetSectionKeys].sort());
  assert.deepEqual(requiredReferenceSheetSections, referenceSheetSectionKeys.map((key) => `## ${referenceSheetSectionLabels[key].en}`));
});

test("lesson heading slugs match the GitHub-style lesson-link rules", () => {
  assert.equal(slugForLessonHeading("A  `B` <em>C</em>!"), "a--b-c");
  assert.equal(slugForLessonHeading("Reference facts: Authority and source roles"), "reference-facts-authority-and-source-roles");
});

test("hint check accepts valid EN/FR two-step hints", async () => {
  await withFixture("valid", async (root) => {
    await writeFixture(root);

    const report = await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });

    assert.equal(report.hintFileCount, 1);
    assert.equal(report.hintQuestionCount, 1);
    assert.equal(report.checkedQuestionCount, 1);
  });
});

test("hint check accepts one-level hints only with a reason and validates lesson links", async () => {
  await withFixture("single-level", async (root) => {
    const oneLevel = hint({
      hints: [{ level: 1, en: "Think about the broad setup before choosing.", fr: "Pensez au contexte général avant de choisir." }],
      singleLevelReason: "A second hint would name the deciding document for this recall question.",
    });
    await writeFixture(root, oneLevel);

    const report = await checkHints({
      hintRoot: path.join(root, "content/hints"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      lessonRoot: path.join(root, "content/lessons"),
      requireComplete: true,
    });
    assert.equal(report.hintQuestionCount, 1);
  });

  await withFixture("single-level-missing-reason", async (root) => {
    await writeFixture(root, hint({
      hints: [{ level: 1, en: "Think about the broad setup before choosing.", fr: "Pensez au contexte général avant de choisir." }],
    }));

    await assert.rejects(
      () => checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
      }),
      (error: unknown) => error instanceof HintCheckError
        && error.report.issues.some((issue) => issue.includes("singleLevelReason must be non-empty")),
    );
  });

  await withFixture("bad-lesson-link", async (root) => {
    await writeFixture(root, hint({ lessonLink: { lessonId: "L-001-01", sectionAnchor: "missing-section" } }));

    await assert.rejects(
      () => checkHints({
        hintRoot: path.join(root, "content/hints"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        lessonRoot: path.join(root, "content/lessons"),
      }),
      (error: unknown) => error instanceof HintCheckError
        && error.report.issues.some((issue) => issue.includes("lessonLink.sectionAnchor missing-section does not exist")),
    );
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
        lessonRoot: path.join(root, "content/lessons"),
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
