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

    func testCalculatorAutoFocusesHardwareKeyboardOnOpen() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        app.typeKey("7", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "7", "Opening the calculator should focus hardware-keyboard input without tapping inside the panel")
    }

    func testCalculatorKeyboardInputIsFocusScoped() throws {
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamPracticeMode", "review-later"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let keyTwo = app.buttons["calculator-key-2"].firstMatch
        XCTAssertTrue(keyTwo.waitForExistence(timeout: 5), "Expected the calculator 2 key")
        XCTAssertTrue(keyTwo.isHittable, "The calculator 2 key should be hittable before keyboard entry")
        keyTwo.tap()
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["3"], on: focusedCalculator)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "23", "Tapping a calculator key must not let the background focus resetter disable hardware-keyboard input")

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected an answer to clear calculator keyboard focus")
        positionElementFullyVisibleAboveToolSheet(answer, in: app, context: "answer A before clearing calculator keyboard focus")
        XCTAssertTrue(answer.isHittable, "Answer should be hittable before clearing calculator keyboard focus")
        answer.tap()
        waitBriefly(0.5)
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "23", "Typing after answer focus leaves must not change the calculator")

        let allClear = app.buttons["calculator-key-all-clear"].firstMatch
        XCTAssertTrue(allClear.waitForExistence(timeout: 5), "Expected the calculator all-clear key before refocusing")
        scrollExamToolUntilHittable(allClear, in: app, maxSwipes: 8)
        XCTAssertTrue(allClear.isHittable, "All-clear should be hittable before refocusing the calculator")
        allClear.tap()
        keyTwo.tap()
        typeCalculatorKeys(["4"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "24", "Calculator should accept hardware input again after tapping back into the calculator")

        let questionCard = app.descendants(matching: .any)["question-card"].firstMatch
        XCTAssertTrue(questionCard.waitForExistence(timeout: 5), "Expected the question card before tapping non-text exam content")
        scrollBackgroundUntilHittable(questionCard, in: app, maxSwipes: 12)
        questionCard.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
        waitBriefly(0.5)
        app.typeKey("1", modifierFlags: [])
        waitBriefly()
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "24", "Typing after tapping card padding must not change the calculator")
    }

    func testCalculatorValueSurvivesCloseAndReopenAndResetsForNewSession() throws {
        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamPracticeLimit", "1"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["2", "+", "2", "="], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)
        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "4")
        closeTool(in: app)

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected an answer to finish the one-question session")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected the answer to be hittable before finishing the session")
        answer.tap()
        let finish = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 5), "Expected the Finish session button")
        scrollExamToolUntilHittable(finish, in: app, maxSwipes: 12)
        XCTAssertTrue(finish.isHittable, "Expected the Finish session button to be hittable")
        finish.tap()

        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "0")
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

    func testCalculatorValueResetsForNewMockExam() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-mock-reset",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        let focusedCalculator = focusCalculatorKeyboard(in: app)
        typeCalculatorKeys(["7"], on: focusedCalculator)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "7")
        closeTool(in: app)

        let endExam = app.buttons["end-mock-exam-button"].firstMatch
        XCTAssertTrue(endExam.waitForExistence(timeout: 5), "Expected End exam button")
        scrollExamToolUntilHittable(endExam, in: app, maxSwipes: 12)
        XCTAssertTrue(endExam.isHittable, "Expected End exam to be hittable")
        endExam.tap()
        let alert = app.alerts["End mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Expected end-exam confirmation")
        alert.buttons["End exam"].tap()

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "0", "Starting a new mock exam should reset calculator state")
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
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The medium-detent audit exception is approved only for compact sheet presentation; iPad uses the inspector audit.")
#endif
        let app = launchAuditPracticeQuestion(appearance: "light")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "light calculator medium")
    }

    func testAccessibilityAuditExamToolsDark() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The medium-detent audit exception is approved only for compact sheet presentation; iPad uses the inspector audit.")
