import SwiftUI

enum WatchSection: String, CaseIterable, Identifiable {
    case practice
    case morse
    case alphabet
    case settings

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .practice: "Practice"
        case .morse: "Morse"
        case .alphabet: "Alphabet"
        case .settings: "Settings"
        }
    }
}

struct WatchHomeView: View {
    @State private var language = WatchLanguage.system
    @State private var morseSettings = WatchMorseSettings()

    var body: some View {
        NavigationStack {
            List(WatchSection.allCases) { section in
                NavigationLink(value: section) {
                    Text(section.title) // l10n: localized
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityIdentifier("watch-section-\(section.id)")
            }
            .navigationTitle("Canadian Ham")
            .navigationDestination(for: WatchSection.self) { section in
                if section == .practice {
                    WatchPracticeView()
                } else if section == .morse {
                    WatchMorseView(settings: $morseSettings)
                } else if section == .alphabet {
                    WatchAlphabetView()
                } else {
                    WatchSettingsView(language: $language)
                }
            }
        }
        .environment(\.locale, language.locale())
    }
}
