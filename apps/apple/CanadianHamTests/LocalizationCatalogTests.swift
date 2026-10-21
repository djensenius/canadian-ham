@testable import CanadianHam
import CanadianHamContent
import XCTest

final class LocalizationCatalogTests: XCTestCase {
    @MainActor
    func testConceptCheckAnswerStatusMapsShuffledSourceChoices() throws {
        let quiz = try conceptFeedbackQuiz()
        let check = try XCTUnwrap(quiz.conceptChecks.first)
        let permutation = [2, 0, 3, 1]
        let item = LessonQuizRuntimeItem.concept(id: check.id, conceptCheck: check, choicePermutation: permutation)
        let expected = ["Incorrect English fallback.", "Correct English correct.", "Incorrect", "Incorrect English incorrect."]
        for (displayIndex, sourceIndex) in permutation.enumerated() {
            let state = LessonQuizSessionState()
            state.items = [item]
            state.select(sourceIndex, for: item)
            let status = try XCTUnwrap(conceptCheckAnswerStatus(check: check, selectedSourceIndex: state.selectedByItemId[item.id], language: .english))
            XCTAssertEqual(String(status.characters), expected[displayIndex])
        }
    }

    func testConceptCheckAnswerStatusFrenchAndFallbackLanguageMetadata() throws {
        let check = try XCTUnwrap(conceptFeedbackQuiz().conceptChecks.first)
        for (sourceIndex, expectedText, expectedLanguage) in [
            (0, "Rétroaction correcte.", "fr-CA"),
            (1, "Rétroaction incorrecte.", "fr-CA"),
            (2, "English fallback.", "en-CA")
        ] {
            let status = try XCTUnwrap(conceptCheckAnswerStatus(check: check, selectedSourceIndex: sourceIndex, language: .french))
            let feedbackRuns = status.runs.filter { $0.languageIdentifier != nil }
            XCTAssertEqual(feedbackRuns.map { String(status[$0.range].characters) }.joined(), expectedText)
            XCTAssertEqual(Set(feedbackRuns.compactMap(\.languageIdentifier)), [expectedLanguage])
        }
        let english = try XCTUnwrap(conceptCheckAnswerStatus(check: check, selectedSourceIndex: 0, language: .english))
        XCTAssertEqual(english.runs.compactMap(\.languageIdentifier), ["en-CA"])
        XCTAssertEqual(String(english.characters), "Correct English correct.")
    }

    func testConceptCheckAnswerStatusLegacyChoiceAndNoDisclosureBeforeSelection() throws {
        let check = try XCTUnwrap(conceptFeedbackQuiz().conceptChecks.first)
        XCTAssertNil(check.choices[3].feedback, "Legacy choices decode without feedback")
        let legacy = try XCTUnwrap(conceptCheckAnswerStatus(check: check, selectedSourceIndex: 3, language: .french))
        XCTAssertEqual(String(legacy.characters), String(localized: "Incorrect"))
        XCTAssertTrue(legacy.runs.allSatisfy { $0.languageIdentifier == nil })
        XCTAssertNil(conceptCheckAnswerStatus(check: check, selectedSourceIndex: nil, language: .english))
        XCTAssertNil(conceptCheckAnswerStatus(check: check, selectedSourceIndex: -1, language: .english))
        XCTAssertNil(conceptCheckAnswerStatus(check: check, selectedSourceIndex: 4, language: .english))
    }

