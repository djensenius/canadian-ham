import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { buildLessonQuizItems, type LessonQuiz } from "./quizzes";

describe("buildLessonQuizItems", () => {
  it("renders an official-only lesson quiz with no concept checks", () => {
    const quiz: LessonQuiz = {
      id: "QZ-L-TEST-01-A",
      lessonId: "L-TEST-01",
      officialQuestionIds: ["B-001-001-001", "B-001-001-002"],
      conceptChecks: [],
    };

    const items = buildLessonQuizItems(quiz, "official-only-seed");

    assert.equal(items.length, 2);
    assert.deepEqual(new Set(items.map((item) => item.type)), new Set(["official"]));

    const renderedQuestionIds: string[] = [];
    for (const item of items) {
      if (item.type !== "official") {
        assert.fail("expected only official quiz items");
      }
      renderedQuestionIds.push(item.questionId);
      assert.deepEqual([...item.choicePermutation].sort(), [0, 1, 2, 3]);
    }
    assert.deepEqual(new Set(renderedQuestionIds), new Set(quiz.officialQuestionIds));
  });
});
