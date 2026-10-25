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
                                .id("top")
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

/// A separate native wheel owns Crown focus; ordinary question/feedback scrolling never submits.
private struct WatchCrownAnswerView: View {
    let choices: [Answer]
    let french: Bool
    let submit: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection = 0

    var body: some View {
        VStack(spacing: 8) {
            Picker("Answer", selection: $selection) {
                ForEach(choices.indices, id: \.self) { index in
                    Text("Answer \(index + 1)")
                        .accessibilityLabel(Text(answerText(index))) // l10n: content(question)
                        .tag(index)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 70)
            .accessibilityIdentifier("watch-crown-picker")
            ScrollView {
                Text(answerText(selection)) // l10n: content(question)
                    .font(.body)
                    .accessibilityValue("Selected")
                    .accessibilityIdentifier("watch-crown-selection")
            }
            Button("Confirm answer") {
                guard choices.indices.contains(selection) else { return }
                submit(choices[selection].sourceIndex)
                dismiss()
            }
            .accessibilityIdentifier("watch-confirm")
        }
        .padding(.horizontal)
    }

    private func answerText(_ index: Int) -> String {
        guard choices.indices.contains(index) else { return "" }
        return french ? choices[index].text.fr : choices[index].text.en
    }
}
