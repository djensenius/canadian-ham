import SwiftUI

private let aboutRBR4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"

struct AboutView: View {
    let bank: QuestionBank

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("About Canadian Ham")
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                paperSection("Bank") {
                    Text("Active bank: \(bank.manifest.bankId), effective \(bank.manifest.effectiveDate).")
                    Text("Questions: \(bank.questions.count); categories: \(bank.categories.count); subsections: \(bank.subsections.count).") // l10n: localized
                }

                paperSection("Sources") {
                    Text("ISED Amateur Radio Operator Certificate Basic Qualification question bank, effective \(bank.manifest.effectiveDate).")
                    Text("Question bank source URL: \(bank.manifest.source.url)")
                        .font(DesignTokens.FontScale.caption)
                        .textSelection(.enabled)
                    Text("RBR-4, Standards for the Operation of Radio Stations in the Amateur Radio Service: \(aboutRBR4CitationURL)")
                        .font(DesignTokens.FontScale.caption)
                        .textSelection(.enabled)
                    Text("ISED provides the Basic exam reference sheet with formulas and block diagrams at the exam; the reference PDFs are source artifacts and are not shipped in the apps.")
                }

                paperSection("Attribution") {
                    // TODO(task-1.1): Replace this draft attribution with the exact wording from the recorded ISED permission before public release. Do not add permission details until task-1.1 records them.
                    Text("TODO before public release: replace this draft attribution with the exact wording from the recorded ISED permission in task-1.1. Written permission details are not recorded yet.")
                        .accessibilityLabel(Text(english("TODO before public release: replace this draft attribution with the exact wording from the recorded ISED permission in task-1.1. Written permission details are not recorded yet."))) // l10n: content(en)
                    Text("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.")
                        .accessibilityLabel(Text(english("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page."))) // l10n: content(en)
                }

                paperSection("Disclaimer") {
                    Text("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.")
                        .accessibilityLabel(Text(english("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner."))) // l10n: content(en)
                }

                paperSection("Privacy") {
                    Text("This Apple app works fully offline with bundled content, has no accounts, analytics, telemetry, ads, networking code, iCloud sync, push notifications, remote config, or third-party SDKs, and stores progress only on this device unless you export it.")
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("About")
    }

    private func paperSection<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                content()
            }
            .font(DesignTokens.FontScale.body)
            .foregroundStyle(DesignTokens.Colors.ink)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
        )
    }
}

private func english(_ string: String) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributed
}
