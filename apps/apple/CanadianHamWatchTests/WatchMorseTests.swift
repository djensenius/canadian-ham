import AVFoundation
import CanadianHamMorseEngine
import XCTest
import WatchKit
@testable import CanadianHamWatch

final class WatchMorseTests: XCTestCase {
    func testTimingFixturesMapToWatchPresetsAndToneSegments() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "timing", withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let fixture = try decoder.decode(TimingFixture.self, from: Data(contentsOf: url))
        var checked = 0
        for item in fixture.cases {
            guard let expected = item.expectedOutput, let symbols = expected.symbols else { continue }
            let profile: MorseTimingProfile
            if let name = item.input.profile.name {
                profile = profileForName(try XCTUnwrap(MorseProfileName(rawValue: name)))
            } else {
                profile = try farnsworthTiming(characterWpm: XCTUnwrap(item.input.profile.characterWpm),
                                               effectiveWpm: XCTUnwrap(item.input.profile.effectiveWpm))
            }
            let sequence = try textToTimedMorse(item.input.text, profile: profile)
            let expectedSignals = symbols.filter { $0.kind == "dot" || $0.kind == "dash" }
            let events = WatchMorseEvent.events(for: sequence)
            XCTAssertEqual(events.count, expectedSignals.count, item.id)
            for (event, symbol) in zip(events, expectedSignals) {
                XCTAssertEqual(event.atSeconds, symbol.startSeconds, accuracy: 1e-9, item.id)
                XCTAssertEqual(event.pulse, symbol.kind == "dot" ? .dot : .dash, item.id)
            }
            let tone = WatchMorseToneSchedule(sequence: sequence, sampleRate: 48_000)
            XCTAssertEqual(tone.segments.count, expectedSignals.count, item.id)
            for (segment, symbol) in zip(tone.segments, expectedSignals) {
                XCTAssertEqual(segment.lowerBound, Int64((symbol.startSeconds * 48_000).rounded()), item.id)
                let duration = symbol.kind == "dot" ? expected.durationsSeconds.dot : expected.durationsSeconds.dash
                XCTAssertEqual(segment.upperBound, Int64(((symbol.startSeconds + duration) * 48_000).rounded()), item.id)
                XCTAssertEqual(tone.sample(at: segment.lowerBound), 0, accuracy: 0.0001)
                XCTAssertEqual(tone.sample(at: segment.upperBound), 0, accuracy: 0.0001)
            }
            checked += 1
        }
        XCTAssertGreaterThan(checked, 0)
    }

    func testFourDistinctSeededChoicesGradingAndNextReset() throws {
        for seed in 0..<100 {
            var drill = WatchMorseDrill(seed: "\(seed)")
            let same = WatchMorseDrill(seed: "\(seed)")
            XCTAssertEqual(drill.letter, same.letter)
            XCTAssertEqual(drill.choices, same.choices)
            XCTAssertEqual(drill.choices.count, 4)
            XCTAssertEqual(Set(drill.choices).count, 4)
            XCTAssertTrue(drill.choices.allSatisfy { WatchMorseDrill.alphabet.contains($0) })
            XCTAssertTrue(drill.choices.contains(drill.letter))
            drill.submit("0")
            XCTAssertNil(drill.selected)
            let wrong = try XCTUnwrap(drill.choices.first { $0 != drill.letter })
            drill.submit(wrong)
            XCTAssertFalse(drill.isCorrect)
            drill.submit(drill.letter)
            XCTAssertEqual(drill.selected, wrong, "Submission locks")
            let previous = drill.letter
            drill.next()
            XCTAssertNotEqual(drill.letter, previous)
            XCTAssertNil(drill.selected)
            drill.submit(drill.letter)
            XCTAssertTrue(drill.isCorrect)
            XCTAssertEqual(drill.pattern, morseCodeTable[drill.letter])
        }
    }

    func testSpeedClampsAndAllLettersRespectCadenceFloor() throws {
        for speed in [-10.0, 1, 1.5, 2, 50, .infinity, .nan] {
            var settings = WatchMorseSettings()
            settings.wordsPerMinute = speed
            for letter in WatchMorseDrill.alphabet {
                let sequence = try settings.sequence(for: letter)
                XCTAssertGreaterThanOrEqual(sequence.profile.dotSeconds, 0.6)
                let events = WatchMorseEvent.events(for: sequence)
                for pair in zip(events, events.dropFirst()) {
                    XCTAssertGreaterThanOrEqual(pair.1.atSeconds - pair.0.atSeconds + 1e-9, WatchMorseSettings.minimumHapticSpacing)
                }
            }
        }
        XCTAssertEqual(try WatchMorseSettings().sequence(for: "A").profile.dotSeconds, 0.6, accuracy: 1e-12)
    }

    @MainActor
    func testHapticStylesMapEveryPairAndReachOutput() {
        let expected: [(WatchMorseHapticStyle, WKHapticType, WKHapticType)] = [
            (.lightRising, .click, .directionUp), (.lightFirm, .click, .start), (.strongFirm, .retry, .start)
        ]
        XCTAssertEqual(Set(expected.map(\.0)), Set(WatchMorseHapticStyle.allCases))
        XCTAssertEqual(WatchMorseSettings().hapticStyle, .lightRising)
        for (style, dot, dash) in expected {
            XCTAssertEqual(style.haptic(for: .dot), dot)
            XCTAssertEqual(style.haptic(for: .dash), dash)
            let clock = FakeMorseScheduler()
            let output = FakeMorseOutput(clock: clock)
            let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
            var settings = WatchMorseSettings()
            settings.hapticStyle = style
            player.play(letter: "A", settings: settings)
            clock.advance(by: 10)
            XCTAssertEqual(output.pulses.map(\.pulse), [.dot, .dash])
            XCTAssertEqual(output.pulses.map(\.style), [style, style])
        }
    }

    @MainActor
    func testLocalToneDriverRendersOffMainActorAndRestartsAfterStop() async throws {
        let output = RecordingMorseToneOutput()
        defer { output.stop() }
        let clock = FakeMorseScheduler()
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        var settings = WatchMorseSettings()
        settings.haptics = false
        settings.tone = true
        for _ in 0..<2 {
            player.play(letter: "A", settings: settings)
            clock.advance(by: 0)
            if let error = output.toneError {
                // Headless hosts may have no activatable audio session. That is
                // an asserted unavailable-output path, not a silent pass/skip.
                guard case WatchMorseToneError.audioSessionUnavailable(let underlying) = error else { throw error }
                XCTAssertFalse(underlying.localizedDescription.isEmpty)
                XCTAssertTrue(player.outputFailed)
                XCTAssertFalse(player.isPlaying)
                XCTAssertFalse(player.hasCompleted)
                XCTAssertFalse(output.driver.hasActiveTone)
                print("Watch tone session unavailable; cleanup and playback failure asserted: \(underlying)")
            } else {
                let deadline = ContinuousClock.now + .seconds(3)
                while output.driver.offMainRenderCount == 0 && ContinuousClock.now < deadline {
                    try await Task.sleep(for: .milliseconds(20))
                }
                XCTAssertGreaterThan(output.driver.offMainRenderCount, 0, "A real audio callback must render off the main actor")
                XCTAssertTrue(output.driver.hasActiveTone)
                XCTAssertFalse(player.outputFailed)
                player.cancel()
                XCTAssertFalse(output.driver.hasActiveTone)
                XCTAssertEqual(output.driver.offMainRenderCount, 0, "Restart must observe a new renderer, not an old count")
            }
        }
    }

    @MainActor
    func testHapticSpacingSurvivesLeavingAndReenteringMorse() {
        // Each visit to the Morse screen builds a new playback controller. A started WatchKit preset can't be
        // cancelled, so the 1.2 s spacing must carry over through the shared cooldown.
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        let cooldown = WatchMorseHapticCooldown()
        let firstVisit = WatchMorsePlayback(output: output, scheduler: clock, cooldown: cooldown)
        firstVisit.play(letter: "E", settings: WatchMorseSettings())
        clock.advance(by: 0)
        XCTAssertEqual(output.pulses.map(\.time), [0])
        firstVisit.cancel() // Back: onDisappear cancels pending work.

        clock.advance(by: 0.3) // Quickly reopen Morse and press Play.
        let secondVisit = WatchMorsePlayback(output: output, scheduler: clock, cooldown: cooldown)
        secondVisit.play(letter: "E", settings: WatchMorseSettings())
        clock.advance(by: 0)
        XCTAssertEqual(output.pulses.count, 1, "The new controller must wait out the previous preset's spacing")
        clock.advance(by: 1.0)
        XCTAssertEqual(output.pulses.count, 2)
        XCTAssertEqual(output.pulses[1].time - output.pulses[0].time, WatchMorseSettings.minimumHapticSpacing, accuracy: 0.0001)

        // A controller with its own cooldown (as before the fix) would have fired immediately.
        let unshared = WatchMorseHapticCooldown()
        XCTAssertNil(unshared.lastHapticAt)
        XCTAssertNotNil(cooldown.lastHapticAt)
    }

    @MainActor
    func testOnlyBeganAudioInterruptionCancelsPlayback() {
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        player.play(letter: "H", settings: WatchMorseSettings())
        clock.advance(by: 0)
        for userInfo: [AnyHashable: Any] in [
            [:], [AVAudioSessionInterruptionTypeKey: 99],
            [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        ] {
            player.handleAudioInterruption(Notification(name: AVAudioSession.interruptionNotification, userInfo: userInfo))
            XCTAssertTrue(player.isPlaying)
        }
        clock.advance(by: 1.2)
        XCTAssertEqual(output.pulses.count, 2)
        player.handleAudioInterruption(Notification(name: AVAudioSession.interruptionNotification,
                                                    userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]))
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.hasCompleted)
        clock.advance(by: 10)
        XCTAssertEqual(output.pulses.count, 2)
    }

    @MainActor
    func testReplayCannotOverlapAndCompletedReplayUsesSameSequence() {
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        player.play(letter: "A", settings: WatchMorseSettings())
        player.play(letter: "T", settings: WatchMorseSettings())
        XCTAssertTrue(player.isPlaying)
        clock.advance(by: 10)
        XCTAssertEqual(output.pulses.map(\.pulse), [.dot, .dash])
        XCTAssertFalse(player.isPlaying)
        XCTAssertTrue(player.hasCompleted)
        player.play(letter: "A", settings: WatchMorseSettings())
        clock.advance(by: 10)
        XCTAssertEqual(output.pulses.map(\.pulse), [.dot, .dash, .dot, .dash])
        XCTAssertTrue(output.toneInputs.isEmpty)
    }

    @MainActor
    func testCancelBeforeStartAndMidSequenceInvalidatesEvenStaleCallbacks() {
        for beforeStart in [true, false] {
            let clock = FakeMorseScheduler()
            let output = FakeMorseOutput(clock: clock)
            let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
            player.play(letter: "H", settings: WatchMorseSettings())
            if !beforeStart { clock.advance(by: 0) }
            let stale = clock.work
            player.cancel()
            let count = output.pulses.count
            stale.forEach { $0.action() }
            clock.advance(by: 100)
            XCTAssertEqual(output.pulses.count, count)
            XCTAssertFalse(player.hasCompleted)
            XCTAssertFalse(player.isPlaying)
            XCTAssertGreaterThan(output.stops, 0)
        }
    }

    @MainActor
    func testNextCancelsAndPreservesPresetCooldown() {
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        player.play(letter: "H", settings: WatchMorseSettings())
        clock.advance(by: 0)
        XCTAssertEqual(output.pulses.count, 1)
        player.next()
        player.play(letter: "T", settings: WatchMorseSettings())
        clock.advance(by: 1.19)
        XCTAssertEqual(output.pulses.count, 1)
        clock.advance(by: 0.02)
        XCTAssertEqual(output.pulses.map(\.pulse), [.dot, .dash])
        XCTAssertGreaterThanOrEqual(output.pulses[1].time - output.pulses[0].time, 1.2)
        clock.advance(by: 10)
        XCTAssertTrue(player.hasCompleted)
        player.next()
        XCTAssertFalse(player.hasCompleted)
    }

    @MainActor
    func testDelayedSchedulerDoesNotCollapsePresets() {
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        player.play(letter: "H", settings: WatchMorseSettings())
        clock.advance(by: 0)
        clock.stall(by: 5)
        clock.advance(by: 10)
        XCTAssertEqual(output.pulses.count, 4)
        for pair in zip(output.pulses, output.pulses.dropFirst()) {
            XCTAssertGreaterThanOrEqual(pair.1.time - pair.0.time + 1e-9, 1.2)
        }
    }

    @MainActor
    func testOutputsAreIndependentOffDoesNotStartAndToneFailureStops() {
        for haptics in [false, true] {
            for tone in [false, true] {
                let clock = FakeMorseScheduler()
                let output = FakeMorseOutput(clock: clock)
                let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
                var settings = WatchMorseSettings()
                settings.haptics = haptics
                settings.tone = tone
                player.play(letter: "E", settings: settings)
                clock.advance(by: 10)
                XCTAssertEqual(output.pulses.count, haptics ? 1 : 0)
                XCTAssertEqual(output.toneInputs, tone ? ["E"] : [])
                XCTAssertEqual(player.hasCompleted, haptics || tone)
            }
        }
        let clock = FakeMorseScheduler()
        let output = FakeMorseOutput(clock: clock)
        output.failTone = true
        let player = WatchMorsePlayback(output: output, scheduler: clock, cooldown: WatchMorseHapticCooldown())
        var settings = WatchMorseSettings()
        settings.tone = true
        player.play(letter: "C", settings: settings)
        clock.advance(by: 100)
        XCTAssertTrue(player.outputFailed)
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.hasCompleted)
        XCTAssertTrue(output.pulses.isEmpty)
    }
}

