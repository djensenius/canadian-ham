import CanadianHamContent
import Foundation
import XCTest

final class QuestionBankTests: XCTestCase {
    func testAppBundleContainsOnlyExpectedGeneratedBankDirectories() throws {
        XCTAssertEqual(
            try bundledGeneratedBankIDs(in: Bundle.main),
            Set(["basic-2025-07-15", "advanced-2025-02-04"])
        )
    }

    func testBundledJSONDecodesExpectedCounts() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.manifest.counts.questions, 984)
        XCTAssertEqual(bank.manifest.counts.subsections, 100)
        XCTAssertEqual(bank.manifest.counts.categories, 8)
    }

    func testAdvancedBundledJSONDecodesExpectedCountsAndEnglishCategoryFallbacks() throws {
        let bank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))

        XCTAssertEqual(bank.manifest.bankId, CourseBankID.advanced.rawValue)
        XCTAssertEqual(bank.questions.count, 549)
        XCTAssertEqual(bank.subsections.count, 50)
        XCTAssertEqual(bank.categories.count, 7)
        XCTAssertTrue(bank.categories.allSatisfy { $0.name.fr == nil })
        XCTAssertEqual(bank.categories.first?.name.resolvedLanguage(for: .french), .english)
    }

    func testAdvancedMockExamUsesFiftyQuestionsAndNoHonours() throws {
        let bank = try QuestionBankStore.load(bankId: .advanced, from: Bundle(for: Self.self))
        let exam = try AppleStudyEngine.generatedMockExam(bank: bank, seed: "advanced-unit-mock")
        let selected = Dictionary(uniqueKeysWithValues: exam.items.enumerated().map { index, item in
            (item.questionId, index < 40 ? Optional(0) : Optional(1))
        })
        let attempt = try AppleStudyEngine.buildExamAttempt(
            bank: bank,
            seed: "advanced-unit-mock",
            startedAt: "2026-01-02T00:00:00.000Z",
            submittedAt: "2026-01-02T01:00:00.000Z",
            timerEnabled: false,
            secondsElapsed: 0,
            generatedItems: exam.items,
            selectedByQuestionId: selected,
            flaggedQuestionIds: []
        )

        XCTAssertEqual(exam.items.count, 50)
        XCTAssertEqual(Set(exam.items.map(\.subsectionId)).count, 50)
        XCTAssertEqual(attempt.bankId, CourseBankID.advanced.rawValue)
        XCTAssertEqual(attempt.score.total, 50)
        XCTAssertEqual(attempt.score.correct, 40)
        XCTAssertTrue(attempt.score.passed)
        XCTAssertFalse(attempt.score.honours)
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

    private func bundledGeneratedBankIDs(in bundle: Bundle) throws -> Set<String> {
        let generatedURL = try XCTUnwrap(bundle.resourceURL?.appendingPathComponent("generated", isDirectory: true))
        let resourceValues = try generatedURL.resourceValues(forKeys: [.isDirectoryKey])
        XCTAssertEqual(resourceValues.isDirectory, true, "Expected generated resources directory in \(bundle.bundleURL.path)")
        let urls = try FileManager.default.contentsOfDirectory(at: generatedURL, includingPropertiesForKeys: [.isDirectoryKey])
        return Set(try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            return values.isDirectory == true ? url.lastPathComponent : nil
        })
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
