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

function lessonMarkdown(overrides: { id?: string; quizIds?: string[]; covers?: string[] } = {}): string {
  const id = overrides.id ?? "L-TEST-01";
  const quizIds = overrides.quizIds ?? ["QZ-L-TEST-01-A"];
  const covers = overrides.covers ?? ["B-005-001"];
  const quizIdLines = quizIds.length === 0 ? "quizIds: []" : `quizIds:\n${quizIds.map((quizId) => `  - ${quizId}`).join("\n")}`;
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
${quizIdLines}
status: draft
---
# Fixture lesson
`;
}

function questionsJson(): string {
  return `${JSON.stringify([
    {
      id: "B-005-001-001",
      subsectionId: "B-005-001",
      text: { en: "Which fixture value should be selected for the calibration step?", fr: null },
      answers: [
        { isCorrect: true, text: { en: "Use the calibrated reference value", fr: null } },
        { isCorrect: false, text: { en: "Use an unrelated guess", fr: null } },
      ],
    },
    {
      id: "B-005-002-001",
      subsectionId: "B-005-002",
      text: { en: "Which outside fixture value belongs to another subsection?", fr: null },
      answers: [
        { isCorrect: true, text: { en: "Use the other subsection value", fr: null } },
        { isCorrect: false, text: { en: "Use the first subsection value", fr: null } },
      ],
    },
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
          { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
          { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
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

test("quiz check accepts an official-only quiz with an empty conceptChecks array", async () => {
  await withFixture("official-only", async (root) => {
    await writeBaseFixture(root, quiz({ conceptChecks: [] }));

    const report = await runCheck(root);

    assert.equal(report.quizFileCount, 1);
    assert.equal(report.officialQuestionCount, 1);
    assert.equal(report.conceptCheckCount, 0);
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

test("quiz check rejects concept checks that overlap official questions in the same quiz", async () => {
  await withFixture("official-overlap", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "Which fixture value should be selected for the calibration step?", fr: null },
          choices: [
            { text: { en: "Use the calibrated reference value", fr: null }, isCorrect: true, feedback: { en: "This duplicates the keyed official answer.", fr: null } },
            { text: { en: "Use an unrelated guess", fr: null }, isCorrect: false, feedback: { en: "This ignores the reference.", fr: null } },
          ],
          explanation: { en: "The concept check restates the fixture official item.", fr: null },
        },
      ],
    }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("CONCEPT-CHECK OVERLAP") && issue.includes("official question B-005-001-001")),
    );
  });
});

test("quiz check rejects concept checks that overlap lesson Try-it lines", async () => {
  await withFixture("try-it-overlap", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "What is checked?", fr: null },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
          ],
          explanation: { en: "One choice is correct.", fr: null },
        },
      ],
    }));
    await writeFile(
      path.join(root, "content/lessons/module/l-test-01.md"),
      `${lessonMarkdown()}\n## Try it\n\n1. What is checked? Correct\n`,
      "utf8",
    );

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("CONCEPT-CHECK OVERLAP") && issue.includes("Try-it line 1")),
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
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Also correct", fr: null }, isCorrect: true, feedback: { en: "This creates an invalid second key.", fr: null } },
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
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
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

test("quiz check accepts non-empty French localized text", async () => {
  await withFixture("french-text", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "What is checked?", fr: "Que vérifie-t-on?" },
          choices: [
            { text: { en: "Correct", fr: "Correct" }, isCorrect: true, feedback: { en: "This matches.", fr: "Ce choix convient." } },
            { text: { en: "Wrong", fr: "Incorrect" }, isCorrect: false, feedback: { en: "This does not match.", fr: "Ce choix ne convient pas." } },
          ],
          explanation: { en: "One choice is correct.", fr: "Un choix est correct." },
        },
      ],
    }));

    const report = await runCheck(root);

    assert.equal(report.conceptCheckCount, 1);
  });
});

