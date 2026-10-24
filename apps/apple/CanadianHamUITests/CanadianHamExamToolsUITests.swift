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
#if os(iOS)
        XCUIDevice.shared.orientation = .portrait
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
#endif
        try super.tearDownWithError()
    }

    func testM1QuizRoundsLightAndFullAccessibilityAudits() throws {
        try verifyM1RoundAccessibility(appearance: "light", french: false, largestType: false)
    }

    func testM1QuizRoundsDarkAndFullAccessibilityAudits() throws {
        try verifyM1RoundAccessibility(appearance: "dark", french: false, largestType: false)
    }

    func testM1QuizRoundsFrenchLargestTypeLightAndFullAccessibilityAudits() throws {
        try verifyM1RoundAccessibility(appearance: "light", french: true, largestType: true)
    }

    func testM1QuizRoundsFrenchLargestTypeDarkAndFullAccessibilityAudits() throws {
        try verifyM1RoundAccessibility(appearance: "dark", french: true, largestType: true)
    }

    // Coordinator decision 2026-10-24 under owner delegation 2026-10-22 (AGENTS.md TASK-71/73).
    private func auditM1RoundsIgnoringOccludedOrMeasuredContrast(app: XCUIApplication) throws {
        let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)
        let windowFrame = app.windows.firstMatch.frame
        let navigationBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(
            navigationBar.exists ? navigationBar.frame.maxY : windowFrame.minY,
            statusBar.exists ? statusBar.frame.maxY : windowFrame.minY
        )
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            let isOccluded = { () -> Bool in
                guard let element = issue.element else { return false }
                let frame = element.frame
                guard frame.width > 0, frame.height > 0 else { return false }
                guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
                guard self.element(element, withFrame: frame, isDescendantOf: auditGeometry.scrollView) else { return false }
                guard !auditGeometry.visibleScrollArea.contains(frame) else { return false }

                XCTContext.runActivity(named: "Ignored occluded lesson scroll-content contrast false positive") { activity in
                    let note = "label=\(element.label) frame=\(self.frameDescription(frame)) visibleScrollArea=\(self.frameDescription(auditGeometry.visibleScrollArea)) scrollFrame=\(self.frameDescription(auditGeometry.scrollFrame)) matchedScrollDescendant=true"
                    let attachment = XCTAttachment(string: note)
                    attachment.lifetime = .keepAlways
                    activity.add(attachment)
                }
                return true
            }()
            if isOccluded { return true }

            let element = issue.element
            let frame = element?.frame
            var measurement = ControlTextContrastMeasurement(fullImageRatio: nil, ratio: nil)
            if let element, let frame,
               isFullyVisibleForContrastMeasurement(frame: frame, windowFrame: windowFrame, protectedMaxY: protectedMaxY),
               let image = contrastMeasurementCGImage(from: element.screenshot()) {
                measurement = controlTextContrastMeasurement(
                    in: image, scale: CGFloat(image.width) / frame.width,
                    isButton: element.elementType == .button
                )
            }
            let verified = measurement.ratio.map { $0 >= 4.5 } ?? false
            let activityName = verified ? "Verified contrast audit finding with measured WCAG contrast" : "Failed contrast audit finding"
            XCTContext.runActivity(named: activityName) { activity in
                let attachment = XCTAttachment(string: "label=\(element?.label ?? "<nil>") frame=\(frame.map { "\($0)" } ?? "<nil>") \(measurement.logDescription)")
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return verified
        }
    }

    private func launchM1Rounds(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchApp(appearance: appearance, arguments: [
            "-CanadianHamInitialLessonQuizID", "QZ-L-001-01-A",
            "-CanadianHamLessonQuizLimit", "6", "-CanadianHamLessonQuizSeed", "m1-rounds",
            "-CanadianHamExamToolInitialDetent", "large"
        ] + extraArguments)
    }

    private func verifyM1RoundAccessibility(appearance: String, french: Bool, largestType: Bool) throws {
        // Deliberately mismatch bank and interface languages: round chrome and title follow the interface.
        var arguments = ["-AppleLanguages", french ? "(fr)" : "(en)", "-AppleLocale", french ? "fr_CA" : "en_CA", "-CanadianHamLanguage", french ? "en" : "fr"]
        if largestType {
            arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        let app = launchM1Rounds(appearance: appearance, extraArguments: arguments)
        defer { app.terminate() }
        let heading = app.staticTexts["lesson-quiz-round-heading"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10))
        XCTAssertTrue(heading.label.hasPrefix(french ? "Série 1 sur 4" : "Round 1 of 4"))
        XCTAssertTrue(heading.label.contains(french ? "L’autorité provient de sources désignées" : "Authority comes from named sources"))
        positionConceptFeedback([heading], in: app)
        XCTAssertTrue(isFullyVisible(heading, in: app, requiresHittable: true), "The full round title must wrap at the requested Dynamic Type size")
        try auditM1RoundsIgnoringOccludedOrMeasuredContrast(app: app)
        let next = app.buttons[french ? "Suivant" : "Next"].firstMatch
        for _ in 0..<5 {
            positionConceptFeedback([next], in: app)
            next.tap()
        }
        let checkpoint = app.staticTexts["lesson-quiz-round-checkpoint"].firstMatch
        XCTAssertTrue(checkpoint.waitForExistence(timeout: 5))
        XCTAssertEqual(checkpoint.label, french ? "Bilan de la série 1 sur 4" : "Round 1 of 4 checkpoint")
        XCTAssertTrue(app.staticTexts[french ? "Faits de référence : L’autorité provient de sources désignées" : "Reference facts: Authority comes from named sources"].firstMatch.exists)
        positionConceptFeedback([checkpoint], in: app)
        XCTAssertTrue(isFullyVisible(checkpoint, in: app, requiresHittable: true))
        try auditM1RoundsIgnoringOccludedOrMeasuredContrast(app: app)
        let score = app.staticTexts["lesson-quiz-round-score"].firstMatch
        XCTAssertEqual(score.label, french ? "Score actuel : 0 / 5. Réponses : 0 / 5." : "Score so far: 0 / 5. Answered: 0 / 5.")
        positionConceptFeedback([score], in: app)
        XCTAssertTrue(isFullyVisible(score, in: app, requiresHittable: true))
        let continueButton = app.buttons["lesson-quiz-round-continue"].firstMatch
        XCTAssertEqual(continueButton.label, french ? "Continuer à la série suivante" : "Continue to next round")
        positionConceptFeedback([continueButton], in: app)
        continueButton.tap()
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        XCTAssertTrue(heading.label.hasPrefix(french ? "Série 2 sur 4" : "Round 2 of 4"))
        XCTAssertFalse(checkpoint.exists)
        positionConceptFeedback([heading], in: app)
        try auditM1RoundsIgnoringOccludedOrMeasuredContrast(app: app)
        XCTAssertFalse(app.buttons["submit-lesson-quiz-button"].firstMatch.isEnabled, "Unanswered navigation must not submit or complete the quiz")
    }

    func testM1QuizRoundsKeepHelpAnswersResumeAndOneSavedAttempt() throws {
        var app = launchM1Rounds(extraArguments: ["-AppleLanguages", "(en)"])
        let heading = app.staticTexts["lesson-quiz-round-heading"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10))
        openTool(.hint, in: app)
        let reveal = app.buttons["hint-show-level-1-button"].firstMatch
        scrollExamToolUntilHittable(reveal, in: app, maxSwipes: 8)
        reveal.tap()
        waitBriefly(0.8)
        closeTool(in: app)
        // Fixed IDs and answer letters pin this UI fixture to the m1-rounds seed; a seed change fails loudly.
        let ids = ["B-001-001-003", "B-001-001-004", "B-001-003-004", "B-001-001-002", "B-001-001-001", "B-001-022-004"]
        let correctLetters = ["D", "B", "C", "C", "A", "D"]
        for index in 0..<6 {
            XCTAssertEqual(app.staticTexts["question-identifier"].firstMatch.label, ids[index])
            let answer = app.buttons["answer-\(correctLetters[index])-button"].firstMatch
            positionConceptFeedback([answer], in: app)
            answer.tap()
            XCTAssertTrue(app.staticTexts["answer-feedback-title"].firstMatch.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["answer-feedback-title"].firstMatch.label, "Correct")
            if index == 0 {
                XCTAssertTrue(app.staticTexts["lesson-quiz-with-help-marker"].firstMatch.exists)
            }
            if index < 5 {
                let next = app.buttons["Next"].firstMatch
                positionConceptFeedback([next], in: app)
                next.tap()
            }
            if index == 4 {
                XCTAssertEqual(app.staticTexts["lesson-quiz-round-score"].firstMatch.label, "Score so far: 5 / 5. Answered: 5 / 5.")
                let continueButton = app.buttons["lesson-quiz-round-continue"].firstMatch
                positionConceptFeedback([continueButton], in: app)
                continueButton.tap()
                XCTAssertTrue(heading.label.hasPrefix("Round 2 of 4"))
                let question = app.staticTexts["question-stem"].firstMatch
                let original = question.label
                // A current-lesson hint link pushes the section, then returns to this same session.
                openTool(.hint, in: app)
                let reveal = app.buttons["hint-show-level-1-button"].firstMatch
                scrollExamToolUntilHittable(reveal, in: app, maxSwipes: 8)
                reveal.tap()
                waitBriefly(0.8)
                let link = app.buttons["hint-review-in-lesson-button"].firstMatch
                scrollExamToolUntilHittable(link, in: app, maxSwipes: 12)
                link.tap()
                XCTAssertTrue(app.staticTexts["lesson-heading-reference-facts-qualifications-follow-a-learning-path"].firstMatch.waitForExistence(timeout: 10))
                app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
                XCTAssertTrue(heading.waitForExistence(timeout: 10))
                XCTAssertTrue(heading.label.hasPrefix("Round 2 of 4"))
                XCTAssertEqual(question.label, original)
                XCTAssertFalse(app.staticTexts["lesson-quiz-round-checkpoint"].exists, "Resume must not reopen a dismissed checkpoint")
                let previous = app.buttons["Previous"].firstMatch
                positionConceptFeedback([previous], in: app)
                previous.tap()
                XCTAssertEqual(app.staticTexts["question-identifier"].firstMatch.label, ids[4])
                // AnswerChoiceButton freezes interaction via hit testing, not the enabled trait.
                XCTAssertTrue(app.buttons["answer-A-button"].firstMatch.isSelected)
                XCTAssertEqual(app.staticTexts["answer-feedback-title"].firstMatch.label, "Correct")
                let next = app.buttons["Next"].firstMatch
                positionConceptFeedback([next], in: app)
                next.tap()
                positionConceptFeedback([continueButton], in: app)
                continueButton.tap()
            }
        }
        // The second hint round trip occurred before the sixth choice, so both choices used help.
        let submit = app.buttons["submit-lesson-quiz-button"].firstMatch
        positionConceptFeedback([submit], in: app)
        XCTAssertTrue(submit.isEnabled)
        submit.tap()
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.waitForExistence(timeout: 10))
        positionConceptFeedback([app.staticTexts["lesson-quiz-help-summary"].firstMatch], in: app)
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.label.contains("6 / 6 (100%). Attempts saved: 1."))
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 2.")
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-CanadianHamInitialLessonQuizID", "QZ-L-001-01-A", "-AppleLanguages", "(en)"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.label.contains("6 / 6 (100%). Attempts saved: 1."))
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 2.")
    }

    func testLessonQuizConceptOptionCorrectLightAndFullAccessibilityAudit() throws {
        try verifyConceptOptionFeedback(appearance: "light", correct: true, french: false)
    }

    func testLessonQuizConceptOptionCorrectDarkAndFullAccessibilityAudit() throws {
        try verifyConceptOptionFeedback(appearance: "dark", correct: true, french: false)
    }

    func testLessonQuizConceptOptionIncorrectFrenchFallbackLightAndFullAccessibilityAudit() throws {
        try verifyConceptOptionFeedback(appearance: "light", correct: false, french: true)
    }

    func testLessonQuizConceptOptionIncorrectFrenchFallbackDarkAndFullAccessibilityAudit() throws {
        try verifyConceptOptionFeedback(appearance: "dark", correct: false, french: true)
    }

    func testLessonQuizConceptOptionFeedbackLargestDynamicType() throws {
        let app = launchLessonQuiz(seed: "lesson-hints-15", extraArguments: [
            "-AppleLanguages", "(en)",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        defer { app.terminate() }
        let answer = app.buttons["lesson-quiz-choice-B-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["lesson-quiz-feedback-status"].exists)
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 20)
        answer.tap()
        let status = app.staticTexts["lesson-quiz-feedback-status"].firstMatch
        positionConceptFeedback([status], in: app)
        waitBriefly(0.8)
        XCTAssertEqual(status.label, "Correct. 820 / 1 000 = 0.82 A, so only the display unit differs.")
        XCTAssertTrue(isFullyVisible(status, in: app, requiresHittable: true), "Feedback must wrap without truncation at AX-XXXL")
        try auditIgnoringOccludedOrMeasuredContrast(app: app)
        let explanation = app.staticTexts["lesson-quiz-feedback-explanation"].firstMatch
        positionConceptFeedback([explanation], in: app)
        waitBriefly(0.8)
        XCTAssertEqual(explanation.label, "Compare values only after expressing them in the same unit.")
        XCTAssertTrue(isFullyVisible(explanation, in: app, requiresHittable: true), "Explanation must be fully visible after the audit's scroll changes. Frame: \(frameDescription(explanation.frame))")
        try auditIgnoringOccludedOrMeasuredContrast(app: app)
    }

    private func verifyConceptOptionFeedback(appearance: String, correct: Bool, french: Bool) throws {
        // Real shared seeded shuffle: C1 source order [3, 1, 0, 2]. A is source 3, not source 0.
        let app = launchLessonQuiz(seed: "lesson-hints-15", appearance: appearance, extraArguments: [
            "-AppleLanguages", french ? "(fr)" : "(en)", "-AppleLocale", french ? "fr_CA" : "en_CA"
        ])
        defer { app.terminate() }
        let answer = app.buttons[correct ? "lesson-quiz-choice-B-button" : "lesson-quiz-choice-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertTrue(answer.label.contains(correct ? "They describe the same current." : "The readings differ by a factor of one hundred."))
        XCTAssertFalse(app.staticTexts["lesson-quiz-feedback-status"].exists)
        XCTAssertFalse(app.staticTexts["lesson-quiz-feedback-explanation"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "so only the display unit differs.")).firstMatch.exists)
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 15)
        try auditIgnoringOccludedOrMeasuredContrast(app: app)
        answer.tap()
        let status = app.staticTexts["lesson-quiz-feedback-status"].firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        let correctness = french ? "Mauvaise réponse." : "Correct."
        let optionFeedback = correct
            ? "820 / 1 000 = 0.82 A, so only the display unit differs."
            : "This treats milli as a tenfold step. It is a thousandth of an ampere."
        XCTAssertEqual(status.label, "\(correctness) \(optionFeedback)")
        let explanation = app.staticTexts["lesson-quiz-feedback-explanation"].firstMatch
        XCTAssertEqual(explanation.label, "Compare values only after expressing them in the same unit.")
        positionConceptFeedback([status, explanation], in: app)
        XCTAssertTrue(isFullyVisible(status, in: app, requiresHittable: true))
        XCTAssertTrue(isFullyVisible(explanation, in: app, requiresHittable: true))
        // Keep the full default audit with only the two owner-approved contrast rules.
        try auditIgnoringOccludedOrMeasuredContrast(app: app)
    }

    // Owner decisions 2026-10-12 and 2026-10-22 (TASK-71); only the new concept-option audits.
    private func auditIgnoringOccludedOrMeasuredContrast(app: XCUIApplication) throws {
        let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)
        let windowFrame = app.windows.firstMatch.frame
        let navigationBar = app.navigationBars.firstMatch
        let statusBar = app.statusBars.firstMatch
        let protectedMaxY = max(
            navigationBar.exists ? navigationBar.frame.maxY : windowFrame.minY,
            statusBar.exists ? statusBar.frame.maxY : windowFrame.minY
        )
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            let isOccluded = { () -> Bool in
                guard let element = issue.element else { return false }
                let frame = element.frame
                guard frame.width > 0, frame.height > 0 else { return false }
                guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
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
            if isOccluded() { return true }

            let element = issue.element
            let frame = element?.frame
            var ratio: Double?
            if let element, let frame,
               isFullyVisibleForContrastMeasurement(frame: frame, windowFrame: windowFrame, protectedMaxY: protectedMaxY),
               let image = contrastMeasurementCGImage(from: element.screenshot()) {
                ratio = measuredTextContrast(in: image)
            }
            let verified = ratio.map { $0 >= 4.5 } ?? false
            let activityName = verified ? "Verified contrast audit finding with measured WCAG contrast" : "Failed contrast audit finding"
            XCTContext.runActivity(named: activityName) { activity in
                let measurement = ratio.map { "\($0):1" } ?? "unmeasurable"
                let attachment = XCTAttachment(string: "label=\(element?.label ?? "<nil>") frame=\(frame.map { "\($0)" } ?? "<nil>") ratio=\(measurement)")
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return verified
        }
    }

    private func positionConceptFeedback(_ elements: [XCUIElement], in app: XCUIApplication) {
        for _ in 0..<24 where !elements.allSatisfy({ isFullyVisible($0, in: app, requiresHittable: true) }) {
            let visibleFrame = visibleFrameExcludingNavigationBar(in: app)
            let top = elements.map(\.frame.minY).min() ?? visibleFrame.minY
            let bottom = elements.map(\.frame.maxY).max() ?? visibleFrame.maxY
            let scroll = scrollView(containing: elements[0], in: app)
            // Audits can scroll back to the quiz header. Cover long distances before fine positioning.
            if top > visibleFrame.maxY {
                scroll.swipeUp()
            } else if bottom < visibleFrame.minY {
                scroll.swipeDown()
            } else {
                preciseExamToolScroll(scroll, in: app, fingerDeltaY: top < visibleFrame.minY ? 72 : -72)
            }
            waitBriefly()
        }
    }

    func testLessonQuizHintsLightAndFullAccessibilityAudits() throws {
        try verifyLessonQuizHintsAndAudits(appearance: "light")
    }

    func testLessonQuizHintsDarkAndFullAccessibilityAudits() throws {
        try verifyLessonQuizHintsAndAudits(appearance: "dark")
    }

    func testLessonQuizHintsFrenchAndCurrentLessonRoundTrip() throws {
        let app = launchLessonQuiz(extraArguments: ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_CA"])
        defer { app.terminate() }
        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        let original = question.label
        openTool(.hint, in: app)
        XCTAssertEqual(app.buttons["hint-show-level-1-button"].firstMatch.label, "Afficher l’indice 1")
        revealBothHints(in: app)
        let notice = app.staticTexts["hint-english-only-lesson-notice"].firstMatch
        scrollExamToolUntilHittable(notice, in: app, maxSwipes: 8)
        XCTAssertTrue(notice.exists)
        let link = app.buttons["hint-review-in-lesson-button"].firstMatch
        scrollExamToolUntilHittable(link, in: app, maxSwipes: 8)
        link.tap()
        XCTAssertTrue(app.descendants(matching: .any)["lesson-heading-the-metric-prefix-ladder"].firstMatch.waitForExistence(timeout: 10))
        app.navigationBars.firstMatch.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        XCTAssertEqual(question.label, original)
        openTool(.hint, in: app)
        let secondHint = app.staticTexts["hint-level-2-title"].firstMatch
        let hintScroll = app.scrollViews["hint-tool-scroll"].firstMatch
        XCTAssertTrue(hintScroll.waitForExistence(timeout: 5))
        for _ in 0..<10 where !secondHint.isHittable {
            hintScroll.swipeUp()
            waitBriefly()
        }
        XCTAssertTrue(secondHint.isHittable, "The restored Hint 2 must be reachable in the reopened panel")
        closeTool(in: app)
        chooseLessonQuizCorrectAnswer(in: app)
        let marker = app.staticTexts["lesson-quiz-with-help-marker"].firstMatch
        scrollBackgroundUntilHittable(marker, in: app, maxSwipes: 12)
        XCTAssertEqual(marker.label, "Réponse avec aide")
        submitLessonQuiz(in: app)
        XCTAssertTrue(app.staticTexts["lesson-quiz-help-summary"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Réponses avec aide : 1.")
    }

    func testLessonQuizOneLevelHintAndHelpCountPersistsAfterRelaunch() throws {
        var app = launchLessonQuiz(seed: "lesson-hints-2")
        openTool(.hint, in: app)
        let first = app.buttons["hint-show-level-1-button"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        XCTAssertTrue(app.buttons["hint-review-in-lesson-button"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["hint-show-level-2-button"].exists)
        waitBriefly(0.8)
        closeTool(in: app)
        let answer = app.buttons["answer-A-button"].firstMatch
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        answer.tap()
        submitLessonQuiz(in: app)
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 1.")
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-CanadianHamInitialLessonQuizID", "QZ-L-005-01-A", "-CanadianHamAppearance", "light", "-AppleLanguages", "(en)"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["lesson-quiz-help-summary"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 1.")
    }

    func testLessonQuizConceptCheckHasNoHintOrOtherTools() throws {
        let app = launchLessonQuiz(seed: "lesson-hints-15")
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["lesson-quiz-choice-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["exam-tool-hint-button"].exists)
        XCTAssertFalse(app.buttons["exam-tool-calculator-button"].exists)
        XCTAssertFalse(app.buttons["exam-tool-referenceSheet-button"].exists)
#if os(iOS)
        let title = app.staticTexts["QZ-L-005-01-A"].firstMatch
        let retry = app.buttons["Retry quiz"].firstMatch
        XCTAssertTrue(title.exists)
        XCTAssertTrue(retry.exists)
        XCTAssertGreaterThan(retry.frame.minX, title.frame.maxX, "The default-size quiz header keeps Retry alongside the title on iPhone and iPad")
        XCTAssertLessThan(retry.frame.minY, title.frame.maxY, "The default-size quiz header must not stack Retry below its text on iPhone or iPad")
        if UIDevice.current.userInterfaceIdiom == .pad {
            let previous = app.buttons["Previous"].firstMatch
            let next = app.buttons["Next"].firstMatch
            let submit = app.buttons["submit-lesson-quiz-button"].firstMatch
            scrollBackgroundUntilHittable(submit, in: app, maxSwipes: 12)
            XCTAssertTrue(previous.exists)
            XCTAssertTrue(next.exists)
            XCTAssertEqual(previous.frame.minY, next.frame.minY, accuracy: 1, "Default-size iPad quiz navigation must remain horizontal")
            XCTAssertLessThanOrEqual(previous.frame.maxX, next.frame.minX)
            XCTAssertLessThanOrEqual(next.frame.maxX, submit.frame.minX)
        }
#endif
    }

    func testLessonQuizPostChoiceHintsDoNotChangeSavedHelpAndRelaunchKeepsHelpCount() throws {
        var app = launchLessonQuiz()
        chooseLessonQuizCorrectAnswer(in: app)
        openTool(.hint, in: app)
        revealBothHints(in: app)
        waitBriefly(0.8)
        closeTool(in: app)
        XCTAssertFalse(app.staticTexts["lesson-quiz-with-help-marker"].exists)
        submitLessonQuiz(in: app)
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 0.")
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-CanadianHamInitialLessonQuizID", "QZ-L-005-01-A", "-CanadianHamAppearance", "light", "-AppleLanguages", "(en)"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["lesson-quiz-help-summary"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 0.")
    }

    func testLessonQuizHintLargestDynamicTypeAndLayoutRoundTrip() throws {
        let app = launchLessonQuiz(extraArguments: navigationTransitionArguments(initialSizeClass: "compact") + [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        defer { app.terminate() }
        openTool(.hint, in: app)
        revealBothHints(in: app)
        closeTool(in: app)
        let question = app.staticTexts["question-stem"].firstMatch
        let original = question.label
        applySimulatedSizeClassChange(in: app, expectedSizeClassValue: "regular", context: "lesson quiz hints at largest Dynamic Type")
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        XCTAssertEqual(question.label, original)
        let hintButton = app.buttons["exam-tool-hint-button"].firstMatch
        let layoutControl = app.buttons["debug-simulated-size-class-change-button"].firstMatch
        // At AX-XXXL the debug layout control overlaps the scroll content. Scroll the real Hint
        // button below that overlay rather than tapping through the test control.
        for _ in 0..<12 where hintButton.frame.minY <= layoutControl.frame.maxY + 12 {
            preciseExamToolScroll(app.scrollViews.firstMatch, in: app, fingerDeltaY: 72)
            waitBriefly()
        }
        XCTAssertGreaterThan(hintButton.frame.minY, layoutControl.frame.maxY)
        openTool(.hint, in: app)
        let secondHint = app.staticTexts["hint-level-2-title"].firstMatch
        let hintScroll = app.scrollViews["hint-tool-scroll"].firstMatch
        XCTAssertTrue(hintScroll.waitForExistence(timeout: 5))
        for _ in 0..<12 where !secondHint.isHittable {
            if secondHint.exists && secondHint.frame.minY < visibleFrameExcludingNavigationBar(in: app).minY {
                hintScroll.swipeDown()
            } else {
                hintScroll.swipeUp()
            }
            waitBriefly()
        }
        let restoredHintFrame = secondHint.exists ? frameDescription(secondHint.frame) : "missing"
        XCTAssertTrue(secondHint.isHittable, "The restored Hint 2 must be reachable in the reopened panel. Hint: \(restoredHintFrame); scroll: \(frameDescription(hintScroll.frame))")
        closeTool(in: app)
        chooseLessonQuizCorrectAnswer(in: app)
        let marker = app.staticTexts["lesson-quiz-with-help-marker"].firstMatch
        scrollBackgroundUntilHittable(marker, in: app, maxSwipes: 15)
        XCTAssertTrue(marker.isHittable)
        let previous = app.buttons["Previous"].firstMatch
        let next = app.buttons["Next"].firstMatch
        scrollBackgroundUntilHittable(next, in: app, maxSwipes: 15)
        XCTAssertTrue(previous.exists)
        XCTAssertTrue(next.exists)
        XCTAssertGreaterThanOrEqual(next.frame.minY, previous.frame.maxY, "AX-XXXL quiz navigation must fall back to a vertical stack")
    }

    private func launchLessonQuiz(seed: String = "lesson-hints-1", appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchApp(appearance: appearance, arguments: [
            "-CanadianHamInitialLessonQuizID", "QZ-L-005-01-A",
            "-CanadianHamLessonQuizLimit", "1", "-CanadianHamLessonQuizSeed", seed,
            "-CanadianHamExamToolInitialDetent", "large"
        ] + extraArguments)
    }

    private func chooseLessonQuizCorrectAnswer(in app: XCUIApplication) {
        // Shared seeded shuffle: B-005-001-001 has source order [3, 2, 0, 1].
        let correct = app.buttons["answer-C-button"].firstMatch
        XCTAssertTrue(correct.waitForExistence(timeout: 10))
        scrollBackgroundUntilHittable(correct, in: app, maxSwipes: 15)
        correct.tap()
        XCTAssertTrue(app.staticTexts["answer-feedback-title"].firstMatch.waitForExistence(timeout: 5))
    }

    private func submitLessonQuiz(in app: XCUIApplication) {
        let submit = app.buttons["submit-lesson-quiz-button"].firstMatch
        scrollBackgroundUntilHittable(submit, in: app, maxSwipes: 15)
        XCTAssertTrue(submit.isEnabled)
        submit.tap()
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.waitForExistence(timeout: 10))
        let summary = app.staticTexts["lesson-quiz-help-summary"].firstMatch
        let quizTitle = app.staticTexts["QZ-L-005-01-A"].firstMatch
        let quizScroll = app.scrollViews.firstMatch
        for _ in 0..<16 where !isFullyVisible(summary, in: app, requiresHittable: true) || !isFullyVisible(quizTitle, in: app, requiresHittable: true) {
            quizScroll.swipeDown()
            waitBriefly()
        }
        XCTAssertTrue(isFullyVisible(summary, in: app, requiresHittable: true), "Saved help summary must be fully visible below the navigation bar")
        XCTAssertTrue(isFullyVisible(quizTitle, in: app, requiresHittable: true), "Quiz title must not be clipped under the navigation bar")
    }

    private func verifyLessonQuizHintsAndAudits(appearance: String) throws {
        let app = launchLessonQuiz(appearance: appearance)
        defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["question-stem"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["exam-tool-calculator-button"].exists)
        XCTAssertFalse(app.buttons["exam-tool-referenceSheet-button"].exists)
        openTool(.hint, in: app)
        revealBothHints(in: app)
        XCTAssertFalse(app.descendants(matching: .any)["hint-reference-pointer"].exists)
        waitBriefly(0.8)
        try app.performAccessibilityAudit()
        closeTool(in: app)
        chooseLessonQuizCorrectAnswer(in: app)
        let marker = app.staticTexts["lesson-quiz-with-help-marker"].firstMatch
        let feedbackTitle = app.staticTexts["answer-feedback-title"].firstMatch
        scrollBackgroundUntilHittable(feedbackTitle, in: app, maxSwipes: 12)
        for _ in 0..<12 where !isFullyVisible(marker, in: app, requiresHittable: true) || !isFullyVisible(feedbackTitle, in: app, requiresHittable: true) {
            let top = min(marker.frame.minY, feedbackTitle.frame.minY)
            let delta: CGFloat = top < visibleFrameExcludingNavigationBar(in: app).minY ? 72 : -72
            preciseExamToolScroll(app.scrollViews.firstMatch, in: app, fingerDeltaY: delta)
            waitBriefly()
        }
        XCTAssertTrue(marker.isHittable)
        XCTAssertTrue(isFullyVisible(marker, in: app, requiresHittable: true), "Help marker must be fully visible before auditing feedback. Frame: \(frameDescription(marker.frame))")
        XCTAssertTrue(isFullyVisible(feedbackTitle, in: app, requiresHittable: true), "Feedback title must be fully visible before auditing it. Frame: \(frameDescription(feedbackTitle.frame))")
        try auditIgnoringOccludedLessonTextContrast(app: app)
        submitLessonQuiz(in: app)
        XCTAssertEqual(app.staticTexts["lesson-quiz-help-summary"].firstMatch.label, "Answers with help: 1.")
        XCTAssertTrue(app.staticTexts["lesson-quiz-latest-score"].firstMatch.label.contains("1 / 1 (100%)"), "Help must not reduce quiz correctness")
        try app.performAccessibilityAudit()
    }

    func testPracticeCalculatorSheetKeepsAnswersHittableAtMediumDetent() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5))
        waitBriefly(0.8)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "practice calculator sheet")
    }

    func testForcedRegularIPhoneLandscapeCalculatorUsesSheetAndKeepsSelection() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Forced-regular iPhone sheet persistence is covered by the targeted iPhone run.")
        XCUIDevice.shared.orientation = .landscapeLeft
        waitBriefly(0.8)
        defer {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
        }

        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before opening the calculator")
        let initialQuestionText = question.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before selecting an answer")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before selecting it")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before opening the calculator")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator sheet UI after opening the calculator")
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape after open")
        waitBriefly(1.0)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.exists, "The calculator sheet should still be open after SwiftUI settles")
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape after settle")
        XCTAssertEqual(question.label, initialQuestionText, "Opening the calculator sheet must not rebuild to a different question")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Opening the calculator sheet must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Opening the calculator sheet must preserve the selected answer state")