    private func conceptFeedbackQuiz() throws -> LessonQuiz {
        try JSONDecoder().decode(LessonQuiz.self, from: Data(#"""
        {
          "id": "feedback-quiz", "lessonId": "feedback-lesson", "officialQuestionIds": [],
          "conceptChecks": [{
            "id": "feedback-check", "prompt": {"en": "Choose.", "fr": null},
            "choices": [
              {"text": {"en": "Correct", "fr": null}, "isCorrect": true,
               "feedback": {"en": "English correct.", "fr": "Rétroaction correcte."}},
              {"text": {"en": "Incorrect", "fr": null}, "isCorrect": false,
               "feedback": {"en": "English incorrect.", "fr": "Rétroaction incorrecte."}},
              {"text": {"en": "Fallback", "fr": null}, "isCorrect": false,
               "feedback": {"en": "English fallback.", "fr": null}},
              {"text": {"en": "Legacy", "fr": null}, "isCorrect": false}
            ],
            "explanation": {"en": "General explanation.", "fr": null}
          }]
        }
        """#.utf8))
    }

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

        let sendingPassFormat = frenchBundle.localizedString(forKey: "PASS, 100%%, with %lld errors.", value: nil, table: nil)
        XCTAssertEqual(String(format: sendingPassFormat, locale: locale, Int64(1)), "RÉUSSITE, 100\u{00A0}%, avec 1 erreur.")
        XCTAssertEqual(String(format: sendingPassFormat, locale: locale, Int64(2)), "RÉUSSITE, 100\u{00A0}%, avec 2 erreurs.")

        let sendingDiffFormat = frenchBundle.localizedString(forKey: "%lld total errors: %lld wrong, %lld missing, %lld inserted.", value: nil, table: nil)
        XCTAssertEqual(
            String(format: sendingDiffFormat, locale: locale, Int64(2), Int64(1), Int64(0), Int64(1)),
            "Total des erreurs\u{00A0}: 2; caractères erronés\u{00A0}: 1; caractères manquants\u{00A0}: 0; caractères ajoutés\u{00A0}: 1."
        )

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

        let missingResourceFormat = frenchBundle.localizedString(forKey: "Missing bundled resource: %@.json", value: nil, table: nil)
        XCTAssertEqual(
            String(format: missingResourceFormat, locale: locale, "manifest"),
            "Ressource intégrée manquante : manifest.json"
        )
        XCTAssertEqual(localizedAnsweredOutOfTotal(answered: 3, total: 100), "Answered 3 of 100")
    }

    func testQuestionBankLoadErrorDescriptionUsesFrenchLocale() throws {
        let error = QuestionBankLoadError.missingResource("manifest")
        XCTAssertEqual(error.errorDescription, error.localizedMessage(bundle: .main))

        for localeIdentifier in ["fr", "fr-CA"] {
            let bundle = try localizationBundle(for: localeIdentifier)
            XCTAssertEqual(
                error.localizedMessage(bundle: bundle),
                "Ressource intégrée manquante : manifest.json",
                "QuestionBankLoadError should use the French runtime localization for \(localeIdentifier)."
            )
        }
    }

    func testLanguagePreferenceResolvesSystemAndOverrides() {
        XCTAssertEqual(ApplePreferences.LanguagePreference.system.resolvedLanguage(preferredLanguages: ["fr-CA", "en-CA"]), .french)
        XCTAssertEqual(ApplePreferences.LanguagePreference.system.resolvedLanguage(preferredLanguages: ["en-CA", "fr-CA"]), .english)
        XCTAssertEqual(ApplePreferences.LanguagePreference.system.resolvedLanguage(preferredLanguages: ["de-DE", "fr-CA"]), .french)
        XCTAssertEqual(ApplePreferences.LanguagePreference.system.resolvedLanguage(preferredLanguages: ["de-DE"]), .english)
        XCTAssertEqual(ApplePreferences.LanguagePreference.english.resolvedLanguage(preferredLanguages: ["fr-CA"]), .english)
        XCTAssertEqual(ApplePreferences.LanguagePreference.french.resolvedLanguage(preferredLanguages: ["en-CA"]), .french)
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

    private func localizationBundle(for localeIdentifier: String) throws -> Bundle {
        let bundleCandidates = try localizedResourceBundleCandidates()
        for bundleURL in bundleCandidates {
            let lprojCandidates = [
                bundleURL.appendingPathComponent("\(localeIdentifier).lproj", isDirectory: true),
                bundleURL.appendingPathComponent("Contents/Resources/\(localeIdentifier).lproj", isDirectory: true)
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

        XCTFail("Could not find \(localeIdentifier).lproj with compiled Localizable resources. Candidates: \(bundleCandidates.map(\.path).joined(separator: ", "))")
        throw CocoaError(.fileNoSuchFile)
    }

    private func frenchLocalizationBundle() throws -> Bundle {
        try localizationBundle(for: "fr")
    }

    private func localizedResourceBundleCandidates() throws -> [URL] {
        var bundleCandidates = [Bundle.main.bundleURL, Bundle(for: type(of: self)).bundleURL]
        for parent in bundleCandidates.map({ $0.deletingLastPathComponent() }) {
            if let appBundles = try? FileManager.default.contentsOfDirectory(
                at: parent,
                includingPropertiesForKeys: nil
            ).filter({ $0.pathExtension == "app" }) {
                bundleCandidates.append(contentsOf: appBundles)
            }
        }

        return bundleCandidates
    }
}
