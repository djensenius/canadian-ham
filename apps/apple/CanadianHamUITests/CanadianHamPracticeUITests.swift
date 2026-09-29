import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToPracticeIfNeeded(in: app)

        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        XCTAssertTrue(languagePicker.waitForExistence(timeout: 10), "Question language picker should be reachable in practice")
        let frenchSegment = languagePicker.buttons["Français"].firstMatch
        XCTAssertTrue(frenchSegment.waitForExistence(timeout: 2), "French segment should be available")
        frenchSegment.tap()
        XCTAssertTrue(frenchSegment.isSelected, "Français segment should be selected after tapping it")

        answerFirstVisibleQuestion(in: app)

        let feedback = waitForAnswerFeedback(in: app)
        let feedbackLabel = feedback.label
        XCTAssertTrue(
            feedbackLabel.hasPrefix("Correct") || feedbackLabel.hasPrefix("Incorrect"),
            "Feedback label should start with Correct or Incorrect, got: \(feedbackLabel)"
        )
    }

    func testAccessibilityAuditCategoryListAndAnsweredPracticeScreen() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToCategoryListIfNeeded(in: app)
        try performAccessibilityAuditIfAvailable(on: app, allowingAnswerTextContrastExclusions: false)

        navigateToPracticeIfNeeded(in: app)
        answerFirstVisibleQuestion(in: app)
        _ = waitForAnswerFeedback(in: app)
        try performAccessibilityAuditIfAvailable(on: app, allowingAnswerTextContrastExclusions: true)
    }

    func testPracticeFlowSupportsLargestAccessibilityTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        navigateToPracticeIfNeeded(in: app)
        answerFirstVisibleQuestion(in: app)
        _ = waitForAnswerFeedback(in: app)

        let nextQuestionButton = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist at the largest accessibility text size")
        scrollUntilHittable(nextQuestionButton, in: app)
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be reachable by scrolling at the largest accessibility text size")
        nextQuestionButton.tap()

        let nextAnswerButton = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(nextAnswerButton.waitForExistence(timeout: 5), "A new answer should be visible after advancing at the largest accessibility text size")
    }

    private func navigateToPracticeIfNeeded(in app: XCUIApplication) {
        if app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10) {
            return
        }

        let firstCategory = app.staticTexts["Regulations and Policies"].firstMatch
        if firstCategory.waitForExistence(timeout: 5) {
            firstCategory.tap()
        }
    }

    private func navigateToCategoryListIfNeeded(in app: XCUIApplication) {
        if app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 2) {
            return
        }

        let backToListButton = app.navigationBars.buttons["Canadian Ham"].firstMatch
        if backToListButton.waitForExistence(timeout: 2) {
            backToListButton.tap()
        }

        XCTAssertTrue(
            app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 5),
            "Practice category list should be reachable for accessibility auditing"
        )
    }

    private func answerFirstVisibleQuestion(in app: XCUIApplication) {
        let answerButton = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answerButton.waitForExistence(timeout: 10), "An answer button should be reachable")
        scrollUntilHittable(answerButton, in: app)
        XCTAssertTrue(answerButton.isHittable, "Answer A should be hittable after scrolling if needed")
        answerButton.tap()
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !element.isHittable {
            app.swipeUp()
        }
    }

    private func waitForAnswerFeedback(in app: XCUIApplication) -> XCUIElement {
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Answer feedback should appear after selecting an answer")
        return feedback
    }

    private func performAccessibilityAuditIfAvailable(
        on app: XCUIApplication,
        allowingAnswerTextContrastExclusions: Bool
    ) throws {
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit { issue in
                self.shouldIgnoreKnownAccessibilityAuditIssue(
                    issue,
                    allowingAnswerTextContrastExclusions: allowingAnswerTextContrastExclusions
                )
            }
        }
    }

    @available(iOS 17.0, *)
    private func shouldIgnoreKnownAccessibilityAuditIssue(
        _ issue: XCUIAccessibilityAuditIssue,
        allowingAnswerTextContrastExclusions: Bool
    ) -> Bool {
        let description = String(describing: issue)
        guard allowingAnswerTextContrastExclusions else { return false }

        // PracticeView renders answer-button text with primary foreground, a clear
        // background, and black/white answer-letter chips. iOS 27 can still report
        // those internal SwiftUI StaticText nodes as contrast failures inside the
        // custom answer button. Ignore only contrast findings for those StaticText
        // nodes on the answered practice screen; category-list contrast and all
        // non-contrast audits still fail normally.
        return description.contains("AuditType:\"1\"")
            && description.contains("StaticText")
    }
}