#else
        throw XCTSkip("Forced-regular iPhone sheet persistence is iOS-only.")
#endif
    }

    func testForcedRegularIPhoneLandscapeMediumSheetScrollsEveryCalculatorKey() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Forced-regular iPhone landscape sheet scrolling is covered by the targeted iPhone run.")
        XCUIDevice.shared.orientation = .landscapeLeft
        waitBriefly(0.8)
        defer {
            XCUIDevice.shared.orientation = .portrait
            waitBriefly(0.8)
        }

        let app = launchPracticeQuestion(extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        openTool(.calculator, in: app)
        assertCalculatorPresentedAsSheet(in: app, context: "forced-regular iPhone landscape key reachability")
        let calculatorScrollView = calculatorScrollView(in: app, requiredFor: "landscape medium sheet key reachability", timeout: 5)
        XCTAssertEqual(calculatorScrollView.elementType, .scrollView, "Landscape medium sheets must wrap the calculator in a scroll view so keys scroll instead of shrinking below 44 pt")
        for identifier in calculatorKeyIdentifiers {
            let key = app.buttons[identifier].firstMatch
            scrollCalculatorPanelUntilElementExists(key, in: app, maxSwipes: 10)
            XCTAssertTrue(key.exists, "Expected calculator key \(identifier) to exist in the scrollable landscape sheet")
            scrollExamToolUntilHittable(key, in: app, maxSwipes: 10)
            XCTAssertTrue(key.isHittable, "Calculator key \(identifier) should be hittable after scrolling the landscape medium sheet. Frame: \(frameDescription(key.frame))")
            XCTAssertGreaterThanOrEqual(key.frame.height, 44, "Calculator key \(identifier) must preserve the 44 pt hit target while scrolling. Frame: \(frameDescription(key.frame))")
        }
#else
        throw XCTSkip("Forced-regular iPhone landscape sheet scrolling is iOS-only.")
#endif
    }

    func testReferenceSheetToolAvailableOnlyForBasic() throws {
        let app = launchPracticeQuestion()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertTrue(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists)
        XCTAssertTrue(app.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "Basic offers the official sheet and study fallback in task-44.4")

        let advancedApp = launchAdvancedPracticeQuestion()
        defer { advancedApp.terminate() }
        XCTAssertTrue(advancedApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(advancedApp.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(advancedApp.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Advanced course has no active Apple hints in task-50.12")
        XCTAssertFalse(advancedApp.buttons[Tool.referenceSheet.buttonIdentifier].firstMatch.exists, "Advanced course must not offer the Basic reference sheet")
    }

    func testOfficialReferenceSheetLightAndDarkEnglishAndFrench() throws {
        for language in ["en", "fr"] {
            for appearance in ["light", "dark"] {
                let app = launchPracticeQuestion(appearance: appearance, extraArguments: [
                    "-AppleLanguages", "(\(language))", "-AppleLocale", language == "fr" ? "fr_CA" : "en_CA",
                    "-CanadianHamExamToolInitialDetent", "large"
                ])
                defer { app.terminate() }
                openTool(.referenceSheet, in: app)
                let image = app.images["reference-sheet-official-page"].firstMatch
                XCTAssertTrue(image.waitForExistence(timeout: 5), "The official sheet should be the default")
                let zoom = app.buttons["reference-sheet-zoom-in"].firstMatch
                positionReferenceSheetControl(zoom, in: app)
                zoom.tap()
                XCTAssertEqual(app.staticTexts["reference-sheet-zoom-level"].firstMatch.label, "Zoom")
                XCTAssertEqual(zoom.value as? String, "150%")
                XCTAssertEqual(app.staticTexts["reference-sheet-zoom-level"].firstMatch.value as? String, "150%")
                let nextPage = app.buttons["reference-sheet-page-next"].firstMatch
                positionReferenceSheetControl(nextPage, in: app)
                XCTAssertEqual(nextPage.label, language == "fr" ? "Suivant" : "Next", "Page navigation follows the interface language")
                for _ in 0..<4 { nextPage.tap() }
                XCTAssertTrue(image.label.contains("page 5"), "All five PDF pages should be available offline")
                try app.performAccessibilityAudit()
                let text = app.switches["reference-sheet-text-equivalent"].firstMatch
                positionReferenceSheetControl(text, in: app)
                text.tap()
                XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-official-text"].firstMatch.waitForExistence(timeout: 5))
                try app.performAccessibilityAudit()
                let version = app.buttons["reference-sheet-version"].firstMatch
                positionReferenceSheetControl(version, in: app)
                version.tap()
                XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-study-text"].firstMatch.waitForExistence(timeout: 5))
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    try auditIgnoringOccludedReferenceSheetTextContrast(app: app)
                } else {
                    try app.performAccessibilityAudit()
                }
#else
                try app.performAccessibilityAudit()
#endif
                closeTool(in: app)
                XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.exists, "The question remains available after using the tool")
            }
        }
    }

    func testOfficialReferenceSheetMediumDetentControlsAndShowFullSheet() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "The medium-detent path is iPhone-only; iPad uses the reference inspector matrix.")
