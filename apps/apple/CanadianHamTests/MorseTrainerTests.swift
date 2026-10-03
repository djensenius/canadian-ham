@testable import CanadianHam
import CanadianHamMorseEngine
import XCTest

final class MorseTrainerTests: XCTestCase {
    func testMorseSettingsClampAndPreset() throws {
        let settings = MorseTrainerSettings(
            toneHz: 1_200,
            characterWpm: 30,
            effectiveWpm: 28,
            timingProfile: .general,
            volume: 2
        ).normalized()

        XCTAssertEqual(settings.toneHz, 900)
        XCTAssertEqual(settings.characterWpm, 25)
        XCTAssertEqual(settings.effectiveWpm, 25)
        XCTAssertEqual(settings.volume, 1)

        let preset = settings.applyingISEDExamPreset()
        XCTAssertEqual(preset.characterWpm, 12)
        XCTAssertEqual(preset.effectiveWpm, 5)
        XCTAssertEqual(preset.timingProfile, .isedParis)
    }

    func testMorseAudioScheduleUsesEngineTimingsAndFiveMillisecondRamp() throws {
        let settings = MorseTrainerSettings.default
        let sequence = try textToTimedMorse("E", profile: settings.timingProfileValue())
        let schedule = MorseAudioSchedule(sequence: sequence, settings: settings, sampleRate: 1_000, rampSeconds: 0.005)

        XCTAssertEqual(schedule.frequency, 650)
        XCTAssertEqual(schedule.rampFrames, 5)
        XCTAssertEqual(schedule.segments, [MorseAudioSegment(startFrame: 0, endFrame: 100)])
        XCTAssertEqual(schedule.amplitude(at: 0), 0, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 3), 0.36, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 50), 0.6, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 99), 0.12, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 100), 0, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 52, stopRampStartFrame: 50), 0.36, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 55, stopRampStartFrame: 50), 0, accuracy: 0.000_001)
    }

    func testMorseStopDelayDrainsFadeBeforeStoppingEngine() throws {
        XCTAssertEqual(MorseAudioStopTiming.stopDelay(rampDuration: 0.005), 0.1, accuracy: 0.000_001)
        XCTAssertEqual(MorseAudioStopTiming.stopDelay(rampDuration: 0.12), 0.12, accuracy: 0.000_001)
    }

    func testFixedTimingProfilesUseEngineValues() throws {
        let ised = try MorseTrainerSettings(
            toneHz: 650,
            characterWpm: 25,
            effectiveWpm: 25,
            timingProfile: .isedParis,
            volume: 0.5
        ).timingProfileValue()
        let ric1 = try MorseTrainerSettings(
            toneHz: 650,
            characterWpm: 25,
            effectiveWpm: 25,
            timingProfile: .ric1Literal,
            volume: 0.5
        ).timingProfileValue()
        let general = try MorseTrainerSettings(
            toneHz: 650,
            characterWpm: 20,
            effectiveWpm: 10,
            timingProfile: .general,
            volume: 0.5
        ).timingProfileValue()

        XCTAssertEqual(ised.characterWpm, 12, accuracy: 0.000_001)
        XCTAssertEqual(ised.effectiveWpm, 5, accuracy: 0.000_001)
        XCTAssertEqual(ric1.characterWpm, 12, accuracy: 0.000_001)
        XCTAssertEqual(ric1.effectiveWpm, 60 / 7.6, accuracy: 0.000_001)
        XCTAssertEqual(ric1.dotSeconds, 0.1, accuracy: 0.000_001)
        XCTAssertEqual(ric1.interCharacterGapSeconds, 0.7, accuracy: 0.000_001)
        XCTAssertEqual(ric1.wordGapSeconds, 1.7, accuracy: 0.000_001)
        XCTAssertNil(general.name)
        XCTAssertEqual(general.characterWpm, 20, accuracy: 0.000_001)
        XCTAssertEqual(general.effectiveWpm, 10, accuracy: 0.000_001)
    }

    func testMorseSettingsDecodesLegacyPayloadWithIsEnabled() throws {
        let json = #"""
        {
          "isEnabled": false,
          "toneHz": 720,
          "characterWpm": 16,
          "effectiveWpm": 7,
          "timingProfile": "general",
          "volume": 0.45
        }
        """#

        let decoded = try JSONDecoder().decode(MorseTrainerSettings.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.toneHz, 720)
        XCTAssertEqual(decoded.characterWpm, 16)
        XCTAssertEqual(decoded.effectiveWpm, 7)
        XCTAssertEqual(decoded.timingProfile, .general)
        XCTAssertEqual(decoded.volume, 0.45)
    }

    func testMorseSettingsRoundTripThroughUserDefaults() throws {
        let suiteName = "MorseTrainerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let settings = MorseTrainerSettings(
            toneHz: 700,
            characterWpm: 18,
            effectiveWpm: 9,
            timingProfile: .general,
            volume: 0.35
        )

        settings.save(defaults: defaults)
        XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), settings.normalized())

        MorseTrainerSettings.reset(defaults: defaults)
        XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), .default)
    }
}
