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

    func testPracticeReferenceSheetKeepsAnswersHittableWithBundledSheet() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.referenceSheet, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-scroll"].firstMatch.waitForExistence(timeout: 5), "The app should render the bundled Basic reference sheet when content/reference-sheet/basic.md is present")
        XCTAssertTrue(app.buttons["reference-sheet-show-full-sheet"].firstMatch.waitForExistence(timeout: 5), "The medium sheet should provide a visible Show full sheet action")
        assertReferenceSheetTextIsVisible(in: app)
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice reference sheet")
    }

    func testReferenceSheetUnavailableStateAudits() throws {
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamReferenceSheetResourceName", "missing-reference-sheet"])
        defer { app.terminate() }

        openTool(.referenceSheet, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-unavailable"].firstMatch.waitForExistence(timeout: 5))
        waitForStableToolHeaderFrame(.referenceSheet, in: app)
        try app.performAccessibilityAudit()
    }

    func testAdvancedPracticeDoesNotOfferBasicReferenceSheet() throws {
        let app = launchAdvancedPracticeQuestion()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "Advanced course must not offer the Basic reference sheet")
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
        XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-focus-target-focused"].firstMatch.waitForNonExistence(timeout: 2), "Calculator keyboard input should be scoped to the calculator focus binding")
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "9", "Typing after calculator focus leaves must not change the calculator")
    }

    func testCalculatorValueSurvivesToolSwitchAndResetsForNewSession() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["2", "s"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)
        openTool(.referenceSheet, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-scroll"].firstMatch.waitForExistence(timeout: 5))
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
#else
        throw XCTSkip("Inspector layout is covered by the targeted iPad run.")
#endif
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "Regular width should present exam tools in an inspector side panel")
        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        scrollUntilHittable(answer, in: app, maxSwipes: 8)
        XCTAssertTrue(answer.isHittable, "Answer buttons should remain operable beside the inspector")
    }

    func testAccessibilityAuditExamToolsLight() throws {
        let app = launchAuditPracticeQuestion(appearance: "light")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "light calculator medium")
        closeTool(in: app)
        openTool(.referenceSheet, in: app)
        waitForStableToolHeaderFrame(.referenceSheet, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "light reference sheet medium")
    }

    func testAccessibilityAuditExamToolsDark() throws {
        let app = launchAuditPracticeQuestion(appearance: "dark")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "dark calculator medium")
        closeTool(in: app)
        openTool(.referenceSheet, in: app)
        waitForStableToolHeaderFrame(.referenceSheet, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "dark reference sheet medium")
    }

    func testLargeDetentReferenceSheetRunsFullAccessibilityAudit() throws {
        let app = launchAuditPracticeQuestion()
        defer { app.terminate() }

        openTool(.referenceSheet, in: app)
        let showFullSheet = app.buttons["reference-sheet-show-full-sheet"].firstMatch
        XCTAssertTrue(showFullSheet.waitForExistence(timeout: 5), "Medium detent should expose the Show full sheet button")
        showFullSheet.tap()
        assertReferenceSheetTextIsVisible(in: app)
        waitBriefly(0.8)
        try app.performAccessibilityAudit()
    }

    func testRegularWidthInspectorAccessibilityAudit() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector audit is covered by the targeted iPad run.")
#else
        throw XCTSkip("Inspector audit is covered by the targeted iPad run.")
#endif
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "Regular width should present calculator in an inspector side panel")
        try app.performAccessibilityAudit()
        closeTool(in: app)

        openTool(.referenceSheet, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-reference-sheet-panel"].firstMatch.waitForExistence(timeout: 5), "Regular width should present reference sheet in an inspector side panel")
        assertReferenceSheetTextIsVisible(in: app)
        try app.performAccessibilityAudit()
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

    private func assertReferenceSheetTextIsVisible(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let ohmsLaw = app.staticTexts["Ohm's law"].firstMatch
        XCTAssertTrue(ohmsLaw.waitForExistence(timeout: 5), "Expected real reference-sheet text to be rendered", file: file, line: line)
        XCTAssertTrue(app.windows.firstMatch.frame.intersects(ohmsLaw.frame), "Reference-sheet text should be visible on screen. Frame: \(frameDescription(ohmsLaw.frame))", file: file, line: line)
    }

    private func performMediumDetentExamToolAudit(on app: XCUIApplication, context: String) throws {
        try app.performAccessibilityAudit { issue in
            if self.isApprovedMediumDetentToolScrollTextClip(issue, in: app) {
                NSLog("Ignoring approved task-44.3 medium-detent exam-tool textClipped audit issue [\(context)]: \(issue)")
                return true
            }
            return false
        }
    }

    private func isApprovedMediumDetentToolScrollTextClip(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> Bool {
        guard issue.auditType == .textClipped else { return false }
        guard let element = issue.element else { return false }
        let elementFrame = element.frame
        guard elementFrame.width > 0, elementFrame.height > 0 else { return false }
        for identifier in ["reference-sheet-scroll", "calculator-tool-scroll"] {
            let scrollView = app.scrollViews[identifier].firstMatch
            if scrollView.exists, scrollView.frame.insetBy(dx: -1, dy: -1).intersects(elementFrame) {
                return true
            }
        }
        return false
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
        let focusTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target"].firstMatch
        XCTAssertTrue(focusTarget.waitForExistence(timeout: 5), "Expected a calculator keyboard focus target", file: file, line: line)
        let result = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Expected a calculator result display before focusing keyboard input", file: file, line: line)
        result.tap()
        let focusedTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target-focused"].firstMatch
        XCTAssertTrue(focusedTarget.waitForExistence(timeout: 5), "Expected the calculator .focused binding to become active after tapping the calculator", file: file, line: line)
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
            isFullyVisibleInMiddleBand(element, in: app) && scrollableElementsIntersectingProtectedArea(in: app, scrollView: scrollView).isEmpty
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
        let protectedAreaIntersections = scrollableElementsIntersectingProtectedArea(in: app, scrollView: scrollView)
        XCTAssertTrue(protectedAreaIntersections.isEmpty, "\(context): scrollable elements should not intersect the protected navigation/status area: \(protectedAreaIntersections.joined(separator: " | ")); trace: \(trace.joined(separator: " -> "))", file: file, line: line)
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
        for identifier in ["exam-tool-calculator-panel", "exam-tool-reference-sheet-panel"] {
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
            !["calculator-keyboard-focus-target", "calculator-keyboard-focus-target-focused", "calculator-tool-scroll", "reference-sheet-scroll"].contains(scrollView.identifier)
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

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
