import Foundation
#if os(iOS)
import SwiftUI
import UIKit
#endif

/// Hinge states used by the app-level posture seam. The cases mirror UIKit's
/// UIHinge.Status where available, with `.unavailable` for non-Duo devices or
/// SDKs/runtimes that cannot vend hinge updates.
enum DuoPosture: Equatable, Sendable {
    case unavailable
    case closed
    case partiallyOpen
    case unfolded
    case unknown
}

struct DuoPostureSample: Equatable, Sendable {
    var posture: DuoPosture
    /// Hinge angle in degrees. UIKit reports radians; the app converts to
    /// degrees at the provider boundary so the pure peek policy is SDK-free.
    var angleDegrees: Double?
    var timestamp: TimeInterval

    static let unavailable = DuoPostureSample(posture: .unavailable, angleDegrees: nil, timestamp: 0)
}

struct HingePeekConfiguration: Equatable, Sendable {
    /// Slight-open band for Hint 1 peek. The band intentionally avoids near-0°
    /// closed readings and wider unfolding angles; real-hardware verification
    /// in TASK-54 can tune these defaults if the iPhone Duo reports different
    /// comfortable peek angles.
    var peekAngleRange: ClosedRange<Double> = 20...35
    /// Require a stable hold so a normal unfold that passes through the band
    /// does not reveal a hint.
    var dwellTime: TimeInterval = 0.7
    /// Keep the candidate alive through small sensor jitter around the band
    /// edges without peeking unless the latest sample is back in range.
    var edgeJitterTolerance: Double = 2

    static let `default` = HingePeekConfiguration()
}

struct HingePeekStateMachine: Equatable, Sendable {
    private var configuration: HingePeekConfiguration
    private var stableCandidateStartedAt: TimeInterval?
    private(set) var isPeeking = false

    init(configuration: HingePeekConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func update(status: DuoPosture, angleDegrees: Double?, timestamp: TimeInterval) -> Bool {
        guard status == .partiallyOpen, let angleDegrees else {
            reset()
            return false
        }

        let inPeekBand = configuration.peekAngleRange.contains(angleDegrees)
        let toleratedRange = (configuration.peekAngleRange.lowerBound - configuration.edgeJitterTolerance)...(configuration.peekAngleRange.upperBound + configuration.edgeJitterTolerance)
        let inToleratedBand = toleratedRange.contains(angleDegrees)

        guard inPeekBand || inToleratedBand else {
            reset()
            return false
        }

        if stableCandidateStartedAt == nil {
            stableCandidateStartedAt = timestamp
        }

        guard let stableCandidateStartedAt else { return false }
        if inPeekBand, timestamp - stableCandidateStartedAt >= configuration.dwellTime {
            isPeeking = true
        }
        return isPeeking
    }

    mutating func reset() {
        stableCandidateStartedAt = nil
        isPeeking = false
    }
}

enum HingeHintPeekSessionKind: Equatable, Sendable {
    case practice(ApplePreferences.PracticeMode)
    case mockExam
}

enum HingeHintPeekRules {
    static func canPeekHint(
        sessionKind: HingeHintPeekSessionKind,
        hasHint: Bool,
        alreadySelected: Bool,
        reviewSubmitted: Bool
    ) -> Bool {
        guard hasHint else { return false }
        switch sessionKind {
        case .practice(let mode):
            return PracticeHintRules.canRecordHelp(mode: mode, alreadySelected: alreadySelected, reviewSubmitted: reviewSubmitted)
        case .mockExam:
            return false
        }
    }
}

#if os(iOS)
@MainActor
protocol DuoPostureProviding: AnyObject {
    var sample: DuoPostureSample { get }
    var onPostureChanged: ((DuoPostureSample) -> Void)? { get set }
    func attach(to view: UIView)
    func detach()
}

@MainActor
final class UnavailableDuoPostureProvider: DuoPostureProviding {
    private(set) var sample: DuoPostureSample = .unavailable
    var onPostureChanged: ((DuoPostureSample) -> Void)?

    func attach(to view: UIView) {}
    func detach() {}
}

#if !NO_HINGE_API
@available(iOS 27.1, *)
@MainActor
final class UIHingeDuoPostureProvider: DuoPostureProviding {
    private(set) var sample: DuoPostureSample = .unavailable
    var onPostureChanged: ((DuoPostureSample) -> Void)?

    private weak var attachedView: UIView?
    private var interaction: UIHingeInteraction?

