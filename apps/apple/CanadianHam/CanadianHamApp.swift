import SwiftUI

@main
struct CanadianHamApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .defaultSize(width: 1_080, height: 760)
        #endif
    }
}
