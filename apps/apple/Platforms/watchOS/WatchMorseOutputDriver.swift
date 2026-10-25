import AVFoundation
import CanadianHamMorseEngine
import Foundation
import WatchKit

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

    init(schedule: WatchMorseToneSchedule) { self.schedule = schedule }

    func render(count: AVAudioFrameCount, buffers: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let list = UnsafeMutableAudioBufferListPointer(buffers)
        for offset in 0..<Int(count) {
            let sample = schedule.sample(at: frame + Int64(offset))
            for buffer in list {
                buffer.mData?.assumingMemoryBound(to: Float.self)[offset] = sample
            }
        }
        frame += Int64(count)
        return noErr
    }
}

@MainActor
final class WatchMorseOutputDriver: WatchMorseOutput {
    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private var ownsAudioSession = false

    func haptic(_ pulse: WatchMorsePulse) {
        // Fixed presets, NOT arbitrary-duration Morse pulses. See hardware gate.
        WKInterfaceDevice.current().play(pulse == .dot ? .click : .directionUp)
    }

    func startTone(sequence: TimedMorseSequence) throws {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            ownsAudioSession = true
            let engine = AVAudioEngine()
            self.engine = engine
            let outputFormat = engine.outputNode.outputFormat(forBus: 0)
            let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
            let renderer = WatchMorseToneRenderer(schedule: WatchMorseToneSchedule(sequence: sequence, sampleRate: rate))
            let source = AVAudioSourceNode { _, _, count, buffers in
                renderer.render(count: count, buffers: buffers)
            }
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
        if ownsAudioSession {
            ownsAudioSession = false
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}
