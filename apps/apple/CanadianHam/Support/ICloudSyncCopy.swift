import Foundation

enum ICloudSyncCopy {
    static let title = String(localized: "iCloud Sync")
    static let toggleLabel = String(localized: "Sync practice and exam progress with iCloud")
    static let deviceExplanation = String(localized: "Off by default. When enabled, question practice and mock exam progress can sync through your private iCloud database after restart; lesson progress and preferences stay on this device.")
    static let macExplanation = String(localized: "Off by default. When enabled, question practice and mock exam progress can sync through your private iCloud database after restart; lesson progress and preferences stay on this Mac.")
    static let enabledAfterRestart = String(localized: "iCloud Sync will turn on after you restart the app.")
    static let disabledAfterRestart = String(localized: "iCloud Sync will turn off after you restart the app.")
    static let settingsPrivacySummary = String(localized: "No accounts, analytics, telemetry, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.")
    static let aboutPrivacySummary = String(localized: "This development build includes bundled content and has no accounts, analytics, telemetry, ads, remote config, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.")
}
