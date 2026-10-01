import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { checkLessonOriginality, LessonOriginalityError } from "../src/check-lesson-originality.ts";

const CHECK_SCRIPT = fileURLToPath(new URL("../src/check-lesson-originality.ts", import.meta.url));

type FixtureQuestion = {
  id: string;
  subsectionId?: string;
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

function question(id: string, text: string, correctAnswer: string, subsectionId = "B-005-001"): FixtureQuestion {
  return {
    id,
    subsectionId,
    text: { en: text },
    answers: [
      { isCorrect: true, text: { en: correctAnswer } },
      { isCorrect: false, text: { en: "Distractor" } },
    ],
  };
}

function lessonMarkdown(body: string, overrides: { categoryIds?: string[]; covers?: string[] } = {}): string {
  const categoryIds = overrides.categoryIds ?? ["B-005"];
  const covers = overrides.covers ?? ["B-005-001"];
  return `---
type: lesson
id: L-TEST-01
moduleId: M5
categoryIds:
${categoryIds.map((categoryId) => `  - ${categoryId}`).join("\n")}
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
${body}`;
}

async function writeFixture(root: string, questions: FixtureQuestion[], markdown: string): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), `${JSON.stringify(questions, null, 2)}\n`, "utf8");
  await writeFile(path.join(root, "content/lessons/lesson.md"), markdown, "utf8");
}

async function runCheck(root: string) {
  return checkLessonOriginality({
    lessonRoot: path.join(root, "content/lessons"),
    questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
    allowlistPath: path.join(root, "content/lessons/originality-allowlist.json"),
  });
}

