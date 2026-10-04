import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    private let auditIterationID = CanadianHamPracticeUITests.makeAuditIterationID()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFrenchSystemLanguageNavigatesMainScreensAndAuditsHomeAndPractice() throws {
        XCUIDevice.shared.appearance = .light
        let frenchLocaleArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_CA"]

        var app = launchApp(arguments: frenchLocaleArguments + ["-CanadianHamInitialScreen", "home"])
        XCTAssertTrue(app.staticTexts["Prêt pour la compétence de base avec distinction?"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Effectuez au moins deux examens simulés"), "Expected a localized French readiness body message on Home")
        try performAudit(on: app, context: "French home")
        app.terminate()

        for (screen, expectedText) in [
            ("learn", "Apprendre"),
            ("practice", "S’exercer"),
            ("mock", "Examen simulé"),
            ("settings", "Réglages"),
            ("about", "À propos de Canadian Ham")
        ] {
            app = launchApp(arguments: frenchLocaleArguments + ["-CanadianHamInitialScreen", screen])
            XCTAssertTrue(app.staticTexts[expectedText].firstMatch.waitForExistence(timeout: 10), "Expected localized \(screen) screen")
            if screen == "settings" {
                XCTAssertTrue(anyVisibleLabel(in: app, contains: "La progression est enregistrée sur cet appareil"), "Expected localized Settings body copy")
            }
            if screen == "about" {
                XCTAssertTrue(app.staticTexts["Banque"].firstMatch.waitForExistence(timeout: 5), "Expected localized French About section title")
            }
            if screen == "mock" {
                tap("Commencer l’examen simulé", in: app)
                XCTAssertTrue(app.staticTexts["Question 1 sur 100"].firstMatch.waitForExistence(timeout: 10), "Expected localized interpolated mock-exam progress")
            }
            app.terminate()
        }

        app = launchApp(arguments: frenchLocaleArguments + ["-CanadianHamInitialLessonID", "L-006-03"])
        XCTAssertTrue(app.buttons["Marquer la leçon comme lue"].firstMatch.waitForExistence(timeout: 10), "Expected localized Mark lesson read button")
        app.terminate()

        app = launchApp(arguments: frenchLocaleArguments + ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "French practice question")
    }

    func testMorseSectionIsTopLevelAndShowsSettings() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "morse"])
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts["Morse"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Preview"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Learn (course)"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Copy practice"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Exam"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Quick listen"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morse settings"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hidden until playback finishes."].firstMatch.waitForExistence(timeout: 5))
    }

    func testMorseCopyPracticeAndExamFlow() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "morse",
            "-CanadianHamMorseCopyPlaybackSeconds", "0.1",
            "-CanadianHamMorseExamPlaybackSeconds", "0.1",
            "-CanadianHamMorseExamReviewSeconds", "1"
        ])
        defer { app.terminate() }

        XCTAssertTrue(app.buttons["morse-copy-start-button"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["morse-copy-start-button"].firstMatch.tap()
        let copyEditor = app.textViews["morse-copy-text-editor"].firstMatch
        XCTAssertTrue(copyEditor.waitForExistence(timeout: 5))
        copyEditor.tap()
        copyEditor.typeText("THE NET OPENS AT NOON. QSX")
        XCTAssertTrue(app.staticTexts["Playback finished. Check your copy when ready."].firstMatch.waitForExistence(timeout: 5))
        app.buttons["morse-copy-check-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Character diff"].firstMatch.waitForExistence(timeout: 5))

        let examStart = app.buttons["morse-exam-start-button"].firstMatch
        XCTAssertTrue(examStart.waitForExistence(timeout: 5))
        scrollUntilHittable(examStart, in: app, maxSwipes: 8)
        examStart.tap()
        XCTAssertTrue(app.textViews["morse-exam-text-editor"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "FAIL")).firstMatch.waitForExistence(timeout: 10))
    }

    func testMorseCopyStartResetsAfterAudioStartupFailure() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "morse",
            "-CanadianHamMorseFailCopyAudioStartup"
        ])
        defer { app.terminate() }

        let copyStart = app.buttons["morse-copy-start-button"].firstMatch
        XCTAssertTrue(copyStart.waitForExistence(timeout: 10))
        copyStart.tap()

        XCTAssertTrue(app.staticTexts["Morse error"].firstMatch.waitForExistence(timeout: 5))
        let copyCheck = app.buttons["morse-copy-check-button"].firstMatch
        XCTAssertTrue(copyCheck.waitForExistence(timeout: 5))
        XCTAssertFalse(copyCheck.isEnabled, "Failed audio startup should leave Check copy disabled")
        XCTAssertFalse(app.textViews["morse-copy-text-editor"].firstMatch.isEnabled, "Failed audio startup should leave no active passage for editing")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Playback duration")).firstMatch.exists, "Failed audio startup should clear the attempted copy passage")
    }

    func testMorseExamStartResetsAfterAudioStartupFailure() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "morse",
            "-CanadianHamMorseFailExamAudioStartup"
        ])
        defer { app.terminate() }

        let examStart = app.buttons["morse-exam-start-button"].firstMatch
        XCTAssertTrue(examStart.waitForExistence(timeout: 10))
        scrollUntilHittable(examStart, in: app, maxSwipes: 8)
        examStart.tap()

        XCTAssertTrue(app.staticTexts["Morse error"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(examStart.isEnabled, "Failed audio startup should return the exam to idle so Start is enabled")
        XCTAssertFalse(app.textViews["morse-exam-text-editor"].firstMatch.isEnabled, "Failed audio startup should leave no active exam for editing")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Generated exam")).firstMatch.exists, "Failed audio startup should clear the generated exam summary")
    }

    func testMorseStartingQuickListenStopsCopyPlayback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "morse",
            "-CanadianHamMorseCopyPlaybackSeconds", "10"
        ])
        defer { app.terminate() }

        let copyStart = app.buttons["morse-copy-start-button"].firstMatch
        XCTAssertTrue(copyStart.waitForExistence(timeout: 10))
        copyStart.tap()
        let copyCheck = app.buttons["morse-copy-check-button"].firstMatch
        XCTAssertTrue(copyCheck.waitForExistence(timeout: 5))
        XCTAssertFalse(copyCheck.isEnabled, "Copy check should stay disabled while copy practice is playing")

        let quickPlay = app.buttons["morse-quick-play-button"].firstMatch
        XCTAssertTrue(quickPlay.waitForExistence(timeout: 5))
        scrollUntilHittable(quickPlay, in: app, maxSwipes: 8)
        quickPlay.tap()

        let quickStop = app.buttons["morse-quick-stop-button"].firstMatch
        XCTAssertTrue(quickStop.waitForExistence(timeout: 5))
        XCTAssertTrue(quickStop.isEnabled, "Quick listen should be the active Morse playback after it starts")
        XCTAssertTrue(copyCheck.isEnabled, "Starting Quick listen should stop copy-practice playback and re-enable Check copy")
    }

    func testAccessibilityAuditMorseExamGradedDiffLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditMorseExamGradedDiff(appearance: .light)
    }

    func testAccessibilityAuditMorseExamGradedDiffDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditMorseExamGradedDiff(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testCompactTopLevelListPushesMorseThenLearn() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp()
        defer { app.terminate() }

        XCTAssertTrue(app.buttons["Morse"].firstMatch.waitForExistence(timeout: 10), "Compact iPhone navigation should expose Morse in the root list")
        tap("Morse", in: app)
        XCTAssertTrue(app.staticTexts["Quick listen"].firstMatch.waitForExistence(timeout: 10))
        tapCompactBack(in: app)
        tap("Learn", in: app)
        XCTAssertTrue(app.staticTexts["Structured lessons"].firstMatch.waitForExistence(timeout: 10), "Expected a Learn-only element after returning to the compact root list")
    }

    func testCompactRootNavigationPreservesPracticeSessionState() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "home"])
        defer { app.terminate() }

        tap("Start practice", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["practice-session-tally"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback-title"].firstMatch.waitForExistence(timeout: 5))

        tapCompactBack(in: app)
        tapCompactBack(in: app)
        tap("Morse", in: app)
        XCTAssertTrue(app.staticTexts["Quick listen"].firstMatch.waitForExistence(timeout: 10))
        tapCompactBack(in: app)
        tap("Practice", in: app)
        let allQuestions = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Start all questions")).firstMatch
        XCTAssertTrue(allQuestions.waitForExistence(timeout: 5), "Expected the all-questions practice button")
        allQuestions.tap()

        XCTAssertTrue(app.descendants(matching: .any)["practice-session-tally"].firstMatch.waitForExistence(timeout: 10), "Expected the practice session to reopen from the compact root list")
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback-title"].firstMatch.waitForExistence(timeout: 5), "Expected selected-answer feedback to survive compact Back navigation")
    }

    func testCompactRootNavigationPreservesMockExamState() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        defer { app.terminate() }

        tap("Start mock exam", in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 1"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Selected")).firstMatch.waitForExistence(timeout: 5))

        tapCompactBack(in: app)
        tapCompactBack(in: app)
        tap("Morse", in: app)
        XCTAssertTrue(app.staticTexts["Quick listen"].firstMatch.waitForExistence(timeout: 10))
        tapCompactBack(in: app)
        tap("Home", in: app)
        tap("Mock exam", in: app)

        XCTAssertTrue(app.staticTexts["Question 1 of 1"].firstMatch.waitForExistence(timeout: 10), "Expected the mock exam question to reopen from Home after compact Back navigation")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Selected")).firstMatch.waitForExistence(timeout: 5), "Expected the selected mock-exam answer to survive compact Back navigation")
    }

    func testCompactHomeStartPracticeAndMockExamBackReturnToHome() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "home",
            "-CanadianHamPracticeLimit", "1",
            "-CanadianHamMockExamLimit", "1"
        ])
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts["Ready for Basic with Honours?"].firstMatch.waitForExistence(timeout: 10))
        tap("Start practice", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10))
        tapCompactBack(in: app)
        XCTAssertTrue(app.staticTexts["Ready for Basic with Honours?"].firstMatch.waitForExistence(timeout: 10), "Back from Start practice should return to Home")

        tap("Mock exam", in: app)
        XCTAssertTrue(app.buttons["Start mock exam"].firstMatch.waitForExistence(timeout: 10))
        tapCompactBack(in: app)
        XCTAssertTrue(app.staticTexts["Ready for Basic with Honours?"].firstMatch.waitForExistence(timeout: 10), "Back from Mock exam should return to Home")
    }

    func testAboutShowsReleaseAttributionDisclaimerAndBankVersion() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "about"])
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts["About Canadian Ham"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Active bank: basic-2025-07-15, effective 2025-07-15."), "Expected active bank version and effective date on About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Contains information reproduced from Innovation, Science and Economic Development Canada"), "Expected ISED attribution on About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "canadian-ham is an independent study tool"), "Expected disclaimer on About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Draft attribution, not in effect"), "Expected visible draft-attribution warning on About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "has not yet been granted"), "Expected pending permission status on About")
        assertAboutLowerSectionsReachable(in: app, platformName: "iOS")
    }

    func testFrenchAboutKeepsLegalTextInEnglish() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_CA", "-CanadianHamInitialScreen", "about"])
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts["À propos de Canadian Ham"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Banque"].firstMatch.waitForExistence(timeout: 5), "Expected localized French About section heading")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Draft attribution, not in effect"), "Expected English legal status in French About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Contains information reproduced from Innovation, Science and Economic Development Canada"), "Expected English attribution text in French About")
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "canadian-ham is an independent study tool"), "Expected English disclaimer text in French About")
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])

        assertSingleLanguagePicker(in: app, context: "practice")
        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        let frenchSegment = languagePicker.buttons["Français"].firstMatch
        XCTAssertTrue(frenchSegment.waitForExistence(timeout: 2), "French segment should be available")
        let selectedPredicate = NSPredicate(format: "selected == true")
        for _ in 0..<3 where !frenchSegment.isSelected {
            frenchSegment.tap()
            let selectedExpectation = XCTNSPredicateExpectation(predicate: selectedPredicate, object: frenchSegment)
            if XCTWaiter.wait(for: [selectedExpectation], timeout: 2) == .completed { break }
        }
        XCTAssertTrue(frenchSegment.isSelected, "Français segment should become selected")

        let frenchQuestionTexts = try bundledFrenchQuestionTexts(forCategoryID: "B-001")
        let frenchQuestionPredicate = NSPredicate(format: "label IN %@", Array(frenchQuestionTexts))
        let visibleFrenchQuestion = app.staticTexts.matching(frenchQuestionPredicate).firstMatch
        XCTAssertTrue(
            visibleFrenchQuestion.waitForExistence(timeout: 5),
            "Expected one of the bundled French B-001 question stems after switching language"
        )

        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        let feedbackTitle = app.staticTexts["answer-feedback-title"].firstMatch
        XCTAssertTrue(feedbackTitle.waitForExistence(timeout: 5), "Feedback title should exist")
        XCTAssertTrue(
            feedbackTitle.label.hasPrefix("Correct") || feedbackTitle.label.hasPrefix("Incorrect"),
            "Feedback title should start with Correct or Incorrect, got: \(feedbackTitle.label)"
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

    func testLanguagePickerExistsOnCompactHomeLearnMorseAndMockExam() throws {
        XCUIDevice.shared.appearance = .light
        for (screen, expectedText) in [
            ("home", "Ready for Basic with Honours?"),
            ("learn", "Structured lessons"),
            ("morse", "Quick listen"),
            ("mock", "Mock exam")
        ] {
            let app = launchApp(arguments: ["-CanadianHamInitialScreen", screen])
            assertSingleLanguagePicker(in: app, context: screen)
            XCTAssertTrue(app.staticTexts[expectedText].firstMatch.waitForExistence(timeout: 10), "Expected \(screen) screen content")
            app.terminate()
        }
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
#if os(iOS)
        // Forced regular size class alone does not expose the split-view sidebar on the iPhone simulator.
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
#endif
        let app = launchApp(arguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        XCTAssertTrue(app.descendants(matching: .any)["root-sidebar"].firstMatch.waitForExistence(timeout: 10))
        tap("Learn", in: app)
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
        scrollAndTap("Open lesson L-001-01", in: app)
        XCTAssertTrue(app.staticTexts["Authority, certificates, and exams"].waitForExistence(timeout: 10), "Lesson citation link should be independently activatable from practice feedback")
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

    func testPracticeModeChangeReopensCachedSessionFresh() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "home",
            "-CanadianHamPracticeLimit", "1",
            "-CanadianHamPracticeSeed", "ui-mode-change-cache"
        ])
        defer { app.terminate() }

        tap("Start practice", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)

        tapCompactBack(in: app)
        tapCompactBack(in: app)
        tap("Settings", in: app)
        let practiceModePicker = app.segmentedControls["practice-mode-picker"].firstMatch
        XCTAssertTrue(practiceModePicker.waitForExistence(timeout: 10), "Settings should expose the practice mode picker")
        let reviewLater = practiceModePicker.buttons["Review later"].firstMatch
        XCTAssertTrue(reviewLater.waitForExistence(timeout: 5), "Practice mode picker should expose Review later")
        reviewLater.tap()

        tapCompactBack(in: app)
        tap("Home", in: app)
        tap("Start practice", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10))
        waitForPracticeTally(containing: "Answered 0 of 1", in: app)
        XCTAssertFalse(app.descendants(matching: .any)["answer-feedback"].firstMatch.exists, "Changing practice mode should reopen a fresh session without stale immediate feedback")

        answerFirstVisibleAnswer(in: app)
        waitForPracticeTally(containing: "Answered 1 of 1", in: app)
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Correct answer"), "Fresh review-later session should not reveal correctness before submit")
        scrollAndTap("Submit for review", in: app)
        XCTAssertTrue(app.staticTexts["Practice review"].waitForExistence(timeout: 10), "Fresh review-later session should submit through review mode")
    }

    func testWeakAreasImmediateSessionKeepsFeedbackPositionAndTallyAfterAnswers() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "practice",
            "-CanadianHamSeedPracticeProgressFixture", "weak-due",
            "-CanadianHamPracticeMode", "immediate",
            "-CanadianHamPracticeLimit", "2",
            "-CanadianHamPracticeSeed", "ui-weak-immediate-stability"
        ])
        defer { app.terminate() }

        tapButton(containing: "Start weak areas", in: app)
        let questionIdentifier = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionIdentifier.waitForExistence(timeout: 10))
        let firstQuestionID = questionIdentifier.label

        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        waitForPracticeTally(containing: "1 answered question", in: app)
        XCTAssertEqual(questionIdentifier.label, firstQuestionID, "Weak-area immediate save should not reload away from the answered question")
        XCTAssertTrue(app.buttons["Next question"].firstMatch.waitForExistence(timeout: 5), "Immediate feedback controls should remain after the first weak-area answer")

        scrollAndTap("Next question", in: app)
        scrollToTop(in: app)
        XCTAssertNotEqual(questionIdentifier.label, firstQuestionID, "Next question should advance within the same weak-area session")
        let secondQuestionID = questionIdentifier.label
        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        waitForPracticeTally(containing: "2 answered questions", in: app)
        XCTAssertEqual(questionIdentifier.label, secondQuestionID, "Weak-area immediate save should keep the second answered position")
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback"].firstMatch.exists, "Second-answer feedback should remain after saving progress")
    }

    func testDueReviewLaterSessionKeepsPositionTallyAndReviewAfterSubmit() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "practice",
            "-CanadianHamSeedPracticeProgressFixture", "weak-due",
            "-CanadianHamPracticeMode", "review-later",
            "-CanadianHamPracticeLimit", "2",
            "-CanadianHamPracticeSeed", "ui-due-review-later-stability"
        ])
        defer { app.terminate() }

        tapButton(containing: "Start due review", in: app)
        let questionIdentifier = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionIdentifier.waitForExistence(timeout: 10))
        let firstQuestionID = questionIdentifier.label

        answerFirstVisibleAnswer(in: app)
        waitForPracticeTally(containing: "Answered 1 of 2", in: app)
        scrollAndTap("Next question", in: app)
        scrollToTop(in: app)
        XCTAssertNotEqual(questionIdentifier.label, firstQuestionID, "Due review-later Next should advance instead of reloading question one")
        let secondQuestionID = questionIdentifier.label

        answerFirstVisibleAnswer(in: app)
        waitForPracticeTally(containing: "Answered 2 of 2", in: app)
        XCTAssertEqual(questionIdentifier.label, secondQuestionID, "Due review-later selection should keep the second question position before submit")
        scrollAndTap("Submit for review", in: app)

        XCTAssertTrue(app.staticTexts["Practice review"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5), "Due review-later submit should keep review feedback visible after saving progress")
        waitForPracticeTally(containing: "2 answered questions", in: app)
        waitBriefly(1.0)
        XCTAssertTrue(app.staticTexts["Practice review"].exists, "Saving due review-later progress must not reset the review screen")
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

    func testMockExamNextUnansweredJumpsAfterAnsweringFirstQuestion() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-next-unanswered",
            "-CanadianHamMockExamLimit", "3"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 3"].waitForExistence(timeout: 10))

        answerFirstVisibleAnswer(in: app)
        scrollToTop(in: app)
        let nextUnanswered = app.buttons["mock-next-unanswered-button"].firstMatch
        XCTAssertTrue(nextUnanswered.waitForExistence(timeout: 5), "Mock exam should expose Next unanswered")
        scrollUntilHittable(nextUnanswered, in: app, maxSwipes: 8)
        XCTAssertTrue(nextUnanswered.isEnabled, "Next unanswered should be enabled when a later question is unanswered")
        XCTAssertTrue(nextUnanswered.isHittable, "Next unanswered should be hittable after returning to the question header")
        nextUnanswered.tap()

        XCTAssertTrue(app.staticTexts["Question 2 of 3"].waitForExistence(timeout: 5), "Next unanswered should advance to the first unanswered question")
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

    func testRegularWidthMockExamEndExamDiscardsInProgressSession() throws {
        XCUIDevice.shared.appearance = .light
#if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
#endif
        let app = launchApp(arguments: [
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-regular-end-exam",
            "-CanadianHamMockExamLimit", "1"
        ])
        defer { app.terminate() }
        XCTAssertTrue(app.descendants(matching: .any)["root-sidebar"].firstMatch.waitForExistence(timeout: 10), "Regular-width launch argument should force the split-view sidebar on iPhone simulators")
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 1"].firstMatch.waitForExistence(timeout: 10))
        scrollAndTap("End exam", in: app)
        confirmEndExamAlert(in: app)
        XCTAssertTrue(app.buttons["Start mock exam"].firstMatch.waitForExistence(timeout: 10), "End exam should return regular width to the mock-exam start screen")
        XCTAssertFalse(app.staticTexts["Question 1 of 1"].firstMatch.exists, "End exam should discard the regular-width in-progress mock exam")
    }

    func testMockExamResultHeadingCarriesVoiceOverSubmissionSummary() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-results-heading-announcement",
            "-CanadianHamMockExamLimit", "1"
        ])

        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 1"].waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)

        let heading = app.staticTexts["mock-results-heading"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Mock results should expose a deterministic heading for VoiceOver focus")
        XCTAssertEqual(heading.elementType, .staticText, "Results focus target should be an accessibility static text heading")
        XCTAssertTrue(heading.label.hasPrefix("Mock exam submitted. "), "Heading accessibility label should carry the submission announcement text, got: \(heading.label)")
        XCTAssertTrue(
            heading.label.contains("Basic with Honours") || heading.label.contains("Pass") || heading.label.contains("Needs review"),
            "Heading accessibility label should include the result status, got: \(heading.label)"
        )
        XCTAssertTrue(heading.label.contains(" of 1."), "Heading accessibility label should include the score total, got: \(heading.label)")
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(heading, in: app),
            "Results heading should be visible after submission so VoiceOver can move focus to it. Frame: \(frameDescription(heading.frame))"
        )
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

    func testSettingsResetClearsCompactMockExamCacheWithoutRelaunch() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-reset-clears-cache",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 1"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)

        tapCompactBack(in: app)
        tapCompactBack(in: app)
        tap("Settings", in: app)
        XCTAssertTrue(app.staticTexts["Settings"].firstMatch.waitForExistence(timeout: 10))
        scrollAndTap("Reset all data", in: app)
        confirmResetAlert(in: app)
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "All local progress was reset."), "Reset should show a success status")

        tapCompactBack(in: app)
        tap("Home", in: app)
        tap("Mock exam", in: app)
        XCTAssertTrue(app.buttons["Start mock exam"].firstMatch.waitForExistence(timeout: 10), "Reset should discard the in-memory compact mock exam without relaunching")
        XCTAssertFalse(app.staticTexts["Question 1 of 1"].firstMatch.exists, "The stale in-progress mock exam question should not remain after reset")
    }

    func testCompactMockExamEndExamDiscardsInProgressSession() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-end-exam",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["Question 1 of 1"].firstMatch.waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("End exam", in: app)
        confirmEndExamAlert(in: app)
        XCTAssertTrue(app.buttons["Start mock exam"].firstMatch.waitForExistence(timeout: 10), "End exam should return to the mock-exam start screen")
        XCTAssertFalse(app.staticTexts["Question 1 of 1"].firstMatch.exists, "End exam should discard the in-progress mock exam")
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

    func testMockExamHeaderControlsSupportLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-mock-header-accessibility-size",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1",
            "-CanadianHamExamTimerEnabled", "true",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        scrollToTop(in: app)
        let flagButton = app.buttons["mock-flag-button"].firstMatch
        let questionsButton = app.buttons["mock-questions-button"].firstMatch
        XCTAssertTrue(flagButton.waitForExistence(timeout: 5), "Flag control should exist at the largest accessibility text size")
        scrollUntilHittable(flagButton, in: app, maxSwipes: 8)
        XCTAssertTrue(flagButton.isHittable, "Flag control should remain reachable at the largest accessibility text size")
        XCTAssertTrue(questionsButton.waitForExistence(timeout: 5), "Questions control should exist at the largest accessibility text size")
        scrollUntilHittable(questionsButton, in: app, maxSwipes: 8)
        XCTAssertTrue(questionsButton.isHittable, "Questions control should remain reachable at the largest accessibility text size")

        flagButton.tap()
        XCTAssertTrue(app.buttons["Flagged for review"].firstMatch.waitForExistence(timeout: 5), "Flag control should remain usable after wrapping")
        scrollUntilHittable(questionsButton, in: app, maxSwipes: 8)
        questionsButton.tap()
        XCTAssertTrue(app.staticTexts["Question navigator"].waitForExistence(timeout: 5), "Questions control should remain usable after wrapping")
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

    private func auditMorseExamGradedDiff(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "morse",
            "-CanadianHamMorseExamPlaybackSeconds", "0.1",
            "-CanadianHamMorseExamReviewSeconds", "1"
        ])
        defer { app.terminate() }

        let examStart = app.buttons["morse-exam-start-button"].firstMatch
        XCTAssertTrue(examStart.waitForExistence(timeout: 10))
        scrollUntilHittable(examStart, in: app, maxSwipes: 8)
        examStart.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "FAIL")).firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Character diff"].firstMatch.waitForExistence(timeout: 5))
        let diffView = app.descendants(matching: .any)["morse-diff-view"].firstMatch
        XCTAssertTrue(diffView.waitForExistence(timeout: 5), "Expected the graded Morse diff view before auditing")
        try app.performAccessibilityAudit(for: .contrast) { issue in
            let identifier = issue.element?.identifier ?? ""
            let label = issue.element?.label ?? ""
            let isMorseDiffIssue = identifier.hasPrefix("morse-diff") || label == "Character diff" || label.contains("expected") || label.contains("received")
            return !isMorseDiffIssue
        }
    }

    private func auditCoreScreens(appearance: AuditAppearance) throws {
        var app = launchApp()
        XCTAssertTrue(app.descendants(matching: .any)["compact-root-list"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) compact root list")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "home"])
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

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "morse"])
        XCTAssertTrue(app.staticTexts["Quick listen"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) morse")
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
        answerKnownCorrectLifeAnswerIfPresent(in: correctApp, identifier: "answer-C-button")
        _ = waitForAnswerFeedback(in: correctApp)
        let correctFeedbackTitle = correctApp.staticTexts["answer-feedback-title"].firstMatch
        XCTAssertTrue(correctFeedbackTitle.waitForExistence(timeout: 5), "Correct-answer feedback title should exist")
        XCTAssertEqual(correctFeedbackTitle.label, "Correct", "Audit fixture should expose the exact correct-answer state")
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
        scrollToTop(in: reviewApp)
        try performAudit(on: reviewApp, context: "\(appearance.rawValue) practice review")
        scrollPracticeReviewFeedbackIntoView(in: reviewApp)
        try performAudit(on: reviewApp, context: "\(appearance.rawValue) practice review feedback")
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
        try performAudit(on: app, context: "\(appearance.rawValue) lesson quiz answered")
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
        let pauseTimer = timerApp.buttons["Pause timer"].firstMatch
        XCTAssertTrue(pauseTimer.waitForExistence(timeout: 5), "Timer-enabled mock exam should auto-start and expose Pause timer on the question screen")
        XCTAssertTrue(pauseTimer.isHittable, "Pause timer should be visible and hittable before auditing the question screen")
        let timerPrevious = timerApp.buttons["mock-previous-button"].firstMatch
        let timerNext = timerApp.buttons["mock-next-button"].firstMatch
        XCTAssertTrue(timerPrevious.waitForExistence(timeout: 5), "One-question mock exam should expose Previous")
        XCTAssertTrue(timerNext.waitForExistence(timeout: 5), "One-question mock exam should expose Next")
        XCTAssertFalse(timerPrevious.isEnabled, "Previous should be disabled on a one-question mock exam")
        XCTAssertFalse(timerNext.isEnabled, "Next should be disabled on a one-question mock exam")
        try performAudit(on: timerApp, context: "\(appearance.rawValue) mock exam question timer")
        tap("Questions", in: timerApp)
        XCTAssertTrue(timerApp.staticTexts["Question navigator"].waitForExistence(timeout: 5))
        try performAudit(on: timerApp, context: "\(appearance.rawValue) mock exam question navigator timer")
        timerApp.terminate()

        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-a11y-mock-exam-answered-flagged",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "3"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        let topAnswer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(topAnswer.waitForExistence(timeout: 5), "Answered-flagged fixture should expose answer A")
        XCTAssertTrue(topAnswer.isHittable, "Answered-flagged fixture should answer the visible top answer at offset 0")
        topAnswer.tap()
        waitBriefly()
        tap("Flag for review", in: app)
        waitBriefly()
        XCTAssertTrue(topAnswer.isHittable, "Selected top answer should remain visible before auditing")
        XCTAssertTrue(topAnswer.label.localizedCaseInsensitiveContains("Selected"), "Selected top answer should expose the Selected state before auditing")
        XCTAssertTrue(app.buttons["Flagged for review"].firstMatch.waitForExistence(timeout: 5), "Mock exam should expose the flagged state before auditing")
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam answered flagged question")
        tap("Questions", in: app)
        XCTAssertTrue(app.staticTexts["Question navigator"].firstMatch.waitForExistence(timeout: 5), "Mock exam should expose the navigator sheet before auditing")
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam question navigator answered flagged")
        tap("Done", in: app)
        let next = app.buttons["mock-next-button"].firstMatch
        XCTAssertTrue(next.isEnabled, "Answered-flagged audit fixture should keep mock Next enabled")
        next.tap()

        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        scrollToTop(in: app)
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam results")
        scrollMockResultsDetailsIntoView(in: app)
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam results details")
        app.terminate()
    }

    private func launchApp(arguments: [String] = [], resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (resetData ? ["-CanadianHamResetDataOnLaunch"] : []) + arguments
        app.launch()
        return app
    }

    private func performAudit(on app: XCUIApplication, context _: String) throws {
        try app.performAccessibilityAudit()
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

    private func tapButton(containing labelFragment: String, in app: XCUIApplication) {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", labelFragment)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button containing \(labelFragment)")
        scrollUntilHittable(button, in: app, maxSwipes: 10)
        XCTAssertTrue(button.isHittable, "Expected button containing \(labelFragment) to be hittable")
        button.tap()
    }

    private func tapCompactBack(in app: XCUIApplication) {
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Expected a navigation bar with a compact Back button")
        let backButton = navigationBar.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Expected compact Back button")
        backButton.tap()
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

    private func confirmEndExamAlert(in app: XCUIApplication) {
        let alert = app.alerts["End mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["End exam"].tap()
    }

    private func assertMockExamResultVisible(in app: XCUIApplication) {
        let heading = app.staticTexts["mock-results-heading"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Expected mock exam results heading to remain visible")
        XCTAssertTrue(
            heading.label.contains("Needs review")
            || heading.label.contains("Pass")
            || heading.label.contains("Basic with Honours"),
            "Expected mock exam results status in heading label, got: \(heading.label)"
        )
    }

    private func assertMockExamResultDetailsVisible(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Category breakdown"].waitForExistence(timeout: 5), "Mock exam results should include category breakdown")
        XCTAssertTrue(app.staticTexts["Wrong-answer review"].firstMatch.exists, "Mock exam results should include wrong-answer review")
    }

    private func scrollMockResultsDetailsIntoView(in app: XCUIApplication) {
        let categoryBreakdown = app.descendants(matching: .any)["mock-results-category-breakdown"].firstMatch
        XCTAssertTrue(categoryBreakdown.waitForExistence(timeout: 5), "Mock exam results should expose a deterministic category-breakdown anchor")
        scrollUntilPartiallyVisible(categoryBreakdown, in: app, maxSwipes: 12)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(categoryBreakdown, in: app),
            "Category breakdown anchor should be visible below the navigation bar before auditing mock results details. Frame: \(frameDescription(categoryBreakdown.frame))"
        )
        let wrongAnswerReview = app.descendants(matching: .any)["mock-results-wrong-answer-review"].firstMatch
        XCTAssertTrue(wrongAnswerReview.waitForExistence(timeout: 5), "Mock exam results should expose a deterministic wrong-answer-review anchor")
        scrollUntilPartiallyVisible(wrongAnswerReview, in: app, maxSwipes: 12)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(wrongAnswerReview, in: app),
            "Wrong-answer review anchor should be visible below the navigation bar before auditing mock results details. Frame: \(frameDescription(wrongAnswerReview.frame))"
        )
    }

    private func scrollPracticeReviewFeedbackIntoView(in app: XCUIApplication) {
        let explanation = app.descendants(matching: .any)["explanation-panel"].firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 5), "Practice review should expose a deterministic explanation anchor")
        scrollUntilPartiallyVisible(explanation, in: app, maxSwipes: 12)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(explanation, in: app),
            "Explanation panel anchor should be visible below the navigation bar before auditing practice review feedback. Frame: \(frameDescription(explanation.frame))"
        )
    }

    private func answerKnownCorrectLifeAnswerIfPresent(in app: XCUIApplication, identifier: String) {
        let correctAnswer = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(correctAnswer.waitForExistence(timeout: 5), "Known correct answer \(identifier) should exist for the fixed life-answer fixture")
        scrollUntilHittable(correctAnswer, in: app, maxSwipes: 10)
        XCTAssertTrue(correctAnswer.isHittable, "Known correct answer \(identifier) should be hittable for the fixed life-answer fixture")
        correctAnswer.tap()
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

    private func waitForPracticeTally(containing needle: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", needle)
        let tally = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(tally.waitForExistence(timeout: 5), "Expected practice tally containing \(needle)", file: file, line: line)
    }

    private func assertAboutLowerSectionsReachable(
        in app: XCUIApplication,
        platformName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let disclaimer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "canadian-ham is an independent study tool")).firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5), "Expected About disclaimer text on \(platformName)", file: file, line: line)
        scrollUntilPartiallyVisible(disclaimer, in: app, maxSwipes: 10)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(disclaimer, in: app),
            "About disclaimer text should be on screen on \(platformName), not merely present off screen. Frame: \(frameDescription(disclaimer.frame))",
            file: file,
            line: line
        )

        let privacy = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "works fully offline with bundled content")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), "Expected About privacy text on \(platformName)", file: file, line: line)
        scrollUntilPartiallyVisible(privacy, in: app, maxSwipes: 10)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(privacy, in: app),
            "About privacy text should be on screen on \(platformName), not merely present off screen. Frame: \(frameDescription(privacy.frame))",
            file: file,
            line: line
        )
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
        scrollUntilHittable(button, in: app, maxSwipes: 24)
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
