import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkExplanations, ExplanationCheckError } from "../src/check-explanations.ts";

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-explanations-${testName}-`));
  try {
    await mkdir(path.join(root, "content/explanations/b-005"), { recursive: true });
    await mkdir(path.join(root, "content/explanations/b-006"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m5-basic-electronics"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m6-feedlines-antennas"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

function question(overrides: Record<string, unknown> = {}) {
  return {
    id: "B-005-001-001",
    bankId: "basic-2025-07-15",
    categoryId: "B-005",
    subsectionId: "B-005-001",
    sourceOrder: 1,
    text: { en: "Fixture question?", fr: "Question exemple?" },
    answers: [
      { sourceIndex: 0, isCorrect: true, text: { en: "Correct answer", fr: "Bonne réponse" } },
      { sourceIndex: 1, isCorrect: false, text: { en: "Wrong answer", fr: "Mauvaise réponse" } },
      { sourceIndex: 2, isCorrect: false, text: { en: "Another wrong answer", fr: "Autre mauvaise réponse" } },
      { sourceIndex: 3, isCorrect: false, text: { en: "Long distractor choice with extra detail", fr: "Long choix" } },
    ],
    ...overrides,
  };
}

function lessonMarkdown(overrides: { id?: string; covers?: string[] } = {}): string {
  const id = overrides.id ?? "L-005-01";
  const covers = overrides.covers ?? ["B-005-001"];
  return `---
type: lesson
id: ${id}
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Fixture lesson"
  fr: null
covers:
${covers.map((subsectionId) => `  - ${subsectionId}`).join("\n")}
objectives:
  - "Use fixture objective."
