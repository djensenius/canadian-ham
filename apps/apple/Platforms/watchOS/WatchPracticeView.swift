import SwiftUI
import CanadianHamContent

struct WatchPracticeView: View {
    @Environment(\.locale) private var locale
    @State private var session = WatchPracticeSession()
    @State private var showingCrown = false

    private var french: Bool { locale.language.languageCode?.identifier == "fr" }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if session.failed {
                        Text("Practice unavailable")
                            .accessibilityIdentifier("watch-practice-error")
                        Text("The bundled questions could not be loaded.")
                    } else if let question = session.question {
                        if session.submittedSourceIndex != nil {
                            feedback
                        } else {
                            Text(questionText(question.text)) // l10n: content(question)
                                .id("top")
                                .accessibilityIdentifier("watch-question")
                            Button("Select with Crown") { showingCrown = true }
                                .accessibilityIdentifier("watch-crown-open")
                            ForEach(Array(session.choices.enumerated()), id: \.element.sourceIndex) { index, answer in
                                Button {
                                    session.submit(sourceIndex: answer.sourceIndex)
                                } label: {
                                    Text(questionText(answer.text)) // l10n: content(question)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .accessibilityIdentifier("watch-answer-\(index)")
                                .accessibilityValue("Not selected")
                            }
                        }
                    }
                }
                .font(.body)
                .padding(.horizontal)
            }
            .onChange(of: session.submittedSourceIndex) { _, _ in proxy.scrollTo("top", anchor: .top) }
            .onChange(of: session.question?.id) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .navigationTitle("Practice")
        .sheet(isPresented: $showingCrown) {
            WatchCrownAnswerView(choices: session.choices, french: french) { sourceIndex in
                session.submit(sourceIndex: sourceIndex)
            }
        }
    }

    @ViewBuilder
    private var feedback: some View {
        Text(session.isCorrect ? "Correct" : "Incorrect") // l10n: localized
            .id("top")
            .font(.headline)
            .accessibilityIdentifier("watch-feedback")
        if let selected = session.choices.first(where: { $0.sourceIndex == session.submittedSourceIndex }) {
            Text("Your answer")
                .font(.headline)
            Text(questionText(selected.text)) // l10n: content(question)
                .accessibilityValue("Selected")
        }
        Text("Correct answer")
            .font(.headline)
        if let correct = session.choices.first(where: \.isCorrect) {
            Text(questionText(correct.text)) // l10n: content(question)
                .accessibilityIdentifier("watch-correct-answer")
        }
        Text("Explanation")
            .font(.headline)
        if let explanation = session.explanation {
            let content = WatchExplanationText(explanation: explanation, french: french)
            if content.isEnglishFallback {
                Text("Explanation in English")
                    .accessibilityIdentifier("watch-english-fallback")
            }
            Text(content.attributedBody) // l10n: content(question)
                .accessibilityIdentifier("watch-explanation")
        }
        Button("Next") { session.next() }
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