#endif
        let app = launchAuditPracticeQuestion(appearance: "dark")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        waitForStableToolHeaderFrame(.calculator, in: app)
        try performMediumDetentExamToolAudit(on: app, context: "dark calculator medium")
    }

    func testLargeDetentCalculatorRunsFullAccessibilityAuditLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchAuditPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            expandCompactSheetToLarge(in: app)
            XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "The calculator should show keyboard help when the large detent has room")
            waitBriefly(0.8)
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testRegularWidthInspectorAccessibilityAuditLightAndDark() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector audit is covered by the targeted iPad run.")
        for appearance in ["light", "dark"] {
            try runRegularWidthInspectorAuditScenario(orientation: .portrait, appearance: appearance, context: "iPad portrait inspector audit \(appearance)")
            try runRegularWidthInspectorAuditScenario(orientation: .landscapeLeft, appearance: appearance, context: "iPad landscape inspector audit \(appearance)")
        }
        XCUIDevice.shared.orientation = .portrait
#else
        throw XCTSkip("Inspector audit is covered by the targeted iPad run.")
#endif
    }

    func testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            let reciprocal = app.buttons["calculator-key-reciprocal"].firstMatch
            scrollCalculatorPanelUntilElementExists(reciprocal, in: app, maxSwipes: 10)
            XCTAssertTrue(reciprocal.exists, "The lower calculator keys should exist at the largest accessibility text size")
            scrollExamToolUntilHittable(reciprocal, in: app, maxSwipes: 10)
            XCTAssertTrue(reciprocal.isHittable, "The calculator grid should remain usable by scrolling at the largest accessibility text size")
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testPreciseScrollPositionsAnswerAboveToolSheet() throws {
        let app = launchPracticeQuestion(categoryID: "B-004", questionID: "B-004-001-001")
        defer { app.terminate() }

        openTool(.calculator, in: app)
        let answer = app.descendants(matching: .any)["answer-D-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5))
        positionElementFullyVisibleAboveToolSheet(answer, in: app, context: "answer D with calculator open")
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

        let initialSidebarVisible = isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app)
        XCTAssertTrue(initialSidebarVisible, "\(context): regular-width launch should start with the sidebar visible before opening the inspector", file: file, line: line)
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present exam tools in an inspector side panel", file: file, line: line)
        waitBriefly(0.8)
        assertSidebarVisibility(expectedSidebarVisibility, in: app, context: context, file: file, line: line)
        assertQuestionTitleWithinExamColumn(in: app, context: context, file: file, line: line)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "\(context) calculator inspector", file: file, line: line)
        closeTool(in: app)
        waitBriefly(0.8)
        XCTAssertEqual(isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app), initialSidebarVisible, "\(context): closing the inspector should restore the sidebar visibility that existed before opening it", file: file, line: line)
    }

    private func runRegularWidthInspectorAuditScenario(orientation: UIDeviceOrientation, appearance: String, context: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present calculator in an inspector side panel", file: file, line: line)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-keyboard-help"].firstMatch.waitForExistence(timeout: 5), "\(context): the inspector should show calculator keyboard help when it has room", file: file, line: line)
        waitBriefly(0.8)
        try auditIgnoringOccludedLessonTextContrast(app: app)
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
        launchPracticeQuestion(appearance: appearance, categoryID: "B-001", questionID: "B-001-002-002", extraArguments: extraArguments)
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
        scrollExamToolUntilHittable(button, in: app, maxSwipes: 8)
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

    private func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {
        let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            guard let element = issue.element else { return false }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0 else { return false }
            guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
            guard auditGeometry.scrollFrame.intersects(frame) else { return false }
            guard self.element(element, withFrame: frame, isDescendantOf: auditGeometry.scrollView) else { return false }
            guard !auditGeometry.visibleScrollArea.contains(frame) else { return false }

            XCTContext.runActivity(named: "Ignored occluded lesson scroll-content contrast false positive") { activity in
                let note = "label=\(element.label) frame=\(self.frameDescription(frame)) visibleScrollArea=\(self.frameDescription(auditGeometry.visibleScrollArea)) scrollFrame=\(self.frameDescription(auditGeometry.scrollFrame)) matchedScrollDescendant=true"
                let attachment = XCTAttachment(string: note)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return true
        }
    }

    private func isApprovedMediumDetentToolScrollTextClip(_ issue: XCUIAccessibilityAuditIssue, in app: XCUIApplication) -> Bool {
#if os(iOS)
        issue.auditType == .textClipped && issue.element == nil
#else
        false
#endif
    }

    private func assertMediumDetentToolPanelVisibleElements(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let header = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected a visible calculator panel header before auditing", file: file, line: line)
        XCTAssertTrue(windowFrame.contains(header.frame), "\(context): sheet visible frame should contain the panel header. Header: \(frameDescription(header.frame)); window: \(frameDescription(windowFrame))", file: file, line: line)

        let display = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 5), "\(context): expected the calculator display before auditing", file: file, line: line)
        XCTAssertTrue(display.isHittable, "\(context): calculator display should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(display.frame))", file: file, line: line)

        let close = app.buttons["exam-tool-close-button"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "\(context): expected Close tool before auditing", file: file, line: line)
        XCTAssertTrue(close.isHittable, "\(context): Close tool should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(close.frame))", file: file, line: line)

        for identifier in calculatorKeyIdentifiers {
            let key = app.buttons[identifier].firstMatch
            XCTAssertTrue(key.waitForExistence(timeout: 5), "\(context): expected \(identifier) before auditing", file: file, line: line)
            XCTAssertTrue(key.isHittable, "\(context): \(identifier) should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(key.frame))", file: file, line: line)
        }
    }

    private var calculatorKeyIdentifiers: [String] {
        [
            "calculator-key-all-clear", "calculator-key-clear-entry", "calculator-key-backspace", "calculator-key-divide",
            "calculator-key-7", "calculator-key-8", "calculator-key-9", "calculator-key-multiply",
            "calculator-key-4", "calculator-key-5", "calculator-key-6", "calculator-key-subtract",
            "calculator-key-1", "calculator-key-2", "calculator-key-3", "calculator-key-add",
            "calculator-key-toggle-sign", "calculator-key-0", "calculator-key-decimal", "calculator-key-equals",
            "calculator-key-square-root", "calculator-key-square", "calculator-key-reciprocal", "calculator-key-percent"
        ]
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
        scrollExamToolUntilHittable(start, in: app, maxSwipes: 8)
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

    private func scrollExamToolUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
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
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
            } else {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
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
        let focusedTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target"].firstMatch
        XCTAssertTrue(focusedTarget.waitForExistence(timeout: 5), "Expected the calculator keyboard handler after opening the calculator", file: file, line: line)
        return focusedTarget
    }

    private func typeCalculatorKeys(_ keys: [String], on calculator: XCUIElement) {
        for key in keys {
            calculator.typeKey(key, modifierFlags: [])
            waitBriefly()
        }
    }

    private func positionElementFullyVisibleAboveToolSheet(_ element: XCUIElement, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let scrollView = scrollView(containing: element, in: app)
        XCTAssertTrue(scrollView.waitForExistence(timeout: 1), "\(context): expected a scroll view", file: file, line: line)
        var trace: [String] = ["start: target=\(frameDescription(element.frame)) visible=\(frameDescription(visibleFrameAboveToolSheet(in: app)))"]
        for step in 1...16 where !isFullyVisibleAboveToolSheet(element, in: app) {
            if element.exists && element.frame.maxY <= visibleFrameAboveToolSheet(in: app).minY {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
            } else {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
            }
            waitBriefly()
            trace.append("step \(step): target=\(frameDescription(element.frame)) visible=\(frameDescription(visibleFrameAboveToolSheet(in: app)))")
        }
        XCTAssertTrue(isFullyVisibleAboveToolSheet(element, in: app), "\(context): expected the element fully visible above the tool sheet. Frame: \(frameDescription(element.frame)); trace: \(trace.joined(separator: " -> "))", file: file, line: line)
    }

    private func preciseExamToolScroll(_ scrollView: XCUIElement, in app: XCUIApplication, fingerDeltaY: CGFloat) {
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
            !["calculator-keyboard-focus-target", "calculator-tool-scroll"].contains(scrollView.identifier)
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

    private func isFullyVisibleAboveToolSheet(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return visibleFrameAboveToolSheet(in: app).contains(element.frame)
    }

    private func visibleFrameAboveToolSheet(in app: XCUIApplication) -> CGRect {
        let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
        let sheetTop = activeToolPanelTop(in: app).map { $0 - 8 } ?? visibleFrame.maxY
        let maxY = min(visibleFrame.maxY, sheetTop)
        return CGRect(x: visibleFrame.minX, y: visibleFrame.minY + 8, width: visibleFrame.width, height: max(0, maxY - visibleFrame.minY - 8))
    }

    private struct LessonAuditGeometry {
        let scrollFrame: CGRect
        let visibleScrollArea: CGRect
        let navigationBarElementFrames: [CGRect]
        let scrollView: XCUIElement?
    }

    private func lessonAuditGeometryBelowOpaqueNavigationBar(in app: XCUIApplication) -> LessonAuditGeometry {
        let windowFrame = app.windows.firstMatch.frame
        let protectedMaxY = protectedNavigationFrame(in: app).maxY
        let visibleScrollView = app.scrollViews.allElementsBoundByIndex.first { scrollView in
            scrollView.exists && scrollView.frame.width > 0 && scrollView.frame.height > 0 && scrollView.frame.intersects(windowFrame)
        }
        let scrollFrame = (visibleScrollView?.frame ?? windowFrame).intersection(windowFrame)
        let minY = max(scrollFrame.minY, protectedMaxY)
        let visibleScrollArea = CGRect(
            x: scrollFrame.minX,
            y: minY,
            width: max(0, scrollFrame.width),
            height: max(0, scrollFrame.maxY - minY)
        )
        return LessonAuditGeometry(
            scrollFrame: scrollFrame,
            visibleScrollArea: visibleScrollArea,
            navigationBarElementFrames: navigationBarElementFrames(in: app),
            scrollView: visibleScrollView
        )
    }

    private func navigationBarElementFrames(in app: XCUIApplication) -> [CGRect] {
        let navigationBar = app.navigationBars.firstMatch
        guard navigationBar.exists else { return [] }
        return ([navigationBar] + navigationBar.descendants(matching: .any).allElementsBoundByIndex)
            .compactMap { element in
                guard element.exists else { return nil }
                let frame = element.frame
                guard frame.width > 0, frame.height > 0 else { return nil }
                return frame
            }
    }

    private func element(_ element: XCUIElement, withFrame frame: CGRect, isDescendantOf scrollView: XCUIElement?) -> Bool {
        guard let scrollView, scrollView.exists else { return false }
        let query: XCUIElementQuery
        switch element.elementType {
        case .staticText:
            query = scrollView.staticTexts
        case .button:
            query = scrollView.buttons
        default:
            query = scrollView.descendants(matching: element.elementType)
        }
        let candidates: [XCUIElement]
        if !element.identifier.isEmpty {
            candidates = query.matching(identifier: element.identifier).allElementsBoundByIndex
        } else if !element.label.isEmpty {
            candidates = query.matching(NSPredicate(format: "label == %@", element.label)).allElementsBoundByIndex
        } else {
            candidates = query.allElementsBoundByIndex
        }
        return candidates.contains { candidate in
            guard candidate.exists else { return false }
            return self.frame(frame, matches: candidate.frame)
        }
    }

    private func frame(_ frame: CGRect, matchesAny candidates: [CGRect]) -> Bool {
        candidates.contains { candidate in
            self.frame(frame, matches: candidate)
        }
    }

    private func frame(_ frame: CGRect, matches candidate: CGRect) -> Bool {
        abs(frame.minX - candidate.minX) <= 1
            && abs(frame.minY - candidate.minY) <= 1
            && abs(frame.width - candidate.width) <= 1
            && abs(frame.height - candidate.height) <= 1
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
