import SwiftUI

struct AccessibleSecondaryButtonLabel: View {
    let title: String
    let isDisabled: Bool

    var body: some View {
        Text(title)
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 44)
            .background(DesignTokens.Colors.paperInset, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isDisabled ? DesignTokens.Colors.inkMuted : DesignTokens.Colors.border,
                        style: StrokeStyle(lineWidth: 1, dash: isDisabled ? [5, 4] : [])
                    )
            }
    }
}

struct AccessibleSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
