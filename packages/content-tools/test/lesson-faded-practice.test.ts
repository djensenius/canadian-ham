import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { checkQuizzes } from "../src/check-quizzes.ts";

const lessonRoot = fileURLToPath(new URL("../../../content/lessons/", import.meta.url));
const modulePractice = [
  { directory: "m2-operating-procedures", lessons: { "L-002-01": 1, "L-002-02": 1, "L-002-03": 1, "L-002-04": 2 } },
  { directory: "m3-station-practice-safety", lessons: { "L-003-01": 3, "L-003-02": 3, "L-003-03": 2, "L-003-04": 2, "L-003-05": 3, "L-003-06": 1, "L-003-07": 4, "L-003-08": 1 } },
  { directory: "m4-circuit-components", lessons: { "L-004-01": 2, "L-004-02": 1, "L-004-03": 2 } },
  { directory: "m5-basic-electronics", lessons: { "L-005-01": 2, "L-005-02": 4, "L-005-03": 8, "L-005-04": 2, "L-005-05": 1, "L-005-06": 2 } },
  { directory: "m6-feedlines-antennas", lessons: { "L-006-01": 0, "L-006-02": 4, "L-006-03": 2, "L-006-04": 3, "L-006-05": 3 } },
  { directory: "m7-propagation", lessons: { "L-007-01": 2, "L-007-02": 1, "L-007-03": 1 } },
  { directory: "m8-interference-suppression", lessons: { "L-008-01": 1, "L-008-02": 2 } },
];

