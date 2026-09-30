import SwiftUI

struct AboutView: View {
    let bank: QuestionBank

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("About Canadian Ham")
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)

                paperSection("Bank") {
                    Text("Active bank: \(bank.manifest.bankId)")
                    Text("Effective date: \(bank.manifest.effectiveDate)")
                    Text("Questions: \(bank.questions.count) • Categories: \(bank.categories.count) • Subsections: \(bank.subsections.count)") // l10n: localized
                }

                paperSection("Attribution and development status") {
                    Text(english("Question-bank material and related reference material are sourced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification materials.")) // l10n: content(en)
                    Text(english("The ISED permission request has been drafted but not yet sent or granted. Until written permission is recorded, this app is for private, non-distributed development only and must not claim written permission has been granted.")) // l10n: content(en)
                    Text("Source path: \(bank.manifest.source.path)")
                        .font(DesignTokens.FontScale.caption)
                        .textSelection(.enabled)
                }

                paperSection("Disclaimer") {
                    Text(english("Canadian Ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.")) // l10n: content(en)
                }

                paperSection("Privacy") {
                    Text("This Apple app works offline, uses bundled content, includes no networking code, includes no analytics or telemetry, and stores no progress remotely in this first slice.")
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