test("originality check runs when invoked through a symlink", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-originality-cli-"));
  try {
    const linkedScript = path.join(root, "check-lesson-originality.ts");
    await symlink(CHECK_SCRIPT, linkedScript);

    const result = spawnSync(process.execPath, [linkedScript, path.join(root, "missing-lessons")], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /check-lesson-originality:/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("originality check --all fails when no lesson files are checked", async () => {
  const root = await mkdtemp(path.join(tmpdir(), "canadian-ham-originality-empty-all-"));
  try {
    const result = spawnSync(process.execPath, [CHECK_SCRIPT, "--all", `--lesson-root=${root}`], { encoding: "utf8" });

    assert.equal(result.status, 1);
    assert.match(result.stderr, /check-lesson-originality: no lesson Markdown files were checked/);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test("originality check passes original numeric examples", async () => {
  await withFixture("valid", async (root) => {
    await writeFixture(root, [
      question("B-TEST-001", "If a 5 V circuit draws 2 A, what is the power?", "10 W"),
    ], lessonMarkdown("# Lesson\n\nA fresh example says a 5 V accessory draws 3 A, so P = 15 W.\n"));

    const report = await runCheck(root);

    assert.equal(report.lessonFileCount, 1);
    assert.equal(report.issueCount, 0);
  });
});

test("originality check rejects integer-only question and answer numbers in one heading block", async () => {
  await withFixture("integer-only", async (root) => {
    await writeFixture(root, [
      question("B-TEST-002", "A 12 volt circuit draws 3 amperes. What power is used?", "36 watts"),
    ], lessonMarkdown("# Lesson\n\nA worked example says a 12 V circuit drawing 3 A uses 36 W.\n"));

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
    ], lessonMarkdown("# Lesson\n\nIf two 500 ohm 1 W resistors share power properly, the pair can dissipate 2 W.\n"));

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
    ], lessonMarkdown("# Lesson\n\nA resistor with 0.02 A through 470 ohms has 9.40 V across it.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-004" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check normalizes number words and unit suffixes attached to numbers", async () => {
  await withFixture("number-words-unit-suffix", async (root) => {
    await writeFixture(root, [
      question("B-TEST-005", "Ten equal 100 ohm resistors are connected in parallel. What is the total resistance?", "10 ohms"),
      question("B-TEST-006", "What is the second harmonic of a 1.5 kHz signal?", "3 kHz"),
    ], lessonMarkdown("# Lesson\n\nTen equal 100Ω resistors in parallel have a total of 10Ω. A separate note says 1.5kHz doubled is 3kHz.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-005" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-006" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check rejects round-1 worked examples split across paragraph and bullets in one heading block", async () => {
  await withFixture("heading-block-regression", async (root) => {
    await writeFixture(root, [
      question("B-TEST-007", "Four 100 ohm resistors are connected in parallel across 12 volts. What total current flows?", "480 mA"),
    ], lessonMarkdown(`# Lesson

### Worked example: four 100 ohm resistors in parallel

Four equal 100 ohm resistors are wired in parallel across 12 V.

- Equivalent resistance = 100 / 4 = 25 ohms.
- Current = E / R = 12 / 25 = 0.48 A = 480 mA.
`));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-007" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("originality check does not join numeric examples across different headings", async () => {
  await withFixture("negative-split", async (root) => {
    await writeFixture(root, [
      question("B-TEST-008", "A 12 volt circuit draws 3 amperes. What power is used?", "36 watts"),
    ], lessonMarkdown("# Lesson\n\n## Practice circuit\n\nA practice circuit uses 12 V and 3 A.\n\n## Supply reminder\n\nA different reminder says 36 W is a common supply size.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality uses lesson categoryIds rather than only covered subsections", async () => {
  await withFixture("category-scope", async (root) => {
    await writeFixture(root, [
      question("B-TEST-009", "A 24 volt circuit draws 2 amperes. What power is used?", "48 watts", "B-005-999"),
    ], lessonMarkdown("# Lesson\n\nA worked example says a 24 V circuit drawing 2 A uses 48 W.\n", { covers: ["B-005-001"] }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-009" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality does not compare against questions outside the lesson categories", async () => {
  await withFixture("outside-category", async (root) => {
    await writeFixture(root, [
      question("B-TEST-010", "A 24 volt circuit draws 2 amperes. What power is used?", "48 watts", "B-006-001"),
    ], lessonMarkdown("# Lesson\n\nThis original example uses 24 V and 2 A to get 48 W without copying the other category wording.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("five-gram originality runs against the whole bank", async () => {
  await withFixture("whole-bank-five-gram", async (root) => {
    await writeFixture(root, [
      question("B-TEST-011", "Which antenna part keeps the feed line shield away from RF current?", "A choke balun", "B-006-001"),
    ], lessonMarkdown("# Lesson\n\nWhich antenna part keeps the feed line shield away from RF current? A choke balun.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-011" && issue.issueType === "five-gram-overlap"),
    );
  });
});

test("five-gram originality rejects an eight-word shared run at the threshold boundary", async () => {
  await withFixture("longest-run-boundary", async (root) => {
    await writeFixture(root, [
      question("B-TEST-012", "What term describes the ability of an instrument to display values that are true to reality?", "Accuracy"),
    ], lessonMarkdown("# Lesson\n\nA meter lesson mentions the ability of an instrument to display values during calibration.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-012" && issue.issueType === "five-gram-overlap" && issue.longestSharedWordRun === 8),
    );
  });
});

test("five-gram originality rejects a case at the 40 percent ratio boundary", async () => {
  await withFixture("five-gram-ratio-boundary", async (root) => {
    await writeFixture(root, [
      question("B-TEST-013", "alpha beta gamma delta epsilon zeta eta theta omega psi chi phi upsilon", "tau"),
    ], lessonMarkdown("# Lesson\n\nalpha beta gamma delta epsilon zeta with original bridge text, then omega psi chi phi upsilon tau.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-013" && issue.issueType === "five-gram-overlap" && issue.sharedFiveGramRatio === 0.4),
    );
  });
});

test("five-gram originality allows a case just below the ratio threshold", async () => {
  await withFixture("five-gram-under-ratio", async (root) => {
    await writeFixture(root, [
      question("B-TEST-014", "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu", "nu"),
    ], lessonMarkdown("# Lesson\n\nalpha beta gamma delta epsilon zeta eta then the original explanation changes direction.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});
