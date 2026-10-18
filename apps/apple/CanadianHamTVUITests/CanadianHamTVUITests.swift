import UIKit
import XCTest

@MainActor
final class CanadianHamTVUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCategoryGridAccessibilityAuditLightAndDark() throws {
        try auditScreen(.categories)
    }

    func testPracticeAccessibilityAuditLightAndDark() throws {
        try auditScreen(.practice)
    }

    func testAboutAccessibilityAuditLightAndDark() throws {
        try auditScreen(.about)
    }

    func testMorseAccessibilityAuditLightAndDark() throws {
        try auditScreen(.morse)
    }

    func testMorseScreenShowsPlaybackControls() throws {
        let app = configuredApp(screen: .morse, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.morse.waitElement(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Play"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Stop"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hidden until playback finishes."].firstMatch.exists)
    }

    func testCategoryGridNavigatesToMorse() throws {
        let app = configuredApp(screen: .categories, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 15))
        let morseButton = app.buttons["tv-morse-button"].firstMatch
        XCTAssertTrue(morseButton.waitForExistence(timeout: 5), "Category grid should expose Morse")
        let remote = XCUIRemote.shared
        pressUntilFocused(morseButton, remote: remote, buttons: [.up, .up, .left, .right, .down], maxCycles: 3)
        remote.press(.select)
        XCTAssertTrue(PlatformAuditScreen.morse.waitElement(in: app).waitForExistence(timeout: 10), "Morse should be reachable from the category grid")
        remote.press(.menu)
        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 5), "Menu should return Morse to the category grid")
    }

    func testAboutShowsReleaseAttributionDisclaimerAndBankVersion() throws {
        let app = configuredApp(screen: .about, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.about.waitElement(in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(anyLabel(in: app, contains: "Active bank: basic-2025-07-15, effective 2025-07-15."), "Expected active bank version and effective date on tvOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Contains information reproduced from Innovation, Science and Economic Development Canada"), "Expected ISED attribution on tvOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "canadian-ham is an independent study tool"), "Expected disclaimer on tvOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Practice sessions are kept only while the app is open"), "Expected ephemeral practice-session privacy copy on tvOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "Draft attribution, not in effect"), "Expected visible draft-attribution warning on tvOS About")
        XCTAssertTrue(anyLabel(in: app, contains: "has not yet been granted"), "Expected pending permission status on tvOS About")
    }

    func testAboutLowerSectionsReachableWithRemote() throws {
        let app = configuredApp(screen: .about, appearance: "light")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.about.waitElement(in: app).waitForExistence(timeout: 15))
        let remote = XCUIRemote.shared
        let disclaimer = app.descendants(matching: .any)["tv-about-disclaimer-section"].firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 5), "Expected focusable tvOS About disclaimer section")
        pressDownUntilFocused(disclaimer, remote: remote, maxPresses: 8)
        XCTAssertTrue(disclaimer.hasFocus, "Remote focus should reach the About disclaimer section")
        XCTAssertTrue(disclaimer.label.localizedCaseInsensitiveContains("canadian-ham is an independent study tool"), "Focusable disclaimer section should expose its legal text")
        assertFocusedElementIsOnScreen(disclaimer, in: app, description: "tvOS About disclaimer section")

        let privacy = app.descendants(matching: .any)["tv-about-privacy-section"].firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), "Expected focusable tvOS About privacy section")
        pressDownUntilFocused(privacy, remote: remote, maxPresses: 4)
        XCTAssertTrue(privacy.hasFocus, "Remote focus should reach the About privacy section")
        XCTAssertTrue(privacy.label.localizedCaseInsensitiveContains("Practice sessions are kept only while the app is open"), "Focusable privacy section should expose its privacy text")
        assertFocusedElementIsOnScreen(privacy, in: app, description: "tvOS About privacy section")
        attachScreenScreenshot(name: "tvos-about-lower-sections-focus")
    }

    func testPracticeInteractionUsesConfiguredLanguageShowsFeedbackAndAdvances() throws {
        let app = configuredApp(screen: .practice, appearance: "light", language: "fr", evidenceFocus: "answer")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.staticTexts[Self.fixedFrenchQuestionText].firstMatch.waitForExistence(timeout: 15), "Expected fixed practice question in configured French language")
        XCTAssertFalse(app.buttons["question-language-fr-button"].firstMatch.exists, "tvOS practice should not show a language picker")

        let remote = XCUIRemote.shared
        let firstAnswer = app.descendants(matching: .any)["answer-A-button"].firstMatch
        XCTAssertTrue(firstAnswer.waitForExistence(timeout: 5), "First answer should exist")
        pressUntilFocused(firstAnswer, remote: remote, buttons: [.down, .right], maxCycles: 6)
        remote.press(.select)
        let feedback = app.descendants(matching: .any)["answer-feedback"].firstMatch
        XCTAssertTrue(feedback.waitForExistence(timeout: 5), "Feedback should appear after selecting an answer")

        let nextQuestion = app.buttons["next-question-button"].firstMatch
        XCTAssertTrue(nextQuestion.waitForExistence(timeout: 5), "Next question button should exist")
        assertNextQuestionIsSeparateButton(nextQuestion, feedback: feedback)
        waitForFocus(on: nextQuestion)
        XCTAssertTrue(nextQuestion.hasFocus, "Next question should receive focus automatically after answering")
        assertFocusedElementIsOnScreen(nextQuestion, in: app, description: "Next question")

        remote.press(.select)
        waitForElementToDisappear(feedback, timeout: 5, message: "Feedback should disappear after advancing to the next question with the remote")
        XCTAssertFalse(feedback.exists, "Feedback should disappear after advancing to the next question with the remote")
        XCTAssertTrue(
            app.descendants(matching: .any)["tv-practice-screen"].firstMatch.exists,
            "Advancing with Next question should keep the app on the practice screen"
        )
        let reenabledAnswer = app.buttons["answer-A-button"].firstMatch
        XCTAssertTrue(reenabledAnswer.waitForExistence(timeout: 5), "A new answer should be visible after advancing")
        XCTAssertTrue(reenabledAnswer.isEnabled, "Answers should be re-enabled after advancing to the next question")
    }

    func testPracticeHintLadderLessonLinkAndAudit() throws {
        let app = configuredApp(screen: .practice, appearance: "light", categoryID: "B-006", questionID: "B-006-008-004", language: "fr", evidenceFocus: "hint", interfaceLanguage: "fr")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["tv-practice-screen"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any)["hint-reference-pointer"].firstMatch.exists, "tvOS has no reference-sheet surface, so hint reference pointers stay hidden")

        openHintLevel(1, in: app)
        XCTAssertTrue(app.staticTexts["hint-level-1-body"].firstMatch.waitForExistence(timeout: 5), "Hint 1 should appear in tvOS practice")
        XCTAssertTrue(app.descendants(matching: .any)["hint-show-level-2-button"].firstMatch.waitForExistence(timeout: 5), "Two-level files should reveal Hint 2 only after Hint 1")
        openHintLevel(2, in: app)
        XCTAssertTrue(app.staticTexts["hint-level-2-body"].firstMatch.waitForExistence(timeout: 5), "Hint 2 should appear after the second ladder action")
        let review = app.descendants(matching: .any)["hint-review-in-lesson-button"].firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5), "Last hint level should expose the generic lesson link")
        XCTAssertEqual(review.label, "Revoir dans la leçon", "Lesson link label should stay generic and localized")
        XCTAssertTrue(app.staticTexts["hint-english-only-lesson-notice"].firstMatch.waitForExistence(timeout: 5), "French UI should note that lesson bodies are currently English-only")
        XCTAssertFalse(anyLabel(in: app, contains: "Polarization, dipoles, and wavelength"), "Hint link must not reveal the lesson title before the question is answered")
        XCTAssertFalse(anyLabel(in: app, contains: "Wavelength and frequency"), "Hint link must not reveal the linked section heading before the question is answered")
        try performAudit(on: app, context: "tvOS open hint")

        pressUntilFocused(review, remote: XCUIRemote.shared, buttons: [.down, .right, .left], maxCycles: 8)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.descendants(matching: .any)["tv-lesson-screen"].firstMatch.waitForExistence(timeout: 10), "Review in lesson should open the tvOS lesson reader")
        XCTAssertTrue(app.staticTexts["lesson-heading-wavelength-and-frequency"].firstMatch.waitForExistence(timeout: 10), "Lesson link should open at the sectionAnchor")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.descendants(matching: .any)["tv-practice-screen"].firstMatch.waitForExistence(timeout: 5), "Menu should return to the in-progress practice session")
        XCTAssertTrue(app.staticTexts["hint-level-2-body"].firstMatch.exists, "Hint state should survive the lesson round trip")
    }

    func testPracticeOneLevelHintHasNoHint2AndNonPracticeScreensHaveNoHint() throws {
        let app = configuredApp(screen: .practice, appearance: "light", categoryID: "B-001", questionID: "B-001-002-002", evidenceFocus: "hint")
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.descendants(matching: .any)["tv-practice-screen"].firstMatch.waitForExistence(timeout: 15))
        openHintLevel(1, in: app)
        XCTAssertTrue(app.staticTexts["hint-level-1-body"].firstMatch.waitForExistence(timeout: 5), "One-level hint should show Hint 1")
        XCTAssertFalse(app.descendants(matching: .any)["hint-show-level-2-button"].firstMatch.exists, "One-level files must not expose a broken Hint 2 affordance")
        XCTAssertTrue(app.descendants(matching: .any)["hint-review-in-lesson-button"].firstMatch.exists, "One-level files expose the lesson link after Hint 1")

        let mockApp = XCUIApplication()
        mockApp.launchArguments = [
            "-CanadianHamPlatformInitialScreen", "mockExam",
            "-CanadianHamAppearance", "light"
        ]
        mockApp.launch()
        defer { mockApp.terminate() }
        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: mockApp).waitForExistence(timeout: 15), "tvOS has no mock-exam surface and falls back to the non-practice grid")
        XCTAssertFalse(mockApp.descendants(matching: .any)["hint-show-level-1-button"].firstMatch.exists, "Hints must not be exposed outside practice")
    }

    func testLayoutEvidenceScreenshots() throws {
        for appearance in ["light", "dark"] {
            for language in ["en", "fr"] {
                try captureCategoryGridLayoutEvidence(
                    appearance: appearance,
                    language: language,
                    attachmentNamePrefix: "tvos-category-grid-\(language)-\(appearance)"
                )
                try capturePracticeHeaderLayoutEvidence(
                    appearance: appearance,
                    language: language,
                    attachmentName: "tvos-practice-header-\(language)-\(appearance)"
                )
            }
        }
    }

    func testFocusRingEvidenceScreenshots() throws {
        for appearance in ["light", "dark"] {
            let suffix = appearance == "light" ? "" : "-dark"
            try captureFocusRingEvidence(
                screen: .categories,
                appearance: appearance,
                targetIdentifier: "category-B-001-button",
                evidenceFocus: "category",
                attachmentName: "tvos-category-focus-ring\(suffix)"
            )
            try captureFocusRingEvidence(
                screen: .practice,
                appearance: appearance,
                targetIdentifier: "answer-A-button",
                evidenceFocus: "answer",
                attachmentName: "tvos-answer-focus-ring\(suffix)"
            )
            try captureFocusRingEvidence(
                screen: .practice,
                appearance: appearance,
                targetIdentifier: "next-question-button",
                answeredSourceIndex: 0,
                attachmentName: "tvos-primary-focus-ring\(suffix)"
            )
        }

        try captureFocusRingEvidence(
            screen: .practice,
            appearance: "light",
            targetIdentifier: "answer-A-button",
            evidenceFocus: "answer",
            reduceMotion: true,
            attachmentName: "tvos-answer-focus-ring-reduce-motion"
        )
    }

    func testRemoteMenuReturnsPracticeAndAboutToCategoryGrid() throws {
        for screen in [PlatformAuditScreen.practice, .about] {
            let app = configuredApp(screen: screen, appearance: "light")
            app.launch()
            addTeardownBlock { app.terminate() }
            XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) before pressing Menu")

            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(
                PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 5),
                "Menu should return \(screen.rawValue) to the category grid"
            )
            app.terminate()
        }
    }

    private func auditScreen(_ screen: PlatformAuditScreen) throws {
        for appearance in ["light", "dark"] {
            let app = configuredApp(screen: screen, appearance: appearance)
            app.launch()

            XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) for \(appearance)")
            try performAudit(on: app, context: "\(appearance) \(screen.rawValue)")
            app.terminate()

            if screen == .practice {
                let answeredApp = configuredApp(screen: screen, appearance: appearance, answeredSourceIndex: 0)
                answeredApp.launch()
                XCTAssertTrue(screen.waitElement(in: answeredApp).waitForExistence(timeout: 15), "Expected answered practice question for \(appearance)")
                XCTAssertTrue(
                    answeredApp.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5),
                    "Expected fixed launch-argument feedback state"
                )
                try performAudit(on: answeredApp, context: "\(appearance) answered practice")
                answeredApp.terminate()
            }
        }
    }

    private func configuredApp(
        screen: PlatformAuditScreen,
        appearance: String,
        categoryID: String = "B-001",
        questionID: String = "B-001-002-002",
        answeredSourceIndex: Int? = nil,
        language: String? = nil,
        evidenceFocus: String? = nil,
        interfaceLanguage: String? = nil,
        reduceMotion: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-CanadianHamPlatformInitialScreen", screen.rawValue,
            "-CanadianHamPlatformCategoryID", categoryID,
            "-CanadianHamPlatformQuestionID", questionID,
            "-CanadianHamAppearance", appearance
        ]
        if let answeredSourceIndex {
            app.launchArguments += ["-CanadianHamPlatformAnsweredSourceIndex", "\(answeredSourceIndex)"]
        }
        if let language {
            app.launchArguments += ["-CanadianHamLanguage", language]
        }
        if let evidenceFocus {
            app.launchArguments += ["-CanadianHamTVEvidenceFocus", evidenceFocus]
        }
        if let interfaceLanguage {
            app.launchArguments += ["-AppleLanguages", "(\(interfaceLanguage))", "-AppleLocale", "\(interfaceLanguage)_CA"]
        }
        if reduceMotion {
            app.launchArguments += ["-CanadianHamReduceMotion", "enabled"]
        }
        return app
    }

    private func performAudit(on app: XCUIApplication, context _: String) throws {
        try app.performAccessibilityAudit()
    }

    private func captureCategoryGridLayoutEvidence(
        appearance: String,
        language: String,
        attachmentNamePrefix: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let app = configuredApp(
            screen: .categories,
            appearance: appearance,
            language: language,
            evidenceFocus: "category"
        )
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(PlatformAuditScreen.categories.waitElement(in: app).waitForExistence(timeout: 15), "Expected category grid before capturing \(attachmentNamePrefix)", file: file, line: line)
        let firstCategory = app.descendants(matching: .any)["category-B-001-button"].firstMatch
        XCTAssertTrue(firstCategory.waitForExistence(timeout: 5), "Expected first category before capturing \(attachmentNamePrefix)-top", file: file, line: line)
        waitForFocus(on: firstCategory)
        XCTAssertTrue(firstCategory.hasFocus, "Expected first category to hold focus before top capture", file: file, line: line)
        assertFocusedElementIsOnScreen(firstCategory, in: app, description: "category-B-001-button", file: file, line: line)
        attachScreenScreenshot(name: "\(attachmentNamePrefix)-top")

        let lowerCategory = app.descendants(matching: .any)["category-B-007-button"].firstMatch
        pressRemote([.down, .down], remote: XCUIRemote.shared)
        waitForFocus(on: lowerCategory)
        XCTAssertTrue(lowerCategory.waitForExistence(timeout: 5), "Expected lower category before capturing \(attachmentNamePrefix)-lower", file: file, line: line)
        XCTAssertTrue(lowerCategory.hasFocus, "Expected lower category to hold focus before lower capture", file: file, line: line)
        assertFocusedElementIsOnScreen(lowerCategory, in: app, description: "category-B-007-button", file: file, line: line)
        attachScreenScreenshot(name: "\(attachmentNamePrefix)-lower")
    }

    private func capturePracticeHeaderLayoutEvidence(
        appearance: String,
        language: String,
        attachmentName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let app = configuredApp(
            screen: .practice,
            appearance: appearance,
            categoryID: "B-003",
            language: language
        )
        app.launch()
        defer { app.terminate() }

        let expectedTitle = language == "fr" ? "Montage d'une station, pratique et sécurité" : "Station Assembly, Practice and Safety"
        XCTAssertTrue(app.descendants(matching: .any)["tv-practice-screen"].firstMatch.waitForExistence(timeout: 15), "Expected practice screen before capturing \(attachmentName)", file: file, line: line)
        let title = app.staticTexts[expectedTitle].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Expected practice title before capturing \(attachmentName)", file: file, line: line)
        assertPracticeHeaderTitleFitsTwoLines(title, file: file, line: line)
        try attachTopCroppedScreenshot(name: attachmentName, heightRatio: language == "fr" ? 0.44 : 0.36)
    }

    private func captureFocusRingEvidence(
        screen: PlatformAuditScreen,
        appearance: String,
        targetIdentifier: String,
        language: String? = nil,
        evidenceFocus: String? = nil,
        answeredSourceIndex: Int? = nil,
        reduceMotion: Bool = false,
        attachmentName: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let app = configuredApp(
            screen: screen,
            appearance: appearance,
            answeredSourceIndex: answeredSourceIndex,
            language: language,
            evidenceFocus: evidenceFocus,
            reduceMotion: reduceMotion
        )
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(screen.waitElement(in: app).waitForExistence(timeout: 15), "Expected \(screen.rawValue) before capturing \(attachmentName)", file: file, line: line)
        if answeredSourceIndex != nil {
            XCTAssertTrue(
                app.descendants(matching: .any)["answer-feedback"].firstMatch.waitForExistence(timeout: 5),
                "Expected answered feedback before capturing \(attachmentName)",
                file: file,
                line: line
            )
        }

        let target = app.descendants(matching: .any)[targetIdentifier].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Expected \(targetIdentifier) before capturing \(attachmentName)", file: file, line: line)
        waitForFocus(on: target)
        XCTAssertTrue(target.hasFocus, "Expected \(targetIdentifier) to hold tvOS focus before capturing \(attachmentName)", file: file, line: line)
        assertFocusedElementIsOnScreen(target, in: app, description: targetIdentifier, file: file, line: line)
        attachFocusedScreenshot(target, name: attachmentName)
    }

    private func openHintLevel(_ level: Int, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)["hint-show-level-\(level)-button"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 8), "Expected Show Hint \(level) button", file: file, line: line)
        pressUntilFocused(button, remote: XCUIRemote.shared, buttons: [.down, .right, .left], maxCycles: 10, file: file, line: line)
        XCUIRemote.shared.press(.select)
    }

    private func pressRemote(_ buttons: [XCUIRemote.Button], remote: XCUIRemote) {
        for button in buttons {
            remote.press(button)
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
    }

    private func pressDownUntilFocused(
        _ element: XCUIElement,
        remote: XCUIRemote,
        maxPresses: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<maxPresses where !element.hasFocus {
            remote.press(.down)
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        XCTAssertTrue(element.hasFocus, "Expected remote down presses to focus \(element.identifier)", file: file, line: line)
    }

    private func pressUntilFocused(
        _ element: XCUIElement,
        remote: XCUIRemote,
        buttons: [XCUIRemote.Button],
        maxCycles: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<maxCycles where !element.hasFocus {
            for button in buttons where !element.hasFocus {
                remote.press(button)
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            }
        }
        XCTAssertTrue(element.hasFocus, "Expected remote presses to focus \(element.identifier)", file: file, line: line)
    }

    private func assertNextQuestionIsSeparateButton(
        _ nextQuestion: XCUIElement,
        feedback: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(nextQuestion.elementType, .button, "Next question should be exposed as its own button element", file: file, line: line)
        XCTAssertFalse(
            feedback.descendants(matching: .button)["next-question-button"].exists,
            "Next question must not be nested inside the ignored feedback accessibility element",
            file: file,
            line: line
        )
    }

    private func waitForFocus(on element: XCUIElement) {
        for _ in 0..<10 where !element.hasFocus {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func waitForSelection(on element: XCUIElement) {
        for _ in 0..<10 where !element.isSelected {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
    }

    private func assertFocusedElementIsOnScreen(
        _ element: XCUIElement,
        in app: XCUIApplication,
        description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.exists, "\(description) must exist before capturing focus-ring evidence", file: file, line: line)
        XCTAssertTrue(element.isHittable, "Focused \(description) must be hittable before capturing focus-ring evidence", file: file, line: line)

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "App window should exist before capturing focus-ring evidence", file: file, line: line)
        XCTAssertFalse(element.frame.isEmpty, "\(description) frame should be non-empty before capture", file: file, line: line)
        XCTAssertTrue(
            window.frame.insetBy(dx: -1, dy: -1).contains(element.frame),
            "Focused \(description) frame \(element.frame) should be inside the app window \(window.frame) before capture",
            file: file,
            line: line
        )
    }

    private func attachFocusedScreenshot(_ element: XCUIElement, name: String) {
        XCTAssertTrue(element.hasFocus, "\(name) must be focused before capturing focus-ring evidence")
        attachScreenScreenshot(name: name)
    }

    private func attachScreenScreenshot(name: String) {
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachTopCroppedScreenshot(name: String, heightRatio: CGFloat) throws {
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        let screenshot = XCUIScreen.main.screenshot()
        let sourceImage = try XCTUnwrap(UIImage(data: screenshot.pngRepresentation), "Expected screenshot PNG data")
        let width = sourceImage.size.width
        let height = sourceImage.size.height * heightRatio
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = sourceImage.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.cgContext.clip(to: CGRect(x: 0, y: 0, width: width, height: height))
            sourceImage.draw(in: CGRect(origin: .zero, size: sourceImage.size))
        }
        let pngData = try XCTUnwrap(image.pngData(), "Expected cropped screenshot PNG data")
        let attachment = XCTAttachment(data: pngData, uniformTypeIdentifier: "public.png")
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertPracticeHeaderTitleFitsTwoLines(
        _ title: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(title.frame.isEmpty, "Practice title frame should be non-empty before capture", file: file, line: line)
        let lineHeight = UIFont.preferredFont(forTextStyle: .title1).lineHeight
        let maximumTwoLineHeight = (lineHeight * 2.0).rounded(.up) + 8.0
        XCTAssertLessThanOrEqual(
            title.frame.height,
            maximumTwoLineHeight,
            "Practice title height \(title.frame.height) should fit within two title line heights \(maximumTwoLineHeight)",
            file: file,
            line: line
        )
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

    private func pressUntil(
        _ element: XCUIElement,
        exists expectedExistence: Bool,
        remote: XCUIRemote,
        buttons: [XCUIRemote.Button],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for button in buttons {
            if element.exists == expectedExistence { return }
            remote.press(button)
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        XCTAssertEqual(element.exists, expectedExistence, file: file, line: line)
    }

    private func anyLabel(in app: XCUIApplication, contains needle: String) -> Bool {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", needle)).firstMatch.exists
    }

    private static let fixedFrenchQuestionText = "Le certificat d'opérateur radioamateur est valide pour:"
}

private enum PlatformAuditScreen: String {
    case categories
    case practice
    case morse
    case about

    @MainActor
    func waitElement(in app: XCUIApplication) -> XCUIElement {
        switch self {
        case .categories:
            app.staticTexts["Practice categories"].firstMatch
        case .practice:
            app.staticTexts["An Amateur Radio Operator Certificate is valid for:"].firstMatch
        case .morse:
            app.descendants(matching: .any)["tv-morse-screen"].firstMatch
        case .about:
            app.staticTexts["About Canadian Ham"].firstMatch
        }
    }
}
