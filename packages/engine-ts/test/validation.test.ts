import assert from "node:assert/strict";
import test from "node:test";
import { applyAnswer, computeReadiness, generateExam } from "../src/index.ts";
import { compareOrdinal } from "../src/ordinal.ts";

const oneSubsection = [{ id: "B-001-001", questionIds: ["B-001-001-001"] }];

test("exam generation requires canonical answerSourceIndexes", () => {
  assert.throws(
    () => generateExam({ bankId: "basic-2025-07-15", seed: "seed", subsections: oneSubsection, answerSourceIndexes: [3, 2, 1, 0] }),
    /answerSourceIndexes must be exactly \[0,1,2,3\]/,
  );
  assert.throws(
    () => generateExam({ bankId: "basic-2025-07-15", seed: "seed", subsections: oneSubsection, answerSourceIndexes: [0, 5, 6, 7] }),
    /answerSourceIndexes must be exactly \[0,1,2,3\]/,
  );
});

test("readiness rejects duplicate submittedAt timestamps", () => {
  const attempt = {
    submittedAt: "2026-01-05T00:00:00.000Z",
    score: { correct: 90, total: 100, percent: 90 },
    categoryBreakdown: [{ categoryId: "B-001", correct: 9, total: 10, percent: 90 }],
  };

  assert.throws(
    () => computeReadiness({ completedExams: [attempt, attempt], dueReviewCount: 0 }),
    /completedExams must not contain duplicate submittedAt timestamp 2026-01-05T00:00:00\.000Z/,
  );
});

test("engine timestamp inputs require canonical millisecond UTC format", () => {
  assert.throws(
    () => applyAnswer(null, { questionId: "B-006-004-001", bankId: "basic-2025-07-15", isCorrect: true, now: "2026-01-02T00:00:00Z" }),
    /update\.now must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS\.sssZ/,
  );
});

test("ordinal sorting compares UTF-8 bytes instead of UTF-16 code units", () => {
  const nonBmp = "\u{10000}";
  const privateUseBmp = "\uE000";

  assert.equal(nonBmp < privateUseBmp, true, "JavaScript's native string comparison uses UTF-16 order for this pair");
  assert.equal(compareOrdinal(privateUseBmp, nonBmp), -1);
  assert.deepEqual([nonBmp, privateUseBmp].toSorted(compareOrdinal), [privateUseBmp, nonBmp]);
});
