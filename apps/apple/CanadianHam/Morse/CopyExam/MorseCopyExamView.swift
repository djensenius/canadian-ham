import Accessibility
import CanadianHamMorseEngine
import SwiftUI

private enum MorseCopyPassageLength: String, CaseIterable, Identifiable {
    case short
    case medium
    case long

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .short: String(localized: "Short")
        case .medium: String(localized: "Medium")
        case .long: String(localized: "Long")
        }
    }
}

private struct MorseCopyPracticePassage {
    let title: String
    let text: String
}

private let morseCopyPracticeCorpus: [MorseCopyPassageLength: [MorseCopyPracticePassage]] = [
    .short: [
        MorseCopyPracticePassage(title: "Net check-in", text: "THE NET OPENS AT NOON. QSL?"),
        MorseCopyPracticePassage(title: "QSO signal report", text: "CQ CQ DE VE3HAM. SIGNAL 599."),
    ],
    .medium: [
        MorseCopyPracticePassage(title: "Club station", text: "CQ CQ DE VE3HAM. THE CLUB STATION SENDS A SHORT REPORT FROM OTTAWA. SIGNAL 599."),
        MorseCopyPracticePassage(title: "Portable weather", text: "VE7XYZ/PORTABLE CALLS AFTER THE NET. WEATHER IS CLEAR, WIND NORTH, POWER 25 WATTS."),
    ],
    .long: [
        MorseCopyPracticePassage(title: "Field message", text: "CQ CQ DE VE3HAM. THE FIELD STATION COPIES YOUR REPORT 599. QTH IS OTTAWA AND POWER IS 25 WATTS. PLEASE SEND NAME, QTH, AND RST AGAIN."),
        MorseCopyPracticePassage(title: "Traffic net", text: "THE TRAFFIC NET OPENS AT 1900. STATION VE2HAM SENDS MESSAGE 42 FOR FIELD DAY. MOBILE UNIT CHECKS IN FROM ROAD 17. QSL BEFORE NOON."),
    ],
]

struct MorseCopyExamView: View {
    let settings: MorseTrainerSettings

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            MorseCopyPracticeView(settings: settings)
            MorseReceivingExamView(settings: settings)
        }
    }
}

private struct MorseCopyPracticeView: View {
    let settings: MorseTrainerSettings

