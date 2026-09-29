import SwiftUI

@main
struct CanadianHamApp: App {
    var body: some Scene {
        WindowGroup {
#if DEBUG && os(iOS)
            RootView()
                .forceRegularHorizontalSizeClassForUITestsIfNeeded()
#else
            RootView()
#endif
        }
        #if os(macOS)
        .defaultSize(width: 1_080, height: 760)
        #endif
    }
}

#if DEBUG && os(iOS)
private extension View {
    @ViewBuilder
    func forceRegularHorizontalSizeClassForUITestsIfNeeded() -> some View {
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamForceRegularHorizontalSizeClass") {
            self.environment(\.horizontalSizeClass, .regular)
        } else {
            self
        }
    }
}
#endif
