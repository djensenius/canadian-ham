import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkLessonOriginality, LessonOriginalityError } from "../src/check-lesson-originality.ts";

type FixtureQuestion = {
  id: string;
  text: { en: string };
  answers: Array<{ isCorrect: boolean; text: { en: string } }>;
};

async function withFixture(testName: string, run: (root: string) => Promise<void>): Promise<void> {
  const root = await mkdtemp(path.join(tmpdir(), `canadian-ham-originality-${testName}-`));
  try {
    await mkdir(path.join(root, "content/lessons"), { recursive: true });
    await mkdir(path.join(root, "content/generated/basic-2025-07-15"), { recursive: true });
    await run(root);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

function question(id: string, text: string, correctAnswer: string): FixtureQuestion {
  return {
    id,
    text: { en: text },
    answers: [
      { isCorrect: true, text: { en: correctAnswer } },
      { isCorrect: false, text: { en: "Distractor" } },
    ],
  };
}

async function writeFixture(root: string, questions: FixtureQuestion[], markdown: string): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questions, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/lessons/lesson.md"), markdown, "utf8");
}

async function runCheck(root: string) {
  return checkLessonOriginality({
    lessonRoot: path.join(root, "content/lessons"),
    questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
  });
}

test("originality check passes original numeric examples", async () => {
  await withFixture("valid", async (root) => {
    await writeFixture(root, [
      question("B-TEST-001", "If a 5 V circuit draws 2 A, what is the power?", "10 W"),
    ], "# Lesson\n\nA fresh example says a 5 V accessory draws 3 A, so P = 15 W.\n");

    const report = await runCheck(root);

    assert.equal(report.lessonFileCount, 1);
    assert.equal(report.issueCount, 0);
  });
});

test("originality check rejects integer-only question and answer numbers in one paragraph", async () => {
  await withFixture("integer-only", async (root) => {
    await writeFixture(root, [
      question("B-TEST-002", "A 12 volt circuit draws 3 amperes. What power is used?", "36 watts"),
    ], "# Lesson\n\nA worked example says a 12 V circuit drawing 3 A uses 36 W.\n");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-002" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check rejects unit-word bank scenarios such as two 500 ohm 1 W resistors yielding 2 W", async () => {
  await withFixture("unit-words", async (root) => {
    await writeFixture(root, [
      question("B-TEST-003", "When two 500-ohm 1-watt resistors are connected in series, what total power can be dissipated?", "2 watts"),
    ], "# Lesson\n\nIf two 500 ohm 1 W resistors share power properly, the pair can dissipate 2 W.\n");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-003" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check normalizes trailing zeros before comparing numeric values", async () => {
  await withFixture("trailing-zero", async (root) => {
    await writeFixture(root, [
      question("B-TEST-004", "A 470 ohm resistor has 0.020 A flowing through it. What voltage is across it?", "9.4 volts"),
    ], "# Lesson\n\nA resistor with 0.02 A through 470 ohms has 9.40 V across it.\n");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-004" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check rejects near-verbatim five-gram overlap in one paragraph", async () => {
  await withFixture("five-gram", async (root) => {
    await writeFixture(root, [
      question("B-TEST-005", "Two resistors are in parallel. Resistor A carries twice the current of resistor B, which means that:", "A has half the resistance of B"),
    ], "# Lesson\n\nIf resistor A carries twice the current of resistor B, then A has half the resistance of B.\n");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-005" && issue.issueType === "five-gram-overlap"),
    );
  });
});

test("originality check requires all question numbers and the answer value in the same paragraph or list item", async () => {
  await withFixture("negative-split", async (root) => {
    await writeFixture(root, [
      question("B-TEST-006", "A 12 volt circuit draws 3 amperes. What power is used?", "36 watts"),
    ], "# Lesson\n\nA practice circuit uses 12 V and 3 A.\n\nA different reminder says 36 W is a common supply size.\n");

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});