#endif
        let app = launchPracticeQuestion()
        defer { app.terminate() }
        openTool(.referenceSheet, in: app)
        let header = app.descendants(matching: .any)[Tool.referenceSheet.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        let mediumHeaderFrame = header.frame
        XCTAssertGreaterThan(mediumHeaderFrame.minY, app.windows.firstMatch.frame.height * 0.25, "This test must exercise the medium detent")
        let fullSheet = app.buttons["reference-sheet-show-full-sheet"].firstMatch
        positionReferenceSheetControl(fullSheet, in: app, dragColumn: 0.5)
        XCTAssertGreaterThanOrEqual(fullSheet.frame.width, 44)
        XCTAssertGreaterThanOrEqual(fullSheet.frame.height, 44)
        let image = app.images["reference-sheet-official-page"].firstMatch
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        let next = app.buttons["reference-sheet-page-next"].firstMatch
        positionReferenceSheetControl(next, in: app, dragColumn: 0.5)
        next.tap()
        XCTAssertTrue(image.label.contains("page 2"))
        let previous = app.buttons["reference-sheet-page-previous"].firstMatch
        positionReferenceSheetControl(previous, in: app, dragColumn: 0.5)
        previous.tap()
        XCTAssertTrue(image.label.contains("page 1"))
        let zoomIn = app.buttons["reference-sheet-zoom-in"].firstMatch
        positionReferenceSheetControl(zoomIn, in: app, dragColumn: 0.5)
        zoomIn.tap()
        XCTAssertEqual(zoomIn.value as? String, "150%")
        let zoomOut = app.buttons["reference-sheet-zoom-out"].firstMatch
        positionReferenceSheetControl(zoomOut, in: app, dragColumn: 0.5)
        zoomOut.tap()
        XCTAssertEqual(zoomOut.value as? String, "100%")
        let text = app.switches["reference-sheet-text-equivalent"].firstMatch
        positionReferenceSheetControl(text, in: app, dragColumn: 0.5)
        text.tap()
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-official-text"].firstMatch.waitForExistence(timeout: 5))
        text.tap()
        let version = app.buttons["reference-sheet-version"].firstMatch
        positionReferenceSheetControl(version, in: app, dragColumn: 0.5)
        version.tap()
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-study-text"].firstMatch.waitForExistence(timeout: 5))
        positionReferenceSheetControl(version, in: app, dragColumn: 0.5)
        version.tap()
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        positionReferenceSheetControl(fullSheet, in: app, dragColumn: 0.5)
        let referenceScroll = app.scrollViews["reference-sheet-scroll"].firstMatch
        guard referenceScroll.waitForExistence(timeout: 5) else {
            XCTFail("Expected reference-sheet-scroll; refusing to audit a different scroll view")
            return
        }
        XCTAssertGreaterThan(header.frame.minY, app.windows.firstMatch.frame.height * 0.25, "The exception is limited to the iPhone medium detent")
        XCTAssertEqual(header.frame.minY, mediumHeaderFrame.minY, accuracy: 6, "Scrolling the controls must not expand the medium sheet")
        var ignoredTextClippedIssues = 0
        let maximumIgnoredTextClippedIssues = 6 // TASK-67: five stable observed findings plus one of headroom; growth beyond that fails.
        // Owner decision 2026-10-12 permits larger-Dynamic-Type clipping inside medium-detent tool scroll content.
        // Keep the existing nil-element rule; named findings must match this explicit reference scroll view.
        try app.performAccessibilityAudit { issue in
#if os(iOS)
            guard UIDevice.current.userInterfaceIdiom == .phone, issue.auditType == .textClipped else { return false }
            if !self.isApprovedMediumDetentToolScrollTextClip(issue, in: app) {
                guard let element = issue.element,
                      self.element(element, withFrame: element.frame, isDescendantOf: referenceScroll) else { return false }
            }
            ignoredTextClippedIssues += 1
            let elementDescription = issue.element.map {
                "identifier=\($0.identifier) label=\($0.label) frame=\(self.frameDescription($0.frame))"
            } ?? "element=nil (the audit supplied no identifiable element)"
            let note = "\(ignoredTextClippedIssues)/\(maximumIgnoredTextClippedIssues): \(elementDescription); \(issue)"
            NSLog("Ignoring approved owner-decision-2026-10-12 iPhone medium-detent reference-scroll textClipped issue: %@", note)
            XCTContext.runActivity(named: "Approved medium-detent reference textClipped finding") { activity in
                let attachment = XCTAttachment(string: note)
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return ignoredTextClippedIssues <= maximumIgnoredTextClippedIssues
#else
            return false
#endif
        }
        XCTAssertLessThanOrEqual(ignoredTextClippedIssues, maximumIgnoredTextClippedIssues, "Medium-detent reference audit must retain a bounded cap")
        fullSheet.tap()
        waitBriefly(0.8)
        XCTAssertFalse(fullSheet.exists, "Show full sheet must expand the sheet and disappear")
        XCTAssertLessThan(header.frame.minY, mediumHeaderFrame.minY - 100)
        XCTAssertTrue(image.exists, "Expanding must preserve the official sheet")
    }

    func testReferenceSheetLargestDynamicTypeKeepsControlsReachable() throws {
        let app = launchPracticeQuestion(extraArguments: ["-AppleLanguages", "(en)", "-AppleLocale", "en_CA", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-CanadianHamExamToolInitialDetent", "large"])
        defer { app.terminate() }
        openTool(.referenceSheet, in: app)
        let version = app.buttons["reference-sheet-version"].firstMatch
        positionReferenceSheetControl(version, in: app)
        XCTAssertGreaterThanOrEqual(version.frame.height, 44)
        version.tap()
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-study-text"].firstMatch.waitForExistence(timeout: 5))
        positionReferenceSheetControl(version, in: app)
        version.tap()
        let image = app.images["reference-sheet-official-page"].firstMatch
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        let text = app.switches["reference-sheet-text-equivalent"].firstMatch
        positionReferenceSheetControl(text, in: app)
        XCTAssertEqual(app.switches.matching(identifier: "reference-sheet-text-equivalent").count, 1)
        XCTAssertEqual(text.label, "Text equivalent", "VoiceOver should announce the label exactly once")
        let labelPredicate = NSPredicate(format: "label == %@", "Text equivalent")
        // A native labelled switch can contain a StaticText child; only a label outside it is a duplicate focus stop.
        XCTAssertEqual(app.staticTexts.matching(labelPredicate).count, text.staticTexts.matching(labelPredicate).count, "No Text equivalent label may exist outside the single native switch")
        XCTContext.runActivity(named: "AX-XXXL native reference toggle accessibility hierarchy") { activity in
            let attachment = XCTAttachment(string: text.debugDescription)
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
        XCTAssertGreaterThanOrEqual(text.frame.height, 44)
        XCTAssertEqual(text.value as? String, "0")
        // The label is at the top of the stacked row, away from the native switch thumb.
        text.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertEqual(text.value as? String, "1", "Tapping the visible label must enable the text equivalent at AX-XXXL")
        XCTAssertTrue(app.descendants(matching: .any)["reference-sheet-official-text"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(image.exists)
        text.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        XCTAssertEqual(text.value as? String, "0", "Tapping the label again must restore the official image")
        XCTAssertTrue(image.waitForExistence(timeout: 5))
        let next = app.buttons["reference-sheet-page-next"].firstMatch
        positionReferenceSheetControl(next, in: app)
        XCTAssertGreaterThanOrEqual(next.frame.height, 44)
        next.tap()
        XCTAssertTrue(app.images["reference-sheet-official-page"].firstMatch.label.contains("page 2"))
        let zoom = app.buttons["reference-sheet-zoom-in"].firstMatch
        positionReferenceSheetControl(zoom, in: app)
        XCTAssertGreaterThanOrEqual(zoom.frame.height, 44)
        zoom.tap()
        XCTAssertEqual(app.staticTexts["reference-sheet-zoom-level"].firstMatch.value as? String, "150%")
        positionReferenceSheetControl(app.staticTexts["reference-sheet-version-title"].firstMatch, in: app)
        try auditIgnoringOccludedLessonTextContrast(app: app)
    }

    private func positionReferenceSheetControl(_ control: XCUIElement, in app: XCUIApplication, dragColumn: CGFloat = 0.85, file: StaticString = #filePath, line: UInt = #line) {
        let scroll = app.scrollViews["reference-sheet-scroll"].firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(control.waitForExistence(timeout: 5), file: file, line: line)
        for _ in 0..<30 {
            let frame = scroll.frame.intersection(app.windows.firstMatch.frame)
            let top = max(frame.minY, protectedNavigationFrame(in: app).maxY)
            let visible = CGRect(x: frame.minX, y: top, width: frame.width, height: max(0, frame.maxY - top))
            // Sheet transforms can differ by subpixel rounding at the shared leading edge.
            if visible.insetBy(dx: -0.5, dy: -0.5).contains(control.frame) {
                return
            }
            let distance: CGFloat = control.frame.midY < visible.midY ? 72 : -72
            // Use a blank column, not the Text equivalent switch thumb in the medium sheet.
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: dragColumn, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: distance)), withVelocity: XCUIGestureVelocity.slow, thenHoldForDuration: 0.4)
        }
        XCTFail("Reference-sheet control \(control.identifier) should be fully inside the visible scroll frame below navigation. Control: \(frameDescription(control.frame)); scroll: \(frameDescription(scroll.frame))", file: file, line: line)
    }

    func testLargestDynamicTypeKeepsHintToolButtonReachable() throws {
        let defaultApp = launchPracticeQuestion(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"])
        XCTAssertTrue(defaultApp.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        let defaultHint = defaultApp.buttons[Tool.hint.buttonIdentifier].firstMatch
        XCTAssertTrue(defaultHint.waitForExistence(timeout: 5), "Expected the hint button at the default text size")
        scrollExamToolUntilHittable(defaultHint, in: defaultApp, maxSwipes: 8)
        XCTAssertTrue(defaultHint.isHittable, "The default-size hint button should be visible before measuring it")
        XCTAssertEqual(defaultHint.label, "Hint", "The default-size hint button should expose its title exactly once")
        let defaultHintHeight = defaultHint.frame.height
        XCTAssertGreaterThan(defaultHintHeight, 0)
        defaultApp.terminate()

        let app = launchPracticeQuestion(extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        let calculator = app.buttons[Tool.calculator.buttonIdentifier].firstMatch
        let hint = app.buttons[Tool.hint.buttonIdentifier].firstMatch
        XCTAssertTrue(calculator.waitForExistence(timeout: 5), "Expected the calculator button at the largest accessibility text size")
        XCTAssertTrue(hint.waitForExistence(timeout: 5), "Expected the hint button at the largest accessibility text size")
        XCTAssertEqual(hint.label, "Hint", "The hint tool button keeps the visible localized title")
        scrollExamToolUntilHittable(calculator, in: app, maxSwipes: 8)
        XCTAssertTrue(calculator.isHittable, "The calculator button should remain hittable at the largest accessibility text size. Frame: \(frameDescription(calculator.frame))")
        scrollExamToolUntilHittable(hint, in: app, maxSwipes: 8)
        XCTAssertTrue(hint.isHittable, "The hint button should remain hittable at the largest accessibility text size. Frame: \(frameDescription(hint.frame))")
        XCTAssertGreaterThan(hint.frame.height, defaultHintHeight, "The visible Hint label must grow at AX-XXXL, not just expose scalable accessibility metadata. Default height: \(defaultHintHeight), AX-XXXL frame: \(frameDescription(hint.frame))")
        hint.tap()
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Tapping the largest-text Hint button should open the hint tool")
    }

    func testHintToolLadderAndLessonLink() throws {
        let app = launchTwoLevelHintPracticeQuestion()
        defer { app.terminate() }

        openTool(.hint, in: app)
        XCTAssertTrue(app.staticTexts["hint-tool-empty"].firstMatch.waitForExistence(timeout: 5), "Hint panel should start empty before the learner asks for help")
        XCTAssertTrue(app.buttons["hint-show-level-1-button"].firstMatch.waitForExistence(timeout: 5), "Hint 1 should be the first available action")
        XCTAssertFalse(app.buttons["hint-show-level-2-button"].firstMatch.exists, "Hint 2 must not be available before Hint 1")

        app.buttons["hint-show-level-1-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["hint-show-level-2-button"].firstMatch.waitForExistence(timeout: 5), "Two-level hint files should reveal Hint 2 only after Hint 1")
        XCTAssertTrue(app.descendants(matching: .any)["hint-reference-pointer"].firstMatch.exists, "Basic hints may point to the now-available reference sheet")

        app.buttons["hint-show-level-2-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5))
        let review = app.buttons["hint-review-in-lesson-button"].firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5), "The lesson link appears only after the last available hint level")
        XCTAssertEqual(review.label, "Review in lesson", "The link label must stay generic before answering")
        review.tap()
        let heading = app.descendants(matching: .any)["lesson-heading-wavelength-and-frequency"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Hint lesson link should open the shared sectionAnchor")
        XCTAssertTrue(heading.isHittable || isFullyVisible(heading, in: app, requiresHittable: false), "Hint lesson link should scroll the target heading into view. Frame: \(frameDescription(heading.frame))")

        tapNavigationBack(in: app, context: "returning from hint lesson link")
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 10), "Back from the hint lesson should return to the practice question")
        XCTAssertEqual(questionID.label, "B-006-008-004", "The practice session should keep the same question after a hint lesson round trip")
        openTool(.hint, in: app)
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5), "The practice session should keep Hint 2 visible after returning from the lesson")
    }

    func testOneLevelHintHasNoSecondHintAffordance() throws {
        let app = launchOneLevelHintPracticeQuestion()
        defer { app.terminate() }

        openTool(.hint, in: app)
        app.buttons["hint-show-level-1-button"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["hint-show-level-2-button"].firstMatch.exists, "One-level hint files must not show an empty Hint 2 action")
        XCTAssertTrue(app.buttons["hint-review-in-lesson-button"].firstMatch.waitForExistence(timeout: 5), "One-level files show the lesson link after Hint 1")
    }

    func testSimulatedHingeStableSlightOpenPeeksHintOneInPractice() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: triggeredHingeArguments(
            "partiallyOpen:25@0.1",
            includeProgress: false,
            additionalArguments: ["-CanadianHamExamToolInitialDetent", "large", "-CanadianHamHingePlaybackDebugTriggerHidesAfterTap"]
        ))
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated hinge peek")
        triggerSimulatedHingePlayback(in: app, context: "starting stable slight-open hinge playback")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "A stable slight-open simulated hinge posture should open the existing hint panel")
        XCTAssertTrue(app.staticTexts["hint-level-1-title"].firstMatch.waitForExistence(timeout: 5), "The hinge peek should reveal Hint 1 through the existing hint UI")
        XCTAssertTrue(app.buttons["hint-show-level-2-button"].firstMatch.waitForExistence(timeout: 5), "The normal hint ladder remains available after the peek reveals Hint 1")
        waitBriefly(0.8)
        try auditIgnoringOccludedLessonTextContrast(app: app)
    }

    func testSimulatedHingeDismissedPeekReopensOnlyAfterReset() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: triggeredHingeArguments(
            "partiallyOpen:25@0.1|partiallyOpen:45@2.1,partiallyOpen:25@2.2,partiallyOpen:25@3.0,partiallyOpen:45@3.1|unfolded:180@4.1,partiallyOpen:25@4.2",
            additionalArguments: ["-CanadianHamExamToolInitialDetent", "large"]
        ))
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated hinge peek")
        triggerSimulatedHingePlayback(in: app, context: "starting initial stable peek")
        waitForSimulatedHingePlayback(in: app, atLeast: 0.1, context: "initial stable peek delivered its peek-band sample")
        let hintPanel = app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch
        XCTAssertTrue(hintPanel.waitForExistence(timeout: 5), "The initial stable peek should open Hint")
        closeTool(in: app)
        XCTAssertTrue(hintPanel.waitForNonExistence(timeout: 2), "Dismissing the peek-opened Hint panel should close it")
        triggerSimulatedHingePlayback(in: app, context: "playing no-reset leave-and-reenter posture segment")
        waitForSimulatedHingePlayback(in: app, atLeast: 3.1, context: "dismissed peek should stay closed after leaving and re-entering the peek band without a reset")
        XCTAssertFalse(hintPanel.exists, "Leaving the band and returning without a closed or fully-open reset must not reopen a dismissed panel")
        triggerSimulatedHingePlayback(in: app, context: "playing fully-open reset and fresh slight-open segment")
        waitForSimulatedHingePlayback(in: app, atLeast: 4.2, context: "fully-open reset segment delivered its fresh peek-band sample")
        XCTAssertTrue(hintPanel.waitForExistence(timeout: 5), "After a fully-open reset, a fresh stable dwell may peek again")
    }

    func testSimulatedHingePeekStillWorksAfterHintLessonRoundTrip() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: triggeredHingeArguments(
            "partiallyOpen:25@0.1|partiallyOpen:45@2.1,partiallyOpen:25@2.2,partiallyOpen:25@3.0,partiallyOpen:45@3.1|unfolded:180@4.1,partiallyOpen:25@4.2",
            additionalArguments: ["-CanadianHamExamToolInitialDetent", "large"]
        ))
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated hinge peek")
        triggerSimulatedHingePlayback(in: app, context: "starting initial stable peek before lesson")
        waitForSimulatedHingePlayback(in: app, atLeast: 0.1, context: "initial stable peek before lesson delivered its peek-band sample")
        let hintPanel = app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch
        XCTAssertTrue(hintPanel.waitForExistence(timeout: 5), "The initial simulated hinge peek should open Hint")
        let second = app.buttons["hint-show-level-2-button"].firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 5), "The initial peek should reveal Hint 1 and offer Hint 2")
        second.tap()
        let review = app.buttons["hint-review-in-lesson-button"].firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5), "The lesson link appears after both hints")
        review.tap()
        let heading = app.descendants(matching: .any)["lesson-heading-wavelength-and-frequency"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "Hint lesson link should open the shared sectionAnchor")
        tapNavigationBack(in: app, context: "returning from hint lesson before delayed hinge peek")
        XCTAssertTrue(app.descendants(matching: .any)["question-identifier"].firstMatch.waitForExistence(timeout: 10), "Back from the hint lesson should return to the practice question")
        triggerSimulatedHingePlayback(in: app, context: "playing no-reset posture segment after lesson return")
        waitForSimulatedHingePlayback(in: app, atLeast: 3.1, context: "returned from the lesson with no closed or fully-open reset")
        XCTAssertFalse(hintPanel.exists, "A peek dismissed by the lesson link must stay dismissed after a lesson round trip until a real posture reset")
        triggerSimulatedHingePlayback(in: app, context: "playing fully-open reset and fresh slight-open segment after lesson")
        waitForSimulatedHingePlayback(in: app, atLeast: 4.2, context: "fully-open reset after the lesson delivered its fresh peek-band sample")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "After a fully-open reset following the lesson, a fresh stable dwell may peek again")
    }

    func testSimulatedHingeFastUnfoldDoesNotPeekHintOneInPractice() throws {
        let app = launchTwoLevelHintPracticeQuestion(extraArguments: triggeredHingeArguments("partiallyOpen:25@0.1,unfolded:180@0.2,unfolded:180@1.5"))
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the practice question before the simulated fast unfold")
        triggerSimulatedHingePlayback(in: app, context: "starting fast-unfold hinge playback")
        waitForSimulatedHingePlayback(in: app, atLeast: 1.5, context: "fast unfold reached a stable unfolded posture well past the dwell window")
        XCTAssertFalse(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.exists, "A normal fast unfold through the peek band must not open the hint panel")
        XCTAssertFalse(app.staticTexts["hint-level-1-title"].firstMatch.exists, "A normal fast unfold must not reveal Hint 1")
        XCTAssertTrue(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "The Hint button remains the primary accessible path")
    }

    func testSimulatedHingeNeverPeeksHintOneInMockExam() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-hinge-mock",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3",
            "-CanadianHamSimulatedHingeSequence", "closed:0@0,partiallyOpen:25@0.2,partiallyOpen:25@1.0,partiallyOpen:25@2.0"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10), "Expected the mock exam question before asserting hinge posture cannot reveal hints")
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose the Hint button")
        // Mock exams have no playback trigger or progress hook, so give the automatic sequence time to pass
        // its dwell deadline (about 0.9 s after launch) before asserting the negative.
        XCTAssertFalse(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 3), "Mock exams must never open the hint panel from hinge posture")
        XCTAssertFalse(app.staticTexts["hint-level-1-title"].firstMatch.exists, "Mock exams must never reveal Hint 1 from hinge posture")
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
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        } else {
            positionElementFullyVisibleAboveToolSheet(answer, in: app, context: "answer A before clearing calculator keyboard focus")
        }
