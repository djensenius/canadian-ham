import assert from "node:assert/strict";
import { scoreExam, type QuestionProgressRecord } from "@canadian-ham/engine-ts";
import { beforeAll, describe, it } from "vitest";

import { bankId, loadQuestions, type Question } from "../data/bank";
import { applyPracticeAnswer, buildExamAttempt, buildPracticeItems, createMockExam, examCategoryCounts } from "./studyEngine";

const now = "2026-01-02T00:00:00.000Z";
let testQuestions: readonly Question[] = [];

beforeAll(async () => {
  testQuestions = await loadQuestions();
});

function progressRecord(questionId: string, recentResults: readonly boolean[], dueAt = now): QuestionProgressRecord {
  return {
    questionId,
    bankId,
    attempts: recentResults.length,
    correctAttempts: recentResults.filter(Boolean).length,
    lastAttemptedAt: now,
    lastResult: recentResults.at(-1) ? "correct" : "incorrect",
    lastAnsweredWithHelp: false,
    recentResults,
    recentAnsweredWithHelp: recentResults.map(() => false),
    leitner: { box: 0, dueAt },
    notes: null,
  };
}

describe("web study engine integration", () => {
  it("updates Leitner and recentResults through the shared engine applyAnswer", () => {
    let records: readonly QuestionProgressRecord[] = [];
    records = applyPracticeAnswer(records, "B-001-001-001", 0, now);
    assert.equal(records[0]?.leitner.box, 1);
    assert.equal(records[0]?.leitner.dueAt, "2026-01-03T00:00:00.000Z");
    records = applyPracticeAnswer(records, "B-001-001-001", 1, "2026-01-02T01:00:00.000Z");
    assert.equal(records[0]?.leitner.box, 0);
    assert.deepEqual(records[0]?.recentResults, [true, false]);

    for (const hour of [2, 3, 4, 5]) {
      records = applyPracticeAnswer(records, "B-001-001-001", 0, `2026-01-02T0${hour}:00:00.000Z`);
    }
    assert.deepEqual(records[0]?.recentResults, [false, true, true, true, true]);
  });

  it("records answered-with-help as a flag without mastery credit", () => {
    const records = applyPracticeAnswer([], "B-001-001-001", 0, now, bankId, true);

    assert.equal(records[0]?.correctAttempts, 1);
    assert.equal(records[0]?.lastResult, "correct");
    assert.equal(records[0]?.lastAnsweredWithHelp, true);
    assert.deepEqual(records[0]?.recentResults, [true]);
    assert.deepEqual(records[0]?.recentAnsweredWithHelp, [true]);
    assert.equal(records[0]?.leitner.box, 0);
    assert.equal(records[0]?.leitner.dueAt, now);
  });

  it("builds due-review scope from due stored records only", () => {
    const items = buildPracticeItems({
      questions: testQuestions,
      scope: { type: "due" },
      progress: [progressRecord("B-001-001-001", [false], now)],
      seed: "due-scope",
      now,
      limit: 10,
    });

    assert.equal(items.length, 1);
    assert.equal(items[0]?.question.id, "B-001-001-001");
  });

  it("builds weak-area scope from the engine weak-subsection rule", () => {
    const items = buildPracticeItems({
      questions: testQuestions,
      scope: { type: "weak" },
      progress: [progressRecord("B-001-001-001", [false, true, false])],
      seed: "weak-scope",
      now,
      limit: 10,
    });

    assert.ok(items.length > 0);
    assert.ok(items.every((item) => item.question.subsectionId === "B-001-001"));
  });

  it("generates a full mock exam with one question per subsection and verified category counts", () => {
    const items = createMockExam("mock-fixture-seed", testQuestions);

    assert.equal(items.length, 100);
    assert.equal(new Set(items.map((item) => item.subsectionId)).size, 100);
    assert.deepEqual(examCategoryCounts(items), [25, 9, 21, 6, 13, 13, 8, 5]);
    assert.ok(items.every((item) => item.choicePermutation.length === 4));
  });

  it("scores unanswered exam questions as incorrect and respects pass/honours boundaries", () => {
    const generated = createMockExam("score-seed", testQuestions);
    const unansweredAttempt = buildExamAttempt({
      seed: "score-seed",
      startedAt: now,
      submittedAt: "2026-01-02T01:00:00.000Z",
      timerEnabled: false,
      secondsElapsed: 0,
      generatedItems: generated,
      selectedByQuestionId: new Map([[generated[0]!.questionId, 0]]),
      flaggedQuestionIds: new Set(),
    });
    assert.equal(unansweredAttempt.score.correct, 1);
    assert.equal(unansweredAttempt.items[1]?.selectedSourceIndex, null);
    assert.equal(unansweredAttempt.items[1]?.isCorrect, false);

    const seventy = scoreExam(generated.map((item, index) => ({ ...item, selectedSourceIndex: index < 70 ? 0 : 1 })));
    assert.equal(seventy.passed, true);
    assert.equal(seventy.honours, false);
    const eighty = scoreExam(generated.map((item, index) => ({ ...item, selectedSourceIndex: index < 80 ? 0 : 1 })));
    assert.equal(eighty.passed, true);
    assert.equal(eighty.honours, true);
  });
});
