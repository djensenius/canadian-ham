import SwiftUI

struct AccessibleSecondaryButtonLabel: View {
    let title: String
    @Environment(\.isEnabled) private var isEnabled

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
                        isEnabled ? DesignTokens.Colors.border : DesignTokens.Colors.inkMuted,
                        style: StrokeStyle(lineWidth: 1, dash: isEnabled ? [] : [5, 4])
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

struct AccessiblePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(isEnabled ? DesignTokens.Colors.paper : DesignTokens.Colors.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 44)
            .background(isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.paperInset, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.inkMuted,
                        style: StrokeStyle(lineWidth: 1, dash: isEnabled ? [] : [5, 4])
                    )
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