#else
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
#endif
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
        XCTAssertTrue(focusCalculatorKeyboard(in: app).exists)
        tapCalculatorKey("calculator-key-2", in: app)
        tapCalculatorKey("calculator-key-add", in: app)
        tapCalculatorKey("calculator-key-2", in: app)
        tapCalculatorKey("calculator-key-equals", in: app)
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

    func testMockExamDoesNotExposeHints() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-no-hints",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose hints")
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

    func testMockExamQuestionsNavigatorPresentsAfterCalculatorSheet() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Compact iPhone navigator-sheet coordination is covered by the targeted iPhone run.")
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamMockExamSeed", "ui-exam-tools-navigator",
            "-CanadianHamMockExamQuestionID", "B-001-002-002",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator sheet before opening the question navigator")
        let questions = app.buttons["mock-questions-button"].firstMatch
        XCTAssertTrue(questions.waitForExistence(timeout: 5), "Expected compact mock exam Questions control")
        scrollBackgroundUntilHittable(questions, in: app, maxSwipes: 12)
        XCTAssertTrue(questions.isHittable, "Questions should remain tappable while the calculator sheet is open")
        questions.tap()
        XCTAssertTrue(app.staticTexts["Question navigator"].firstMatch.waitForExistence(timeout: 5), "Tapping Questions while the calculator sheet is open should dismiss the tool sheet and then present the navigator")
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForNonExistence(timeout: 2), "The calculator sheet should be gone after the question navigator appears")
#else
        throw XCTSkip("Compact mock-exam navigator sheet coordination is iOS-only.")
