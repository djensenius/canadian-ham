import SwiftUI
import CanadianHamContent

struct WatchPracticeView: View {
    @Environment(\.locale) private var locale
    @State private var session: WatchPracticeSession?
    @State private var showingCrown = false
    @State private var pendingCrownAnnouncement: String?

    private var french: Bool { locale.language.languageCode?.identifier == "fr" }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let session {
                        if session.failed {
                            Text("Practice unavailable")
                                .accessibilityIdentifier("watch-practice-error")
                            Text("The bundled questions could not be loaded.")
                        } else if let question = session.question {
                            if session.submittedSourceIndex != nil {
                                feedback(for: session)
                            } else {
                                Text(questionText(question.text)) // l10n: content(question)
                                    .id("top")
                                    .accessibilityIdentifier("watch-question")
                                Button("Select with Crown") { showingCrown = true }
                                    .accessibilityIdentifier("watch-crown-open")
                                ForEach(Array(session.choices.enumerated()), id: \.element.sourceIndex) { index, answer in
                                    Button {
                                        submit(sourceIndex: answer.sourceIndex)
                                    } label: {
                                        Text(questionText(answer.text)) // l10n: content(question)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibilityIdentifier("watch-answer-\(index)")
                                }
                            }
                        }
                    } else {
                        ProgressView("Loading question bank")
                            .accessibilityIdentifier("watch-practice-loading")
                    }
                }
                .font(.body)
                .padding(.horizontal)
            }
            .onChange(of: session?.submittedSourceIndex) { _, _ in proxy.scrollTo("top", anchor: .top) }
            .onChange(of: session?.question?.id) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .navigationTitle("Practice")
        .sheet(isPresented: $showingCrown, onDismiss: announceCrownFeedback) {
            WatchCrownAnswerView(choices: session?.choices ?? [], french: french, submit: submit)
        }
        .task {
            guard session == nil else { return }
            do {
                let bank = try await WatchPracticeBankLoader.shared.load()
                guard !Task.isCancelled else { return }
                session = WatchPracticeSession(load: { bank }, seed: practiceSeed)
            } catch {
                guard !Task.isCancelled else { return }
                session = WatchPracticeSession(load: { throw error })
            }
        }
    }

    private var practiceSeed: String {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-watchPracticeSeed"), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }
        #endif
        return UUID().uuidString
    }

    private func submit(sourceIndex: Int) {
        guard session?.submittedSourceIndex == nil else { return }
        session?.submit(sourceIndex: sourceIndex)
        guard let session, session.submittedSourceIndex != nil else { return }
        let announcement = session.isCorrect ? String(localized: "Correct", bundle: WatchLanguage.bundle(for: locale), locale: locale) : String(localized: "Incorrect", bundle: WatchLanguage.bundle(for: locale), locale: locale)
        if showingCrown {
            pendingCrownAnnouncement = announcement
        } else {
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private func announceCrownFeedback() {
        // A sheet transition can interrupt speech posted by Confirm's action.
        guard let announcement = pendingCrownAnnouncement else { return }
        pendingCrownAnnouncement = nil
        AccessibilityNotification.Announcement(announcement).post()
    }

    @ViewBuilder
    private func feedback(for session: WatchPracticeSession) -> some View {
        Text(session.isCorrect ? "Correct" : "Incorrect") // l10n: localized
            .id("top")
            .font(.headline)
            .accessibilityIdentifier("watch-feedback")
        if let selected = session.choices.first(where: { $0.sourceIndex == session.submittedSourceIndex }) {
            Text("Your answer")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(questionText(selected.text)) // l10n: content(question)
                .accessibilityValue("Selected")
                .accessibilityAddTraits(.isSelected)
        }
        Text("Correct answer")
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        if let correct = session.choices.first(where: \.isCorrect) {
            Text(questionText(correct.text)) // l10n: content(question)
                .accessibilityIdentifier("watch-correct-answer")
        }
        Text("Explanation")
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        if let explanation = session.explanation,
           let content = try? WatchExplanationText(explanation: explanation, french: french, choices: session.choices) {
            if content.isEnglishFallback {
                Text("Explanation in English")
                    .accessibilityIdentifier("watch-english-fallback")
            }
            Text(content.attributedBody) // l10n: content(question)
                .accessibilityIdentifier("watch-explanation")
        }
        Button("Next") { self.session?.next() }
            .accessibilityIdentifier("watch-next")
    }

    private func questionText(_ text: CanadianHamContent.LocalizedText) -> String {
        french ? text.fr : text.en
    }
}

/// Crown focus is explicit and separate from scrolling; changing a choice never submits it.
private struct WatchCrownAnswerView: View {
    let choices: [Answer]
    let french: Bool
    let submit: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var crownPosition = 0.0
    @FocusState private var crownFocused: Bool

    private var selection: Int { min(3, max(0, Int(crownPosition.rounded()))) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Answer \(selection + 1)")
                    .font(.headline)
                Text(answerText(selection)) // l10n: content(question)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(answerText(selection))) // l10n: content(question)
                    .accessibilityValue("Selected")
                .accessibilityAddTraits(.isSelected)
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: crownPosition = Double(min(3, selection + 1))
                        case .decrement: crownPosition = Double(max(0, selection - 1))
                        @unknown default: break
                        }
                    }
                    .accessibilityIdentifier("watch-crown-selection")
                Button("Confirm answer") {
                    guard choices.indices.contains(selection) else { return }
                    submit(choices[selection].sourceIndex)
                    dismiss()
                }
                .accessibilityIdentifier("watch-confirm")
            }
            .padding(.horizontal)
        }
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation($crownPosition, from: 0, through: 3, by: 1,
                              sensitivity: .low, isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .defaultFocus($crownFocused, true)
        .onAppear { crownFocused = true }
    }

    private func answerText(_ index: Int) -> String {
        guard choices.indices.contains(index) else { return "" }
        return french ? choices[index].text.fr : choices[index].text.en
    }
}
