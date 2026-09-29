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

    private func auditScreen(_ screen: PlatformAuditScreen) throws {
        for appearance in ["light", "dark"] {
            let app = configuredApp(screen: screen, appearance: appearance)
            app.launch()

            XCTAssertTrue(app.staticTexts[screen.waitLabel].firstMatch.waitForExistence(timeout: 15), "Expected \(screen.waitLabel) for \(appearance) \(screen.rawValue)")
            try performAudit(on: app, context: "\(appearance) \(screen.rawValue)")
            app.terminate()

            if screen == .practice {
                let answeredApp = configuredApp(screen: screen, appearance: appearance, answeredSourceIndex: 0)
                answeredApp.launch()
                XCTAssertTrue(answeredApp.staticTexts[screen.waitLabel].firstMatch.waitForExistence(timeout: 15), "Expected answered practice question for \(appearance)")
                XCTAssertTrue(answeredApp.staticTexts["Correct"].firstMatch.waitForExistence(timeout: 5), "Expected fixed launch-argument feedback state")
                try performAudit(on: answeredApp, context: "\(appearance) answered practice")
                answeredApp.terminate()
            }
        }
    }

    private func configuredApp(screen: PlatformAuditScreen, appearance: String, answeredSourceIndex: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-CanadianHamPlatformInitialScreen", screen.rawValue,
            "-CanadianHamPlatformCategoryID", "B-001",
            "-CanadianHamPlatformQuestionID", "B-001-002-002",
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
}

private enum PlatformAuditScreen: String {
    case categories
    case practice
    case about

    var waitLabel: String {
        switch self {
        case .categories:
            "Practice categories"
        case .practice:
            "An Amateur Radio Operator Certificate is valid for:"
        case .about:
            "About Canadian Ham"
        }
    }
}
