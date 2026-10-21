import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import test from "node:test";

import { validateTryItAnswers } from "../src/try-it-answers.ts";
import { checkLessonCoverage } from "../src/check-lesson-coverage.ts";

const paired = "1. What changes?\n\n:::answer\nThe frequency rises.\n:::";

test("Try-it answer format accepts paired prompts and preserves other lesson sections", () => {
  assert.deepEqual(validateTryItAnswers(`## Worked example\n\n- Answer: 3 A.\n\n## Try it\n\nTry first.\n\n${paired}\n\n2. Name the path.\n\n:::answer\nThe audio path.\n:::\n\n## Summary\n\nOrdinary prose.`), []);
  assert.deepEqual(validateTryItAnswers("## Reference facts\n\nNo Try-its in M1."), []);
});

for (const [name, markdown, error] of [
  ["missing answer", "1. What changes?", /requires a following :::answer/],
  ["legacy inline answer", "1. What changes? The frequency rises.", /inline Try-it answers/],
  ["inline answer even with a block", paired.replace("What changes?", "What changes? It rises."), /inline Try-it answers/],
  ["labelled inline solution", paired.replace("What changes?", "Find the current. Answer: 3 A."), /inline Try-it answers/],
  ["empty answer", paired.replace("The frequency rises.", ""), /nonempty line/],
  ["unclosed answer", paired.slice(0, -3), /followed by :::/],
  ["multiline answer", paired.replace("The frequency rises.", "The frequency\nrises."), /one line of prose/],
  ["answer heading", paired.replace("The frequency rises.", "### Answer"), /plain prose/],
  ["answer list", paired.replace("The frequency rises.", "- The frequency rises."), /plain prose/],
  ["nested directive", paired.replace("The frequency rises.", ":::answer"), /plain prose/],
  ["misnumbered prompt", paired.replace("1.", "2."), /expected Try-it number 1/],
  ["unpaired extra prose", `${paired}\nThe next answer is visible.`, /only introductory prose/],
  ["legacy feedback heading", `${paired}\n### Try-it feedback\n1. Visible answer.`, /only introductory prose/],
  ["empty section", "", /at least one numbered prompt/],
] as const) {
  test(`Try-it answer format rejects ${name}`, () => {
    assert.match(validateTryItAnswers(`## Try it\n\n${markdown}`).join("\n"), error);
  });
}

test("Try-it answer format rejects orphan directives outside Try it", () => {
  assert.match(validateTryItAnswers(":::answer\nVisible answer.\n:::").join("\n"), /only to numbered Try-it prompts/);
});

test("every authored M2–M8 Try-it is paired and lesson coverage enforces the format", async () => {
  const root = fileURLToPath(new URL("../../../content/lessons/", import.meta.url));
  let lessons = 0;
  let answers = 0;
  for (const directory of await readdir(root, { withFileTypes: true })) {
    if (!directory.isDirectory()) continue;
    for (const name of await readdir(path.join(root, directory.name))) {
      if (!/^l-.*\.md$/u.test(name)) continue;
      const markdown = await readFile(path.join(root, directory.name, name), "utf8");
      assert.deepEqual(validateTryItAnswers(markdown), [], name);
      if (/^## Try it$/mu.test(markdown)) {
        lessons += 1;
        answers += [...markdown.matchAll(/^:::answer$/gmu)].length;
      }
    }
  }
  assert.equal(lessons, 31);
  assert.equal(answers, 141);
  const coverage = await checkLessonCoverage();
  assert.deepEqual(coverage.malformedFiles, []);
});
