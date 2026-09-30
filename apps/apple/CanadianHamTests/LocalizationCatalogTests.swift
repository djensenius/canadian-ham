@testable import CanadianHam
import CanadianHamContent
import XCTest

final class LocalizationCatalogTests: XCTestCase {
    func testEveryCatalogKeyHasFrenchTranslations() throws {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CanadianHam/Resources/Localizable.xcstrings")

        let data = try Data(contentsOf: catalogURL)
        let catalogObject = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(catalogObject["sourceLanguage"] as? String, "en")
        let strings = try XCTUnwrap(catalogObject["strings"] as? [String: Any])
        XCTAssertFalse(strings.isEmpty, "Localizable.xcstrings should contain UI keys.")

        var missing: [String] = []
        for (key, rawEntry) in strings {
            let entry = try XCTUnwrap(rawEntry as? [String: Any], "Catalog entry for \(key) should be an object.")
            XCTAssertNotEqual(entry["extractionState"] as? String, "stale", "Catalog key should not be stale: \(key)")
            guard entry["shouldTranslate"] as? Bool != false else { continue }
            let localizations = entry["localizations"] as? [String: Any]
            for locale in ["fr", "fr-CA"] {
                if !Self.hasTranslatedValue(localizations?[locale]) {
                    missing.append("\(key) [\(locale)]")
                }
            }
        }

        XCTAssertTrue(missing.isEmpty, "Missing French localizations: \(missing.sorted().joined(separator: ", "))")
    }

    func testFrenchRuntimeBundleLocalizesCompilerKeysAndPluralCatalogEntries() throws {
        let frenchBundle = try frenchLocalizationBundle()
        let locale = Locale(identifier: "fr")

        let questionFormat = frenchBundle.localizedString(forKey: "Question %lld of %lld", value: nil, table: nil)
        XCTAssertEqual(String(format: questionFormat, locale: locale, Int64(1), Int64(3)), "Question 1 sur 3")

        XCTAssertEqual(localizedQuestionCount(0, bundle: frenchBundle, locale: locale), "0 question")
        XCTAssertEqual(localizedQuestionCount(1, bundle: frenchBundle, locale: locale), "1 question")
        XCTAssertEqual(localizedQuestionCount(2, bundle: frenchBundle, locale: locale), "2 questions")

        let unansweredFormat = frenchBundle.localizedString(forKey: "%lld unanswered questions count as incorrect.", value: nil, table: nil)
        XCTAssertEqual(String(format: unansweredFormat, locale: locale, Int64(0)), "0 question sans réponse comptera comme incorrecte.")
        XCTAssertEqual(localizedUnansweredQuestionCount(0, bundle: frenchBundle, locale: locale), "0 question sans réponse comptera comme incorrecte.")
        XCTAssertEqual(localizedUnansweredQuestionCount(1, bundle: frenchBundle, locale: locale), "1 question sans réponse comptera comme incorrecte.")
        XCTAssertEqual(localizedUnansweredQuestionCount(2, bundle: frenchBundle, locale: locale), "2 questions sans réponse compteront comme incorrectes.")

        let mockExamSubmittedFormat = frenchBundle.localizedString(forKey: "Mock exam submitted. %@, %lld of %lld.", value: nil, table: nil)
        let passStatus = frenchBundle.localizedString(forKey: "Pass", value: nil, table: nil)
        XCTAssertEqual(
            String(format: mockExamSubmittedFormat, locale: locale, passStatus, Int64(82), Int64(100)),
            "Examen simulé soumis. Réussite, 82 sur 100."
        )
        XCTAssertEqual(frenchBundle.localizedString(forKey: "Next unanswered", value: nil, table: nil), "Question sans réponse suivante")
        XCTAssertEqual(frenchBundle.localizedString(forKey: "Next flagged", value: nil, table: nil), "Question marquée suivante")

        XCTAssertEqual(
            String(localized: "Immediate feedback", bundle: frenchBundle, locale: locale),
            "Rétroaction immédiate"
        )

        XCTAssertEqual(localizedAnsweredOutOfTotal(answered: 3, total: 100), "Answered 3 of 100")
    }

    func testLocalizedNullableTextAndLanguageFallsBackToEnglish() {
        let englishOnly = LocalizedNullableText(en: "English fallback", fr: nil)
        let englishFallback = englishOnly.textAndLanguage(for: .french)
        XCTAssertEqual(englishFallback.text, "English fallback")
        XCTAssertEqual(englishFallback.language, .english)

        let localized = LocalizedNullableText(en: "English", fr: "Français")
        let french = localized.textAndLanguage(for: .french)
        XCTAssertEqual(french.text, "Français")
        XCTAssertEqual(french.language, .french)
    }

    private static func hasTranslatedValue(_ rawLocalization: Any?) -> Bool {
        guard let localization = rawLocalization as? [String: Any] else { return false }
        if let stringUnit = localization["stringUnit"] as? [String: Any],
           let value = stringUnit["value"] as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if let variations = localization["variations"] as? [String: Any] {
            return allVariationLeavesHaveTranslatedValues(variations)
        }
        return false
    }

    private static func allVariationLeavesHaveTranslatedValues(_ node: Any) -> Bool {
        if let stringUnit = (node as? [String: Any])?["stringUnit"] as? [String: Any] {
            let value = stringUnit["value"] as? String
            return value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
        if let dictionary = node as? [String: Any] {
            return !dictionary.isEmpty && dictionary.values.allSatisfy(allVariationLeavesHaveTranslatedValues)
        }
        return true
    }

    private func frenchLocalizationBundle() throws -> Bundle {
        var bundleCandidates = [Bundle.main.bundleURL, Bundle(for: type(of: self)).bundleURL]
        for parent in bundleCandidates.map({ $0.deletingLastPathComponent() }) {
            if let appBundles = try? FileManager.default.contentsOfDirectory(
                at: parent,
                includingPropertiesForKeys: nil
            ).filter({ $0.pathExtension == "app" }) {
                bundleCandidates.append(contentsOf: appBundles)
            }
        }

        for bundleURL in bundleCandidates {
            let lprojCandidates = [
                bundleURL.appendingPathComponent("fr.lproj", isDirectory: true),
                bundleURL.appendingPathComponent("Contents/Resources/fr.lproj", isDirectory: true)
            ]
            for lprojURL in lprojCandidates {
                let stringsURL = lprojURL.appendingPathComponent("Localizable.strings")
                let stringsdictURL = lprojURL.appendingPathComponent("Localizable.stringsdict")
                if FileManager.default.fileExists(atPath: stringsURL.path) || FileManager.default.fileExists(atPath: stringsdictURL.path),
                   let bundle = Bundle(url: lprojURL) {
                    return bundle
                }
            }
        }

        XCTFail("Could not find fr.lproj with compiled Localizable resources. Candidates: \(bundleCandidates.map(\.path).joined(separator: ", "))")
        throw CocoaError(.fileNoSuchFile)
    }
}
