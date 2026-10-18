import Foundation

struct ApplePreferences {
    enum PracticeMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case immediate
        case reviewLater = "review-later"

        var id: String { rawValue }
    }
}
