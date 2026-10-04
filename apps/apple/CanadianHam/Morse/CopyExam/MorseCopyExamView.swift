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

private enum MorseCopyResultKind {
    case copyPractice
    case receivingExam

    var title: String {
        switch self {
        case .copyPractice:
            String(localized: "Copy results")
        case .receivingExam:
            String(localized: "Exam results")
        }
    }

    var actionTitle: String {
        switch self {
        case .copyPractice:
            String(localized: "Try another passage")
        case .receivingExam:
            String(localized: "Start another exam")
        }
    }

    var headingIdentifier: String {
        switch self {
        case .copyPractice:
            "morse-copy-results-heading"
        case .receivingExam:
            "morse-exam-results-heading"
        }
    }

    var screenIdentifier: String {
        switch self {
        case .copyPractice:
            "morse-copy-results-screen"
        case .receivingExam:
            "morse-exam-results-screen"
        }
    }

    var actionIdentifier: String {
        switch self {
        case .copyPractice:
            "morse-copy-results-try-another-button"
        case .receivingExam:
            "morse-exam-results-start-another-button"
        }
    }
}

private struct MorseCopyResult {
    let kind: MorseCopyResultKind
    let diff: MorseCopyDiff
    let expectedText: String
    let userCopy: String

    var summary: String {
        switch kind {
        case .copyPractice:
            return String.localizedStringWithFormat(
                String(localized: "Accuracy: %lld%%. Errors: %lld total, %lld wrong, %lld missing, %lld inserted."),
                Int64(copyAccuracyPercent),
                Int64(diff.score.errors),
                Int64(diff.score.wrong),
                Int64(diff.score.missing),
                Int64(diff.score.inserted)
            )
        case .receivingExam:
            return diff.score.passed
                ? String.localizedStringWithFormat(String(localized: "PASS, 100%%, with %lld errors."), Int64(diff.score.errors))
                : String.localizedStringWithFormat(String(localized: "FAIL, %lld%%, with %lld errors."), Int64(diff.score.markPercent), Int64(diff.score.errors))
        }
    }

    var showsExamRule: Bool {
        kind == .receivingExam
    }

    private var copyAccuracyPercent: Int {
        guard diff.score.expectedLength > 0 else { return diff.score.errors == 0 ? 100 : 0 }
        let correct = max(0, diff.score.expectedLength - diff.score.errors)
        return Int((Double(correct) / Double(diff.score.expectedLength) * 100).rounded())
    }
}

struct MorseCopyExamView: View {
    let settings: MorseTrainerSettings
    let playbackCoordinator: MorsePlaybackCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            MorseCopyPracticeView(settings: settings, playbackCoordinator: playbackCoordinator)
            MorseReceivingExamView(settings: settings, playbackCoordinator: playbackCoordinator)
        }
    }
}

private struct MorseCopyPracticeView: View {
    let settings: MorseTrainerSettings
    let playbackCoordinator: MorsePlaybackCoordinator

    @State private var driver = MorseAudioDriver()
    @State private var selectedLength: MorseCopyPassageLength = .short
    @State private var passageIndex = 0
    @State private var activePassage: MorseCopyPracticePassage?
    @State private var activeDuration = 0.0
    @State private var userCopy = ""
    @State private var diff: MorseCopyDiff?
    @State private var presentedResult: MorseCopyResult?
    @State private var isPlaying = false
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var finishTask: Task<Void, Never>?