    func attach(to view: UIView) {
        guard attachedView !== view else { return }
        detach()
        attachedView = view
        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            guard let hinge = update.hinge else {
                self.updateSample(.unavailable)
                return
            }
            self.updateSample(
                DuoPostureSample(
                    posture: Self.posture(for: hinge.status),
                    angleDegrees: Double(hinge.angle) * 180 / .pi,
                    timestamp: ProcessInfo.processInfo.systemUptime
                )
            )
        }
        view.addInteraction(interaction)
        self.interaction = interaction
    }

    func detach() {
        if let interaction, let attachedView {
            attachedView.removeInteraction(interaction)
        }
        interaction = nil
        attachedView = nil
        updateSample(.unavailable)
    }

    private func updateSample(_ sample: DuoPostureSample) {
        guard self.sample != sample else { return }
        self.sample = sample
        onPostureChanged?(sample)
    }

    private static func posture(for status: UIHinge.Status) -> DuoPosture {
        switch status {
        case .closed:
            return .closed
        case .partiallyOpen:
            return .partiallyOpen
        case .fullyOpen:
            return .unfolded
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
#endif

#if DEBUG
@MainActor
final class SimulatedDuoPostureProvider: DuoPostureProviding {
    private(set) var sample: DuoPostureSample = .unavailable
    var onPostureChanged: ((DuoPostureSample) -> Void)?

    private let sequence: [DuoPostureSample]
    private weak var attachedView: UIView?
    private var playbackTask: Task<Void, Never>?

    init(sequence: [DuoPostureSample]) {
        self.sequence = sequence.sorted { $0.timestamp < $1.timestamp }
    }

    func attach(to view: UIView) {
        guard attachedView !== view else { return }
        attachedView = view
        startPlayback()
    }

    func detach() {
        playbackTask?.cancel()
        playbackTask = nil
        attachedView = nil
    }

    private func startPlayback() {
        playbackTask?.cancel()
        playbackTask = Task { @MainActor in
            var previousTimestamp: TimeInterval = 0
            for sample in sequence {
                let delay = max(0, sample.timestamp - previousTimestamp)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                guard !Task.isCancelled else { return }
                self.sample = sample
                self.onPostureChanged?(sample)
                previousTimestamp = sample.timestamp
            }
        }
    }
}

struct SimulatedDuoPostureSequenceParser {
    static func parse(_ rawValue: String) -> [DuoPostureSample] {
        rawValue.split(separator: ",").compactMap { parseStep(String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    private static func parseStep(_ rawStep: String) -> DuoPostureSample? {
        guard !rawStep.isEmpty else { return nil }
        let timeParts = rawStep.split(separator: "@", maxSplits: 1).map(String.init)
        let statePart = timeParts[0]
        let timestamp = timeParts.count == 2 ? TimeInterval(timeParts[1]) ?? 0 : 0
        let stateParts = statePart.split(separator: ":", maxSplits: 1).map(String.init)
        guard let posture = posture(named: stateParts[0]) else { return nil }
        let angle = stateParts.count == 2 ? Double(stateParts[1]) : nil
        return DuoPostureSample(posture: posture, angleDegrees: angle, timestamp: timestamp)
    }

    private static func posture(named rawValue: String) -> DuoPosture? {
        switch rawValue {
        case "closed":
            return .closed
        case "partiallyOpen", "partial":
            return .partiallyOpen
        case "fullyOpen", "unfolded":
            return .unfolded
        case "unknown":
            return .unknown
        case "unavailable":
            return .unavailable
        default:
            return nil
        }
    }
}
#endif

struct DuoPostureObserverView: UIViewRepresentable {
    let provider: any DuoPostureProviding

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        provider.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        provider.attach(to: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // The provider is owned by SwiftUI state and detaches from PracticeSessionView.onDisappear.
    }
}

@MainActor
enum DuoPostureProviderFactory {
    static func makeProvider(arguments: [String] = ProcessInfo.processInfo.arguments) -> any DuoPostureProviding {
#if DEBUG
        if let rawSequence = AppLaunchArguments.value(after: "-CanadianHamSimulatedHingeSequence", in: arguments) {
            let sequence = SimulatedDuoPostureSequenceParser.parse(rawSequence)
            if !sequence.isEmpty {
                return SimulatedDuoPostureProvider(sequence: sequence)
            }
        }
#endif
#if !NO_HINGE_API
        if #available(iOS 27.1, *) {
            return UIHingeDuoPostureProvider()
        }
#endif
        return UnavailableDuoPostureProvider()
    }
}
#endif
