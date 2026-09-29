import XCTest

final class CanadianHamTVTests: XCTestCase {
    func testBundledQuestionBankLoadsForTVApp() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.manifest.bankId, "basic-2025-07-15")
    }

    func testTVPracticeQuestionDrawStaysInCategoryAndShufflesAnswers() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let category = try XCTUnwrap(bank.categories.first { $0.id == "B-001" })
        let question = try XCTUnwrap(
            try AppleQuestionShuffle.randomQuestion(from: bank.questions(in: category), seed: "tvos-unit/category-draw"),
            "Expected a deterministic tvOS practice draw"
        )
        let answers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "tvos-unit/answers/\(question.id)")

        XCTAssertEqual(question.categoryId, category.id)
        XCTAssertEqual(answers.count, 4)
        XCTAssertEqual(Set(answers.map(\.sourceIndex)), Set(question.answers.map(\.sourceIndex)))
        XCTAssertEqual(answers.filter(\.isCorrect).count, 1)
    }
}
