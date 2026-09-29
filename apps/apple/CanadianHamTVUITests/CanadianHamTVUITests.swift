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
        pressRemote([.right, .select, .right, .select], remote: remote)
        XCTAssertTrue(
            app.staticTexts[Self.fixedFrenchQuestionText].firstMatch.waitForExistence(timeout: 5),
            "Fixed question should switch to French through remote interaction"
        )

        let firstAnswer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 5), "First answer should exist")
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        pressUntil(feedback, exists: true, remote: remote, buttons: [.down, .down, .select, .down, .select, .down, .select, .down, .select])
        XCTAssertTrue(feedback.exists, "Feedback should appear after selecting an answer with the remote")

        let nextQuestion = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question button should exist")
        pressUntil(feedback, exists: false, remote: remote, buttons: [.down, .down, .select, .down, .select, .down, .select])
        XCTAssertFalse(feedback.exists, "Feedback should disappear after advancing to the next question with the remote")
    }

    func testRemoteMenuReturnsPracticeAndAboutToCategoryGrid() throws {
        for screen in [PlatformAuditScreen.practice, .about] {
            let app = configuredApp(screen: screen, appearance: "light")
            app.launch()
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
        if #available(tvOS 17.0, *) {
            try app.performAccessibilityAudit()
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable before tvOS 17 for \(context).")
        }
    }

    private func pressRemote(_ buttons: [XCUIRemote.Button], remote: XCUIRemote) {
        for button in buttons {
            remote.press(button)
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
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
