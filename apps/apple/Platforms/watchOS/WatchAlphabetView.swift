import SwiftUI

struct WatchAlphabetView: View {
    var body: some View {
        List {
            Section {
                ForEach(WatchAlphabetReference.letters) { entry in
                    WatchAlphabetRow(entry: entry)
                }
            } header: {
                Text("Letters")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("watch-alphabet-letters")
            }
            Section {
                ForEach(WatchAlphabetReference.digits) { entry in
                    WatchAlphabetRow(entry: entry)
                }
            } header: {
                Text("Digits")
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("watch-alphabet-digits")
            }
        }
        .navigationTitle("Alphabet")
        .accessibilityIdentifier("watch-alphabet-list")
    }
}

private struct WatchAlphabetRow: View {
    let entry: WatchAlphabetEntry
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: entry.character) // l10n: verbatim
                .font(.headline)
            if let word = entry.phoneticWord {
                Text(verbatim: word) // l10n: verbatim (international ITU spelling)
                    .font(.body)
            }
            Text(verbatim: entry.visualPattern) // l10n: verbatim
                .font(.body.monospaced())
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: spokenLabel)) // l10n: localized
        .accessibilityIdentifier("watch-alphabet-row-\(entry.character)")
    }

    private var spokenLabel: String {
        entry.accessibilityLabel(dot: String(localized: "Dot", bundle: WatchLanguage.bundle(for: locale), locale: locale), dash: String(localized: "Dash", bundle: WatchLanguage.bundle(for: locale), locale: locale)) // l10n: localized
    }
}
