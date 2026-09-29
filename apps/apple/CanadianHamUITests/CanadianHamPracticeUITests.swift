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

    func testAccessibilityAuditCategoryListAndAnsweredPracticeScreen() throws {
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

    private func auditCategoryListAndAnsweredPracticeScreen(appearance: AuditAppearance) throws {
        let app = configuredApp()
        app.launchArguments += [
            "-CanadianHamInitialCategoryID", "B-001",
            "-CanadianHamPracticeQuestionID", auditPracticeQuestionID
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
            let records = verifyAuditElementPositions(interests(pass), context: context, in: app)
            recordVisibleAuditCoverage(records, context: context)
        }

        for pass in passes {
            prepare(pass)
            let context = AuditContext(screen: screen, appearance: appearance, pass: pass, questionID: questionID, iterationID: auditIterationID)
            let records = verifyAuditElementPositions(interests(pass), context: context, in: app)
            recordVisibleAuditCoverage(records, context: context)
            captureScreenEvidence(named: "\(context.evidenceStem)-accessibility-audit")
            try captureAccessibilityAudit(on: app, context: context)
        }
    }

    private func configuredApp() -> XCUIApplication {
        XCUIApplication()
    }

    private var auditPracticeQuestionID: String { "B-001-001-004" }

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
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
            app.scrollViews.firstMatch.swipeUp()
            waitBriefly()
            XCTAssertTrue(isFullyVisible(nextQuestionButton, in: app, requiresHittable: true), "Next question button should be visible for the scrolled audit pass")
        }
    }

    private func categoryListAuditInterests(pass: AuditPass, in app: XCUIApplication) -> [AuditInterest] {
        switch pass {
        case .top:
            return [
                AuditInterest(name: "Practice categories header", element: app.staticTexts["Practice categories"].firstMatch),
                AuditInterest(name: "First category title", element: app.staticTexts["Regulations and Policies"].firstMatch),
                AuditInterest(name: "First category count", element: app.staticTexts["199 questions • 26 subsections"].firstMatch, required: false)
            ]
        case .scrolled:
            return [
                AuditInterest(name: "Last category title", element: app.staticTexts["Interference and Suppression"].firstMatch),
                AuditInterest(name: "Last category count", element: app.staticTexts["62 questions • 10 subsections"].firstMatch, required: false)
            ]
        }
    }

    private func answeredPracticeAuditInterests(pass: AuditPass, in app: XCUIApplication) -> [AuditInterest] {
        let any = app.descendants(matching: .any)
        switch pass {
        case .top:
            return [
                AuditInterest(name: "Practice category title", element: any["practice-category-title"].firstMatch),
                AuditInterest(name: "Practice category summary", element: any["practice-category-summary"].firstMatch),
                AuditInterest(name: "Practice session tally", element: any["practice-session-tally"].firstMatch),
                AuditInterest(name: "Question identifier", element: any["question-identifier"].firstMatch),
                AuditInterest(name: "Question stem", element: any["question-stem"].firstMatch),
                AuditInterest(name: "Answers heading", element: any["answers-title"].firstMatch),
                AuditInterest(name: "Answer A", element: any["answer-A-button"].firstMatch),
                AuditInterest(name: "Answer A text", element: any["answer-A-text"].firstMatch),
                AuditInterest(name: "Answer A chip", element: any["answer-A-chip"].firstMatch),
                AuditInterest(name: "Answer B", element: any["answer-B-button"].firstMatch),
                AuditInterest(name: "Answer B text", element: any["answer-B-text"].firstMatch),
                AuditInterest(name: "Answer B chip", element: any["answer-B-chip"].firstMatch)
            ]
        case .scrolled:
            return [
                AuditInterest(name: "Answer C", element: any["answer-C-button"].firstMatch),
                AuditInterest(name: "Answer C text", element: any["answer-C-text"].firstMatch),
                AuditInterest(name: "Answer C chip", element: any["answer-C-chip"].firstMatch),
                AuditInterest(name: "Answer D", element: any["answer-D-button"].firstMatch),
                AuditInterest(name: "Answer D text", element: any["answer-D-text"].firstMatch),
                AuditInterest(name: "Answer D chip", element: any["answer-D-chip"].firstMatch),
                AuditInterest(name: "Answer feedback", element: any["answer-feedback"].firstMatch),
                AuditInterest(name: "Answer feedback title", element: any["answer-feedback-title"].firstMatch),
                AuditInterest(name: "Answer feedback correct answer", element: any["answer-feedback-correct-answer"].firstMatch, required: false),
                AuditInterest(name: "Answer feedback source", element: any["answer-feedback-source"].firstMatch),
                AuditInterest(name: "Next question", element: app.buttons["Next question"].firstMatch)
            ]
        }
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

    private func captureAccessibilityAudit(on app: XCUIApplication, context: AuditContext) throws {
        if #available(iOS 17.0, *) {
            var findings: [String] = []
            var occludedFindings: [String] = []
            var auditError: Error?
            defer {
                attachAuditFindings(findings, occludedFindings: occludedFindings, context: context, error: auditError, app: app)
            }
            do {
                try app.performAccessibilityAudit { issue in
                    let exclusion = self.exclusionDecision(for: issue, context: context, app: app)
                    let description = self.describe(issue, exclusion: exclusion)
                    findings.append(description)
                    if exclusion.kind == .occludedByBar {
                        occludedFindings.append(description)
                    }
                    return exclusion.isExcluded
                }
            } catch {
                auditError = error
                throw error
            }
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
    private func exclusionDecision(for issue: XCUIAccessibilityAuditIssue, context: AuditContext, app: XCUIApplication) -> AuditExclusionDecision {
        let identifier = issue.element?.identifier ?? ""
        if let element = issue.element {
            let occlusion = occlusionProof(for: element.frame, in: app)
            if occlusion.isOccluded {
                let coveredInOtherPass = isCoveredFullyVisibleInOtherPass(element: element, context: context)
                return AuditExclusionDecision(
                    isExcluded: coveredInOtherPass,
                    kind: .occludedByBar,
                    reason: coveredInOtherPass ? "Excluded because the same element is fully visible in the other \(context.screen.rawValue) pass." : "Not excluded because no other pass audited the same element while fully visible.",
                    proof: occlusion.description
                )
            }
        }

        if let allowed = allowedAuditFindings.first(where: { allowed in
            allowed.screen == context.screen
                && allowed.appearance == context.appearance
                && allowed.identifier == identifier
                && allowed.auditType == issue.auditType
        }) {
            return AuditExclusionDecision(
                isExcluded: true,
                kind: .measuredAllowList,
                reason: "Excluded by measured \(allowed.auditTypeName) tuple with ratio \(String(format: "%.2f", allowed.measuredRatio)):1.",
                proof: allowed.evidence
            )
        }

        return AuditExclusionDecision(isExcluded: false, kind: .none, reason: "No occlusion coverage or measured allow-list tuple.", proof: "")
    }

    @available(iOS 17.0, *)
    private var allowedAuditFindings: [AllowedAuditFinding] {
        [
            AllowedAuditFinding(
                screen: .answeredPractice,
                appearance: .dark,
                identifier: "question-identifier",
                auditType: .contrast,
                measuredRatio: 10.82,
                evidence: "Measured in the exported three-iteration audit evidence from text/background clusters #FCD8CC / #3C241E inside the element frame; frame does not intersect the navigation or status bars."
            )
        ]
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
        return """
        auditType: \(issue.auditType)
        auditTypeName: \(auditTypeName(issue.auditType))
        element.identifier: \(identifier)
        element.label: \(label)
        element.elementType: \(elementType)
        element.frame: \(frame)
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
            "Rule: every audited element of interest must be fully below navigationBar.maxY/statusBar.maxY within the window or entirely off-screen/under the bars before performAccessibilityAudit()."
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

            let detail = "\(interest.name): \(status.rawValue); identifier=\(element.identifier); label=\(element.label); frame=\(frameDescription(frame)); navBar.maxY=\(bars.navigationBarFrame.maxY); statusBar.maxY=\(bars.statusBarFrame.maxY)"
            lines.append(detail)
            if status == .partiallyObscuredOrClipped {
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

    private func isCoveredFullyVisibleInOtherPass(element: XCUIElement, context: AuditContext) -> Bool {
        let key = AuditCoverageKey(context: context)
        let elementKey = AuditElementKey(element: element)
        guard let passCoverage = visibleAuditCoverage[key] else { return false }
        return passCoverage.contains { pass, elements in
            pass != context.pass && elements.contains(elementKey)
        }
    }

    private func occlusionProof(for frame: CGRect, in app: XCUIApplication) -> BarOcclusionProof {
        let bars = barFrames(in: app)
        let intersectsNavigationBar = frame.intersects(bars.navigationBarFrame)
        let intersectsStatusBar = frame.intersects(bars.statusBarFrame)
        let isAboveProtectedTop = frame.maxY <= bars.protectedMaxY
        return BarOcclusionProof(
            isOccluded: intersectsNavigationBar || intersectsStatusBar || isAboveProtectedTop,
            intersectsNavigationBar: intersectsNavigationBar,
            intersectsStatusBar: intersectsStatusBar,
            isAboveProtectedTop: isAboveProtectedTop,
            elementFrame: frame,
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

    init(name: String, element: XCUIElement, required: Bool = true) {
        self.name = name
        self.element = element
        self.required = required
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
            identity = "type:\(String(describing: element.elementType))|label:\(element.label)"
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
    let isAboveProtectedTop: Bool
    let elementFrame: CGRect
    let navigationBarFrame: CGRect
    let statusBarFrame: CGRect

    var description: String {
        "elementFrame=(\(elementFrame)); navigationBarFrame=(\(navigationBarFrame)); statusBarFrame=(\(statusBarFrame)); intersectsNavigationBar=\(intersectsNavigationBar); intersectsStatusBar=\(intersectsStatusBar); isAboveProtectedTop=\(isAboveProtectedTop)"
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

    enum Kind: String {
        case none
        case occludedByBar = "occluded-by-bar"
        case measuredAllowList = "measured-allow-list"
    }
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
