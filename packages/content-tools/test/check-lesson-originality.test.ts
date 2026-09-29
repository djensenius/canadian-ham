import assert from "node:assert/strict";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";

import { checkLessonOriginality, LessonOriginalityError } from "../src/check-lesson-originality.ts";

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

function questionsJson(): string {
  return `${JSON.stringify([
    {
      id: "B-TEST-001",
      text: { en: "If a dial marked in megahertz shows 3.525 MHz, what would it show in kilohertz?" },
      answers: [
        { isCorrect: true, text: { en: "3 525 kHz" } },
        { isCorrect: false, text: { en: "35.25 kHz" } },
      ],
    },
    {
      id: "B-TEST-002",
      text: { en: "What is the basic unit of electrical power?" },
      answers: [
        { isCorrect: true, text: { en: "The watt" } },
      ],
    },
  ], null, 2)}\n`;
}

async function writeFixture(root: string, markdown: string): Promise<void> {
  await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");
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
    await writeFixture(root, "# Lesson\n\nA fresh example converts 14.230 MHz to 14 230 kHz.\n");

    const report = await runCheck(root);

    assert.equal(report.lessonFileCount, 1);
    assert.equal(report.issueCount, 0);
  });
});

test("originality check rejects lesson text that reuses official numeric tokens with the correct answer value", async () => {
  await withFixture("invalid", async (root) => {
    await writeFixture(root, "# Lesson\n\nA worked example says 3.525 MHz equals 3 525 kHz.\n");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-001"),
    );
  });
});
