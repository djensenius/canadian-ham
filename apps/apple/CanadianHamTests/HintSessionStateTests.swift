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

    func testHingePeekRequiresStableDwellInSlightOpenBand() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2))

        XCTAssertFalse(machine.update(status: .closed, angleDegrees: 0, timestamp: 0))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.1))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.75))
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.81))
    }

    func testHingePeekFastUnfoldThroughBandNeverPeeks() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2))

        XCTAssertFalse(machine.update(status: .closed, angleDegrees: 0, timestamp: 0))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 22, timestamp: 0.1))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 30, timestamp: 0.25))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 34, timestamp: 0.35))
        XCTAssertFalse(machine.update(status: .unfolded, angleDegrees: 180, timestamp: 0.45))
    }

    func testHingePeekToleratesSmallJitterAtBandEdges() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 20, timestamp: 0))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 19.2, timestamp: 0.25), "Small edge jitter should not reset the stable dwell candidate")
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 20.5, timestamp: 0.72), "Returning inside the band after tolerated jitter should peek once the original dwell elapsed")
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 36.5, timestamp: 0.9), "A visible peek may continue through tolerated edge jitter")
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 38.1, timestamp: 1.0), "Jitter outside the tolerance ends the peek")
    }

    func testHingePeekEndsWhenPhoneFullyOpensOrCloses() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0))
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.8))
        XCTAssertFalse(machine.update(status: .unfolded, angleDegrees: 180, timestamp: 0.9))
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 1.0), "After fully opening, a new dwell must start")
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 1.8))
        XCTAssertFalse(machine.update(status: .closed, angleDegrees: 0, timestamp: 1.9))
    }

    func testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer() {
        XCTAssertTrue(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: true, alreadySelected: true, reviewSubmitted: false))
        XCTAssertTrue(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.immediate), hasHint: true, alreadySelected: false, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.immediate), hasHint: true, alreadySelected: true, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: true, alreadySelected: true, reviewSubmitted: true))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: false, alreadySelected: false, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .mockExam, hasHint: true, alreadySelected: false, reviewSubmitted: false))
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

    func testPeekRouteUsesVisibilityTimerBeforeQualifyingAnsweredWithHelp() async throws {
        let questionID = "B-001-002-002"
        let timer = HintVisibilityQualificationTimer()
        var qualifiedQuestionIds: Set<String> = []
        var answeredWithHelpQuestionIds: Set<String> = []

        timer.begin(questionID: questionID, canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 200_000_000) {
            let result = PracticeHintRules.qualifyingHint(
                questionID: questionID,
                mode: .immediate,
                alreadySelected: false,
                reviewSubmitted: false,
                qualifiedQuestionIds: qualifiedQuestionIds,
                answeredWithHelpQuestionIds: answeredWithHelpQuestionIds
            )
            qualifiedQuestionIds = result.qualifiedQuestionIds
            answeredWithHelpQuestionIds = result.answeredWithHelpQuestionIds
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(qualifiedQuestionIds, [], "A peek reveal must not count as help before the shared 0.5 s visibility rule fires")
        try await Task.sleep(nanoseconds: 180_000_000)
        XCTAssertEqual(qualifiedQuestionIds, [questionID])
        XCTAssertEqual(answeredWithHelpQuestionIds, [])
    }

    func testVisibilityTimerDoesNotRestartForSameQuestionAndCancelsOnQuestionChange() async throws {
        let timer = HintVisibilityQualificationTimer()
        var fired: [String] = []

        // Margins of at least 150 ms on every check keep this deterministic on loaded simulators.
        // Same question: a restart would fire at 1300 ms; the original fires at 1000 ms. Check at 1150 ms.
        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 1_000_000_000) {
            fired.append("first")
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 1_000_000_000) {
            fired.append("restarted")
        }
        try await Task.sleep(nanoseconds: 850_000_000)
        XCTAssertEqual(fired, ["first"], "Beginning the same visible question again must not restart the 0.5 s qualification window")

        // Question change: B-001-002-003 would fire 400 ms after B-001-002-004 begins; B-001-002-004 fires at 900 ms.
        timer.begin(questionID: "B-001-002-003", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 600_000_000) {
            fired.append("second")
        }
        try await Task.sleep(nanoseconds: 200_000_000)
        timer.begin(questionID: "B-001-002-004", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 900_000_000) {
            fired.append("third")
        }
        try await Task.sleep(nanoseconds: 650_000_000)
        XCTAssertEqual(fired, ["first"], "Changing questions before the delay must cancel the previous qualification timer")
        try await Task.sleep(nanoseconds: 450_000_000)
        XCTAssertEqual(fired, ["first", "third"], "The timer for the newly visible question should still qualify after its full delay")
    }
}
