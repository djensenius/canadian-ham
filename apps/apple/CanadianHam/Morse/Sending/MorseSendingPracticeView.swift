import Accessibility
import CanadianHamMorseEngine
import SwiftUI

struct MorseSendingPracticeView: View {
    let settings: MorseTrainerSettings
    let playbackCoordinator: MorsePlaybackCoordinator

    private enum KeyboardFocus: Hashable { case practice, exam }

    @Environment(\.scenePhase) private var scenePhase
    @State private var keyboardFocus: KeyboardFocus?
    @State private var keyboardFocusRequest = UUID()
#if DEBUG
    @State private var keyboardEventDescription = "none"
    @State private var keyboardTimingDescription = "none"
#endif
    @State private var driver = MorseAudioDriver()
    @State private var pendingSamples: [MorseKeyTimingSample] = []
    @State private var decodedText = ""
    @State private var lastFeedback: MorseCharacterTimingFeedback?
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var straightKeyDownAt: Date?
    @State private var finalizeTask: Task<Void, Never>?
    @State private var pressedPaddles: Set<MorseKeyElement> = []
    @State private var paddleRepeatTask: Task<Void, Never>?
    @State private var paddleRepeatToken = UUID()
    @State private var nextIambicElement: MorseKeyElement = .dot
    @State private var lastPaddleElement: MorseKeyElement?
    @State private var examText = ""
    @State private var examRemaining = 180
    @State private var examDeadline: Date?
    @State private var examRunning = false
    @State private var examTimerTask: Task<Void, Never>?
    @State private var finiteToneStopTask: Task<Void, Never>?
    @State private var finiteToneGeneration = 0
    @State private var showingExam = false
    @State private var presentedResult: MorseSendingResult?

    private var profile: MorseTimingProfile { (try? settings.normalized().timingProfileValue()) ?? profileForName(.isedParis) }

    private var resultIsPresented: Binding<Bool> {
        Binding(
            get: { presentedResult != nil },
            set: { isPresented in
                if !isPresented { presentedResult = nil }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Sending practice") // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Practise tap timing with a straight key or iambic-style paddles. With a hardware keyboard, focus this screen first, then hold Space for the straight key; use J for dots and K for dashes. Otherwise, use the large touch targets. Aim for steady dot/dash ratio and timing consistency.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    morseTokenButton("Exam-style check") { openExamStyleCheck() }
                        .accessibilityIdentifier("morse-sending-exam-open-button")
                    sendingControls
                    }
                    .paperCard()
                }
                .pagePadding()
            }
        }
        .background(DesignTokens.Colors.paper)
        .contentShape(Rectangle())
        .navigationTitle("Sending practice") // l10n: localized
        .modifier(MorseSendingKeyboardFocus(
            isActive: !showingExam && presentedResult == nil,
            request: keyboardFocusRequest,
            focusChanged: { updateKeyboardFocus(.practice, isFocused: $0) },
            keyPress: handleKeyPress
        ))
        .onAppear {
            // Another Morse mode starting playback stops any held key or paddle here.
            playbackCoordinator.register("sending-practice") {
                stopAllKeying(finalizeStraight: true)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshExamCountdown()
            } else {
                stopAllKeying(finalizeStraight: true)
            }
        }
        .onChange(of: keyboardFocus) { previous, _ in
            // Release held keys even when focus moves directly between the two screens.
            if previous != nil { stopAllKeying(finalizeStraight: true) }
        }
        .navigationDestination(isPresented: $showingExam) {
            sendingExamScreen
        }
        .onChange(of: showingExam) { _, isPresented in
            if !isPresented, presentedResult == nil, !examText.isEmpty {
                cancelRunningExam(clearExam: true)
            }
        }
        .navigationDestination(isPresented: resultIsPresented) {
            if let presentedResult {
                MorseSendingResultsScreen(result: presentedResult) {
                    resetSending(clearExam: true)
                    self.presentedResult = nil
                }
            }
        }
        .onDisappear {
            playbackCoordinator.unregister("sending-practice")
            stopAllKeying(finalizeStraight: false)
            clearPendingCharacterFinalization(clearPendingSamples: true)
            examTimerTask?.cancel()
        }
    }

    private var sendingControls: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Straight key") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    MorsePressKeyButton(
                        title: String(localized: "Hold key"),
                        accessibilityLabel: String(localized: "Straight key. Hold to send tone, release to classify dot or dash."),
                        accessibilityIdentifier: "morse-sending-straight-key-button",
                        begin: beginStraightKey,
                        end: endStraightKey,
                        sendDotAction: { sendTimedElement(.dot) },
                        sendDashAction: { sendTimedElement(.dash) }
                    )
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Iambic paddle emulation") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    HStack(spacing: DesignTokens.Spacing.md) {
                        MorsePressKeyButton(
                            title: String(localized: "Dot"),
                            accessibilityLabel: String(localized: "Dot paddle. Hold for repeated dots."),
                            accessibilityIdentifier: "morse-sending-dot-paddle-button",
                            begin: { beginPaddle(.dot) },
                            end: { endPaddle(.dot) },
                            defaultAction: { sendTimedElement(.dot) }
                        )
                        MorsePressKeyButton(
                            title: String(localized: "Dash"),
                            accessibilityLabel: String(localized: "Dash paddle. Hold for repeated dashes."),
                            accessibilityIdentifier: "morse-sending-dash-paddle-button",
                            begin: { beginPaddle(.dash) },
                            end: { endPaddle(.dash) },
                            defaultAction: { sendTimedElement(.dash) }
                        )
                    }
                }
                MorseSendingFeedbackView(decodedText: decodedText, pendingSamples: pendingSamples, lastFeedback: lastFeedback)
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseKeyboardStatus") {
                    Text(verbatim: "Focus: \(String(describing: keyboardFocus)); event: \(keyboardEventDescription); held: \(straightKeyDownAt != nil); timing: \(keyboardTimingDescription)") // l10n: verbatim DEBUG-only keyboard test diagnostics
                        .accessibilityIdentifier("morse-sending-keyboard-test-status")
                }
