import Accessibility
import SwiftUI

struct PracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    let showsLanguagePicker: Bool
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
        .safeAreaInset(edge: .bottom) {
            controls
                .padding(.horizontal)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
        }
        .navigationTitle(category.name.text(for: language))
        .toolbar {
            if showsLanguagePicker {
                languageToolbarItem
            }
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
                .fixedSize(horizontal: false, vertical: true)
            Text("Random practice from \(category.questionCount) official Basic questions.")
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Session tally: \(correctCount) correct out of \(answeredCount) answered")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Session tally, \(correctCount) correct out of \(answeredCount) answered")
        }
    }

    private func questionCard(_ question: BankQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.id)
                .font(.body.monospaced())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Question identifier \(question.id)")
            Text(question.text.text(for: language))
                .font(.title2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
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
                    .font(.headline.monospaced().bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: answerLetterMinWidth, minHeight: answerLetterMinWidth, alignment: .center)
                    .padding(6)
                    .background(.black, in: Circle())
                    .accessibilityHidden(true)

                Text(answerText)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isAnswered {
                    if shuffledAnswer.isCorrect {
                        Label("Correct answer", systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.primary)
                    } else if isSelected {
                        Label("Your answer", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .foregroundStyle(.primary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(answerBackground(for: shuffledAnswer, isSelected: isSelected), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(isAnswered ? "Question already answered; choose Next question to continue" : "Selects this answer")
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
                        .foregroundStyle(.primary)
                } else {
                    Label("Incorrect", systemImage: "xmark.circle.fill")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text("Correct answer: \(correctAnswer.answer.text.text(for: language))")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(feedbackAccessibilityLabel(selectedAnswer: selectedAnswer, correctAnswer: correctAnswer))
            .accessibilityIdentifier("answer-feedback")
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
        VStack(alignment: .leading, spacing: 8) {
            Button("Next question") {
                loadNextQuestion()
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .disabled(selectedSourceIndex == nil)
            .accessibilityHint("Loads another random question from this category")

            if selectedSourceIndex == nil {
                Text("Choose an answer to continue.")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
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
        Color.clear
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

    private func feedbackAccessibilityLabel(selectedAnswer: ShuffledAnswer, correctAnswer: ShuffledAnswer) -> String {
        if selectedAnswer.isCorrect {
            return "Correct"
        }

        return "Incorrect. Correct answer: \(correctAnswer.answer.text.text(for: language))"
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
