import AVFoundation
import CanadianHamMorseEngine
#if canImport(CoreHaptics)
import CoreHaptics
#endif
import Foundation

private let morseMinimumStopDrainSeconds: TimeInterval = 0.1

struct MorseAudioStopTiming: Equatable, Sendable {
    static func stopDelay(rampDuration: TimeInterval) -> TimeInterval {
        max(morseMinimumStopDrainSeconds, rampDuration)
    }
}

struct MorseAudioSegment: Equatable, Sendable {
    let startFrame: AVAudioFramePosition
    let endFrame: AVAudioFramePosition
}

struct MorseAudioSchedule: Equatable, Sendable {
    let sampleRate: Double
    let frequency: Double
    let volume: Double
    let rampFrames: AVAudioFramePosition
    let totalFrames: AVAudioFramePosition
    let segments: [MorseAudioSegment]

    init(sequence: TimedMorseSequence, settings: MorseTrainerSettings, sampleRate: Double = 48_000, rampSeconds: Double = 0.005) {
        let normalized = settings.normalized()
        self.sampleRate = sampleRate
        frequency = Double(normalized.toneHz)
        volume = normalized.volume
        rampFrames = max(1, AVAudioFramePosition((rampSeconds * sampleRate).rounded()))
        totalFrames = AVAudioFramePosition(((sequence.totalDurationSeconds + rampSeconds) * sampleRate).rounded(.up))
        segments = sequence.symbols.compactMap { symbol in
            guard symbol.kind == .dot || symbol.kind == .dash else { return nil }
            let start = AVAudioFramePosition((symbol.startSeconds * sampleRate).rounded())
            let end = AVAudioFramePosition(((symbol.startSeconds + symbol.durationSeconds) * sampleRate).rounded())
            return MorseAudioSegment(startFrame: start, endFrame: max(start + 1, end))
        }
    }

    init(continuousSettings settings: MorseTrainerSettings, sampleRate: Double = 48_000, rampSeconds: Double = 0.005) {
        let normalized = settings.normalized()
        self.sampleRate = sampleRate
        frequency = Double(normalized.toneHz)
        volume = normalized.volume
        rampFrames = max(1, AVAudioFramePosition((rampSeconds * sampleRate).rounded()))
        totalFrames = AVAudioFramePosition.max
        segments = [MorseAudioSegment(startFrame: 0, endFrame: AVAudioFramePosition.max)]
    }

    func amplitude(at frame: AVAudioFramePosition, stopRampStartFrame: AVAudioFramePosition? = nil) -> Double {
        guard let segment = segments.first(where: { frame >= $0.startFrame && frame < $0.endFrame }) else { return 0 }
        let framesIntoSegment = frame - segment.startFrame
        let framesUntilEnd = segment.endFrame - frame
        let edgeFrames = min(rampFrames, max(1, (segment.endFrame - segment.startFrame) / 2))
        let envelope = min(1, Double(min(framesIntoSegment, framesUntilEnd)) / Double(edgeFrames))
        let stopEnvelope: Double
        if let stopRampStartFrame, frame >= stopRampStartFrame {
            stopEnvelope = max(0, 1 - (Double(frame - stopRampStartFrame) / Double(rampFrames)))
        } else {
            stopEnvelope = 1
        }
        return volume * max(0, envelope) * stopEnvelope
    }
}

private final class MorseAudioRenderState {
    // NSLock is intentionally kept instead of os_unfair_lock: this shared render state is tiny,
    // cross-platform XCTest coverage can exercise it without platform-specific wrappers, and the
    // lock only guards constant-time reads/writes around AVAudioSourceNode callbacks.
    private let lock = NSLock()
    private var schedule: MorseAudioSchedule?
    private var currentFrame: AVAudioFramePosition = 0
    private var phase = 0.0
    private var stopRampStartFrame: AVAudioFramePosition?

    func configure(schedule: MorseAudioSchedule) {
        lock.withLock {
            self.schedule = schedule
            currentFrame = 0
            phase = 0
            stopRampStartFrame = nil
        }
    }

