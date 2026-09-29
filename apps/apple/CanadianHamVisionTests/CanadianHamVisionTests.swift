import XCTest

final class CanadianHamVisionTests: XCTestCase {
    func testBundledQuestionBankLoadsForVisionApp() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.manifest.bankId, "basic-2025-07-15")
    }

    func testVisionPracticeQuestionDrawStaysInCategoryAndShufflesAnswers() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let category = try XCTUnwrap(bank.categories.first { $0.id == "B-001" })
        let question = try XCTUnwrap(
            try AppleQuestionShuffle.randomQuestion(from: bank.questions(in: category), seed: "vision-unit/category-draw"),
            "Expected a deterministic visionOS practice draw"
        )
        let answers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "vision-unit/answers/\(question.id)")

        XCTAssertEqual(question.categoryId, category.id)
        XCTAssertEqual(answers.count, 4)
        XCTAssertEqual(Set(answers.map(\.sourceIndex)), Set(question.answers.map(\.sourceIndex)))
        XCTAssertEqual(answers.filter(\.isCorrect).count, 1)
    }
}
