import Accessibility
import SwiftUI

struct PracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    @Binding var language: BankLanguage

    @ScaledMetric(relativeTo: .headline) private var answerLetterMinWidth = 32

    @State private var currentQuestion: BankQuestion?
    @State private var shuffledAnswers: [ShuffledAnswer] = []
    @State private var selectedSourceIndex: Int?
    @State private var answeredCount = 0
    @State private var correctCount = 0

    private var categoryQuestions: [BankQuestion] {
        bank.questions(in: category)
    }

    private var selectedAnswer: ShuffledAnswer? {
        guard let selectedSourceIndex else { return nil }
        return shuffledAnswers.first { $0.sourceIndex == selectedSourceIndex }
    }

    private var correctAnswer: ShuffledAnswer? {
        TempShuffle.correctAnswer(in: shuffledAnswers)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let currentQuestion {
                    questionCard(currentQuestion)
                    answerList
                    feedback
                    controls
                } else {
                    ContentUnavailableView(
                        "No questions found",
                        systemImage: "questionmark.circle",
                        description: Text("This category has no bundled questions.")
                    )
                }
            }
            .padding()
            .frame(maxWidth: 860, alignment: .leading)
        }
        .navigationTitle(category.name.text(for: language))
        .toolbar {
            languageToolbarItem
        }
        .onAppear {
            if currentQuestion == nil {
                loadNextQuestion()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name.text(for: language))
                .font(.largeTitle.bold())
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            Text("Random practice from \(category.questionCount) official Basic questions.")
                .foregroundStyle(.secondary)
            Text("Session tally: \(correctCount) correct out of \(answeredCount) answered")
                .font(.headline)
                .accessibilityLabel("Session tally, \(correctCount) correct out of \(answeredCount) answered")
        }
    }

    private func questionCard(_ question: BankQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.id)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Question identifier \(question.id)")
            Text(question.text.text(for: language))
                .font(.title2.weight(.semibold))
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var answerList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Answers")
                .font(.headline)
            ForEach(shuffledAnswers) { shuffledAnswer in
                answerButton(for: shuffledAnswer)
            }
        }
    }

    private func answerButton(for shuffledAnswer: ShuffledAnswer) -> some View {
        let isSelected = selectedSourceIndex == shuffledAnswer.sourceIndex
        let isAnswered = selectedSourceIndex != nil
        let label = answerLetter(for: shuffledAnswer.displayIndex)
        let answerText = shuffledAnswer.answer.text.text(for: language)

        return Button {
            select(shuffledAnswer)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.headline.monospaced())
                    .frame(minWidth: answerLetterMinWidth, minHeight: answerLetterMinWidth, alignment: .center)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())

                Text(answerText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isAnswered {
                    if shuffledAnswer.isCorrect {
                        Label("Correct answer", systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.green)
                    } else if isSelected {
                        Label("Your answer", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answerBackground(for: shuffledAnswer, isSelected: isSelected), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
        .accessibilityLabel(answerAccessibilityLabel(label: label, answerText: answerText, shuffledAnswer: shuffledAnswer, isSelected: isSelected))
        .accessibilityIdentifier("answer-\(label)-button")
    }

    @ViewBuilder
    private var feedback: some View {
        if let selectedAnswer, let correctAnswer {
            VStack(alignment: .leading, spacing: 10) {
                if selectedAnswer.isCorrect {
                    Label("Correct", systemImage: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                } else {
                    Label("Incorrect", systemImage: "xmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.red)
                    Text("Correct answer: \(correctAnswer.answer.text.text(for: language))")
                        .font(.headline)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private var languageToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Picker("Question language", selection: $language) {
                ForEach(BankLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Question language")
            .accessibilityIdentifier("question-language-picker")
        }
    }

    private var controls: some View {
        HStack {
            Button("Next question") {
                loadNextQuestion()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedSourceIndex == nil)
            .accessibilityHint("Loads another random question from this category")

            if selectedSourceIndex == nil {
                Text("Choose an answer to continue.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func select(_ answer: ShuffledAnswer) {
        guard selectedSourceIndex == nil else { return }
        selectedSourceIndex = answer.sourceIndex
        answeredCount += 1
        if answer.isCorrect {
            correctCount += 1
        }
        AccessibilityNotification.Announcement(feedbackAnnouncement(for: answer)).post()
    }

    private func loadNextQuestion() {
        guard !categoryQuestions.isEmpty else {
            currentQuestion = nil
            shuffledAnswers = []
            selectedSourceIndex = nil
            return
        }

        var generator = SystemRandomNumberGenerator()
        let question = categoryQuestions.randomElement(using: &generator) ?? categoryQuestions[0]
        currentQuestion = question
        shuffledAnswers = TempShuffle.shuffledAnswers(for: question, using: &generator)
        selectedSourceIndex = nil
    }

    private func answerLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D"]
        guard letters.indices.contains(index) else { return "\(index + 1)" }
        return letters[index]
    }

    private func answerBackground(for shuffledAnswer: ShuffledAnswer, isSelected: Bool) -> Color {
        guard selectedSourceIndex != nil else { return Color.secondary.opacity(0.08) }
        if shuffledAnswer.isCorrect { return Color.green.opacity(0.18) }
        if isSelected { return Color.red.opacity(0.18) }
        return Color.secondary.opacity(0.08)
    }

    private func feedbackAnnouncement(for answer: ShuffledAnswer) -> String {
        if answer.isCorrect {
            return "Correct"
        }

        if let correctAnswer {
            return "Incorrect. Correct answer: \(correctAnswer.answer.text.text(for: language))"
        }

        return "Incorrect"
    }

    private func answerAccessibilityLabel(
        label: String,
        answerText: String,
        shuffledAnswer: ShuffledAnswer,
        isSelected: Bool
    ) -> String {
        var parts = ["Answer \(label)", answerText]
        if selectedSourceIndex != nil {
            if shuffledAnswer.isCorrect {
                parts.append("correct answer")
            } else if isSelected {
                parts.append("your selected answer, incorrect")
            }
        }
        return parts.joined(separator: ", ")
    }
}
