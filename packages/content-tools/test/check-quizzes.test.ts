import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkQuizzes, QuizCheckError } from "../src/check-quizzes.ts";

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-quizzes-${testName}-`));
  try {
    await mkdir(path.join(root, "content/lessons/module"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await mkdir(path.join(root, "content/quizzes"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

function lessonMarkdown(): string {
  return `---
type: lesson
id: L-TEST-01
moduleId: M5
categoryIds:
  - B-005
title:
  en: "Fixture lesson"
  fr: null
covers:
  - B-005-001
objectives:
  - "Use fixture objective."
prerequisites: []
estimatedMinutes: 10
quizIds:
  - QZ-L-TEST-01-A
status: draft
---
# Fixture lesson
`;
}

function questionsJson(): string {
  return `${JSON.stringify([
    { id: "B-005-001-001", subsectionId: "B-005-001" },
    { id: "B-005-002-001", subsectionId: "B-005-002" },
  ], null, 2)}\n`;
}

function quiz(overrides: Record<string, unknown> = {}): string {
  const value = {
    id: "QZ-L-TEST-01-A",
    lessonId: "L-TEST-01",
    officialQuestionIds: ["B-005-001-001"],
    conceptChecks: [
      {
        id: "QZ-L-TEST-01-A-C1",
        prompt: { en: "What is checked?", fr: null },
        choices: [
          { text: { en: "Correct", fr: null }, isCorrect: true },
          { text: { en: "Wrong", fr: null }, isCorrect: false },
        ],
        explanation: { en: "One choice is correct.", fr: null },
      },
    ],
    ...overrides,
  };
  return `${JSON.stringify(value, null, 2)}\n`;
}

async function writeBaseFixture(root: string, quizContent = quiz()): Promise<void> {
  await writeFile(path.join(root, "content/lessons/module/l-test-01.md"), lessonMarkdown(), "utf8");
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");
  await writeFile(path.join(root, "content/quizzes/QZ-L-TEST-01-A.json"), quizContent, "utf8");
}

async function runCheck(root: string) {
  return checkQuizzes({
    lessonRoot: path.join(root, "content/lessons"),
    questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
    quizRoot: path.join(root, "content/quizzes"),
  });
}

test("quiz check accepts a valid lesson quiz file", async () => {
  await withFixture("valid", async (root) => {
    await writeBaseFixture(root);

    const report = await runCheck(root);

    assert.equal(report.quizFileCount, 1);
    assert.equal(report.officialQuestionCount, 1);
    assert.equal(report.conceptCheckCount, 1);
  });
});

test("quiz check rejects unknown lesson IDs", async () => {
  await withFixture("unknown-lesson", async (root) => {
    await writeBaseFixture(root, quiz({ lessonId: "L-MISSING-01" }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("unknown lessonId")),
    );
  });
});

test("quiz check rejects official questions outside the lesson coverage", async () => {
  await withFixture("wrong-subsection", async (root) => {
    await writeBaseFixture(root, quiz({ officialQuestionIds: ["B-005-002-001"] }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("not covered")),
    );
  });
});

test("quiz check rejects concept checks without exactly one correct choice", async () => {
  await withFixture("two-correct", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "What is checked?", fr: null },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true },
            { text: { en: "Also correct", fr: null }, isCorrect: true },
          ],
          explanation: { en: "Only one choice should be correct.", fr: null },
        },
      ],
    }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("exactly one choice")),
    );
  });
});

test("quiz check rejects empty localized text", async () => {
  await withFixture("empty-text", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "", fr: null },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true },
            { text: { en: "Wrong", fr: null }, isCorrect: false },
          ],
          explanation: { en: "One choice is correct.", fr: null },
        },
      ],
    }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("prompt must have non-empty en text")),
    );
  });
});
