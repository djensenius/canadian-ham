import Accessibility
import CanadianHamMorseEngine
import SwiftUI

struct MorseSendingPracticeView: View {
    let settings: MorseTrainerSettings
    let playbackCoordinator: MorsePlaybackCoordinator

    @State private var driver = MorseAudioDriver()
    @State private var pendingSamples: [MorseKeyTimingSample] = []
    @State private var decodedText = ""
    @State private var lastFeedback: MorseCharacterTimingFeedback?
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var straightKeyDownAt: Date?
    @State private var finalizeTask: Task<Void, Never>?
    @State private var paddleTasks: [MorseKeyElement: Task<Void, Never>] = [:]
    @State private var examText = ""
    @State private var examRemaining = 180
    @State private var examRunning = false
    @State private var examTimerTask: Task<Void, Never>?
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Sending practice") // l10n: localized
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Practise tap timing with a straight key or iambic-style paddles. On Mac, hold Space for the straight key; use J for dots and K for dashes. On iPhone and iPad, use the large touch targets.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                MorseSendingExamCard(
                    examText: examText,
                    examRemaining: examRemaining,
                    examRunning: examRunning,
                    start: startExam,
                    grade: { gradeExam(completedWithinTime: examRemaining > 0) }
                )
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Straight key") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    MorsePressKeyButton(
                        title: String(localized: "Hold key"),
                        accessibilityLabel: String(localized: "Straight key. Hold to send tone, release to classify dot or dash."),
                        accessibilityIdentifier: "morse-sending-straight-key-button",
                        begin: beginStraightKey,
                        end: endStraightKey
                    )
#if os(macOS)
                    .keyboardShortcut(.space, modifiers: [])
#endif
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
                            end: { endPaddle(.dot) }
                        )
#if os(macOS)
                        .keyboardShortcut("j", modifiers: [])
#endif
                        MorsePressKeyButton(
                            title: String(localized: "Dash"),
                            accessibilityLabel: String(localized: "Dash paddle. Hold for repeated dashes."),
                            accessibilityIdentifier: "morse-sending-dash-paddle-button",
                            begin: { beginPaddle(.dash) },
                            end: { endPaddle(.dash) }
                        )
#if os(macOS)
                        .keyboardShortcut("k", modifiers: [])
