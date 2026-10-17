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
    }

    func testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange() async throws {
        let timer = HintVisibilityQualificationTimer()
        var fired: [String] = []

        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 80_000_000) {
            fired.append("first")
        }
        try await Task.sleep(nanoseconds: 30_000_000)
        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 80_000_000) {
            fired.append("restarted")
        }
        try await Task.sleep(nanoseconds: 70_000_000)
        XCTAssertEqual(fired, ["first"], "Beginning the same visible question again must not restart the 0.5 s qualification window")

        timer.begin(questionID: "B-001-002-003", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 80_000_000) {
            fired.append("second")
        }
        timer.cancel()
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(fired, ["first"], "Closing the hint or changing away before the delay must not qualify help")
    }
}