    func requestStopRamp() -> TimeInterval? {
        lock.withLock {
            guard let schedule else { return nil }
            if stopRampStartFrame == nil {
                stopRampStartFrame = currentFrame
            }
            return Double(schedule.rampFrames) / schedule.sampleRate
        }
    }

    func reset() {
        lock.withLock {
            schedule = nil
            currentFrame = 0
            phase = 0
            stopRampStartFrame = nil
        }
    }

    func render(frameCount: AVAudioFrameCount, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        lock.withLock {
            guard let schedule else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frameOffset in 0..<Int(frameCount) {
                let frame = currentFrame + AVAudioFramePosition(frameOffset)
                let amplitude = schedule.amplitude(at: frame, stopRampStartFrame: stopRampStartFrame)
                let sample = Float(sin(phase) * amplitude)
                phase += (2 * Double.pi * schedule.frequency) / schedule.sampleRate
                if phase > 2 * Double.pi { phase -= 2 * Double.pi }
                for buffer in abl {
                    let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    pointer?[frameOffset] = sample
                }
            }
            currentFrame += AVAudioFramePosition(frameCount)
            return noErr
        }
    }
}

/// Counts Morse players using the shared audio session, so one player's delayed
/// cleanup can't deactivate the session while another player is already playing.
struct MorseAudioSessionUsage: Equatable, Sendable {
    private(set) var activeUsers = 0

    /// Records a player starting to use the session.
    mutating func acquire() {
        activeUsers += 1
    }

    /// Records a player releasing the session; returns true when it was the last user.
    mutating func release() -> Bool {
        activeUsers = max(0, activeUsers - 1)
        return activeUsers == 0
    }
}

final class MorseHapticDriver {
#if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?
#endif

    private static let cachedSupportsHaptics: Bool = {
#if os(iOS) && canImport(CoreHaptics)
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
#else
        false
#endif
    }()

    static var supportsHaptics: Bool { cachedSupportsHaptics }

    func play(sequence: TimedMorseSequence) throws -> TimeInterval {
#if os(iOS) && canImport(CoreHaptics)
        guard Self.supportsHaptics else { throw MorseOutputError.hapticsUnavailable }
        stop()
        let engine = try CHHapticEngine()
        try engine.start()
        let events = morseHapticEvents(sequence: sequence).map { event in
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: event.symbolKind == .dot ? 0.55 : 0.75),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65),
                ],
                relativeTime: event.startSeconds,
                duration: event.durationSeconds
            )
        }
        let pattern = try CHHapticPattern(events: events, parameters: [])
        let player = try engine.makePlayer(with: pattern)
        try player.start(atTime: 0)
        self.engine = engine
        self.player = player
        return sequence.totalDurationSeconds
#else
        throw MorseOutputError.hapticsUnavailable
#endif
    }

    func stop() {
#if canImport(CoreHaptics)
        try? player?.stop(atTime: 0)
        player = nil
        engine?.stop(completionHandler: nil)
        engine = nil
#endif
    }
}

enum MorseOutputError: LocalizedError {
    case hapticsUnavailable

    var errorDescription: String? {
        switch self {
        case .hapticsUnavailable:
            String(localized: "Haptics are not available on this device.")
        }
    }
}

final class MorseAudioDriver {
    nonisolated(unsafe) private static var sessionUsage = MorseAudioSessionUsage()
    // Sending prepares on its audio actor while other players use the main actor.
    private static let sessionUsageLock = NSLock()
    private var holdsSession = false

    private let engine: AVAudioEngine
    private let renderState = MorseAudioRenderState()
    private var sourceNode: AVAudioSourceNode?
    private var pendingStopWorkItem: DispatchWorkItem?

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.engine = engine
    }

#if DEBUG
    static var activeSessionUsers: Int {
        sessionUsageLock.withLock { sessionUsage.activeUsers }
    }