    private var resultIsPresented: Binding<Bool> {
        Binding(
            get: { presentedResult != nil },
            set: { isPresented in
                if !isPresented {
                    presentedResult = nil
                }
            }
        )
    }

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
            if let errorMessage {
                MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
            }
        }
        .paperCard()
        .navigationDestination(isPresented: resultIsPresented) {
            if let presentedResult {
                MorseCopyResultsScreen(result: presentedResult) {
                    resetPracticeForAnotherPassage()
                }
            }
        }
        .onAppear {
            playbackCoordinator.register("copy-practice") {
                stopPracticeIfPlaying()
            }
        }
        .onDisappear {
            playbackCoordinator.unregister("copy-practice")
            stopPractice(message: "")
        }
    }

    private func resetPracticeForAnotherPassage() {
        finishTask?.cancel()
        finishTask = nil
        driver.stop()
        activePassage = nil
        activeDuration = 0
        userCopy = ""
        diff = nil
        presentedResult = nil
        isPlaying = false
        statusMessage = ""
        errorMessage = nil
    }

    private func startPractice() {
        let passages = morseCopyPracticeCorpus[selectedLength] ?? []
        guard !passages.isEmpty else { return }
        let passage = passages[passageIndex % passages.count]
        do {
            playbackCoordinator.claim("copy-practice")
            finishTask?.cancel()
            finishTask = nil
            driver.stop()
            activePassage = nil
            activeDuration = 0
            userCopy = ""
            diff = nil
            presentedResult = nil
            isPlaying = false
            statusMessage = ""
            errorMessage = nil
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseFailCopyAudioStartup") {
                throw NSError(domain: "CanadianHamUITests", code: 1)
            }
#endif
            let duration = try driver.play(text: passage.text, settings: settings.normalized())
            passageIndex += 1
            activePassage = passage
            activeDuration = duration
            isPlaying = true
            statusMessage = String(localized: "Copy practice playback started.")
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
            finishTask?.cancel()
            finishTask = nil
            driver.stop()
            activePassage = nil
            activeDuration = 0
            userCopy = ""
            diff = nil
            presentedResult = nil
            isPlaying = false
            statusMessage = ""
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

    private func stopPracticeIfPlaying() {
        guard isPlaying else { return }
        stopPractice(message: String(localized: "Morse playback stopped."))
    }

    private func gradeCopy() {
        guard let activePassage else { return }
        do {
            let scoredDiff = try diffMorseCopy(expected: activePassage.text, received: userCopy)
            diff = scoredDiff
            let errors = scoredDiff.score.errors
            statusMessage = String.localizedStringWithFormat(String(localized: "Copy checked: %lld errors."), Int64(errors))
            AccessibilityNotification.Announcement(statusMessage).post()
            presentedResult = MorseCopyResult(kind: .copyPractice, diff: scoredDiff, expectedText: activePassage.text, userCopy: userCopy)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }
}

private struct MorseReceivingExamView: View {
    let settings: MorseTrainerSettings
    let playbackCoordinator: MorsePlaybackCoordinator

    @State private var driver = MorseAudioDriver()
    @State private var selectedProfile: MorseTrainerSettings.TimingProfile = .isedParis
    @State private var examText: MorseExamText?
    @State private var userCopy = ""
    @State private var diff: MorseCopyDiff?
    @State private var presentedResult: MorseCopyResult?
    @State private var stage: ExamStage = .idle
    @State private var reviewRemaining = examReviewDuration
    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var playbackTask: Task<Void, Never>?
    @State private var reviewTask: Task<Void, Never>?

    private var resultIsPresented: Binding<Bool> {
        Binding(
            get: { presentedResult != nil },
            set: { isPresented in
                if !isPresented {
                    presentedResult = nil
                }
            }
        )
    }

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
                .accessibilityIdentifier("morse-exam-title")
            Text("The receiving exam plays once without pause or replay, then gives a 2-minute review before grading. Results open on a separate screen after grading.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("morse-exam-explanation")
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
                    .accessibilityIdentifier("morse-exam-generated-summary")
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
            if let errorMessage {
                MessagePanel(title: "Morse error", message: errorMessage, kind: .warning)
            }
        }
        .paperCard()
        .accessibilityElement(children: .contain)
        .navigationDestination(isPresented: resultIsPresented) {
            if let presentedResult {
                MorseCopyResultsScreen(result: presentedResult) {
                    resetExamForAnotherAttempt()
                }
            }
        }
        .onAppear {
            playbackCoordinator.register("simulated-exam") {
                stopExamPlaybackIfPlaying()
            }
        }
        .onDisappear {
            playbackCoordinator.unregister("simulated-exam")
            stopAll()
        }
    }

    private func resetExamForAnotherAttempt() {
        stopAll()
        examText = nil
        userCopy = ""
        diff = nil
        presentedResult = nil
        reviewRemaining = examReviewDuration
        stage = .idle
        statusMessage = ""
        errorMessage = nil
    }

    private func startExam() {
        do {
            playbackCoordinator.claim("simulated-exam")
            stopAll()
            let profileName: MorseProfileName = selectedProfile == .ric1Literal ? .ric1Literal : .isedParis
            let profile = profileForName(profileName)
            let generated = try generateMorseExamText(seed: "apple-\(profileName.rawValue)-\(UUID().uuidString)", profile: profile)
            examText = nil
            userCopy = ""
            diff = nil
            presentedResult = nil
            reviewRemaining = examReviewDuration
            stage = .playing
            statusMessage = ""
            errorMessage = nil
            var playbackSettings = settings.normalized()
            playbackSettings.timingProfile = selectedProfile
            playbackSettings.characterWpm = 12
            playbackSettings.effectiveWpm = 5
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamMorseFailExamAudioStartup") {
                throw NSError(domain: "CanadianHamUITests", code: 1)
            }
#endif
            let duration = try driver.play(text: generated.text, settings: playbackSettings)
            examText = generated
            statusMessage = String(localized: "Exam playback started. Audio cannot be paused or replayed.")
            let waitSeconds = debugExamPlaybackOverride ?? duration
            playbackTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((waitSeconds * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                driver.stop()
                startReview()
            }
        } catch {
            playbackTask?.cancel()
            playbackTask = nil
            reviewTask?.cancel()
            reviewTask = nil
            driver.stop()
            examText = nil
            userCopy = ""
            diff = nil
            presentedResult = nil
            stage = .idle
            statusMessage = ""
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
            let scoredDiff = try diffMorseCopy(expected: examText.text, received: userCopy)
            diff = scoredDiff
            stage = .graded
            let result = MorseCopyResult(kind: .receivingExam, diff: scoredDiff, expectedText: examText.text, userCopy: userCopy)
            statusMessage = result.summary
            AccessibilityNotification.Announcement(statusMessage).post()
            presentedResult = result
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: "), detail: error)
        }
    }

    private func stopExamPlaybackIfPlaying() {
        guard stage == .playing else { return }
        playbackTask?.cancel()
        playbackTask = nil
        reviewTask?.cancel()
        reviewTask = nil
        driver.stop()
        examText = nil
        userCopy = ""
        diff = nil
        presentedResult = nil
        reviewRemaining = examReviewDuration
        stage = .idle
        statusMessage = String(localized: "Morse playback stopped.")
        AccessibilityNotification.Announcement(statusMessage).post()
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

private struct MorseCopyResultsScreen: View {
    let result: MorseCopyResult
    let onStartAnother: () -> Void

    @AccessibilityFocusState private var headingFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(result.kind.title) // l10n: localized
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(result.diff.score.passed ? DesignTokens.Colors.correctText : DesignTokens.Colors.warningText)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(result.kind.headingIdentifier)
                        .accessibilityFocused($headingFocused)
                        .onAppear { focusHeadingAfterLayout() }
                    Text(result.summary) // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityIdentifier("morse-results-summary")
                }
                .paperCard()

                MorseDiffView(diff: result.diff, expectedText: result.expectedText, showsExamRule: result.showsExamRule)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Your copy") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    if result.userCopy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No copy entered.") // l10n: localized
                            .font(.body.monospaced())
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .accessibilityIdentifier("morse-results-user-copy")
                    } else {
                        Text(verbatim: result.userCopy) // l10n: verbatim
                            .font(.body.monospaced())
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("morse-results-user-copy")
                    }
                }
                .paperCard()

                // onStartAnother resets the parent state, which clears presentedResult and pops this
                // screen exactly once through the navigationDestination binding.
                Button(result.kind.actionTitle) { // l10n: localized
                    onStartAnother()
                }
                .buttonStyle(AccessiblePrimaryButtonStyle())
                .accessibilityIdentifier(result.kind.actionIdentifier)
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(result.kind.title) // l10n: localized
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .accessibilityIdentifier(result.kind.screenIdentifier)
    }

    private func focusHeadingAfterLayout() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            headingFocused = true
        }
    }
}

