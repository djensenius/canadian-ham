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
    /// Keep an already-visible peek alive through small sensor jitter around
    /// the band edges. Pre-peek dwell still starts only in the real band.
    var edgeJitterTolerance: Double = 2
    /// Restart dwell if the hinge keeps moving instead of holding near the
    /// angle where the candidate began. This is deliberately separate from
    /// edge jitter because jitter tolerance is only for an active peek.
    var stableAngleTolerance: Double = 3

    static let `default` = HingePeekConfiguration()
}

struct HingePeekUpdateResult: Equatable, Sendable {
    var isPeeking: Bool
    var startedPeeking: Bool
    var endedByPostureReset: Bool
    var pendingDwellDeadline: TimeInterval?
}

struct HingePeekStateMachine: Equatable, Sendable {
    private var configuration: HingePeekConfiguration
    private var stableCandidateStartedAt: TimeInterval?
    private var stableCandidateStartedAngle: Double?
    private var lastSample: DuoPostureSample?
    private(set) var isPeeking = false

    init(configuration: HingePeekConfiguration = .default) {
        self.configuration = configuration
    }

    mutating func update(status: DuoPosture, angleDegrees: Double?, timestamp: TimeInterval) -> HingePeekUpdateResult {
        let sample = DuoPostureSample(posture: status, angleDegrees: angleDegrees, timestamp: timestamp)
        return update(sample: sample)
    }

    mutating func update(sample: DuoPostureSample) -> HingePeekUpdateResult {
        lastSample = sample
        guard sample.posture == .partiallyOpen, let angleDegrees = sample.angleDegrees else {
            let endedByPostureReset = sample.posture == .closed || sample.posture == .unfolded
            reset()
            return result(startedPeeking: false, endedByPostureReset: endedByPostureReset)
        }

        let wasPeeking = isPeeking
        if isPeeking {
            let toleratedRange = (configuration.peekAngleRange.lowerBound - configuration.edgeJitterTolerance)...(configuration.peekAngleRange.upperBound + configuration.edgeJitterTolerance)
            guard toleratedRange.contains(angleDegrees) else {
                clearCandidate()
                isPeeking = false
                return result(startedPeeking: false)
            }
            return result(startedPeeking: !wasPeeking && isPeeking)
        }

        guard configuration.peekAngleRange.contains(angleDegrees) else {
            clearCandidate()
            return result(startedPeeking: false)
        }

        if let startAngle = stableCandidateStartedAngle,
           abs(angleDegrees - startAngle) > configuration.stableAngleTolerance {
            stableCandidateStartedAt = sample.timestamp
            stableCandidateStartedAngle = angleDegrees
        } else if stableCandidateStartedAt == nil {
            stableCandidateStartedAt = sample.timestamp
            stableCandidateStartedAngle = angleDegrees
        }

        guard let stableCandidateStartedAt else { return result(startedPeeking: false) }
        if sample.timestamp - stableCandidateStartedAt + 0.000_001 >= configuration.dwellTime {
            isPeeking = true
            return result(startedPeeking: true)
        }
        return result(startedPeeking: false, pendingDwellDeadline: stableCandidateStartedAt + configuration.dwellTime)
    }

    mutating func recheck(timestamp: TimeInterval) -> HingePeekUpdateResult {
        guard let lastSample else { return result(startedPeeking: false) }
        return update(
            sample: DuoPostureSample(
                posture: lastSample.posture,
                angleDegrees: lastSample.angleDegrees,
                timestamp: timestamp
            )
        )
    }

    mutating func reset() {
        clearCandidate()
        lastSample = nil
        isPeeking = false
    }

    private mutating func clearCandidate() {
        stableCandidateStartedAt = nil
        stableCandidateStartedAngle = nil
    }

