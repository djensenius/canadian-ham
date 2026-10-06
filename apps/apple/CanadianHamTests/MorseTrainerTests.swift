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

    func testMorseAudioSessionStaysActiveUntilLastPlayerReleases() {
        var usage = MorseAudioSessionUsage()
        usage.acquire() // course starts
        usage.acquire() // Quick listen starts before the course's delayed cleanup runs
        XCTAssertFalse(usage.release(), "The outgoing player must not deactivate the session while another plays")
        XCTAssertTrue(usage.release(), "The last player releases the session")
        XCTAssertTrue(usage.release(), "An extra release stays at zero users")
        XCTAssertEqual(usage.activeUsers, 0)
    }

    func testMorseStopDelayDrainsFadeBeforeStoppingEngine() throws {
        XCTAssertEqual(MorseAudioStopTiming.stopDelay(rampDuration: 0.005), 0.1, accuracy: 0.000_001)
        XCTAssertEqual(MorseAudioStopTiming.stopDelay(rampDuration: 0.12), 0.12, accuracy: 0.000_001)
    }

    @MainActor
    func testMorsePlaybackCoordinatorStopsCourseAndOtherOwnersOneAtATime() throws {
        let coordinator = MorsePlaybackCoordinator()
        var courseStops = 0
        var quickListenStops = 0

        coordinator.register("course") {
            courseStops += 1
        }
        coordinator.register("quick-listen") {
            quickListenStops += 1
        }

        coordinator.claim("course")
        XCTAssertEqual(courseStops, 0)
        XCTAssertEqual(quickListenStops, 1, "Course audio should stop other Morse playback owners before it starts")

        coordinator.claim("quick-listen")
        XCTAssertEqual(courseStops, 1, "Other Morse playback owners should stop course audio before they start")
        XCTAssertEqual(quickListenStops, 1)
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

    func testMorseExamGeneratorMeetsReceivingExamConstraints() throws {
        for profileName in [MorseProfileName.isedParis, .ric1Literal] {
            let profile = profileForName(profileName)
            let exam = try generateMorseExamText(seed: "apple-unit-\(profileName.rawValue)", profile: profile)
            let weight = try weightedCharacterCount(exam.text)
            let sequence = try textToTimedMorse(exam.text, profile: profile)

            XCTAssertGreaterThanOrEqual(weight.weightedCharacters, 75, profileName.rawValue)
            XCTAssertGreaterThanOrEqual(sequence.totalDurationSeconds, 180, profileName.rawValue)
            XCTAssertEqual(exam.weightedCharacters, weight.weightedCharacters, profileName.rawValue)
            XCTAssertEqual(exam.durationSeconds, sequence.totalDurationSeconds, accuracy: 0.000_001, profileName.rawValue)
            XCTAssertTrue(validateMorseText(exam.text).valid, profileName.rawValue)
        }
    }

    func testMorseCopyDiffClassifiesWrongMissingAndInsertedCharacters() throws {
        let diff = try diffMorseCopy(expected: "ABC", received: "AXCD")

        XCTAssertEqual(diff.score.errors, 2)
        XCTAssertEqual(diff.score.wrong, 1)
        XCTAssertEqual(diff.score.missing, 0)
        XCTAssertEqual(diff.score.inserted, 1)
        XCTAssertEqual(diff.operations.map(\.kind), [.match, .wrong, .match, .inserted])
    }

    func testMorseSendingClassifiesTimingAndErrorSignal() throws {
        let profile = profileForName(.isedParis)
        let dot = try classifyMorseKeyDown(durationSeconds: 0.1, profile: profile)
        let dash = try classifyMorseKeyDown(durationSeconds: 0.31, profile: profile)
        let feedback = morseCharacterTimingFeedback(samples: [dot, dash])
        let errorSignal = decodeMorseElements(String(repeating: ".", count: morseErrorSignalDots))

        XCTAssertEqual(dot.element, .dot)
        XCTAssertEqual(dash.element, .dash)
        XCTAssertEqual(feedback.decoded.character, "A")
        XCTAssertEqual(feedback.dotDashRatio ?? 0, 3.1, accuracy: 0.000_001)
        XCTAssertEqual(errorSignal.kind, .errorSignal)
        XCTAssertEqual(applyMorseDecodedCharacter(text: "AB", decoded: errorSignal), "A")
    }

    func testMorseSendingScoreCountsTimeoutOnlyThroughMissingCharacters() throws {
        let pass = try scoreMorseSending(expected: "ABCDEF", sent: "ABCDE", completedWithinTime: false)
        let fail = try scoreMorseSending(expected: "ABCDEFGHIJK", sent: "ABCDE", completedWithinTime: false)

        XCTAssertTrue(pass.passed)
        XCTAssertEqual(pass.diff.score.missing, 1)
        XCTAssertEqual(pass.markPercent, 100)
        XCTAssertFalse(fail.passed)
        XCTAssertEqual(fail.diff.score.missing, 6)
        XCTAssertEqual(fail.markPercent, 99)
    }

    func testCompletedMorseCourseSessionIgnoresResubmittedAnswer() throws {
        var session = MorseCourseSession(mode: .review, exercises: [.typeCharacter("K")], index: 0, correct: 1, total: 1, characterResults: [(character: "K", correct: true)], done: true)

        XCTAssertFalse(session.applyAnswer(correct: false, results: [("K", false)]))
        XCTAssertEqual(session.index, 0)
        XCTAssertEqual(session.correct, 1)
        XCTAssertEqual(session.total, 1)
        XCTAssertEqual(session.characterResults.count, 1)
        XCTAssertTrue(session.done)
    }

    func testMorseCourseSummaryCopyDependsOnSessionModeAndLessonPosition() throws {
        let course = try minimalMorseCourse()
        let finalLesson = try XCTUnwrap(course.lessons.first)

        XCTAssertEqual(
            morseCourseSummaryMessage(for: MorseCourseSession(mode: .review, exercises: [.typeCharacter("K")], done: true), percent: 100, course: course),
            String(localized: "Review complete. Practice progress was saved.")
        )
        XCTAssertEqual(
            morseCourseSummaryMessage(for: MorseCourseSession(mode: .lesson(finalLesson), exercises: [.typeCharacter("K")], done: true), percent: 100, course: course),
            String(localized: "Great work. All Morse lessons are complete.")
        )
        XCTAssertEqual(
            morseCourseSummaryMessage(for: MorseCourseSession(mode: .lesson(finalLesson), exercises: [.typeCharacter("K")], done: true), percent: 80, course: course),
            String(localized: "Reach 90% accuracy to complete this lesson.")
        )
        for session in [
            MorseCourseSession(mode: .review, exercises: [.typeCharacter("K")], done: true),
            MorseCourseSession(mode: .lesson(course.lessons[0]), exercises: [.typeCharacter("K")], done: true),
        ] {
            XCTAssertEqual(
                morseCourseSummaryMessage(for: session, percent: 100, course: course, progressSaved: false),
                String(localized: "Progress was not saved. Try again before relying on this result."),
                "A failed save must never claim progress was saved or a lesson unlocked"
            )
        }
    }

    func testMorseCourseLocalDateStringUsesGregorianCalendarInCurrentTimeZone() throws {
        let formatter = ISO8601DateFormatter()
        let date = try XCTUnwrap(formatter.date(from: "2026-10-04T12:00:00Z"))
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        var buddhistCalendar = Calendar(identifier: .buddhist)
        buddhistCalendar.timeZone = timeZone

        XCTAssertEqual(buddhistCalendar.component(.year, from: date), 2569)
        XCTAssertEqual(morseCourseLocalDateString(date, timeZone: timeZone), "2026-10-04")
    }

    func testMorseCourseProgressIgnoresStoredProgressForAnotherCourse() throws {
        let storedProgress = MorseCourseProgressExport(
            courseId: "other-course",
            lessonProgress: [MorseLessonProgressRecord(
                lessonId: "koch-001",
                attempts: 1,
                bestAccuracy: 1,
                lastAccuracy: 1,
                lastAttemptedAt: "2026-01-02T04:30:00.000Z",
                completedAt: "2026-01-02T04:30:00.000Z"
            )],
            characterStats: [],
            dailyActivity: []
        )

        let selectedProgress = morseCourseProgressForBundledCourse(storedProgress, courseId: "ised-koch-g4fon-v1")

        XCTAssertEqual(selectedProgress.courseId, "ised-koch-g4fon-v1")
        XCTAssertTrue(selectedProgress.lessonProgress.isEmpty)
    }

    private func minimalMorseCourse() throws -> MorseCourse {
        let json = #"""
        {
          "schemaVersion": 1,
          "kind": "morse-course",
          "courseId": "test-course",
          "unlockAccuracy": 0.9,
          "unitSize": 5,
          "characterOrder": ["K"],
          "units": [
            { "id": "unit-01", "unitNumber": 1, "title": "Unit 1", "lessonIds": ["koch-001"] }
          ],
          "lessons": [
            { "id": "koch-001", "unitId": "unit-01", "lessonNumber": 1, "title": "Lesson 1", "newCharacters": ["K"], "learnedCharacters": ["K"] }
          ]
        }
        """#
        return try JSONDecoder().decode(MorseCourse.self, from: Data(json.utf8))
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