@MainActor
private final class FakeMorseScheduler: WatchMorseScheduler {
    final class Work: WatchMorseScheduledWork {
        let time: Double
        let action: @MainActor () -> Void
        var cancelled = false
        init(time: Double, action: @escaping @MainActor () -> Void) { self.time = time; self.action = action }
        func cancel() { cancelled = true }
    }
    var now = 0.0
    var work: [Work] = []
    func schedule(after seconds: Double, action: @escaping @MainActor () -> Void) -> any WatchMorseScheduledWork {
        let item = Work(time: now + seconds, action: action)
        work.append(item)
        return item
    }
    func stall(by seconds: Double) { now += seconds }
    func advance(by seconds: Double) {
        let target = now + seconds
        while let item = work.filter({ !$0.cancelled && $0.time <= target }).min(by: { $0.time < $1.time }) {
            item.cancelled = true
            now = max(now, item.time)
            item.action()
        }
        now = target
    }
}

@MainActor
private final class FakeMorseOutput: WatchMorseOutput {
    let clock: FakeMorseScheduler
    var pulses: [(pulse: WatchMorsePulse, style: WatchMorseHapticStyle, time: Double)] = []
    var toneInputs: [String] = []
    var stops = 0
    var failTone = false
    init(clock: FakeMorseScheduler) { self.clock = clock }
    func startTone(sequence: TimedMorseSequence) throws {
        if failTone { throw NSError(domain: "fake-tone", code: 1) }
        toneInputs.append(sequence.normalizedText)
    }
    func haptic(_ pulse: WatchMorsePulse, style: WatchMorseHapticStyle) { pulses.append((pulse, style, clock.now)) }
    func stop() { stops += 1 }
}

@MainActor
private final class RecordingMorseToneOutput: WatchMorseOutput {
    let driver = WatchMorseOutputDriver()
    private(set) var toneError: (any Error)?

    func startTone(sequence: TimedMorseSequence) throws {
        toneError = nil
        do { try driver.startTone(sequence: sequence) }
        catch {
            toneError = error
            throw error
        }
    }
    func haptic(_ pulse: WatchMorsePulse, style: WatchMorseHapticStyle) { driver.haptic(pulse, style: style) }
    func stop() { driver.stop() }
}

private struct TimingFixture: Decodable {
    let cases: [Case]
    struct Case: Decodable {
        let id: String
        let input: Input
        let expectedOutput: Output?
    }
    struct Input: Decodable { let text: String; let profile: Profile }
    struct Profile: Decodable {
        let name: String?
        let characterWpm: Double?
        let effectiveWpm: Double?
    }
    struct Output: Decodable {
        let symbols: [Symbol]?
        let durationsSeconds: Durations
    }
    struct Durations: Decodable { let dot: Double; let dash: Double }
    struct Symbol: Decodable { let kind: String; let startSeconds: Double }
}
