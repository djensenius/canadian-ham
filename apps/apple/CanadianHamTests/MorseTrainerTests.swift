@testable import CanadianHam
import CanadianHamMorseEngine
import SwiftUI
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
        XCTAssertEqual(settings.outputMode, .audio)

        let visualSettings = MorseTrainerSettings(toneHz: 650, characterWpm: 15, effectiveWpm: 5, timingProfile: .general, volume: 0.6, outputMode: .visualBeacon).normalized()
        XCTAssertEqual(visualSettings.outputMode, .visualBeacon)

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

    func testMorseSettingsCodableRoundTripPreservesOutputMode() throws {
        let settings = MorseTrainerSettings(toneHz: 700, characterWpm: 18, effectiveWpm: 6, timingProfile: .general, volume: 0.4, outputMode: .visualTape)

        let decoded = try JSONDecoder().decode(MorseTrainerSettings.self, from: JSONEncoder().encode(settings))

        XCTAssertEqual(decoded, settings)
    }

    func testMorseBeaconPaletteMatchesDesignTokensAndKeepsAreaAndContrastMargins() throws {
        let tokensURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "CanadianHam/Design/Tokens.swift")
        let tokens = try String(contentsOf: tokensURL, encoding: .utf8)
        XCTAssertTrue(tokens.contains("paperInset = Color.dynamicToken(light: DesignTokens.RGB(red: 0.937255, green: 0.890196, blue: 0.796078), dark: DesignTokens.RGB(red: 0.094118, green: 0.078431, blue: 0.062745))"))
        XCTAssertTrue(tokens.contains("accent = Color.dynamicToken(light: DesignTokens.RGB(red: 0.647059, green: 0.227451, blue: 0.164706), dark: DesignTokens.RGB(red: 1.000000, green: 0.541176, blue: 0.439216))"))
        XCTAssertLessThanOrEqual(morseBeaconAreaCssPixels, morseFlashMaxAreaCssPixels)
        for scheme in [ColorScheme.light, .dark] {
            let palette = morseBeaconPalette(for: scheme)
            let safety = evaluateMorseBeaconFlashSafety(palette: palette, flashesPerSecond: 5)
            XCTAssertTrue(safety.safe)
            XCTAssertEqual(safety.reason, .belowAreaThreshold)
            XCTAssertGreaterThanOrEqual(morseContrastRatio(palette.resting, palette.active), 3)
        }
    }

    func testLessonBodyAndBulletContrastTokensMeetMinimumRatio() throws {
        let tokensURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "CanadianHam/Design/Tokens.swift")
        let tokens = try String(contentsOf: tokensURL, encoding: .utf8)
        let ink = try designTokenRGB(named: "ink", in: tokens)
        let paper = try designTokenRGB(named: "paper", in: tokens)
        let paperElevated = try designTokenRGB(named: "paperElevated", in: tokens)

        let cases: [(String, MorseRGB, MorseRGB)] = [
            ("light lesson body ink on paper", ink.light, paper.light),
            ("dark lesson body ink on paper", ink.dark, paper.dark),
            ("light lesson body ink on paperElevated card", ink.light, paperElevated.light),
            ("dark lesson body ink on paperElevated card", ink.dark, paperElevated.dark),
            ("light lesson bullet ink on paper", ink.light, paper.light),
            ("dark lesson bullet ink on paper", ink.dark, paper.dark),
            ("light lesson bullet ink on paperElevated card", ink.light, paperElevated.light),
            ("dark lesson bullet ink on paperElevated card", ink.dark, paperElevated.dark)
        ]

        for (name, foreground, background) in cases {
            XCTAssertGreaterThanOrEqual(morseContrastRatio(foreground, background), 4.5, name)
        }
    }

    func testMorseSettingsNotesInkOnBackgroundsMeetWCAGContrast() throws {
        let tokensURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "CanadianHam/Design/Tokens.swift")
        let tokens = try String(contentsOf: tokensURL, encoding: .utf8)
        let ink = try designTokenRGB(named: "ink", in: tokens)
        let paper = try designTokenRGB(named: "paper", in: tokens)
        let cardBackground = try designTokenRGB(named: "paperElevated", in: tokens)

        let cases: [(name: String, foreground: MorseRGB, background: MorseRGB)] = [
            ("Morse settings description ink on light card background", ink.light, cardBackground.light),
            ("Morse settings description ink on dark card background", ink.dark, cardBackground.dark),
            ("Morse fixed-timing note ink on light note background", ink.light, paper.light),
            ("Morse fixed-timing note ink on dark note background", ink.dark, paper.dark)
        ]

        for contrastCase in cases {
            XCTAssertGreaterThanOrEqual(
                morseContrastRatio(contrastCase.foreground, contrastCase.background),
                4.5,
                "\(contrastCase.name) regressed below WCAG AA contrast"
            )
        }

        let trainerSourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "CanadianHam/Morse/MorseTrainerView.swift")
        let trainerSource = try String(contentsOf: trainerSourceURL, encoding: .utf8)
        let descriptionRange = try XCTUnwrap(trainerSource.range(of: "Text(\"These local settings control Morse tone, timing, and playback volume without network access.\")"))
        let descriptionBlock = trainerSource[descriptionRange.lowerBound...].prefix(360)
        XCTAssertTrue(descriptionBlock.contains(".foregroundStyle(DesignTokens.Colors.ink)"), "The contrast guard must track the settings description text token")
        XCTAssertTrue(descriptionBlock.contains(".accessibilityIdentifier(\"morse-settings-description\")"), "The settings description audit exception must stay tied to the stable identifier")

        let fixedTimingRange = try XCTUnwrap(trainerSource.range(of: "Text(fixedTimingDescription)"))
        let fixedTimingBlock = trainerSource[fixedTimingRange.lowerBound...].prefix(520)
        XCTAssertTrue(fixedTimingBlock.contains(".foregroundStyle(DesignTokens.Colors.ink)"), "The contrast guard must track the fixed-timing note text token")
        XCTAssertTrue(fixedTimingBlock.contains(".accessibilityIdentifier(\"morse-settings-fixed-timing-description\")"), "The fixed-timing audit exception must stay tied to the stable identifier")
        XCTAssertTrue(fixedTimingBlock.contains(".background(DesignTokens.Colors.paper, in: RoundedRectangle"), "The contrast guard must track the fixed-timing note background token")

        let settingsSectionRange = try XCTUnwrap(trainerSource.range(of: "MorseSettingsSection(settings: $settings, openMorse: {})"))
        let settingsSectionBlock = trainerSource[settingsSectionRange.lowerBound...].prefix(180)
        XCTAssertTrue(settingsSectionBlock.contains(".paperCard()"), "MorseSettingsSection must stay wrapped in paperCard() so the description uses the guarded card background token")

        let viewsSourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "CanadianHam/Views/StudyViews.swift")
        let viewsSource = try String(contentsOf: viewsSourceURL, encoding: .utf8)
        let paperCardRange = try XCTUnwrap(viewsSource.range(of: "func paperCard()"))
        let paperCardBlock = viewsSource[paperCardRange.lowerBound...].prefix(420)
        XCTAssertTrue(paperCardBlock.contains(".background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))"), "paperCard() must continue to use the guarded settings-description card background token")
    }

    func testMorseVisualPlaybackPlanUsesBeaconWhenSafeAndTapeWhenRequestedOrReduced() throws {
        let sequence = try textToTimedMorse("5", profile: profileForName(.isedParis))

        let beacon = morseVisualPlaybackPlan(sequence: sequence, requestedMode: .visualBeacon, reduceFlashing: false, colorScheme: .light)
        let reduced = morseVisualPlaybackPlan(sequence: sequence, requestedMode: .visualBeacon, reduceFlashing: true, colorScheme: .light)
        let requestedTape = morseVisualPlaybackPlan(sequence: sequence, requestedMode: .visualTape, reduceFlashing: false, colorScheme: .light)

        XCTAssertFalse(beacon.useTape)
        XCTAssertTrue(beacon.safety.safe)
        XCTAssertEqual(beacon.safety.reason, .belowAreaThreshold)
        XCTAssertTrue(reduced.useTape)
        XCTAssertTrue(requestedTape.useTape)
    }

    func testMorseBeaconSafetyNoteUsesSquarePointsAndGroupedAreas() throws {
        let sequence = try textToTimedMorse("5", profile: profileForName(.isedParis))
        let plan = morseVisualPlaybackPlan(sequence: sequence, requestedMode: .visualBeacon, reduceFlashing: false, colorScheme: .light)

        XCTAssertEqual(formattedMorseArea(12_544, locale: Locale(identifier: "en_CA")), "12,544")
        XCTAssertEqual(formattedMorseArea(21_824, locale: Locale(identifier: "en_CA")), "21,824")
        XCTAssertEqual(formattedMorseArea(12_544, locale: Locale(identifier: "fr_CA")), "12\u{00A0}544")
        XCTAssertTrue(plan.safetyNote.contains("\(formattedMorseArea(morseBeaconAreaCssPixels)) square points"), plan.safetyNote)
        XCTAssertTrue(plan.safetyNote.contains("\(formattedMorseArea(plan.safety.maxAreaCssPixels)) square-point WCAG flash cap"), plan.safetyNote)
        XCTAssertFalse(plan.safetyNote.contains("px"), "Apple's measured area is in square points, not CSS pixels")
    }

    func testReduceFlashingDecisionUsesInjectedFlags() {
        XCTAssertFalse(shouldReduceMorseFlashing(flags: MorseReduceFlashingFlags(environmentReduceMotion: false, systemReduceMotion: false, dimFlashingLights: false)))
        XCTAssertTrue(shouldReduceMorseFlashing(flags: MorseReduceFlashingFlags(environmentReduceMotion: true, systemReduceMotion: false, dimFlashingLights: false)))
        XCTAssertTrue(shouldReduceMorseFlashing(flags: MorseReduceFlashingFlags(environmentReduceMotion: false, systemReduceMotion: true, dimFlashingLights: false)))
        XCTAssertTrue(shouldReduceMorseFlashing(flags: MorseReduceFlashingFlags(environmentReduceMotion: false, systemReduceMotion: false, dimFlashingLights: true)))
    }

    func testReduceFlashingStopsOnlyRunningVisualBeacon() {
        let enabledFlags = MorseReduceFlashingFlags(environmentReduceMotion: true, systemReduceMotion: false, dimFlashingLights: false)
        let disabledFlags = MorseReduceFlashingFlags(environmentReduceMotion: false, systemReduceMotion: false, dimFlashingLights: false)
        let completedBeaconState = MorseVisualPlaybackState(mode: .visualBeacon, beaconActive: false, tape: "", safetyNote: "finished")
        var ownerState = completedBeaconState

        XCTAssertTrue(shouldStopMorseVisualBeaconForReducedFlashing(state: MorseVisualPlaybackState(mode: .visualBeacon), isPlaybackRunning: true, flags: enabledFlags))
        XCTAssertFalse(shouldStopMorseVisualBeaconForReducedFlashing(state: MorseVisualPlaybackState(mode: .visualTape), isPlaybackRunning: true, flags: enabledFlags))
        XCTAssertFalse(shouldStopMorseVisualBeaconForReducedFlashing(state: MorseVisualPlaybackState(mode: .idle), isPlaybackRunning: true, flags: enabledFlags))
        XCTAssertFalse(shouldStopMorseVisualBeaconForReducedFlashing(state: MorseVisualPlaybackState(mode: .visualBeacon), isPlaybackRunning: true, flags: disabledFlags))
        XCTAssertFalse(shouldStopMorseVisualBeaconForReducedFlashing(state: completedBeaconState, isPlaybackRunning: false, flags: enabledFlags))
        if shouldStopMorseVisualBeaconForReducedFlashing(state: ownerState, isPlaybackRunning: false, flags: enabledFlags) {
            ownerState = MorseVisualPlaybackState()
        }
        XCTAssertEqual(ownerState, completedBeaconState, "Completed beacon output must not be cleared by a later Reduce Motion change")
    }

    @MainActor
    func testScheduleMorseVisualPlaybackInitialStateAndFallback() throws {
        let sequence = try textToTimedMorse("E", profile: profileForName(.isedParis))
        var beaconState = MorseVisualPlaybackState()
        var tapeState = MorseVisualPlaybackState()
        var beaconTasks: [Task<Void, Never>] = []
        var tapeTasks: [Task<Void, Never>] = []
        defer {
            beaconTasks.forEach { $0.cancel() }
            tapeTasks.forEach { $0.cancel() }
        }

        beaconTasks = scheduleMorseVisualPlayback(sequence: sequence, requestedMode: .visualBeacon, reduceFlashing: false, colorScheme: .light) { beaconState = $0 }
        tapeTasks = scheduleMorseVisualPlayback(sequence: sequence, requestedMode: .visualBeacon, reduceFlashing: true, colorScheme: .light) { tapeState = $0 }

        XCTAssertEqual(beaconState.mode, .visualBeacon)
        XCTAssertFalse(beaconState.beaconActive)
        XCTAssertEqual(tapeState.mode, .visualTape)
        XCTAssertEqual(tapeState.tape, "")
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
        XCTAssertEqual(decoded.outputMode, .audio)
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

    func testMorseSendingPendingFinalizationHelperCancelsAndClears() throws {
        var task: Task<Void, Never>? = Task { try? await Task.sleep(for: .seconds(60)) }
        var pendingSamples = [MorseKeyTimingSample(element: .dot, durationSeconds: 0.1, expectedSeconds: 0.1, ratioToExpected: 1)]

        clearMorseSendingPendingCharacterFinalization(finalizeTask: &task, pendingSamples: &pendingSamples, clearPendingSamples: true)

        XCTAssertNil(task)
        XCTAssertTrue(pendingSamples.isEmpty)
    }

    func testMorseSendingRemainingExamSecondsUsesFixedDeadline() throws {
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let deadline = now.addingTimeInterval(90)

        XCTAssertEqual(morseSendingRemainingExamSeconds(deadline: deadline, now: now), 90)
        XCTAssertEqual(morseSendingRemainingExamSeconds(deadline: deadline, now: now.addingTimeInterval(89.1)), 1)
        XCTAssertEqual(morseSendingRemainingExamSeconds(deadline: deadline, now: deadline), 0)
        XCTAssertEqual(morseSendingRemainingExamSeconds(deadline: deadline, now: deadline.addingTimeInterval(12)), 0)
    }

    func testMorsePressKeyButtonAccessibilityActionsTriggerConfiguredKeying() async throws {
        let actions = await MainActor.run {
            var actions: [String] = []
            let straightKey = MorsePressKeyButton(
                title: "Hold key",
                accessibilityLabel: "Straight key",
                accessibilityIdentifier: "test-straight-key",
                begin: { actions.append("begin") },
                end: { actions.append("end") },
                sendDotAction: { actions.append("dot") },
                sendDashAction: { actions.append("dash") }
            )
            let paddle = MorsePressKeyButton(
                title: "Dot",
                accessibilityLabel: "Dot paddle",
                accessibilityIdentifier: "test-dot-paddle",
                begin: { actions.append("paddle-begin") },
                end: { actions.append("paddle-end") },
                defaultAction: { actions.append("paddle-default") }
            )
            straightKey.sendDotAction?()
            straightKey.sendDashAction?()
            paddle.defaultAction?()
            return actions
        }

        XCTAssertEqual(actions, ["dot", "dash", "paddle-default"])
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

    private func morseContrastRatio(_ left: MorseRGB, _ right: MorseRGB) -> Double {
        let leftLuminance = morseRelativeLuminance(left)
        let rightLuminance = morseRelativeLuminance(right)
        let lighter = max(leftLuminance, rightLuminance)
        let darker = min(leftLuminance, rightLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private struct DesignTokenRGBPair {
        let light: MorseRGB
        let dark: MorseRGB
    }

    private func designTokenRGB(named name: String, in tokens: String) throws -> DesignTokenRGBPair {
        let number = #"([0-9]+(?:\.[0-9]+)?)"#
        let pattern = #"public static let \#(name) = Color\.dynamicToken\(light: DesignTokens\.RGB\(red: \#(number), green: \#(number), blue: \#(number)\), dark: DesignTokens\.RGB\(red: \#(number), green: \#(number), blue: \#(number)\)\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let nsTokens = tokens as NSString
        let range = NSRange(location: 0, length: nsTokens.length)
        let match = try XCTUnwrap(regex.firstMatch(in: tokens, range: range), "Expected to find DesignTokens.Colors.\(name)")
        func value(at index: Int) throws -> Double {
            let range = match.range(at: index)
            return try XCTUnwrap(Double(nsTokens.substring(with: range)), "Expected numeric RGB component for DesignTokens.Colors.\(name)")
        }
        return DesignTokenRGBPair(
            light: MorseRGB(red: try value(at: 1), green: try value(at: 2), blue: try value(at: 3)),
            dark: MorseRGB(red: try value(at: 4), green: try value(at: 5), blue: try value(at: 6))
        )
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

    @MainActor
    func testStudySettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess() throws {
        let bank = try CanadianHam.QuestionBankStore.load(from: Bundle(for: Self.self))
        let suiteName = "MorseTrainerTests.studyImport.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        var settings = MorseTrainerSettings.default
        var replacements: [Bool] = []
        let view = SettingsView(
            bank: bank,
            progressStore: store,
            morseSettings: Binding(get: { settings }, set: { settings = $0 }),
            openMorse: {},
            openAbout: {},
            hasUnfinishedCourseWork: { false },
            localDataReplacementRevision: 0,
            onDataChanged: { replacements.append($0) }
        )

        for (json, expected) in morseImportCases {
            let imported = try morseImportFixture(bankId: bank.manifest.bankId, morseJSON: json)
            try view.importProgress(imported, defaults: defaults)
            XCTAssertEqual(settings, expected, "Study Settings must normalize its live binding")
            XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), expected)
            XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        }
        XCTAssertEqual(replacements, Array(repeating: true, count: morseImportCases.count))

        let beforeFailure = settings
        let invalid = try morseImportFixture(bankId: "unknown-bank", morseJSON: morseImportCases[0].0)
        XCTAssertThrowsError(try view.importProgress(invalid, defaults: defaults))
        XCTAssertEqual(settings, beforeFailure)
        XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), beforeFailure)
        XCTAssertEqual(replacements.count, morseImportCases.count, "A rejected import must not announce replacement")
    }

#if os(macOS)
    @MainActor
    func testNativeSettingsImportUpdatesLiveAndPersistedMorseSettingsOnlyAfterSuccess() throws {
        let bank = try CanadianHam.QuestionBankStore.load(from: Bundle(for: Self.self))
        let suiteName = "MorseTrainerTests.nativeImport.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = try CanadianHam.ProgressStoreService.inMemoryForTests(defaults: defaults, defaultsDomainName: suiteName)
        let appSettings = AppSettingsModel(morseSettings: .default)
        appSettings.bank = bank
        appSettings.progressStore = store
        let view = NativeDataSettingsTab(appSettings: appSettings)
        let initialRevision = appSettings.localDataReplacementRevision

        for (json, expected) in morseImportCases {
            let imported = try morseImportFixture(bankId: bank.manifest.bankId, morseJSON: json)
            try view.importProgress(imported, defaults: defaults)
            XCTAssertEqual(appSettings.morseSettings, expected, "Native Settings must normalize its live observable model")
            XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), expected)
            XCTAssertEqual(store.preferences.practiceMode, .reviewLater)
        }
        XCTAssertEqual(appSettings.localDataReplacementRevision, initialRevision + morseImportCases.count)

        let beforeFailure = appSettings.morseSettings
        let invalid = try morseImportFixture(bankId: "unknown-bank", morseJSON: morseImportCases[0].0)
        XCTAssertThrowsError(try view.importProgress(invalid, defaults: defaults))
        XCTAssertEqual(appSettings.morseSettings, beforeFailure)
        XCTAssertEqual(MorseTrainerSettings.load(defaults: defaults), beforeFailure)
        XCTAssertEqual(appSettings.localDataReplacementRevision, initialRevision + morseImportCases.count)
    }
