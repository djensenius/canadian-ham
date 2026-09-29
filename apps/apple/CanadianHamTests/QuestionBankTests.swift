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

    func testTempShufflePreservesAnswerInvariantsForEveryBundledQuestion() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let seeds: [UInt64] = [
            0x0000_0000_0000_0001,
            0x1234_5678_9abc_def0,
            0x0fed_cba9_8765_4321,
            0xcafe_f00d_dead_beef,
            0xfeed_face_c001_d00d,
            0xffff_ffff_ffff_ffc5
        ]

        for question in bank.questions {
            let originalSourceIndexes = question.answers.map(\.sourceIndex)
            let originalSourceIndexSet = Set(originalSourceIndexes)
            let expectedCorrectSourceIndex = try XCTUnwrap(
                question.correctAnswer?.sourceIndex,
                "Question \(question.id) must have a correct answer"
            )
            var sawPermutation = false

            for seed in seeds {
                var generator = StableRandomNumberGenerator(seed: seed)
                let shuffledAnswers = TempShuffle.shuffledAnswers(for: question, using: &generator)
                let shuffledSourceIndexes = shuffledAnswers.map(\.sourceIndex)
                let correctAnswer = try XCTUnwrap(
                    TempShuffle.correctAnswer(in: shuffledAnswers),
                    "Question \(question.id), seed \(seed), must keep one correct answer"
                )

                XCTAssertEqual(shuffledAnswers.count, 4, "Question \(question.id), seed \(seed), must present four answers")
                XCTAssertEqual(shuffledAnswers.map(\.displayIndex), [0, 1, 2, 3], "Question \(question.id), seed \(seed), must reset display indexes")
                XCTAssertEqual(Set(shuffledSourceIndexes), originalSourceIndexSet, "Question \(question.id), seed \(seed), must preserve source indexes")
                XCTAssertEqual(shuffledAnswers.filter(\.isCorrect).count, 1, "Question \(question.id), seed \(seed), must have exactly one correct answer")
                XCTAssertEqual(correctAnswer.sourceIndex, expectedCorrectSourceIndex, "Question \(question.id), seed \(seed), must preserve correct-answer identity")

                if shuffledSourceIndexes != originalSourceIndexes {
                    sawPermutation = true
                }
            }

            XCTAssertTrue(sawPermutation, "Question \(question.id) should be permuted by at least one deterministic seed")
        }
    }
}

private struct StableRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