#endif

    var isPlaying: Bool { engine.isRunning }

    func play(text: String, settings: MorseTrainerSettings) throws -> TimeInterval {
        stopImmediately()
        let sequence = try textToTimedMorse(text, profile: settings.timingProfileValue())
        try start(scheduleFactory: { sampleRate in
            MorseAudioSchedule(sequence: sequence, settings: settings, sampleRate: sampleRate)
        }, settings: settings)
        return sequence.totalDurationSeconds
    }

    func startTone(settings: MorseTrainerSettings) throws {
        stopImmediately()
        try start(scheduleFactory: { sampleRate in
            MorseAudioSchedule(continuousSettings: settings, sampleRate: sampleRate)
        }, settings: settings)
    }

    // Sending retains a silent engine between elements so key events never wait for
    // AVAudioEngine startup. The sending audio actor serializes these operations.
    func prepareSendingTone(settings: MorseTrainerSettings) throws {
        guard !engine.isRunning else { return }
        // An interruption can stop the engine without detaching its old source
        // or releasing its session. Clean both up before attaching a replacement.
        stopImmediately()
        var silentSettings = settings
        silentSettings.volume = 0
        try start(scheduleFactory: { sampleRate in
            MorseAudioSchedule(continuousSettings: silentSettings, sampleRate: sampleRate)
        }, settings: silentSettings)
    }

    func startPreparedSendingTone(settings: MorseTrainerSettings) {
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        renderState.configure(schedule: MorseAudioSchedule(continuousSettings: settings, sampleRate: sampleRate > 0 ? sampleRate : 48_000))
    }

    func playPreparedSendingElement(_ element: MorseKeyElement, settings: MorseTrainerSettings) throws {
        let sequence = try textToTimedMorse(element == .dot ? "E" : "T", profile: settings.timingProfileValue())
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        renderState.configure(schedule: MorseAudioSchedule(sequence: sequence, settings: settings, sampleRate: sampleRate > 0 ? sampleRate : 48_000))
    }

    func silencePreparedSendingTone() {
        _ = renderState.requestStopRamp()
    }

    func releasePreparedSendingTone() {
        stopImmediately()
    }

    private func start(scheduleFactory: (Double) -> MorseAudioSchedule, settings: MorseTrainerSettings) throws {
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
        renderState.configure(schedule: scheduleFactory(sampleRate))

        try Self.sessionUsageLock.withLock { () throws -> Void in
#if !os(macOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
#endif
            if !holdsSession {
                holdsSession = true
                Self.sessionUsage.acquire()
            }
        }

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            self?.renderState.render(frameCount: frameCount, audioBufferList: audioBufferList) ?? noErr
        }
        sourceNode = node
        engine.attach(node)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: max(1, outputFormat.channelCount))
        engine.connect(node, to: [AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 0)], fromBus: 0, format: format)
        do {
            try engine.start()
        } catch {
            cleanupStoppedEngine()
            throw error
        }
    }

    func stop() {
        pendingStopWorkItem?.cancel()
        guard engine.isRunning else {
            cleanupStoppedEngine()
            return
        }
        let rampDuration = renderState.requestStopRamp() ?? 0.005
        let stopDelay = MorseAudioStopTiming.stopDelay(rampDuration: rampDuration)
        let workItem = DispatchWorkItem {
            self.stopImmediately()
        }
        pendingStopWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay, execute: workItem)
    }

    private func stopImmediately() {
        pendingStopWorkItem?.cancel()
        pendingStopWorkItem = nil
        if engine.isRunning {
            engine.stop()
        }
        cleanupStoppedEngine()
    }

    private func cleanupStoppedEngine() {
        if let sourceNode {
            engine.detach(sourceNode)
        }
        sourceNode = nil
        renderState.reset()
        guard holdsSession else { return }
        holdsSession = false
        Self.sessionUsageLock.withLock {
            let wasLastUser = Self.sessionUsage.release()
#if !os(macOS)
            if wasLastUser {
                try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            }
#else
            _ = wasLastUser
#endif
        }
    }
}
