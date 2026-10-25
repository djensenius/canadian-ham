import XCTest
import CanadianHamContent
import CanadianHamEngine
import CanadianHamMorseEngine
@testable import CanadianHamWatch

final class CanadianHamWatchTests: XCTestCase {
    func testPlannedSections() {
        XCTAssertEqual(WatchSection.allCases.map(\.id), ["practice", "morse", "alphabet"])
    }

    func testSharedPackagesOnWatch() throws {
        var firstRng = Pcg32(seed: "watch-smoke")
        var secondRng = Pcg32(seed: "watch-smoke")
        XCTAssertEqual(try shuffled([0, 1, 2, 3], rng: &firstRng),
                       try shuffled([0, 1, 2, 3], rng: &secondRng))
        XCTAssertEqual(ContentLanguage(rawValue: "fr"), .fr)
        let sequence = try textToTimedMorse("A")
        XCTAssertEqual(sequence.normalizedText, "A")
        XCTAssertEqual(sequence.symbols.filter { $0.kind == .dot || $0.kind == .dash }.map(\.kind), [.dot, .dash])
    }

    func testIndependentOfflineBundle() throws {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.bundleIdentifier, "org.davidjensenius.CanadianHam.watchkitapp")
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "WKApplication") as? Bool, true)
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "WKRunsIndependentlyOfCompanionApp") as? Bool, true)
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "UIBackgroundModes"))
        XCTAssertNil(bundle.object(forInfoDictionaryKey: "WKBackgroundModes"))
        let url = try XCTUnwrap(bundle.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let privacy = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])
        XCTAssertEqual(privacy["NSPrivacyTracking"] as? Bool, false)
        for key in ["NSPrivacyTrackingDomains", "NSPrivacyCollectedDataTypes", "NSPrivacyAccessedAPITypes"] {
            XCTAssertEqual((privacy[key] as? [Any])?.count, 0, key)
        }
    }
}
