import type { Answer } from "../data/bank";

export interface ShuffledAnswers<TAnswer extends Pick<Answer, "isCorrect" | "sourceIndex">> {
  readonly answers: readonly TAnswer[];
  readonly correctDisplayIndex: number;
  readonly correctSourceIndex: number;
}

// Temporary answer shuffling for the first usable web slice; replace with @canadian-ham/engine-ts.
export function shuffleAnswers<TAnswer extends Pick<Answer, "isCorrect" | "sourceIndex">>(
  answers: readonly TAnswer[],
  random: () => number = Math.random,
): ShuffledAnswers<TAnswer> {
  const shuffled = [...answers];
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex]!, shuffled[index]!];
  }

  const correctDisplayIndex = shuffled.findIndex((answer) => answer.isCorrect);
  if (correctDisplayIndex === -1) {
    throw new Error("cannot shuffle answers: no correct answer found");
  }

  return {
    answers: shuffled,
    correctDisplayIndex,
    correctSourceIndex: shuffled[correctDisplayIndex]!.sourceIndex,
  };
}