prerequisites: []
estimatedMinutes: 10
quizIds: []
status: draft
---
# Fixture lesson
`;
}

function explanation(overrides: Record<string, unknown> = {}) {
  return {
    id: "EXP-B-005-001-001",
    questionId: "B-005-001-001",
    bankId: "basic-2025-07-15",
    status: "draft",
    body: {
      en: "Question B-005-001-001.\n\nWhy the distractors are wrong:\n- sourceIndex 1: \"Wrong answer\": This confuses the fixture principle.\n- sourceIndex 3: \"Long distractor choice…\": This documented short prefix still identifies the long choice.",
      fr: null,
    },
    citations: [
      { type: "lesson", id: "L-005-01" },
      { type: "question", id: "B-005-001-001" },
    ],
    licenseClass: "original",
    ...overrides,
  };
}

async function writeBaseFixture(root: string, overrides: { questions?: unknown[]; explanationRecord?: unknown; lesson?: string } = {}): Promise<void> {
  await writeFile(
    path.join(root, "content/generated/basic-2025-07-15/questions.json"),
    `${JSON.stringify(overrides.questions ?? [question()], null, 2)}\n`,
    "utf8",
  );
  await writeFile(path.join(root, "content/lessons/m5-basic-electronics/l-005-01.md"), overrides.lesson ?? lessonMarkdown(), "utf8");
  await writeFile(
    path.join(root, "content/explanations/b-005/b-005-001-001.json"),
    `${JSON.stringify(overrides.explanationRecord ?? explanation(), null, 2)}\n`,
    "utf8",
  );
}

async function runCheck(root: string, options: { categoryId?: string; moduleId?: string } = {}) {
  return checkExplanations({
    explanationRoot: path.join(root, "content/explanations"),
    questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
    lessonRoot: path.join(root, "content/lessons"),
    ...options,
  });
}

test("explanation check accepts valid schema, exact choice quotes, short prefixes, and lesson coverage", async () => {
  await withFixture("valid", async (root) => {
    await writeBaseFixture(root);

    const report = await runCheck(root);

    assert.equal(report.explanationFileCount, 1);
    assert.equal(report.explanationQuestionCount, 1);
    assert.equal(report.perChoiceNoteCount, 2);
    assert.equal(report.explainedQuestionCount, 1);
  });
});

test("explanation check rejects schema failures", async () => {
  await withFixture("schema", async (root) => {
    await writeBaseFixture(root, { explanationRecord: { ...explanation(), body: { en: "", fr: null } } });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("body must have non-empty en text")),
    );
  });
});

test("explanation check rejects a bank record whose correct sourceIndex is not zero", async () => {
  await withFixture("correct-source-index", async (root) => {
    await writeBaseFixture(root, {
      questions: [question({
        answers: [
          { sourceIndex: 0, isCorrect: false, text: { en: "Correct answer", fr: "Bonne réponse" } },
          { sourceIndex: 1, isCorrect: true, text: { en: "Wrong answer", fr: "Mauvaise réponse" } },
          { sourceIndex: 2, isCorrect: false, text: { en: "Another wrong answer", fr: "Autre mauvaise réponse" } },
          { sourceIndex: 3, isCorrect: false, text: { en: "Long distractor choice with extra detail", fr: "Long choix" } },
        ],
      })],
    });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("correct sourceIndex is 1, expected 0")),
    );
  });
});

test("explanation check rejects per-choice notes that do not start with the quoted official choice text", async () => {
  await withFixture("bad-quote", async (root) => {
    await writeBaseFixture(root, {
      explanationRecord: explanation({
        body: {
          en: "Question B-005-001-001.\n\n- sourceIndex 1: \"Different wrong answer\": This explains the mismatch.",
          fr: null,
        },
      }),
    });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("quoted choice") && issue.includes("Wrong answer")),
    );
  });
});

test("explanation check rejects empty per-choice note bodies", async () => {
  await withFixture("empty-note", async (root) => {
    await writeBaseFixture(root, {
      explanationRecord: explanation({
        body: {
          en: "Question B-005-001-001.\n\n- sourceIndex 1: \"Wrong answer\":   ",
          fr: null,
        },
      }),
    });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("per-choice note body must be non-empty")),
    );
  });
});

test("explanation check rejects generic filler phrases in per-choice notes", async () => {
  await withFixture("generic-note", async (root) => {
    await writeBaseFixture(root, {
      explanationRecord: explanation({
        body: {
          en: "Question B-005-001-001.\n\n- sourceIndex 1: \"Wrong answer\": This does not match the principle tested here.",
          fr: null,
        },
      }),
    });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("generic filler phrase")),
    );
  });
});

test("explanation check rejects duplicate normalized note bodies in three or more files", async () => {
  await withFixture("duplicate-note", async (root) => {
    const questions = [1, 2, 3].map((sourceOrder) => question({ id: `B-005-001-00${sourceOrder}`, sourceOrder }));
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questions, null, 2)}\n`, "utf8");
    await writeFile(path.join(root, "content/lessons/m5-basic-electronics/l-005-01.md"), lessonMarkdown(), "utf8");
    for (const sourceOrder of [1, 2, 3]) {
      const questionId = `B-005-001-00${sourceOrder}`;
      await writeFile(
        path.join(root, `content/explanations/b-005/${questionId.toLowerCase()}.json`),
        `${JSON.stringify(explanation({
          id: `EXP-${questionId}`,
          questionId,
          body: { en: `Question ${questionId}.\n\n- sourceIndex 1: \"Wrong answer\": Repeated note body for duplicate detection.`, fr: null },
          citations: [{ type: "lesson", id: "L-005-01" }, { type: "question", id: questionId }],
        }), null, 2)}\n`,
        "utf8",
      );
    }

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("DUPLICATE-NOTE") && issue.includes("3 files")),
    );
  });
});

test("explanation check rejects missing or non-covering lesson citations", async () => {
  await withFixture("lesson-citation", async (root) => {
    await writeBaseFixture(root, {
      explanationRecord: explanation({ citations: [{ type: "lesson", id: "L-005-99" }, { type: "question", id: "B-005-001-001" }] }),
    });

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError
        && error.report.issues.some((issue) => issue.includes("unknown lesson citation L-005-99"))
        && error.report.issues.some((issue) => issue.includes("no cited lesson covers B-005-001")),
    );
  });
});

test("explanation check supports category and module filters while full runs stay strict", async () => {
  await withFixture("filters", async (root) => {
    await writeBaseFixture(root);
    await writeFile(
      path.join(root, "content/explanations/b-006/b-006-001-001.json"),
      `${JSON.stringify({ ...explanation(), id: "EXP-B-006-001-001", questionId: "B-006-001-001", body: { en: "", fr: null } }, null, 2)}\n`,
      "utf8",
    );

    assert.equal((await runCheck(root, { categoryId: "B-005" })).explanationFileCount, 1);
    assert.equal((await runCheck(root, { moduleId: "M5" })).explanationFileCount, 1);
    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof ExplanationCheckError && error.report.issues.some((issue) => issue.includes("b-006-001-001.json") && issue.includes("body must have non-empty en text")),
    );
  });
});