#endif
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

    func testRegularWidthIPhoneUsesInspectorAndKeepsPracticeSelection() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before opening a regular-width inspector")
        let initialQuestionText = question.label
        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before selecting an answer")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before selecting it")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before opening the regular-width inspector")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), "Regular-width iPhone should keep the calculator available while exercising the inspector selection policy")
        XCTAssertEqual(question.label, initialQuestionText, "Opening the regular-width tool panel must not rebuild to a different question")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Opening the inspector must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Opening the inspector must preserve the selected answer state")
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom != .phone {
            assertQuestionTitleWithinExamColumn(in: app, context: "regular-width inspector")
            assertVisibleAnswerButtonsRemainHittable(in: app, context: "regular-width inspector")
        }
#endif
    }

    func testCompactWidthIPhoneKeepsCompactSheet() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        openTool(.calculator, in: app)
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            assertCalculatorPresentedAsSheet(in: app, context: "compact-width iPhone")
        }
#endif
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Compact-width iPhone should keep the calculator available in the sheet")
    }

    func testSimulatedCompactToRegularSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedHorizontalSizeClass", "compact",
            "-CanadianHamShowSimulatedSizeClassChangeControl",
            "-CanadianHamSimulatedHorizontalSizeClassAfterChange", "regular",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before simulated size-class change")
        let initialQuestionText = question.label
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 5), "Expected the practice question identifier before simulated size-class change")
        let initialQuestionID = questionID.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before simulated size-class change")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before simulated size-class change")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before simulated size-class change")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            assertCalculatorPresentedAsSheet(in: app, context: "compact-width iPhone before regular size class")
        }
