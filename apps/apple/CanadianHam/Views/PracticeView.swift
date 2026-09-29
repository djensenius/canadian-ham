import Accessibility
import Foundation
import SwiftUI

struct PracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    let showsLanguagePicker: Bool
    @Binding var language: BankLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .headline) private var answerLetterMinWidth = 34
    @ScaledMetric(relativeTo: .body) private var cardPadding = DesignTokens.Spacing.lg

    @State private var currentQuestion: BankQuestion?
    @State private var shuffledAnswers: [ShuffledAnswer] = []
    @State private var selectedSourceIndex: Int?
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var loadError: String?

    private var categoryQuestions: [BankQuestion] {
        bank.questions(in: category)
    }

    private var selectedAnswer: ShuffledAnswer? {
        guard let selectedSourceIndex else { return nil }
        return shuffledAnswers.first { $0.sourceIndex == selectedSourceIndex }
    }

    private var correctAnswer: ShuffledAnswer? {
        AppleQuestionShuffle.correctAnswer(in: shuffledAnswers)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header

                if let loadError {
                    messagePanel(title: "Practice unavailable", systemImage: "exclamationmark.triangle.fill", message: loadError)
                } else if let currentQuestion {
                    questionCard(currentQuestion)
                    answerList
                } else {
                    ContentUnavailableView(
                        "No questions found",
                        systemImage: "questionmark.circle",
                        description: Text("This category has no bundled questions.")
                    )
                    .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(category.name.text(for: language))
        .toolbar {
            if showsLanguagePicker {
                languageToolbarItem
            }
        }
#if os(iOS)
        .toolbarBackground(DesignTokens.Colors.paper, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
#endif
        .onAppear {
            if currentQuestion == nil {
                loadNextQuestion()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(category.name.text(for: language))
                .font(.title.bold())
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("Random practice from \(category.questionCount) official Basic questions.")
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text("Session tally: \(correctCount) correct out of \(answeredCount) answered")
                .font(.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(headerAccessibilityLabel())
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
        )
    }

    private func questionCard(_ question: BankQuestion) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(question.id)
                .font(.body.monospaced())
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .accessibilityLabel("Question identifier \(question.id)")
            Text(localizedAttributedString(question.text.text(for: language)))
                .font(.title3.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .textSelection(.enabled)
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(questionAccessibilityLabel(question)))
        .accessibilityIdentifier("question-stem")
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
        )
        .accessibilityIdentifier("question-card")
    }

    private var answerList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Answers")
                .font(.title2.bold())
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityHidden(true)
            ForEach(shuffledAnswers) { shuffledAnswer in
                answerButton(for: shuffledAnswer)
            }
            if selectedSourceIndex != nil {
                feedback
                controls
            }
        }
    }

    private func answerButton(for shuffledAnswer: ShuffledAnswer) -> some View {
        let isSelected = selectedSourceIndex == shuffledAnswer.sourceIndex
        let isAnswered = selectedSourceIndex != nil
        let label = answerLetter(for: shuffledAnswer.displayIndex)
        let answerText = shuffledAnswer.answer.text.text(for: language)
        let state = answerState(for: shuffledAnswer, isSelected: isSelected)

        return Button {
            select(shuffledAnswer)
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(label)
                    .font(.headline.monospaced().bold())
                    .foregroundStyle(state.chipForeground)
                    .frame(minWidth: answerLetterMinWidth, minHeight: answerLetterMinWidth, alignment: .center)
                    .padding(DesignTokens.Spacing.xs)
                    .background(state.chipBackground, in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(localizedAttributedString(answerText))
                        .font(.body)
                        .foregroundStyle(state.textColor)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityHidden(true)

                    if let iconName = state.iconName, let statusText = state.statusText {
                        Label(statusText, systemImage: iconName)
                            .font(.caption.bold())
                            .foregroundStyle(state.textColor)
                            .labelStyle(.titleAndIcon)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(state.background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(state.border, lineWidth: isSelected || state.isSemantic ? 2 : 1)
            )
            .accessibilityElement(children: .ignore)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isAnswered ? "Question answered" : "Not answered")
        .accessibilityHint(isAnswered ? "Question already answered; this answer cannot be changed. Choose Next question to continue." : "Selects this answer")
        .accessibilityLabel(Text(answerAccessibilityLabel(label: label, answerText: answerText, shuffledAnswer: shuffledAnswer, isSelected: isSelected)))
        .accessibilityIdentifier("answer-\(label)-button")
    }

    @ViewBuilder
    private var feedback: some View {
        if let selectedAnswer, let correctAnswer {
            let correct = selectedAnswer.isCorrect
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .accessibilityHidden(true)
                    Text(correct ? "Correct" : "Incorrect")
                        .font(.body.bold())
                        .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .foregroundStyle(correct ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                .accessibilityHidden(true)

                if !correct {
                    Text(correctAnswerFeedbackText(correctAnswer.answer.text.text(for: language)))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.incorrectText)
                        .textSelection(.enabled)
                        .accessibilityHidden(true)
                }

                Text("Source: \(category.name.text(for: language)) • \(currentQuestion?.subsectionId ?? "")")
                    .font(.caption)
                    .foregroundStyle(correct ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                    .accessibilityHidden(true)
            }
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(correct ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(correct ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(feedbackAccessibilityLabel(selectedAnswer: selectedAnswer, correctAnswer: correctAnswer)))
            .accessibilityIdentifier("answer-feedback")
        }
    }

    private func messagePanel(title: String, systemImage: String, message: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(.title2.bold())
                Text(message)
                    .font(.body)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(DesignTokens.Colors.warningText)
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.warningBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .strokeBorder(DesignTokens.Colors.warningBorder, lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Button {
                loadNextQuestion()
            } label: {
                Text("Next question")
                    .font(.body.bold())
                    .foregroundStyle(DesignTokens.Colors.paper)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity)
                    .background(DesignTokens.Colors.accent, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(DesignTokens.Colors.accentStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Loads another random question from this category")
            .accessibilityIdentifier("next-question-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func select(_ answer: ShuffledAnswer) {
        guard selectedSourceIndex == nil else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            selectedSourceIndex = answer.sourceIndex
        }
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

        let questionSeed = "practice-question/\(category.id)/\(answeredCount)/\(UUID().uuidString)"
        do {
            guard let question = try AppleQuestionShuffle.randomQuestion(from: categoryQuestions, seed: questionSeed) else {
                currentQuestion = nil
                shuffledAnswers = []
                selectedSourceIndex = nil
                return
            }

            let answerSeed = "practice-answers/\(question.id)/\(answeredCount)/\(UUID().uuidString)"
            currentQuestion = question
            shuffledAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: answerSeed)
            selectedSourceIndex = nil
            loadError = nil
        } catch {
            currentQuestion = nil
            shuffledAnswers = []
            selectedSourceIndex = nil
            loadError = "Unable to prepare this question with the shared engine: \(error.localizedDescription)"
        }
    }

    private func answerLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D"]
        guard letters.indices.contains(index) else { return "\(index + 1)" }
        return letters[index]
    }

    private func answerState(for shuffledAnswer: ShuffledAnswer, isSelected: Bool) -> AnswerVisualState {
        guard selectedSourceIndex != nil else {
            return AnswerVisualState(
                background: DesignTokens.Colors.paperElevated,
                border: DesignTokens.Colors.border,
                textColor: DesignTokens.Colors.ink,
                chipBackground: DesignTokens.Colors.paperInset,
                chipForeground: DesignTokens.Colors.ink,
                iconName: nil,
                statusText: nil,
                isSemantic: false
            )
        }

        if shuffledAnswer.isCorrect {
            return AnswerVisualState(
                background: DesignTokens.Colors.correctBg,
                border: DesignTokens.Colors.correctBorder,
                textColor: DesignTokens.Colors.correctText,
                chipBackground: DesignTokens.Colors.correctBg,
                chipForeground: DesignTokens.Colors.correctText,
                iconName: "checkmark.circle.fill",
                statusText: isSelected ? "Your answer, correct answer" : "Correct answer",
                isSemantic: true
            )
        }

        if isSelected {
            return AnswerVisualState(
                background: DesignTokens.Colors.incorrectBg,
                border: DesignTokens.Colors.incorrectBorder,
                textColor: DesignTokens.Colors.incorrectText,
                chipBackground: DesignTokens.Colors.incorrectBg,
                chipForeground: DesignTokens.Colors.incorrectText,
                iconName: "xmark.circle.fill",
                statusText: "Your answer",
                isSemantic: true
            )
        }

        return AnswerVisualState(
            background: DesignTokens.Colors.paperInset,
            border: DesignTokens.Colors.border,
            textColor: DesignTokens.Colors.ink,
            chipBackground: DesignTokens.Colors.paperElevated,
            chipForeground: DesignTokens.Colors.ink,
            iconName: nil,
            statusText: nil,
            isSemantic: false
        )
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

    private func headerAccessibilityLabel() -> String {
        "\(category.name.text(for: language)). Random practice from \(category.questionCount) official Basic questions. Session tally: \(correctCount) correct out of \(answeredCount) answered."
    }

    private func questionAccessibilityLabel(_ question: BankQuestion) -> AttributedString {
        var label = englishAttributedString("Question identifier \(question.id). ")
        label += localizedAttributedString(question.text.text(for: language))
        return label
    }

    private func feedbackAccessibilityLabel(selectedAnswer: ShuffledAnswer, correctAnswer: ShuffledAnswer) -> AttributedString {
        if selectedAnswer.isCorrect {
            var label = englishAttributedString("Correct. Your answer: ")
            label += localizedAttributedString(selectedAnswer.answer.text.text(for: language))
            label += englishAttributedString(". Source: \(category.name.text(for: language)), \(currentQuestion?.subsectionId ?? "")")
            return label
        }

        var label = englishAttributedString("Incorrect. Correct answer: ")
        label += localizedAttributedString(correctAnswer.answer.text.text(for: language))
        label += englishAttributedString(". Source: \(category.name.text(for: language)), \(currentQuestion?.subsectionId ?? "")")
        return label
    }

    private func answerAccessibilityLabel(
        label: String,
        answerText: String,
        shuffledAnswer: ShuffledAnswer,
        isSelected: Bool
    ) -> AttributedString {
        var accessibilityLabel = englishAttributedString("Answer \(label), ")
        accessibilityLabel += localizedAttributedString(answerText)

        if selectedSourceIndex != nil {
            if isSelected {
                accessibilityLabel += englishAttributedString(", your answer")
            }
            if shuffledAnswer.isCorrect {
                accessibilityLabel += englishAttributedString(", correct answer")
            } else if isSelected {
                accessibilityLabel += englishAttributedString(", incorrect")
            }
        }

        return accessibilityLabel
    }

    private func correctAnswerFeedbackText(_ answerText: String) -> AttributedString {
        var text = englishAttributedString("Correct answer: ")
        text += localizedAttributedString(answerText)
        return text
    }

    private func localizedAttributedString(_ string: String) -> AttributedString {
        var attributedString = AttributedString(string)
        attributedString.languageIdentifier = language.accessibilityLanguageCode
        return attributedString
    }

    private func englishAttributedString(_ string: String) -> AttributedString {
        var attributedString = AttributedString(string)
        attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
        return attributedString
    }
}

private struct AnswerVisualState {
    let background: Color
    let border: Color
    let textColor: Color
    let chipBackground: Color
    let chipForeground: Color
    let iconName: String?
    let statusText: String?
    let isSemantic: Bool
}
