import XCTest

@MainActor
final class CanadianHamPracticeUITests: XCTestCase {
    private let auditIterationID = CanadianHamPracticeUITests.makeAuditIterationID()
    private var visibleAuditCoverage: [AuditCoverageKey: [AuditPass: Set<AuditElementKey>]] = [:]

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

    func testAccessibilityAuditCategoryListUnansweredAndAnsweredPracticeScreens() throws {
        XCUIDevice.shared.appearance = .light
        defer { XCUIDevice.shared.appearance = .light }

        try auditFastPracticeFlow(appearance: .light)

        XCUIDevice.shared.appearance = .dark
        try auditFastPracticeFlow(appearance: .dark)

        XCUIDevice.shared.appearance = .light
    }

    func testA11yDiagnosticsEvidenceHarness() throws {
        guard ProcessInfo.processInfo.environment["CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS"] == "1" else {
            throw XCTSkip("Set CANADIAN_HAM_RUN_A11Y_DIAGNOSTICS=1 to run the opt-in accessibility evidence/position-log diagnostic harness.")
        }

        XCUIDevice.shared.appearance = .light
        defer { XCUIDevice.shared.appearance = .light }

        try auditCategoryListAndAnsweredPracticeScreen(appearance: .light)

        XCUIDevice.shared.appearance = .dark
        try auditCategoryListAndAnsweredPracticeScreen(appearance: .dark)

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

    func testLongestAnswerWrapsAtLargestAccessibilityTextSize() throws {
        XCUIDevice.shared.appearance = .light
        let longestAnswer = try longestEnglishAnswerInBank()
        let app = configuredApp()
        app.launchArguments += [
            "-CanadianHamInitialCategoryID", longestAnswer.categoryId,
            "-CanadianHamPracticeQuestionID", longestAnswer.questionId,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()

        navigateToPracticeIfNeeded(in: app)
        let answerText = app.staticTexts.matching(NSPredicate(format: "label == %@", longestAnswer.answerText)).firstMatch
        XCTAssertTrue(
            answerText.waitForExistence(timeout: 10),
            "Expected longest bundled answer to render for \(longestAnswer.questionId)"
        )
        scrollUntilPartiallyVisible(answerText, in: app, maxSwipes: 20)
        XCTAssertTrue(
            isPartiallyVisibleBelowNavigationBar(answerText, in: app),
            "Longest answer should have a visible, scrollable text frame below the navigation bar at the largest Dynamic Type size. Frame: \(frameDescription(answerText.frame))"
        )
        XCTAssertGreaterThan(
            answerText.frame.height,
            200,
            "Longest answer should expose its full multi-line text height at the largest Dynamic Type size rather than clipping to one line"
        )
    }

    private func auditFastPracticeFlow(appearance: AuditAppearance) throws {
        let app = configuredApp()
        app.launchArguments += [
            "-CanadianHamShowCategoryList",
            "-CanadianHamPracticeQuestionID", fastAuditPracticeQuestionID
        ]
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 10), "Category list should render before the category-list audit")
        try performFastAccessibilityAudit(on: app, context: "\(appearance.rawValue) category list")

        let category = app.staticTexts["Regulations and Policies"].firstMatch
        XCTAssertTrue(category.exists, "Fast audit category should be visible on the category list")
        category.tap()

        XCTAssertTrue(app.staticTexts["An Amateur Radio Operator Certificate is valid for:"].firstMatch.waitForExistence(timeout: 10), "Fast audit question should render before the unanswered practice audit")
        try performFastAccessibilityAudit(on: app, context: "\(appearance.rawValue) unanswered practice")

        answerFastAuditQuestionCorrectly(in: app)
        _ = waitForAnswerFeedback(in: app)
        try performFastAccessibilityAudit(on: app, context: "\(appearance.rawValue) answered practice")
    }

