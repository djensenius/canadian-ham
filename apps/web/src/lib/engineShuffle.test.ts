import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { shuffleAnswersWithSeed } from "./engineShuffle";

const answers = [
  { sourceIndex: 0, isCorrect: true, text: { en: "Correct", fr: "Correct FR" } },
  { sourceIndex: 1, isCorrect: false, text: { en: "Wrong 1", fr: "Wrong 1 FR" } },
  { sourceIndex: 2, isCorrect: false, text: { en: "Wrong 2", fr: "Wrong 2 FR" } },
  { sourceIndex: 3, isCorrect: false, text: { en: "Wrong 3", fr: "Wrong 3 FR" } },
];

describe("shuffleAnswersWithSeed", () => {
  it("uses the shared engine shuffle and tracks the correct answer", () => {
    const shuffled = shuffleAnswersWithSeed(answers, "web-answer-seed-001");

    assert.equal(shuffled.correctSourceIndex, 0);
    assert.equal(shuffled.answers[shuffled.correctDisplayIndex]?.isCorrect, true);
    assert.deepEqual(shuffled.choicePermutation, shuffled.answers.map((answer) => answer.sourceIndex));
    assert.notDeepEqual(shuffled.choicePermutation, answers.map((answer) => answer.sourceIndex));
    assert.deepEqual(shuffleAnswersWithSeed(answers, "web-answer-seed-001").choicePermutation, shuffled.choicePermutation);
  });
});
