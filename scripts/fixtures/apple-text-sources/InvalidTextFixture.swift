import SwiftUI

struct InvalidTextFixture: View {
    let wrappedKey: String
    let marked: String
    let model: UnknownTextModel
    let localized: LocalizedStringResource

    var body: some View {
        let text = "Runtime value from a same-name clash"

        Text("Literal \(wrappedKey)")
        Text(LocalizedStringKey(wrappedKey))
        Text(makeTitle())
        Text(model.title)
        Text(marked) // l10n: localized
        Text(localized) // l10n: localized
        Text(text)
    }

    private func makeTitle() -> String { wrappedKey }
}

struct UnknownTextModel {
    let title: String
}
