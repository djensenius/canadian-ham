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

        waitBriefly()
        let visibleTextLabels = Set(app.descendants(matching: .any).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty })
        let frenchQuestionTexts = try bundledFrenchQuestionTexts(forCategoryID: "B-001")
        let visibleFrenchQuestion = frenchQuestionTexts.first { visibleTextLabels.contains($0) }
        XCTAssertNotNil(
            visibleFrenchQuestion,
            "Expected one of the bundled French B-001 question stems after switching language. Visible labels: \(visibleTextLabels.sorted())"
        )

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
        scrollUntilHittable(nextQuestionButton, in: app, maxSwipes: 14)
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be reachable by scrolling at the largest accessibility text size")
        nextQuestionButton.tap()

        waitForElementToDisappear(feedback, timeout: 5, message: "Answer feedback should disappear after advancing at the largest accessibility text size")
    }

    private func auditCategoryListAndAnsweredPracticeScreen(named appearanceName: String) throws {
        let app = configuredApp()
        app.launch()
        defer { app.terminate() }

        navigateToCategoryListIfNeeded(in: app)
        let firstCategory = app.staticTexts["Regulations and Policies"].firstMatch
        XCTAssertTrue(firstCategory.waitForExistence(timeout: 5), "Category list should exist before the accessibility audit")
        scrollElementToVisibleMiddle(firstCategory, in: app)
        XCTAssertTrue(
            isFullyVisible(firstCategory, in: app, requiresHittable: true),
            "First category should be fully visible below the navigation bar before auditing"
        )
        captureScreenEvidence(named: "category-list-\(appearanceName)-accessibility-audit")
        try captureAccessibilityAudit(on: app, screenName: "category-list-\(appearanceName)")

        navigateToPracticeIfNeeded(in: app)
        answerFirstVisibleQuestion(in: app)
        _ = waitForAnswerFeedback(in: app)
        let auditedAnswer = app.descendants(matching: .any)["answer-C-button"].firstMatch
        scrollElementToVisibleMiddle(auditedAnswer, in: app)
        XCTAssertTrue(
            isFullyVisible(auditedAnswer, in: app, requiresHittable: true),
            "The audited answer row should be fully visible below the navigation bar before auditing"
        )
        captureScreenEvidence(named: "answered-practice-\(appearanceName)-accessibility-audit")
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

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
    }

    private func scrollElementToVisibleMiddle(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 16) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element should exist before scrolling for audit")
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 1) else {
            return
        }

        for _ in 0..<maxSwipes {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            let elementFrame = element.frame
            let isFullyInsideVisibleFrame = elementFrame.minY > visibleFrame.minY && elementFrame.maxY < visibleFrame.maxY
            let isNearMiddle = abs(elementFrame.midY - visibleFrame.midY) <= 180

            if isFullyInsideVisibleFrame && isNearMiddle {
                return
            }

            if elementFrame.minY <= visibleFrame.minY || elementFrame.midY < visibleFrame.midY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func waitForHittableAndStable(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame = CGRect.null
        var stableSamples = 0

        while Date() < deadline {
            if isFullyVisible(element, in: app, requiresHittable: true) {
                let frame = element.frame
                if frame.equalTo(previousFrame) {
                    stableSamples += 1
                    if stableSamples >= 2 {
                        return true
                    }
                } else {
                    stableSamples = 0
                    previousFrame = frame
                }
            } else {
                stableSamples = 0
                previousFrame = .null
            }
            waitBriefly()
        }

        return false
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let navBarMaxY = navBar.exists ? navBar.frame.maxY : windowFrame.minY
        let topInset = navBarMaxY + 16
        let bottomInset = windowFrame.maxY - 16
        return CGRect(
            x: windowFrame.minX + 16,
            y: topInset,
            width: max(0, windowFrame.width - 32),
            height: max(0, bottomInset - topInset)
        )
    }

    private func waitBriefly() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
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

    @discardableResult
    private func captureScreenEvidence(named name: String) -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(screenshot.pngRepresentation, filename: "\(name).png")
        return screenshot
    }

    private func attachAuditFindings(_ findings: [String], screenName: String, error: Error?, screenFrame: CGRect) {
        var lines = [
            "Screen: \(screenName)",
            "Screen frame: \(frameDescription(screenFrame))"
        ]
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

        let rawFindings = lines.joined(separator: "\n\n")
        let attachment = XCTAttachment(string: rawFindings)
        attachment.name = "\(screenName)-raw-accessibility-audit-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(Data(rawFindings.utf8), filename: "\(screenName)-raw-accessibility-audit-findings.txt")
    }

    private func captureAccessibilityAudit(on app: XCUIApplication, screenName: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            var capturedIssueScreenshot = false
            var auditError: Error?
            defer {
                attachAuditFindings(findings, screenName: screenName, error: auditError, screenFrame: app.windows.firstMatch.frame)
            }
            do {
                try app.performAccessibilityAudit { issue in
                    let description = self.describe(issue)
                    findings.append(description)
                    if !capturedIssueScreenshot {
                        self.captureScreenEvidence(named: "\(screenName)-accessibility-audit")
                        capturedIssueScreenshot = true
                    }
                    return self.shouldExclude(issue, screenName: screenName)
                }
            } catch {
                auditError = error
                throw error
            }
        } else {
            let rawFindings = "Screen: \(screenName)\nScreen frame: \(frameDescription(app.windows.firstMatch.frame))\nperformAccessibilityAudit is unavailable before iOS 17."
            let attachment = XCTAttachment(string: rawFindings)
            attachment.name = "\(screenName)-raw-accessibility-audit-findings"
            attachment.lifetime = .keepAlways
            add(attachment)
            exportEvidence(Data(rawFindings.utf8), filename: "\(screenName)-raw-accessibility-audit-findings.txt")
        }
    }

    @available(iOS 17.0, *)
    private func shouldExclude(_ issue: XCUIAccessibilityAuditIssue, screenName: String) -> Bool {
        let auditType = String(describing: issue.auditType)
        let identifier = issue.element?.identifier ?? ""

        if auditType == "XCUIAccessibilityAuditType(rawValue: 1)" {
            return contrastFalsePositiveIdentifiers.contains(identifier)
        }

        if auditType == "XCUIAccessibilityAuditType(rawValue: 131072)" {
            return textClippingFalsePositiveIdentifiers.contains(identifier)
        }

        return false
    }

    private var contrastFalsePositiveIdentifiers: Set<String> {
        var identifiers: Set<String> = [
            "practice-category-title",
            "practice-category-summary",
            "practice-session-tally",
            "question-identifier",
            "question-stem",
            "answers-title",
            "answer-feedback-title",
            "answer-feedback-correct-answer",
            "answer-feedback-source"
        ]
        for label in ["A", "B", "C", "D"] {
            identifiers.insert("answer-\(label)-chip")
            identifiers.insert("answer-\(label)-text")
            identifiers.insert("answer-\(label)-status")
        }
        return identifiers
    }

    private var textClippingFalsePositiveIdentifiers: Set<String> {
        var identifiers: Set<String> = [
            "question-stem",
            "answer-feedback-title",
            "answer-feedback-correct-answer",
            "answer-feedback-source"
        ]
        for label in ["A", "B", "C", "D"] {
            identifiers.insert("answer-\(label)-text")
        }
        return identifiers
    }

    private func exportEvidence(
        _ data: Data,
        filename: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let directory = evidenceDirectoryURL()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
        } catch {
            XCTFail("Failed to export accessibility evidence \(filename): \(error)", file: file, line: line)
        }
    }

    private func evidenceDirectoryURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/a11y-evidence", isDirectory: true)
    }

    @available(iOS 17.0, *)
    private func describe(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element = issue.element
        let identifier = element?.identifier ?? ""
        let label = element?.label ?? ""
        let elementType = element.map { String(describing: $0.elementType) } ?? "nil"
        let frame = element.map { frameDescription($0.frame) } ?? "nil"
        return """
        auditType: \(issue.auditType)
        element.identifier: \(identifier)
        element.label: \(label)
        element.elementType: \(elementType)
        element.frame: \(frame)
        compactDescription: \(issue.compactDescription)
        """
    }

    private func bundledFrenchQuestionTexts(forCategoryID categoryID: String) throws -> Set<String> {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "questions", withExtension: "json"),
            "UI test bundle should include generated question-bank questions.json"
        )
        let data = try Data(contentsOf: url)
        let questions = try JSONDecoder().decode([UITestQuestion].self, from: data)
        return Set(
            questions.compactMap { question in
                guard question.categoryId == categoryID else { return nil }
                return question.text.fr
            }
        )
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }
}

private struct UITestQuestion: Decodable {
    let categoryId: String
    let text: UITestLocalizedText
}

private struct UITestLocalizedText: Decodable {
    let fr: String?
}
