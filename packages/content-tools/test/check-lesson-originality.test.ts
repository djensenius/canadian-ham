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

test("numeric originality allows common dB and ratio shortcut numbers without question context", async () => {
  await withFixture("common-db-steps", async (root) => {
    await writeFixture(root, [
      question("B-TEST-DB-001", "A two-times increase in power results in a change of how many dB?", "3 dB higher"),
      question("B-TEST-DB-002", "If a signal has a 10 dB power gain, what is the approximate power ratio?", "10 times"),
      question("B-TEST-DB-003", "What change in transmitter power results in a 3 dB decrease?", "Divide the original power by 2"),
    ], lessonMarkdown(`# Lesson

## Worked example: estimating gain without copying a question

For Basic-level estimating, use practical power shortcuts. A 2x power step is about +3 dB, +10 dB is about 10x, and a -3 dB step means divide power by 2.
`));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality allows standalone common numbers without distinctive context", async () => {
  await withFixture("standalone-common-numbers", async (root) => {
    await writeFixture(root, [
      question("B-TEST-COMMON-001", "If a 5 V circuit draws 2 A, what is the power?", "10 W"),
    ], lessonMarkdown("# Lesson\n\nA 2-minute warm-up reviews a 5 W handheld note and the +10 dB shortcut before any circuit examples begin.\n"));

    const report = await runCheck(root);

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

test("numeric originality rejects common numbers when paired with distinctive question context", async () => {
  await withFixture("common-numbers-with-context", async (root) => {
    await writeFixture(root, [
      question("B-TEST-CONTEXT-001", "If you wire two 20-microfarad capacitors in series, what is the capacity of the combination?", "10 microfarads"),
    ], lessonMarkdown("# Lesson\n\nTwo 20 uF capacitors in series combine to make 10 uF.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-CONTEXT-001" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality rejects common-number leaks when matching units replace missing nouns", async () => {
  const cases = [
    {
      name: "microfarad-symbol",
      id: "B-TEST-UNIT-001",
      text: "If you wire two 20-microfarad capacitors in series, what is the capacity of the combination?",
      answer: "10 microfarads",
      lesson: "Two 20 µF in series give 10 µF.",
    },
    {
      name: "microfarad-synonym",
      id: "B-TEST-UNIT-002",
      text: "If you wire two 20-microfarad capacitors in series, what is the capacity of the combination?",
      answer: "10 microfarads",
      lesson: "Two 20 uF caps in series: 10 uF.",
    },
    {
      name: "millihenry-parallel",
      id: "B-TEST-UNIT-003",
      text: "If you wire two 20-millihenry inductors in parallel, what is the inductance of the combination?",
      answer: "10 millihenries",
      lesson: "Two 20 mH coils in parallel give 10 mH.",
    },
    {
      name: "ohm-volt-watt",
      id: "B-005-006-009",
      text: "What is the power consumption of two 10-ohm resistors connected in series with a 10-volt battery?",
      answer: "5 watts",
      lesson: "Two 10 ohm loads in series across a 10 V supply draw 5 W.",
    },
    {
      name: "spelled-ohm-volt-watt",
      id: "B-005-006-009",
      text: "What is the power consumption of two 10-ohm resistors connected in series with a 10-volt battery?",
      answer: "5 watts",
      lesson: "Two ten-ohm loads in series on a ten-volt supply draw five watts.",
    },
    {
      name: "spelled-microfarad",
      id: "B-005-009-010",
      text: "If you wire two 20-microfarad capacitors in series, what is the capacity of the combination?",
      answer: "10 microfarads",
      lesson: "Two twenty-microfarad caps in series give ten microfarads.",
    },
    {
      name: "spelled-coax-values",
      id: "B-TEST-UNIT-005",
      text: "A line is 50 ohms and another is 75 ohms. What value is used for the dummy load?",
      answer: "50 ohms",
      lesson: "A fifty-ohm feed line and a seventy-five-ohm line are compared before choosing a fifty-ohm dummy load.",
    },
  ];

  for (const fixture of cases) {
    await withFixture(fixture.name, async (root) => {
      await writeFixture(root, [
        question(fixture.id, fixture.text, fixture.answer),
      ], lessonMarkdown(`# Lesson

${fixture.lesson}
`));

      await assert.rejects(
        () => runCheck(root),
        (error: unknown) => error instanceof LessonOriginalityError
          && error.report.issues.some((issue) => issue.questionId === fixture.id && issue.issueType === "numeric-overlap"),
      );
    });
  }
});

test("numeric originality requires unit word boundaries", async () => {
  await withFixture("unit-word-boundary", async (root) => {
    await writeFixture(root, [
      question("B-TEST-UNIT-BOUNDARY-001", "If two 20-watt loads are connected in series, what number is shown?", "10"),
    ], lessonMarkdown("# Lesson\n\nTwo 20 wires in series give 10.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality does not treat picofarads as farads", async () => {
  await withFixture("picofarad-not-farad", async (root) => {
    await writeFixture(root, [
      question("B-TEST-PF-FAMILY-001", "If two 20-farad capacitors are connected in series, what number is shown?", "10"),
    ], lessonMarkdown("# Lesson\n\nTwo 20 pF parts in series give 10.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality keeps scaled unit-pair magnitudes distinct", async () => {
  await withFixture("scaled-unit-pair-magnitude", async (root) => {
    await writeFixture(root, [
      question("B-TEST-SCALED-PAIR-001", "If two 1-kohm resistors are connected in series, what total resistance results?", "2 kohms"),
    ], lessonMarkdown("# Lesson\n\nTwo 1 ohm loads in series give 2 ohms.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality allows low-context metric conversion teaching", async () => {
  await withFixture("allowed-metric-conversion", async (root) => {
    await writeFixture(root, [
      question("B-005-001-003", "How many hertz is 1 kHz?", "1000 Hz"),
    ], lessonMarkdown("# Lesson\n\nA kilohertz is 1000 hertz.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });
});

test("numeric originality recognizes scaled unit words and abbreviations", async () => {
  await withFixture("scaled-unit-words", async (root) => {
    await writeFixture(root, [
      question("B-TEST-KILOHM-001", "A resistor is marked 4.7 kilohms. What is its resistance in ohms?", "4700 ohms"),
      question("B-TEST-MEGOHM-001", "A resistor is marked 0.027 megohms. What is its resistance in ohms?", "27000 ohms"),
      question("B-TEST-MILLIWATT-001", "If a hand-held output is 500 milliwatts, how many watts is that?", "0.5 watts"),
      question("B-TEST-MICROHENRY-001", "For a coil conversion, 10000 microhenries equals how many millihenries?", "10 millihenries"),
      question("B-TEST-MV-001", "For a signal conversion, 2000 mV equals how many volts?", "2 volts"),
      question("B-TEST-PICOFARAD-001", "If two 20-picofarad capacitors are in series, what capacitance results?", "10 picofarads"),
    ], lessonMarkdown(`# Lesson

A copied resistance value says 4700 ohms.
Another copied resistance value says 27000 ohms.
A hand-held output conversion says 0.5 W.
A coil conversion says 10 mH.
A signal conversion equals 2 volts.
Two 20 pF caps in series give 10 pF.
`));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-KILOHM-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-MEGOHM-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-MILLIWATT-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-MICROHENRY-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-MV-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-PICOFARAD-001" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality normalizes voltage and resistance plurals for context", async () => {
  await withFixture("plural-context-forms", async (root) => {
    await writeFixture(root, [
      question("B-TEST-PLURAL-001", "If voltage resistance uses two items, what total is shown?", "10"),
      question("B-TEST-PLURAL-002", "What is the voltage across a 2-ohm resistor if a current of 0.5 amperes flows through it?", "1.0 volts"),
      question("B-TEST-PLURAL-003", "What is the total resistance of five 10-ohm resistors in series?", "50 ohms"),
    ], lessonMarkdown(`# Lesson

Voltages resistances use two items: 10.
Resistor voltages: 2 ohms at 0.5 A gives 1 V.
Five 10-ohm resistances in series give 50 ohms.
`));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-PLURAL-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-PLURAL-002" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-PLURAL-003" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality keeps the common-number context threshold boundary", async () => {
  await withFixture("one-context-word", async (root) => {
    await writeFixture(root, [
      question("B-TEST-THRESHOLD-001", "If you place two blue tokens in series, what total is shown?", "10"),
    ], lessonMarkdown("# Lesson\n\nTwo items in series give 10.\n"));

    const report = await runCheck(root);

    assert.equal(report.issueCount, 0);
  });

  await withFixture("two-context-words", async (root) => {
    await writeFixture(root, [
      question("B-TEST-THRESHOLD-002", "If you place two blue tokens in series, what total is shown?", "10"),
    ], lessonMarkdown("# Lesson\n\nTwo blue items in series give 10.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-THRESHOLD-002" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality flags low-context unit and scaled-prefix copies", async () => {
  await withFixture("low-context-units", async (root) => {
    await writeFixture(root, [
      question("B-TEST-HZ-001", "For a dial, how many hertz is 1 kHz?", "1 000 Hz"),
      question("B-TEST-HZ-002", "What dial frequency is 1.5 kHz in hertz?", "1500 Hz"),
      question("B-TEST-KOHM-001", "A resistor is marked 1.5 k ohms. What is its resistance in ohms?", "1500 ohms"),
    ], lessonMarkdown(`# Lesson

A copied dial conversion says 1 kHz is 1,000 Hz.
A copied scaled-unit dial example says 1500 Hz.
A copied resistance note says a 1500 ohm part has 1500 ohms.
`));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-HZ-001" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-HZ-002" && issue.issueType === "numeric-overlap")
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-KOHM-001" && issue.issueType === "numeric-overlap"),
    );
  });
});

test("numeric originality parses French decimal commas with units", async () => {
  await withFixture("french-decimal-comma", async (root) => {
    await writeFixture(root, [
      question("B-TEST-DECIMAL-001", "What is the second harmonic of a 1.5 kHz signal?", "3 kHz"),
    ], lessonMarkdown("# Lesson\n\nA copied example says 1,5 kHz doubled is 3 kHz.\n"));

    await assert.rejects(
      () => runCheck(root),
      (error: unknown) => error instanceof LessonOriginalityError
        && error.report.issues.some((issue) => issue.questionId === "B-TEST-DECIMAL-001" && issue.issueType === "numeric-overlap"),
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
