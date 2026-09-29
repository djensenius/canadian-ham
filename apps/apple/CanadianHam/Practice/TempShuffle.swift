import Foundation

struct ShuffledAnswer: Hashable, Identifiable, Sendable {
    let answer: BankAnswer
    let displayIndex: Int

    var id: Int { answer.sourceIndex }
    var sourceIndex: Int { answer.sourceIndex }
    var isCorrect: Bool { answer.isCorrect }
}

enum TempShuffle {
    /// Temporary answer shuffler for the first usable Apple slice.
    /// Replace with packages/engine-swift once the shared Swift engine is available.
    static func shuffledAnswers<RNG: RandomNumberGenerator>(
        for question: BankQuestion,
        using generator: inout RNG
    ) -> [ShuffledAnswer] {
        question.answers
            .shuffled(using: &generator)
            .enumerated()
            .map { offset, answer in
                ShuffledAnswer(answer: answer, displayIndex: offset)
            }
    }

    static func correctAnswer(in answers: [ShuffledAnswer]) -> ShuffledAnswer? {
        answers.first { $0.isCorrect }
    }
}
