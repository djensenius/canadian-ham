import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  buildMorseLessonExercises,
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

  it("rejects course fixtures with unexpected unit IDs", () => {
    const invalidFixture = JSON.parse(JSON.stringify(courseFixture));
    invalidFixture.units[0].id = "unit-99";

    expect(() => parseMorseCourseFixture(invalidFixture)).toThrow(/Morse unit unit-99 is out of order/);
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
    expect(dailyStreak(progress.dailyActivity, "2026-10-04T00:10:00.000Z")).toBe(1);
    expect(dailyStreak(progress.dailyActivity, "2026-10-05T00:10:00.000Z")).toBe(0);
  });

  it("builds seeded real lesson exercises with both lesson-one characters and meaningful scoring", () => {
    const course = parseMorseCourseFixture(courseFixture);
    const lesson = course.lessons[0]!;

    const exercises = buildMorseLessonExercises({ lesson, seed: "lesson-one" });
    const scored = exercises.filter((exercise) => exercise.kind !== "meet");
    const options = exercises.filter((exercise) => exercise.kind === "choose").map((exercise) => exercise.options.join(""));
    const groups = exercises.filter((exercise) => exercise.kind === "type-group").map((exercise) => exercise.text);

    expect(exercises.slice(0, 2)).toEqual([{ kind: "meet", character: "K" }, { kind: "meet", character: "M" }]);
    expect(scored.length).toBeGreaterThanOrEqual(15);
    expect(scored.length).toBeLessThanOrEqual(25);
    expect(options.every((entry) => entry.length >= 2)).toBe(true);
    expect(options.some((entry) => !entry.endsWith("K"))).toBe(true);
    expect(groups.every((group) => group.length === 5 && [...group].every((character) => lesson.learnedCharacters.includes(character)))).toBe(true);
    expect(buildMorseLessonExercises({ lesson, seed: "lesson-one" })).toEqual(exercises);
    expect(buildMorseLessonExercises({ lesson, seed: "lesson-one-other" })).not.toEqual(exercises);
  });

  it("weights later lesson practice toward new and weak characters", () => {
    const course = parseMorseCourseFixture(courseFixture);
    const lesson = course.lessons[4]!;
    const progress = {
      ...emptyMorseCourseProgress(course.courseId),
      characterStats: [
        { character: "K", attempts: 5, correctAttempts: 5, recentResults: [true, true, true, true, true], lastPracticedAt: "2026-10-03T12:00:00.000Z" },
        { character: "U", attempts: 5, correctAttempts: 1, recentResults: [false, false, false, false, true], lastPracticedAt: "2026-10-03T12:00:00.000Z" },
      ],
    };

    const exercises = buildMorseLessonExercises({ lesson, progress, seed: "weak-weight" });
    const targets = exercises.flatMap((exercise) => {
      if (exercise.kind === "choose" || exercise.kind === "type-character") return [exercise.character];
      if (exercise.kind === "type-group") return [...exercise.text];
      return [];
    });

    expect(targets.filter((character) => character === "A").length).toBeGreaterThan(0);
    expect(targets.filter((character) => character === "U").length).toBeGreaterThan(0);
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
