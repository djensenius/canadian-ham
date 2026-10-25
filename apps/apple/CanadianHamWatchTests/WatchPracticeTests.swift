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
            XCTAssertFalse(["lessons", "quizzes", "hints", "figures", "figureassets.car", "readme.md"].contains(name), url.path)
            XCTAssertFalse(name.contains("advanced"), url.path)
        }
        let decoder = JSONDecoder()
        let original = try decoder.decode([Question].self, from: Data(contentsOf: root.appendingPathComponent("\(basicBankId)/questions.json")))
        XCTAssertEqual(bank.questions, original, "Never rewrite official EN/FR stems or choices")
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
        var first = WatchPracticeSession(load: { bank }, seed: "relaunch")
        first.submit(sourceIndex: first.choices[0].sourceIndex)
        first.next()
        first.submit(sourceIndex: first.choices[0].sourceIndex)
        let relaunched = WatchPracticeSession(load: { bank }, seed: "relaunch")
        XCTAssertNil(relaunched.submittedSourceIndex)
        XCTAssertNotEqual(first.question?.id, relaunched.question?.id)
    }

    func testFrenchExplanationFallbackHasEnglishAccessibilityLanguage() throws {
        let bank = try WatchPracticeBank.load()
        for explanation in bank.explanations.values {
            let fallback = WatchExplanationText(explanation: explanation, french: true)
            XCTAssertTrue(fallback.isEnglishFallback)
            XCTAssertEqual(fallback.languageIdentifier, "en-CA")
            XCTAssertEqual(fallback.body, explanation.body.en)
            XCTAssertTrue(fallback.attributedBody.runs.allSatisfy { $0.languageIdentifier == "en-CA" })
        }
        let original = try XCTUnwrap(bank.explanations.values.first)
        let translated = Explanation(id: original.id, questionId: original.questionId, bankId: original.bankId,
                                     status: original.status, body: .init(en: "English", fr: "Français"),
                                     citations: original.citations, licenseClass: original.licenseClass)
        let french = WatchExplanationText(explanation: translated, french: true)
        XCTAssertEqual(french.body, "Français")
        XCTAssertEqual(french.languageIdentifier, "fr-CA")
        XCTAssertFalse(french.isEnglishFallback)
    }

    // Sort first so the allocator has not already held a decoded bank in this process.
    func testAColdBundledPracticeLoadMeasurements() throws {
        try measureBundledPracticeLoad()
    }

    func testMeasureBundledPracticeLoad() throws {
        try measureBundledPracticeLoad()
    }

    private func measureBundledPracticeLoad() throws {
        let before = residentBytes()
        let start = ContinuousClock.now
        let bank = try WatchPracticeBank.load()
        let elapsed = start.duration(to: .now)
        let after = residentBytes()
        let root = try XCTUnwrap(Bundle.main.resourceURL)
        let files = try XCTUnwrap(FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey]))
            .compactMap { $0 as? URL }
        let logicalBytes = try files.reduce(0) { total, url in
            total + (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
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