private struct MorseDiffView: View {
    let diff: MorseCopyDiff
    let expectedText: String
    let showsExamRule: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Character diff") // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.paper)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("morse-diff-title")
            Text(diffSummary) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .background(DesignTokens.Colors.paper)
                .accessibilityIdentifier("morse-diff-summary")
            if showsExamRule {
                Text(examRuleSummary) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .background(DesignTokens.Colors.paper)
                    .accessibilityIdentifier("morse-diff-rule")
            }
            DisclosureGroup("Expected transcript") { // l10n: localized
                Text(verbatim: expectedText) // l10n: verbatim
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: DesignTokens.Spacing.xs)], alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                ForEach(Array(diff.operations.enumerated()), id: \.offset) { _, operation in
                    Text(visibleDiffLabel(operation)) // l10n: localized markers with verbatim characters
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(diffForeground(operation))
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, 3)
                        .background(diffBackground(operation), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.xs, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.xs, style: .continuous).strokeBorder(diffBorder(operation), lineWidth: 1))
                        .accessibilityLabel(Text(accessibilityDiffLabel(operation))) // l10n: localized
                        .accessibilityIdentifier("morse-diff-token-\(operation.kind.rawValue)")
                }
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.paper, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
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

    private var examRuleSummary: String {
        diff.score.passed
            ? String.localizedStringWithFormat(String(localized: "Exam rule: pass at %lld%% because 5 or fewer errors count as 100%%."), Int64(diff.score.markPercent))
            : String.localizedStringWithFormat(String(localized: "Exam rule: fail at %lld%% because more than 5 errors is below the 100%% pass mark."), Int64(diff.score.markPercent))
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

private func diffForeground(_: MorseCopyDiffOperation) -> Color {
    DesignTokens.Colors.ink
}

private func diffBorder(_ operation: MorseCopyDiffOperation) -> Color {
    switch operation.kind {
    case .match:
        DesignTokens.Colors.border
    case .wrong:
        DesignTokens.Colors.incorrectBorder
    case .missing:
        DesignTokens.Colors.warningBorder
    case .inserted:
        DesignTokens.Colors.accent
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
