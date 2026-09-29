import SwiftUI

struct AccessibleSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            styledLabel(configuration.label)
                .opacity(isEnabled ? 1 : 0)
            if !isEnabled {
                styledLabel(configuration.label.environment(\.isEnabled, true))
            }
        }
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
    }

    private func styledLabel<Label: View>(_ label: Label) -> some View {
        label
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
    }
}