test("quiz check rejects empty French localized text", async () => {
  await withFixture("empty-french-text", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "What is checked?", fr: "" },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
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

test("quiz check rejects missing French localized text", async () => {
  await withFixture("missing-french-text", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "What is checked?" },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
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

test("quiz check rejects missing quiz files referenced by lesson front matter", async () => {
  await withFixture("missing-quiz-file", async (root) => {
    await writeFile(path.join(root, "content/lessons/module/l-test-01.md"), lessonMarkdown(), "utf8");
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("missing quiz file")),
    );
  });
});

test("quiz check rejects duplicate quizIds across lessons", async () => {
  await withFixture("duplicate-quiz-id-lessons", async (root) => {
    await writeBaseFixture(root);
    await writeFile(path.join(root, "content/lessons/module/l-test-02.md"), lessonMarkdown({ id: "L-TEST-02" }), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("duplicate quizId")),
    );
  });
});

test("quiz check rejects duplicate concept-check IDs", async () => {
  await withFixture("duplicate-concept-check", async (root) => {
    await writeBaseFixture(root, quiz({
      conceptChecks: [
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "First?", fr: null },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
          ],
          explanation: { en: "First explanation.", fr: null },
        },
        {
          id: "QZ-L-TEST-01-A-C1",
          prompt: { en: "Second?", fr: null },
          choices: [
            { text: { en: "Correct", fr: null }, isCorrect: true, feedback: { en: "This matches the fixture condition.", fr: null } },
            { text: { en: "Wrong", fr: null }, isCorrect: false, feedback: { en: "This misses the fixture condition.", fr: null } },
          ],
          explanation: { en: "Second explanation.", fr: null },
        },
      ],
    }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("duplicate concept-check id")),
    );
  });
});

test("quiz check rejects duplicate official question IDs once per quiz", async () => {
  await withFixture("duplicate-official-question", async (root) => {
    await writeBaseFixture(root, quiz({ officialQuestionIds: ["B-005-001-001", "B-005-001-001"] }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => {
        if (!(error instanceof QuizCheckError)) {
          return false;
        }
        const duplicateIssues = error.report.issues.filter((issue) => issue.includes("duplicate official question id B-005-001-001"));
        return duplicateIssues.length === 1;
      },
    );
  });
});

test("quiz check rejects unknown official question IDs", async () => {
  await withFixture("unknown-official-question", async (root) => {
    await writeBaseFixture(root, quiz({ officialQuestionIds: ["B-005-999-001"] }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("unknown official question id")),
    );
  });
});

test("quiz check rejects orphan quiz files that no lesson references", async () => {
  await withFixture("orphan-quiz", async (root) => {
    await writeFile(path.join(root, "content/lessons/module/l-test-01.md"), lessonMarkdown({ quizIds: [] }), "utf8");
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");
    await writeFile(path.join(root, "content/quizzes/QZ-L-TEST-01-A.json"), quiz(), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("not referenced by any lesson front matter")),
    );
  });
});

test("quiz check does not also report missing quiz file when a referenced quiz has shape failures", async () => {
  await withFixture("shape-failure-not-missing", async (root) => {
    await writeFile(path.join(root, "content/lessons/module/l-test-01.md"), lessonMarkdown(), "utf8");
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");
    await writeFile(path.join(root, "content/quizzes/QZ-L-TEST-01-A.json"), "[]\n", "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError
        && error.report.issues.some((issue) => issue.includes("quiz file must contain a JSON object"))
        && !error.report.issues.some((issue) => issue.includes("missing quiz file")),
    );
  });
});

test("quiz check validates unknown official IDs even when lessonId is unknown", async () => {
  await withFixture("unknown-official-with-unknown-lesson", async (root) => {
    await writeBaseFixture(root, quiz({ lessonId: "L-MISSING-01", officialQuestionIds: ["B-005-999-001"] }));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError
        && error.report.issues.some((issue) => issue.includes("unknown lessonId"))
        && error.report.issues.some((issue) => issue.includes("unknown official question id B-005-999-001")),
    );
  });
});

test("quiz check rejects duplicate lesson IDs", async () => {
  await withFixture("duplicate-lesson-id", async (root) => {
    await writeBaseFixture(root);
    await writeFile(path.join(root, "content/lessons/module/l-test-duplicate.md"), lessonMarkdown({ quizIds: [] }), "utf8");

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof QuizCheckError && error.report.issues.some((issue) => issue.includes("duplicate lesson id L-TEST-01")),
    );
  });
});

