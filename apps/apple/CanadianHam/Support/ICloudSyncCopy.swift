import Foundation

enum ICloudSyncCopy {
    static let title = String(localized: "iCloud Sync")
    static let toggleLabel = String(localized: "Sync learning progress with iCloud")
    static let deviceExplanation = String(localized: "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay on this device.")
    static let macExplanation = String(localized: "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay on this Mac.")
    static let enabledAfterRestart = String(localized: "iCloud Sync will turn on after you restart the app.")
    static let disabledAfterRestart = String(localized: "iCloud Sync will turn off after you restart the app.")
    static let deleteProgressButton = String(localized: "Delete iCloud Progress")
    static let deleteProgressTitle = String(localized: "Delete iCloud Progress?")
    static let deleteProgressMessage = String(localized: "This stops iCloud Sync, deletes the app's private iCloud progress, and lets you choose whether to keep progress on this device. Other devices with iCloud Sync still on can upload their progress again.")
    static let deleteProgressKeepLocal = String(localized: "Delete from iCloud, keep on device")
    static let deleteProgressDeleteLocal = String(localized: "Delete from iCloud and this device")
    static let deleteProgressSuccess = String(localized: "iCloud progress was deleted.")
    static let settingsPrivacySummary = String(localized: "No accounts, analytics, telemetry, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.")
    static let aboutPrivacySummary = String(localized: "This development build bundles all study content locally. It has no accounts, analytics, telemetry, ads, remote config, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.")
}
