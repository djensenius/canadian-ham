import XCTest

final class LocalizationCatalogTests: XCTestCase {
    func testEveryCatalogKeyHasFrenchTranslations() throws {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CanadianHam/Resources/Localizable.xcstrings")

        let data = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(StringCatalog.self, from: data)
        XCTAssertEqual(catalog.sourceLanguage, "en")
        XCTAssertFalse(catalog.strings.isEmpty, "Localizable.xcstrings should contain UI keys.")

        var missing: [String] = []
        for (key, entry) in catalog.strings {
            for locale in ["fr", "fr-CA"] {
                let value = entry.localizations?[locale]?.stringUnit?.value.trimmingCharacters(in: .whitespacesAndNewlines)
                if value?.isEmpty != false {
                    missing.append("\(key) [\(locale)]")
                }
            }
        }

        XCTAssertTrue(missing.isEmpty, "Missing French localizations: \(missing.sorted().joined(separator: ", "))")
    }
}

private struct StringCatalog: Decodable {
    let sourceLanguage: String
    let strings: [String: StringCatalogEntry]
}

private struct StringCatalogEntry: Decodable {
    let localizations: [String: StringCatalogLocalization]?
}

private struct StringCatalogLocalization: Decodable {
    let stringUnit: StringCatalogUnit?
}

private struct StringCatalogUnit: Decodable {
    let value: String
}
