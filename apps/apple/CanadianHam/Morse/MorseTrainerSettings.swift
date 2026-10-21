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

    enum OutputMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case audio
        case visualBeacon
        case visualTape
        case haptics

        var id: String { rawValue }

        var localizedLabel: String {
            switch self {
            case .audio: String(localized: "Audio tone")
            case .visualBeacon: String(localized: "Visual beacon")
            case .visualTape: String(localized: "Non-flashing tape")
            case .haptics: String(localized: "Haptics")
            }
        }

        static var availableCases: [OutputMode] {
#if os(iOS)
            MorseHapticDriver.supportsHaptics ? allCases : allCases.filter { $0 != .haptics }
#else
            allCases.filter { $0 != .haptics }
#endif
        }
    }

    var toneHz: Int
    var characterWpm: Int
    var effectiveWpm: Int
    var timingProfile: TimingProfile
    var volume: Double
    var outputMode: OutputMode

    static let `default` = MorseTrainerSettings(
        toneHz: 650,
        characterWpm: 15,
        effectiveWpm: 5,
        timingProfile: .isedParis,
        volume: 0.6,
        outputMode: .audio
    )

    static let storageKey = "canadian-ham.morse-trainer-settings.v1"

    init(toneHz: Int, characterWpm: Int, effectiveWpm: Int, timingProfile: TimingProfile, volume: Double, outputMode: OutputMode = .audio) {
        self.toneHz = toneHz
        self.characterWpm = characterWpm
        self.effectiveWpm = effectiveWpm
        self.timingProfile = timingProfile
        self.volume = volume
        self.outputMode = outputMode
    }

    enum CodingKeys: String, CodingKey {
        case toneHz
        case characterWpm
        case effectiveWpm
        case timingProfile
        case volume
        case outputMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        toneHz = try container.decode(Int.self, forKey: .toneHz)
        characterWpm = try container.decode(Int.self, forKey: .characterWpm)
        effectiveWpm = try container.decode(Int.self, forKey: .effectiveWpm)
        timingProfile = try container.decode(TimingProfile.self, forKey: .timingProfile)
        volume = try container.decode(Double.self, forKey: .volume)
        outputMode = try container.decodeIfPresent(OutputMode.self, forKey: .outputMode) ?? .audio
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(toneHz, forKey: .toneHz)
        try container.encode(characterWpm, forKey: .characterWpm)
        try container.encode(effectiveWpm, forKey: .effectiveWpm)
        try container.encode(timingProfile, forKey: .timingProfile)
        try container.encode(volume, forKey: .volume)
        try container.encode(outputMode, forKey: .outputMode)
    }

    // Conversion has defensive enum defaults; progress-file validation rejects unknown
    // strings before reaching this initializer, matching web import validation.
    init(exported: ExportedMorseSettings) {
        self.init(
            toneHz: exported.toneHz,
            characterWpm: exported.characterWpm,
            effectiveWpm: exported.effectiveWpm,
            timingProfile: TimingProfile(rawValue: exported.timingProfile) ?? .isedParis,
            volume: exported.volume,
            outputMode: OutputMode(rawValue: exported.outputMode) ?? .audio
        )
    }

    var exportedPreferences: ExportedMorseSettings {
        let settings = normalized()
        let webCompatibleOutputMode: OutputMode = settings.outputMode == .haptics ? .audio : settings.outputMode
        return ExportedMorseSettings(
            toneHz: settings.toneHz,
            characterWpm: settings.characterWpm,
            effectiveWpm: settings.effectiveWpm,
            timingProfile: settings.timingProfile.rawValue,
            volume: settings.volume,
            outputMode: webCompatibleOutputMode.rawValue
        )
    }

    func normalized() -> MorseTrainerSettings {
        let normalizedCharacterWpm = Self.clamp(characterWpm, min: 12, max: 25)
        return MorseTrainerSettings(
            toneHz: Self.clamp(toneHz, min: 400, max: 900),
            characterWpm: normalizedCharacterWpm,
            effectiveWpm: Self.clamp(effectiveWpm, min: 5, max: normalizedCharacterWpm),
            timingProfile: timingProfile,
            volume: min(1, max(0, volume)),
            outputMode: Self.normalizedOutputMode(outputMode)
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

    private static func normalizedOutputMode(_ mode: OutputMode) -> OutputMode {
        OutputMode.availableCases.contains(mode) ? mode : .audio
    }
}
