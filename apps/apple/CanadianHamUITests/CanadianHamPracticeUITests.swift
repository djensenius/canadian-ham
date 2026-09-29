import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    private let auditIterationID = CanadianHamPracticeUITests.makeAuditIterationID()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])

        assertSingleLanguagePicker(in: app, context: "practice")
        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        let frenchSegment = languagePicker.buttons["Français"].firstMatch
        XCTAssertTrue(frenchSegment.waitForExistence(timeout: 2), "French segment should be available")
        frenchSegment.tap()

        waitBriefly()
        let visibleTextLabels = Set(app.descendants(matching: .any).allElementsBoundByIndex.map(\.label).filter { !$0.isEmpty })
        let frenchQuestionTexts = try bundledFrenchQuestionTexts(forCategoryID: "B-001")
        let visibleFrenchQuestion = frenchQuestionTexts.first { visibleTextLabels.contains($0) }
        XCTAssertNotNil(
            visibleFrenchQuestion,
            "Expected one of the bundled French B-001 question stems after switching language. Visible labels: \(visibleTextLabels.sorted())"
        )

        answerFirstVisibleAnswer(in: app)
        let feedback = waitForAnswerFeedback(in: app)
        XCTAssertTrue(
            feedback.label.hasPrefix("Correct") || feedback.label.hasPrefix("Incorrect"),
            "Feedback label should start with Correct or Incorrect, got: \(feedback.label)"
        )
    }

    func testLanguagePickerExistsOnCategoryListAndPractice() throws {
        XCUIDevice.shared.appearance = .light
        var app = launchApp(arguments: ["-CanadianHamInitialScreen", "practice"])
        assertSingleLanguagePicker(in: app, context: "practice hub")
        XCTAssertTrue(app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 10))
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        assertSingleLanguagePicker(in: app, context: "practice")
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
    }

    func testPracticeImmediateFeedbackKeepsStateAfterFirstAnswer() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.descendants(matching: .any)["question-identifier"].firstMatch.label, "B-001-002-002")

        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        waitBriefly(1.0)

        XCTAssertEqual(app.descendants(matching: .any)["question-identifier"].firstMatch.label, "B-001-002-002", "Saving progress must not reload the practice session")
        XCTAssertTrue(app.buttons["Next question"].firstMatch.exists, "Immediate feedback controls should remain after saving progress")
        XCTAssertTrue(app.descendants(matching: .any)["answer-feedback"].firstMatch.exists, "Feedback should remain after saving progress")
    }

    func testMockExamDoesNotShowCorrectnessBeforeSubmit() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: ["-CanadianHamInitialScreen", "mock", "-CanadianHamMockExamSeed", "ui-mock-no-correctness"])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))

        answerFirstVisibleAnswer(in: app)
        waitBriefly()

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.exists)
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Correct answer"), "Mock exams must not reveal the correct answer before submit")
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Your answer, incorrect"), "Mock exams must not reveal incorrectness before submit")
    }

    func testReviewLaterHidesCorrectnessUntilSubmitAndResultsSurviveSave() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002",
            "-CanadianHamPracticeMode", "review-later",
            "-CanadianHamPracticeLimit", "1"
        ])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))

        answerFirstVisibleAnswer(in: app)
        waitBriefly()
        XCTAssertFalse(anyVisibleLabel(in: app, contains: "Correct answer"), "Review-later practice must not reveal correctness before submit")
        scrollAndTap("Submit for review", in: app)

        XCTAssertTrue(app.staticTexts["Practice review"].waitForExistence(timeout: 10))
        XCTAssertTrue(anyVisibleLabel(in: app, contains: "Correct answer:"), "Review-later results should reveal correctness after submit")
        waitBriefly(1.0)
        XCTAssertTrue(app.staticTexts["Practice review"].exists, "Saving review-later progress must not reset the review screen")
    }

    func testRegularWidthMockExamResultPersistsAfterSubmit() throws {
        XCUIDevice.shared.appearance = .light
#if os(iOS)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
#endif
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-regular-result"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        answerFirstVisibleAnswer(in: app)
        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        waitBriefly(1.0)
        assertMockExamResultVisible(in: app)
    }

    func testPracticeFlowSupportsLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", "B-001-002-002",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        answerFirstVisibleAnswer(in: app)
        let feedback = waitForAnswerFeedback(in: app)
        XCTAssertTrue(feedback.exists, "Answer feedback should exist after answering at the largest accessibility text size")

        let nextQuestionButton = app.buttons["Next question"].firstMatch
        XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist at the largest accessibility text size")
        scrollUntilHittable(nextQuestionButton, in: app, maxSwipes: 14)
        XCTAssertTrue(nextQuestionButton.isHittable, "Next question button should be reachable by scrolling at the largest accessibility text size")
        nextQuestionButton.tap()

        waitForElementToDisappear(feedback, timeout: 5, message: "Answer feedback should disappear after advancing at the largest accessibility text size")
    }

    func testLongestAnswerWrapsAtLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let longestAnswer = try longestEnglishAnswerInBank()
        let app = launchApp(arguments: [
            "-CanadianHamInitialCategoryID", longestAnswer.categoryId,
            "-CanadianHamPracticeQuestionID", longestAnswer.questionId,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        let answerText = app.staticTexts.matching(NSPredicate(format: "label == %@", longestAnswer.answerText)).firstMatch
        XCTAssertTrue(
            answerText.waitForExistence(timeout: 10),
            "Expected longest bundled answer to render for \(longestAnswer.questionId)"
        )
        scrollUntilPartiallyVisible(answerText, in: app, maxSwipes: 20)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(answerText, in: app),
            "Longest answer should have a visible, scrollable text frame below the navigation bar. Frame: \(frameDescription(answerText.frame))"
        )
        XCTAssertGreaterThan(
            answerText.frame.height,
            200,
            "Longest answer should expose its full multi-line text height rather than clipping to one line"
        )
    }

    func testAccessibilityAuditCoreScreensLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditCoreScreens(appearance: .light)
    }

    func testAccessibilityAuditCoreScreensDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditCoreScreens(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testAccessibilityAuditPracticeSessionLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditPracticeSession(appearance: .light)
    }

    func testAccessibilityAuditPracticeSessionDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditPracticeSession(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testAccessibilityAuditMockExamFlowLight() throws {
        XCUIDevice.shared.appearance = .light
        try auditMockExamFlow(appearance: .light)
    }

    func testAccessibilityAuditMockExamFlowDark() throws {
        XCUIDevice.shared.appearance = .dark
        try auditMockExamFlow(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    func testA11yDiagnosticsEvidenceHarness() throws {
        guard ProcessInfo.processInfo.environment["CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS"] == "1" else {
            throw XCTSkip("Set CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS=1 to run the opt-in accessibility evidence diagnostic harness.")
        }

        XCUIDevice.shared.appearance = .light
        try runDiagnosticsHarness(appearance: .light)
        XCUIDevice.shared.appearance = .dark
        try runDiagnosticsHarness(appearance: .dark)
        XCUIDevice.shared.appearance = .light
    }

    private func auditCoreScreens(appearance: AuditAppearance) throws {
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

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "learn"])
        XCTAssertTrue(app.staticTexts["Learn"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) learn placeholder")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "settings"])
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) settings")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamInitialScreen", "about"])
        XCTAssertTrue(app.staticTexts["About Canadian Ham"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) about")
        app.terminate()

        app = launchApp(arguments: ["-CanadianHamForceStoreOpenError"], resetData: false)
        XCTAssertTrue(app.staticTexts["Local progress store unavailable"].waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) store recovery")
        app.terminate()
    }

    private func auditPracticeSession(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        try performAudit(on: app, context: "\(appearance.rawValue) unanswered practice")

        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        app.scrollViews.firstMatch.swipeUp()
        waitBriefly()
        try performAudit(on: app, context: "\(appearance.rawValue) answered practice")
        app.terminate()
    }

    private func auditMockExamFlow(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-a11y-mock-exam",
            "-CanadianHamExamTimerEnabled", "true",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "1"
        ])
        openMockExamStart(in: app)
        XCTAssertTrue(app.staticTexts["mock-exam-seed"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Question navigator"].waitForExistence(timeout: 5))
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam question navigator timer")

        answerKnownCorrectLifeAnswerIfPresent(in: app)
        scrollAndTap("Submit exam", in: app)
        submitMockExamAlert(in: app)
        assertMockExamResultVisible(in: app)
        app.scrollViews.firstMatch.swipeUp()
        waitBriefly()
        try performAudit(on: app, context: "\(appearance.rawValue) mock exam results")
        app.terminate()
    }

    private func runDiagnosticsHarness(appearance: AuditAppearance) throws {
        let app = launchApp(arguments: ["-CanadianHamInitialCategoryID", "B-001", "-CanadianHamPracticeQuestionID", "B-001-002-002"])
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        captureScreenEvidence(named: "practice-\(appearance.rawValue)-unanswered-iteration-\(auditIterationID)")
        try captureAccessibilityAudit(on: app, context: "practice \(appearance.rawValue) unanswered")
        answerFirstVisibleAnswer(in: app)
        _ = waitForAnswerFeedback(in: app)
        captureScreenEvidence(named: "practice-\(appearance.rawValue)-answered-iteration-\(auditIterationID)")
        try captureAccessibilityAudit(on: app, context: "practice \(appearance.rawValue) answered")
        app.terminate()
    }

    private func launchApp(arguments: [String] = [], resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (resetData ? ["-CanadianHamResetDataOnLaunch"] : []) + arguments
        app.launch()
        return app
    }

    private func performAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            try app.performAccessibilityAudit { issue in
                findings.append(self.describe(issue))
                return true
            }
            XCTAssertTrue(findings.isEmpty, "Accessibility audit reported issues for \(context): \(findings.joined(separator: " | "))")
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable before iOS 17 for \(context).")
        }
    }

    private func captureAccessibilityAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            do {
                try app.performAccessibilityAudit { issue in
                    findings.append(self.describe(issue))
                    return true
                }
            } catch {
                attachRawAuditFindings(findings, context: context, error: error)
                throw error
            }
            attachRawAuditFindings(findings, context: context, error: nil)
            XCTAssertTrue(findings.isEmpty, "Accessibility audit reported issues for \(context): \(findings.joined(separator: " | "))")
        } else {
            attachRawAuditFindings(["performAccessibilityAudit is unavailable before iOS 17."], context: context, error: nil)
        }
    }

    @available(iOS 17.0, *)
    private func describe(_ issue: XCUIAccessibilityAuditIssue) -> String {
        let element = issue.element
        return """
        auditType: \(issue.auditType)
        element.identifier: \(element?.identifier ?? "")
        element.label: \(element?.label ?? "")
        element.frame: \(element.map { frameDescription($0.frame) } ?? "nil")
        compactDescription: \(issue.compactDescription)
        """
    }

    private func attachRawAuditFindings(_ findings: [String], context: String, error: Error?) {
        var lines = ["Context: \(context)", "Iteration: \(auditIterationID)"]
        if let error { lines.append("Audit error: \(error)") }
        lines.append(findings.isEmpty ? "No accessibility audit issues reported." : findings.joined(separator: "\n\n"))
        let text = lines.joined(separator: "\n\n")
        let attachment = XCTAttachment(string: text)
        attachment.name = "\(sanitizedEvidenceName(context))-raw-accessibility-audit-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(Data(text.utf8), filename: "\(sanitizedEvidenceName(context))-raw-accessibility-audit-findings.txt")
    }

    @discardableResult
    private func captureScreenEvidence(named name: String) -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = sanitizedEvidenceName(name)
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(screenshot.pngRepresentation, filename: "\(sanitizedEvidenceName(name)).png")
        return screenshot
    }

    private func exportEvidence(_ data: Data, filename: String, file: StaticString = #filePath, line: UInt = #line) {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("CanadianHamA11yEvidence", isDirectory: true)
            .appendingPathComponent(auditIterationID, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(sanitizedEvidenceName(filename)), options: .atomic)
        } catch {
            XCTFail("Failed to export accessibility evidence \(filename): \(error)", file: file, line: line)
        }
    }

    private func sanitizedEvidenceName(_ name: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(name.unicodeScalars.map { allowedCharacters.contains($0) ? Character($0) : "-" })
    }

    private func openMockExamStart(in app: XCUIApplication) {
        let start = app.buttons["Start mock exam"].firstMatch
        if !start.waitForExistence(timeout: 3) {
            let sidebarMock = app.buttons["Mock exam"].firstMatch
            if sidebarMock.waitForExistence(timeout: 3) {
                sidebarMock.tap()
            }
        }
        tap("Start mock exam", in: app)
    }

    private func tap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        button.tap()
    }

    private func scrollAndTap(_ label: String, in app: XCUIApplication) {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Expected button \(label)")
        for _ in 0..<14 where !button.isHittable {
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
        XCTAssertTrue(button.isHittable, "Expected button \(label) to be hittable")
        button.tap()
    }

    private func submitMockExamAlert(in app: XCUIApplication) {
        let alert = app.alerts["Submit mock exam?"].firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Submit"].tap()
    }

    private func assertMockExamResultVisible(in app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["Needs review"].waitForExistence(timeout: 10)
            || app.staticTexts["Pass"].waitForExistence(timeout: 1)
            || app.staticTexts["Basic with Honours"].waitForExistence(timeout: 1),
            "Expected mock exam results to remain visible"
        )
    }

    private func answerKnownCorrectLifeAnswerIfPresent(in app: XCUIApplication) {
        let correctAnswer = app.staticTexts["life"].firstMatch
        if correctAnswer.waitForExistence(timeout: 2) {
            correctAnswer.tap()
        } else {
            answerFirstVisibleAnswer(in: app)
        }
    }

    private func answerFirstVisibleAnswer(in app: XCUIApplication) {
        let identifiers = ["answer-A-button", "answer-B-button", "answer-C-button", "answer-D-button"]
        XCTAssertTrue(app.descendants(matching: .any)[identifiers[0]].firstMatch.waitForExistence(timeout: 10))
        for _ in 0..<10 {
            for id in identifiers {
                let button = app.descendants(matching: .any)[id].firstMatch
                if button.exists && button.isHittable {
                    button.tap()
                    return
                }
            }
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
        XCTFail("No answer button became hittable")
    }

    private func waitForAnswerFeedback(in app: XCUIApplication) -> XCUIElement {
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Answer feedback should appear after selecting an answer")
        return feedback
    }

    private func assertSingleLanguagePicker(in app: XCUIApplication, context: String) {
        let languagePickers = app.segmentedControls.matching(identifier: "question-language-picker")
        XCTAssertTrue(languagePickers.firstMatch.waitForExistence(timeout: 10), "Question language picker should exist on \(context)")
        XCTAssertEqual(languagePickers.count, 1, "Exactly one question language picker should be visible on \(context)")
    }

    private func anyVisibleLabel(in app: XCUIApplication, contains needle: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", needle)
        return app.staticTexts.matching(predicate).firstMatch.exists
    }

    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
        }
    }

    private func scrollUntilPartiallyVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 1) else { return }
        for _ in 0..<maxSwipes where !isPartiallyVisibleBelowNavigationBar(element, in: app) {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            if element.frame.maxY <= visibleFrame.minY {
                scrollView.swipeDown()
            } else {
                scrollView.swipeUp()
            }
            waitBriefly()
        }
    }

    private func isPartiallyVisibleBelowNavigationBar(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        return element.frame.intersects(visibleFrameExcludingNavigationBar(in: app))
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let navBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(navBar.exists ? navBar.frame.maxY : windowFrame.minY, statusBar.exists ? statusBar.frame.maxY : windowFrame.minY)
        return CGRect(x: windowFrame.minX + 16, y: protectedMaxY + 1, width: max(0, windowFrame.width - 32), height: max(0, windowFrame.maxY - protectedMaxY - 17))
    }

    private func scrollToTop(in app: XCUIApplication) {
        let target = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
        for _ in 0..<6 {
            target.swipeDown()
            waitBriefly()
        }
    }

    private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval, message: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, message, file: file, line: line)
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func bundledFrenchQuestionTexts(forCategoryID categoryID: String) throws -> Set<String> {
        let questions = try bundledQuestions()
        return Set(questions.compactMap { question in
            guard question.categoryId == categoryID else { return nil }
            return question.text.fr
        })
    }

    private func longestEnglishAnswerInBank() throws -> UITestLongestAnswer {
        let questions = try bundledQuestions()
        let answers = questions.flatMap { question in
            question.answers.compactMap { answer -> UITestLongestAnswer? in
                guard let text = answer.text.en, !text.isEmpty else { return nil }
                return UITestLongestAnswer(questionId: question.id, categoryId: question.categoryId, answerText: text)
            }
        }
        return try XCTUnwrap(answers.max { $0.answerText.count < $1.answerText.count })
    }

    private func bundledQuestions() throws -> [UITestQuestion] {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "questions", withExtension: "json"),
            "UI test bundle should include generated question-bank questions.json"
        )
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([UITestQuestion].self, from: data)
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private static func makeAuditIterationID() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "-")
            + "-\(UUID().uuidString.prefix(8))"
    }
}

private enum AuditAppearance: String {
    case light
    case dark
}

private struct UITestQuestion: Decodable {
    let id: String
    let categoryId: String
    let text: UITestLocalizedText
    let answers: [UITestAnswer]
}

private struct UITestAnswer: Decodable {
    let text: UITestLocalizedText
}

private struct UITestLocalizedText: Decodable {
    let en: String?
    let fr: String?
}

private struct UITestLongestAnswer {
    let questionId: String
    let categoryId: String
    let answerText: String
}
