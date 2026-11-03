import { Pcg32, shuffled } from "./rng.ts";

export interface LessonReviewPool {
  readonly lessonId: string;
  readonly questionIds: readonly string[];
}
export interface LessonReviewItem {
  readonly lessonId: string;
  readonly questionId: string;
}

/** Pools are in Learn's recommended order; exclusions include the current taught pool. */
export function selectLessonReviewItems(orderedPools: readonly LessonReviewPool[], lessonId: string, excludedQuestionIds: readonly string[], seed: string): LessonReviewItem[] {
  const index = orderedPools.findIndex((pool) => pool.lessonId === lessonId);
  if (index <= 0) return [];
  const seen = new Set(excludedQuestionIds);
  const recent: LessonReviewItem[] = [];
  const older: LessonReviewItem[] = [];
  for (let i = index - 1; i >= 0; i -= 1) {
    const pool = orderedPools[i]!;
    for (const questionId of [...pool.questionIds].sort()) {
      if (seen.has(questionId)) continue;
      seen.add(questionId);
      (i >= index - 3 ? recent : older).push({ lessonId: pool.lessonId, questionId });
    }
  }
  const rng = Pcg32.fromSeedString(`${seed}:review:${lessonId}`);
  return [...shuffled(recent, rng), ...shuffled(older, rng)].slice(0, 2);
}
