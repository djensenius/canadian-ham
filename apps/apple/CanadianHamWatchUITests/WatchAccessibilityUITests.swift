import XCTest

/// Every audit uses the full default API, without handlers, masks or runtime skips.
final class WatchAccessibilityUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testEnglishHomeAudit() throws { try audit(.home, language: "en") }
    @MainActor func testFrenchHomeAudit() throws { try audit(.home, language: "fr") }
    @MainActor func testEnglishPracticeQuestionAudit() throws { try audit(.question, language: "en") }
    @MainActor func testFrenchPracticeQuestionAudit() throws { try audit(.question, language: "fr") }
    @MainActor func testEnglishPracticeFeedbackAudit() throws { try audit(.feedback, language: "en") }
    @MainActor func testFrenchPracticeFeedbackAudit() throws { try audit(.feedback, language: "fr") }
    @MainActor func testEnglishMorseBeforeAnswerAudit() throws { try audit(.morse, language: "en") }
    @MainActor func testFrenchMorseBeforeAnswerAudit() throws { try audit(.morse, language: "fr") }
    @MainActor func testEnglishMorseAfterAnswerAudit() throws { try audit(.morseFeedback, language: "en") }
    @MainActor func testFrenchMorseAfterAnswerAudit() throws { try audit(.morseFeedback, language: "fr") }
    @MainActor func testEnglishMorseSettingsAudit() throws { try audit(.outputSettings, language: "en") }
    @MainActor func testFrenchMorseSettingsAudit() throws { try audit(.outputSettings, language: "fr") }
    @MainActor func testEnglishReferenceAudit() throws { try audit(.reference, language: "en") }
    @MainActor func testFrenchReferenceAudit() throws { try audit(.reference, language: "fr") }
    @MainActor func testEnglishSettingsAudit() throws { try audit(.settings, language: "en") }
    @MainActor func testFrenchSettingsAudit() throws { try audit(.settings, language: "fr") }

    @MainActor func testEnglishLargestTextControlsAndLongQuestion() { checkLargestText(language: "en") }
    @MainActor func testFrenchLargestTextControlsAndLongQuestion() { checkLargestText(language: "fr") }

    @MainActor
    func testSessionLanguageOverrideUpdatesSwiftUIAndBundleLookupsAndResets() {
        let app = launch(language: "en")
        enter("settings", in: app)
        tap(app.buttons["watch-language-french"], in: app)
        XCTAssertTrue(app.navigationBars["Réglages"].exists)
        XCTAssertTrue(app.buttons["watch-language-french"].isSelected)
        back(app)
        reveal(app.buttons["watch-section-practice"], in: app)
        XCTAssertEqual(app.buttons["watch-section-practice"].label, "S’exercer")
        enter("alphabet", in: app)
        XCTAssertEqual(app.staticTexts["watch-alphabet-row-A"].label, "A, Alfa, Point, Tiret")
        back(app)
        enter("practice", in: app)
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["watch-question"].label, "La puissance s'exprime en:")
        tap(app.buttons["watch-answer-0"], in: app)
        XCTAssertEqual(app.staticTexts["watch-feedback"].label, "Mauvaise réponse")
        reveal(app.staticTexts["watch-english-fallback"], in: app)
        XCTAssertEqual(app.staticTexts["watch-english-fallback"].label, "Explication en anglais")
        back(app)
        enter("morse", in: app)
        openOutputSettings(app)
        XCTAssertEqual(app.switches["watch-morse-haptics"].label, "Vibrations")
        reveal(app.staticTexts["Point léger, tiret ascendant"], in: app)
        tap(app.buttons["watch-morse-settings-done"], in: app)
        tap(app.buttons["watch-morse-play"], in: app)
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 20))
        reveal(app.buttons["watch-morse-answer-0"], in: app)
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].label.hasPrefix("Lettre "))
        tap(app.buttons["watch-morse-answer-0"], in: app)
        reveal(app.staticTexts["watch-morse-pattern"], in: app)
        XCTAssertEqual(app.staticTexts["watch-morse-pattern"].label, "Point, Tiret, Point")
        back(app)
        enter("settings", in: app)
        tap(app.buttons["watch-language-english"], in: app)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        tap(app.buttons["watch-language-system"], in: app)
        XCTAssertTrue(app.buttons["watch-language-system"].isSelected)
        tap(app.buttons["watch-language-french"], in: app)
        app.terminate()
        app.launch()
        XCTAssertEqual(app.buttons["watch-section-practice"].label, "Practice")
        enter("settings", in: app)
        XCTAssertTrue(app.buttons["watch-language-system"].isSelected)
    }

    private enum Screen: String {
        case home, question, feedback, morse, morseFeedback, outputSettings, reference, settings
    }

    @MainActor
    private func audit(_ screen: Screen, language: String) throws {
        let app = launch(language: language)
        switch screen {
        case .home: break
        case .question, .feedback:
            enter("practice", in: app)
            XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 10))
            if screen == .feedback {
                tap(app.buttons["watch-answer-0"], in: app)
                XCTAssertTrue(app.staticTexts["watch-feedback"].waitForExistence(timeout: 5))
            }
        case .morse, .morseFeedback, .outputSettings:
            enter("morse", in: app)
            XCTAssertTrue(app.staticTexts["watch-morse-prompt"].waitForExistence(timeout: 5))
            if screen == .outputSettings {
                openOutputSettings(app)
            } else {
                tap(app.buttons["watch-morse-play"], in: app)
                XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 20))
                if screen == .morseFeedback {
                    tap(app.buttons["watch-morse-answer-0"], in: app)
                    XCTAssertTrue(app.staticTexts["watch-morse-feedback"].waitForExistence(timeout: 5))
                }
            }
        case .reference: enter("alphabet", in: app)
        case .settings: enter("settings", in: app)
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(language)-\(screen.rawValue)-largest-text-before-full-audit"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        try app.performAccessibilityAudit()
    }

    @MainActor
    private func checkLargestText(language: String) {
        let app = launch(language: language)
        enter("practice", in: app)
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 10))
        for index in 0..<4 {
            let answer = app.buttons["watch-answer-\(index)"]
            reveal(answer, in: app)
            XCTAssertFalse(answer.label.isEmpty)
        }
        tap(app.buttons["watch-answer-0"], in: app)
        reveal(app.staticTexts["watch-selected-answer"], in: app)
        XCTAssertTrue(app.staticTexts["watch-selected-answer"].isSelected)
        reveal(app.staticTexts["watch-correct-answer"], in: app)
        reveal(app.staticTexts["watch-explanation"], in: app)
        tap(app.buttons["watch-next"], in: app)
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 5))
        let question = app.staticTexts["watch-question"]
        XCTAssertEqual(question.label, language == "fr"
            ? "Quelle est la largeur de bande autorisée dans les bandes de 6 mètres et 2 mètres?"
            : "What is the maximum authorized bandwidth on the 6-metre and 2-metre bands?")
        keepScreenshot("\(language)-long-official-question-largest", app: app)
        tap(app.buttons["watch-crown-open"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["watch-crown-selection"].waitForExistence(timeout: 5))
        // The Crown selects; touch scroll keeps the confirm button reachable for long choices.
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.25)
        let confirm = app.buttons["watch-confirm"]
        for _ in 0..<20 {
            if confirm.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(confirm.isHittable)
        keepScreenshot("\(language)-crown-confirm-largest", app: app)
        confirm.tap()
        XCTAssertTrue(app.staticTexts["watch-feedback"].waitForExistence(timeout: 5))
        back(app)
        enter("morse", in: app)
        openOutputSettings(app)
        for id in ["watch-morse-haptics", "watch-morse-tone"] {
            reveal(app.switches[id], in: app)
        }
        for id in ["watch-morse-haptic-style", "watch-morse-speed"] {
            reveal(app.buttons[id], in: app)
            XCTAssertTrue(app.buttons[id].isHittable)
        }
        tap(app.buttons["watch-morse-settings-done"], in: app)
        tap(app.buttons["watch-morse-play"], in: app)
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 20))
        for index in 0..<4 { reveal(app.buttons["watch-morse-answer-\(index)"], in: app) }
        tap(app.buttons["watch-morse-answer-0"], in: app)
        reveal(app.staticTexts["watch-morse-selected-answer"], in: app)
        XCTAssertTrue(app.staticTexts["watch-morse-selected-answer"].isSelected)
        reveal(app.staticTexts["watch-morse-correct-answer"], in: app)
        tap(app.buttons["watch-morse-next"], in: app)
        back(app)
        enter("settings", in: app)
        for language in ["system", "english", "french"] {
            reveal(app.buttons["watch-language-\(language)"], in: app)
        }
        reveal(app.staticTexts["watch-language-session-note"], in: app)
    }

    @MainActor
    private func keepScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func launch(language: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "fr" ? "fr_CA" : "en_CA",
                               "-watchPracticeSeed", "3121", "-watchMorseSeed", "3121",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["watch-section-practice"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func enter(_ section: String, in app: XCUIApplication) { tap(app.buttons["watch-section-\(section)"], in: app) }

    @MainActor
    private func openOutputSettings(_ app: XCUIApplication) {
        tap(app.buttons["watch-morse-settings"], in: app)
        XCTAssertTrue(app.switches["watch-morse-haptics"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func back(_ app: XCUIApplication) { app.navigationBars.buttons.firstMatch.tap() }

    @MainActor
    private func tap(_ target: XCUIElement, in app: XCUIApplication) {
        reveal(target, in: app)
        target.tap()
    }

    @MainActor
    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        for attempt in 0..<80 {
            let top = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : 28
            if target.exists && target.isHittable && target.frame.minY >= top {
                let availableHeight = app.frame.maxY - top - 4
                // A partly visible watch button can be hittable while its centre is
                // outside the safe tap area. Require the whole control when it fits;
                // long official prose instead needs its start reachable for reading.
                if target.frame.maxY <= app.frame.maxY - 4 || target.frame.height > availableHeight { return }
            }
            // A lazy list keeps its scroll position on Back, so a target above the viewport may not
            // be in the hierarchy at all. After 40 forward swipes without finding it, scroll back up.
            let backwards = (target.exists && target.frame.minY < top) || (!target.exists && attempt >= 40)
            let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let upper = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            (backwards ? upper : lower).press(forDuration: 0.05, thenDragTo: backwards ? lower : upper,
                                             withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTFail("Could not reach \(target.identifier): \(target.frame)")
    }
}
