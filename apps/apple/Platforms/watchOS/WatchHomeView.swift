import SwiftUI

enum WatchSection: String, CaseIterable, Identifiable {
    case practice
    case morse
    case alphabet

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .practice: "Practice"
        case .morse: "Morse"
        case .alphabet: "Alphabet"
        }
    }
}

struct WatchHomeView: View {
    @State private var morseSettings = WatchMorseSettings()

    var body: some View {
        NavigationStack {
            List(WatchSection.allCases) { section in
                NavigationLink(value: section) {
                    Text(section.title) // l10n: localized
                }
                .accessibilityIdentifier("watch-section-\(section.id)")
            }
            .navigationTitle("Canadian Ham")
            .navigationDestination(for: WatchSection.self) { section in
                if section == .practice {
                    WatchPracticeView()
                } else if section == .morse {
                    WatchMorseView(settings: $morseSettings)
                } else {
                    WatchSectionPlaceholder(section: section)
                }
            }
        }
    }
}

private struct WatchSectionPlaceholder: View {
    let section: WatchSection

    var body: some View {
        ScrollView {
            Text("Coming soon")
                .accessibilityIdentifier("watch-placeholder-\(section.id)")
        }
        .navigationTitle(section.title) // l10n: localized
    }
}
