import SwiftUI

struct AccessibleSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isEnabled, true)
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 44)
            .background(DesignTokens.Colors.paperInset, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isEnabled ? DesignTokens.Colors.border : DesignTokens.Colors.inkMuted,
                        style: StrokeStyle(lineWidth: 1, dash: isEnabled ? [] : [5, 4])
                    )
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .accessibilityRespondsToUserInteraction(isEnabled)
    }
}
