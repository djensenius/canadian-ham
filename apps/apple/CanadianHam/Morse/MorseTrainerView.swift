import Accessibility
import CanadianHamMorseEngine
#if os(iOS) || os(macOS)
import MediaAccessibility
#endif
import SwiftUI
#if os(iOS)
import UIKit
#endif

private let morsePracticeText = "KMRSU PARIS"

struct MorseVisualPlaybackState: Equatable {
    enum Mode: Equatable { case idle, visualBeacon, visualTape }
    var mode: Mode = .idle
    var beaconActive = false
    var tape = ""
    var safetyNote = ""
}

struct MorseVisualPlaybackView: View {
    let state: MorseVisualPlaybackState

    var body: some View {
        if state.mode != .idle {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if state.mode == .visualBeacon {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Beacon") // l10n: localized
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityIdentifier("morse-visual-beacon")
                        Circle()
                            .fill(state.beaconActive ? DesignTokens.Colors.accent : DesignTokens.Colors.paperInset)
                            .overlay(Circle().strokeBorder(DesignTokens.Colors.border, lineWidth: 2))
                            .frame(width: 112, height: 112)
                    }
                }
                if state.mode == .visualTape {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Tape") // l10n: localized
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(verbatim: state.tape.isEmpty ? "·" : state.tape) // l10n: verbatim
                            .font(DesignTokens.FontScale.body.monospaced().weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Morse tape output")) // l10n: localized
                    .accessibilityValue(Text(state.tape.isEmpty ? "·" : state.tape)) // l10n: verbatim
                    .accessibilityIdentifier("morse-visual-tape")
                }
                if !state.safetyNote.isEmpty {
                    Text(state.safetyNote) // l10n: localized, contains measured numbers
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.paper, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        }
    }
}

struct MorseVisualPlaybackPlan: Equatable {
    let useTape: Bool
    let safety: MorseFlashSafetyResult
    let flashesPerSecond: Int
    let safetyNote: String
}

func morseVisualPlaybackPlan(sequence: TimedMorseSequence, requestedMode: MorseTrainerSettings.OutputMode, reduceFlashing: Bool, colorScheme: ColorScheme) -> MorseVisualPlaybackPlan {
    let signalEvents = morseSignalEvents(sequence: sequence)
    let flashesPerSecond = maxMorseFlashesPerSecond(events: signalEvents)
    let safety = evaluateMorseBeaconFlashSafety(palette: morseBeaconPalette(for: colorScheme), flashesPerSecond: flashesPerSecond)
    let useTape = requestedMode == .visualTape || reduceFlashing || !safety.safe
    let safetyNote: String
    if reduceFlashing {
        safetyNote = String(localized: "Reduced Motion or Dim Flashing Lights is on, so playback uses the non-flashing tape.")
    } else if !safety.safe {
        safetyNote = String(localized: "Beacon safety limits were exceeded, so playback uses the non-flashing tape.")
    } else {
        let flashCount = String.localizedStringWithFormat(String(localized: "%lld flashes/s"), Int64(flashesPerSecond))
        safetyNote = String.localizedStringWithFormat(
            String(localized: "Beacon area %@ square points is below the %@ square-point WCAG flash cap; max %@."),
            formattedMorseArea(morseBeaconAreaCssPixels),
            formattedMorseArea(safety.maxAreaCssPixels),
            flashCount
        )
    }
    return MorseVisualPlaybackPlan(useTape: useTape, safety: safety, flashesPerSecond: flashesPerSecond, safetyNote: safetyNote)
}

func morseBeaconPalette(for colorScheme: ColorScheme) -> MorseFlashBeaconPalette {
    colorScheme == .dark
        ? morseBeaconPalette(accent: morseDarkAccentRGB, background: morseDarkPaperInsetRGB)
        : morseBeaconPalette(accent: morseLightAccentRGB, background: morseLightPaperInsetRGB)
}

func formattedMorseArea(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0)))
}

