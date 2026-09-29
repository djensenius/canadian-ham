import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMockExamHappyPathWithDeterministicSeed() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock", "-CanadianHamMockExamSeed", "ui-mock-exam-seed"])
        tap("Start mock exam", in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].label.contains("ui-mock-exam-seed"))
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("Submit exam", in: app)
        let alert = app.alerts["Submit mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts.element(boundBy: 1).label.contains("unanswered"))
        alert.buttons["Submit"].tap()
        XCTAssertTrue(
            app.staticTexts["Needs review"].waitForExistence(timeout: 10)
            || app.staticTexts["Pass"].waitForExistence(timeout: 1)
            || app.staticTexts["Basic with Honours"].waitForExistence(timeout: 1)
        )
    }

    func testSettingsResetConfirmation() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "settings"])
        scrollAndTap("Reset all data", in: app)
        let alert = app.alerts["Reset all local data?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Reset"].tap()
        XCTAssertTrue(app.staticTexts["All local progress was reset."].waitForExistence(timeout: 5))
    }

    func testPracticeImmediateFeedback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.segmentedControls["question-language-picker"].firstMatch.waitForExistence(timeout: 5))
        answerFirstVisibleAnswer(in: app)
    }

    func testAccessibilityAuditNewScreensLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditNewScreens(appearance: .light)
    }

    func testAccessibilityAuditNewScreensDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditNewScreens(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    private func auditNewScreens(appearance: AuditAppearance) throws {
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

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "settings"])
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) settings")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "about"])
        XCTAssertTrue(app.staticTexts["About Canadian Ham"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) about")
        app.terminate()
    }

    private func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-CanadianHamResetDataOnLaunch"] + arguments
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

    private func open(_ label: String, in app: XCUIApplication) {
        let exactButton = app.buttons[label].firstMatch
        if exactButton.waitForExistence(timeout: 2) {
            if !exactButton.isHittable { scrollToTop(in: app) }
            exactButton.tap()
            return
        }
        let staticText = app.staticTexts[label].firstMatch
        XCTAssertTrue(staticText.waitForExistence(timeout: 5), "Expected navigation item \(label)")
        staticText.tap()
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        button.tap()
    }

    private func scrollAndTap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        for _ in 0..<12 where !button.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(button.isHittable, "Expected button \(label) to be hittable")
        button.tap()
    }

    private func answerFirstVisibleAnswer(in app: XCUIApplication) {
        let identifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        XCTAssertTrue(app.descendants(matching: .any)[identifiers[0]].firstMatch.waitForExistence(timeout: 10))
        for _ in 0..<8 {
            for id in identifiers {
                let button = app.descendants(matching: .any)[id].firstMatch
                if button.exists && button.isHittable {
                    button.tap()
                    return
                }
            }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTFail("No answer button became hittable")
    }

    private func scrollToTop(in app: XCUIApplication) {
        let target = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
        for _ in 0..<4 { target.swipeDown() }
    }
}

private enum AuditAppearance: String {
    case light
    case dark
}
