import CanadianHamEngine
import Foundation

struct ShuffledAnswer: Hashable, Identifiable, Sendable {
    let answer: BankAnswer
    let displayIndex: Int

    var id: Int { answer.sourceIndex }
    var sourceIndex: Int { answer.sourceIndex }
    var isCorrect: Bool { answer.isCorrect }
}

enum AppleQuestionShuffle {
    static func randomQuestion(from questions: [BankQuestion], seed: String) throws -> BankQuestion? {
        guard !questions.isEmpty else { return nil }
        var rng = Pcg32(seed: seed)
        return try CanadianHamEngine.shuffled(questions, rng: &rng).first
    }

    static func shuffledAnswers(for question: BankQuestion, seed: String) throws -> [ShuffledAnswer] {
        var rng = Pcg32(seed: seed)
        return try CanadianHamEngine.shuffled(question.answers, rng: &rng)
            .enumerated()
            .map { offset, answer in
                ShuffledAnswer(answer: answer, displayIndex: offset)
            }
    }

    static func correctAnswer(in answers: [ShuffledAnswer]) -> ShuffledAnswer? {
        answers.first { $0.isCorrect }
    }
}