@MainActor
func scheduleMorseVisualPlayback(sequence: TimedMorseSequence, requestedMode: MorseTrainerSettings.OutputMode, reduceFlashing: Bool, colorScheme: ColorScheme, setState: @escaping (MorseVisualPlaybackState) -> Void) -> [Task<Void, Never>] {
    let plan = morseVisualPlaybackPlan(sequence: sequence, requestedMode: requestedMode, reduceFlashing: reduceFlashing, colorScheme: colorScheme)
    let signalEvents = morseSignalEvents(sequence: sequence)
    var tasks: [Task<Void, Never>] = []
    if plan.useTape {
        setState(MorseVisualPlaybackState(mode: .visualTape, beaconActive: false, tape: "", safetyNote: plan.safetyNote))
        var tape = ""
        for token in morseTapeTokens(sequence: sequence) {
            tasks.append(Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(max(0, Int((token.revealAtSeconds * 1000).rounded()))))
                guard !Task.isCancelled else { return }
                tape += token.token
                setState(MorseVisualPlaybackState(mode: .visualTape, beaconActive: false, tape: tape, safetyNote: plan.safetyNote))
            })
        }
    } else {
        setState(MorseVisualPlaybackState(mode: .visualBeacon, beaconActive: false, tape: "", safetyNote: plan.safetyNote))
        for event in signalEvents {
            tasks.append(Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(max(0, Int((event.atSeconds * 1000).rounded()))))
                guard !Task.isCancelled else { return }
                setState(MorseVisualPlaybackState(mode: .visualBeacon, beaconActive: event.kind == .on, tape: "", safetyNote: plan.safetyNote))
            })
        }
    }
    tasks.append(Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(Int((sequence.totalDurationSeconds * 1000).rounded(.up)) + 60))
        guard !Task.isCancelled else { return }
        setState(MorseVisualPlaybackState(mode: plan.useTape ? .visualTape : .visualBeacon, beaconActive: false, tape: plan.useTape ? morseTapeTokens(sequence: sequence).map(\.token).joined() : "", safetyNote: plan.safetyNote))
    })
    return tasks
}

@MainActor
func cancelMorseVisualPlayback(_ tasks: inout [Task<Void, Never>], state: inout MorseVisualPlaybackState) {
    tasks.forEach { $0.cancel() }
    tasks = []
    state = MorseVisualPlaybackState()
}

struct MorseReduceFlashingFlags: Equatable {
    let environmentReduceMotion: Bool
    let systemReduceMotion: Bool
    let dimFlashingLights: Bool
}

func shouldReduceMorseFlashing(flags: MorseReduceFlashingFlags) -> Bool {
    flags.environmentReduceMotion || flags.systemReduceMotion || flags.dimFlashingLights
}

func shouldStopMorseVisualBeaconForReducedFlashing(state: MorseVisualPlaybackState, flags: MorseReduceFlashingFlags) -> Bool {
    state.mode == .visualBeacon && shouldReduceMorseFlashing(flags: flags)
}

@MainActor
func currentMorseReduceFlashingFlags(environmentReduceMotion: Bool, dimFlashingLightsEnabled: Bool? = nil) -> MorseReduceFlashingFlags {
#if os(iOS)
    MorseReduceFlashingFlags(
        environmentReduceMotion: environmentReduceMotion,
        systemReduceMotion: UIAccessibility.isReduceMotionEnabled,
        dimFlashingLights: dimFlashingLightsEnabled ?? morseDimFlashingLightsEnabled()
    )
#elseif os(macOS)
    MorseReduceFlashingFlags(
        environmentReduceMotion: environmentReduceMotion,
        systemReduceMotion: environmentReduceMotion,
        dimFlashingLights: dimFlashingLightsEnabled ?? morseDimFlashingLightsEnabled()
    )
#else
    MorseReduceFlashingFlags(environmentReduceMotion: environmentReduceMotion, systemReduceMotion: environmentReduceMotion, dimFlashingLights: false)
#endif
}

func morseDimFlashingLightsEnabled() -> Bool {
#if os(iOS) || os(macOS)
    MADimFlashingLightsEnabled()
#else
    false
#endif
}

extension Notification.Name {
    static let morseDimFlashingLightsChanged: Notification.Name = {
#if os(iOS) || os(macOS)
        Notification.Name(kMADimFlashingLightsChangedNotification as String)
#else
        Notification.Name("CanadianHamMorseDimFlashingLightsChangedUnavailable")
#endif
    }()
}