    private func performFastAccessibilityAudit(on app: XCUIApplication, context: String) throws {
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit()
        } else {
            throw XCTSkip("performAccessibilityAudit is unavailable before iOS 17 for \(context).")
        }
    }

    private func answerFastAuditQuestionCorrectly(in app: XCUIApplication) {
        let correctAnswer = app.staticTexts["life"].firstMatch
        XCTAssertTrue(correctAnswer.exists, "Known correct answer should be visible in the fast audit question")
        correctAnswer.tap()
    }

    private func auditCategoryListAndAnsweredPracticeScreen(appearance: AuditAppearance) throws {
        let app = configuredApp()
        app.launchArguments += [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", auditPracticeQuestionID,
            "-CanadianHamA11yAuditExtraBottomMargin"
        ]
        app.launch()
        defer { app.terminate() }

        navigateToCategoryListIfNeeded(in: app)
        try auditScreenInTwoPasses(
            app: app,
            screen: .categoryList,
            appearance: appearance,
            questionID: nil,
            prepare: { pass in
                prepareCategoryList(pass: pass, in: app)
            },
            interests: { pass in
                categoryListAuditInterests(pass: pass, in: app)
            }
        )

        navigateToPracticeIfNeeded(in: app)
        let questionID = currentQuestionID(in: app) ?? auditPracticeQuestionID
        answerFirstVisibleQuestion(in: app)
        _ = waitForAnswerFeedback(in: app)
        try auditScreenInTwoPasses(
            app: app,
            screen: .answeredPractice,
            appearance: appearance,
            questionID: questionID,
            prepare: { pass in
                prepareAnsweredPractice(pass: pass, in: app)
            },
            interests: { pass in
                answeredPracticeAuditInterests(pass: pass, in: app)
            }
        )
    }

    private func auditScreenInTwoPasses(
        app: XCUIApplication,
        screen: AuditScreen,
        appearance: AuditAppearance,
        questionID: String?,
        prepare: (AuditPass) -> Void,
        interests: (AuditPass) -> [AuditInterest]
    ) throws {
        let passes: [AuditPass] = [.top, .scrolled]

        for pass in passes {
            prepare(pass)
            let context = AuditContext(screen: screen, appearance: appearance, pass: pass, questionID: questionID, iterationID: auditIterationID)
            let passInterests = interests(pass)
            waitForStableAuditLayout(passInterests, context: context, in: app)
            let records = verifyAuditElementPositions(passInterests, context: context, in: app)
            recordVisibleAuditCoverage(records, context: context)
        }

        for pass in passes {
            prepare(pass)
            let context = AuditContext(screen: screen, appearance: appearance, pass: pass, questionID: questionID, iterationID: auditIterationID)
            let passInterests = interests(pass)
            waitForStableAuditLayout(passInterests, context: context, in: app)
            let records = verifyAuditElementPositions(passInterests, context: context, in: app)
            recordVisibleAuditCoverage(records, context: context)
            captureScreenEvidence(named: "\(context.evidenceStem)-accessibility-audit")
            try captureAccessibilityAudit(on: app, context: context, preAuditRecords: records)
        }
    }

    private func configuredApp() -> XCUIApplication {
        XCUIApplication()
    }

    private var auditPracticeQuestionID: String { "B-001-001-004" }
    private var fastAuditPracticeQuestionID: String { "B-001-002-002" }

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

    private func prepareCategoryList(pass: AuditPass, in app: XCUIApplication) {
        switch pass {
        case .top:
            scrollToTop(in: app)
            XCTAssertTrue(app.staticTexts["Practice categories"].firstMatch.waitForExistence(timeout: 5))
        case .scrolled:
            let lastCategory = app.staticTexts["Interference and Suppression"].firstMatch
            scrollElementToVisibleMiddle(lastCategory, in: app, maxSwipes: 14)
            XCTAssertTrue(isFullyVisible(lastCategory, in: app, requiresHittable: false), "Last category should be visible for the scrolled category-list pass")
        }
    }

    private func prepareAnsweredPractice(pass: AuditPass, in app: XCUIApplication) {
        switch pass {
        case .top:
            scrollToTop(in: app)
            let title = app.descendants(matching: .any)["practice-category-title"].firstMatch
            XCTAssertTrue(title.waitForExistence(timeout: 5), "Practice title should exist before the top audit pass")
            XCTAssertTrue(isFullyVisible(title, in: app, requiresHittable: false), "Practice title should start below the navigation bar at scroll position 0")
        case .scrolled:
            let nextQuestionButton = app.buttons["Next question"].firstMatch
            XCTAssertTrue(nextQuestionButton.waitForExistence(timeout: 5), "Next question button should exist before the scrolled audit pass")
            scrollUntilHittable(nextQuestionButton, in: app, maxSwipes: 8)
            for _ in 0..<3 {
                app.scrollViews.firstMatch.swipeUp()
                waitBriefly()
            }
            let answerC = app.descendants(matching: .any)["answer-C-button"].firstMatch
            XCTAssertTrue(isFullyVisible(answerC, in: app, requiresHittable: false), "Answer C should be fully visible for the scrolled audit pass")
            XCTAssertTrue(isFullyVisible(nextQuestionButton, in: app, requiresHittable: true), "Next question button should be visible for the scrolled audit pass")
        }
    }

    private func categoryListAuditInterests(pass: AuditPass, in app: XCUIApplication) -> [AuditInterest] {
        let firstCategoryCount = categoryCountLabel(categoryID: "B-001")
        let lastCategoryCount = categoryCountLabel(categoryID: "B-008")
        switch pass {
        case .top:
            return [
                AuditInterest(name: "Practice categories header", element: app.staticTexts["Practice categories"].firstMatch),
                AuditInterest(name: "First category title", element: app.staticTexts["Regulations and Policies"].firstMatch),
                AuditInterest(name: "First category count", element: app.staticTexts[firstCategoryCount].firstMatch)
            ]
        case .scrolled:
            return [
                AuditInterest(name: "Last category title", element: app.staticTexts["Interference and Suppression"].firstMatch),
                AuditInterest(name: "Last category count", element: app.staticTexts[lastCategoryCount].firstMatch)
            ]
        }
    }

    private func answeredPracticeAuditInterests(pass: AuditPass, in app: XCUIApplication) -> [AuditInterest] {
        let any = app.descendants(matching: .any)
        let namesEnforcedInPass: Set<String>
        switch pass {
        case .top:
            namesEnforcedInPass = [
                "Practice category title",
                "Practice category summary",
                "Practice session tally",
                "Question identifier",
                "Question stem",
                "Answers heading",
                "Answer A",
                "Answer A text",
                "Answer A chip",
                "Answer B",
                "Answer B text",
                "Answer B chip"
            ]
        case .scrolled:
            namesEnforcedInPass = [
                "Answer C",
                "Answer C text",
                "Answer C chip",
                "Answer D",
                "Answer D text",
                "Answer D chip",
                "Answer feedback",
                "Answer feedback title",
                "Answer feedback correct answer",
                "Answer feedback source",
                "Next question"
            ]
        }

        func interest(_ name: String, _ element: XCUIElement, required: Bool = true) -> AuditInterest {
            AuditInterest(
                name: name,
                element: element,
                required: required,
                enforcesVisibility: namesEnforcedInPass.contains(name)
            )
        }

        return [
            interest("Practice category title", any["practice-category-title"].firstMatch),
            interest("Practice category summary", any["practice-category-summary"].firstMatch),
            interest("Practice session tally", any["practice-session-tally"].firstMatch),
            interest("Question identifier", any["question-identifier"].firstMatch),
            interest("Question stem", any["question-stem"].firstMatch),
            interest("Answers heading", any["answers-title"].firstMatch),
            interest("Answer A", any["answer-A-button"].firstMatch),
            interest("Answer A text", any["answer-A-text"].firstMatch),
            interest("Answer A chip", any["answer-A-chip"].firstMatch),
            interest("Answer B", any["answer-B-button"].firstMatch),
            interest("Answer B text", any["answer-B-text"].firstMatch),
            interest("Answer B chip", any["answer-B-chip"].firstMatch),
            interest("Answer C", any["answer-C-button"].firstMatch),
            interest("Answer C text", any["answer-C-text"].firstMatch),
            interest("Answer C chip", any["answer-C-chip"].firstMatch),
            interest("Answer D", any["answer-D-button"].firstMatch),
            interest("Answer D text", any["answer-D-text"].firstMatch),
            interest("Answer D chip", any["answer-D-chip"].firstMatch),
            interest("Answer feedback", any["answer-feedback"].firstMatch),
            interest("Answer feedback title", any["answer-feedback-title"].firstMatch),
            interest("Answer feedback correct answer", any["answer-feedback-correct-answer"].firstMatch, required: false),
            interest("Answer feedback source", any["answer-feedback-source"].firstMatch),
            interest("Next question", app.buttons["Next question"].firstMatch)
        ]
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

    private func currentQuestionID(in app: XCUIApplication) -> String? {
        let questionIdentifier = app.descendants(matching: .any)["question-identifier"].firstMatch
        guard questionIdentifier.waitForExistence(timeout: 2) else { return nil }
        return questionIdentifier.label.isEmpty ? nil : questionIdentifier.label
    }

    private func categoryCountLabel(categoryID: String) -> String {
        guard let questions = try? bundledQuestions() else {
            return "missing bundled question count for \(categoryID)"
        }
        let categoryQuestions = questions.filter { $0.categoryId == categoryID }
        let subsectionCount = Set(categoryQuestions.map(\.subsectionId)).count
        return "\(categoryQuestions.count) questions • \(subsectionCount) subsections"
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

    private func scrollElementToVisibleMiddle(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 16) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element should exist before scrolling for audit")
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 1) else {
            return
        }

        for _ in 0..<maxSwipes {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            let elementFrame = element.frame
            let isFullyInsideVisibleFrame = elementFrame.minY >= visibleFrame.minY && elementFrame.maxY <= visibleFrame.maxY
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

    private func scrollToTop(in app: XCUIApplication) {
        let scrollTarget = app.scrollViews.firstMatch.exists ? app.scrollViews.firstMatch : app
        for _ in 0..<8 {
            scrollTarget.swipeDown()
            waitBriefly()
        }
    }

    private func waitForStableAuditLayout(
        _ interests: [AuditInterest],
        context: AuditContext,
        in app: XCUIApplication,
        timeout: TimeInterval = 3,
        tolerance: CGFloat = 0.5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var previousSnapshot = auditFrameSnapshot(for: interests, in: app)
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            waitBriefly()
            let currentSnapshot = auditFrameSnapshot(for: interests, in: app)
            if auditFramesAreStable(previousSnapshot, currentSnapshot, tolerance: tolerance) {
                return
            }
            previousSnapshot = currentSnapshot
        } while Date() < deadline

        XCTFail("Audit layout did not settle before \(context.evidenceStem). Last frames: \(auditFrameSnapshotDescription(previousSnapshot))", file: file, line: line)
    }

    private func auditFrameSnapshot(for interests: [AuditInterest], in app: XCUIApplication) -> [String: CGRect] {
        var snapshot: [String: CGRect] = [:]
        let bars = barFrames(in: app)
        snapshot["window"] = app.windows.firstMatch.exists ? app.windows.firstMatch.frame : .null
        snapshot["navigationBar"] = bars.navigationBarFrame
        snapshot["statusBar"] = bars.statusBarFrame
        for interest in interests {
            snapshot["element:\(interest.name)"] = interest.element.exists ? interest.element.frame : .null
        }
        return snapshot
    }

    private func auditFramesAreStable(_ first: [String: CGRect], _ second: [String: CGRect], tolerance: CGFloat) -> Bool {
        guard Set(first.keys) == Set(second.keys) else { return false }
        return first.allSatisfy { key, firstFrame in
            guard let secondFrame = second[key] else { return false }
            if firstFrame.isNull || secondFrame.isNull {
                return firstFrame.isNull && secondFrame.isNull
            }
            return abs(firstFrame.minX - secondFrame.minX) <= tolerance
                && abs(firstFrame.minY - secondFrame.minY) <= tolerance
                && abs(firstFrame.width - secondFrame.width) <= tolerance
                && abs(firstFrame.height - secondFrame.height) <= tolerance
        }
    }

    private func auditFrameSnapshotDescription(_ snapshot: [String: CGRect]) -> String {
        snapshot.keys.sorted().map { key in
            let frame = snapshot[key] ?? .null
            return "\(key)=\(frame.isNull ? "nil" : frameDescription(frame))"
        }.joined(separator: "; ")
    }

    private func isFullyVisible(_ element: XCUIElement, in app: XCUIApplication, requiresHittable: Bool) -> Bool {
        guard element.exists else { return false }
        if requiresHittable && !element.isHittable { return false }
        return visibleFrameExcludingNavigationBar(in: app).contains(element.frame)
    }

    private func visibleFrameExcludingNavigationBar(in app: XCUIApplication) -> CGRect {
        let windowFrame = app.windows.firstMatch.frame
        let bars = barFrames(in: app)
        let topInset = bars.protectedMaxY + 1
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
        attachment.name = sanitizedEvidenceName(name)
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(screenshot.pngRepresentation, filename: "\(sanitizedEvidenceName(name)).png")
        return screenshot
    }

    private func attachAuditFindings(
        _ findings: [String],
        occludedFindings: [String],
        context: AuditContext,
        error: Error?,
        app: XCUIApplication
    ) {
        let bars = barFrames(in: app)
        var lines = [
            "Screen: \(context.screen.rawValue)",
            "Appearance: \(context.appearance.rawValue)",
            "Pass: \(context.pass.rawValue)",
            "Iteration: \(context.iterationID)",
            "Question ID: \(context.questionID ?? "n/a")",
            "Screen frame: \(frameDescription(app.windows.firstMatch.frame))",
            "Navigation bar frame: \(frameDescription(bars.navigationBarFrame))",
            "Status bar frame: \(frameDescription(bars.statusBarFrame))"
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
        if occludedFindings.isEmpty {
            lines.append("Occluded-by-bar findings: none")
        } else {
            lines.append("Occluded-by-bar findings:\n\(occludedFindings.joined(separator: "\n\n"))")
        }

        let rawFindings = lines.joined(separator: "\n\n")
        let attachment = XCTAttachment(string: rawFindings)
        attachment.name = "\(context.evidenceStem)-raw-accessibility-audit-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(Data(rawFindings.utf8), filename: "\(context.evidenceStem)-raw-accessibility-audit-findings.txt")
    }

    private func attachPositionLog(_ log: String, context: AuditContext) {
        let attachment = XCTAttachment(string: log)
        attachment.name = "\(context.evidenceStem)-audit-position-log"
        attachment.lifetime = .keepAlways
        add(attachment)
        exportEvidence(Data(log.utf8), filename: "\(context.evidenceStem)-audit-position-log.txt")
    }

    private func captureAccessibilityAudit(
        on app: XCUIApplication,
        context: AuditContext,
        preAuditRecords: [AuditElementPositionRecord]
    ) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            var occludedFindings: [String] = []
            var nonExcludedFindings: [String] = []
            var auditError: Error?
            do {
                try app.performAccessibilityAudit { issue in
                    let exclusion = self.exclusionDecision(for: issue, context: context, app: app, preAuditRecords: preAuditRecords)
                    let description = self.describe(issue, exclusion: exclusion)
                    findings.append(description)
                    if exclusion.kind == .occludedByBar {
                        occludedFindings.append(description)
                    }
                    if !exclusion.isExcluded {
                        nonExcludedFindings.append(description)
                    }
                    // Suppress XCTest's immediate audit failure so the raw finding
                    // evidence is always attached before this test fails below.
                    return true
                }
            } catch {
                auditError = error
                attachAuditFindings(findings, occludedFindings: occludedFindings, context: context, error: auditError, app: app)
                throw error
            }
            attachAuditFindings(findings, occludedFindings: occludedFindings, context: context, error: auditError, app: app)
            XCTAssertTrue(
                nonExcludedFindings.isEmpty,
                "Accessibility audit reported non-excluded issues before \(context.evidenceStem): \(nonExcludedFindings.joined(separator: " | "))"
            )
        } else {
            let rawFindings = "Screen: \(context.screen.rawValue)\nAppearance: \(context.appearance.rawValue)\nPass: \(context.pass.rawValue)\nIteration: \(context.iterationID)\nScreen frame: \(frameDescription(app.windows.firstMatch.frame))\nperformAccessibilityAudit is unavailable before iOS 17."
            let attachment = XCTAttachment(string: rawFindings)
            attachment.name = "\(context.evidenceStem)-raw-accessibility-audit-findings"
            attachment.lifetime = .keepAlways
            add(attachment)
            exportEvidence(Data(rawFindings.utf8), filename: "\(context.evidenceStem)-raw-accessibility-audit-findings.txt")
        }
    }

    @available(iOS 17.0, *)
    private func exclusionDecision(
        for issue: XCUIAccessibilityAuditIssue,
        context: AuditContext,
        app: XCUIApplication,
        preAuditRecords: [AuditElementPositionRecord]
    ) -> AuditExclusionDecision {
        let identifier = issue.element?.identifier ?? ""
        let reportedFrame = issue.element?.frame ?? .null
        let recordedRecord = issue.element.flatMap { matchedPreAuditRecord(for: $0, in: preAuditRecords) }
        let recordedFrame = recordedRecord?.frame ?? .null
        let recordedStatus = recordedRecord?.status.rawValue ?? "not-recorded"
        let recordedDetail = recordedRecord?.detail ?? "No matching pre-audit element record by identifier/label."

        if let recordedRecord {
            let occlusion = occlusionProof(forRecordedFrame: recordedRecord.frame, reportedFrame: reportedFrame, in: app)
            if occlusion.isOccluded {
                let coveredInOtherPass = isCoveredFullyVisibleInOtherPass(key: recordedRecord.key, context: context)
                XCTAssertTrue(
                    coveredInOtherPass,
                    "A bar-occluded audit finding for \(recordedDetail) must be fully visible and recorded in the other \(context.screen.rawValue) pass before it can be excluded."
                )
                return AuditExclusionDecision(
                    isExcluded: coveredInOtherPass,
                    kind: .occludedByBar,
                    reason: coveredInOtherPass ? "Excluded because the same element is fully visible in the other \(context.screen.rawValue) pass." : "Not excluded because no other pass audited the same element while fully visible.",
                    proof: occlusion.description,
                    recordedFrame: recordedFrame,
                    recordedStatus: recordedStatus,
                    recordedDetail: recordedDetail
                )
            }
        }

        if let allowed = allowedAuditFindings.first(where: { allowed in
            allowed.screen == context.screen
                && allowed.appearance == context.appearance
                && allowed.identifier == identifier
                && allowed.auditType == issue.auditType
        }) {
            captureScreenEvidence(named: "\(context.evidenceStem)-finding-\(sanitizedEvidenceName(identifier.isEmpty ? "unidentified" : identifier))-\(auditTypeName(issue.auditType))")
            return AuditExclusionDecision(
                isExcluded: true,
                kind: .measuredAllowList,
                reason: "Excluded by measured \(allowed.auditTypeName) tuple with ratio \(String(format: "%.2f", allowed.measuredRatio)):1.",
                proof: allowed.evidence,
                recordedFrame: recordedFrame,
                recordedStatus: recordedStatus,
                recordedDetail: recordedDetail
            )
        }

        return AuditExclusionDecision(
            isExcluded: false,
            kind: .none,
            reason: "No frame-verified occlusion coverage or measured allow-list tuple.",
            proof: "",
            recordedFrame: recordedFrame,
            recordedStatus: recordedStatus,
            recordedDetail: recordedDetail
        )
    }

    @available(iOS 17.0, *)
    private var allowedAuditFindings: [AllowedAuditFinding] { [] }

    private func exportEvidence(
        _ data: Data,
        filename: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let directory = evidenceDirectoryURL()
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(sanitizedEvidenceName(filename)), options: .atomic)
        } catch {
            XCTFail("Failed to export accessibility evidence \(filename): \(error)", file: file, line: line)
        }
    }

    private func evidenceDirectoryURL() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("CanadianHamA11yEvidence", isDirectory: true)
            .appendingPathComponent(auditIterationID, isDirectory: true)
    }

    private func sanitizedEvidenceName(_ name: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return String(name.unicodeScalars.map { allowedCharacters.contains($0) ? Character($0) : "-" })
    }

    @available(iOS 17.0, *)
    private func describe(_ issue: XCUIAccessibilityAuditIssue, exclusion: AuditExclusionDecision) -> String {
        let element = issue.element
        let identifier = element?.identifier ?? ""
        let label = element?.label ?? ""
        let elementType = element.map { String(describing: $0.elementType) } ?? "nil"
        let frame = element.map { frameDescription($0.frame) } ?? "nil"
        let recordedFrame = exclusion.recordedFrame.isNull ? "nil" : frameDescription(exclusion.recordedFrame)
        return """
        auditType: \(issue.auditType)
        auditTypeName: \(auditTypeName(issue.auditType))
        element.identifier: \(identifier)
        element.label: \(label)
        element.elementType: \(elementType)
        element.frame: \(frame)
        recordedElement.frame: \(recordedFrame)
        recordedElement.status: \(exclusion.recordedStatus)
        recordedElement.detail: \(exclusion.recordedDetail)
        compactDescription: \(issue.compactDescription)
        exclusion.kind: \(exclusion.kind.rawValue)
        exclusion.isExcluded: \(exclusion.isExcluded)
        exclusion.reason: \(exclusion.reason)
        exclusion.proof: \(exclusion.proof)
        """
    }

    @available(iOS 17.0, *)
    private func auditTypeName(_ auditType: XCUIAccessibilityAuditType) -> String {
        if auditType == .contrast { return "contrast" }
#if os(iOS)
        if auditType == .textClipped { return "textClipped" }
#endif
        return String(describing: auditType)
    }

    private func verifyAuditElementPositions(_ interests: [AuditInterest], context: AuditContext, in app: XCUIApplication) -> [AuditElementPositionRecord] {
        let bars = barFrames(in: app)
        let windowFrame = app.windows.firstMatch.frame
        var records: [AuditElementPositionRecord] = []
        var violations: [String] = []
        var lines = [
            "Screen: \(context.screen.rawValue)",
            "Appearance: \(context.appearance.rawValue)",
            "Pass: \(context.pass.rawValue)",
            "Iteration: \(context.iterationID)",
            "Question ID: \(context.questionID ?? "n/a")",
            "Window frame: \(frameDescription(windowFrame))",
            "Navigation bar frame: \(frameDescription(bars.navigationBarFrame))",
            "Status bar frame: \(frameDescription(bars.statusBarFrame))",
            "Rule: every identified element is recorded before performAccessibilityAudit(); elements marked enforcesVisibility=true must be fully below navigationBar.maxY/statusBar.maxY within the window or entirely off-screen/under the bars."
        ]

        for interest in interests {
            let element = interest.element
            guard element.exists else {
                let status: AuditElementVisibilityStatus = .missing
                let line = "\(interest.name): missing (required: \(interest.required))"
                lines.append(line)
                if interest.required { violations.append(line) }
                records.append(AuditElementPositionRecord(interest: interest, key: nil, frame: .null, status: status, detail: line))
                continue
            }

            let frame = element.frame
            let key = AuditElementKey(element: element)
            let isFullyBelowBar = frame.minY >= bars.protectedMaxY - 0.5
            let isFullyInsideWindow = frame.minX >= windowFrame.minX - 0.5
                && frame.maxX <= windowFrame.maxX + 0.5
                && frame.maxY <= windowFrame.maxY + 0.5
            let isEntirelyUnderBars = frame.maxY <= bars.protectedMaxY + 0.5
            let isEntirelyOffscreen = frame.maxX <= windowFrame.minX + 0.5
                || frame.minX >= windowFrame.maxX - 0.5
                || frame.maxY <= windowFrame.minY + 0.5
                || frame.minY >= windowFrame.maxY - 0.5
            let status: AuditElementVisibilityStatus
            if isFullyBelowBar && isFullyInsideWindow {
                status = .fullyVisibleBelowBars
            } else if isEntirelyUnderBars || isEntirelyOffscreen {
                status = .entirelyOffscreenOrUnderBars
            } else {
                status = .partiallyObscuredOrClipped
            }

            let detail = "\(interest.name): \(status.rawValue); required=\(interest.required); enforcesVisibility=\(interest.enforcesVisibility); identifier=\(element.identifier); label=\(element.label); frame=\(frameDescription(frame)); navBar.maxY=\(bars.navigationBarFrame.maxY); statusBar.maxY=\(bars.statusBarFrame.maxY)"
            lines.append(detail)
            if status == .partiallyObscuredOrClipped && interest.enforcesVisibility {
                violations.append(detail)
            }
            records.append(AuditElementPositionRecord(interest: interest, key: key, frame: frame, status: status, detail: detail))
        }

        attachPositionLog(lines.joined(separator: "\n"), context: context)
        XCTAssertTrue(violations.isEmpty, "Audit position verification found partially obscured/clipped elements before \(context.evidenceStem): \(violations.joined(separator: " | "))")
        return records
    }

    private func recordVisibleAuditCoverage(_ records: [AuditElementPositionRecord], context: AuditContext) {
        let key = AuditCoverageKey(context: context)
        var passCoverage = visibleAuditCoverage[key, default: [:]]
        var visibleElements = passCoverage[context.pass, default: []]
        for record in records where record.status == .fullyVisibleBelowBars {
            if let key = record.key {
                visibleElements.insert(key)
            }
        }
        passCoverage[context.pass] = visibleElements
        visibleAuditCoverage[key] = passCoverage
    }

    private func matchedPreAuditRecord(for element: XCUIElement, in records: [AuditElementPositionRecord]) -> AuditElementPositionRecord? {
        let elementKey = AuditElementKey(element: element)
        return records.first { record in
            record.key == elementKey
        }
    }

    private func isCoveredFullyVisibleInOtherPass(key elementKey: AuditElementKey?, context: AuditContext) -> Bool {
        guard let elementKey else { return false }
        let key = AuditCoverageKey(context: context)
        guard let passCoverage = visibleAuditCoverage[key] else { return false }
        return passCoverage.contains { pass, elements in
            pass != context.pass && elements.contains(elementKey)
        }
    }

    private func occlusionProof(forRecordedFrame recordedFrame: CGRect, reportedFrame: CGRect, in app: XCUIApplication) -> BarOcclusionProof {
        let bars = barFrames(in: app)
        let intersectsNavigationBar = recordedFrame.intersects(bars.navigationBarFrame)
        let intersectsStatusBar = recordedFrame.intersects(bars.statusBarFrame)
        return BarOcclusionProof(
            isOccluded: intersectsNavigationBar || intersectsStatusBar,
            intersectsNavigationBar: intersectsNavigationBar,
            intersectsStatusBar: intersectsStatusBar,
            recordedElementFrame: recordedFrame,
            auditReportedFrame: reportedFrame,
            navigationBarFrame: bars.navigationBarFrame,
            statusBarFrame: bars.statusBarFrame
        )
    }

    private func barFrames(in app: XCUIApplication) -> BarFrames {
        let windowFrame = app.windows.firstMatch.exists ? app.windows.firstMatch.frame : CGRect(x: 0, y: 0, width: 0, height: 0)
        let navBar = app.navigationBars.firstMatch
        let navigationFrame = navBar.exists ? navBar.frame : CGRect(x: windowFrame.minX, y: windowFrame.minY, width: windowFrame.width, height: 0)
        let statusBar = app.statusBars.firstMatch
        let statusFrame: CGRect
        if statusBar.exists {
            statusFrame = statusBar.frame
        } else {
            statusFrame = CGRect(
                x: windowFrame.minX,
                y: windowFrame.minY,
                width: windowFrame.width,
                height: max(0, navigationFrame.minY - windowFrame.minY)
            )
        }
        return BarFrames(navigationBarFrame: navigationFrame, statusBarFrame: statusFrame)
    }

    private func bundledFrenchQuestionTexts(forCategoryID categoryID: String) throws -> Set<String> {
        let questions = try bundledQuestions()
        return Set(
            questions.compactMap { question in
                guard question.categoryId == categoryID else { return nil }
                return question.text.fr
            }
        )
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
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "-")
        return "\(timestamp)-\(UUID().uuidString.prefix(8))"
    }
}

