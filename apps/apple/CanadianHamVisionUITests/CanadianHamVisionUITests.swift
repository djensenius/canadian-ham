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

        let nextQuestion = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question button should exist")
        scrollUntilHittable(nextQuestion, in: app, maxSwipes: 8)
        nextQuestion.tap()
        waitForElementToDisappear(feedback, timeout: 5, message: "Feedback should disappear after advancing to the next question")
    }

    func testLongestQuestionSupportsLargestDynamicType() throws {
        let app = configuredApp(
            screen: .practice,
            appearance: "light",
            categoryID: Self.longestQuestionCategoryID,
            questionID: Self.longestQuestionID
        )
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        defer { app.terminate() }

        let question = app.staticTexts.matching(NSPredicate(format: "label == %@", Self.longestQuestionText)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 15), "Expected the longest bundled English question to render")
        XCTAssertEqual(question.label, Self.longestQuestionText, "Longest question text should not be truncated in the accessibility tree")
        XCTAssertGreaterThan(question.frame.height, 90, "Longest question should occupy a multi-line frame at the largest Dynamic Type size")

        answerFirstVisibleQuestion(in: app)
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Feedback should remain reachable at the largest Dynamic Type size")
        let nextQuestion = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question should exist at the largest Dynamic Type size")
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
        answeredSourceIndex: Int? = nil
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
        return app
    }

    private func performAudit(on app: XCUIApplication, context: String) throws {
        if #available(visionOS 1.0, *) {
            try app.performAccessibilityAudit()
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable for \(context).")
        }
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

    private static let fixedFrenchQuestionText = "Le certificat d'opérateur radioamateur est valide pour:"
    private static let longestQuestionID = "B-002-006-007"
    private static let longestQuestionCategoryID = "B-002"
    private static let longestQuestionText = "Your receiver's S-meter is calibrated to a standard of 6 dB per S-unit per a recommendation by the International Amateur Radio Union (IARU). The S-meter shows S9 when receiving a station transmitting with 100 watts. Neglecting propagation changes, what transmitter power would cause your receiver's S-meter to read S8?"
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
