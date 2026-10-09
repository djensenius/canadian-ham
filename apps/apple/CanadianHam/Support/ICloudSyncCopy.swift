import Foundation

enum ICloudSyncCopy {
    static var title: String {
        String(localized: "iCloud Sync")
    }

    static var toggleLabel: String {
        String(localized: "Sync learning progress with iCloud")
    }

    static var deviceExplanation: String {
        String(localized: "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay local on this device.")
    }

    static var macExplanation: String {
        String(localized: "Off by default. When enabled, learning progress can sync through your private iCloud database after restart; preferences stay local on this Mac.")
    }

    static var enabledAfterRestart: String {
        String(localized: "iCloud Sync will turn on after you restart the app.")
    }

    static var disabledAfterRestart: String {
        String(localized: "iCloud Sync will turn off after you restart the app.")
    }

    static var gatedPrivacySummary: String {
        String(localized: "No accounts, analytics, telemetry, third-party SDKs, or developer-operated servers. iCloud Sync is optional and off until you turn it on; import and export use local files you choose.")
    }
}