    private func result(startedPeeking: Bool, endedByPostureReset: Bool = false, pendingDwellDeadline: TimeInterval? = nil) -> HingePeekUpdateResult {
        HingePeekUpdateResult(isPeeking: isPeeking, startedPeeking: startedPeeking, endedByPostureReset: endedByPostureReset, pendingDwellDeadline: pendingDwellDeadline)
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

struct HingeHintPeekPresentationState: Equatable {
    var posturePeekActive = false
    var openedToolByPeek = false
    var suppressedUntilPostureReset = false
    var activeQuestionID: String?
}

struct HingeHintPeekPresentationContext: Equatable {
    var questionID: String?
    var canPeek: Bool
    var selectedTool: ExamTool?
}

enum HingeHintPeekPresentationAction: Equatable {
    case postureStarted
    case postureEnded
    case selectedToolChanged(ExamTool?)
    case questionChanged
    case eligibilityChanged
}

enum HingeHintPeekPresentationEffect: Equatable {
    case presentHint(questionID: String)
    case closeHint
}

enum HingeHintPeekPresentationReducer {
    /// Drives the view effects for an already-qualified hinge dwell. It is
    /// intentionally start-transition based: once the user dismisses or changes
    /// tools, the same held posture cannot reopen Hint until the posture state
    /// machine resets at closed or fully-open.
    static func reduce(
        state: inout HingeHintPeekPresentationState,
        action: HingeHintPeekPresentationAction,
        context: HingeHintPeekPresentationContext
    ) -> [HingeHintPeekPresentationEffect] {
        switch action {
        case .postureStarted:
            guard !state.posturePeekActive else { return [] }
            state.posturePeekActive = true
            guard !state.suppressedUntilPostureReset,
                  context.canPeek,
                  let questionID = context.questionID
            else { return [] }
            state.activeQuestionID = questionID
            state.openedToolByPeek = context.selectedTool != .hint
            return [.presentHint(questionID: questionID)]

        case .postureEnded:
            // A peek-opened panel is transient and closes when the phone fully
            // opens or closes. A Hint panel the learner opened with the button
            // remains open, and we intentionally do not restore a calculator or
            // other tool that the peek replaced.
            let shouldClose = state.openedToolByPeek && context.selectedTool == .hint
            state = HingeHintPeekPresentationState()
            return shouldClose ? [.closeHint] : []

        case .selectedToolChanged(let selectedTool):
            guard state.posturePeekActive, state.openedToolByPeek, selectedTool != .hint else { return [] }
            state.openedToolByPeek = false
            state.suppressedUntilPostureReset = true
            return []

        case .questionChanged:
            let shouldClose = state.openedToolByPeek && context.selectedTool == .hint
            state = HingeHintPeekPresentationState()
            return shouldClose ? [.closeHint] : []

        case .eligibilityChanged:
            guard state.posturePeekActive, !context.canPeek else { return [] }
            let shouldClose = state.openedToolByPeek && context.selectedTool == .hint
            state.openedToolByPeek = false
            state.suppressedUntilPostureReset = true
            return shouldClose ? [.closeHint] : []
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
    var onPostureChanged: ((DuoPostureSample) -> Void)? {
        didSet {
            if onPostureChanged == nil {
                playbackTask?.cancel()
                playbackTask = nil
            } else if attachedView != nil {
                startPlayback()
            }
        }
    }

    private let sequence: [DuoPostureSample]
    private weak var attachedView: UIView?
    private var playbackTask: Task<Void, Never>?

    init(sequence: [DuoPostureSample]) {
        self.sequence = sequence.sorted { $0.timestamp < $1.timestamp }
    }

    func attach(to view: UIView) {
        guard attachedView !== view else { return }
        attachedView = view
        if onPostureChanged != nil {
            startPlayback()
        }
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

    final class Coordinator {
        var provider: (any DuoPostureProviding)?

        init(provider: any DuoPostureProviding) {
            self.provider = provider
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(provider: provider)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.provider = provider
        provider.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let existing = context.coordinator.provider, existing !== provider {
            existing.detach()
        }
        context.coordinator.provider = provider
        provider.attach(to: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.provider?.detach()
        coordinator.provider = nil
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