#endif
        tapCalculatorKey("calculator-key-2", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Expected the calculator value before the simulated size-class change")

        assertSimulatedLayoutMode(in: app, expectedMode: "compact", context: "compact before regular size class")
        applySimulatedSizeClassChange(in: app, expectedSizeClassValue: "regular", context: "compact to regular size class")
        assertSimulatedLayoutMode(in: app, expectedMode: "split", context: "compact to regular size class")
        if !app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.exists {
            openTool(.calculator, in: app)
        }
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected the calculator after the simulated size-class change")
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom != .phone {
            assertSimulatedLayoutChanged(in: app, to: .inspector, context: "compact to regular size class")
        }
#else
        assertSimulatedLayoutChanged(in: app, to: .inspector, context: "compact to regular size class")
#endif

        XCTAssertTrue(question.waitForExistence(timeout: 5), "Expected to remain in the practice session after the simulated size-class change")
        XCTAssertEqual(question.label, initialQuestionText, "Simulated size-class change must keep the same question")
        XCTAssertEqual(questionID.label, initialQuestionID, "Simulated size-class change must keep the same question identifier")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Simulated size-class change must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Simulated size-class change must preserve the selected answer state")
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Simulated size-class change must preserve the calculator value")
    }

    func testSimulatedRegularToCompactSizeClassKeepsPracticeQuestionSelectionAndCalculatorValue() throws {
        let app = launchPracticeQuestion(extraArguments: [
            "-CanadianHamSimulatedHorizontalSizeClass", "regular",
            "-CanadianHamShowSimulatedSizeClassChangeControl",
            "-CanadianHamSimulatedHorizontalSizeClassAfterChange", "compact",
            "-CanadianHamPracticeMode", "review-later"
        ])
        defer { app.terminate() }

        let question = app.staticTexts["question-stem"].firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 10), "Expected the practice question before simulated compact size class")
        let initialQuestionText = question.label
        let questionID = app.descendants(matching: .any)["question-identifier"].firstMatch
        XCTAssertTrue(questionID.waitForExistence(timeout: 5), "Expected the practice question identifier before simulated compact size class")
        let initialQuestionID = questionID.label

        let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A before simulated compact size class")
        scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
        XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before simulated compact size class")
        answer.tap()
        waitBriefly()
        XCTAssertTrue(answer.isSelected, "Answer A should be selected before simulated compact size class")
        let selectedAnswerLabel = answer.label

        openTool(.calculator, in: app)
        tapCalculatorKey("calculator-key-2", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Expected the calculator value before the simulated compact size class")

        assertSimulatedLayoutMode(in: app, expectedMode: "split", context: "regular before compact size class")
        applySimulatedSizeClassChange(in: app, expectedSizeClassValue: "compact", context: "regular to compact size class")
        assertSimulatedLayoutMode(in: app, expectedMode: "compact", context: "regular to compact size class")
        if !app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.exists {
            openTool(.calculator, in: app)
        }
#if os(iOS)
        let expectedPresentation: SimulatedToolPresentationExpectation = .sheet
#else
        let expectedPresentation: SimulatedToolPresentationExpectation = .inspector
#endif
        assertSimulatedLayoutChanged(in: app, to: expectedPresentation, context: "regular to compact size class")
        XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected the calculator after the simulated compact size class")

        XCTAssertTrue(question.waitForExistence(timeout: 5), "Expected to remain in the practice session after the simulated compact size class")
        XCTAssertEqual(question.label, initialQuestionText, "Simulated size-class change must keep the same question")
        XCTAssertEqual(questionID.label, initialQuestionID, "Simulated size-class change must keep the same question identifier")
        XCTAssertEqual(answer.label, selectedAnswerLabel, "Simulated size-class change must preserve the selected answer label")
        XCTAssertTrue(answer.isSelected, "Simulated size-class change must preserve the selected answer state")
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "Simulated size-class change must preserve the calculator value")
    }

    func testCompactToSplitKeepsDeepLearnLesson() throws {
        assertDeepLearnTransition(initialSizeClass: "compact", showsQuiz: false)
    }

    func testSplitToCompactKeepsDeepLearnLesson() throws {
        assertDeepLearnTransition(initialSizeClass: "regular", showsQuiz: false)
    }

    func testCompactToSplitKeepsDeepLearnQuiz() throws {
        assertDeepLearnTransition(initialSizeClass: "compact", showsQuiz: true)
    }

    func testSplitToCompactKeepsDeepLearnQuiz() throws {
        assertDeepLearnTransition(initialSizeClass: "regular", showsQuiz: true)
    }

    private func navigationTransitionArguments(initialSizeClass: String) -> [String] {
        [
            "-CanadianHamSimulatedHorizontalSizeClass", initialSizeClass,
            "-CanadianHamShowSimulatedSizeClassChangeControl",
            "-CanadianHamSimulatedHorizontalSizeClassAfterChange", initialSizeClass == "compact" ? "regular" : "compact"
        ]
    }

    private func assertDeepLearnTransition(initialSizeClass: String, showsQuiz: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let app = launchApp(arguments: navigationTransitionArguments(initialSizeClass: initialSizeClass) + ["-CanadianHamInitialScreen", "learn"])
        defer { app.terminate() }
        let module = app.buttons["Open module"].firstMatch
        XCTAssertTrue(module.waitForExistence(timeout: 10), file: file, line: line)
        scrollBackgroundUntilHittable(module, in: app, maxSwipes: 20)
        XCTAssertTrue(module.isHittable, file: file, line: line)
        module.tap()
        let lesson = app.staticTexts["Units, conductors, and current"].firstMatch
        XCTAssertTrue(lesson.waitForExistence(timeout: 10), file: file, line: line)
        lesson.tap()
        let title = app.descendants(matching: .any)["lesson-reader-title"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), file: file, line: line)
        let expectedLessonTitle = title.label
        if showsQuiz {
            let quizLink = app.buttons["go-to-lesson-quiz-button"].firstMatch
            for _ in 0..<32 where !quizLink.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(quizLink.isHittable, file: file, line: line)
            quizLink.tap()
        }
        let heading = showsQuiz ? app.staticTexts["QZ-L-005-01-A"].firstMatch : title
        XCTAssertTrue(heading.waitForExistence(timeout: 10), file: file, line: line)
        // The lesson reader's quiz summary also shows the quiz ID, so prove the quiz screen itself is pushed.
        let quizCard = app.descendants(matching: .any)["lesson-quiz-card"].firstMatch
        if showsQuiz {
            XCTAssertTrue(quizCard.waitForExistence(timeout: 10), "The quiz screen must be pushed before the transition", file: file, line: line)
        }
        let expectedHeading = heading.label
        XCTAssertFalse(expectedHeading.isEmpty, file: file, line: line)
        assertSimulatedLayoutMode(in: app, expectedMode: initialSizeClass == "compact" ? "compact" : "split", context: "before deep Learn transition", file: file, line: line)
        let target = initialSizeClass == "compact" ? "regular" : "compact"
        applySimulatedSizeClassChange(in: app, expectedSizeClassValue: target, context: "deep Learn transition", file: file, line: line)
        assertSimulatedLayoutMode(in: app, expectedMode: target == "compact" ? "compact" : "split", context: "after deep Learn transition", file: file, line: line)
        XCTAssertTrue(heading.waitForExistence(timeout: 10), "The exact deep route must stay presented", file: file, line: line)
        XCTAssertEqual(heading.label, showsQuiz ? expectedHeading : expectedLessonTitle, file: file, line: line)
        XCTAssertTrue(heading.isHittable, "The lesson or quiz heading must be visible after the transition", file: file, line: line)
        if showsQuiz {
            XCTAssertTrue(quizCard.waitForExistence(timeout: 10), "The quiz screen itself must stay pushed after the transition", file: file, line: line)
        }
    }

    func testRegularWidthMockExamUsesCalculatorInspectorWithoutHints() throws {
        let app = launchApp(arguments: [
            "-CanadianHamInitialScreen", "mock",
            "-CanadianHamForceRegularHorizontalSizeClass",
            "-CanadianHamMockExamSeed", "ui-exam-tools-duo-mock",
            "-CanadianHamMockExamQuestionID", "B-006-008-004",
            "-CanadianHamMockExamLimit", "3"
        ])
        defer { app.terminate() }

        tapStartMockExam(in: app)
        XCTAssertTrue(app.descendants(matching: .any)["answer-A-button"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[Tool.calculator.buttonIdentifier].firstMatch.exists)
        XCTAssertFalse(app.buttons[Tool.hint.buttonIdentifier].firstMatch.exists, "Mock exams must never expose hints, including in regular-width layout")
        openTool(.calculator, in: app)
        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 5), "Regular-width mock exams should keep the calculator available while exercising the inspector selection policy")
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom != .phone {
            assertQuestionTitleWithinExamColumn(in: app, context: "regular-width mock exam inspector")
            assertVisibleAnswerButtonsRemainHittable(in: app, context: "regular-width mock exam inspector")
        }
