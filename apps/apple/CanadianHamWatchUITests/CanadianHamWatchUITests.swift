import XCTest

final class CanadianHamWatchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchAndNavigateEnglish() {
        assertLaunchAndNavigation(language: "en", practiceTitle: "Practice")
    }

    @MainActor
    func testLaunchAndNavigateFrench() {
        assertLaunchAndNavigation(language: "fr", practiceTitle: "S’exercer")
    }

    @MainActor
    private func assertLaunchAndNavigation(language: String, practiceTitle: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "fr" ? "fr_CA" : "en_CA"]
        app.launch()

        for (section, title) in [("practice", practiceTitle), ("morse", "Morse"), ("alphabet", "Alphabet")] {
            let link = app.buttons["watch-section-\(section)"]
            XCTAssertTrue(link.waitForExistence(timeout: 10), section)
            if !link.isHittable { app.swipeUp() }
            XCTAssertEqual(link.label, title)
            link.tap()
            XCTAssertTrue(app.staticTexts["watch-placeholder-\(section)"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
}
