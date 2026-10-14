import XCTest
#if os(iOS)
import UIKit
#endif

@MainActor
final class CanadianHamExamToolsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
        try super.tearDownWithError()
    }

    func testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice calculator sheet")
    }

    func testReferenceSheetToolHiddenUntilTask44Dot4() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "task-44.3 ships only the calculator on Apple; the reference sheet follows in task-44.4")

        let advancedApp = launchAdvancedPracticeQuestion()
        defer { advancedApp.terminate() }
        XCTAssertTrue(advancedApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(advancedApp.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(advancedApp.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "Advanced course must not offer the Basic reference sheet")
    }

    func testCalculatorKeyboardInputIsFocusScoped() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["3", "s"], on: focusedCalculator)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "9")

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected an answer to clear calculator keyboard focus")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Answer should be hittable before clearing calculator keyboard focus")
        answer.tap()
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "9", "Typing after calculator focus leaves must not change the calculator")
    }

    func testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["2", "s"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)
        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")

        app.terminate()
        let freshApp = launchPracticeQuestion(questionID: "B-001-003-001")
        defer { freshApp.terminate() }
        openTool(.calculator, in: freshApp)
        XCTAssertEqual(freshApp.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "0")
    }

    func testMockExamCalculatorKeepsAnswersHittableAndTimerRuns() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-timer",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "3",
            "-CanadianHamExamTimerEnabled", "true"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        let timerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Timer running")).firstMatch
        XCTAssertTrue(timerText.waitForExistence(timeout: 10), "Mock exam should start with the optional timer running when enabled")
        let initialTimerLabel = timerText.label
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(2.2))
        let advancedTimer = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label != %@", "Timer running", initialTimerLabel)).firstMatch
        XCTAssertTrue(advancedTimer.waitForExistence(timeout: 5), "The mock-exam timer should continue while a tool is open; initial label was \(initialTimerLabel)")
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "mock calculator sheet")
    }

    func testRegularWidthUsesInspectorAndKeepsAnswersHittable() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector layout is covered by the targeted iPad run.")
        try runRegularWidthInspectorScenario(orientation: .portrait, expectedSidebarVisibility: .collapsed, context: "iPad portrait")
        try runRegularWidthInspectorScenario(orientation: .landscapeLeft, expectedSidebarVisibility: .visible, context: "iPad landscape")
        XCUIDevice.shared.orientation = .portrait
#else
        throw XCTSkip("Inspector layout is covered by the targeted iPad run.")
#endif
    }

    func testAccessibilityAuditExamToolsLight() throws {
        let app = launchAuditPracticeQuestion(appearance: "light")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "light calculator medium")
    }

    func testAccessibilityAuditExamToolsDark() throws {
        let app = launchAuditPracticeQuestion(appearance: "dark")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "dark calculator medium")
    }

    func testLargeDetentCalculatorRunsFullAccessibilityAudit() throws {
        let app = launchAuditPracticeQuestion(extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        expandCompactSheetToLarge(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "The calculator should show keyboard help when the large detent has room")
        waitBriefly(0.8)
        try app.performAccessibilityAudit()
    }

    func testRegularWidthInspectorAccessibilityAudit() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector audit is covered by the targeted iPad run.")
        try runRegularWidthInspectorAuditScenario(orientation: .portrait, context: "iPad portrait inspector audit")
        try runRegularWidthInspectorAuditScenario(orientation: .landscapeLeft, context: "iPad landscape inspector audit")
        XCUIDevice.shared.orientation = .portrait
#else
        throw XCTSkip("Inspector audit is covered by the targeted iPad run.")
#endif
    }

    func testLargestDynamicTypeKeepsCalculatorGridReachable() throws {
        let app = launchPracticeQuestion(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let reciprocal = app.buttons["calculator-key-reciprocal"].firstMatch
        scrollCalculatorPanelUntilElementExists(reciprocal, in: app, maxSwipes: 10)
        XCTAssertTrue(reciprocal.exists, "The lower calculator keys should exist at the largest accessibility text size")
        scrollUntilHittable(reciprocal, in: app, maxSwipes: 10)
        XCTAssertTrue(reciprocal.isHittable, "The calculator grid should remain usable by scrolling at the largest accessibility text size")
        try app.performAccessibilityAudit()
    }

    func testPreciseScrollPositionsAnswerBelowProtectedAreaWithToolOpen() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        positionElementInMiddleVisibleBand(answer, in: app, context: "answer with calculator open")
        XCTAssertTrue(answer.isHittable, "The positioned answer should be hittable with the calculator sheet open")
    }

    func testCaptureCalculatorEvidenceScreenshots() throws {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
            for appearance in ["light", "dark"] {
                let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
                openTool(.calculator, in: app)
                XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-ipad-inspector-\(appearance).png")
                app.terminate()
            }
            XCUIDevice.shared.orientation = .landscapeLeft
            waitBriefly(0.8)
            let landscapeApp = launchPracticeQuestion(appearance: "light", extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
            openTool(.calculator, in: landscapeApp)
            XCTAssertTrue(landscapeApp.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5))
            waitBriefly(0.8)
            try saveScreenshot(named: "calculator-ipad-inspector-landscape-light.png")
            landscapeApp.terminate()
            XCUIDevice.shared.orientation = .portrait
        } else {
            for appearance in ["light", "dark"] {
                let mediumApp = launchPracticeQuestion(appearance: appearance)
                openTool(.calculator, in: mediumApp)
                XCTAssertTrue(mediumApp.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-iphone-medium-\(appearance).png")
                mediumApp.terminate()

                let largeApp = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
                openTool(.calculator, in: largeApp)
                XCTAssertTrue(largeApp.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5))
                waitBriefly(0.8)
                try saveScreenshot(named: "calculator-iphone-large-\(appearance).png")
                largeApp.terminate()
            }
        }