#endif
    }

    func testRegularWidthUsesInspectorAndKeepsAnswersHittable() throws {
#if os(iOS)
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "Inspector layout is covered by the targeted iPad run.")
        try runRegularWidthInspectorScenario(orientation: .portrait, expectedInitialSidebarVisibility: .collapsed, expectedOpenSidebarVisibility: .collapsed, context: "iPad portrait")
        try runRegularWidthInspectorScenario(orientation: .portrait, expectedInitialSidebarVisibility: .visible, expectedOpenSidebarVisibility: .collapsed, extraArguments: ["-CanadianHamInitialSplitColumnVisibility", "all"], context: "iPad portrait visible sidebar")
        try runRegularWidthInspectorScenario(orientation: .landscapeLeft, expectedInitialSidebarVisibility: .visible, expectedOpenSidebarVisibility: .collapsed, context: "iPad landscape")
        try runRegularWidthInspectorScenario(orientation: .landscapeLeft, expectedInitialSidebarVisibility: .collapsed, expectedOpenSidebarVisibility: .collapsed, extraArguments: ["-CanadianHamInitialSplitColumnVisibility", "detailOnly"], context: "iPad landscape hidden sidebar")
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

    func testAccessibilityAuditHintToolLightAndDark() throws {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            for appearance in ["light", "dark"] {
                let app = launchTwoLevelHintPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
                defer { app.terminate() }

                openTool(.hint, in: app)
                XCTAssertTrue(app.descendants(matching: .any)[Tool.hint.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Expected iPad inspector hint panel")
                revealBothHints(in: app)
                waitBriefly(0.8)
                try auditIgnoringOccludedLessonTextContrast(app: app)
                app.terminate()
            }
        } else {
            for appearance in ["light", "dark"] {
                let app = launchTwoLevelHintPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamExamToolInitialDetent", "large"])
                defer { app.terminate() }

                openTool(.hint, in: app)
                revealBothHints(in: app)
                waitBriefly(0.8)
                try auditIgnoringOccludedLessonTextContrast(app: app)
                app.terminate()
            }
        }
#else
        for appearance in ["light", "dark"] {
            let app = launchTwoLevelHintPracticeQuestion(appearance: appearance)
            defer { app.terminate() }

            openTool(.hint, in: app)
            revealBothHints(in: app)
            waitBriefly(0.8)
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
#endif
    }

    func testAccessibilityAuditHintedAnswerResultLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchTwoLevelHintPracticeQuestion(appearance: appearance)
            openTool(.hint, in: app)
            let first = app.buttons["hint-show-level-1-button"].firstMatch
            XCTAssertTrue(first.waitForExistence(timeout: 5), "Expected Hint 1 before qualifying a hinted answer")
            scrollExamToolUntilHittable(first, in: app, maxSwipes: 8)
            first.tap()
            waitBriefly(0.7)
            closeTool(in: app)
            waitBriefly(0.3)

            let answer = app.descendants(matching: .any)["answer-A-button"].firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 5), "Expected answer A after closing the hint tool")
            scrollBackgroundUntilHittable(answer, in: app, maxSwipes: 12)
            XCTAssertTrue(answer.isHittable, "Expected answer A to be hittable before completing the hinted-answer flow")
            answer.tap()
            let feedback = app.descendants(matching: .any)["answer-feedback-title"].firstMatch
            XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Expected immediate feedback after a hinted answer")
            scrollBackgroundUntilHittable(feedback, in: app, maxSwipes: 12)
            scrollBackgroundPastElement(app.descendants(matching: .any)["exam-tool-calculator-button"].firstMatch, preserving: feedback, in: app, maxSwipes: 8)
            XCTAssertTrue(feedback.isHittable || isFullyVisible(feedback, in: app, requiresHittable: false), "Expected hinted-answer feedback to be visible before auditing the result. Frame: \(frameDescription(feedback.frame))")
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

    func testSizeClassRegularInspectorAccessibilityAuditLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchAuditPracticeQuestion(appearance: appearance, extraArguments: ["-CanadianHamForceRegularHorizontalSizeClass"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            XCTAssertTrue(app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch.waitForExistence(timeout: 5), "Regular-width inspector should present the calculator before auditing")
            waitBriefly(0.8)
            guard activeToolPanelTop(in: app) == nil else {
                XCTContext.runActivity(named: "Native inspector adapted to a sheet in this window") { activity in
                    activity.add(XCTAttachment(string: "The regular size-class policy is active, but the calculator is presented as a sheet in a \(frameDescription(app.windows.firstMatch.frame)) window; this test audits trailing inspectors only."))
                }
                app.terminate()
                continue
            }
            try auditIgnoringOccludedLessonTextContrast(app: app)
            app.terminate()
        }
    }

    func testLargestDynamicTypeKeepsCalculatorGridReachableLightAndDark() throws {
        for appearance in ["light", "dark"] {
            let app = launchPracticeQuestion(appearance: appearance, extraArguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
            defer { app.terminate() }

            openTool(.calculator, in: app)
            XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "Expected the calculator panel before checking largest Dynamic Type reachability")
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
        try XCTSkipUnless(evidenceDirectory() != nil, "Set CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR to write calculator evidence screenshots.")
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
        case hint
        case referenceSheet

        var buttonIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-button"
            case .hint: "exam-tool-hint-button"
            case .referenceSheet: "exam-tool-referenceSheet-button"
            }
        }

        var panelIdentifier: String {
            switch self {
            case .calculator: "exam-tool-calculator-panel"
            case .hint: "exam-tool-hint-panel"
            case .referenceSheet: "exam-tool-reference-sheet-panel"
            }
        }
    }

    private enum SimulatedToolPresentationExpectation {
        case inspector
        case sheet
    }

    private func applySimulatedSizeClassChange(in app: XCUIApplication, expectedSizeClassValue: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["debug-simulated-size-class-change-button"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(context): expected the DEBUG simulated size-class change control", file: file, line: line)
        XCTAssertTrue(button.isHittable, "\(context): expected the DEBUG simulated size-class change control to be hittable", file: file, line: line)
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        assertSimulatedSizeClassApplied(in: app, expectedSizeClassValue: expectedSizeClassValue, context: context, file: file, line: line)
    }

    private func assertSimulatedSizeClassApplied(in app: XCUIApplication, expectedSizeClassValue: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(5)
        var observedValue: String?
        var observedLabel: String?
        while Date() < deadline {
            let button = app.buttons["debug-simulated-size-class-change-button"].firstMatch
            observedValue = button.value as? String
            observedLabel = button.label
            if observedValue?.hasPrefix(expectedSizeClassValue + " ") == true || observedLabel?.contains(expectedSizeClassValue) == true {
                return
            }
            waitBriefly(0.2)
        }
        XCTFail("\(context): expected the DEBUG simulated size-class hook to apply \(expectedSizeClassValue); button value is \(String(describing: observedValue)), label is \(String(describing: observedLabel))", file: file, line: line)
    }

    private func triggeredHingeArguments(_ sequenceSegments: String, includeProgress: Bool = true, additionalArguments: [String] = []) -> [String] {
        additionalArguments
            + (includeProgress ? ["-CanadianHamHingePlaybackDebugStatus"] : [])
            + [
                "-CanadianHamHingePlaybackDebugTrigger",
                "-CanadianHamSimulatedHingeTriggeredSequences", sequenceSegments
            ]
    }

    private func triggerSimulatedHingePlayback(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let triggers = app.buttons.matching(identifier: "debug-hinge-playback-trigger")
        XCTAssertTrue(triggers.firstMatch.waitForExistence(timeout: 5), "\(context): expected the DEBUG hinge playback trigger", file: file, line: line)
        guard let trigger = triggers.allElementsBoundByIndex.first(where: { $0.exists && $0.isHittable }) else {
            XCTFail("\(context): expected a hittable DEBUG hinge playback trigger", file: file, line: line)
            return
        }
        trigger.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func waitForSimulatedHingePlayback(in app: XCUIApplication, atLeast timestamp: TimeInterval, context: String, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let progress = app.staticTexts["debug-hinge-playback-progress"].firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 5), "\(context): expected the DEBUG hinge playback progress element", file: file, line: line)
        let deadline = Date().addingTimeInterval(timeout)
        var observedValue: String?
        while Date() < deadline {
            observedValue = progress.value as? String
            if let observedValue, let observedTimestamp = TimeInterval(observedValue), observedTimestamp + 0.000_001 >= timestamp {
                return
            }
            waitBriefly(0.2)
        }
        XCTFail("\(context): expected simulated hinge playback to reach \(timestamp); observed value is \(String(describing: observedValue))", file: file, line: line)
    }

    /// Asserts the root layout decision (DEBUG control value suffix) independently of the rendered window width.
    private func assertSimulatedLayoutMode(in app: XCUIApplication, expectedMode: String, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(5)
        var observedValue: String?
        while Date() < deadline {
            observedValue = app.buttons["debug-simulated-size-class-change-button"].firstMatch.value as? String
            if observedValue?.hasSuffix(" " + expectedMode) == true {
                return
            }
            waitBriefly(0.2)
        }
        XCTFail("\(context): expected the root layout decision to be \(expectedMode); DEBUG control value is \(String(describing: observedValue))", file: file, line: line)
    }

    private func assertSimulatedLayoutChanged(in app: XCUIApplication, to expected: SimulatedToolPresentationExpectation, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
            guard panel.exists else {
                waitBriefly(0.2)
                continue
            }
            let hasSheet = activeToolPanelTop(in: app) != nil
            switch expected {
            case .inspector where !hasSheet:
                return
            case .sheet where hasSheet:
                return
            default:
                waitBriefly(0.2)
            }
        }

        let panel = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        let panelDescription = panel.exists ? frameDescription(panel.frame) : "missing"
        switch expected {
        case .inspector:
            XCTFail("\(context): expected the simulated layout change to replace the bottom sheet with the inspector. Window: \(frameDescription(app.windows.firstMatch.frame)); panel: \(panelDescription)", file: file, line: line)
        case .sheet:
            XCTFail("\(context): expected the simulated layout change to replace the inspector with the bottom sheet. Window: \(frameDescription(app.windows.firstMatch.frame)); panel: \(panelDescription)", file: file, line: line)
        }
    }

