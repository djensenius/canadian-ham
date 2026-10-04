import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct CanadianHamApp: App {
    @StateObject private var appSettings = AppSettingsModel()

    init() {
#if os(iOS)
        let segmentedControl = UISegmentedControl.appearance()
        segmentedControl.selectedSegmentTintColor = .label
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.systemBackground], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
#endif
    }

    var body: some Scene {
        WindowGroup {
#if DEBUG && os(iOS)
            RootView(appSettings: appSettings)
                .forceRegularHorizontalSizeClassForUITestsIfNeeded()
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
    func forceRegularHorizontalSizeClassForUITestsIfNeeded() -> some View {
        if ProcessInfo.processInfo.arguments.contains("-CanadianHamForceRegularHorizontalSizeClass") {
            self.environment(\.horizontalSizeClass, .regular)
        } else {
            self
        }
    }
}
#endif
