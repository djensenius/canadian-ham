import { Pcg32, shuffled } from "@canadian-ham/engine-ts";

import type { Answer } from "../data/bank";

export interface ShuffledAnswers<TAnswer extends Pick<Answer, "isCorrect" | "sourceIndex">> {
  readonly answers: readonly TAnswer[];
  readonly choicePermutation: readonly number[];
  readonly correctDisplayIndex: number;
  readonly correctSourceIndex: number;
}

export function shuffleAnswersWithSeed<TAnswer extends Pick<Answer, "isCorrect" | "sourceIndex">>(
  answers: readonly TAnswer[],
  seed: string,
): ShuffledAnswers<TAnswer> {
  const bySourceIndex = new Map(answers.map((answer) => [answer.sourceIndex, answer]));
  const sourceIndexes = answers.map((answer) => answer.sourceIndex);
  const choicePermutation = shuffled(sourceIndexes, Pcg32.fromSeedString(seed));
  const shuffledAnswers = choicePermutation.map((sourceIndex) => {
    const answer = bySourceIndex.get(sourceIndex);
    if (answer === undefined) {
      throw new Error(`cannot shuffle answers: missing source index ${sourceIndex}`);
    }
    return answer;
  });
  const correctDisplayIndex = shuffledAnswers.findIndex((answer) => answer.isCorrect);
  if (correctDisplayIndex === -1) {
    throw new Error("cannot shuffle answers: no correct answer found");
  }

  return {
    answers: shuffledAnswers,
    choicePermutation,
    correctDisplayIndex,
    correctSourceIndex: shuffledAnswers[correctDisplayIndex]!.sourceIndex,
  };
}
