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
    const report = await checkQuizzes({ lessonRoot: path.join(lessonRoot, module.directory), requireFeedback: true });
    assert.equal(report.issues.length, 0);
    for (const lessonId of Object.keys(module.lessons)) {
      const quizPath = fileURLToPath(new URL(`../../../content/quizzes/QZ-${lessonId}-A.json`, import.meta.url));
      const quiz = JSON.parse(await readFile(quizPath, "utf8")) as {
        conceptChecks: { id: string; prompt: { en: string }; choices: { feedback: { en: string } }[] }[];
      };
      for (const check of quiz.conceptChecks) {
        assert.doesNotMatch(check.prompt.en, /\bNOT\b|\b(?:not true|would not|spot the error)\b/iu, check.id);
        assert.equal(new Set(check.choices.map((choice) => choice.feedback.en)).size, check.choices.length, `${check.id}: each choice needs its own diagnosis`);
      }
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
