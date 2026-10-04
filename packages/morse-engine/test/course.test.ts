import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  dailyStreak,
  emptyMorseCourseProgress,
  learnedCharactersForProgress,
  lessonState,
  parseMorseCourseFixture,
  recordMorseLessonAttempt,
  selectWeakestCharacters,
} from "../src/index.ts";

const courseFixture = JSON.parse(await readFile(join(process.cwd(), "../../fixtures/morse/course.json"), "utf8"));

describe("Morse Koch course fixture", () => {
  it("matches the approved ISED/G4FON course shape", () => {
    const course = parseMorseCourseFixture(courseFixture);
    expect(course.characterOrder).toEqual("K M R S U A P T L O W I . N J E F 0 Y , V G 5 / Q 9 Z H 3 8 B ? 4 2 7 C 1 D 6 X -".split(" "));
    expect(course.lessons).toHaveLength(40);
    expect(course.units).toHaveLength(8);
    expect(course.lessons[0]?.newCharacters).toEqual(["K", "M"]);
    expect(course.lessons[39]?.newCharacters).toEqual(["-"]);
  });

  it("unlocks the next lesson only at 90 percent accuracy", () => {
    const course = parseMorseCourseFixture(courseFixture);
    let progress = emptyMorseCourseProgress(course.courseId);
    expect(lessonState(course, progress, "koch-001")).toBe("current");
    expect(lessonState(course, progress, "koch-002")).toBe("locked");

    progress = recordMorseLessonAttempt({ course, progress, lessonId: "koch-001", correct: 8, total: 10, characterResults: [], attemptedAt: "2026-10-03T12:00:00.000Z" });
    expect(lessonState(course, progress, "koch-001")).toBe("current");
    expect(lessonState(course, progress, "koch-002")).toBe("locked");

    progress = recordMorseLessonAttempt({ course, progress, lessonId: "koch-001", correct: 9, total: 10, characterResults: [], attemptedAt: "2026-10-03T12:05:00.000Z" });
    expect(lessonState(course, progress, "koch-001")).toBe("completed");
    expect(lessonState(course, progress, "koch-002")).toBe("current");
    expect(dailyStreak(progress.dailyActivity, "2026-10-03T12:10:00.000Z")).toBe(1);
  });

  it("selects weakest learned characters by recent accuracy", () => {
    const course = parseMorseCourseFixture(courseFixture);
    const learned = learnedCharactersForProgress(course, emptyMorseCourseProgress(course.courseId));
    expect(selectWeakestCharacters([
      { character: "K", attempts: 4, correctAttempts: 4, recentResults: [true, true, true, true], lastPracticedAt: "2026-10-03T12:00:00.000Z" },
      { character: "M", attempts: 4, correctAttempts: 1, recentResults: [false, false, false, true], lastPracticedAt: "2026-10-03T12:00:00.000Z" },
    ], learned, 2)).toEqual(["M", "K"]);
  });
});