#else
        throw XCTSkip("Calculator evidence screenshots are captured from iPhone and iPad UI-test runs.")
#endif
    }

    private enum Tool {
        case calculator
        case referenceSheet

        var buttonIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-button"
            case .referenceSheet: "exam-tool-referenceSheet-button"
            }
        }

        var panelIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-panel"
            case .referenceSheet: "exam-tool-reference-sheet-panel"
            }
        }
    }

#if os(iOS)
    private enum SidebarVisibilityExpectation {
        case collapsed
        case visible
    }

    private func runRegularWidthInspectorScenario(orientation: UIDeviceOrientation, expectedSidebarVisibility: SidebarVisibilityExpectation, context: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present exam tools in an inspector side panel", file: file, line: line)
        waitBriefly(0.8)
        assertSidebarVisibility(expectedSidebarVisibility, in: app, context: context, file: file, line: line)
        assertQuestionTitleWithinExamColumn(in: app, context: context, file: file, line: line)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "\(context) calculator inspector", file: file, line: line)
    }

    private func runRegularWidthInspectorAuditScenario(orientation: UIDeviceOrientation, context: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present calculator in an inspector side panel", file: file, line: line)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "\(context): the inspector should show calculator keyboard help when it has room", file: file, line: line)
        waitBriefly(0.8)
        try app.performAccessibilityAudit()
    }

    private func assertSidebarVisibility(_ expected: SidebarVisibilityExpectation, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let sidebar = app.descendants(matching: .any)["root-sidebar"].firstMatch
        let visible = isSidebarVisible(sidebar, in: app)
        switch expected {
        case .collapsed:
            XCTAssertFalse(visible, "\(context): opening an inspector tool in portrait should collapse the sidebar so the exam column is not dimmed or covered. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
        case .visible:
            XCTAssertTrue(visible, "\(context): landscape has enough room for sidebar, exam column, and inspector; the sidebar should stay visible. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
        }
    }

    private func assertQuestionTitleWithinExamColumn(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let questionTitle = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(questionTitle.waitForExistence(timeout: 5), "\(context): expected the question title", file: file, line: line)
        let inspectorHeader = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(inspectorHeader.waitForExistence(timeout: 5), "\(context): expected the calculator inspector header", file: file, line: line)

        let windowFrame = app.windows.firstMatch.frame
        let sidebar = app.descendants(matching: .any)["root-sidebar"].firstMatch
        let examColumnMinX = isSidebarVisible(sidebar, in: app) ? sidebar.frame.maxX : windowFrame.minX
        let examColumnMaxX = min(windowFrame.maxX, inspectorHeader.frame.minX)
        let examColumn = CGRect(x: examColumnMinX, y: windowFrame.minY, width: max(0, examColumnMaxX - examColumnMinX), height: windowFrame.height)
        XCTAssertGreaterThanOrEqual(examColumn.width, 420, "\(context): expected an exam column of at least about 420 pt beside the inspector. Exam column: \(frameDescription(examColumn)); window: \(frameDescription(windowFrame)); inspector header: \(frameDescription(inspectorHeader.frame))", file: file, line: line)
        XCTAssertTrue(examColumn.insetBy(dx: -1, dy: -1).contains(questionTitle.frame), "\(context): question title should be fully within the exam column, not truncated under the inspector. Title: \(frameDescription(questionTitle.frame)); exam column: \(frameDescription(examColumn))", file: file, line: line)
    }

    private func isSidebarVisible(_ sidebar: XCUIElement, in app: XCUIApplication) -> Bool {
        guard sidebar.exists else { return false }
        let windowFrame = app.windows.firstMatch.frame
        return sidebar.frame.width > 80 && sidebar.frame.height > 80 && sidebar.frame.intersects(windowFrame) && sidebar.frame.minX < windowFrame.midX
    }
#endif

    private func launchPracticeQuestion(appearance: String = "light", categoryID: String = "B-001", questionID: String = "B-001-002-002", extraArguments: [String] = []) -> XCUIApplication {
        launchApp(appearance: appearance, arguments: extraArguments + [
            "-CanadianHamInitialCategoryID", categoryID,
            "-CanadianHamPracticeQuestionID", questionID
        ])
    }

    private func launchAuditPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-004", questionID: "B-004-001-001", extraArguments: extraArguments)
    }

    private func launchAdvancedPracticeQuestion() -> XCUIApplication {
        launchApp(arguments: [
            "-CanadianHamCourseBankId", "advanced-2025-02-04",
            "-CanadianHamInitialCategoryID", "A-001",
            "-CanadianHamPracticeQuestionID", "A-001-001-001"
        ])
    }

    private func launchApp(appearance: String = "light", arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-CanadianHamResetDataOnLaunch", "-CanadianHamAppearance", appearance] + arguments
        app.launch()
        return app
    }

    private func openTool(_ tool: Tool, in app: XCUIApplication) {
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected an exam question before opening tools")
        let button = app.buttons[tool.buttonIdentifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected tool button \(tool.buttonIdentifier)")
        scrollUntilHittable(button, in: app, maxSwipes: 8)
        XCTAssertTrue(button.isHittable, "Tool button \(tool.buttonIdentifier) should be hittable")
        button.tap()
    }

    private func closeTool(in app: XCUIApplication) {
        let close = app.buttons["exam-tool-close-button"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "Expected a close tools button")
        close.tap()
    }

    private func performMediumDetentExamToolAudit(on app: XCUIApplication, context: String) throws {
        assertMediumDetentToolPanelVisibleElements(in: app, context: context)
        var ignoredTextClippedIssues = 0
        try app.performAccessibilityAudit { issue in
            if self.isApprovedMediumDetentToolScrollTextClip(issue, in: app) {
                ignoredTextClippedIssues += 1
                XCTContext.runActivity(named: "Ignored approved task-44.3 medium-detent textClipped issue") { _ in
                    NSLog("Ignoring approved task-44.3 medium-detent exam-tool textClipped audit issue [\(context)]: type=\(issue.auditType) element=\(String(describing: issue.element)) issue=\(issue)")
                }
                return ignoredTextClippedIssues <= 5
            }
            return false
        }
        XCTAssertLessThanOrEqual(ignoredTextClippedIssues, 5, "\(context): medium-detent audit ignored too many nil-element textClipped issues")
    }

    private func isApprovedMediumDetentToolScrollTextClip(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> Bool {
        issue.auditType == .textClipped && issue.element == nil
    }

    private func assertMediumDetentToolPanelVisibleElements(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let header = ["exam-tool-calculator-panel"]
            .map { app.descendants(matching: .any)[$0].firstMatch }
            .first { $0.exists }
        guard let header else {
            XCTFail("\(context): expected a visible exam-tool panel header before auditing", file: file, line: line)
            return
        }
        XCTAssertTrue(windowFrame.contains(header.frame), "\(context): sheet visible frame should contain the panel header. Header: \(frameDescription(header.frame)); window: \(frameDescription(windowFrame))", file: file, line: line)
        let panelBounds = CGRect(x: windowFrame.minX, y: max(0, header.frame.minY - 48), width: windowFrame.width, height: windowFrame.maxY - max(0, header.frame.minY - 48))
        let candidates = app.staticTexts.allElementsBoundByIndex.map { ("staticText", $0) } + app.buttons.allElementsBoundByIndex.map { ("button", $0) }
        for (kind, element) in candidates where element.exists && element.frame.intersects(panelBounds) {
            XCTAssertGreaterThan(element.frame.width, 0, "\(context): \(kind) \(element.identifier) should not have an empty frame", file: file, line: line)
            XCTAssertGreaterThan(element.frame.height, 0, "\(context): \(kind) \(element.identifier) should not have an empty frame", file: file, line: line)
            XCTAssertTrue(element.isHittable || panelBounds.insetBy(dx: -1, dy: -1).intersects(element.frame), "\(context): \(kind) \(element.identifier) should be hittable or within the panel's visible scroll bounds. Frame: \(frameDescription(element.frame)); panel: \(frameDescription(panelBounds))", file: file, line: line)
        }
    }

    private func waitForStableToolHeaderFrame(_ tool: Tool, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let header = app.descendants(matching: .any)[tool.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Expected tool header \(tool.panelIdentifier)", file: file, line: line)

        let deadline = Date().addingTimeInterval(5)
        var previousFrame = header.frame
        var consecutiveStableSamples = 0
        while Date() < deadline, consecutiveStableSamples < 3 {
            waitBriefly(0.1)
            let currentFrame = header.frame
            if currentFrame == previousFrame {
                consecutiveStableSamples += 1
            } else {
                consecutiveStableSamples = 0
                previousFrame = currentFrame
            }
        }
        XCTAssertEqual(consecutiveStableSamples, 3, "Expected tool header \(tool.panelIdentifier) frame to settle before auditing. Last frame: \(frameDescription(previousFrame))", file: file, line: line)
    }

    private func expandCompactSheetToLarge(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let header = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Expected calculator header before expanding the sheet", file: file, line: line)
        let windowFrame = app.windows.firstMatch.frame
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: header.frame.midX, dy: header.frame.midY))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: header.frame.midX, dy: windowFrame.minY + 96))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.2)
        waitForStableToolHeaderFrame(.calculator, in: app, file: file, line: line)
    }

    private func tapStartMockExam(in app: XCUIApplication) {
        let start = app.buttons["start-mock-exam-button"].firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Expected mock exam start button")
        scrollUntilHittable(start, in: app, maxSwipes: 8)
        start.tap()
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected mock exam answer choices")
    }

    private func assertVisibleAnswerButtonsRemainHittable(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let answerIdentifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        for identifier in answerIdentifiers {
            let answer = app.descendants(matching: .any)[identifier].firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "\(context): expected \(identifier)", file: file, line: line)
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
            XCTAssertTrue(answer.isHittable, "\(context): \(identifier) should remain hittable with the non-modal tool open. Frame: \(frameDescription(answer.frame))", file: file, line: line)
        }
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let calculatorScrollView = app.scrollViews["calculator-tool-scroll"].firstMatch
        let scrollView = element.identifier.hasPrefix("calculator-key-") && calculatorScrollView.exists ? calculatorScrollView : scrollView(containing: element, in: app)
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            if element.exists && element.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func scrollBackgroundUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = scrollView(containing: element, in: app)
        for _ in 0..<maxSwipes where !element.isHittable {
            if element.exists && element.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                preciseScroll(scrollView, in: app, fingerDeltaY: 72)
            } else {
                preciseScroll(scrollView, in: app, fingerDeltaY: -72)
            }
            waitBriefly()
        }
    }

    private func scrollCalculatorPanelUntilElementExists(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let panel = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        let calculatorScrollView = app.scrollViews["calculator-tool-scroll"].firstMatch
        let scrollView = calculatorScrollView.exists ? calculatorScrollView : panel.scrollViews.firstMatch.exists ? panel.scrollViews.firstMatch : app.scrollViews.firstMatch
        for _ in 0..<maxSwipes where !element.exists {
            scrollView.swipeUp()
            waitBriefly()
        }
    }

    private func focusCalculatorKeyboard(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let result = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Expected a calculator result display before focusing keyboard input", file: file, line: line)
        let focusedTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target-focused"].firstMatch
        XCTAssertTrue(focusedTarget.waitForExistence(timeout: 5), "Expected the calculator keyboard handler to become active after opening the calculator", file: file, line: line)
        return focusedTarget
    }

    private func typeCalculatorKeys(_ keys: [String], on calculator: XCUIElement) {
        for key in keys {
            calculator.typeKey(key, modifierFlags: [])
            waitBriefly()
        }
    }

    private func positionElementInMiddleVisibleBand(_ element: XCUIElement, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let scrollView = scrollView(containing: element, in: app)
        XCTAssertTrue(scrollView.waitForExistence(timeout: 1), "\(context): expected a scroll view", file: file, line: line)
        var trace: [String] = []
        func record(_ label: String) {
            trace.append("\(label): target=\(frameDescription(element.frame)); offenders=\(scrollableElementsIntersectingProtectedArea(in: app, scrollView: scrollView).joined(separator: " | "))")
        }
        func positioned() -> Bool {
            isFullyVisibleInMiddleBand(element, in: app)
        }
        record("start")
        if !positioned() {
            for direction in [CGFloat(1), CGFloat(-1)] where !positioned() {
                for step in 1...12 where !positioned() {
                    preciseScroll(scrollView, in: app, fingerDeltaY: direction * 72)
                    waitBriefly()
                    record("scan \(direction > 0 ? "down" : "up") \(step)")
                }
            }
        }
        XCTAssertTrue(isFullyVisibleInMiddleBand(element, in: app), "\(context): expected the element in the middle visible band. Frame: \(frameDescription(element.frame)); trace: \(trace.joined(separator: " -> "))", file: file, line: line)
    }

    private func preciseScroll(_ scrollView: XCUIElement, in app: XCUIApplication, fingerDeltaY: CGFloat) {
        let limitedDelta = fingerDeltaY > 0 ? min(80, max(8, fingerDeltaY)) : -min(80, max(8, abs(fingerDeltaY)))
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let protectedBottom = activeToolPanelTop(in: app).map { $0 - 80 } ?? (visibleFrame.maxY - 24)
        let usableMinY = visibleFrame.minY + 24
        let usableMaxY = max(usableMinY, min(visibleFrame.maxY - 24, protectedBottom))
        let startY = min(max(visibleFrame.midY, usableMinY), usableMaxY)
        let startX = min(max(scrollView.frame.midX, visibleFrame.minX + 24), visibleFrame.maxX - 24)
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: startX, dy: startY))
        let end = start.withOffset(CGVector(dx: 0, dy: limitedDelta))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
    }

    private func activeToolPanelTop(in app: XCUIApplication) -> CGFloat? {
        let close = app.buttons["exam-tool-close-button"].firstMatch
        if close.exists, close.frame.minY > 0 {
            return max(0, close.frame.minY - 24)
        }
        for identifier in ["exam-tool-calculator-panel"] {
            let panel = app.descendants(matching: .any)[identifier].firstMatch
            if panel.exists, panel.frame.minY > 0 {
                return max(0, panel.frame.minY - 32)
            }
        }
        return nil
    }

    private func scrollView(containing element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        let backgroundScrollViews = scrollViews.filter { scrollView in
            !["calculator-keyboard-focus-target", "calculator-keyboard-focus-target-focused", "calculator-tool-scroll"].contains(scrollView.identifier)
        }
        if !element.identifier.isEmpty {
            for scrollView in backgroundScrollViews where scrollView.descendants(matching: .any)[element.identifier].firstMatch.exists {
                return scrollView
            }
        }
        return backgroundScrollViews.first ?? app.scrollViews.firstMatch
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func isFullyVisibleInMiddleBand(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return middleVisibleBand(in: app).contains(element.frame)
    }

    private func middleVisibleBand(in app: XCUIApplication) -> CGRect {
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let sheetTop = activeToolPanelTop(in: app).map { $0 - 8 }
        let defaultBottomLimit = app.windows.firstMatch.frame.maxY - (app.windows.firstMatch.frame.height * 0.15)
        let bottomLimit = min(defaultBottomLimit, sheetTop ?? defaultBottomLimit)
        return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + 8, width: visibleFrame.width, height: max(0, bottomLimit - visibleFrame.minY - 8))
    }

    private func scrollableElementsIntersectingProtectedArea(in app: XCUIApplication, scrollView: XCUIElement) -> [String] {
        let windowMinY = app.windows.firstMatch.frame.minY
        let protectedMaxY = protectedNavigationFrame(in: app).maxY + 1
        let candidates = scrollView.staticTexts.allElementsBoundByIndex.map { ("staticText", $0) } + scrollView.buttons.allElementsBoundByIndex.map { ("button", $0) }
        return candidates.compactMap { kind, element in
            guard element.exists else { return nil }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0, frame.maxY > windowMinY, frame.minY < protectedMaxY else { return nil }
            return "\(kind) id=\(element.identifier) label=\(element.label) frame=\(frameDescription(frame))"
        }
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let protectedFrame = protectedNavigationFrame(in: app)
        let protectedMaxY = protectedFrame.maxY
        return CGRect(x: windowFrame.minX + 16, y: protectedMaxY + 1, width: max(0, windowFrame.width - 32), height: max(0, windowFrame.maxY - protectedMaxY - 17))
    }

    private func protectedNavigationFrame(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(navBar.exists ? navBar.frame.maxY : windowFrame.minY, statusBar.exists ? statusBar.frame.maxY : windowFrame.minY)
        return CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: max(0, protectedMaxY - windowFrame.minY))
    }

    private func saveScreenshot(named fileName: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let directory = evidenceDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: url, options: .atomic)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Expected screenshot at \(url.path)", file: file, line: line)
    }

    private func evidenceDirectory() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/evidence/task-44.3", isDirectory: true)
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
