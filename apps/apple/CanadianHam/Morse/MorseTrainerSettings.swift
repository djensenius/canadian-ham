import Foundation
import CanadianHamMorseEngine

struct MorseTrainerSettings: Codable, Equatable, Sendable {
    enum TimingProfile: String, Codable, CaseIterable, Identifiable, Sendable {
        case isedParis
        case ric1Literal
        case general

        var id: String { rawValue }

        var localizedLabel: String {
            switch self {
            case .isedParis: String(localized: "ISED 5 wpm (PARIS-calibrated)")
            case .ric1Literal: String(localized: "RIC-1 literal spacing")
            case .general: String(localized: "General Farnsworth")
            }
        }
    }

    var toneHz: Int
    var characterWpm: Int
    var effectiveWpm: Int
    var timingProfile: TimingProfile
    var volume: Double

    static let `default` = MorseTrainerSettings(
        toneHz: 650,
        characterWpm: 15,
        effectiveWpm: 5,
        timingProfile: .isedParis,
        volume: 0.6
    )

    static let storageKey = "canadian-ham.morse-trainer-settings.v1"

    func normalized() -> MorseTrainerSettings {
        let normalizedCharacterWpm = Self.clamp(characterWpm, min: 12, max: 25)
        return MorseTrainerSettings(
            toneHz: Self.clamp(toneHz, min: 400, max: 900),
            characterWpm: normalizedCharacterWpm,
            effectiveWpm: Self.clamp(effectiveWpm, min: 5, max: normalizedCharacterWpm),
            timingProfile: timingProfile,
            volume: min(1, max(0, volume))
        )
    }

    func applyingISEDExamPreset() -> MorseTrainerSettings {
        var next = self
        next.characterWpm = 12
        next.effectiveWpm = 5
        next.timingProfile = .isedParis
        return next.normalized()
    }

    func timingProfileValue() throws -> MorseTimingProfile {
        let settings = normalized()
        switch settings.timingProfile {
        case .isedParis:
            return profileForName(.isedParis)
        case .general:
            return try farnsworthTiming(characterWpm: Double(settings.characterWpm), effectiveWpm: Double(settings.effectiveWpm))
        case .ric1Literal:
            return profileForName(.ric1Literal)
        }
    }

    static func load(defaults: UserDefaults = .standard) -> MorseTrainerSettings {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(MorseTrainerSettings.self, from: data) else {
            return .default
        }
        return decoded.normalized()
    }

    func save(defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(normalized()) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: storageKey)
    }

    private static func clamp(_ value: Int, min lowerBound: Int, max upperBound: Int) -> Int {
        Swift.min(upperBound, Swift.max(lowerBound, value))
    }
}
