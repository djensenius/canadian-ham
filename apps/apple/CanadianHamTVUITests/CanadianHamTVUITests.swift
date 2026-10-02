import XCTest

@MainActor
final class CanadianHamTVUITests: XCTestCase {
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

        let remote = XCUIRemote.shared
        let frenchLanguage = app.buttons["question-language-fr-button"].firstMatch
        XCTAssertTrue(frenchLanguage.waitForExistence(timeout: 5), "French language button should exist")
        pressRemote([.right, .select, .right, .select], remote: remote)
        XCTAssertTrue(
            app.staticTexts[Self.fixedFrenchQuestionText].firstMatch.waitForExistence(timeout: 5),
            "Fixed question should switch to French through tvOS interaction"
        )

        let firstAnswer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 5), "First answer should exist")
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        pressUntil(feedback, exists: true, remote: remote, buttons: [.down, .down, .select, .down, .select, .down, .select, .down, .select])
        XCTAssertTrue(feedback.exists, "Feedback should appear after selecting an answer with the remote")

        let nextQuestion = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question button should exist")
        assertNextQuestionIsSeparateButton(nextQuestion, feedback: feedback)
        waitForFocus(on: nextQuestion)
        XCTAssertTrue(nextQuestion.hasFocus, "Next question should receive tvOS focus after answering before Select is pressed")
        assertFocusedElementIsOnScreen(nextQuestion, in: app, description: "Next question")

        remote.press(.select)
        waitForElementToDisappear(feedback, timeout: 5, message: "Feedback should disappear after advancing to the next question with the remote")
        XCTAssertFalse(feedback.exists, "Feedback should disappear after advancing to the next question with the remote")
        XCTAssertTrue(
            app.descendants(matching: .any)["tv-practice-screen"].firstMatch.exists,
            "Advancing with Next question should keep the app on the practice screen"
        )
        let reenabledAnswer = app.buttons["answer-A-button"].firstMatch
        XCTAssertTrue(reenabledAnswer.waitForExistence(timeout: 5), "A new answer should be visible after advancing")
        XCTAssertTrue(reenabledAnswer.isEnabled, "Answers should be re-enabled after advancing to the next question")
    }

    func testFocusRingEvidenceScreenshots() throws {
        try captureFocusRingEvidence(
            screen: .categories,
            appearance: "light",
            targetIdentifier: "category-B-001-button",
            evidenceFocus: "category",
            attachmentName: "tvos-category-focus-ring"
        )
        try captureFocusRingEvidence(
            screen: .practice,
            appearance: "light",
            targetIdentifier: "answer-A-button",
            evidenceFocus: "answer",
            attachmentName: "tvos-answer-focus-ring"
        )
        try captureFocusRingEvidence(
            screen: .practice,
            appearance: "light",
            targetIdentifier: "next-question-button",
            answeredSourceIndex: 0,
            attachmentName: "tvos-primary-focus-ring"
        )
    }

    func testRemoteMenuReturnsPracticeAndAboutToCategoryGrid() throws {
        for screen in [PlatformAuditScreen.practice, .about] {
            let app = configuredApp(screen: screen, appearance: "light")
            app.launch()
            addTeardownBlock { app.terminate() }
            XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) before pressing Menu")

            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(
                PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 5),
                "Menu should return \(screen.rawValue) to the category grid"
            )
            app.terminate()
        }
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
        evidenceFocus: String? = nil
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
        if let evidenceFocus {
            app.launchArguments += ["-CanadianHamTVEvidenceFocus", evidenceFocus]
        }
        return app
    }

    private func performAudit(on app: XCUIApplication, context _: String) throws {
        try app.performAccessibilityAudit()
    }

    private func captureFocusRingEvidence(
        screen: PlatformAuditScreen,
        appearance: String,
        targetIdentifier: String,
        evidenceFocus: String? = nil,
        answeredSourceIndex: Int? = nil,
        attachmentName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let app = configuredApp(
            screen: screen,
            appearance: appearance,
            answeredSourceIndex: answeredSourceIndex,
            evidenceFocus: evidenceFocus
        )
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) before capturing \(attachmentName)", file: file, line: line)
        if answeredSourceIndex != nil {
            XCTAssertTrue(
                app.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5),
                "Expected answered feedback before capturing \(attachmentName)",
                file: file,
                line: line
            )
        }

        let target = app.descendants(matching: .any)[targetIdentifier].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Expected \(targetIdentifier) before capturing \(attachmentName)", file: file, line: line)
        waitForFocus(on: target)
        XCTAssertTrue(target.hasFocus, "Expected \(targetIdentifier) to hold tvOS focus before capturing \(attachmentName)", file: file, line: line)
        assertFocusedElementIsOnScreen(target, in: app, description: targetIdentifier, file: file, line: line)
        attachFocusedScreenshot(target, name: attachmentName)
    }

    private func pressRemote(_ buttons: [XCUIRemote.Button], remote: XCUIRemote) {
        for button in buttons {
            remote.press(button)
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
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

    private func waitForFocus(on element: XCUIElement) {
        for _ in 0..<10 where !element.hasFocus {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func assertFocusedElementIsOnScreen(
        _ element: XCUIElement,
        in app: XCUIApplication,
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.exists, "\(description) must exist before capturing focus-ring evidence", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Focused \(description) must be hittable before capturing focus-ring evidence", file: file, line: line)

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "App window should exist before capturing focus-ring evidence", file: file, line: line)
        XCTAssertFalse(element.frame.isEmpty, "\(description) frame should be non-empty before capture", file: file, line: line)
        XCTAssertTrue(
            window.frame.insetBy(dx: -1, dy: -1).contains(element.frame),
            "Focused \(description) frame \(element.frame) should be inside the app window \(window.frame) before capture",
            file: file,
            line: line
        )
    }

    private func attachFocusedScreenshot(_ element: XCUIElement, name: String) {
        XCTAssertTrue(element.hasFocus, "\(name) must be focused before capturing focus-ring evidence")
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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

    private func pressUntil(
        _ element: XCUIElement,
        exists expectedExistence: Bool,
        remote: XCUIRemote,
        buttons: [XCUIRemote.Button],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for button in buttons {
            if element.exists == expectedExistence { return }
            remote.press(button)
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        XCTAssertEqual(element.exists, expectedExistence, file: file, line: line)
    }

    private static let fixedFrenchQuestionText = "Le certificat d'opérateur radioamateur est valide pour:"
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