@MainActor
final class MorsePlaybackCoordinator {
    private var stopHandlers: [String: () -> Void] = [:]

    func register(_ ownerID: String, stop: @escaping () -> Void) {
        stopHandlers[ownerID] = stop
    }

    func unregister(_ ownerID: String) {
        stopHandlers[ownerID] = nil
    }

    func claim(_ ownerID: String) {
        for (registeredOwnerID, stop) in stopHandlers where registeredOwnerID != ownerID {
            stop()
        }
    }
}

struct MorseTrainerView: View {
    @Binding var settings: MorseTrainerSettings
    let progressStore: ProgressStoreService
    let onSettingsChanged: (MorseTrainerSettings) -> Void
    let onProgressChanged: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var dimFlashingLightsEnabled = morseDimFlashingLightsEnabled()
    @State private var driver = MorseAudioDriver()
    @State private var hapticDriver = MorseHapticDriver()
    @State private var visualPlaybackState = MorseVisualPlaybackState()
    @State private var visualPlaybackTasks: [Task<Void, Never>] = []
    @State private var isPlaying = false
    @State private var isRevealed = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var stopTask: Task<Void, Never>?
    @State private var playbackCoordinator = MorsePlaybackCoordinator()

    private var normalizedSettings: MorseTrainerSettings {
        var normalized = settings.normalized()
#if DEBUG
        if let rawOutputMode = AppLaunchArguments.value(after: "-CanadianHamMorseOutputMode"),
           let outputMode = MorseTrainerSettings.OutputMode(rawValue: rawOutputMode) {
            normalized.outputMode = outputMode
        }
#endif
        return normalized.normalized()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                        Text("Morse") // l10n: localized
                            .font(DesignTokens.FontScale.headline.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Preview") // l10n: localized
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(DesignTokens.Colors.paperInset, in: Capsule())
                    }
                    Text("Learn and practise Morse code offline with the Koch course, copy practice and the simulated receiving exam below.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        MorseHomeNavigationLink(title: "Learn (course)", message: "Koch lessons available now.", accessibilityIdentifier: "morse-course-open-button") {
                            MorseCourseView(progressStore: progressStore, settings: $settings, onProgressChanged: onProgressChanged, playbackCoordinator: playbackCoordinator)
                        }
                        MorseHomePlaceholder(title: "Copy practice", message: "Listen to full passages and compare your copy below.")
                        MorseHomePlaceholder(title: "Exam", message: "Try a simulated Canadian 5 wpm receiving exam below.")
                    }
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Quick listen") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Preview the current player with a short practice group. The text is revealed only after playback so you can copy by ear first.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    HStack {
                        morseTokenButton("Play") { play() }
                            .disabled(isPlaying)
                            .accessibilityLabel(Text("Play Morse practice output")) // l10n: localized
                            .accessibilityIdentifier("morse-quick-play-button")
                        morseTokenButton("Stop") { stopPlayback(reveal: false, message: String(localized: "Morse playback stopped.")) }
                            .disabled(!isPlaying)
                            .accessibilityLabel(Text("Stop Morse practice output")) // l10n: localized
                            .accessibilityIdentifier("morse-quick-stop-button")
                    }
                    MorseVisualPlaybackView(state: visualPlaybackState)
                    if !statusMessage.isEmpty {
                        Text(statusMessage) // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Practice text") // l10n: localized
                            .font(DesignTokens.FontScale.body.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        if isRevealed {
                            Text(verbatim: morsePracticeText) // l10n: verbatim
                                .font(.title.weight(.bold).monospaced())
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .textSelection(.enabled)
                        } else {
                            Text("Hidden until playback finishes.") // l10n: localized
                                .font(DesignTokens.FontScale.body)
                                .foregroundStyle(DesignTokens.Colors.ink)
                        }
                    }
                }
                .paperCard()

                MorseCopyExamView(settings: normalizedSettings, playbackCoordinator: playbackCoordinator)

                MorseHomeNavigationLink(title: "Sending practice", message: "Practise tap timing with a straight key or iambic paddles.", accessibilityIdentifier: "morse-sending-open-button") {
                    MorseSendingPracticeView(settings: normalizedSettings, playbackCoordinator: playbackCoordinator)
                }


