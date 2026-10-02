import AVFoundation
import CanadianHamMorseEngine
import Foundation

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

    func amplitude(at frame: AVAudioFramePosition) -> Double {
        guard let segment = segments.first(where: { frame >= $0.startFrame && frame < $0.endFrame }) else { return 0 }
        let framesIntoSegment = frame - segment.startFrame
        let framesUntilEnd = segment.endFrame - frame
        let edgeFrames = min(rampFrames, max(1, (segment.endFrame - segment.startFrame) / 2))
        let envelope = min(1, Double(min(framesIntoSegment, framesUntilEnd)) / Double(edgeFrames))
        return volume * max(0, envelope)
    }
}

final class MorseAudioDriver {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var schedule: MorseAudioSchedule?
    private var currentFrame: AVAudioFramePosition = 0
    private var phase = 0.0

    var isPlaying: Bool { engine.isRunning }

    func play(text: String, settings: MorseTrainerSettings) throws -> TimeInterval {
        stop()
        let sequence = try textToTimedMorse(text, profile: settings.timingProfileValue())
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48_000
        let nextSchedule = MorseAudioSchedule(sequence: sequence, settings: settings, sampleRate: sampleRate)
        schedule = nextSchedule
        currentFrame = 0
        phase = 0

#if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
#endif

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self, let schedule = self.schedule else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frameOffset in 0..<Int(frameCount) {
                let frame = self.currentFrame + AVAudioFramePosition(frameOffset)
                let amplitude = schedule.amplitude(at: frame)
                let sample = Float(sin(self.phase) * amplitude)
                self.phase += (2 * Double.pi * schedule.frequency) / schedule.sampleRate
                if self.phase > 2 * Double.pi { self.phase -= 2 * Double.pi }
                for buffer in abl {
                    let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    pointer?[frameOffset] = sample
                }
            }
            self.currentFrame += AVAudioFramePosition(frameCount)
            return noErr
        }
        sourceNode = node
        engine.attach(node)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: max(1, outputFormat.channelCount))
        engine.connect(node, to: [AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 0)], fromBus: 0, format: format)
        try engine.start()
        return sequence.totalDurationSeconds
    }

    func stop() {
        if engine.isRunning {
            engine.stop()
        }
        if let sourceNode {
            engine.detach(sourceNode)
        }
        sourceNode = nil
        schedule = nil
        currentFrame = 0
        phase = 0
    }
}