for (const module of modulePractice) {
  for (const [lessonId, expectedCount] of Object.entries(module.lessons)) {
    test(`${lessonId} keeps faded calculation sets with blanks before separate solutions`, async () => {
      const directory = path.join(lessonRoot, module.directory);
      const file = (await readdir(directory)).find((name) => name.startsWith(`${lessonId.toLowerCase()}-`));
      assert.ok(file, lessonId);
      const markdown = await readFile(path.join(directory, file), "utf8");
      const practice = [...markdown.matchAll(/^### Faded practice: .+\n([\s\S]*?)(?=^### Check your work: )/gmu)];
      assert.equal(practice.length, expectedCount, lessonId);
      for (const [, prompt] of practice) {
        for (const label of ["Given", "Find", "Formula", "Complete", "Sanity check"]) {
          assert.match(prompt!, new RegExp(`^- ${label}:`, "mu"), `${lessonId}: ${label}`);
        }
        assert.match(prompt!, /___/u, `${lessonId}: missing completion blank`);
        assert.doesNotMatch(prompt!, /^- Answer:|^## /mu, `${lessonId}: answer or new section before solution`);
      }
    });
  }

  test(`${module.directory} requires diagnostic concept-choice feedback`, async () => {
    const report = await checkQuizzes({ lessonRoot: path.join(lessonRoot, module.directory) });
    assert.equal(report.issues.length, 0);
    for (const lessonId of Object.keys(module.lessons)) {
      const quizPath = fileURLToPath(new URL(`../../../content/quizzes/QZ-${lessonId}-A.json`, import.meta.url));
      const quiz = JSON.parse(await readFile(quizPath, "utf8")) as {
        conceptChecks: { id: string; prompt: { en: string }; choices: { text: { en: string }; isCorrect: boolean; feedback: { en: string } }[] }[];
      };
      for (const check of quiz.conceptChecks) {
        assert.doesNotMatch(check.prompt.en, /\bNOT\b|\b(?:not true|would not|spot the error)\b/iu, check.id);
        assert.equal(new Set(check.choices.map((choice) => choice.feedback.en)).size, check.choices.length, `${check.id}: each choice needs its own diagnosis`);
        const wrong = check.choices.filter((choice) => !choice.isCorrect);
        const distractorCue = /\b(?:must|always|guarantee\w*|automatic\w*|prove\w*|necessarily|only|treating|neglecting|ignoring|sufficient|enough evidence|alone)\b/iu;
        assert.ok(wrong.some((choice) => !distractorCue.test(choice.text.en)), `${check.id}: at least one distractor must be free of the checked wording cues so the key is not the only cue-free option`);
      }
    }
  });
}

for (const [lessonId, checkNumber] of [["L-006-01", 1], ["L-006-03", 2], ["L-007-01", 1]] as const) {
  test(`QZ-${lessonId}-A-C${checkNumber} states wrong reasoning without labelling its own flaw`, async () => {
    const quiz = JSON.parse(await readFile(fileURLToPath(new URL(`../../../content/quizzes/QZ-${lessonId}-A.json`, import.meta.url)), "utf8")) as {
      conceptChecks: { id: string; choices: { text: { en: string }; isCorrect: boolean }[] }[];
    };
    const concept = quiz.conceptChecks.find((item) => item.id === `QZ-${lessonId}-A-C${checkNumber}`);
    assert.ok(concept);
    for (const choice of concept.choices.filter((item) => !item.isCorrect)) {
      assert.doesNotMatch(choice.text.en, /\b(?:treating|neglecting|ignoring)\b/iu, concept.id);
    }
  });
}

test("M1 retains its reference-only format and official-only quizzes", async () => {
  for (const file of (await readdir(path.join(lessonRoot, "m1-regulations-policies"))).filter((name) => name.startsWith("l-"))) {
    const markdown = await readFile(path.join(lessonRoot, "m1-regulations-policies", file), "utf8");
    assert.doesNotMatch(markdown, /^## Try it|^### (?:Worked example|Faded practice):/mu, file);
    const lessonId = markdown.match(/^id: (L-\d+-\d+)$/mu)?.[1];
    assert.ok(lessonId);
    const quiz = JSON.parse(await readFile(fileURLToPath(new URL(`../../../content/quizzes/QZ-${lessonId}-A.json`, import.meta.url)), "utf8")) as { conceptChecks: unknown[] };
    assert.deepEqual(quiz.conceptChecks, [], lessonId);
  }
});

const reviewedTransfers = [
  { lessonId: "L-003-06", check: 1, prompt: /average output.*clean peak limit/u, answer: /keep peaks within the clean limit/u },
  { lessonId: "L-003-08", check: 3, prompt: /point-source.*metal structures/u, answer: /model-based comparison.*not approval/u },
  { lessonId: "L-004-01", check: 2, prompt: /preserve a test waveform.*more DC power/u, answer: /less efficient.*does not show worse linearity/u },
  { lessonId: "L-004-01", check: 3, prompt: /higher supply voltage.*resistor.*unchanged/u, answer: /raises current and heat/u },
  { lessonId: "L-004-02", check: 1, prompt: /control pin.*fan/u, answer: /supply provides the load energy/u },
  { lessonId: "L-004-02", check: 3, prompt: /FET.*triode.*interchangeable/u, answer: /electric field.*separate current path/u },
  { lessonId: "L-005-05", check: 2, prompt: /heavier load.*dips/u, answer: /draws stored energy faster/u, excludedContent: /bypass|reactance/iu },
  { lessonId: "L-005-06", check: 2, prompt: /steady DC.*brief pulse/u, answer: /field changes during switching/u, excludedContent: /voltmeter|ammeter|high resistance|low resistance/iu },
  { lessonId: "L-006-01", check: 3, prompt: /low-current continuity.*intermittent/u, answer: /resistive contact.*small test current.*transmit load/u, excludedContent: /velocity factor|dielectric/iu },
  { lessonId: "L-006-05", check: 3, prompt: /trap antenna.*unwanted-output check/u, answer: /Recheck radiation on related bands/u, excludedContent: /audio distortion|counterpoise|RF feedback/iu },
  { lessonId: "L-007-03", check: 3, prompt: /taller VHF mast.*more power/u, answer: /same route, frequency, and power/u, excludedContent: /skip zone|scatter|ground wave/iu },
  { lessonId: "L-008-01", check: 2, prompt: /switching off a charger.*rerouting/u, answer: /changes separately/u, excludedContent: /IF filter|attenuator|suitable input filter/iu },
  { lessonId: "L-008-02", check: 2, prompt: /metal cover.*removed for cooling/u, answer: /run uncovered, recheck it that way.*refit the cover/u, excludedContent: /keying|click|symbol rate|rise time/iu },
];

for (const { lessonId, check, prompt, answer, excludedContent } of reviewedTransfers) {
  test(`QZ-${lessonId}-A-C${check} retains the reviewed transfer instead of the old recognition item`, async () => {
    const quiz = JSON.parse(await readFile(fileURLToPath(new URL(`../../../content/quizzes/QZ-${lessonId}-A.json`, import.meta.url)), "utf8")) as {
      conceptChecks: { id: string; prompt: { en: string }; explanation: { en: string }; choices: { text: { en: string }; isCorrect: boolean; feedback: { en: string } }[] }[];
    };
    const concept = quiz.conceptChecks.find((item) => item.id === `QZ-${lessonId}-A-C${check}`);
    assert.ok(concept);
    assert.match(concept.prompt.en, prompt);
    const correct = concept.choices.filter((choice) => choice.isCorrect);
    assert.equal(correct.length, 1);
    assert.match(correct[0]!.text.en, answer);
    if (excludedContent) {
      const disclosedContent = [concept.prompt.en, concept.explanation.en, ...concept.choices.flatMap((choice) => [choice.text.en, choice.feedback.en])].join("\n");
      assert.doesNotMatch(disclosedContent, excludedContent, `${concept.id}: the former overlapping answer must not return in any option, feedback, or explanation`);
    }
  });
}

for (const lessonId of ["L-002-01", "L-002-02", "L-002-03", "L-002-04"]) {
  test(`${lessonId} keeps later Try-its independent rather than repeating faded scaffolds`, async () => {
    const directory = path.join(lessonRoot, "m2-operating-procedures");
    const file = (await readdir(directory)).find((name) => name.startsWith(`${lessonId.toLowerCase()}-`));
    assert.ok(file);
    const markdown = await readFile(path.join(directory, file), "utf8");
    const tryIt = markdown.split("## Try it\n")[1]?.split("\n## ")[0]?.replace(/:::answer\n[^\n]+\n:::/gu, "");
    assert.ok(tryIt);
    assert.doesNotMatch(tryIt, /___|fill in|finish this setup|add half a turn/iu);
  });
}

test("L-006-01 labels its qualitative feed-point story rather than calling it a calculation", async () => {
  const markdown = await readFile(path.join(lessonRoot, "m6-feedlines-antennas/l-006-01-feedline-basics-and-types.md"), "utf8");
  assert.match(markdown, /^### In the real world: feeding a simple dipole$/mu);
  assert.doesNotMatch(markdown, /^### (?:Worked example|Faded practice):/mu);
});

test("EXP-B-008-004-004 keeps out-of-band and spurious categories distinct", async () => {
  const explanation = JSON.parse(await readFile(fileURLToPath(new URL("../../../content/explanations/b-008/b-008-004-004.json", import.meta.url)), "utf8")) as {
    questionId: string; body: { en: string; fr: string | null };
  };
  assert.equal(explanation.questionId, "B-008-004-004");
  assert.match(explanation.body.en, /Out-of-band emission is modulation-related/u);
  assert.match(explanation.body.en, /Unwanted emissions is the umbrella term for both out-of-band and spurious emissions/u);
  assert.match(explanation.body.en, /sourceIndex 3: "Spurious emissions": This category excludes out-of-band emissions/u);
  assert.doesNotMatch(explanation.body.en, /Spurious emissions is a broad category/u);
  assert.equal(explanation.body.fr, null);
});
