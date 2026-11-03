import AVFoundation
import CanadianHamMorseEngine
import Foundation
import Synchronization
import WatchKit

enum WatchMorseHapticStyle: Int, CaseIterable {
    case lightRising, lightFirm, strongFirm

    struct Preset {
        let title: LocalizedStringResource
        let description: LocalizedStringResource
        let dot: WKHapticType
        let dash: WKHapticType
    }

    // Candidate sensations, not hardware-verified durations. Keep every pair in
    // this table so the owner can compare them without changing the build.
    static let presets: [Self: Preset] = [
        .lightRising: Preset(title: "Style 1", description: "Light dot, rising dash", dot: .click, dash: .directionUp),
        .lightFirm: Preset(title: "Style 2", description: "Light dot, firm dash", dot: .click, dash: .start),
        .strongFirm: Preset(title: "Style 3", description: "Stronger dot, firm dash", dot: .retry, dash: .start)
    ]

    var preset: Preset { Self.presets[self]! }
    func haptic(for pulse: WatchMorsePulse) -> WKHapticType { pulse == .dot ? preset.dot : preset.dash }
}

enum WatchMorseToneError: Error {
    case audioSessionUnavailable(any Error)
}

struct WatchMorseToneSchedule {
    let sampleRate: Double
    let segments: [Range<Int64>]

    init(sequence: TimedMorseSequence, sampleRate: Double) {
        self.sampleRate = sampleRate
        segments = sequence.symbols.compactMap { symbol in
            guard symbol.kind == .dot || symbol.kind == .dash else { return nil }
            let start = Int64((symbol.startSeconds * sampleRate).rounded())
            let end = Int64(((symbol.startSeconds + symbol.durationSeconds) * sampleRate).rounded())
            return start..<max(start + 1, end)
        }
    }

    func sample(at frame: Int64) -> Float {
        guard let segment = segments.first(where: { $0.contains(frame) }) else { return 0 }
        // 5 ms attack/release, like the iOS synthesizer, avoids hard-edged clicks.
        let ramp = max(1, min(sampleRate * 0.005, Double(segment.count) / 2))
        let envelope = min(1, Double(min(frame - segment.lowerBound, segment.upperBound - frame)) / ramp)
        return Float(sin(2 * .pi * 600 * Double(frame) / sampleRate) * 0.2 * envelope)
    }
}

// Only the audio callback uses frame; the immutable schedule and callback's
// cursor are retired by stopping/detaching the engine before another is created.
private final class WatchMorseToneRenderer: @unchecked Sendable {
    let schedule: WatchMorseToneSchedule
    private var frame: Int64 = 0
    // Relaxed atomics let tests observe real audio-thread work without a lock in
    // the render callback. The cursor itself remains audio-thread-only.
    let offMainRenderCount = Atomic<Int>(0)

    init(schedule: WatchMorseToneSchedule) { self.schedule = schedule }

    // Construct outside the main-actor driver so Swift does not infer main-actor
    // isolation for a callback AVFoundation runs on its real-time audio thread.
    func makeSourceNode() -> AVAudioSourceNode {
        AVAudioSourceNode { [self] _, _, count, buffers in
            render(count: count, buffers: buffers)
        }
    }

    func render(count: AVAudioFrameCount, buffers: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let list = UnsafeMutableAudioBufferListPointer(buffers)
        for offset in 0..<Int(count) {
            let sample = schedule.sample(at: frame + Int64(offset))
            for buffer in list {
                buffer.mData?.assumingMemoryBound(to: Float.self)[offset] = sample
            }
        }
        frame += Int64(count)
        if !Thread.isMainThread { offMainRenderCount.wrappingAdd(1, ordering: .relaxed) }
        return noErr
    }
}

@MainActor
final class WatchMorseOutputDriver: WatchMorseOutput {
    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private var ownsAudioSession = false
    private var renderer: WatchMorseToneRenderer?

    var offMainRenderCount: Int { renderer?.offMainRenderCount.load(ordering: .relaxed) ?? 0 }
    var hasActiveTone: Bool { engine != nil || source != nil || ownsAudioSession }

    func haptic(_ pulse: WatchMorsePulse, style: WatchMorseHapticStyle) {
        // Fixed presets, NOT arbitrary-duration Morse pulses. See hardware gate.
        WKInterfaceDevice.current().play(style.haptic(for: pulse))
    }

    func startTone(sequence: TimedMorseSequence) throws {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                ownsAudioSession = true
            } catch {
                throw WatchMorseToneError.audioSessionUnavailable(error)
            }
            let engine = AVAudioEngine()
            self.engine = engine
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
            let renderer = WatchMorseToneRenderer(schedule: WatchMorseToneSchedule(sequence: sequence, sampleRate: rate))
            self.renderer = renderer
            let source = renderer.makeSourceNode()
            self.source = source
            engine.attach(source)
            engine.connect(source, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1))
            try engine.start()
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        engine?.stop()
        if let source { engine?.detach(source) }
        source = nil
        engine = nil
        renderer = nil
        if ownsAudioSession {
            ownsAudioSession = false
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}
