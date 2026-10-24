import assert from "node:assert/strict";
import test from "node:test";
import { validateDataAgainstSchema } from "./validate.mjs";

const legacyQuiz = {
  id: "QZ-L-004-01-A",
  lessonId: "L-004-01",
  officialQuestionIds: ["B-004-001-001"],
  conceptChecks: [{
    id: "QZ-L-004-01-A-C1",
    prompt: { en: "Compare the signal paths.", fr: null },
    choices: [
      { text: { en: "RF amplification", fr: null }, isCorrect: true },
      { text: { en: "Detection", fr: null }, isCorrect: false },
    ],
    explanation: { en: "The carrier frequency stays the same.", fr: null },
  }],
};

function quizWithFeedback(feedback) {
  const quiz = structuredClone(legacyQuiz);
  quiz.conceptChecks[0].choices[1].feedback = feedback;
  return quiz;
}

test("lesson quiz schema accepts legacy choices and optional localized feedback", () => {
  for (const quiz of [legacyQuiz, quizWithFeedback({ en: "Detection recovers audio.", fr: null }), quizWithFeedback({ en: "Detection recovers audio.", fr: "La détection récupère l’audio." })]) {
    assert.deepEqual(validateDataAgainstSchema(quiz, "lesson-quiz.schema.json"), []);
  }
});

test("lesson quiz schema rejects malformed or empty choice feedback", () => {
  for (const feedback of [null, "A note", {}, { en: "A note" }, { en: "", fr: null }, { en: "A note", fr: "" }, { en: "A note", fr: 4 }]) {
    const errors = validateDataAgainstSchema(quizWithFeedback(feedback), "lesson-quiz.schema.json");
    assert.ok(errors.some((error) => error.includes("choices[1].feedback")), JSON.stringify({ feedback, errors }));
  }
});

test("lesson quiz schema validates optional section-sized rounds", () => {
  const round = { sectionAnchor: "principle", title: { en: "Principle", fr: "Principe" }, officialQuestionIds: ["B-004-001-001"] };
  assert.deepEqual(validateDataAgainstSchema({ ...legacyQuiz, rounds: [round] }, "lesson-quiz.schema.json"), []);
  for (const rounds of [[], [null], [{ ...round, sectionAnchor: "" }], [{ ...round, title: { en: "Principle" } }], [{ ...round, officialQuestionIds: [] }], [{ ...round, officialQuestionIds: ["B-004-001-001", "B-004-001-001"] }], [{ ...round, extra: true }]]) {
    assert.ok(validateDataAgainstSchema({ ...legacyQuiz, rounds }, "lesson-quiz.schema.json").some((error) => error.includes("rounds")));
  }
});
