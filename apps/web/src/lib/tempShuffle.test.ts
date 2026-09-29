import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { shuffleAnswers } from "./tempShuffle";

const answers = [
  { sourceIndex: 0, isCorrect: true, text: { en: "Correct", fr: "Correct FR" } },
  { sourceIndex: 1, isCorrect: false, text: { en: "Wrong 1", fr: "Wrong 1 FR" } },
  { sourceIndex: 2, isCorrect: false, text: { en: "Wrong 2", fr: "Wrong 2 FR" } },
  { sourceIndex: 3, isCorrect: false, text: { en: "Wrong 3", fr: "Wrong 3 FR" } },
];

describe("shuffleAnswers", () => {
  it("tracks the correct answer after shuffling", () => {
    const randomValues = [0.75, 0.25, 0.5];
    const shuffled = shuffleAnswers(answers, () => randomValues.shift() ?? 0);

    assert.equal(shuffled.correctSourceIndex, 0);
    assert.equal(shuffled.answers[shuffled.correctDisplayIndex]?.isCorrect, true);
    assert.notDeepEqual(shuffled.answers.map((answer) => answer.sourceIndex), answers.map((answer) => answer.sourceIndex));
  });
});
