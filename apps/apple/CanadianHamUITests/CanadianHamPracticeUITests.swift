import XCTest

final class CanadianHamPracticeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCanPracticeInFrenchAndSeeFeedback() throws {
        let app = XCUIApplication()
        app.launch()

        navigateToPracticeIfNeeded(in: app)

        let languagePicker = app.segmentedControls["question-language-picker"].firstMatch
        XCTAssertTrue(languagePicker.waitForExistence(timeout: 10), "Question language picker should be reachable in practice")
        languagePicker.buttons["Français"].tap()

        let answerButton = app.buttons["answer-A-button"].firstMatch
        XCTAssertTrue(answerButton.waitForExistence(timeout: 10), "An answer button should be reachable")
        answerButton.tap()

        let feedbackAppeared = app.staticTexts["Correct"].waitForExistence(timeout: 5)
            || app.staticTexts["Incorrect"].waitForExistence(timeout: 5)
        XCTAssertTrue(feedbackAppeared, "Answer feedback should appear after selecting an answer")
    }

    private func navigateToPracticeIfNeeded(in app: XCUIApplication) {
        if app.buttons["answer-A-button"].firstMatch.waitForExistence(timeout: 10) {
            return
        }

        let firstCategory = app.staticTexts["Regulations and Policies"].firstMatch
        if firstCategory.waitForExistence(timeout: 5) {
            firstCategory.tap()
        }
    }
}