private enum AuditScreen: String, Hashable {
    case categoryList = "category-list"
    case answeredPractice = "answered-practice"
}

private enum AuditAppearance: String, Hashable {
    case light
    case dark
}

private enum AuditPass: String, Hashable {
    case top
    case scrolled
}

private struct AuditContext: Hashable {
    let screen: AuditScreen
    let appearance: AuditAppearance
    let pass: AuditPass
    let questionID: String?
    let iterationID: String

    var evidenceStem: String {
        let questionPart = questionID.map { "-question-\($0)" } ?? ""
        return "\(screen.rawValue)-\(appearance.rawValue)-\(pass.rawValue)-iteration-\(iterationID)\(questionPart)"
    }
}

private struct AuditCoverageKey: Hashable {
    let screen: AuditScreen
    let appearance: AuditAppearance
    let questionID: String?

    init(context: AuditContext) {
        self.screen = context.screen
        self.appearance = context.appearance
        self.questionID = context.questionID
    }
}

private struct AuditInterest {
    let name: String
    let element: XCUIElement
    let required: Bool
    let enforcesVisibility: Bool

    init(name: String, element: XCUIElement, required: Bool = true, enforcesVisibility: Bool = true) {
        self.name = name
        self.element = element
        self.required = required
        self.enforcesVisibility = enforcesVisibility
    }
}