    @State private var driver = MorseAudioDriver()
    @State private var selectedLength: MorseCopyPassageLength = .short
    @State private var passageIndex = 0
    @State private var activePassage: MorseCopyPracticePassage?
    @State private var activeDuration = 0.0
    @State private var userCopy = ""
    @State private var diff: MorseCopyDiff?
    @State private var isPlaying = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var finishTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Copy practice") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Choose a passage length, start the audio, and type what you hear during or after playback. Passages use only RIC-1 section 8.2 characters.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Picker("Passage length", selection: $selectedLength) { // l10n: localized
                ForEach(MorseCopyPassageLength.allCases) { length in
                    Text(length.localizedLabel).tag(length) // l10n: localized
                }
            }
            .disabled(isPlaying)
            HStack {
                morseTokenButton("Start copy practice") { startPractice() }
                    .disabled(isPlaying)
                    .accessibilityIdentifier("morse-copy-start-button")
                morseTokenButton("Stop") { stopPractice(message: String(localized: "Morse playback stopped.")) }
                    .disabled(!isPlaying)
                morseTokenButton("Check copy") { gradeCopy() }
                    .disabled(activePassage == nil || isPlaying)
                    .accessibilityIdentifier("morse-copy-check-button")
            }
            if activePassage != nil {
                Text(String.localizedStringWithFormat(String(localized: "Playback duration: %@ seconds."), formattedSeconds(activeDuration))) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            TextEditor(text: $userCopy)
                .font(.body.monospaced())
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                .disabled(activePassage == nil)
                .accessibilityLabel(Text("Your copy")) // l10n: localized
                .accessibilityIdentifier("morse-copy-text-editor")
            if containsDotDashNotation(userCopy) {
                Text("Enter the characters you heard, not dot and dash notation.") // l10n: localized
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.warningText)
            }
            if !statusMessage.isEmpty {
                Text(statusMessage) // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            if let diff, let activePassage {
                MorseDiffView(diff: diff, expectedText: activePassage.text)
            }
            if let errorMessage {
                MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
            }
        }
        .paperCard()
        .onDisappear { stopPractice(message: "") }
    }

    private func startPractice() {
        let passages = morseCopyPracticeCorpus[selectedLength] ?? []
        guard !passages.isEmpty else { return }
        let passage = passages[passageIndex % passages.count]
        passageIndex += 1
        do {
            finishTask?.cancel()
            activePassage = passage
            let duration = try driver.play(text: passage.text, settings: settings.normalized())
            activeDuration = duration
            userCopy = ""
            diff = nil
            isPlaying = true
            statusMessage = String(localized: "Copy practice playback started.")
            errorMessage = nil
            let waitSeconds = debugCopyPlaybackOverride ?? duration
            finishTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((waitSeconds * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                driver.stop()
                isPlaying = false
                statusMessage = String(localized: "Playback finished. Check your copy when ready.")
                AccessibilityNotification.Announcement(statusMessage).post()
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }

    private func stopPractice(message: String) {
        finishTask?.cancel()
        finishTask = nil
        driver.stop()
        isPlaying = false
        statusMessage = message
        if !message.isEmpty {
            AccessibilityNotification.Announcement(message).post()
        }
    }

    private func gradeCopy() {
        guard let activePassage else { return }
        do {
            diff = try diffMorseCopy(expected: activePassage.text, received: userCopy)
            let errors = diff?.score.errors ?? 0
            statusMessage = String.localizedStringWithFormat(String(localized: "Copy checked: %lld errors."), Int64(errors))
            AccessibilityNotification.Announcement(statusMessage).post()
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }
}

private struct MorseReceivingExamView: View {
    let settings: MorseTrainerSettings

    @State private var driver = MorseAudioDriver()
    @State private var selectedProfile: MorseTrainerSettings.TimingProfile = .isedParis
    @State private var examText: MorseExamText?
    @State private var userCopy = ""
    @State private var diff: MorseCopyDiff?
    @State private var stage: ExamStage = .idle
    @State private var reviewRemaining = examReviewDuration
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var playbackTask: Task<Void, Never>?
    @State private var reviewTask: Task<Void, Never>?

    enum ExamStage {
        case idle
        case playing
        case review
        case graded
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Simulated 5 wpm exam") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("The receiving exam plays once without pause or replay, then gives a 2-minute review before grading. Results stay only on this screen.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Picker("Exam timing profile", selection: $selectedProfile) { // l10n: localized
                Text(MorseTrainerSettings.TimingProfile.isedParis.localizedLabel).tag(MorseTrainerSettings.TimingProfile.isedParis) // l10n: localized
                Text(MorseTrainerSettings.TimingProfile.ric1Literal.localizedLabel).tag(MorseTrainerSettings.TimingProfile.ric1Literal) // l10n: localized
            }
            .disabled(stage == .playing || stage == .review)
            morseTokenButton("Start simulated exam") { startExam() }
                .disabled(stage == .playing || stage == .review)
                .accessibilityIdentifier("morse-exam-start-button")
            if let examText {
                Text(String.localizedStringWithFormat(String(localized: "Generated exam: %lld weighted characters, %@ seconds of audio."), Int64(examText.weightedCharacters), formattedSeconds(examText.durationSeconds))) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            if stage == .review {
                Text(String.localizedStringWithFormat(String(localized: "Review time remaining: %lld seconds."), Int64(reviewRemaining))) // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityIdentifier("morse-exam-review-timer")
            }
            TextEditor(text: $userCopy)
                .font(.body.monospaced())
                .frame(minHeight: 140)
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                .disabled(stage == .idle || stage == .graded)
                .accessibilityLabel(Text("Your copy")) // l10n: localized
                .accessibilityIdentifier("morse-exam-text-editor")
            if containsDotDashNotation(userCopy) {
                Text("Enter the characters you heard, not dot and dash notation.") // l10n: localized
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.warningText)
            }
            if !statusMessage.isEmpty {
                Text(statusMessage) // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityIdentifier("morse-exam-status")
            }
            if let diff, let examText {
                MorseDiffView(diff: diff, expectedText: examText.text)
            }
            if let errorMessage {
                MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
            }
        }
        .paperCard()
        .onDisappear { stopAll() }
    }

    private func startExam() {
        do {
            stopAll()
            let profileName: MorseProfileName = selectedProfile == .ric1Literal ? .ric1Literal : .isedParis
            let profile = profileForName(profileName)
            let generated = try generateMorseExamText(seed: "apple-\(profileName.rawValue)-\(UUID().uuidString)", profile: profile)
            examText = generated
            userCopy = ""
            diff = nil
            stage = .playing
            statusMessage = String(localized: "Exam playback started. Audio cannot be paused or replayed.")
            errorMessage = nil
            var playbackSettings = settings.normalized()
            playbackSettings.timingProfile = selectedProfile
            playbackSettings.characterWpm = 12
            playbackSettings.effectiveWpm = 5
            let duration = try driver.play(text: generated.text, settings: playbackSettings)
            let waitSeconds = debugExamPlaybackOverride ?? duration
            playbackTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((waitSeconds * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                driver.stop()
                startReview()
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }

    private func startReview() {
        stage = .review
        reviewRemaining = examReviewDuration
        statusMessage = String.localizedStringWithFormat(String(localized: "Playback finished. The %lld-second review period has started."), Int64(examReviewDuration))
        AccessibilityNotification.Announcement(statusMessage).post()
        reviewTask = Task { @MainActor in
            while reviewRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                reviewRemaining -= 1
            }
            gradeExam()
        }
    }

    private func gradeExam() {
        guard let examText else { return }
        do {
            diff = try diffMorseCopy(expected: examText.text, received: userCopy)
            guard let score = diff?.score else { return }
            stage = .graded
            statusMessage = score.passed
                ? String.localizedStringWithFormat(String(localized: "PASS, 100%%, with %lld errors."), Int64(score.errors))
                : String.localizedStringWithFormat(String(localized: "FAIL, %lld%%, with %lld errors."), Int64(score.markPercent), Int64(score.errors))
            AccessibilityNotification.Announcement(statusMessage).post()
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }

    private func stopAll() {
        playbackTask?.cancel()
        playbackTask = nil
        reviewTask?.cancel()
        reviewTask = nil
        driver.stop()
        if stage == .playing || stage == .review {
            stage = examText == nil ? .idle : .graded
        }
    }
}

private struct MorseDiffView: View {
    let diff: MorseCopyDiff
    let expectedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Character diff") // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("morse-diff-title")
            Text(diffSummary) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(diff.score.passed ? String.localizedStringWithFormat(String(localized: "Exam rule: pass at %lld%% because 5 or fewer errors count as 100%%."), Int64(diff.score.markPercent)) : String.localizedStringWithFormat(String(localized: "Exam rule: fail at %lld%% because more than 5 errors is below the 100%% pass mark."), Int64(diff.score.markPercent))) // l10n: localized
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            DisclosureGroup("Expected transcript") { // l10n: localized
                Text(verbatim: expectedText) // l10n: verbatim
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: DesignTokens.Spacing.xs)], alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                ForEach(Array(diff.operations.enumerated()), id: \.offset) { _, operation in
                    Text(visibleDiffLabel(operation)) // l10n: localized markers with verbatim characters
                        .font(.caption.monospaced().weight(.bold))
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(diffBackground(operation), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.xs, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.xs, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
                        .accessibilityLabel(Text(accessibilityDiffLabel(operation))) // l10n: localized
                }
            }
        }
    }

    private var diffSummary: String {
        String.localizedStringWithFormat(
            String(localized: "%lld total errors: %lld wrong, %lld missing, %lld inserted."),
            Int64(diff.score.errors),
            Int64(diff.score.wrong),
            Int64(diff.score.missing),
            Int64(diff.score.inserted)
        )
    }
}

private func visibleDiffLabel(_ operation: MorseCopyDiffOperation) -> String {
    switch operation.kind {
    case .match:
        operation.expected ?? ""
    case .wrong:
        "✕ \(operation.expected ?? "")/\(operation.received ?? "")"
    case .missing:
        "− \(operation.expected ?? "")"
    case .inserted:
        "+ \(operation.received ?? "")"
    }
}

private func accessibilityDiffLabel(_ operation: MorseCopyDiffOperation) -> String {
    switch operation.kind {
    case .match:
        operation.expected ?? ""
    case .wrong:
        String.localizedStringWithFormat(String(localized: "Wrong: expected %@, received %@"), operation.expected ?? "", operation.received ?? "")
    case .missing:
        String.localizedStringWithFormat(String(localized: "Missing: %@"), operation.expected ?? "")
    case .inserted:
        String.localizedStringWithFormat(String(localized: "Inserted: %@"), operation.received ?? "")
    }
}

private func diffBackground(_ operation: MorseCopyDiffOperation) -> Color {
    switch operation.kind {
    case .match:
        DesignTokens.Colors.paperInset
    case .wrong:
        DesignTokens.Colors.incorrectBg
    case .missing:
        DesignTokens.Colors.warningBg
    case .inserted:
        DesignTokens.Colors.paperElevated
    }
}

private func containsDotDashNotation(_ text: String) -> Bool {
    let stripped = text.filter { !$0.isWhitespace }
    return !stripped.isEmpty && stripped.allSatisfy { $0 == "." || $0 == "-" }
}

private func formattedSeconds(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 1
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
}

private var examReviewDuration: Int {
#if DEBUG
    if let value = AppLaunchArguments.value(after: "-CanadianHamMorseExamReviewSeconds"), let seconds = Int(value), seconds > 0 {
        return seconds
    }
#endif
    return 120
}

private var debugCopyPlaybackOverride: Double? {
#if DEBUG
    if let value = AppLaunchArguments.value(after: "-CanadianHamMorseCopyPlaybackSeconds"), let seconds = Double(value), seconds > 0 {
        return seconds
    }
#endif
    return nil
}

private var debugExamPlaybackOverride: Double? {
#if DEBUG
    if let value = AppLaunchArguments.value(after: "-CanadianHamMorseExamPlaybackSeconds"), let seconds = Double(value), seconds > 0 {
        return seconds
    }
#endif
    return nil
}