#endif
                    }
                }
                MorseSendingFeedbackView(decodedText: decodedText, pendingSamples: pendingSamples, lastFeedback: lastFeedback)
                HStack {
                    morseTokenButton("Clear sending practice") { resetSending(clearExam: false) }
#if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseSendingDebugHook") {
                        Button(action: fillExamTextForUITest) {
                            Text(verbatim: "Fill sending check") // l10n: verbatim DEBUG-only UI test hook
                                .font(DesignTokens.FontScale.body.weight(.bold))
                        }
                        .accessibilityIdentifier("morse-sending-debug-fill-button")
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
            .paperCard()
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
            stopAllKeying()
            examTimerTask?.cancel()
        }
    }

    private func beginStraightKey() {
        guard straightKeyDownAt == nil else { return }
        playbackCoordinator.claim("sending-practice")
        straightKeyDownAt = Date()
        do {
            _ = try driver.play(text: "E", settings: settings.normalized())
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            straightKeyDownAt = nil
        }
    }

    private func endStraightKey() {
        guard let started = straightKeyDownAt else { return }
        let duration = max(0.001, Date().timeIntervalSince(started))
        straightKeyDownAt = nil
        driver.stop()
        do {
            appendSample(try classifyMorseKeyDown(durationSeconds: duration, profile: profile))
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func beginPaddle(_ element: MorseKeyElement) {
        guard paddleTasks[element] == nil else { return }
        playbackCoordinator.claim("sending-practice")
        emitPaddleElement(element)
        let delay = max(40_000_000, UInt64((profile.dotSeconds + profile.intraCharacterGapSeconds) * 1_000_000_000))
        paddleTasks[element] = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { break }
                emitPaddleElement(element)
            }
        }
    }

    private func endPaddle(_ element: MorseKeyElement) {
        paddleTasks[element]?.cancel()
        paddleTasks[element] = nil
    }

    private func emitPaddleElement(_ element: MorseKeyElement) {
        let text = element == .dot ? "E" : "T"
        _ = try? driver.play(text: text, settings: settings.normalized())
        let duration = element == .dot ? profile.dotSeconds : profile.dashSeconds
        appendSample(MorseKeyTimingSample(element: element, durationSeconds: duration, expectedSeconds: duration, ratioToExpected: 1))
    }

    private func appendSample(_ sample: MorseKeyTimingSample) {
        pendingSamples.append(sample)
        scheduleFinalizeCharacter()
    }

    private func scheduleFinalizeCharacter() {
        finalizeTask?.cancel()
        let delay = UInt64((profile.interCharacterGapSeconds * 1_000_000_000).rounded(.up)) + 20_000_000
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

    private func startExam() {
        resetSending(clearExam: false)
        do {
            let generated = try generateMorseExamText(seed: "apple-sending-\(Date().timeIntervalSince1970)", profile: profileForName(.isedParis), minDurationSeconds: 0)
            examText = generated.text
            examRemaining = debugExamDurationSeconds
            examRunning = true
            statusMessage = String(localized: "Sending check started. Send the displayed passage within 3:00.")
            examTimerTask?.cancel()
            examTimerTask = Task { @MainActor in
                while examRemaining > 0, !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    examRemaining -= 1
                }
                if !Task.isCancelled, examRunning {
                    gradeExam(completedWithinTime: false)
                }
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func gradeExam(completedWithinTime: Bool) {
        finalizeCharacter()
        guard !examText.isEmpty else { return }
        examRunning = false
        examTimerTask?.cancel()
        do {
            let score = try scoreMorseSending(expected: examText, sent: decodedText, completedWithinTime: completedWithinTime)
            presentedResult = MorseSendingResult(score: score, decodedText: decodedText)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func resetSending(clearExam: Bool) {
        stopAllKeying()
        finalizeTask?.cancel()
        finalizeTask = nil
        pendingSamples = []
        decodedText = ""
        lastFeedback = nil
        statusMessage = ""
        errorMessage = nil
        if clearExam {
            examTimerTask?.cancel()
            examText = ""
            examRemaining = debugExamDurationSeconds
            examRunning = false
        }
    }

    private func stopAllKeying() {
        driver.stop()
        straightKeyDownAt = nil
        for task in paddleTasks.values { task.cancel() }
        paddleTasks = [:]
    }

#if DEBUG
    private func fillExamTextForUITest() {
        decodedText = (try? canonicalMorseCharacters(examText).joined()) ?? examText.replacingOccurrences(of: " ", with: "")
        statusMessage = "Decoded exam text filled for UI testing."
    }
#else
    private func fillExamTextForUITest() {}
#endif
}

private struct MorseSendingExamCard: View {
    let examText: String
    let examRemaining: Int
    let examRunning: Bool
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
                    .disabled(examRunning)
                    .accessibilityIdentifier("morse-sending-start-exam-button")
                morseTokenButton("End and grade") { grade() }
                    .disabled(examText.isEmpty)
                    .accessibilityIdentifier("morse-sending-grade-exam-button")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }
}

private struct MorsePressKeyButton: View {
    let title: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let begin: () -> Void
    let end: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(title) // l10n: localized
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
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        begin()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        end()
                    }
                })
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
        let ratio = lastFeedback.dotDashRatio.map { String(format: "%.2f", $0) } ?? String(localized: "not enough dots and dashes")
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Sending results") // l10n: localized
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("morse-sending-results-heading")
                    .fixedSize(horizontal: false, vertical: true)
                Text(summary) // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityIdentifier("morse-sending-results-summary")
                    .fixedSize(horizontal: false, vertical: true)
                Text("Rule: 5 or fewer errors and all text within 3:00 to pass.") // l10n: localized
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
