import SwiftUI

struct AccessibleSecondaryButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .contentShape(Capsule())
            .onTapGesture {
                if isEnabled {
                    configuration.trigger()
                }
            }
    }
}
