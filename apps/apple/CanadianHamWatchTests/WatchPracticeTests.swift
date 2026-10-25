import XCTest
import Darwin
import CanadianHamContent
import CanadianHamEngine
@testable import CanadianHamWatch

final class WatchPracticeTests: XCTestCase {
    func testWatchBundleContainsCompleteBasicBankAndOnlyPracticeContent() throws {
        let root = try XCTUnwrap(Bundle.main.resourceURL)
        let bank = try WatchPracticeBank.load()
        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(Set(bank.questions.map(\.id)).count, 984)
        XCTAssertEqual(Set(bank.explanations.keys), Set(bank.questions.map(\.id)))
        let files = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
            .compactMap { $0 as? URL }
        let jsonPaths = files.filter { $0.pathExtension == "json" }.map { String($0.path.dropFirst(root.path.count + 1)) }
        let expected = Set(["questions", "categories", "subsections", "manifest"].map { "\(basicBankId)/\($0).json" } + bank.questions.map {
            "explanations/\($0.categoryId.lowercased())/\($0.id.lowercased()).json"
        })
        XCTAssertEqual(Set(jsonPaths), expected)
        for url in files {
            let name = url.lastPathComponent.lowercased()
            XCTAssertFalse(["lessons", "quizzes", "hints", "figures", "readme.md"].contains(name), url.path)
            XCTAssertFalse(name.contains("advanced"), url.path)
            XCTAssertFalse(["svg", "png"].contains(url.pathExtension.lowercased()), "No loose figure images: \(url.path)")
        }
        let power = try XCTUnwrap(bank.questions.first { $0.id == "B-005-003-006" })
        XCTAssertEqual(power.text.en, "Power is expressed in:")
        XCTAssertEqual(power.text.fr, "La puissance s'exprime en:")
        XCTAssertEqual(power.answers.map(\.text.en), ["watts", "volts", "amperes", "ohms"])
        XCTAssertEqual(power.answers.map(\.text.fr), ["watts", "volts", "ampères", "ohms"])
    }

    func testSeededShuffleGradesSourceIndexNotDisplayPositionAndLocksSubmission() throws {
        let bank = try WatchPracticeBank.load()
        var movedCorrectAnswer = false
        for seed in 0..<20 {
            var correct = WatchPracticeSession(load: { bank }, seed: "watch-\(seed)")
            let same = WatchPracticeSession(load: { bank }, seed: "watch-\(seed)")
            XCTAssertEqual(correct.question, same.question)
            XCTAssertEqual(correct.choices, same.choices)
            XCTAssertEqual(Set(correct.choices.map(\.sourceIndex)), Set(0...3))
            let right = try XCTUnwrap(correct.choices.firstIndex(where: \.isCorrect))
            movedCorrectAnswer = movedCorrectAnswer || right != 0
            let sourceIndex = correct.choices[right].sourceIndex
            correct.submit(sourceIndex: sourceIndex)
            XCTAssertTrue(correct.isCorrect)
            correct.submit(sourceIndex: correct.choices.first(where: { !$0.isCorrect })!.sourceIndex)
            XCTAssertEqual(correct.submittedSourceIndex, sourceIndex)
            XCTAssertTrue(correct.isCorrect)

            var wrong = WatchPracticeSession(load: { bank }, seed: "watch-\(seed)")
            wrong.submit(sourceIndex: -1)
            XCTAssertNil(wrong.submittedSourceIndex)
            wrong.submit(sourceIndex: wrong.choices.first(where: { !$0.isCorrect })!.sourceIndex)
            XCTAssertFalse(wrong.isCorrect)
            let oldQuestion = wrong.question?.id
            wrong.next()
            XCTAssertNil(wrong.submittedSourceIndex)
            XCTAssertNotEqual(wrong.question?.id, oldQuestion)
            XCTAssertFalse(wrong.failed)
        }
        XCTAssertTrue(movedCorrectAnswer)
    }

    func testEmptyLoadErrorAndMissingResourcesFailSafely() throws {
        for session in [WatchPracticeSession(load: { WatchPracticeBank(questions: [], explanations: [:]) }),
                        WatchPracticeSession(load: { throw WatchPracticeError.unavailable })] {
            XCTAssertTrue(session.failed)
            XCTAssertNil(session.question)
            XCTAssertEqual(session.choices, [])
            var empty = session
            empty.submit(sourceIndex: 0)
            empty.next()
            XCTAssertNil(empty.submittedSourceIndex)
            XCTAssertTrue(empty.failed)
        }
        XCTAssertThrowsError(try WatchPracticeBank.load(resourceRoot: URL(fileURLWithPath: "/nonexistent-watch-resources")))
    }

    func testNewSessionRestoresNeitherAnswerNorQuestionSequence() throws {
        let bank = try WatchPracticeBank.load()
        var first = WatchPracticeSession(load: { bank }, seed: "3121")
        let initialQuestion = first.question
        let initialChoices = first.choices
        first.submit(sourceIndex: first.choices[0].sourceIndex)
        XCTAssertNotNil(first.submittedSourceIndex)
        first.next()
        let secondQuestion = first.question
        let secondChoices = first.choices
        first.submit(sourceIndex: first.choices[0].sourceIndex)
        XCTAssertNotNil(first.submittedSourceIndex)

        var relaunched = WatchPracticeSession(load: { bank }, seed: "3121")
        XCTAssertNil(relaunched.submittedSourceIndex)
        XCTAssertEqual(relaunched.question, initialQuestion, "Fresh session restarts the seeded RNG, not the old cursor")
        XCTAssertEqual(relaunched.choices, initialChoices)
        XCTAssertEqual(relaunched.question?.id, "B-005-003-006")
        relaunched.next()
        XCTAssertNil(relaunched.submittedSourceIndex)
        XCTAssertEqual(relaunched.question, secondQuestion)
        XCTAssertEqual(relaunched.choices, secondChoices)
        XCTAssertEqual(relaunched.question?.id, "B-001-016-001", "The UI seed has short, known first and second questions")
    }