private struct AuditElementKey: Hashable {
    let identity: String

    @MainActor
    init(element: XCUIElement) {
        let identifier = element.identifier
        if !identifier.isEmpty {
            identity = "identifier:\(identifier)"
        } else {
            identity = "label:\(element.label)"
        }
    }
}

private enum AuditElementVisibilityStatus: String {
    case fullyVisibleBelowBars = "fully-visible-below-bars"
    case entirelyOffscreenOrUnderBars = "entirely-offscreen-or-under-bars"
    case partiallyObscuredOrClipped = "partially-obscured-or-clipped"
    case missing
}

private struct AuditElementPositionRecord {
    let interest: AuditInterest
    let key: AuditElementKey?
    let frame: CGRect
    let status: AuditElementVisibilityStatus
    let detail: String
}

private struct BarFrames {
    let navigationBarFrame: CGRect
    let statusBarFrame: CGRect

    var protectedMaxY: CGFloat {
        max(navigationBarFrame.maxY, statusBarFrame.maxY)
    }
}

private struct BarOcclusionProof {
    let isOccluded: Bool
    let intersectsNavigationBar: Bool
    let intersectsStatusBar: Bool
    let recordedElementFrame: CGRect
    let auditReportedFrame: CGRect
    let navigationBarFrame: CGRect
    let statusBarFrame: CGRect

