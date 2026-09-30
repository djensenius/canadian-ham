import SwiftUI

struct InvalidTextFixture: View {
    let content: String
    let identifier: String
    let localized: LocalizedStringKey
    let unmarked: String

    var body: some View {
        Text(content) // l10n: content
        Text(identifier) // l10n: verbatim
        Text(unmarked)
        Text(localized)
        Text("Literal")
        Text(String(localized: "Localized literal"))
    }
}