test("quiz check scoped to a module ignores other modules' quiz files but keeps same-prefix orphan checks", async () => {
  await withFixture("module-scope", async (root) => {
    await mkdir(path.join(root, "content/lessons/m4-circuit-components"), { recursive: true });
    await mkdir(path.join(root, "content/lessons/m5-basic-electronics"), { recursive: true });
    await writeFile(path.join(root, "content/generated/basic-2025-07-15/questions.json"), questionsJson(), "utf8");
    await writeFile(
      path.join(root, "content/lessons/m4-circuit-components/l-004-01.md"),
      lessonMarkdown({ id: "L-004-01", quizIds: ["QZ-L-004-01-A"] }),
      "utf8",
    );
    await writeFile(
      path.join(root, "content/lessons/m5-basic-electronics/l-005-01.md"),
      lessonMarkdown({ id: "L-005-01", quizIds: ["QZ-L-005-01-A"] }),
      "utf8",
    );
    await writeFile(
      path.join(root, "content/quizzes/QZ-L-004-01-A.json"),
      quiz({ id: "QZ-L-004-01-A", lessonId: "L-004-01" }),
      "utf8",
    );
    await writeFile(
      path.join(root, "content/quizzes/QZ-L-004-99-A.json"),
      quiz({ id: "QZ-L-004-99-A", lessonId: "L-004-99" }),
      "utf8",
    );
    await writeFile(
      path.join(root, "content/quizzes/QZ-L-005-01-A.json"),
      "[]\n",
      "utf8",
    );

    await assert.rejects(
      () => checkQuizzes({
        lessonRoot: path.join(root, "content/lessons/m4-circuit-components"),
        questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
        quizRoot: path.join(root, "content/quizzes"),
      }),
      (error: unknown) => error instanceof QuizCheckError
        && error.report.quizFileCount === 2
        && error.report.issues.some((issue) => issue.includes("QZ-L-004-99-A.json") && issue.includes("not referenced"))
        && !error.report.issues.some((issue) => issue.includes("QZ-L-005-01-A.json")),
    );
  });
});

test("quiz check requires every choice's feedback by default and with the compatibility flag", async () => {
  await withFixture("choice-feedback", async (root) => {
    const options = {
      lessonRoot: path.join(root, "content/lessons"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      quizRoot: path.join(root, "content/quizzes"),
    };
    const check = JSON.parse(quiz()).conceptChecks[0];
    for (const missingCount of [1, 2]) {
      const choices = check.choices.map((choice: { text: object; isCorrect: boolean; feedback: object }, index: number) => {
        const { feedback, ...legacyChoice } = choice;
        return index < missingCount ? legacyChoice : choice;
      });
      await writeBaseFixture(root, quiz({ conceptChecks: [{ ...check, choices }] }));
      for (const mode of [options, { ...options, requireFeedback: true }]) {
        await assert.rejects(checkQuizzes(mode), (error: unknown) => {
          assert.ok(error instanceof QuizCheckError);
          assert.equal(error.report.issues.filter((issue) => issue.includes("feedback is required")).length, missingCount);
          return true;
        });
      }
      assert.equal((await checkQuizzes({ ...options, requireFeedback: false })).conceptCheckCount, 1);
    }
    await writeBaseFixture(root);
    assert.equal((await runCheck(root)).conceptCheckCount, 1);
    await writeBaseFixture(root, quiz({ conceptChecks: [] }));
    assert.equal((await runCheck(root)).conceptCheckCount, 0);
  });
});

test("quiz check rejects malformed feedback even when legacy completeness is explicitly allowed", async () => {
  await withFixture("malformed-feedback", async (root) => {
    const options = {
      lessonRoot: path.join(root, "content/lessons"),
      questionsPath: path.join(root, "content/generated/basic-2025-07-15/questions.json"),
      quizRoot: path.join(root, "content/quizzes"),
      requireFeedback: false,
    };
    const check = JSON.parse(quiz()).conceptChecks[0];
    for (const feedback of [null, "note", {}, { en: "", fr: null }, { en: "note", fr: "" }, { en: "note" }]) {
      await writeBaseFixture(root, quiz({ conceptChecks: [{ ...check, choices: check.choices.map((choice: object) => ({ ...choice, feedback })) }] }));
      await assert.rejects(checkQuizzes(options), (error: unknown) => {
        assert.ok(error instanceof QuizCheckError);
        assert.ok(error.report.issues.some((issue) => issue.includes("feedback must have non-empty en text")));
        return true;
      });
    }
    await writeBaseFixture(root, quiz({ conceptChecks: [{ ...check, choices: check.choices.map((choice: object, index: number) => ({ ...choice, feedback: { en: "Explain this option.", fr: index === 0 ? null : "Expliquer ce choix." } })) }] }));
    assert.equal((await runCheck(root)).conceptCheckCount, 1);
  });
});
