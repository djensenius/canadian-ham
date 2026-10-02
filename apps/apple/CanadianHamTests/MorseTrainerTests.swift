@testable import CanadianHam
import CanadianHamMorseEngine
import XCTest

final class MorseTrainerTests: XCTestCase {
    func testMorseSettingsClampAndPreset() throws {
        let settings = MorseTrainerSettings(
            isEnabled: true,
            toneHz: 1_200,
            characterWpm: 30,
            effectiveWpm: 28,
            timingProfile: .general,
            volume: 2
        ).normalized()

        XCTAssertTrue(settings.isEnabled)
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
        XCTAssertEqual(schedule.segments, [MorseAudioSegment(startFrame: 0, endFrame: 80)])
        XCTAssertEqual(schedule.amplitude(at: 0), 0, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 3), 0.36, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 40), 0.6, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 79), 0.12, accuracy: 0.000_001)
        XCTAssertEqual(schedule.amplitude(at: 80), 0, accuracy: 0.000_001)
    }

    func testRIC1LiteralTimingScalesFromCharacterSpeed() throws {
        let settings = MorseTrainerSettings.default.applyingISEDExamPreset().normalized()
        let profile = try MorseTrainerSettings(
            isEnabled: true,
            toneHz: 650,
            characterWpm: settings.characterWpm,
            effectiveWpm: settings.effectiveWpm,
            timingProfile: .ric1Literal,
            volume: 0.5
        ).timingProfileValue()

        XCTAssertEqual(profile.dotSeconds, 0.1, accuracy: 0.000_001)
        XCTAssertEqual(profile.interCharacterGapSeconds, 0.7, accuracy: 0.000_001)
        XCTAssertEqual(profile.wordGapSeconds, 1.7, accuracy: 0.000_001)
    }
}
