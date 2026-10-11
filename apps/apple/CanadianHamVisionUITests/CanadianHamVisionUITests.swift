import XCTest

@MainActor
final class CanadianHamVisionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCategoryGridAccessibilityAuditLightAndDark() throws {
        try auditScreen(.categories)
    }

    func testPracticeAccessibilityAuditLightAndDark() throws {
        try auditScreen(.practice)
    }

    func testAboutAccessibilityAuditLightAndDark() throws {
        try auditScreen(.about)
    }

    func testMorseAccessibilityAuditLightAndDark() throws {
        try auditScreen(.morse)
    }

    func testMorseScreenShowsPlaybackControls() throws {
        let app = configuredApp(screen: .morse, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.morse.waitElement(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Play"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Stop"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hidden until playback finishes."].firstMatch.exists)
    }

    func testCategoryGridNavigatesToMorse() throws {
        let app = configuredApp(screen: .categories, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 15))
        let morseButton = app.buttons["vision-morse-button"].firstMatch
        XCTAssertTrue(morseButton.waitForExistence(timeout: 5), "Category grid should expose Morse")
        morseButton.tap()
        XCTAssertTrue(PlatformAuditScreen.morse.waitElement(in: app).waitForExistence(timeout: 10), "Morse should be reachable from the category grid")
        app.buttons["Categories"].firstMatch.tap()
        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 5), "Categories should return Morse to the category grid")
    }

    func testAboutShowsReleaseAttributionDisclaimerAndBankVersion() throws {
        let app = configuredApp(screen: .about, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.about.waitElement(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(anyLabel(in: app, contains: "Active bank: basic-2025-07-15, effective 2025-07-15."), "Expected active bank version and effective date on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Contains information reproduced from Innovation, Science and Economic Development Canada"), "Expected ISED attribution on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "canadian-ham is an independent study tool"), "Expected disclaimer on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Practice sessions are kept only while the app is open"), "Expected ephemeral practice-session privacy copy on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Draft attribution, not in effect"), "Expected visible draft-attribution warning on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "has not yet been granted"), "Expected pending permission status on visionOS About")
        assertAboutLowerSectionsReachable(in: app, platformName: "visionOS")
    }

    func testPracticeInteractionUsesConfiguredLanguageShowsFeedbackAndAdvances() throws {
        let app = configuredApp(screen: .practice, appearance: "light", language: "fr")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.practice.waitElement(in: app).waitForExistence(timeout: 15), "Expected fixed practice question")

        XCTAssertFalse(app.segmentedControls["question-language-picker"].firstMatch.exists, "visionOS practice should not show a language picker")
        XCTAssertTrue(
            app.staticTexts[Self.fixedFrenchQuestionText].firstMatch.waitForExistence(timeout: 5),
            "Fixed question should use the configured French language"
        )

        answerFirstVisibleQuestion(in: app)
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Feedback should appear after selecting an answer")

        let nextQuestion = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question button should exist")
        assertNextQuestionIsSeparateButton(nextQuestion, feedback: feedback)
        scrollUntilHittable(nextQuestion, in: app, maxSwipes: 8)
        nextQuestion.tap()
        waitForElementToDisappear(feedback, timeout: 5, message: "Feedback should disappear after advancing to the next question")
    }

    func testLongestQuestionSupportsLargestDynamicType() throws {
        let defaultApp = configuredApp(
            screen: .practice,
            appearance: "light",
            categoryID: Self.longestQuestionCategoryID,
            questionID: Self.longestQuestionID,
            language: Self.longestQuestionLanguage
        )
        defaultApp.launch()
        let defaultQuestion = defaultApp.staticTexts.matching(NSPredicate(format: "label == %@", Self.longestQuestionText)).firstMatch
        XCTAssertTrue(defaultQuestion.waitForExistence(timeout: 15), "Expected the longest bundled question to render at the default Dynamic Type size")
        let defaultQuestionHeight = defaultQuestion.frame.height
        defaultApp.terminate()

        let app = configuredApp(
            screen: .practice,
            appearance: "light",
            categoryID: Self.longestQuestionCategoryID,
            questionID: Self.longestQuestionID,
            language: Self.longestQuestionLanguage
        )
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        defer { app.terminate() }

        let question = app.staticTexts.matching(NSPredicate(format: "label == %@", Self.longestQuestionText)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 15), "Expected the longest bundled question to render at the largest Dynamic Type size")
        XCTAssertEqual(question.label, Self.longestQuestionText, "Longest question text should not be truncated in the accessibility tree")
        XCTAssertGreaterThan(
            question.frame.height,
            defaultQuestionHeight * 2.4,
            "Largest Dynamic Type should make the full longest-question text much taller than the default rendering"
        )

        answerFirstVisibleQuestion(in: app)
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Feedback should remain reachable at the largest Dynamic Type size")
        let nextQuestion = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question should exist at the largest Dynamic Type size")
        assertNextQuestionIsSeparateButton(nextQuestion, feedback: feedback)
        scrollUntilHittable(nextQuestion, in: app, maxSwipes: 12)
        XCTAssertTrue(nextQuestion.isHittable, "Next question should be reachable by scrolling at the largest Dynamic Type size")
    }

    private func auditScreen(_ screen: PlatformAuditScreen) throws {
        for appearance in ["light", "dark"] {
            let app = configuredApp(screen: screen, appearance: appearance)
            app.launch()

            XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) for \(appearance)")
            try performAudit(on: app, context: "\(appearance) \(screen.rawValue)")
            app.terminate()

            if screen == .practice {
                let answeredApp = configuredApp(screen: screen, appearance: appearance, answeredSourceIndex: 0)
                answeredApp.launch()
                XCTAssertTrue(screen.waitElement(in: answeredApp).waitForExistence(timeout: 15), "Expected answered practice question for \(appearance)")
                XCTAssertTrue(
                    answeredApp.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5),
                    "Expected fixed launch-argument feedback state"
                )
                try performAudit(on: answeredApp, context: "\(appearance) answered practice")
                answeredApp.terminate()
            }
        }
    }

    private func configuredApp(
        screen: PlatformAuditScreen,
        appearance: String,
        categoryID: String = "B-001",
        questionID: String = "B-001-002-002",
        answeredSourceIndex: Int? = nil,
        language: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-CanadianHamPlatformInitialScreen", screen.rawValue,
            "-CanadianHamPlatformCategoryID", categoryID,
            "-CanadianHamPlatformQuestionID", questionID,
            "-CanadianHamAppearance", appearance
        ]
        if let answeredSourceIndex {
            app.launchArguments += ["-CanadianHamPlatformAnsweredSourceIndex", "\(answeredSourceIndex)"]
        }
        if let language {
            app.launchArguments += ["-CanadianHamLanguage", language]
        }
        return app
    }

    private func performAudit(on app: XCUIApplication, context _: String) throws {
        try app.performAccessibilityAudit()
    }

    private func assertNextQuestionIsSeparateButton(
        _ nextQuestion: XCUIElement,
        feedback: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(nextQuestion.elementType, .button, "Next question should be exposed as its own button element", file: file, line: line)
        XCTAssertFalse(
            feedback.descendants(matching: .button)["next-question-button"].exists,
            "Next question must not be nested inside the ignored feedback accessibility element",
            file: file,
            line: line
        )
    }

    private func answerFirstVisibleQuestion(in app: XCUIApplication) {
        let firstAnswer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 10), "An answer should exist")

        for identifier in ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"] {
            let answer = app.descendants(matching: .any)[identifier].firstMatch
            if answer.exists && answer.isHittable {
                answer.tap()
                return
            }
        }

        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<10 {
            scrollView.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
            for identifier in ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"] {
                let answer = app.descendants(matching: .any)[identifier].firstMatch
                if answer.exists && answer.isHittable {
                    answer.tap()
                    return
                }
            }
        }

        XCTFail("At least one answer should be hittable after scrolling")
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<maxSwipes where !element.isHittable {
            scrollView.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func assertAboutLowerSectionsReachable(
        in app: XCUIApplication,
        platformName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let disclaimer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "canadian-ham is an independent study tool")).firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5), "Expected About disclaimer text on \(platformName)", file: file, line: line)
        scrollUntilOnScreen(disclaimer, in: app, maxSwipes: 10)
        XCTAssertTrue(
            isOnScreen(disclaimer, in: app),
            "About disclaimer text should be on screen on \(platformName), not merely present off screen. Frame: \(frameDescription(disclaimer.frame))",
            file: file,
            line: line
        )

        let privacy = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Practice sessions are kept only while the app is open")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), "Expected About privacy text on \(platformName)", file: file, line: line)
        scrollUntilOnScreen(privacy, in: app, maxSwipes: 10)
        XCTAssertTrue(
            isOnScreen(privacy, in: app),
            "About privacy text should be on screen on \(platformName), not merely present off screen. Frame: \(frameDescription(privacy.frame))",
            file: file,
            line: line
        )
    }

    private func scrollUntilOnScreen(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 1) else { return }
        for _ in 0..<maxSwipes where !isOnScreen(element, in: app) {
            if element.frame.maxY <= app.windows.firstMatch.frame.minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func isOnScreen(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return app.windows.firstMatch.frame.insetBy(dx: 16, dy: 16).intersects(element.frame)
    }

    private func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
    }

    private func anyLabel(in app: XCUIApplication, contains needle: String) -> Bool {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", needle)).firstMatch.exists
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private static let fixedFrenchQuestionText = "Le certificat d'opérateur radioamateur est valide pour:"
    private static let longestQuestionID = "B-002-006-007"
    private static let longestQuestionCategoryID = "B-002"
    private static let longestQuestionEnglishText = "Your receiver's S-meter is calibrated to a standard of 6 dB per S-unit per a recommendation by the International Amateur Radio Union (IARU). The S-meter shows S9 when receiving a station transmitting with 100 watts. Neglecting propagation changes, what transmitter power would cause your receiver's S-meter to read S8?"
    private static let longestQuestionFrenchText = "Le S-mètre sur votre récepteur est étalonné selon une recommandation de l'Union internationale des radioamateurs (IARU), soit 6 dB par unité S. Une station utilisant 100 watts est reçue à S9. Sans changement à la propagation, quelle puissance à l'émetteur réduirait l'indication de votre S-mètre à S8?"
    private static var longestQuestionText: String {
        longestQuestionEnglishText.count >= longestQuestionFrenchText.count ? longestQuestionEnglishText : longestQuestionFrenchText
    }
    private static var longestQuestionLanguage: String {
        longestQuestionEnglishText.count >= longestQuestionFrenchText.count ? "en" : "fr"
    }
}

private enum PlatformAuditScreen: String {
    case categories
    case practice
    case morse
    case about

    @MainActor
    func waitElement(in app: XCUIApplication) -> XCUIElement {
        switch self {
        case .categories:
            app.staticTexts["Practice categories"].firstMatch
        case .practice:
            app.staticTexts["An Amateur Radio Operator Certificate is valid for:"].firstMatch
        case .morse:
            app.descendants(matching: .any)["vision-morse-screen"].firstMatch
        case .about:
            app.staticTexts["About Canadian Ham"].firstMatch
        }
    }
}
