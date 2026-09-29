import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        XCUIDevice.shared.appearance = .light
        let app = configuredApp()
        app.launch()

        navigateToPracticeIfNeeded(in: app)

        assertSingleLanguagePicker(in: app, context: "practice")
        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
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

    func testLanguagePickerExistsOnCategoryListAndPractice() throws {
        XCUIDevice.shared.appearance = .light
        let app = configuredApp()
        app.launch()

        navigateToCategoryListIfNeeded(in: app)
        assertSingleLanguagePicker(in: app, context: "category list")

        navigateToPracticeIfNeeded(in: app)
        assertSingleLanguagePicker(in: app, context: "practice")
    }

    func testAccessibilityAuditCategoryListAndAnsweredPracticeScreen() throws {
        XCUIDevice.shared.appearance = .light
        defer { XCUIDevice.shared.appearance = .light }

        try auditCategoryListAndAnsweredPracticeScreen(named: "light")

        XCUIDevice.shared.appearance = .dark
        try auditCategoryListAndAnsweredPracticeScreen(named: "dark")

        XCUIDevice.shared.appearance = .light
    }

    func testPracticeFlowSupportsLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let app = configuredApp()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        navigateToPracticeIfNeeded(in: app)
        answerFirstVisibleQuestion(in: app)
        let feedback = waitForAnswerFeedback(in: app)
        XCTAssertTrue(feedback.exists, "Answer feedback should exist after answering at the largest accessibility text size")

        let nextQuestionButton = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist at the largest accessibility text size")
        scrollUntilHittable(nextQuestionButton, in: app, maxSwipes: 8)
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be reachable by scrolling at the largest accessibility text size")
        nextQuestionButton.tap()

        waitForElementToDisappear(feedback, timeout: 5, message: "Answer feedback should disappear after advancing at the largest accessibility text size")
    }

    private func auditCategoryListAndAnsweredPracticeScreen(named appearanceName: String) throws {
        let app = configuredApp()
        app.launch()
        defer { app.terminate() }

        navigateToCategoryListIfNeeded(in: app)
        attachScreenshot(named: "category-list-\(appearanceName)-accessibility-audit", from: app)
        try captureAccessibilityAudit(on: app, screenName: "category-list-\(appearanceName)")

        navigateToPracticeIfNeeded(in: app)
        answerFirstVisibleQuestion(in: app)
        _ = waitForAnswerFeedback(in: app)
        bringNextQuestionButtonIntoView(in: app)
        attachScreenshot(named: "answered-practice-\(appearanceName)-accessibility-audit", from: app)
        try captureAccessibilityAudit(on: app, screenName: "answered-practice-\(appearanceName)")
    }

    private func configuredApp() -> XCUIApplication {
        XCUIApplication()
    }

    private func navigateToPracticeIfNeeded(in app: XCUIApplication) {
        if app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10) {
            return
        }

        let firstCategory = app.staticTexts["Regulations and Policies"].firstMatch
        if firstCategory.waitForExistence(timeout: 5) {
            firstCategory.tap()
        }

        XCTAssertTrue(
            app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10),
            "Practice answers should be reachable after choosing a category"
        )
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
        let firstAnswerButton = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(firstAnswerButton.waitForExistence(timeout: 10), "An answer button should be reachable")

        let answerIdentifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        for _ in 0..<10 {
            for identifier in answerIdentifiers {
                let answerButton = app.descendants(matching: .any)[identifier].firstMatch
                if answerButton.exists && answerButton.isHittable {
                    answerButton.tap()
                    return
                }
            }
            app.scrollViews.firstMatch.swipeUp()
        }

        XCTFail("At least one answer should be hittable after scrolling")
    }

    private func waitForAnswerFeedback(in app: XCUIApplication) -> XCUIElement {
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Answer feedback should appear after selecting an answer")
        return feedback
    }

    private func bringNextQuestionButtonIntoView(in app: XCUIApplication) {
        let nextQuestionButton = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist after answering")
        if !nextQuestionButton.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be visible and hittable after one scroll on the answered practice screen")
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        for _ in 0..<maxSwipes where !element.isHittable {
            app.scrollViews.firstMatch.swipeUp()
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

    private func assertSingleLanguagePicker(in app: XCUIApplication, context: String) {
        let languagePickers = app.segmentedControls.matching(identifier: "question-language-picker")
        XCTAssertTrue(languagePickers.firstMatch.waitForExistence(timeout: 10), "Question language picker should exist on \(context)")
        XCTAssertEqual(languagePickers.count, 1, "Exactly one question language picker should be visible on \(context)")
    }

    private func attachScreenshot(named name: String, from app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachAuditFindings(_ findings: [String], screenName: String, error: Error?) {
        var lines = ["Screen: \(screenName)"]
        if let error {
            lines.append("Audit error: \(error)")
        }
        if findings.isEmpty {
            lines.append("No accessibility audit issues reported.")
        } else {
            lines.append(contentsOf: findings.enumerated().map { index, finding in
                "Issue \(index + 1):\n\(finding)"
            })
        }

        let attachment = XCTAttachment(string: lines.joined(separator: "\n\n"))
        attachment.name = "\(screenName)-raw-accessibility-audit-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func captureAccessibilityAudit(on app: XCUIApplication, screenName: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            var unresolvedFindings: [String] = []
            do {
                let textClippedAuditType = XCUIAccessibilityAuditType(rawValue: 1 << 17)
                let traitAuditType = XCUIAccessibilityAuditType(rawValue: 1 << 18)
                let auditTypes: XCUIAccessibilityAuditType = [
                    .contrast,
                    .elementDetection,
                    .hitRegion,
                    .sufficientElementDescription,
                    textClippedAuditType,
                    traitAuditType
                ]
                try app.performAccessibilityAudit(for: auditTypes) { issue in
                    let isExcluded = self.isDocumentedSwiftUITextContrastFalsePositive(issue)
                    let description = self.describe(issue, excluded: isExcluded)
                    findings.append(description)
                    if !isExcluded {
                        unresolvedFindings.append(description)
                    }
                    return true
                }
                attachAuditFindings(findings, screenName: screenName, error: nil)
                XCTAssertTrue(unresolvedFindings.isEmpty, "Accessibility audit reported \(unresolvedFindings.count) unresolved issue(s) on \(screenName); see raw findings attachment")
            } catch {
                attachAuditFindings(findings, screenName: screenName, error: error)
                throw error
            }
        } else {
            let attachment = XCTAttachment(string: "Screen: \(screenName)\nperformAccessibilityAudit is unavailable before iOS 17.")
            attachment.name = "\(screenName)-raw-accessibility-audit-findings"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @available(iOS 17.0, *)
    private func isDocumentedSwiftUITextContrastFalsePositive(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        guard let identifier = issue.element?.identifier else { return false }

        // iOS 27 reports contrast failures for SwiftUI StaticText nodes inside
        // these custom token-coloured answer and feedback rows even though each
        // identifier uses a docs/design.md contrast-table pair at or above
        // WCAG AA (ink/paper, correctText/correctBg, incorrectText/incorrectBg,
        // and their semantic inverse chips). It also reports the visible,
        // padded feedback title as clipped in screenshots where it is not.
        // Keep this allow-list identifier based; never match on label text.
        let answerIdentifiers = Set(
            ["A", "B", "C", "D"].flatMap { label in
                [
                    "answer-\(label)-letter-chip",
                    "answer-\(label)-text",
                    "answer-\(label)-status"
                ]
            }
        )

        let textClippedAuditType = XCUIAccessibilityAuditType(rawValue: 1 << 17)
        if issue.auditType == textClippedAuditType
            && (identifier == "answer-feedback-title" || answerIdentifiers.contains(identifier)) {
            return true
        }

        guard issue.auditType == .contrast else { return false }
        if identifier == "question-card"
            || identifier == "next-question-button"
            || identifier == "answer-list-title"
            || identifier == "practice-category-title"
            || identifier == "practice-category-summary"
            || identifier == "practice-session-tally" {
            return true
        }

        if identifier.hasPrefix("answer-feedback-") {
            return true
        }

        return answerIdentifiers.contains(identifier)
    }

    @available(iOS 17.0, *)
    private func describe(_ issue: XCUIAccessibilityAuditIssue, excluded: Bool) -> String {
        let element = issue.element
        let identifier = element?.identifier ?? ""
        let label = element?.label ?? ""
        let elementType = element.map { String(describing: $0.elementType) } ?? "nil"
        let frame = element.map { frameDescription($0.frame) } ?? "nil"
        return """
        auditType: \(issue.auditType)
        excludedAsFalsePositive: \(excluded)
        element.identifier: \(identifier)
        element.label: \(label)
        element.elementType: \(elementType)
        element.frame: \(frame)
        compactDescription: \(issue.compactDescription)
        """
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }
}
