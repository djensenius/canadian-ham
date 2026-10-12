import UIKit
import XCTest

@MainActor
final class CanadianHamExamToolsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
        XCUIDevice.shared.appearance = .light
        try super.tearDownWithError()
    }

    func testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice calculator sheet")
    }

    func testPracticeReferenceSheetSheetKeepsAnswersHittableWithUnavailableFallback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.referenceSheet, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-scroll"].firstMatch.waitForExistence(timeout: 5), "The app should render the bundled Basic reference sheet when content/reference-sheet/basic.md is present")
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice reference sheet")
    }

    func testMockExamCalculatorKeepsAnswersHittableAndTimerRuns() throws {
        XCUIDevice.shared.appearance = .light
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
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector layout is covered by the targeted iPad run.")
        XCUIDevice.shared.appearance = .light
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
        XCUIDevice.shared.appearance = .light
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        try app.performAccessibilityAudit()
        closeTool(in: app)
        openTool(.referenceSheet, in: app)
        try app.performAccessibilityAudit()
    }

    func testAccessibilityAuditExamToolsDark() throws {
        XCUIDevice.shared.appearance = .dark
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        try app.performAccessibilityAudit()
        closeTool(in: app)
        openTool(.referenceSheet, in: app)
        try app.performAccessibilityAudit()
    }

    func testLargestDynamicTypeKeepsCalculatorGridReachable() throws {
        XCUIDevice.shared.appearance = .light
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
        XCUIDevice.shared.appearance = .light
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
    }

    private func launchPracticeQuestion(extraArguments: [String] = []) -> XCUIApplication {
        launchApp(arguments: extraArguments + [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002"
        ])
    }

    private func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-CanadianHamResetDataOnLaunch"] + arguments
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
        let scrollView = scrollView(containing: element, in: app)
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
        for _ in 0..<maxSwipes where !element.isHittable {
            if element.exists && element.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                preciseBackgroundScroll(in: app, fingerDeltaY: 72)
            } else {
                preciseBackgroundScroll(in: app, fingerDeltaY: -72)
            }
            waitBriefly()
        }
    }

    private func scrollCalculatorPanelUntilElementExists(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let panel = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        let scrollView = panel.scrollViews.firstMatch.exists ? panel.scrollViews.firstMatch : app.scrollViews.firstMatch
        for _ in 0..<maxSwipes where !element.exists {
            scrollView.swipeUp()
            waitBriefly()
        }
    }

    private func positionElementInMiddleVisibleBand(_ element: XCUIElement, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let scrollView = scrollView(containing: element, in: app)
        XCTAssertTrue(scrollView.waitForExistence(timeout: 1), "\(context): expected a scroll view", file: file, line: line)
        for _ in 0..<12 where !isFullyVisibleInMiddleBand(element, in: app) || !scrollableElementsIntersectingProtectedArea(in: app, scrollView: scrollView).isEmpty {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            let delta: CGFloat = element.frame.midY > visibleFrame.midY ? -72 : 72
            preciseBackgroundScroll(in: app, fingerDeltaY: delta)
            waitBriefly()
        }
        XCTAssertTrue(isFullyVisibleInMiddleBand(element, in: app), "\(context): expected the element in the middle visible band. Frame: \(frameDescription(element.frame))", file: file, line: line)
        let offenders = scrollableElementsIntersectingProtectedArea(in: app, scrollView: scrollView)
        XCTAssertTrue(offenders.isEmpty, "\(context): no scrollable text or buttons should intersect the protected navigation/status area; offenders: \(offenders.joined(separator: "; "))", file: file, line: line)
    }

    private func preciseScroll(_ scrollView: XCUIElement, contentDeltaY: CGFloat) {
        let limitedMagnitude = min(80, max(8, abs(contentDeltaY)))
        let fingerDeltaY = contentDeltaY > 0 ? limitedMagnitude : -limitedMagnitude
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = start.withOffset(CGVector(dx: 0, dy: fingerDeltaY))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
    }

    private func preciseBackgroundScroll(in app: XCUIApplication, fingerDeltaY: CGFloat) {
        let window = app.windows.firstMatch
        let limitedDelta = fingerDeltaY > 0 ? min(80, max(8, fingerDeltaY)) : -min(80, max(8, abs(fingerDeltaY)))
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        let end = start.withOffset(CGVector(dx: 0, dy: limitedDelta))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
    }

    private func scrollView(containing element: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        let scrollViews = app.scrollViews.allElementsBoundByIndex
        if !element.identifier.isEmpty {
            for scrollView in scrollViews where scrollView.descendants(matching: .any)[element.identifier].firstMatch.exists {
                return scrollView
            }
        }
        return app.scrollViews.firstMatch
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func isFullyVisibleInMiddleBand(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let bottomLimit = app.windows.firstMatch.frame.maxY - (app.windows.firstMatch.frame.height * 0.15)
        let band = CGRect(x: visibleFrame.minX, y: visibleFrame.minY + 8, width: visibleFrame.width, height: max(0, bottomLimit - visibleFrame.minY - 8))
        return band.contains(element.frame)
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