    func testFrenchExplanationFallbackHasEnglishAccessibilityLanguage() throws {
        let bank = try WatchPracticeBank.load()
        for explanation in bank.explanations.values {
            let fallback = try WatchExplanationText(explanation: explanation, french: true)
            XCTAssertTrue(fallback.isEnglishFallback)
            XCTAssertEqual(fallback.languageIdentifier, "en-CA")
            let parsed = try ExplanationBodyParser.parse(explanation)
            XCTAssertTrue(fallback.body.hasPrefix(parsed.correctAnswerParagraph))
            for note in parsed.distractorNotes {
                XCTAssertTrue(fallback.body.contains("\"\(note.quotedChoice)\": \(note.note)"))
            }
            XCTAssertTrue(fallback.attributedBody.runs.allSatisfy { $0.languageIdentifier == "en-CA" })
        }
        let original = try XCTUnwrap(bank.explanations.values.first)
        let translatedBody = "Why the correct answer is right: Français\n\nWhy the distractors are wrong:\n- sourceIndex 1: \"Choix\": Note française."
        let translated = Explanation(id: original.id, questionId: original.questionId, bankId: original.bankId,
                                     status: original.status, body: .init(en: original.body.en, fr: translatedBody),
                                     citations: original.citations, licenseClass: original.licenseClass)
        let french = try WatchExplanationText(explanation: translated, french: true)
        XCTAssertEqual(french.body, "Français\n\n\"Choix\": Note française.")
        XCTAssertEqual(french.languageIdentifier, "fr-CA")
        XCTAssertFalse(french.isEnglishFallback)
        XCTAssertTrue(french.attributedBody.runs.allSatisfy { $0.languageIdentifier == "fr-CA" })
    }

    func testRenderedExplanationsNeverExposeAuthoringLabels() throws {
        let bank = try WatchPracticeBank.load()
        for explanation in bank.explanations.values {
            for french in [false, true] {
                let rendered = try WatchExplanationText(explanation: explanation, french: french)
                XCTAssertFalse(rendered.body.contains("sourceIndex"), explanation.questionId)
                XCTAssertFalse(rendered.body.contains("Question B-"), explanation.questionId)
                XCTAssertFalse(rendered.body.contains("Why the correct answer is right:"), explanation.questionId)
                let parsed = try ExplanationBodyParser.parse(explanation, language: french ? .fr : .en)
                XCTAssertEqual(rendered.body.components(separatedBy: "\n\n"), [parsed.correctAnswerParagraph] + parsed.distractorNotes.map {
                    "\"\($0.quotedChoice)\": \($0.note)"
                })
            }
        }
    }

    // Sort first. The assertion fails rather than calling an already-warmed host a cold load.
    @MainActor
    func testAColdBundledPracticeLoadMeasurements() async throws {
        _ = WatchHomeView()
        _ = WatchPracticeView()
        let count = await WatchPracticeBankLoader.shared.loadCount
        XCTAssertEqual(count, 0, "Home/view construction must not decode practice resources")
        try await measureBundledPracticeLoad()
        let loadedCount = await WatchPracticeBankLoader.shared.loadCount
        XCTAssertEqual(loadedCount, 1)
    }

    @MainActor
    func testMeasureBundledPracticeLoad() async throws {
        async let first = WatchPracticeBankLoader.shared.load()
        async let second = WatchPracticeBankLoader.shared.load()
        let banks = try await (first, second)
        XCTAssertEqual(banks.0.questions, banks.1.questions)
        let count = await WatchPracticeBankLoader.shared.loadCount
        XCTAssertEqual(count, 1, "Concurrent and subsequent visits share the same decode task")
        try await measureBundledPracticeLoad()
    }

    @MainActor
    private func measureBundledPracticeLoad() async throws {
        let before = residentBytes()
        let start = ContinuousClock.now
        let bank = try await WatchPracticeBankLoader.shared.load()
        let elapsed = start.duration(to: .now)
        let after = residentBytes()
        let root = try XCTUnwrap(Bundle.main.resourceURL)
        let files = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]))
            .compactMap { $0 as? URL }
        let logicalBytes = try files.reduce(0) { total, url in
            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            return total + (values.isRegularFile == true ? (values.fileSize ?? 0) : 0)
        }
        let report = "WatchSimulator practice: questions=\(bank.questions.count), explanations=\(bank.explanations.count), load=\(elapsed), residentBefore=\(before), residentAfter=\(after), residentDelta=\(Int64(after) - Int64(before)), bundleLogicalBytes=\(logicalBytes)"
        print(report)
        let attachment = XCTAttachment(string: report)
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(bank.questions.count, 984)
    }

    private func residentBytes() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
}
