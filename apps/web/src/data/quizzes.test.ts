import assert from "node:assert/strict";
import { describe, it } from "vitest";

import { buildLessonQuizItems, lessonQuizzes, lessonQuizRoundProgress, type LessonQuiz, type LessonQuizRoundProgress } from "./quizzes";

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

describe("M1 teaching-section rounds", () => {
  it("retains all 199 official items and the existing seeded order within each section", () => {
    let total = 0;
    for (const quiz of lessonQuizzes.filter((quiz) => quiz.rounds !== undefined)) {
      const items = buildLessonQuizItems(quiz, "m1-rounds");
      const legacyItems = buildLessonQuizItems({ ...quiz, rounds: undefined }, "m1-rounds");
      assert.deepEqual(items, buildLessonQuizItems(quiz, "m1-rounds"));
      assert.equal(items.length, quiz.officialQuestionIds.length);
      assert.equal(new Set(items.map((item) => item.id)).size, items.length);
      assert.deepEqual(items, quiz.rounds!.flatMap((round) => legacyItems.filter((item) => item.type === "official" && round.officialQuestionIds.includes(item.questionId))));
      for (const [index, item] of items.entries()) {
        const progress: LessonQuizRoundProgress = lessonQuizRoundProgress(quiz, items, index)!;
        assert.ok(item.type === "official" && progress.round.officialQuestionIds.includes(item.questionId));
        assert.equal(progress.questionCount, progress.round.officialQuestionIds.length);
        assert.ok(index >= progress.startIndex && index <= progress.endIndex);
      }
      total += items.length;
    }
    assert.equal(total, 199);
  });

  it("does not group non-M1 quizzes", () => {
    const quiz = lessonQuizzes.find((quiz) => quiz.lessonId === "L-005-01")!;
    assert.equal(quiz.rounds, undefined);
    assert.equal(lessonQuizRoundProgress(quiz, buildLessonQuizItems(quiz, "legacy"), 0), undefined);
  });
});
