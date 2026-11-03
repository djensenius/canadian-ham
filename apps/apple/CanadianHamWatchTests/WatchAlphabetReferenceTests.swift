import CanadianHamMorseEngine
import XCTest
@testable import CanadianHamWatch

final class WatchAlphabetReferenceTests: XCTestCase {
    func testAllLettersMatchL00201PhoneticsAndSharedMorseTable() {
        // Lessons are deliberately not watch resources. The pnpm test source check
        // compares the reference directly with L-002-01 in the repository.
        let expectedWords = [
            "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel", "India",
            "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo",
            "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu",
        ]
        let letters = WatchAlphabetReference.letters
        XCTAssertEqual(letters.map(\.character), Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init))
        XCTAssertEqual(letters.map(\.phoneticWord), expectedWords.map(Optional.some))
        assertSharedMorseAndUniqueIDs(letters, expectedCount: 26)
    }

    func testAllDigitsMatchSharedMorseTableWithoutPhonetics() {
        let digits = WatchAlphabetReference.digits
        XCTAssertEqual(digits.map(\.character), Array("0123456789").map(String.init))
        XCTAssertTrue(digits.allSatisfy { $0.phoneticWord == nil })
        assertSharedMorseAndUniqueIDs(digits, expectedCount: 10)
        XCTAssertEqual(Set((WatchAlphabetReference.letters + digits).map(\.id)).count, 36)
    }

    func testSpokenPatternsUseLocalizedWordsAndKeepInternationalPhonetics() throws {
        for language in ["en", "fr", "fr-CA"] {
            let locale = Locale(identifier: language)
            let bundle = WatchLanguage.bundle(for: locale)
            XCTAssertNotEqual(bundle.bundleURL, Bundle.main.bundleURL, "The test must use compiled localization resources")
            let dot = String(localized: "Dot", bundle: bundle, locale: locale)
            let dash = String(localized: "Dash", bundle: bundle, locale: locale)
            XCTAssertEqual(dot, language == "en" ? "Dot" : "Point")
            XCTAssertEqual(dash, language == "en" ? "Dash" : "Trait")
            for entry in WatchAlphabetReference.letters + WatchAlphabetReference.digits {
                let spoken = entry.pattern.map { $0 == "." ? dot : dash }.joined(separator: ", ")
                let expected = [entry.character, entry.phoneticWord, spoken].compactMap { $0 }.joined(separator: ", ")
                XCTAssertEqual(entry.accessibilityLabel(dot: dot, dash: dash), expected, "\(language): \(entry.character)")
                XCTAssertFalse(entry.accessibilityLabel(dot: dot, dash: dash).contains("."))
                XCTAssertFalse(entry.accessibilityLabel(dot: dot, dash: dash).contains("—"))
            }
        }
        let a = try XCTUnwrap(WatchAlphabetReference.letters.first)
        XCTAssertEqual(a.visualPattern, "• —")
        XCTAssertEqual(a.accessibilityLabel(dot: "Dot", dash: "Dash"), "A, Alfa, Dot, Dash")
        XCTAssertEqual(a.accessibilityLabel(dot: "Point", dash: "Trait"), "A, Alfa, Point, Trait")
    }

    private func assertSharedMorseAndUniqueIDs(_ entries: [WatchAlphabetEntry], expectedCount: Int) {
        XCTAssertEqual(entries.count, expectedCount)
        XCTAssertEqual(Set(entries.map(\.id)).count, expectedCount)
        for entry in entries {
            XCTAssertEqual(entry.pattern, morseCodeTable[entry.character], entry.character)
            XCTAssertFalse(entry.pattern.isEmpty)
            XCTAssertTrue(entry.pattern.allSatisfy { $0 == "." || $0 == "-" })
            XCTAssertEqual(entry.visualPattern.split(separator: " ").count, entry.pattern.count)
        }
    }
}
