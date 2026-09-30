import SwiftUI

struct InvalidTextFixture: View {
    let wrappedKey: String
    let marked: String
    let model: UnknownTextModel
    let localized: LocalizedStringResource
    let text: LocalizedStringKey
    let runtime: String
    let s: String

    var body: some View {
        let text = "Runtime value from a same-name clash"

        Text("Literal \(wrappedKey)")
        Text(LocalizedStringKey(wrappedKey))
        Text(makeTitle())
        Text(model.title)
        Text(marked) // l10n: localized
        Text(localized) // l10n: localized
        Text(text)
        Text("" + runtime)
        Text("x".uppercased())
        Text(verbatim: "" + runtime)
        Text("Question \(model.title)")
        Text("Answer \(model.name)")
            .accessibilityLabel("" + s)
        Text(LocalizedStringKey("" + runtime))
        Text(LocalizedStringKey.init(marked)) // l10n: localized
    }

    private func makeTitle() -> String { wrappedKey }
}

struct UnknownTextModel {
    let title: String
    let name: String
}
