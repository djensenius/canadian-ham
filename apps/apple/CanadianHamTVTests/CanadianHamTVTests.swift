import CanadianHamContent
import CanadianHamEngine
import XCTest

final class CanadianHamTVTests: XCTestCase {
    func testAppBundleContainsOnlyBasicQuestionBankResources() throws {
        let appBundle = try builtAppBundle(named: "CanadianHamTV")
        let bank = try QuestionBankStore.load(from: appBundle)

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.manifest.bankId, "basic-2025-07-15")
        XCTAssertEqual(try bundledGeneratedBankIDs(in: appBundle), ["basic-2025-07-15"])
        XCTAssertEqual(try bundledReadmePaths(in: appBundle), [], "tvOS app bundle must not contain README.md files")
        XCTAssertTrue(try bundledAdvancedResourcePaths(in: appBundle).isEmpty, "tvOS app bundle must not contain Advanced generated resources")
        let library = try ContentLibrary.load(from: appBundle)
        XCTAssertEqual(library.questionHints.count, 984)
        XCTAssertNotNil(library.questionHintsByQuestionId["B-001-002-002"])
    }

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

    private func builtAppBundle(named name: String) throws -> Bundle {
        let productsDirectory = Bundle(for: Self.self).bundleURL.deletingLastPathComponent()
        let appURL = productsDirectory.appendingPathComponent("\(name).app", isDirectory: true)
        return try XCTUnwrap(Bundle(url: appURL), "Expected built app bundle at \(appURL.path)")
    }

    private func bundledReadmePaths(in bundle: Bundle) throws -> [String] {
        let resourceURL = try XCTUnwrap(bundle.resourceURL)
        let urls = FileManager.default.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        )?.compactMap { $0 as? URL } ?? []

        return try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true, url.lastPathComponent.caseInsensitiveCompare("README.md") == .orderedSame else {
                return nil
            }
            return url.path.replacingOccurrences(of: resourceURL.path + "/", with: "")
        }
        .sorted()
    }

    private func bundledGeneratedBankIDs(in bundle: Bundle) throws -> Set<String> {
        guard let generatedURL = bundle.resourceURL?.appendingPathComponent("generated", isDirectory: true), FileManager.default.fileExists(atPath: generatedURL.path) else {
            return []
        }
        let resourceValues = try generatedURL.resourceValues(forKeys: [.isDirectoryKey])
        XCTAssertEqual(resourceValues.isDirectory, true, "Expected generated resources path to be a directory in \(bundle.bundleURL.path)")
        let urls = try FileManager.default.contentsOfDirectory(at: generatedURL, includingPropertiesForKeys: [.isDirectoryKey])
        return Set(try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            return values.isDirectory == true ? url.lastPathComponent : nil
        })
    }

    private func bundledAdvancedResourcePaths(in bundle: Bundle) throws -> [String] {
        let resourceURL = try XCTUnwrap(bundle.resourceURL)
        let urls = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey])?.compactMap { $0 as? URL } ?? []
        return urls
            .map { $0.path.replacingOccurrences(of: resourceURL.path + "/", with: "") }
            .filter { $0.contains("advanced-") || $0.contains("A-001") }
            .sorted()
    }

    @MainActor
    func testTVHintLadderHelpRecordingAndLessonAnchors() throws {
        let appBundle = try builtAppBundle(named: "CanadianHamTV")
        let library = try ContentLibrary.load(from: appBundle)
        let oneLevelHint = try XCTUnwrap(library.questionHintsByQuestionId["B-001-002-002"])
        let twoLevelHint = try XCTUnwrap(library.questionHintsByQuestionId["B-006-008-004"])

        XCTAssertEqual(oneLevelHint.hints.map(\.level), [1])
        XCTAssertNil(oneLevelHint.hints.first { $0.level == 2 }, "One-level files must not expose an empty Hint 2")
        XCTAssertEqual(twoLevelHint.hints.map(\.level), [1, 2])
        XCTAssertNotNil(twoLevelHint.lessonLink.sectionAnchor)

        let lesson = try XCTUnwrap(library.lessonsById[twoLevelHint.lessonLink.lessonId])
        let anchors = try LessonHeadingAnchors.anchors(for: lesson.bodyMarkdown, title: lesson.title.en)
        XCTAssertTrue(anchors.contains(try XCTUnwrap(twoLevelHint.lessonLink.sectionAnchor)))

        let qualification = PracticeHintRules.qualifyingHint(
            questionID: twoLevelHint.questionId,
            mode: .immediate,
            alreadySelected: false,
            reviewSubmitted: false,
            qualifiedQuestionIds: [],
            answeredWithHelpQuestionIds: []
        )
        XCTAssertTrue(qualification.qualifiedQuestionIds.contains(twoLevelHint.questionId))
        let selection = PlatformPracticeSelectionLogic.selectAnswer(
            questionID: twoLevelHint.questionId,
            qualifiedQuestionIds: qualification.qualifiedQuestionIds,
            answeredWithHelpQuestionIds: qualification.answeredWithHelpQuestionIds
        )
        XCTAssertTrue(selection.answeredWithHelp)
        XCTAssertTrue(selection.answeredWithHelpQuestionIds.contains(twoLevelHint.questionId), "tvOS selection records helped answers in the in-session answer state")

        XCTAssertEqual(HintVisibilityQualificationTimer.defaultDelayNanoseconds, 500_000_000, "tvOS uses the shared 0.5 s hint visibility rule")
        let updated = try applyAnswer(existing: nil, update: AnswerUpdate(
            questionId: twoLevelHint.questionId,
            bankId: "basic-2025-07-15",
            isCorrect: true,
            now: "2026-01-01T00:00:00.000Z",
            answeredWithHelp: true
        ))
        XCTAssertTrue(updated.lastAnsweredWithHelp)
        XCTAssertEqual(updated.recentAnsweredWithHelp, [true])
        XCTAssertEqual(updated.leitner.box, 0, "Helped correct answers must not advance mastery")
        XCTAssertEqual(updated.leitner.dueAt, "2026-01-01T00:00:00.000Z", "Helped correct answers remain due for spaced review")
        XCTAssertEqual(try dueCount(records: [updated], now: "2026-01-01T00:00:00.000Z"), 1)

        let secondHelped = try applyAnswer(existing: updated, update: AnswerUpdate(
            questionId: twoLevelHint.questionId,
            bankId: "basic-2025-07-15",
            isCorrect: true,
            now: "2026-01-01T00:01:00.000Z",
            answeredWithHelp: true
        ))
        XCTAssertEqual(weakSubsectionIds(records: [secondHelped]), ["B-006-008"], "Helped correct answers count as attempts without proficiency credit in weak-area calculations")
    }

    func testTVReferencePointersAreHiddenBecauseReferenceSheetIsUnavailable() {
        XCTAssertFalse(PlatformReferenceSheetAvailability.isAvailable)
        XCTAssertFalse(HintToolRules.showsReferencePointer(referenceSheetAvailable: PlatformReferenceSheetAvailability.isAvailable, visibleLevel: 1, referenceSheetSection: "ohms-law"))
    }

    func testTVPracticeSeedsVaryAcrossSessionIDs() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let category = try XCTUnwrap(bank.categories.first { $0.id == "B-001" })
        let questions = bank.questions(in: category)
        let sessionIDs = (0..<6).map { "tvos-session-\($0)" }

        let questionIDs = try Set(sessionIDs.compactMap { sessionID in
            try AppleQuestionShuffle.randomQuestion(
                from: questions,
                seed: "tvos-practice/\(category.id)/0/\(sessionID)"
            )?.id
        })
        let firstQuestion = try XCTUnwrap(questions.first)
        let answerOrders = try Set(sessionIDs.map { sessionID in
            try AppleQuestionShuffle.shuffledAnswers(
                for: firstQuestion,
                seed: "tvos-answers/\(firstQuestion.id)/0/\(sessionID)"
            )
            .map(\.sourceIndex)
        })

        XCTAssertGreaterThan(questionIDs.count, 1, "Practice question seeds should vary when the per-session launch ID changes")
        XCTAssertGreaterThan(answerOrders.count, 1, "Answer shuffle seeds should vary when the per-session launch ID changes")
    }
}
