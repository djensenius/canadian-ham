import AVFoundation
import CanadianHamMorseEngine
import Foundation
import Observation

@MainActor
protocol WatchMorseScheduledWork: AnyObject {
    func cancel()
}

@MainActor
protocol WatchMorseScheduler {
    var now: Double { get }
    func schedule(after seconds: Double, action: @escaping @MainActor () -> Void) -> any WatchMorseScheduledWork
}

@MainActor
private final class WatchMorseTask: WatchMorseScheduledWork {
    let task: Task<Void, Never>

    init(seconds: Double, action: @escaping @MainActor () -> Void) {
        task = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard !Task.isCancelled else { return }
            action()
        }
    }

    func cancel() { task.cancel() }
}

@MainActor
struct WatchMorseLiveScheduler: WatchMorseScheduler {
    var now: Double { ProcessInfo.processInfo.systemUptime }
    func schedule(after seconds: Double, action: @escaping @MainActor () -> Void) -> any WatchMorseScheduledWork {
        WatchMorseTask(seconds: max(0, seconds), action: action)
    }
}

@MainActor
protocol WatchMorseOutput: AnyObject {
    func startTone(sequence: TimedMorseSequence) throws
    func haptic(_ pulse: WatchMorsePulse, style: WatchMorseHapticStyle)
    func stop()
}

/// The last time any Morse playback issued a WatchKit haptic preset. A started preset can't be
/// cancelled, so the minimum spacing has to survive leaving and re-entering the Morse screen
/// (each visit builds a new `WatchMorsePlayback`). Shared per process; tests inject their own.
@MainActor
final class WatchMorseHapticCooldown {
    static let device = WatchMorseHapticCooldown()
    var lastHapticAt: Double?
}

@MainActor
@Observable
final class WatchMorsePlayback {
    private let output: any WatchMorseOutput
    private let scheduler: any WatchMorseScheduler
    private var pending: [any WatchMorseScheduledWork] = []
    private var generation = 0
    private let cooldown: WatchMorseHapticCooldown
    private var lastHapticAt: Double? {
        get { cooldown.lastHapticAt }
        set { cooldown.lastHapticAt = newValue }
    }
    private(set) var isPlaying = false
    private(set) var hasCompleted = false
    private(set) var outputFailed = false

    init(output: any WatchMorseOutput, scheduler: any WatchMorseScheduler = WatchMorseLiveScheduler(),
         cooldown: WatchMorseHapticCooldown = .device) {
        self.output = output
        self.scheduler = scheduler
        self.cooldown = cooldown
    }

    func play(letter: String, settings: WatchMorseSettings) {
        // Replay is disabled in the UI too; programmatic replay cannot overlap.
        guard !isPlaying, settings.hasOutput else { return }
        cancel()
        outputFailed = false
        guard let sequence = try? settings.sequence(for: letter) else {
            outputFailed = true
            return
        }
        isPlaying = true
        let current = generation
        let delay = lastHapticAt.map { max(0, $0 + WatchMorseSettings.minimumHapticSpacing - scheduler.now) } ?? 0
        enqueue(after: delay, generation: current) { player in
            do {
                if settings.tone { try player.output.startTone(sequence: sequence) }
            } catch {
                player.cancel()
                player.outputFailed = true
                return
            }
            if settings.haptics {
                player.scheduleHaptic(sequence: sequence, events: WatchMorseEvent.events(for: sequence),
                                      style: settings.hapticStyle, index: 0, origin: player.scheduler.now, generation: current)
            } else {
                player.finish(after: Self.signalEnd(sequence), generation: current)
            }
        }
    }

    func cancel() {
        generation += 1
        pending.forEach { $0.cancel() }
        pending.removeAll()
        output.stop()
        isPlaying = false
        // WatchKit cannot stop a preset already issued. Retain its onset across
        // cancellation so a new round/replay still observes the spacing floor.
    }

    func handleAudioInterruption(_ notification: Notification) {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .began else { return }
        cancel()
    }

    func next() {
        cancel()
        hasCompleted = false
        outputFailed = false
    }

    private static func signalEnd(_ sequence: TimedMorseSequence) -> Double {
        // One character needs no trailing word gap.
        sequence.symbols.filter { $0.kind == .dot || $0.kind == .dash }
            .map { $0.startSeconds + $0.durationSeconds }.max() ?? 0
    }

    private func scheduleHaptic(sequence: TimedMorseSequence, events: [WatchMorseEvent], style: WatchMorseHapticStyle, index: Int,
                                origin: Double, generation current: Int) {
        guard events.indices.contains(index) else {
            finish(after: 0, generation: current)
            return
        }
        let event = events[index]
        let earliest = max(origin + event.atSeconds, lastHapticAt.map { $0 + WatchMorseSettings.minimumHapticSpacing } ?? 0)
        enqueue(after: max(0, earliest - scheduler.now), generation: current) { player in
            player.output.haptic(event.pulse, style: style)
            player.lastHapticAt = player.scheduler.now
            if index + 1 < events.count {
                // Schedule the next only after this onset; a delayed main actor
                // must not dump overdue presets into WatchKit in a burst.
                player.scheduleHaptic(sequence: sequence, events: events, style: style, index: index + 1,
                                      origin: origin, generation: current)
            } else {
                player.finish(after: Self.signalEnd(sequence) - event.atSeconds, generation: current)
            }
        }
    }

    private func finish(after seconds: Double, generation current: Int) {
        enqueue(after: seconds, generation: current) { player in
            player.cancel()
            player.hasCompleted = true
        }
    }

    private func enqueue(after seconds: Double, generation expected: Int,
                         action: @escaping @MainActor (WatchMorsePlayback) -> Void) {
        pending.append(scheduler.schedule(after: seconds) { [weak self] in
            guard let self, self.generation == expected else { return }
            action(self)
        })
    }
}
