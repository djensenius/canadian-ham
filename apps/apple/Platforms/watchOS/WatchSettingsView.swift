import SwiftUI

/// Session-only: unlike the phone's persisted preference, this never writes AppleLanguages.
enum WatchLanguage: String, CaseIterable, Identifiable {
    case system, english, french

    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .english: "English"
        case .french: "Français"
        }
    }

    func locale(bundle: Bundle = .main) -> Locale {
        switch self {
        case .system: Locale(identifier: bundle.preferredLocalizations.first ?? "en")
        case .english: Locale(identifier: "en")
        case .french: Locale(identifier: "fr-CA")
        }
    }

    // Foundation's locale parameter formats values; it does not select an lproj.
    // SwiftUI uses the environment locale; explicit String lookups use this bundle too.
    static func bundle(for locale: Locale, in bundle: Bundle = .main) -> Bundle {
        let language = locale.language.languageCode?.identifier == "fr" ? "fr" : "en"
        guard let path = bundle.path(forResource: language, ofType: "lproj"),
              let localized = Bundle(path: path) else { return bundle }
        return localized
    }
}

struct WatchSettingsView: View {
    @Binding var language: WatchLanguage
    @Environment(\.locale) private var locale

    var body: some View {
        List {
            Section("Language") {
                ForEach(WatchLanguage.allCases) { option in
                    Button {
                        language = option
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.title) // l10n: localized
                                .fixedSize(horizontal: false, vertical: true)
                            if option == language {
                                Text("Selected")
                                    .font(.caption)
                            }
                        }
                    }
                    .accessibilityAddTraits(option == language ? [.isSelected] : [])
                    .accessibilityIdentifier("watch-language-\(option.id)")
                }
            }
            Text("Language changes last until the app closes.")
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("watch-language-session-note")
        }
        // watchOS can cache a localized-key navigation title when revisiting
        // this destination. Resolve it explicitly so live overrides update it too.
        .navigationTitle(Text(verbatim: String(localized: "Settings", bundle: WatchLanguage.bundle(for: locale), locale: locale))) // l10n: localized
    }
}
