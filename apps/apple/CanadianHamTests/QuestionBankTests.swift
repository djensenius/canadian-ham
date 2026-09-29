import Foundation
import XCTest

final class QuestionBankTests: XCTestCase {
    func testBundledJSONDecodesExpectedCounts() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.manifest.counts.questions, 984)
        XCTAssertEqual(bank.manifest.counts.subsections, 100)
        XCTAssertEqual(bank.manifest.counts.categories, 8)
    }

    func testTempShuffleKeepsCorrectAnswerIdentity() throws {
        let question = BankQuestion(
            id: "TEST-001",
            bankId: "test-bank",
            categoryId: "TEST",
            subsectionId: "TEST-001",
            sourceOrder: 1,
            text: LocalizedText(en: "Question", fr: "Question"),
            answers: [
                BankAnswer(sourceIndex: 0, isCorrect: true, text: LocalizedText(en: "Correct", fr: "Correcte")),
                BankAnswer(sourceIndex: 1, isCorrect: false, text: LocalizedText(en: "Distractor 1", fr: "Distracteur 1")),
                BankAnswer(sourceIndex: 2, isCorrect: false, text: LocalizedText(en: "Distractor 2", fr: "Distracteur 2")),
                BankAnswer(sourceIndex: 3, isCorrect: false, text: LocalizedText(en: "Distractor 3", fr: "Distracteur 3"))
            ]
        )
        var generator = StableRandomNumberGenerator()

        let shuffledAnswers = TempShuffle.shuffledAnswers(for: question, using: &generator)
        let sourceIndexes = Set(shuffledAnswers.map(\.sourceIndex))
        let correctAnswer = try XCTUnwrap(TempShuffle.correctAnswer(in: shuffledAnswers))

        XCTAssertEqual(shuffledAnswers.count, 4)
        XCTAssertEqual(sourceIndexes, Set([0, 1, 2, 3]))
        XCTAssertEqual(correctAnswer.sourceIndex, 0)
        XCTAssertTrue(correctAnswer.isCorrect)
    }
}

private struct StableRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64 = 0x1234_5678_9abc_def0

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
