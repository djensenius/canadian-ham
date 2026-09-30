import CanadianHamContent
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

    func testEngineShufflePreservesAnswerInvariantsForEveryBundledQuestion() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let seeds = [
            "apple-engine-shuffle-1",
            "apple-engine-shuffle-2",
            "apple-engine-shuffle-3",
            "apple-engine-shuffle-4",
            "apple-engine-shuffle-5",
            "apple-engine-shuffle-6"
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
                let shuffledAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "\(seed)/\(question.id)")
                let shuffledSourceIndexes = shuffledAnswers.map(\.sourceIndex)
                let correctAnswer = try XCTUnwrap(
                    AppleQuestionShuffle.correctAnswer(in: shuffledAnswers),
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

            XCTAssertTrue(sawPermutation, "Question \(question.id) should be permuted by at least one deterministic engine seed")
        }
    }

    func testEngineQuestionDrawKeepsQuestionInsideRequestedCategory() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        for category in bank.categories {
            let questions = bank.questions(in: category)
            let drawn = try XCTUnwrap(
                try AppleQuestionShuffle.randomQuestion(from: questions, seed: "category-draw/\(category.id)"),
                "Category \(category.id) should draw a question"
            )
            XCTAssertEqual(drawn.categoryId, category.id)
        }
    }

    func testRealBundleKnownLessonIdsCoverBundledContentLibraryLessons() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self)).withKnownLessonIds(Set(library.lessons.map(\.id)))

        XCTAssertEqual(bank.knownLessonIds.count, library.lessons.count)
        XCTAssertEqual(bank.knownLessonIds, Set(library.lessons.map(\.id)))
        XCTAssertTrue(bank.knownLessonIds.contains("L-005-01"))
    }

    func testBundledLessonsAndExplanationsLoadThroughContentLibrary() throws {
        let library = try ContentLibrary.load(from: Bundle(for: Self.self))

        XCTAssertEqual(library.lessons.count, library.orderedLessons().count)
        XCTAssertFalse(library.lessons.isEmpty)
        XCTAssertEqual(library.explanations.count, library.questions.count)
        for lesson in library.lessons {
            XCTAssertNoThrow(try LessonMarkdownRenderer.render(lesson.bodyMarkdown), "Lesson \(lesson.id) should render")
        }
        for explanation in library.explanations {
            XCTAssertNoThrow(try ExplanationBodyParser.parse(explanation), "Explanation \(explanation.id) should parse")
        }
    }

    func testKnownLessonIdsComeFromSubsectionLessonMappingsWithoutQuizzes() {
        let bank = QuestionBank(
            questions: [],
            categories: [],
            subsections: [
                BankSubsection(
                    id: "B-TEST-001",
                    bankId: "test-bank",
                    categoryId: "B-TEST",
                    questionIds: [],
                    questionCount: 0,
                    lessonIds: ["L-WITHOUT-QUIZ"],
                    title: LocalizedText(en: "Synthetic subsection", fr: nil)
                )
            ],
            manifest: BankManifest(
                bankId: "test-bank",
                certificate: "Basic",
                effectiveDate: "2026-01-01",
                source: BankManifest.Source(path: "synthetic", sha256: "", url: "", encoding: "utf-8", lineEndings: "lf"),
                importer: BankManifest.Importer(name: "synthetic", version: "test"),
                counts: BankManifest.Counts(questions: 0, categories: 0, subsections: 1)
            ),
            lessonQuizzes: []
        )

        XCTAssertEqual(bank.knownLessonIds, Set(["L-WITHOUT-QUIZ"]))
    }
}
