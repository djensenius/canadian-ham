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

    func testAboutShowsReleaseAttributionDisclaimerAndBankVersion() throws {
        let app = configuredApp(screen: .about, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.about.waitElement(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(anyLabel(in: app, contains: "Active bank: basic-2025-07-15, effective 2025-07-15."), "Expected active bank version and effective date on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Contains information reproduced from Innovation, Science and Economic Development Canada"), "Expected ISED attribution on visionOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "canadian-ham is an independent study tool"), "Expected disclaimer on visionOS About")
    }

    func testPracticeInteractionSwitchesLanguageShowsFeedbackAndAdvances() throws {
        let app = configuredApp(screen: .practice, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.practice.waitElement(in: app).waitForExistence(timeout: 15), "Expected fixed practice question")

        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        let frenchSegment = languagePicker.buttons["Français"].firstMatch
        XCTAssertTrue(frenchSegment.waitForExistence(timeout: 5), "French language segment should exist")
        frenchSegment.tap()
        XCTAssertTrue(
            app.staticTexts[Self.fixedFrenchQuestionText].firstMatch.waitForExistence(timeout: 5),
            "Fixed question should switch to French"
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
    case about

    @MainActor
    func waitElement(in app: XCUIApplication) -> XCUIElement {
        switch self {
        case .categories:
            app.staticTexts["Practice categories"].firstMatch
        case .practice:
            app.staticTexts["An Amateur Radio Operator Certificate is valid for:"].firstMatch
        case .about:
            app.staticTexts["About Canadian Ham"].firstMatch
        }
    }
}
