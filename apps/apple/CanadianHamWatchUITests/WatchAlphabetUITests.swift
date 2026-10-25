import XCTest

final class WatchAlphabetUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testEnglishReferenceScrollsToNineAndBack() {
        assertReference(language: "en", lettersTitle: "Letters", digitsTitle: "Digits", dot: "Dot", dash: "Dash", largeText: false)
    }

    @MainActor
    func testFrenchReferenceAtLargeDynamicTypeScrollsToNineAndBack() {
        assertReference(language: "fr", lettersTitle: "Lettres", digitsTitle: "Chiffres", dot: "Point", dash: "Tiret", largeText: true)
    }

    @MainActor
    private func assertReference(language: String, lettersTitle: String, digitsTitle: String, dot: String, dash: String, largeText: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "fr" ? "fr_CA" : "en_CA"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let link = app.buttons["watch-section-alphabet"]
        scrollTo(link, in: app)
        XCTAssertEqual(link.label, "Alphabet")
        link.tap()
        let letters = app.staticTexts["watch-alphabet-letters"]
        XCTAssertTrue(letters.waitForExistence(timeout: 5))
        XCTAssertEqual(letters.label, lettersTitle)
        let a = app.staticTexts["watch-alphabet-row-A"]
        XCTAssertTrue(a.waitForExistence(timeout: 5))
        XCTAssertEqual(a.label, "A, Alfa, \(dot), \(dash)")
        let aHeight = a.frame.height
        let juliett = app.staticTexts["watch-alphabet-row-J"]
        scrollTo(juliett, in: app)
        XCTAssertEqual(juliett.label, "J, Juliett, \(dot), \(dash), \(dash) \(dash)")
        XCTAssertLessThanOrEqual(juliett.frame.maxY, app.frame.maxY, "The phonetic word and pattern are fully reachable")
        let letterScreenshot = XCTAttachment(screenshot: app.screenshot())
        letterScreenshot.name = "\(language)-alphabet-Juliett-\(largeText ? "large" : "default")"
        letterScreenshot.lifetime = .keepAlways
        add(letterScreenshot)
        let digits = app.staticTexts["watch-alphabet-digits"]
        scrollTo(digits, in: app)
        XCTAssertEqual(digits.label, digitsTitle)
        let nine = app.staticTexts["watch-alphabet-row-9"]
        scrollTo(nine, in: app)
        XCTAssertEqual(nine.label, "9, \(dash), \(dash) \(dash), \(dash), \(dot)")
        XCTAssertGreaterThan(nine.frame.height, 0)
        XCTAssertGreaterThanOrEqual(nine.frame.minY, app.navigationBars.firstMatch.frame.maxY)
        XCTAssertLessThanOrEqual(nine.frame.maxY, app.frame.maxY, "The last row is fully reachable")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(language)-alphabet-nine-\(largeText ? "large" : "default")"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["watch-section-practice"].waitForExistence(timeout: 5))
        if largeText {
            // Compare the same row with a normal-size relaunch: verify that the
            // watch runtime actually honored the content-size launch argument.
            app.terminate()
            app.launchArguments.removeLast(2)
            app.launch()
            scrollTo(link, in: app)
            link.tap()
            XCTAssertTrue(a.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(aHeight, a.frame.height, "Large Dynamic Type must increase row height")
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    private func scrollTo(_ target: XCUIElement, in app: XCUIApplication) {
        // Watch lists are lazy. Short touch drags avoid Crown row snapping
        // jumping past a section header or a partly visible reference row.
        for _ in 0..<80 {
            var scrollBack = false
            if target.exists {
                let top = app.navigationBars.firstMatch.frame.maxY
                if target.isHittable && target.frame.minY >= top && target.frame.maxY <= app.frame.maxY { return }
                scrollBack = target.frame.minY < top
            }
            let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
            let upper = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            (scrollBack ? upper : lower).press(forDuration: 0.05, thenDragTo: scrollBack ? lower : upper,
                                               withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Could not reveal \(target.identifier)")
    }
}