#endif
                HStack {
                    morseTokenButton("Clear sending practice") { resetSending(clearExam: false) }
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseSendingDebugHook") {
                        Button(action: fillExamTextForUITest) {
                            Text(verbatim: "Fill sending check") // l10n: verbatim DEBUG-only UI test hook
                                .font(DesignTokens.FontScale.body.weight(.bold))
                        }
                        .accessibilityIdentifier("morse-sending-debug-fill-button")
                        Button(action: gradeHeldStraightKeyForUITest) {
                            Text(verbatim: "Grade held straight key for sending test") // l10n: verbatim DEBUG-only UI test hook
                                .font(DesignTokens.FontScale.body.weight(.bold))
                        }
                        .accessibilityIdentifier("morse-sending-debug-grade-held-straight-button")
                        Button(action: openExamWithPendingCharacterForUITest) {
                            Text(verbatim: "Open exam with pending sending test") // l10n: verbatim DEBUG-only UI test hook
                                .font(DesignTokens.FontScale.body.weight(.bold))
                        }
                        .accessibilityIdentifier("morse-sending-debug-open-exam-pending-button")
                    }
#endif
                }
                if !statusMessage.isEmpty {
                    Text(statusMessage) // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
                if let errorMessage {
                    MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
                }
        }
    }

    private var sendingExamScreen: some View {
        // Keep Space on the keying focus target, not the ScrollView's paging handler.
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Exam-style check") // l10n: localized
                            .font(DesignTokens.FontScale.title.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Send the displayed passage, then end and grade when ready. Unsent characters at 0:00 count as errors.") // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        MorseSendingExamCard(
                            examText: examText,
                            examRemaining: examRemaining,
                            start: startExam,
                            grade: { gradeExam(completedWithinTime: examCompletedWithinDeadline()) }
                        )
                        sendingControls
                    }
                    .paperCard()
                }
                .pagePadding()
            }
        }
        .background(DesignTokens.Colors.paper)
        .contentShape(Rectangle())
        .navigationTitle("Exam-style check") // l10n: localized
        .modifier(MorseSendingKeyboardFocus(
            isActive: showingExam && presentedResult == nil,
            request: keyboardFocusRequest,
            focusChanged: { updateKeyboardFocus(.exam, isFocused: $0) },
            keyPress: handleKeyPress
        ))
        .onDisappear {
            if presentedResult == nil, !examText.isEmpty {
                cancelRunningExam(clearExam: true)
            }
        }
    }

    private func updateKeyboardFocus(_ target: KeyboardFocus, isFocused: Bool) {
        if isFocused {
            keyboardFocus = target
        } else if keyboardFocus == target {
            keyboardFocus = nil
        }
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
#if DEBUG
        keyboardEventDescription = "\(String(describing: press.phase)) \(press.characters)"
#endif
        let character = press.characters.lowercased()
        let element = character == "j" ? MorseKeyElement.dot : character == "k" ? MorseKeyElement.dash : nil
        switch press.phase {
        case .down:
            if press.key == .space {
                beginStraightKey()
                return .handled
            }
            if let element {
                beginPaddle(element)
                return .handled
            }
        case .up:
            if press.key == .space {
                endStraightKey()
                return .handled
            }
            if let element {
                endPaddle(element)
                return .handled
            }
        default:
            break
        }
        return .ignored
    }

    private func beginStraightKey() {
        guard straightKeyDownAt == nil else { return }
        cancelFiniteToneStop()
        finalizeTask?.cancel()
        finalizeTask = nil
        playbackCoordinator.claim("sending-practice")
        straightKeyDownAt = Date()
        do {
            try driver.startTone(settings: settings.normalized())
#if DEBUG
            keyboardTimingDescription = "audio startup: \(Date().timeIntervalSince(straightKeyDownAt ?? Date()))"
#endif
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            straightKeyDownAt = nil
        }
    }

    private func endStraightKey() {
        guard let started = straightKeyDownAt else { return }
        let duration = max(0.001, Date().timeIntervalSince(started))
#if DEBUG
        keyboardTimingDescription += "; hold: \(duration); dot limit: \(2 * profile.dotSeconds)"
#endif
        straightKeyDownAt = nil
        driver.stop()
        do {
            appendSample(try classifyMorseKeyDown(durationSeconds: duration, profile: profile))
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func beginPaddle(_ element: MorseKeyElement) {
        finalizeTask?.cancel()
        finalizeTask = nil
        pressedPaddles.insert(element)
        playbackCoordinator.claim("sending-practice")
        if paddleRepeatTask == nil {
            startPaddleRepeat(preferredElement: element)
        }
    }

    private func endPaddle(_ element: MorseKeyElement) {
        pressedPaddles.remove(element)
        if pressedPaddles.isEmpty {
            paddleRepeatTask?.cancel()
            paddleRepeatTask = nil
        }
    }

    private func startPaddleRepeat(preferredElement: MorseKeyElement? = nil) {
        paddleRepeatTask?.cancel()
        let token = UUID()
        paddleRepeatToken = token
        paddleRepeatTask = Task { @MainActor in
            var preferred = preferredElement
            while !Task.isCancelled, !pressedPaddles.isEmpty {
                let element = nextPaddleElement(preferred: preferred)
                preferred = nil
                emitPaddleElement(element)
                let duration = element == .dot ? profile.dotSeconds : profile.dashSeconds
                let delay = max(40_000_000, UInt64(((duration + profile.intraCharacterGapSeconds) * 1_000_000_000).rounded()))
                try? await Task.sleep(nanoseconds: delay)
            }
            if paddleRepeatToken == token {
                paddleRepeatTask = nil
            }
        }
    }

    private func nextPaddleElement(preferred: MorseKeyElement?) -> MorseKeyElement {
        if pressedPaddles.contains(.dot), pressedPaddles.contains(.dash) {
            let element = lastPaddleElement.map(oppositeElement) ?? nextIambicElement
            nextIambicElement = oppositeElement(element)
            return element
        }
        let element = preferred ?? (pressedPaddles.contains(.dot) ? .dot : .dash)
        nextIambicElement = oppositeElement(element)
        return element
    }

    private func emitPaddleElement(_ element: MorseKeyElement) {
        sendTimedElement(element)
        lastPaddleElement = element
    }

    private func sendTimedElement(_ element: MorseKeyElement) {
        // VoiceOver actions reach here without a press, so claim the shared player here too.
        playbackCoordinator.claim("sending-practice")
        finalizeTask?.cancel()
        finalizeTask = nil
        let text = element == .dot ? "E" : "T"
        let duration = element == .dot ? profile.dotSeconds : profile.dashSeconds
        if let playbackDuration = try? driver.play(text: text, settings: settings.normalized()) {
            scheduleFiniteToneStop(after: playbackDuration)
        }
        appendSample(MorseKeyTimingSample(element: element, durationSeconds: duration, expectedSeconds: duration, ratioToExpected: 1), finalizeAfterElementSeconds: duration)
    }

    private func appendSample(_ sample: MorseKeyTimingSample, finalizeAfterElementSeconds: Double = 0) {
        pendingSamples.append(sample)
        scheduleFinalizeCharacter(finalizeAfterElementSeconds: finalizeAfterElementSeconds)
    }

    private func scheduleFinalizeCharacter(finalizeAfterElementSeconds: Double = 0) {
        finalizeTask?.cancel()
        let delay = UInt64(((finalizeAfterElementSeconds + profile.interCharacterGapSeconds) * 1_000_000_000).rounded(.up)) + 20_000_000
        finalizeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            finalizeCharacter()
        }
    }

    private func finalizeCharacter() {
        finalizeTask?.cancel()
        finalizeTask = nil
        guard !pendingSamples.isEmpty else { return }
        let feedback = morseCharacterTimingFeedback(samples: pendingSamples)
        pendingSamples = []
        lastFeedback = feedback
        decodedText = applyMorseDecodedCharacter(text: decodedText, decoded: feedback.decoded)
        switch feedback.decoded.kind {
        case .errorSignal:
            statusMessage = String(localized: "Error signal received: previous character deleted.")
        case .character:
            statusMessage = String.localizedStringWithFormat(String(localized: "Decoded %@."), feedback.decoded.character ?? "")
        case .unknown:
            statusMessage = String.localizedStringWithFormat(String(localized: "No character matches %@."), feedback.elements)
        }
        AccessibilityNotification.Announcement(statusMessage).post()
    }

    private func scheduleFiniteToneStop(after duration: TimeInterval) {
        finiteToneGeneration += 1
        let generation = finiteToneGeneration
        finiteToneStopTask?.cancel()
        finiteToneStopTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int((duration * 1000).rounded(.up)) + 60))
            guard !Task.isCancelled, generation == finiteToneGeneration else { return }
            driver.stop()
            finiteToneStopTask = nil
        }
    }

    private func cancelFiniteToneStop() {
        finiteToneGeneration += 1
        finiteToneStopTask?.cancel()
        finiteToneStopTask = nil
    }

    private func refreshExamCountdown(now: Date = Date()) {
        guard examRunning, let examDeadline else { return }
        let remaining = morseSendingRemainingExamSeconds(deadline: examDeadline, now: now)
        examRemaining = remaining
        if remaining == 0 {
            gradeExam(completedWithinTime: false)
        }
    }

    private func examCompletedWithinDeadline(now: Date = Date()) -> Bool {
        guard let examDeadline else { return examRemaining > 0 }
        return now < examDeadline
    }

    private func openExamStyleCheck() {
        resetSending(clearExam: true)
        showingExam = true
    }

    private func startExam() {
        resetSending(clearExam: false)
        do {
            let generated = try generateMorseExamText(seed: "apple-sending-\(Date().timeIntervalSince1970)", profile: profileForName(.isedParis), minDurationSeconds: 0)
            examText = debugExamTextOverride ?? generated.text
            examRemaining = debugExamDurationSeconds
            examDeadline = Date().addingTimeInterval(TimeInterval(debugExamDurationSeconds))
            examRunning = true
            statusMessage = String(localized: "Sending check started. Send the displayed passage within 3:00.")
            keyboardFocusRequest = UUID()
            examTimerTask?.cancel()
            examTimerTask = Task { @MainActor in
                while !Task.isCancelled, examRunning {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    refreshExamCountdown()
                }
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func gradeExam(completedWithinTime: Bool) {
        guard !examText.isEmpty else { return }
        stopAllKeying(finalizeStraight: true)
        finalizeCharacter()
        cancelRunningExam(clearExam: false)
        do {
            let score = try scoreMorseSending(expected: examText, sent: decodedText, completedWithinTime: completedWithinTime)
            presentedResult = MorseSendingResult(score: score, decodedText: decodedText)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func resetSending(clearExam: Bool) {
        stopAllKeying(finalizeStraight: false)
        clearPendingCharacterFinalization(clearPendingSamples: true)
        decodedText = ""
        lastFeedback = nil
        statusMessage = ""
        errorMessage = nil
        if clearExam {
            cancelRunningExam(clearExam: true)
        }
    }

    private func cancelRunningExam(clearExam: Bool) {
        examTimerTask?.cancel()
        if clearExam {
            examText = ""
        }
        examRemaining = debugExamDurationSeconds
        examDeadline = nil
        examRunning = false
    }

    private func stopAllKeying(finalizeStraight: Bool) {
        if finalizeStraight, let started = straightKeyDownAt {
            let duration = max(0.001, Date().timeIntervalSince(started))
            if let sample = try? classifyMorseKeyDown(durationSeconds: duration, profile: profile) {
                appendSample(sample)
            }
        }
        cancelFiniteToneStop()
        driver.stop()
        straightKeyDownAt = nil
        pressedPaddles = []
        paddleRepeatTask?.cancel()
        paddleRepeatToken = UUID()
        paddleRepeatTask = nil
    }

    private func clearPendingCharacterFinalization(clearPendingSamples: Bool) {
        clearMorseSendingPendingCharacterFinalization(finalizeTask: &finalizeTask, pendingSamples: &pendingSamples, clearPendingSamples: clearPendingSamples)
    }

#if DEBUG
    private func fillExamTextForUITest() {
        decodedText = (try? canonicalMorseCharacters(examText).joined()) ?? examText.replacingOccurrences(of: " ", with: "")
        statusMessage = "Decoded exam text filled for UI testing."
    }

    private func gradeHeldStraightKeyForUITest() {
        pendingSamples = []
        decodedText = ""
        straightKeyDownAt = Date().addingTimeInterval(-profile.dotSeconds)
        playbackCoordinator.claim("sending-practice")
        gradeExam(completedWithinTime: true)
    }

    private func openExamWithPendingCharacterForUITest() {
        openExamStyleCheck()
        decodedText = ""
        lastFeedback = nil
        statusMessage = ""
        pendingSamples = [MorseKeyTimingSample(element: .dot, durationSeconds: profile.dotSeconds, expectedSeconds: profile.dotSeconds, ratioToExpected: 1)]
        scheduleFinalizeCharacter(finalizeAfterElementSeconds: profile.dotSeconds)
    }
#else
    private func fillExamTextForUITest() {}
    private func gradeHeldStraightKeyForUITest() {}
#endif
}

// Each navigation host owns its focus binding. A binding owned by the practice host
// cannot reliably focus the pushed exam's key capture surface.
private struct MorseSendingKeyboardFocus: ViewModifier {
    let isActive: Bool
    let request: UUID
    let focusChanged: (Bool) -> Void
    let keyPress: (KeyPress) -> KeyPress.Result

    @FocusState private var hasKeyboardFocus: Bool

    func body(content: Content) -> some View {
        content
            .focusable(isActive, interactions: .edit)
            .focused($hasKeyboardFocus)
            .defaultFocus($hasKeyboardFocus, true, priority: .userInitiated)
            .task(id: request) {
                // Wait for the pushed host to finish its initial navigation layout.
                await Task.yield()
                guard !Task.isCancelled, isActive else { return }
                hasKeyboardFocus = true
            }
            .onChange(of: isActive) { _, active in
                hasKeyboardFocus = active
            }
            .onChange(of: hasKeyboardFocus) { _, focused in
                focusChanged(focused)
            }
            .onKeyPress(phases: [.down, .up]) { press in
                guard isActive else { return .ignored }
                return keyPress(press)
            }
    }
}

func clearMorseSendingPendingCharacterFinalization(finalizeTask: inout Task<Void, Never>?, pendingSamples: inout [MorseKeyTimingSample], clearPendingSamples: Bool) {
    finalizeTask?.cancel()
    finalizeTask = nil
    if clearPendingSamples {
        pendingSamples = []
    }
}

private struct MorseSendingExamCard: View {
    let examText: String
    let examRemaining: Int
    let start: () -> Void
    let grade: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("3-minute sending check") // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            if examText.isEmpty {
                Text("Start a check to show the plain-language passage.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            } else {
                Text(verbatim: examText) // l10n: verbatim
                    .font(.title3.monospaced().weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("morse-sending-exam-text")
            }
            Text(String.localizedStringWithFormat(String(localized: "Time remaining: %@"), sendingTimerLabel(examRemaining))) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("morse-sending-timer")
            HStack {
                morseTokenButton("Start sending check") { start() }
                    .accessibilityIdentifier("morse-sending-start-exam-button")
                morseTokenButton("End and grade") { grade() }
                    .disabled(examText.isEmpty)
                    .accessibilityIdentifier("morse-sending-grade-exam-button")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paper, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }
}

struct MorsePressKeyButton: View {
    let title: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let begin: () -> Void
    let end: () -> Void
    var defaultAction: (() -> Void)? = nil
    var sendDotAction: (() -> Void)? = nil
    var sendDashAction: (() -> Void)? = nil

    @GestureState private var gestureIsPressing = false
    @State private var isPressed = false

    var body: some View {
        let label = Text(title) // l10n: localized
            .font(DesignTokens.FontScale.title.weight(.bold))
            .frame(minHeight: 76)
            .frame(maxWidth: .infinity)
            .foregroundStyle(DesignTokens.Colors.ink)
            .background(isPressed ? DesignTokens.Colors.paper : DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 2))
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(accessibilityLabel)) // l10n: localized
            .accessibilityIdentifier(accessibilityIdentifier)
            .gesture(DragGesture(minimumDistance: 0)
                .updating($gestureIsPressing) { _, state, _ in state = true }
                .onChanged { _ in startPressIfNeeded() }
                .onEnded { _ in endPressIfNeeded() })
            .onChange(of: gestureIsPressing) { _, pressing in
                if !pressing { endPressIfNeeded() }
            }
        configuredAccessibilityActions(for: label)
    }

    @ViewBuilder
    private func configuredAccessibilityActions<Content: View>(for content: Content) -> some View {
        if let sendDotAction, let sendDashAction {
            content
                .accessibilityAction(named: Text("Send dot")) { sendDotAction() } // l10n: localized
                .accessibilityAction(named: Text("Send dash")) { sendDashAction() } // l10n: localized
        } else if let defaultAction {
            content.accessibilityAction { defaultAction() }
        } else {
            content
        }
    }

    private func startPressIfNeeded() {
        guard !isPressed else { return }
        isPressed = true
        begin()
    }

    private func endPressIfNeeded() {
        guard isPressed else { return }
        isPressed = false
        end()
    }
}

private struct MorseSendingFeedbackView: View {
    let decodedText: String
    let pendingSamples: [MorseKeyTimingSample]
    let lastFeedback: MorseCharacterTimingFeedback?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Sending feedback") // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            LabeledContent("Current elements") { // l10n: localized
                Text(pendingSamples.map(\.element.rawValue).joined().isEmpty ? "—" : pendingSamples.map(\.element.rawValue).joined()) // l10n: localized
                    .font(.body.monospaced())
                    .accessibilityIdentifier("morse-sending-current-elements")
            }
            LabeledContent("Decoded text") { // l10n: localized
                Text(decodedText.isEmpty ? "—" : decodedText) // l10n: localized
                    .font(.body.monospaced())
                    .accessibilityIdentifier("morse-sending-decoded-text")
            }
            LabeledContent("Latest feedback") { // l10n: localized
                Text(feedbackSummary) // l10n: localized
                    .accessibilityIdentifier("morse-sending-feedback-summary")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }

    private var feedbackSummary: String {
        guard let lastFeedback else {
            return String(localized: "Send a character to see dot/dash ratio and timing consistency.")
        }
        let ratio = lastFeedback.dotDashRatio.map { $0.formatted(.number.precision(.fractionLength(2))) } ?? String(localized: "not enough dots and dashes")
        return String.localizedStringWithFormat(
            String(localized: "%@, dot/dash ratio %@, timing consistency %lld%%."),
            lastFeedback.elements,
            ratio,
            Int64(lastFeedback.timingConsistencyPercent)
        )
    }
}

private struct MorseSendingResult {
    let score: MorseSendingScore
    let decodedText: String
}

private struct MorseSendingResultsScreen: View {
    let result: MorseSendingResult
    let startAgain: () -> Void

    @AccessibilityFocusState private var headingFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Sending results") // l10n: localized
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("morse-sending-results-heading")
                    .accessibilityFocused($headingFocused)
                    .onAppear { focusHeadingAfterLayout() }
                    .fixedSize(horizontal: false, vertical: true)
                Text(summary) // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityIdentifier("morse-sending-results-summary")
                    .fixedSize(horizontal: false, vertical: true)
                Text("Rule: unsent characters at 0:00 count as errors; 5 or fewer errors count as 100% and pass.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String.localizedStringWithFormat(String(localized: "%lld total errors: %lld wrong, %lld missing, %lld inserted."), Int64(result.score.diff.score.errors), Int64(result.score.diff.score.wrong), Int64(result.score.diff.score.missing), Int64(result.score.diff.score.inserted))) // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Decoded text") // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(result.decodedText.isEmpty ? String(localized: "No text sent.") : result.decodedText) // l10n: localized
                    .font(.body.monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(decodedTextAccessibilityLabel)) // l10n: localized
                morseTokenButton("Start another sending check") { startAgain() }
                    .accessibilityIdentifier("morse-sending-results-start-another-button")
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Sending results") // l10n: localized
    }

    private var summary: String {
        result.score.passed
            ? String.localizedStringWithFormat(String(localized: "PASS, 100%%, with %lld errors."), Int64(result.score.diff.score.errors))
            : String.localizedStringWithFormat(String(localized: "FAIL, %lld%%, with %lld errors."), Int64(result.score.markPercent), Int64(result.score.diff.score.errors))
    }

    private var decodedTextAccessibilityLabel: String {
        guard !result.decodedText.isEmpty else { return String(localized: "No text sent.") }
        return Array(result.decodedText).map(String.init).joined(separator: " ")
    }

    private func focusHeadingAfterLayout() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            headingFocused = true
        }
    }
}

private func oppositeElement(_ element: MorseKeyElement) -> MorseKeyElement {
    element == .dot ? .dash : .dot
}

func morseSendingRemainingExamSeconds(deadline: Date, now: Date) -> Int {
    max(0, Int(ceil(deadline.timeIntervalSince(now))))
}

private func sendingTimerLabel(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}

private var debugExamDurationSeconds: Int {
#if DEBUG
    if let value = AppLaunchArguments.value(after: "-CanadianHamMorseSendingExamSeconds"), let seconds = Int(value), seconds > 0 {
        return seconds
    }
#endif
    return 180
}

private var debugExamTextOverride: String? {
#if DEBUG
    AppLaunchArguments.value(after: "-CanadianHamMorseSendingExamText")
#else
    nil
#endif
}