    var description: String {
        "recordedRealFrame=(\(recordedElementFrame)); auditReportedFrame=(\(auditReportedFrame)); navigationBarFrame=(\(navigationBarFrame)); statusBarFrame=(\(statusBarFrame)); intersectsNavigationBar=\(intersectsNavigationBar); intersectsStatusBar=\(intersectsStatusBar)"
    }
}

@available(iOS 17.0, *)
private struct AllowedAuditFinding {
    let screen: AuditScreen
    let appearance: AuditAppearance
    let identifier: String
    let auditType: XCUIAccessibilityAuditType
    let measuredRatio: Double
    let evidence: String

    var auditTypeName: String {
        if auditType == .contrast { return "contrast" }
#if os(iOS)
        if auditType == .textClipped { return "textClipped" }
#endif
        return String(describing: auditType)
    }
}

private struct AuditExclusionDecision {
    let isExcluded: Bool
    let kind: Kind
    let reason: String
    let proof: String
    let recordedFrame: CGRect
    let recordedStatus: String
    let recordedDetail: String

    enum Kind: String {
        case none
        case occludedByBar = "occluded-by-bar"
        case measuredAllowList = "measured-allow-list"
    }
}

private struct UITestQuestion: Decodable {
    let id: String
    let categoryId: String
    let subsectionId: String
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
