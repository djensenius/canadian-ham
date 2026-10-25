import XCTest

final class WatchMorseUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPlayReplayAnswerNextAndNoEarlyReveal() {
        let app = launchMorse()
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        XCTAssertFalse(app.staticTexts["watch-morse-correct-answer"].exists)
        XCTAssertFalse(app.buttons["watch-morse-answer-0"].exists)
        let play = app.buttons["watch-morse-play"]
        XCTAssertEqual(play.label, "Play Morse")
        play.tap()
        XCTAssertTrue(app.staticTexts["watch-morse-playing"].waitForExistence(timeout: 3))
        XCTAssertFalse(play.isEnabled)
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        XCTAssertFalse(app.staticTexts["watch-morse-correct-answer"].exists)
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 20))
        reveal(play, in: app)
        XCTAssertEqual(play.label, "Replay")
        play.tap()
        XCTAssertTrue(app.staticTexts["watch-morse-playing"].waitForExistence(timeout: 3))
        XCTAssertFalse(play.isEnabled)
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        let finished = NSPredicate(format: "enabled == true")
        expectation(for: finished, evaluatedWith: play)
        waitForExpectations(timeout: 20)
        let choices = (0..<4).map { app.buttons["watch-morse-answer-\($0)"].label }
        XCTAssertEqual(Set(choices).count, 4)
        let answer = app.buttons["watch-morse-answer-0"]
        reveal(answer, in: app)
        let chosen = answer.label
        answer.tap()
        let feedback = app.staticTexts["watch-morse-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        let correct = app.staticTexts["watch-morse-correct-answer"]
        reveal(correct, in: app)
        XCTAssertEqual(feedback.label, chosen == correct.label ? "Correct" : "Incorrect")
        XCTAssertTrue(app.staticTexts["watch-morse-pattern"].exists)
        let firstLetter = correct.label
        reveal(app.buttons["watch-morse-next"], in: app)
        app.buttons["watch-morse-next"].tap()
        XCTAssertTrue(app.staticTexts["watch-morse-prompt"].waitForExistence(timeout: 5))
        XCTAssertFalse(feedback.exists)
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        XCTAssertFalse(correct.exists)
        XCTAssertFalse(app.buttons["watch-morse-answer-0"].exists)
        reveal(play, in: app)
        play.tap()
        // Advancing while playing must cancel, not finish the old round later.
        reveal(app.buttons["watch-morse-next"], in: app)
        app.buttons["watch-morse-next"].tap()
        reveal(play, in: app)
        XCTAssertEqual(play.label, "Play Morse")
        XCTAssertTrue(play.isEnabled)
        play.tap()
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 20))
        reveal(app.buttons["watch-morse-answer-0"], in: app)
        app.buttons["watch-morse-answer-0"].tap()
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        reveal(correct, in: app)
        XCTAssertTrue(choices.contains(firstLetter))
        XCTAssertEqual(correct.label.count, 1)
    }

    @MainActor
    func testIndependentOutputsTextAlternativeAndSessionOnlySettings() {
        let app = launchMorse()
        openSettings(app)
        let haptics = app.switches["watch-morse-haptics"]
        let tone = app.switches["watch-morse-tone"]
        XCTAssertEqual(haptics.value as? String, "1")
        XCTAssertEqual(tone.value as? String, "0")
        haptics.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
        tone.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(tone.value as? String, "1")
        let speed = app.buttons["watch-morse-speed"]
        reveal(speed, in: app)
        XCTAssertTrue(speed.exists)
        speed.tap()
        // Native watch Picker offers tap alternatives to Crown scrolling.
        let slow = app.buttons["1 WPM"]
        XCTAssertTrue(slow.waitForExistence(timeout: 5))
        slow.tap()
        closeSettings(app)
        XCTAssertFalse(app.staticTexts["watch-morse-no-output"].exists)
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        reveal(app.buttons["watch-morse-play"], in: app)
        app.buttons["watch-morse-play"].tap()
        XCTAssertTrue(app.buttons["watch-morse-answer-0"].waitForExistence(timeout: 30), "Tone-only playback completes")
        XCTAssertFalse(app.staticTexts["watch-morse-output-error"].exists)
        openSettings(app)
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(tone.value as? String, "1")
        tone.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5)).tap()
        closeSettings(app)
        let unavailable = app.staticTexts["watch-morse-no-output"]
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        XCTAssertEqual(unavailable.label, "Haptics and tone are off. Request the text pattern to practise.")
        XCTAssertFalse(app.buttons["watch-morse-play"].isEnabled)
        XCTAssertFalse(app.staticTexts["watch-morse-pattern"].exists)
        let show = app.buttons["watch-morse-show-pattern"]
        reveal(show, in: app)
        show.tap()
        let pattern = app.staticTexts["watch-morse-pattern"]
        XCTAssertTrue(pattern.waitForExistence(timeout: 5))
        XCTAssertTrue(pattern.label.contains("Dot") || pattern.label.contains("Dash"))
        XCTAssertFalse(app.staticTexts["watch-morse-correct-answer"].exists)
        reveal(app.buttons["watch-morse-answer-0"], in: app)
        app.buttons["watch-morse-answer-0"].tap()
        XCTAssertTrue(app.staticTexts["watch-morse-feedback"].waitForExistence(timeout: 5))
        // Output settings are lifted above the destination, but never persisted.
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["watch-section-morse"].tap()
        XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
        openSettings(app)
        XCTAssertEqual(haptics.value as? String, "0")
        XCTAssertEqual(tone.value as? String, "0")
        closeSettings(app)
        app.terminate()
        app.launch()
        app.buttons["watch-section-morse"].tap()
        openSettings(app)
        XCTAssertEqual(haptics.value as? String, "1")
        XCTAssertEqual(tone.value as? String, "0")
    }

    @MainActor
    private func launchMorse() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_CA", "-watchMorseSeed", "3121"]
        app.launch()
        XCTAssertTrue(app.buttons["watch-section-morse"].waitForExistence(timeout: 10))
        app.buttons["watch-section-morse"].tap()
        XCTAssertTrue(app.staticTexts["watch-morse-prompt"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func openSettings(_ app: XCUIApplication) {
        let settings = app.buttons["watch-morse-settings"]
        reveal(settings, in: app)
        settings.tap()
        XCTAssertTrue(app.switches["watch-morse-haptics"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func closeSettings(_ app: XCUIApplication) {
        let done = app.buttons["watch-morse-settings-done"]
        reveal(done, in: app)
        done.tap()
        XCTAssertTrue(app.staticTexts["watch-morse-prompt"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func reveal(_ target: XCUIElement, in app: XCUIApplication) {
        // Form rows are lazy on watchOS; scroll before requiring existence.
        for _ in 0..<16 {
            if target.exists && target.isHittable { return }
            let above = target.exists && target.frame.maxY <= 56
            XCUIDevice.shared.rotateDigitalCrown(delta: above ? -0.5 : 0.5)
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Could not reveal \(target.identifier): \(target.frame)")
    }
}
