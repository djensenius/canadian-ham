import assert from "node:assert/strict";
import test from "node:test";
import { applyAnswer, computeReadiness, generateExam, rulesForBankId, scoreExam, SYNTHETIC_ADVANCED_BANK_ID, type ExamSubsectionInput } from "../src/index.ts";
import { compareOrdinal } from "../src/ordinal.ts";

const oneSubsection = [{ id: "B-001-001", questionIds: ["B-001-001-001"] }];

function makeSubsections(prefix: "A" | "B", count: number): ExamSubsectionInput[] {
  return Array.from({ length: count }, (_, index) => {
    const ordinal = String(index + 1).padStart(3, "0");
    const subsectionId = `${prefix}-001-${ordinal}`;
    return { id: subsectionId, questionIds: [`${subsectionId}-001`] };
  });
}

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

test("full mock exam generation uses the active bank subsection count", () => {
  assert.throws(
    () => generateExam({ bankId: SYNTHETIC_ADVANCED_BANK_ID, seed: "seed", subsections: makeSubsections("A", 100), requireFullMockExam: true }),
    /full mock exam generation for advanced-synthetic requires exactly 50 subsections; received 100/,
  );
  assert.throws(
    () => generateExam({ bankId: "basic-2025-07-15", seed: "seed", subsections: makeSubsections("B", 50), requireFullMockExam: true }),
    /full mock exam generation for basic-2025-07-15 requires exactly 100 subsections; received 50/,
  );
});

test("practice exam generation does not require known bank rules unless a full mock is requested", () => {
  const generated = generateExam({ bankId: "unknown-bank", seed: "seed", subsections: oneSubsection });
  assert.equal(generated.bankId, "unknown-bank");
  assert.equal(generated.items.length, 1);

  assert.throws(
    () => generateExam({ bankId: "unknown-bank", seed: "seed", subsections: oneSubsection, requireFullMockExam: true }),
    /unsupported bankId unknown-bank/,
  );
});

test("bank rules accept only schema-valid Advanced ids", () => {
  assert.equal(rulesForBankId("advanced-2026-01-15").bankId, "advanced-2026-01-15");
  for (const bankId of ["advanced-", "advanced-X", "advanced-2026_01", "advanced-2026 01"]) {
    assert.throws(() => rulesForBankId(bankId), new RegExp(`unsupported bankId ${bankId}`));
  }
});

test("scoreExam rejects unsupported bankIds", () => {
  assert.throws(
    () => scoreExam([{ questionId: "B-001-001-001", selectedSourceIndex: 0 }], { bankId: "unknown-bank" }),
    /unsupported bankId unknown-bank/,
  );
});

test("advanced readiness treats the 70 percent pass threshold as inclusive", () => {
  const categoryBreakdown = [{ categoryId: "A-001", correct: 50, total: 50, percent: 100 }];
  const result = computeReadiness({
    bankId: SYNTHETIC_ADVANCED_BANK_ID,
    completedExams: [
      { submittedAt: "2026-01-03T00:00:00.000Z", score: { correct: 35, total: 50, percent: 70 }, categoryBreakdown },
      { submittedAt: "2026-01-02T00:00:00.000Z", score: { correct: 34, total: 50, percent: 68 }, categoryBreakdown },
    ],
    dueReviewCount: 0,
  });

  assert.deepEqual(result, {
    state: "needs-review",
    consideredExamCount: 2,
    consideredSubmittedAt: ["2026-01-03T00:00:00.000Z", "2026-01-02T00:00:00.000Z"],
    reasons: [],
  });
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