#if os(macOS)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Morse settings") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Use Settings to change Morse tone, timing, and playback volume.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    SettingsLink {
                        Text("Open Morse settings") // l10n: localized
                    }
                }
                .paperCard()
#else
                MorseSettingsSection(settings: $settings, openMorse: {}) { nextSettings in
                    onSettingsChanged(nextSettings)
                }
                .paperCard()
#endif

                if let errorMessage {
                    MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .morseTrainerOpaqueNavigationBar()
        .navigationTitle("Morse")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            playbackCoordinator.register("quick-listen") {
                stopPlayback(reveal: false, message: String(localized: "Morse playback stopped."))
            }
        }
        .onChange(of: reduceMotion) { _, _ in
            stopBeaconPlaybackIfReducedFlashingIsEnabled()
        }
        .onReceive(NotificationCenter.default.publisher(for: .morseDimFlashingLightsChanged)) { _ in
            dimFlashingLightsEnabled = morseDimFlashingLightsEnabled()
            stopBeaconPlaybackIfReducedFlashingIsEnabled()
        }
        .onDisappear {
            playbackCoordinator.unregister("quick-listen")
            stopPlayback(reveal: false, message: "")
        }
    }

    private func play() {
        do {
            playbackCoordinator.claim("quick-listen")
            isRevealed = false
            let duration = try startConfiguredOutput(text: morsePracticeText)
            isPlaying = true
            statusMessage = String(localized: "Morse playback started.")
            errorMessage = nil
            stopTask?.cancel()
            stopTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((duration * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                stopPlayback(reveal: true, message: String(localized: "Morse playback finished."))
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func stopBeaconPlaybackIfReducedFlashingIsEnabled() {
        let flags = currentMorseReduceFlashingFlags(environmentReduceMotion: reduceMotion, dimFlashingLightsEnabled: dimFlashingLightsEnabled)
        if shouldStopMorseVisualBeaconForReducedFlashing(state: visualPlaybackState, flags: flags) {
            stopPlayback(reveal: false, message: String(localized: "Morse playback stopped."))
        }
    }

    private func stopPlayback(reveal: Bool, message: String) {
        stopTask?.cancel()
        stopTask = nil
        driver.stop()
        hapticDriver.stop()
        visualPlaybackTasks.forEach { $0.cancel() }
        visualPlaybackTasks = []
        if reveal {
            visualPlaybackState.beaconActive = false
        } else {
            visualPlaybackState = MorseVisualPlaybackState()
        }
        isPlaying = false
        if reveal { isRevealed = true }
        statusMessage = message
        if !message.isEmpty {
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func startConfiguredOutput(text: String) throws -> TimeInterval {
        driver.stop()
        hapticDriver.stop()
        cancelMorseVisualPlayback(&visualPlaybackTasks, state: &visualPlaybackState)
        let sequence = try textToTimedMorse(text, profile: normalizedSettings.timingProfileValue())
        switch normalizedSettings.outputMode {
        case .audio:
            return try driver.play(text: text, settings: normalizedSettings)
        case .haptics:
            return try hapticDriver.play(sequence: sequence)
        case .visualBeacon, .visualTape:
            visualPlaybackTasks = scheduleMorseVisualPlayback(
                sequence: sequence,
                requestedMode: normalizedSettings.outputMode,
                reduceFlashing: shouldReduceMorseFlashing(flags: currentMorseReduceFlashingFlags(environmentReduceMotion: reduceMotion, dimFlashingLightsEnabled: dimFlashingLightsEnabled)),
                colorScheme: colorScheme
            ) { nextState in
                visualPlaybackState = nextState
            }
            return sequence.totalDurationSeconds
        }
    }
}

private extension View {
    @ViewBuilder
    func morseTrainerOpaqueNavigationBar() -> some View {
#if os(iOS)
        toolbarBackground(DesignTokens.Colors.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
#else
        self
#endif
    }
}

private struct MorseHomePlaceholder: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        MorseHomeCardContent(title: title, message: message)
    }
}

private struct MorseHomeNavigationLink<Destination: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let accessibilityIdentifier: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            MorseHomeCardContent(title: title, message: message)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct MorseHomeCardContent: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(message) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paper, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }
}

private func formattedWpm(_ wpm: Double) -> String {
    if wpm.rounded() == wpm {
        return String.localizedStringWithFormat(String(localized: "%lld wpm"), Int64(wpm))
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 1
    let value = formatter.string(from: NSNumber(value: wpm)) ?? String(format: "%.1f", wpm)
    return String.localizedStringWithFormat(String(localized: "%@ wpm"), value)
}

@MainActor
func morseTokenButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        AccessibleSecondaryButtonLabel(title: title)
    }
    .buttonStyle(AccessibleSecondaryButtonStyle())
}

struct MorseSettingsSection: View {
    @Binding var settings: MorseTrainerSettings
    let openMorse: () -> Void
    let onChange: (MorseTrainerSettings) -> Void

    private var displayedCharacterWpm: Double {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return Double(normalized.characterWpm) }
        return profile.characterWpm
    }

    private var displayedEffectiveWpm: Double {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return Double(normalized.effectiveWpm) }
        return profile.effectiveWpm
    }

    private var fixedTimingDescription: String? {
        let normalized = settings.normalized()
        guard normalized.timingProfile != .general,
              let profile = try? normalized.timingProfileValue() else { return nil }
        return String.localizedStringWithFormat(
            String(localized: "This exam timing profile fixes speed controls at %@ character speed and %@ effective speed. Choose General Farnsworth to edit speed settings."),
            formattedWpm(profile.characterWpm),
            formattedWpm(profile.effectiveWpm)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Morse settings") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("These local settings control Morse tone, timing, and playback volume without network access.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Stepper(value: binding(\.toneHz), in: 400...900, step: 10) {
                HStack {
                    Text("Tone") // l10n: localized
                    Text(verbatim: "\(settings.normalized().toneHz) Hz") // l10n: verbatim
                }
            }
            Stepper(value: binding(\.characterWpm), in: 12...25, step: 1) {
                HStack {
                    Text("Character speed") // l10n: localized
                    Text(formattedWpm(displayedCharacterWpm)) // l10n: localized
                }
            }
            .disabled(settings.normalized().timingProfile != .general)
            Stepper(value: binding(\.effectiveWpm), in: 5...settings.normalized().characterWpm, step: 1) {
                HStack {
                    Text("Effective speed") // l10n: localized
                    Text(formattedWpm(displayedEffectiveWpm)) // l10n: localized
                }
            }
            .disabled(settings.normalized().timingProfile != .general)
            Picker("Timing profile", selection: binding(\.timingProfile)) { // l10n: localized
                ForEach(MorseTrainerSettings.TimingProfile.allCases) { profile in
                    Text(profile.localizedLabel).tag(profile) // l10n: localized
                }
            }
            if let fixedTimingDescription {
                Text(fixedTimingDescription) // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .padding(DesignTokens.Spacing.sm)
            }
            Slider(value: binding(\.volume), in: 0...1, step: 0.05) {
                Text("Trainer volume") // l10n: localized
            }
            Picker("Output mode", selection: binding(\.outputMode)) { // l10n: localized
                ForEach(MorseTrainerSettings.OutputMode.availableCases) { mode in
                    Text(mode.localizedLabel).tag(mode) // l10n: localized
                }
            }
            .accessibilityIdentifier("morse-output-mode-picker")
            morseTokenButton("ISED exam preset") {
                update(settings.applyingISEDExamPreset())
            }
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<MorseTrainerSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settings.normalized()[keyPath: keyPath] },
            set: { value in
                var next = settings
                next[keyPath: keyPath] = value
                update(next)
            }
        )
    }

    private func update(_ next: MorseTrainerSettings) {
        let normalized = next.normalized()
        if normalized == settings.normalized() {
            return
        }
        settings = normalized
        normalized.save()
        onChange(normalized)
    }
}