#endif

    private var morseImportCases: [(String, MorseTrainerSettings)] {
        [
            (#"{"toneHz":1200,"characterWpm":30,"effectiveWpm":28,"timingProfile":"general","volume":2,"outputMode":"visualTape"}"#,
             MorseTrainerSettings(toneHz: 900, characterWpm: 25, effectiveWpm: 25, timingProfile: .general, volume: 1, outputMode: .visualTape)),
            (#"{"toneHz":700,"characterWpm":18,"effectiveWpm":6,"timingProfile":"future-profile","volume":0.4,"outputMode":"future-output"}"#,
             MorseTrainerSettings(toneHz: 700, characterWpm: 18, effectiveWpm: 6, timingProfile: .isedParis, volume: 0.4, outputMode: .audio))
        ]
    }

    private func morseImportFixture(bankId: String, morseJSON: String) throws -> CanadianHam.ProgressExportV1 {
        let json = """
        {
          "schema": "canadian-ham.progress-export",
          "version": 1,
          "exportedAt": "2026-01-02T05:04:05.000Z",
          "bankId": "\(bankId)",
          "questionProgress": [],
          "examAttempts": [],
          "lessonProgress": [],
          "lessonQuizAttempts": [],
          "preferences": {
            "practiceMode": "review-later",
            "examTimerEnabled": false,
            "theme": "system",
            "morse": \(morseJSON)
          }
        }
        """
        return try JSONDecoder().decode(CanadianHam.ProgressExportV1.self, from: Data(json.utf8))
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