#if os(iOS)
    private enum SidebarVisibilityExpectation {
        case collapsed
        case visible
    }

    private func runRegularWidthInspectorScenario(
        orientation: UIDeviceOrientation,
        expectedInitialSidebarVisibility: SidebarVisibilityExpectation,
        expectedOpenSidebarVisibility: SidebarVisibilityExpectation,
        extraArguments: [String] = [],
        context: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        XCUIDevice.shared.orientation = orientation
        waitBriefly(0.8)
        let app = launchPracticeQuestion(extraArguments: extraArguments + ["-CanadianHamForceRegularHorizontalSizeClass"])
        defer { app.terminate() }

        let initialSidebarVisible = isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app)
        assertSidebarVisibility(expectedInitialSidebarVisibility, in: app, context: "\(context) before opening calculator", file: file, line: line)
        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch.waitForExistence(timeout: 5), "\(context): regular width should present exam tools in an inspector side panel", file: file, line: line)
        waitBriefly(0.8)
        assertSidebarVisibility(expectedOpenSidebarVisibility, in: app, context: "\(context) with calculator open", file: file, line: line)
        assertQuestionTitleWithinExamColumn(in: app, context: context, file: file, line: line)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "\(context) calculator inspector", file: file, line: line)
        tapCalculatorKey("calculator-key-2", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "\(context): calculator should remain interactive after the sidebar adapts", file: file, line: line)
        closeTool(in: app)
        waitBriefly(0.8)
        XCTAssertEqual(isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app), initialSidebarVisible, "\(context): closing the inspector should restore the sidebar visibility that existed before opening it", file: file, line: line)

        openTool(.calculator, in: app)
        XCTAssertTrue(app.descendants(matching: .any)["calculator-result"].firstMatch.waitForExistence(timeout: 5), "\(context): the inspector should reopen after restoring the sidebar", file: file, line: line)
        XCTAssertEqual(app.descendants(matching: .any)["calculator-result"].firstMatch.value as? String, "2", "\(context): reopening should preserve calculator state", file: file, line: line)
        assertSidebarVisibility(expectedOpenSidebarVisibility, in: app, context: "\(context) with calculator reopened", file: file, line: line)
        assertQuestionTitleWithinExamColumn(in: app, context: "\(context) calculator reopened", file: file, line: line)
        assertVisibleAnswerButtonsRemainHittable(in: app, context: "\(context) calculator inspector reopened", file: file, line: line)
        closeTool(in: app)
        waitBriefly(0.8)
        XCTAssertEqual(isSidebarVisible(app.descendants(matching: .any)["root-sidebar"].firstMatch, in: app), initialSidebarVisible, "\(context): closing the reopened inspector should restore the original sidebar visibility", file: file, line: line)
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
            XCTAssertFalse(visible, "\(context): expected the sidebar collapsed so the exam column is not dimmed or covered. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
        case .visible:
            XCTAssertTrue(visible, "\(context): expected the sidebar visible. Sidebar frame: \(frameDescription(sidebar.frame))", file: file, line: line)
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

    private func launchTwoLevelHintPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-006", questionID: "B-006-008-004", extraArguments: extraArguments)
    }

    private func launchOneLevelHintPracticeQuestion(appearance: String = "light", extraArguments: [String] = []) -> XCUIApplication {
        launchPracticeQuestion(appearance: appearance, categoryID: "B-006", questionID: "B-006-003-008", extraArguments: extraArguments)
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

    private func tapNavigationBack(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "\(context): expected a navigation bar before tapping Back", file: file, line: line)
        let labels = ["Back", "All questions", "Practice"]
        let preferredBack = navigationBar.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        if preferredBack.waitForExistence(timeout: 2) {
            preferredBack.tap()
            return
        }
        let anyBack = navigationBar.buttons.element(boundBy: 0)
        XCTAssertTrue(anyBack.waitForExistence(timeout: 5), "\(context): expected a navigation back button", file: file, line: line)
        anyBack.tap()
    }

    private func revealBothHints(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let first = app.buttons["hint-show-level-1-button"].firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5), "Expected Hint 1 button", file: file, line: line)
        scrollExamToolUntilHittable(first, in: app, maxSwipes: 8, file: file, line: line)
        first.tap()
        let second = app.buttons["hint-show-level-2-button"].firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 5), "Expected Hint 2 button", file: file, line: line)
        scrollExamToolUntilHittable(second, in: app, maxSwipes: 8, file: file, line: line)
        second.tap()
        XCTAssertTrue(app.staticTexts["hint-level-2-title"].firstMatch.waitForExistence(timeout: 5), "Expected both hints to be visible", file: file, line: line)
    }

    private func assertCalculatorPresentedAsSheet(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let header = app.descendants(matching: .any)[Tool.calculator.panelIdentifier].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected the calculator panel header", file: file, line: line)
        XCTAssertNotNil(activeToolPanelTop(in: app), "\(context): expected a bottom sheet, not a trailing inspector", file: file, line: line)
        XCTAssertLessThan(header.frame.minX, windowFrame.midX, "\(context): iPhone regular-width landscape should keep tools in the bottom sheet rather than a trailing inspector. Header: \(frameDescription(header.frame)); window: \(frameDescription(windowFrame))", file: file, line: line)
    }

    private func performMediumDetentExamToolAudit(on app: XCUIApplication, context: String) throws {
        let mediumHeaderFrame = currentCalculatorHeaderFrame(in: app, context: "\(context) before medium-detent precheck")
        assertMediumDetentHeaderFrame(mediumHeaderFrame, in: app, context: "\(context) before medium-detent precheck")
        assertMediumDetentToolPanelVisibleElements(in: app, context: context)
        scrollCalculatorPanelToTop(in: app, context: context)
        assertMediumDetentHeaderFrame(mediumHeaderFrame, in: app, context: "\(context) immediately before medium-detent audit")
        assertCalculatorDisplayAndCloseHittable(in: app, context: "\(context) immediately before medium-detent audit")

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

    // Approved exception (a): the iPad inspector is a second scroll view. Select it
    // explicitly; the contrast rule below is identical to the approved shared helper.
    private func auditIgnoringOccludedReferenceSheetTextContrast(app: XCUIApplication) throws {
        let visibleScrollView = app.scrollViews["reference-sheet-scroll"].firstMatch
        guard visibleScrollView.waitForExistence(timeout: 5) else {
            XCTFail("Expected reference-sheet-scroll; refusing to audit a different scroll view")
            return
        }
        let windowFrame = app.windows.firstMatch.frame
        let protectedMaxY = protectedNavigationFrame(in: app).maxY
        let scrollFrame = visibleScrollView.frame.intersection(windowFrame)
        let minY = max(scrollFrame.minY, protectedMaxY)
        let auditGeometry = LessonAuditGeometry(
            scrollFrame: scrollFrame,
            visibleScrollArea: CGRect(x: scrollFrame.minX, y: minY, width: max(0, scrollFrame.width), height: max(0, scrollFrame.maxY - minY)),
            navigationBarElementFrames: navigationBarElementFrames(in: app),
            scrollView: visibleScrollView
        )
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            guard let element = issue.element else { return false }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0 else { return false }
            guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
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

    private func auditIgnoringOccludedLessonTextContrast(app: XCUIApplication) throws {
        let auditGeometry = lessonAuditGeometryBelowOpaqueNavigationBar(in: app)
        try app.performAccessibilityAudit { issue in
            guard issue.auditType == .contrast else { return false }
            guard let element = issue.element else { return false }
            let frame = element.frame
            guard frame.width > 0, frame.height > 0 else { return false }
            guard !self.frame(frame, matchesAny: auditGeometry.navigationBarElementFrames) else { return false }
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

        assertCalculatorDisplayAndCloseHittable(in: app, context: "\(context) before medium-detent precheck", file: file, line: line)

        for identifier in calculatorKeyIdentifiers {
            let key = app.buttons[identifier].firstMatch
            scrollCalculatorPanelUntilElementExists(key, in: app, maxSwipes: 10, file: file, line: line)
            XCTAssertTrue(key.waitForExistence(timeout: 5), "\(context): expected \(identifier) before auditing", file: file, line: line)
            scrollExamToolUntilHittable(key, in: app, maxSwipes: 10, file: file, line: line)
            XCTAssertTrue(key.isHittable, "\(context): \(identifier) should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(key.frame))", file: file, line: line)
            XCTAssertGreaterThanOrEqual(key.frame.height, 44, "\(context): \(identifier) must preserve the 44 pt hit target before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(key.frame))", file: file, line: line)
        }
    }

    private func assertCalculatorDisplayAndCloseHittable(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let display = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 5), "\(context): expected the calculator display", file: file, line: line)
        XCTAssertTrue(display.isHittable, "\(context): calculator display should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(display.frame))", file: file, line: line)

        let close = app.buttons["exam-tool-close-button"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "\(context): expected Close tool", file: file, line: line)
        XCTAssertTrue(close.isHittable, "\(context): Close tool should be hittable before using the medium-detent text-clipped audit exception. Frame: \(frameDescription(close.frame))", file: file, line: line)
    }

    private func currentCalculatorHeaderFrame(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
        let header = app.descendants(matching: .any)["exam-tool-calculator-panel"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "\(context): expected a calculator panel header", file: file, line: line)
        return header.frame
    }

    private func assertMediumDetentHeaderFrame(_ expectedFrame: CGRect, in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let windowFrame = app.windows.firstMatch.frame
        let currentFrame = currentCalculatorHeaderFrame(in: app, context: context, file: file, line: line)
        XCTAssertTrue(windowFrame.contains(currentFrame), "\(context): medium sheet header should stay in the window. Header: \(frameDescription(currentFrame)); window: \(frameDescription(windowFrame))", file: file, line: line)
        XCTAssertGreaterThan(currentFrame.minY, windowFrame.height * 0.25, "\(context): sheet appears to have left the medium detent. Header: \(frameDescription(currentFrame)); window: \(frameDescription(windowFrame))", file: file, line: line)
        XCTAssertLessThan(abs(currentFrame.minY - expectedFrame.minY), 6, "\(context): sheet header moved after the medium-detent precheck, so the medium-detent audit exception would be applied outside the approved detent. Expected: \(frameDescription(expectedFrame)); current: \(frameDescription(currentFrame))", file: file, line: line)
        XCTAssertLessThan(abs(currentFrame.height - expectedFrame.height), 2, "\(context): sheet header height changed before audit. Expected: \(frameDescription(expectedFrame)); current: \(frameDescription(currentFrame))", file: file, line: line)
    }

    private func scrollCalculatorPanelToTop(in app: XCUIApplication, context: String, file: StaticString = #filePath, line: UInt = #line) {
        let display = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(display.waitForExistence(timeout: 5), "\(context): expected calculator display before restoring scroll position", file: file, line: line)
        guard !display.isHittable else { return }
        let scrollView = calculatorScrollView(in: app, requiredFor: "restoring calculator medium-detent audit scroll position", file: file, line: line)
        for _ in 0..<10 where !display.isHittable {
            scrollView.swipeDown()
            waitBriefly()
        }
        XCTAssertTrue(display.isHittable, "\(context): calculator display should be hittable after restoring the calculator scroll view to the top. Frame: \(frameDescription(display.frame))", file: file, line: line)
    }

    private var calculatorKeyIdentifiers: [String] {
        [
            "calculator-key-all-clear", "calculator-key-clear-entry", "calculator-key-backspace", "calculator-key-divide",
            "calculator-key-7", "calculator-key-8", "calculator-key-9", "calculator-key-multiply",
            "calculator-key-4", "calculator-key-5", "calculator-key-6", "calculator-key-subtract",
            "calculator-key-1", "calculator-key-2", "calculator-key-3", "calculator-key-add",
            "calculator-key-toggle-sign", "calculator-key-0", "calculator-key-decimal", "calculator-key-equals",
            "calculator-key-percent", "calculator-key-square-root", "calculator-key-square", "calculator-key-reciprocal"
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

    private func scrollExamToolUntilHittable(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<maxSwipes where !isFullyVisible(element, in: app, requiresHittable: true) {
            let scrollView = element.identifier.hasPrefix("calculator-key-")
                ? calculatorScrollView(in: app, requiredFor: "scrolling calculator key \(element.identifier)", file: file, line: line)
                : scrollView(containing: element, in: app)
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

    private func scrollBackgroundPastElement(_ element: XCUIElement, preserving preservedElement: XCUIElement, in app: XCUIApplication, maxSwipes: Int) {
        let scrollView = scrollView(containing: preservedElement, in: app)
        for _ in 0..<maxSwipes where element.exists && visibleFrameExcludingNavigationBar(in: app).intersects(element.frame) {
            preciseExamToolScroll(scrollView, in: app, fingerDeltaY: -72)
            waitBriefly()
            if preservedElement.exists && preservedElement.frame.maxY <= visibleFrameExcludingNavigationBar(in: app).minY {
                preciseExamToolScroll(scrollView, in: app, fingerDeltaY: 72)
                waitBriefly()
                break
            }
        }
    }

    private func scrollCalculatorPanelUntilElementExists(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<maxSwipes where !element.exists {
            // Offscreen lazy-grid keys have no snapshot yet, so even reading their identifier fails before scrolling.
            let scrollView = calculatorScrollView(in: app, requiredFor: "revealing an offscreen calculator element", file: file, line: line)
            scrollView.swipeUp()
            waitBriefly()
        }
    }

    /// The calculator's ScrollView is the root of `CalculatorToolView`, so XCTest exposes it with the
    /// outer `calculator-keyboard-focus-target` identifier rather than the inner `calculator-tool-scroll`.
    /// Accept only a scroll view carrying one of those two calculator identifiers that also contains the
    /// calculator result display; never fall back to the background question scroll view.
    private func calculatorScrollView(in app: XCUIApplication, requiredFor context: String, timeout: TimeInterval = 1, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let calculatorIdentifiers = NSPredicate(format: "identifier IN %@", ["calculator-tool-scroll", "calculator-keyboard-focus-target"])
        let scrollView = app.scrollViews
            .matching(calculatorIdentifiers)
            .containing(.any, identifier: "calculator-result")
            .firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: timeout), "Expected the calculator scroll view (containing calculator-result) for \(context); refusing to fall back to the background scroll view", file: file, line: line)
        return scrollView
    }

    private func focusCalculatorKeyboard(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let result = app.descendants(matching: .any)["calculator-result"].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Expected a calculator result display before focusing keyboard input", file: file, line: line)
        let focusedTarget = app.descendants(matching: .any)["calculator-keyboard-focus-target"].firstMatch
        XCTAssertTrue(focusedTarget.waitForExistence(timeout: 5), "Expected the calculator keyboard handler after opening the calculator", file: file, line: line)
        return focusedTarget
    }

    private func tapCalculatorKey(_ identifier: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let key = app.buttons[identifier].firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5), "Expected calculator key \(identifier)", file: file, line: line)
        scrollExamToolUntilHittable(key, in: app, maxSwipes: 8)
        XCTAssertTrue(key.isHittable, "Expected calculator key \(identifier) to be hittable", file: file, line: line)
        key.tap()
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
        let windowFrame = app.windows.firstMatch.frame
        for identifier in ["exam-tool-calculator-panel"] {
            let panel = app.descendants(matching: .any)[identifier].firstMatch
            if panel.exists, panel.frame.minX > windowFrame.midX, panel.frame.width < windowFrame.width * 0.7 {
                return nil
            }
        }
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
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = fileName
        attachment.lifetime = .keepAlways
        add(attachment)

        let directory = try XCTUnwrap(evidenceDirectory(), "Set CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR before saving calculator evidence screenshots.", file: file, line: line)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try screenshot.pngRepresentation.write(to: url, options: .atomic)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Expected screenshot at \(url.path)", file: file, line: line)
    }

    private func evidenceDirectory() -> URL? {
        ProcessInfo.processInfo.environment["CANADIAN_HAM_EXAM_TOOLS_EVIDENCE_DIR"]
            .flatMap { $0.isEmpty ? nil : URL(fileURLWithPath: $0, isDirectory: true) }
    }

    private func frameDescription(_ frame: CGRect) -> String {
        "x: \(frame.origin.x), y: \(frame.origin.y), width: \(frame.size.width), height: \(frame.size.height)"
    }

    private func waitBriefly(_ seconds: TimeInterval = 0.2) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }
}
