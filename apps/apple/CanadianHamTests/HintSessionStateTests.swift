import CanadianHamEngine
import XCTest

@MainActor
final class HintSessionStateTests: XCTestCase {
    func testHintQualificationMarksUnansweredQuestionAsQualifiedOnly() {
        let result = PracticeHintRules.qualifyingHint(
            questionID: "B-001-002-002",
            mode: .immediate,
            alreadySelected: false,
            reviewSubmitted: false,
            qualifiedQuestionIds: [],
            answeredWithHelpQuestionIds: []
        )

        XCTAssertEqual(result.qualifiedQuestionIds, ["B-001-002-002"])
        XCTAssertEqual(result.answeredWithHelpQuestionIds, [])
        XCTAssertTrue(PracticeHintRules.shouldCommitAnswerWithHelp(questionID: "B-001-002-002", qualifiedQuestionIds: result.qualifiedQuestionIds, answeredWithHelpQuestionIds: result.answeredWithHelpQuestionIds))
        XCTAssertTrue(PracticeHintRules.shouldSubmitAnswerWithHelp(questionID: "B-001-002-002", qualifiedQuestionIds: result.qualifiedQuestionIds, answeredWithHelpQuestionIds: result.answeredWithHelpQuestionIds))
    }

    func testImmediateModeHintAfterScoredAnswerDoesNotRecordHelp() {
        let result = PracticeHintRules.qualifyingHint(
            questionID: "B-001-002-002",
            mode: .immediate,
            alreadySelected: true,
            reviewSubmitted: false,
            qualifiedQuestionIds: [],
            answeredWithHelpQuestionIds: []
        )

        XCTAssertEqual(result.qualifiedQuestionIds, [])
        XCTAssertEqual(result.answeredWithHelpQuestionIds, [])
        XCTAssertFalse(PracticeHintRules.canRecordHelp(mode: .immediate, alreadySelected: true, reviewSubmitted: false))
    }

    func testReviewLaterHintAfterSelectionRecordsHelp() {
        let result = PracticeHintRules.qualifyingHint(
            questionID: "B-001-002-002",
            mode: .reviewLater,
            alreadySelected: true,
            reviewSubmitted: false,
            qualifiedQuestionIds: [],
            answeredWithHelpQuestionIds: []
        )

        XCTAssertEqual(result.qualifiedQuestionIds, ["B-001-002-002"])
        XCTAssertEqual(result.answeredWithHelpQuestionIds, ["B-001-002-002"])
    }

    func testSelectingAfterQualifiedHintRecordsHelpForReviewLaterSubmission() {
        let answered = PracticeHintRules.answeredWithHelpQuestionIdsAfterSelection(
            questionID: "B-001-002-002",
            qualifiedQuestionIds: ["B-001-002-002"],
            answeredWithHelpQuestionIds: []
        )

        XCTAssertEqual(answered, ["B-001-002-002"])
        XCTAssertTrue(PracticeHintRules.shouldSubmitAnswerWithHelp(questionID: "B-001-002-002", qualifiedQuestionIds: [], answeredWithHelpQuestionIds: answered))
    }

    func testReferencePointerRuleShowsOnlyWhenReferenceSheetIsAvailable() {
        XCTAssertTrue(HintToolRules.showsReferencePointer(referenceSheetAvailable: true, visibleLevel: 1, referenceSheetSection: "ohms-law"))
        XCTAssertFalse(HintToolRules.showsReferencePointer(referenceSheetAvailable: false, visibleLevel: 1, referenceSheetSection: "ohms-law"))
        XCTAssertFalse(HintToolRules.showsReferencePointer(referenceSheetAvailable: true, visibleLevel: 0, referenceSheetSection: "ohms-law"))
        XCTAssertFalse(HintToolRules.showsReferencePointer(referenceSheetAvailable: true, visibleLevel: 1, referenceSheetSection: nil))
    }

    func testApplyPracticeAnswerSubmitsAnsweredWithHelpToEngine() throws {
        let question = BankQuestion(
            id: "B-006-004-001",
            bankId: CourseBankID.basic.rawValue,
            categoryId: "B-006",
            subsectionId: "B-006-004",
            sourceOrder: 1,
            text: LocalizedText(en: "Sample question", fr: "Exemple"),
            answers: [
                BankAnswer(sourceIndex: 0, isCorrect: true, text: LocalizedText(en: "Correct", fr: "Correct")),
                BankAnswer(sourceIndex: 1, isCorrect: false, text: LocalizedText(en: "Wrong", fr: "Incorrect")),
                BankAnswer(sourceIndex: 2, isCorrect: false, text: LocalizedText(en: "Wrong", fr: "Incorrect")),
                BankAnswer(sourceIndex: 3, isCorrect: false, text: LocalizedText(en: "Wrong", fr: "Incorrect"))
            ]
        )

        let records = try AppleStudyEngine.applyPracticeAnswer(
            progress: [],
            question: question,
            selectedSourceIndex: 0,
            now: "2026-01-02T00:00:00.000Z",
            answeredWithHelp: true
        )
        let record = try XCTUnwrap(records.first)

        XCTAssertTrue(record.lastAnsweredWithHelp)
        XCTAssertEqual(record.recentAnsweredWithHelp, [true])
        XCTAssertEqual(record.leitner.box, 0)
        XCTAssertEqual(record.leitner.dueAt, "2026-01-02T00:00:00.000Z")
    }

    func testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange() async throws {
        let timer = HintVisibilityQualificationTimer()
        var fired: [String] = []

        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 400_000_000) {
            fired.append("first")
        }
        try await Task.sleep(nanoseconds: 150_000_000)
        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 400_000_000) {
            fired.append("restarted")
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(fired, ["first"], "Beginning the same visible question again must not restart the 0.5 s qualification window")

        timer.begin(questionID: "B-001-002-003", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 350_000_000) {
            fired.append("second")
        }
        try await Task.sleep(nanoseconds: 150_000_000)
        timer.begin(questionID: "B-001-002-004", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 350_000_000) {
            fired.append("third")
        }
        try await Task.sleep(nanoseconds: 250_000_000)
        XCTAssertEqual(fired, ["first"], "Changing questions before the delay must cancel the previous qualification timer")
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertEqual(fired, ["first", "third"], "The timer for the newly visible question should still qualify after its full delay")
    }
}
