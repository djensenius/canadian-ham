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
    var body: some View {
        NavigationStack {
            List(WatchSection.allCases) { section in
                NavigationLink {
                    WatchSectionPlaceholder(section: section)
                } label: {
                    Text(section.title) // l10n: localized
                }
                .accessibilityIdentifier("watch-section-\(section.id)")
            }
            .navigationTitle("Canadian Ham")
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
