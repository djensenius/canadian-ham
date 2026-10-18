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
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .closed, angleDegrees: 0, timestamp: 0).isPeeking)
        XCTAssertEqual(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.1).pendingDwellDeadline ?? -1, 0.8, accuracy: 0.000_001)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.75).isPeeking)
        let result = machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.81)
        XCTAssertTrue(result.isPeeking)
        XCTAssertTrue(result.startedPeeking)
    }

    func testHingePeekRecheckPeeksWithoutNewSamples() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        let candidate = machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 10)
        XCTAssertFalse(candidate.isPeeking)
        XCTAssertEqual(candidate.pendingDwellDeadline ?? -1, 10.7, accuracy: 0.000_001)

        let recheck = machine.recheck(timestamp: 10.7)
        XCTAssertTrue(recheck.isPeeking, "A single in-band sample should qualify when the scheduled dwell re-check fires with the last posture sample")
        XCTAssertTrue(recheck.startedPeeking)
    }

    func testHingePeekStartsOnlyInsideRealBandAndDoesNotUseEdgeJitterBeforePeek() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 37, timestamp: 0).isPeeking)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 37, timestamp: 1.0).isPeeking)
        let boundary = machine.update(status: .partiallyOpen, angleDegrees: 35, timestamp: 1.1)
        XCTAssertFalse(boundary.isPeeking, "Touching the real band after holding in the jitter range must start a fresh dwell, not peek instantly")
        XCTAssertEqual(boundary.pendingDwellDeadline ?? -1, 1.8, accuracy: 0.000_001)
    }

    func testHingePeekSlowCloseThroughBandNeverPeeks() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        for (timestamp, angle) in [(0.0, 35.0), (0.35, 31.5), (0.7, 28.0), (1.05, 24.5), (1.4, 21.0), (1.75, 19.0)] {
            XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: angle, timestamp: timestamp).isPeeking, "Continuous motion through the band must restart dwell instead of peeking at \(angle)°")
        }
    }

    func testHingePeekFastUnfoldThroughBandNeverPeeks() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .closed, angleDegrees: 0, timestamp: 0).isPeeking)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 22, timestamp: 0.1).isPeeking)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 30, timestamp: 0.25).isPeeking)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 34, timestamp: 0.35).isPeeking)
        XCTAssertFalse(machine.update(status: .unfolded, angleDegrees: 180, timestamp: 0.45).isPeeking)
    }

    func testHingePeekToleratesSmallJitterOnlyAfterPeekStarts() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 19.2, timestamp: 0).isPeeking, "Pre-peek edge jitter must not start dwell")
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 20, timestamp: 0.1).isPeeking)
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 20.5, timestamp: 0.82).isPeeking)
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 36.5, timestamp: 0.9).isPeeking, "A visible peek may continue through tolerated edge jitter")
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 38.1, timestamp: 1.0).isPeeking, "Jitter outside the tolerance ends the peek")
    }

    func testHingePeekEndsWhenPhoneFullyOpensOrCloses() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0).isPeeking)
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.8).isPeeking)
        let unfolded = machine.update(status: .unfolded, angleDegrees: 180, timestamp: 0.9)
        XCTAssertFalse(unfolded.isPeeking)
        XCTAssertTrue(unfolded.endedByPostureReset)
        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 1.0).isPeeking, "After fully opening, a new dwell must start")
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 1.8).isPeeking)
        let closed = machine.update(status: .closed, angleDegrees: 0, timestamp: 1.9)
        XCTAssertFalse(closed.isPeeking)
        XCTAssertTrue(closed.endedByPostureReset)
    }

    func testHingePeekLeavingToleranceDoesNotResetDismissalSuppression() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0).isPeeking)
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.8).isPeeking)
        let outsideTolerance = machine.update(status: .partiallyOpen, angleDegrees: 38.1, timestamp: 0.9)
        XCTAssertFalse(outsideTolerance.isPeeking)
        XCTAssertFalse(outsideTolerance.endedByPostureReset, "Moving outside the peek range should end dwell without allowing a dismissed panel to reopen before closed/fully-open reset")
    }

    func testHingePeekUnavailableSampleDoesNotResetDismissalSuppression() {
        var machine = HingePeekStateMachine(configuration: HingePeekConfiguration(peekAngleRange: 20...35, dwellTime: 0.7, edgeJitterTolerance: 2, stableAngleTolerance: 3))

        XCTAssertFalse(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0).isPeeking)
        XCTAssertTrue(machine.update(status: .partiallyOpen, angleDegrees: 25, timestamp: 0.8).isPeeking)
        let unavailable = machine.update(status: .unavailable, angleDegrees: nil, timestamp: 0.9)
        XCTAssertFalse(unavailable.isPeeking)
        XCTAssertFalse(unavailable.endedByPostureReset, "Transient nil-hinge or unavailable samples must not clear dismissal suppression; only closed or fully-open resets do that")
    }

    func testHingePeekEligibilityAllowsPracticeReviewLaterButNeverMockExamOrScoredImmediateAnswer() {
        XCTAssertTrue(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: true, alreadySelected: true, reviewSubmitted: false))
        XCTAssertTrue(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.immediate), hasHint: true, alreadySelected: false, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.immediate), hasHint: true, alreadySelected: true, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: true, alreadySelected: true, reviewSubmitted: true))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .practice(.reviewLater), hasHint: false, alreadySelected: false, reviewSubmitted: false))
        XCTAssertFalse(HingeHintPeekRules.canPeekHint(sessionKind: .mockExam, hasHint: true, alreadySelected: false, reviewSubmitted: false))
    }

    func testHingePeekPresentationStartsOnlyOnceUntilPostureReset() {
        var state = HingeHintPeekPresentationState()
        let eligible = HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)

        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible), [.presentHint(questionID: "B-001-002-002")])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: .hint)), [])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureEnded, context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: .hint)), [.closeHint])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible), [.presentHint(questionID: "B-001-002-002")])
    }

    func testHingePeekPresentationDismissalSuppressesReopenUntilReset() {
        var state = HingeHintPeekPresentationState()
        let eligible = HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)

        _ = HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible)
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .selectedToolChanged(nil), context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)), [])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)), [])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureEnded, context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)), [])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible), [.presentHint(questionID: "B-001-002-002")])
    }

    func testHingePeekPresentationKeepsButtonOpenedHintOpenOnReset() {
        var state = HingeHintPeekPresentationState()
        let buttonOpened = HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: .hint)

        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: buttonOpened), [.presentHint(questionID: "B-001-002-002")])
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureEnded, context: buttonOpened), [], "A Hint panel opened by the button must stay open when the peek posture ends")
    }

    func testHingePeekPresentationClosesPeekOpenedHintOnQuestionChangeAndRequiresFreshDwell() {
        var state = HingeHintPeekPresentationState()
        let eligible = HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)

        _ = HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible)
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .questionChanged, context: HingeHintPeekPresentationContext(questionID: "B-001-002-003", canPeek: true, selectedTool: .hint)), [.closeHint])
        XCTAssertFalse(state.posturePeekActive)
    }

    func testHingePeekPresentationImmediateAnswerEndsEligibility() {
        var state = HingeHintPeekPresentationState()
        let eligible = HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: true, selectedTool: nil)

        _ = HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible)
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .eligibilityChanged, context: HingeHintPeekPresentationContext(questionID: "B-001-002-002", canPeek: false, selectedTool: .hint)), [.closeHint])
        XCTAssertTrue(state.suppressedUntilPostureReset)
        XCTAssertEqual(HingeHintPeekPresentationReducer.reduce(state: &state, action: .postureStarted, context: eligible), [])
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

    func testHintVisibilityTimerDoesNotQualifyShortPeekRoute() async throws {
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

    func testHintVisibilityTimerCancelsShortPeekBeforeRecordingHelp() async throws {
        let timer = HintVisibilityQualificationTimer()
        var qualifiedQuestionIds: Set<String> = []

        timer.begin(questionID: "B-001-002-002", canRecordHelp: true, alreadyQualified: false, delayNanoseconds: 300_000_000) {
            qualifiedQuestionIds.insert("B-001-002-002")
        }
        try await Task.sleep(nanoseconds: 120_000_000)
        timer.cancel()
        try await Task.sleep(nanoseconds: 260_000_000)

        XCTAssertEqual(qualifiedQuestionIds, [], "A peek that closes before the 0.5 s visibility rule must not record help")
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
