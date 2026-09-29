import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    private let auditIterationID = CanadianHamPracticeUITests.makeAuditIterationID()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])

        assertSingleLanguagePicker(in: app, context: "practice")
        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        let frenchSegment = languagePicker.buttons["Français"].firstMatch
        XCTAssertTrue(frenchSegment.waitForExistence(timeout: 2), "French segment should be available")
        frenchSegment.tap()
        let selectedPredicate = NSPredicate(format: "selected == true")
        let selectedExpectation = XCTNSPredicateExpectation(predicate: selectedPredicate, object: frenchSegment)
        XCTAssertEqual(XCTWaiter.wait(for: [selectedExpectation], timeout: 5), .completed, "Français segment should become selected")

        let frenchQuestionTexts = try bundledFrenchQuestionTexts(forCategoryID: "B-001")
        let frenchQuestionPredicate = NSPredicate(format: "label IN %@", Array(frenchQuestionTexts))
        let visibleFrenchQuestion = app.staticTexts.matching(frenchQuestionPredicate).firstMatch
        XCTAssertTrue(
            visibleFrenchQuestion.waitForExistence(timeout: 5),
            "Expected one of the bundled French B-001 question stems after switching language"
        )

        answerFirstVisibleAnswer(in: app)
        let feedback = waitForAnswerFeedback(in: app)
        XCTAssertTrue(
            feedback.label.hasPrefix("Correct") || feedback.label.hasPrefix("Incorrect"),
            "Feedback label should start with Correct or Incorrect, got: \(feedback.label)"
        )
    }

    func testLanguagePickerExistsOnCategoryListAndPractice() throws {
        XCUIDevice.shared.appearance = .light
        var app = launchApp(arguments: ["-CanadianHamInitialScreen", "practice"])
        assertSingleLanguagePicker(in: app, context: "practice hub")
        XCTAssertTrue(app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 10))
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        assertSingleLanguagePicker(in: app, context: "practice")
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
    }

    func testLearnOpensLessonAndShowsFirstHeading() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialLessonID", "L-006-03"])

        XCTAssertTrue(app.staticTexts["Polarization, dipoles, and wavelength"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["lesson-reader-title"].firstMatch.exists)
    }

    func testLessonQuizResultPersistsAfterRelaunch() throws {
        XCUIDevice.shared.appearance = .light
        var app = launchApp(arguments: [
            "-CanadianHamInitialLessonQuizID", "QZ-L-006-03-A",
            "-CanadianHamLessonQuizLimit", "1",
            "-CanadianHamLessonQuizSeed", "ui-lesson-quiz-persist"
        ])
        waitForLessonQuizScreen(in: app)
        completeVisibleLessonQuiz(in: app, expectedCount: 1)
        XCTAssertTrue(app.descendants(matching: .any)["lesson-quiz-latest-score"].firstMatch.waitForExistence(timeout: 10))
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialLessonQuizID", "QZ-L-006-03-A"], resetData: false)
        waitForLessonQuizScreen(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["lesson-quiz-latest-score"].firstMatch.waitForExistence(timeout: 10), "Saved lesson quiz score should persist after relaunch")
    }

    func testLearnUserNavigationOpensLessonQuiz() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "learn"])
        XCTAssertTrue(app.staticTexts["Learn"].firstMatch.waitForExistence(timeout: 10))

        tap("Open module", in: app)
        XCTAssertTrue(app.staticTexts["Basic Electronics and Theory"].firstMatch.waitForExistence(timeout: 10))

        let firstLesson = app.staticTexts["Units, conductors, and current"].firstMatch
        XCTAssertTrue(firstLesson.waitForExistence(timeout: 10), "First module should expose its first lesson")
        firstLesson.tap()
        XCTAssertTrue(app.descendants(matching: .any)["lesson-reader-title"].firstMatch.waitForExistence(timeout: 10))

        goToLessonQuiz(in: app)
    }

    func testExplanationAppearsAfterAnsweringInPractice() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["explanation-panel"].firstMatch.waitForExistence(timeout: 5), "Immediate feedback should include the authored explanation")
    }

    func testReferenceViewerOpensAndClosesFromMockExam() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock"])
        XCTAssertTrue(app.staticTexts["Mock exam"].waitForExistence(timeout: 10))
        scrollAndTap("Exam reference sheet", in: app)
        XCTAssertTrue(app.navigationBars["Exam reference sheet"].waitForExistence(timeout: 10))
        app.buttons["reference-viewer-done-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Mock exam"].waitForExistence(timeout: 5))
    }

    func testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10))
        assertQuestion(app, showsQuestionID: "B-001-002-002")

        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        waitBriefly(1.0)

        assertQuestion(app, showsQuestionID: "B-001-002-002", message: "Saving progress must not reload the practice session")
        XCTAssertTrue(app.buttons["Next question"].firstMatch.exists, "Immediate feedback controls should remain after saving progress")
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback"].firstMatch.exists, "Feedback should remain after saving progress")
    }

    func testMockExamDoesNotShowCorrectnessBeforeSubmit() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock", "-CanadianHamMockExamSeed", "ui-mock-no-correctness"])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))

        answerFirstVisibleAnswer(in: app)
        waitBriefly()

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.exists)
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Correct answer"), "Mock exams must not reveal the correct answer before submit")
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Your answer, incorrect"), "Mock exams must not reveal incorrectness before submit")
    }

    func testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002",
            "-CanadianHamPracticeMode", "review-later",
            "-CanadianHamPracticeLimit", "1"
        ])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))

        answerFirstVisibleAnswer(in: app)
        waitBriefly()
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Correct answer"), "Review-later practice must not reveal correctness before submit")
        scrollAndTap("Submit for review", in: app)

        XCTAssertTrue(app.staticTexts["Practice review"].waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Correct answer:"), "Review-later results should reveal correctness after submit")
        waitBriefly(1.0)
        XCTAssertTrue(app.staticTexts["Practice review"].exists, "Saving review-later progress must not reset the review screen")
    }

    func testRegularWidthMockExamResultPersistsAfterSubmit() throws {
        XCUIDevice.shared.appearance = .light
#if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
#endif
        let app = launchApp(arguments: [
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-regular-result"
        ])
        XCTAssertTrue(app.descendants(matching: .any)["root-sidebar"].firstMatch.waitForExistence(timeout: 10), "Regular-width launch argument should force the split-view sidebar on iPhone simulators")
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Question 1 of 100"), "Default mock exam should expose the full 100-question count")
        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        assertMockExamResultDetailsVisible(in: app)
        waitBriefly(1.0)
        assertMockExamResultVisible(in: app)
    }

    func testSettingsResetClearsSavedMockExamProgress() throws {
        XCUIDevice.shared.appearance = .light
        var app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-reset-progress",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "settings"], resetData: false)
        XCTAssertTrue(app.staticTexts["Settings"].firstMatch.waitForExistence(timeout: 10))
        scrollAndTap("Reset all data", in: app)
        confirmResetAlert(in: app)
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "All local progress was reset."), "Reset should show a success status")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "home"], resetData: false)
        XCTAssertTrue(app.staticTexts["Ready for Basic with Honours?"].waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Completed mock exams: 0"), "Reset should clear previously saved mock exam attempts")
    }

    func testSubsectionPracticeOpensFromHubAndShowsReviewScreen() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "practice",
            "-CanadianHamPracticeMode", "review-later",
            "-CanadianHamPracticeLimit", "1"
        ])
        XCTAssertTrue(app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 10))
        let disclosure = app.buttons["Subsections"].firstMatch
        XCTAssertTrue(disclosure.waitForExistence(timeout: 10), "Practice hub should expose subsection disclosure controls")
        disclosure.tap()
        let subsection = app.buttons["Practice subsection B-001-001, 4 questions"].firstMatch
        XCTAssertTrue(subsection.waitForExistence(timeout: 5), "Opening a category disclosure should reveal subsection practice buttons")
        subsection.tap()

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "B-001-001"), "Subsection practice should open a subsection-scoped session")
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("Submit for review", in: app)
        XCTAssertTrue(app.staticTexts["Practice review"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5), "Practice review should show answer feedback after a review-later subsection session is submitted")
    }

    func testPracticeFlowSupportsLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        answerFirstVisibleAnswer(in: app)
        let feedback = waitForAnswerFeedback(in: app)
        XCTAssertTrue(feedback.exists, "Answer feedback should exist after answering at the largest accessibility text size")

        let nextQuestionButton = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist at the largest accessibility text size")
        scrollUntilHittable(nextQuestionButton, in: app, maxSwipes: 14)
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be reachable by scrolling at the largest accessibility text size")
        nextQuestionButton.tap()

        waitForElementToDisappear(feedback, timeout: 5, message: "Answer feedback should disappear after advancing at the largest accessibility text size")
    }

    func testLongestAnswerWrapsAtLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let longestAnswer = try longestEnglishAnswerInBank()
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", longestAnswer.categoryId,
            "-CanadianHamPracticeQuestionID", longestAnswer.questionId,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        let answerText = app.staticTexts.matching(NSPredicate(format: "label == %@", longestAnswer.answerText)).firstMatch
        XCTAssertTrue(
            answerText.waitForExistence(timeout: 10),
            "Expected longest bundled answer to render for \(longestAnswer.questionId)"
        )
        scrollUntilPartiallyVisible(answerText, in: app, maxSwipes: 20)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(answerText, in: app),
            "Longest answer should have a visible, scrollable text frame below the navigation bar. Frame: \(frameDescription(answerText.frame))"
        )
        XCTAssertGreaterThan(
            answerText.frame.height,
            200,
            "Longest answer should expose its full multi-line text height rather than clipping to one line"
        )
    }

    func testAccessibilityAuditCoreScreensLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditCoreScreens(appearance: .light)
    }

    func testAccessibilityAuditCoreScreensDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditCoreScreens(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testAccessibilityAuditPracticeSessionLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditPracticeSession(appearance: .light)
    }

    func testAccessibilityAuditPracticeSessionDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditPracticeSession(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testAccessibilityAuditLearnFlowLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditLearnFlow(appearance: .light)
    }

    func testAccessibilityAuditLearnFlowDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditLearnFlow(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testAccessibilityAuditMockExamFlowLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditMockExamFlow(appearance: .light)
    }

    func testAccessibilityAuditMockExamFlowDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditMockExamFlow(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testA11yDiagnosticsEvidenceHarness() throws {
        guard ProcessInfo.processInfo.environment["CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS"] == "1" else {
            throw XCTSkip("Set CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS=1 to run the opt-in accessibility evidence diagnostic harness.")
        }

        XCUIDevice.shared.appearance = .light
        try runDiagnosticsHarness(appearance: .light)
        XCUIDevice.shared.appearance = .dark
        try runDiagnosticsHarness(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    private func auditCoreScreens(appearance: AuditAppearance) throws {
        var app = launchApp(arguments: ["-CanadianHamInitialScreen", "home"])
        XCTAssertTrue(app.staticTexts["Ready for Basic with Honours?"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) home")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "practice"])
        XCTAssertTrue(app.staticTexts["Practice"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) practice hub")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock"])
        XCTAssertTrue(app.staticTexts["Mock exam"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam start")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "learn"])
        XCTAssertTrue(app.staticTexts["Learn"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) learn module list")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "settings"])
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) settings")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "about"])
        XCTAssertTrue(app.staticTexts["About Canadian Ham"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) about")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamForceStoreOpenError"], resetData: false)
        XCTAssertTrue(app.staticTexts["Local progress store unavailable"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) store recovery")
        app.terminate()
    }

    private func auditPracticeSession(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) unanswered practice")

        answerKnownIncorrectLifeAnswerIfPresent(in: app)
        _ = waitForAnswerFeedback(in: app)
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Incorrect"), "Audit fixture should expose the incorrect-answer state")
        try performAudit(on: app, context: "\(appearance.rawValue) incorrect answered practice")
        app.terminate()

        let correctApp = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(correctApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        answerKnownCorrectLifeAnswerIfPresent(in: correctApp)
        _ = waitForAnswerFeedback(in: correctApp)
        XCTAssertTrue(anyVisibleLabel(in: correctApp, contains: "Correct"), "Audit fixture should expose the correct-answer state")
        try performAudit(on: correctApp, context: "\(appearance.rawValue) correct answered practice")
        correctApp.terminate()

        let reviewApp = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002",
            "-CanadianHamPracticeMode", "review-later",
            "-CanadianHamPracticeLimit", "1"
        ])
        XCTAssertTrue(reviewApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: reviewApp)
        scrollAndTap("Submit for review", in: reviewApp)
        XCTAssertTrue(reviewApp.staticTexts["Practice review"].waitForExistence(timeout: 10))
        try performAudit(on: reviewApp, context: "\(appearance.rawValue) practice review")
        reviewApp.terminate()
    }

    private func auditLearnFlow(appearance: AuditAppearance) throws {
        var app = launchApp(arguments: ["-CanadianHamInitialScreen", "learn"])
        XCTAssertTrue(app.staticTexts["Learn"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) learn module list")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialLessonID", "L-006-03"])
        XCTAssertTrue(app.descendants(matching: .any)["lesson-reader-title"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) lesson reader top")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialLessonQuizID", "QZ-L-006-03-A", "-CanadianHamLessonQuizLimit", "1", "-CanadianHamLessonQuizSeed", "ui-a11y-lesson-quiz"])
        waitForLessonQuizScreen(in: app)
        answerFirstVisibleQuizAnswer(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["lesson-quiz-feedback"].firstMatch.waitForExistence(timeout: 5) || app.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 1))
        app.scrollViews.firstMatch.swipeUp()
        waitBriefly(0.1)
        app.scrollViews.firstMatch.swipeUp()
        waitBriefly(0.1)
        try performAudit(on: app, context: "\(appearance.rawValue) lesson quiz answered")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock"])
        XCTAssertTrue(app.staticTexts["Mock exam"].waitForExistence(timeout: 10))
        scrollAndTap("Exam reference sheet", in: app)
        XCTAssertTrue(app.navigationBars["Exam reference sheet"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["reference-pdf-view"].firstMatch.waitForExistence(timeout: 10))
        try performReferenceViewerAudit(on: app, context: "\(appearance.rawValue) reference viewer")
        app.terminate()
    }

    private func auditMockExamFlow(appearance: AuditAppearance) throws {
        let timerApp = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-a11y-mock-exam-timer",
            "-CanadianHamExamTimerEnabled", "true",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: timerApp)
        XCTAssertTrue(timerApp.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        XCTAssertTrue(timerApp.staticTexts["Question navigator"].waitForExistence(timeout: 5))
        XCTAssertFalse(timerApp.buttons["mock-previous-button"].firstMatch.isEnabled, "Previous should be disabled on the first question")
        XCTAssertFalse(timerApp.buttons["mock-next-button"].firstMatch.isEnabled, "Next should be disabled on the last question when the fixture has one item")
        try performAudit(on: timerApp, context: "\(appearance.rawValue) mock exam question navigator timer")
        timerApp.terminate()

        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-a11y-mock-exam-answered-flagged",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        answerKnownCorrectLifeAnswerIfPresent(in: app)
        scrollAndTap("Flag for review", in: app)
        waitBriefly()
        XCTAssertTrue(app.buttons["Flagged for review"].firstMatch.waitForExistence(timeout: 5), "Mock exam should expose the flagged state before auditing")
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam question navigator answered flagged")

        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        app.scrollViews.firstMatch.swipeUp()
        waitBriefly()
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam results")
        app.terminate()
    }

    private func runDiagnosticsHarness(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        captureScreenEvidence(named: "practice-\(appearance.rawValue)-unanswered-iteration-\(auditIterationID)")
        try captureAccessibilityAudit(on: app, context: "practice \(appearance.rawValue) unanswered")
        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        captureScreenEvidence(named: "practice-\(appearance.rawValue)-answered-iteration-\(auditIterationID)")
        try captureAccessibilityAudit(on: app, context: "practice \(appearance.rawValue) answered")
        app.terminate()
    }

    private func launchApp(arguments: [String] = [], resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (resetData ? ["-CanadianHamResetDataOnLaunch"] : []) + arguments
        app.launch()
        return app
    }

    private func performAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit()
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable before iOS 17 for \(context).")
        }
    }

    private func performReferenceViewerAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            var ignoredFindings: [String] = []
            do {
                try app.performAccessibilityAudit { issue in
                    let description = self.describe(issue)
                    findings.append(description)
                    if self.isAllowedReferencePDFIssue(issue, in: app) {
                        ignoredFindings.append(description)
                        return true
                    }
                    return false
                }
            } catch {
                attachRawAuditFindings(findings, context: context, error: error)
                throw error
            }
            attachRawAuditFindings(
                findings.isEmpty ? ["No accessibility audit issues reported."] : findings,
                context: context,
                error: nil
            )
            XCTAssertEqual(findings.count, ignoredFindings.count, "Reference viewer audit should ignore only fixed-layout PDF page Dynamic Type or contrast issues. Findings: \(findings.joined(separator: " | "))")
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable before iOS 17 for \(context).")
        }
    }

    @available(iOS 17.0, *)
    private func isAllowedReferencePDFIssue(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> Bool {
        let dynamicType = XCUIAccessibilityAuditType(rawValue: 1 << 16)
        guard issue.auditType == dynamicType || issue.auditType == .contrast else { return false }
        if issue.element?.identifier == "reference-pdf-view" { return true }
        guard let issueFrame = issue.element?.frame, app.descendants(matching: .any)["reference-pdf-view"].firstMatch.exists else { return false }
        let pdfFrame = app.descendants(matching: .any)["reference-pdf-view"].firstMatch.frame
        return pdfFrame.contains(CGPoint(x: issueFrame.midX, y: issueFrame.midY))
    }

    private func captureAccessibilityAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            do {
                try app.performAccessibilityAudit { issue in
                    findings.append(self.describe(issue))
                    return true
                }
            } catch {
                attachRawAuditFindings(findings, context: context, error: error)
                throw error
            }
            attachRawAuditFindings(findings, context: context, error: nil)
            XCTAssertTrue(findings.isEmpty, "Accessibility audit reported issues for \(context): \(findings.joined(separator: " | "))")
        } else {
            attachRawAuditFindings(["performAccessibilityAudit is unavailable before iOS 17."], context: context, error: nil)
        }
    }

    @available(iOS 17.0, *)
    private func describe(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element = issue.element
        return """
        auditType: \(issue.auditType)
        element.identifier: \(element?.identifier ?? "")
        element.label: \(element?.label ?? "")
        element.frame: \(element.map { frameDescription($0.frame) } ?? "nil")
        compactDescription: \(issue.compactDescription)
        """
    }

    private func attachRawAuditFindings(_ findings: [String], context: String, error: Error?) {
        var lines = ["Context: \(context)", "Iteration: \(auditIterationID)"]
        if let error { lines.append("Audit error: \(error)") }
        lines.append(findings.isEmpty ? "No accessibility audit issues reported." : findings.joined(separator: "\n\n"))
        let text = lines.joined(separator: "\n\n")
        let attachment = XCTAttachment(string: text)
        attachment.name = "\(sanitizedEvidenceName(context))-raw-accessibility-audit-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(Data(text.utf8), filename: "\(sanitizedEvidenceName(context))-raw-accessibility-audit-findings.txt")
    }

    @discardableResult
    private func captureScreenEvidence(named name: String) -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = sanitizedEvidenceName(name)
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(screenshot.pngRepresentation, filename: "\(sanitizedEvidenceName(name)).png")
        return screenshot
    }

    private func exportEvidence(_ data: Data, filename: String, file: StaticString = #filePath, line: UInt = #line) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("CanadianHamA11yEvidence", isDirectory: true)
            .appendingPathComponent(auditIterationID, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(sanitizedEvidenceName(filename)), options: .atomic)
        } catch {
            XCTFail("Failed to export accessibility evidence \(filename): \(error)", file: file, line: line)
        }
    }

    private func sanitizedEvidenceName(_ name: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(name.unicodeScalars.map { allowedCharacters.contains($0) ? Character($0) : "-" })
    }

    private func openMockExamStart(in app: XCUIApplication) {
        let start = app.buttons["Start mock exam"].firstMatch
        if !start.waitForExistence(timeout: 3) {
            let sidebarMock = app.buttons["Mock exam"].firstMatch
            if sidebarMock.waitForExistence(timeout: 3) {
                sidebarMock.tap()
            }
        }
        tap("Start mock exam", in: app)
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        button.tap()
    }

    private func scrollAndTap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        for _ in 0..<14 where !button.isHittable {
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
        XCTAssertTrue(button.isHittable, "Expected button \(label) to be hittable")
        button.tap()
    }

    private func submitMockExamAlert(in app: XCUIApplication) {
        let alert = app.alerts["Submit mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Submit"].tap()
    }

    private func confirmResetAlert(in app: XCUIApplication) {
        let alert = app.alerts["Reset all local data?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Reset"].tap()
    }

    private func assertMockExamResultVisible(in app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["Needs review"].waitForExistence(timeout: 10)
            || app.staticTexts["Pass"].waitForExistence(timeout: 1)
            || app.staticTexts["Basic with Honours"].waitForExistence(timeout: 1),
            "Expected mock exam results to remain visible"
        )
    }

    private func assertMockExamResultDetailsVisible(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Category breakdown"].waitForExistence(timeout: 5), "Mock exam results should include category breakdown")
        XCTAssertTrue(app.staticTexts["Wrong-answer review"].firstMatch.exists, "Mock exam results should include wrong-answer review")
    }

    private func answerKnownCorrectLifeAnswerIfPresent(in app: XCUIApplication) {
        let correctAnswer = app.staticTexts["life"].firstMatch
        if correctAnswer.waitForExistence(timeout: 2) {
            correctAnswer.tap()
        } else {
            answerFirstVisibleAnswer(in: app)
        }
    }

    private func answerKnownIncorrectLifeAnswerIfPresent(in app: XCUIApplication) {
        let identifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        if app.staticTexts["life"].firstMatch.waitForExistence(timeout: 2) {
            for id in identifiers {
                let button = app.descendants(matching: .any)[id].firstMatch
                if button.exists && button.isHittable && !button.label.localizedCaseInsensitiveContains("life") {
                    button.tap()
                    return
                }
            }
        }
        answerFirstVisibleAnswer(in: app)
    }

    private func completeVisibleLessonQuiz(in app: XCUIApplication, expectedCount: Int) {
        for index in 1...expectedCount {
            answerFirstVisibleQuizAnswer(in: app)
            if index < expectedCount {
                scrollAndTap("Next", in: app)
            }
        }
        scrollAndTap("Submit lesson quiz", in: app)
    }

    private func answerFirstVisibleQuizAnswer(in app: XCUIApplication) {
        let identifiers = ["answer-A-button", "lesson-quiz-choice-A-button", "answer-B-button", "lesson-quiz-choice-B-button", "answer-C-button", "lesson-quiz-choice-C-button", "answer-D-button", "lesson-quiz-choice-D-button"]
        for _ in 0..<12 {
            for id in identifiers {
                let button = app.descendants(matching: .any)[id].firstMatch
                if button.exists && button.isEnabled && button.isHittable {
                    button.tap()
                    return
                }
            }
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
        XCTFail("No lesson quiz answer button was available after tapping Go to quiz")
    }

    private func answerFirstVisibleAnswer(in app: XCUIApplication) {
        let identifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        XCTAssertTrue(app.descendants(matching: .any)[identifiers[0]].firstMatch.waitForExistence(timeout: 10))
        for _ in 0..<10 {
            for id in identifiers {
                let button = app.descendants(matching: .any)[id].firstMatch
                if button.exists && button.isHittable {
                    button.tap()
                    return
                }
            }
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
        XCTFail("No answer button became hittable")
    }

    private func waitForAnswerFeedback(in app: XCUIApplication) -> XCUIElement {
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Answer feedback should appear after selecting an answer")
        return feedback
    }

    private func assertSingleLanguagePicker(in app: XCUIApplication, context: String) {
        let languagePickers = app.segmentedControls.matching(identifier: "question-language-picker")
        XCTAssertTrue(languagePickers.firstMatch.waitForExistence(timeout: 10), "Question language picker should exist on \(context)")
        XCTAssertEqual(languagePickers.count, 1, "Exactly one question language picker should be visible on \(context)")
    }

    private func anyVisibleLabel(in app: XCUIApplication, contains needle: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", needle)
        return app.staticTexts.matching(predicate).firstMatch.exists
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
    }

    private func scrollUntilPartiallyVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 1) else { return }
        for _ in 0..<maxSwipes where !isPartiallyVisibleBelowNavigationBar(element, in: app) {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            if element.frame.maxY <= visibleFrame.minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func isPartiallyVisibleBelowNavigationBar(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return element.frame.intersects(visibleFrameExcludingNavigationBar(in: app))
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(navBar.exists ? navBar.frame.maxY : windowFrame.minY, statusBar.exists ? statusBar.frame.maxY : windowFrame.minY)
        return CGRect(x: windowFrame.minX + 16, y: protectedMaxY + 1, width: max(0, windowFrame.width - 32), height: max(0, windowFrame.maxY - protectedMaxY - 17))
    }

    private func scrollToTop(in app: XCUIApplication) {
        let target = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
        for _ in 0..<6 {
            target.swipeDown()
            waitBriefly()
        }
    }

    private func goToLessonQuiz(in app: XCUIApplication) {
        let button = app.buttons["Go to quiz"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Lesson reader should expose a Go to quiz button")
        scrollUntilHittable(button, in: app, maxSwipes: 6)
        XCTAssertTrue(button.isHittable, "Go to quiz button should be hittable")
        button.tap()
        waitForLessonQuizScreen(in: app)
    }

    private func waitForLessonQuizScreen(in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["lesson-quiz-card"].firstMatch.waitForExistence(timeout: 10), "Expected the real lesson quiz screen")
    }

    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval, message: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func assertQuestion(_ app: XCUIApplication, showsQuestionID questionID: String, message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let identifier = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertEqual(identifier.label, questionID, message ?? "Practice should show the forced question ID", file: file, line: line)

        do {
            let expectedText = try bundledEnglishQuestionText(forQuestionID: questionID)
            let stem = app.descendants(matching: .any)["question-stem"].firstMatch
            XCTAssertTrue(stem.waitForExistence(timeout: 5), "Question stem should be visible for \(questionID)", file: file, line: line)
            XCTAssertEqual(stem.label, expectedText, message ?? "Practice should show the forced question stem", file: file, line: line)
        } catch {
            XCTFail("Failed to load bundled expected question text for \(questionID): \(error)", file: file, line: line)
        }
    }

    private func bundledFrenchQuestionTexts(forCategoryID categoryID: String) throws -> Set<String> {
        let questions = try bundledQuestions()
        return Set(questions.compactMap { question in
            guard question.categoryId == categoryID else { return nil }
            return question.text.fr
        })
    }

    private func bundledEnglishQuestionText(forQuestionID questionID: String) throws -> String {
        let question = try XCTUnwrap(
            try bundledQuestions().first { $0.id == questionID },
            "UI test bundle should include \(questionID)"
        )
        return try XCTUnwrap(question.text.en, "\(questionID) should include English text")
    }

    private func longestEnglishAnswerInBank() throws -> UITestLongestAnswer {
        let questions = try bundledQuestions()
        let answers = questions.flatMap { question in
            question.answers.compactMap { answer -> UITestLongestAnswer? in
                guard let text = answer.text.en, !text.isEmpty else { return nil }
                return UITestLongestAnswer(questionId: question.id, categoryId: question.categoryId, answerText: text)
            }
        }
        return try XCTUnwrap(answers.max { $0.answerText.count < $1.answerText.count })
    }

    private func bundledQuestions() throws -> [UITestQuestion] {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "questions", withExtension: "json"),
            "UI test bundle should include generated question-bank questions.json"
        )
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([UITestQuestion].self, from: data)
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private static func makeAuditIterationID() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "-")
            + "-\(UUID().uuidString.prefix(8))"
    }
}

private enum AuditAppearance: String {
    case light
    case dark
}

private struct UITestQuestion: Decodable {
    let id: String
    let categoryId: String
    let text: UITestLocalizedText
    let answers: [UITestAnswer]
}

private struct UITestAnswer: Decodable {
    let text: UITestLocalizedText
}

private struct UITestLocalizedText: Decodable {
    let en: String?
    let fr: String?
}

private struct UITestLongestAnswer {
    let questionId: String
    let categoryId: String
    let answerText: String
}
