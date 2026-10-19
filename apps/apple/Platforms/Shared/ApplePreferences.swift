import CanadianHamEngine
import Foundation

struct ApplePreferences: Codable, Equatable, Sendable {
    enum PracticeMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case immediate
        case reviewLater = "review-later"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .immediate: "Immediate feedback"
            case .reviewLater: "Review later"
            }
        }
    }

    enum Theme: String, Codable, CaseIterable, Identifiable, Sendable {
        case system
        case light
        case dark

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    enum LanguagePreference: String, Codable, CaseIterable, Identifiable, Sendable {
        case system
        case english = "en"
        case french = "fr"

        var id: String { rawValue }

        func resolvedLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> BankLanguage {
            switch self {
            case .system:
                Self.systemLanguage(preferredLanguages: preferredLanguages)
            case .english:
                .english
            case .french:
                .french
            }
        }

        func requiresInterfaceRestart(
            currentLocalizations: [String] = Bundle.main.preferredLocalizations,
            preferredLanguages: [String] = Locale.preferredLanguages
        ) -> Bool {
            resolvedLanguage(preferredLanguages: preferredLanguages) != BankLanguage.systemPreferred(preferredLanguages: currentLocalizations)
        }

        static func systemLanguage(preferredLanguages: [String] = Locale.preferredLanguages) -> BankLanguage {
            BankLanguage.systemPreferred(preferredLanguages: preferredLanguages)
        }
    }

    var practiceMode: PracticeMode
    var examTimerEnabled: Bool
    var language: LanguagePreference
    var theme: Theme
    var activeBankId: CourseBankID

    static let `default` = ApplePreferences(
        practiceMode: .immediate,
        examTimerEnabled: false,
        language: .system,
        theme: .system,
        activeBankId: .basic
    )
}
