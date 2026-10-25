import XCTest

final class WatchPracticeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTapFeedbackNextAndRelaunchDoesNotRestoreAnswer() {
        let app = launchPractice(language: "en")
        let question = app.staticTexts["watch-question"].label
        let answer = app.buttons["watch-answer-0"]
        reveal(answer, in: app)
        let chosenText = answer.label
        answer.tap()
        let feedback = app.staticTexts["watch-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(["Correct", "Incorrect"].contains(feedback.label))
        XCTAssertFalse(app.buttons["watch-answer-0"].exists)
        let correct = app.staticTexts["watch-correct-answer"]
        reveal(correct, in: app)
        XCTAssertFalse(correct.label.isEmpty)
        if feedback.label == "Correct" { XCTAssertEqual(correct.label, chosenText) }
        let explanation = app.staticTexts["watch-explanation"]
        reveal(explanation, in: app)
        XCTAssertTrue(explanation.label.contains("Why the correct answer is right:"))
        XCTAssertFalse(app.buttons["Hint"].exists)
        let next = app.buttons["watch-next"]
        reveal(next, in: app)
        next.tap()
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 5))
        XCTAssertNotEqual(app.staticTexts["watch-question"].label, question)
        XCTAssertFalse(feedback.exists)
        let nextAnswer = app.buttons["watch-answer-0"]
        reveal(nextAnswer, in: app)
        nextAnswer.tap()
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["watch-section-practice"].tap()
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 5))
        XCTAssertFalse(feedback.exists)
        reveal(app.buttons["watch-answer-0"], in: app)
        XCTAssertEqual(app.buttons["watch-answer-0"].value as? String, "Not selected")
    }

    @MainActor
    func testCrownSelectionRequiresConfirmAndFrenchFeedbackLabelsEnglishFallback() {
        let app = launchPractice(language: "fr")
        let open = app.buttons["watch-crown-open"]
        reveal(open, in: app)
        // Crown scrolling on the question must not submit.
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.5)
        XCTAssertFalse(app.staticTexts["watch-feedback"].exists)
        reveal(open, in: app)
        open.tap()
        let picker = app.otherElements["watch-crown-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        var seenAnswers: Set<String> = [app.staticTexts["watch-crown-selection"].label]
        // Native watchOS XCUIAutomation exposes Crown rotation (but not adjust(toPickerWheelValue:)).
        for _ in 0..<16 {
            XCUIDevice.shared.rotateDigitalCrown(delta: 0.05)
            seenAnswers.insert(app.staticTexts["watch-crown-selection"].label)
            print("Crown selected answers: \(seenAnswers.count); current: \(app.staticTexts["watch-crown-selection"].label)")
            XCTAssertTrue(app.buttons["watch-confirm"].exists)
            XCTAssertFalse(app.staticTexts["watch-feedback"].exists)
            if seenAnswers.count == 4 { break }
        }
        XCTAssertEqual(seenAnswers.count, 4, "The Crown can select every answer without submitting")
        let selected = app.staticTexts["watch-crown-selection"].label
        reveal(app.buttons["watch-confirm"], in: app)
        app.buttons["watch-confirm"].tap()
        let feedback = app.staticTexts["watch-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertTrue(["Bonne réponse", "Mauvaise réponse"].contains(feedback.label))
        XCTAssertTrue(app.staticTexts[selected].exists)
        let fallback = app.staticTexts["watch-english-fallback"]
        reveal(fallback, in: app)
        XCTAssertEqual(fallback.label, "Explication en anglais")
        reveal(app.staticTexts["watch-explanation"], in: app)
        XCTAssertTrue(app.staticTexts["watch-explanation"].label.contains("Why the correct answer is right:"))
        reveal(app.buttons["watch-next"], in: app)
        XCTAssertEqual(app.buttons["watch-next"].label, "Suivant")
        app.buttons["watch-next"].tap()
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 5))
        XCTAssertFalse(feedback.exists)
    }

    @MainActor
    private func launchPractice(language: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "fr" ? "fr_CA" : "en_CA"]
        app.launch()
        XCTAssertTrue(app.buttons["watch-section-practice"].waitForExistence(timeout: 10))
        app.buttons["watch-section-practice"].tap()
        XCTAssertTrue(app.staticTexts["watch-question"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<24 {
            if element.isHittable { return }
            if element.frame.maxY <= 56 {
                XCUIDevice.shared.rotateDigitalCrown(delta: -0.15)
            } else {
                XCUIDevice.shared.rotateDigitalCrown(delta: 0.15)
            }
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Could not reveal \(element.identifier), frame=\(element.frame)")
    }
}
