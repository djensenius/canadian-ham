import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { selectLessonReviewItems } from "../src/index.ts";

const fixture = JSON.parse(readFileSync(new URL("../../../fixtures/lesson-review.json", import.meta.url), "utf8"));
for (const item of fixture.cases) {
  test(`lesson-review shared fixture: ${item.id}`, () => {
    assert.deepEqual(selectLessonReviewItems(item.orderedPools, item.lessonId, item.excludedQuestionIds, item.seed), item.expected);
  });
}
