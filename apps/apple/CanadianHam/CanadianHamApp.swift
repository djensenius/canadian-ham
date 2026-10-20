import SwiftUI

@main
struct CanadianHamApp: App {
    @StateObject private var appSettings = AppSettingsModel()

    var body: some Scene {
        WindowGroup {
#if DEBUG && os(iOS)
            RootView(appSettings: appSettings)
                .forceRegularHorizontalSizeClassForUITestsIfNeeded()
                .morseReduceMotionControlForUITestsIfNeeded()
#else
            RootView(appSettings: appSettings)
#endif
        }
        #if os(macOS)
        .defaultSize(width: 1_080, height: 760)
        #endif

#if os(macOS)
        Settings {
            NativeSettingsView(appSettings: appSettings)
        }
#endif
    }
}

#if DEBUG && os(iOS)
private extension View {
    @ViewBuilder
    func morseReduceMotionControlForUITestsIfNeeded() -> some View {
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseReduceMotionControl") {
            modifier(MorseReduceMotionUITestModifier())
        } else {
            self
        }
    }

    @ViewBuilder
    func forceRegularHorizontalSizeClassForUITestsIfNeeded() -> some View {
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamForceRegularHorizontalSizeClass") {
            self.environment(\.horizontalSizeClass, .regular)
        } else {
            self
        }
    }
}

private struct MorseReduceMotionUITestModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var reduceMotion = false

    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityReduceMotion, systemReduceMotion || reduceMotion)
            .safeAreaInset(edge: .bottom) {
                Button { reduceMotion = true } label: {
                    Text(verbatim: "Enable Reduce Motion for Morse test") // l10n: verbatim DEBUG-only UI test hook
                }
                .accessibilityIdentifier("morse-enable-reduce-motion-test-button")
                .padding()
            }
    }
}
#endif
