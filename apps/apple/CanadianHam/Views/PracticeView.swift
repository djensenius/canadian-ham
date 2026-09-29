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
        .onAppear {
            if currentQuestion == nil {
                loadNextQuestion()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(category.name.text(for: language))
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("practice-category-title")
            Text("Random practice from \(category.questionCount) official Basic questions.")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("practice-category-summary")
            Text("Session tally: \(correctCount) correct out of \(answeredCount) answered")
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Session tally, \(correctCount) correct out of \(answeredCount) answered")
                .accessibilityIdentifier("practice-session-tally")
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Question identifier \(question.id)")
            Text(question.text.text(for: language))
                .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .environment(\.locale, Locale(identifier: language.accessibilityLanguageCode))
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("answer-list-title")
            ForEach(shuffledAnswers) { shuffledAnswer in
                answerButton(for: shuffledAnswer)
                if selectedSourceIndex == shuffledAnswer.sourceIndex {
                    feedback
                    controls
                }
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
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
                Text(label)
                    .font(.headline.monospaced().bold())
                    .foregroundStyle(state.chipForeground)
                    .frame(minWidth: answerLetterMinWidth, minHeight: answerLetterMinWidth, alignment: .center)
                    .padding(DesignTokens.Spacing.xs)
                    .background(state.chipBackground, in: Circle())
                    .accessibilityIdentifier("answer-\(label)-letter-chip")

                Text(answerText)
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(state.textColor)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.locale, Locale(identifier: language.accessibilityLanguageCode))
                    .accessibilityIdentifier("answer-\(label)-text")

                if let iconName = state.iconName, let statusText = state.statusText {
                    Label(statusText, systemImage: iconName)
                        .font(DesignTokens.FontScale.caption.weight(.bold))
                        .foregroundStyle(state.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .labelStyle(.titleAndIcon)
                        .accessibilityIdentifier("answer-\(label)-status")
                }
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
        .disabled(isAnswered)
        .accessibilityElement(children: .ignore)
        .accessibilityHint(isAnswered ? "Question already answered; choose Next question to continue" : "Selects this answer")
        .accessibilityLabel(answerAccessibilityLabel(label: label, answerText: answerText, shuffledAnswer: shuffledAnswer, isSelected: isSelected))
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
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .foregroundStyle(correct ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("answer-feedback-title")

                if !correct {
                    Text("Correct answer: \(correctAnswer.answer.text.text(for: language))")
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.incorrectText)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .environment(\.locale, Locale(identifier: language.accessibilityLanguageCode))
                        .accessibilityIdentifier("answer-feedback-correct-answer")
                }

                Text("Source: \(category.name.text(for: language)) • \(currentQuestion?.subsectionId ?? "")")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(correct ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("answer-feedback-source")
            }
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(correct ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(correct ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(feedbackAccessibilityLabel(selectedAnswer: selectedAnswer, correctAnswer: correctAnswer))
            .accessibilityIdentifier("answer-feedback")
        }
    }

    private func messagePanel(title: String, systemImage: String, message: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(title)
                    .font(DesignTokens.FontScale.title.weight(.bold))
                Text(message)
                    .font(DesignTokens.FontScale.body)
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
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(selectedSourceIndex == nil ? DesignTokens.Colors.inkMuted : DesignTokens.Colors.paper)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity)
                    .background(selectedSourceIndex == nil ? DesignTokens.Colors.paperInset : DesignTokens.Colors.accent, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(selectedSourceIndex == nil ? DesignTokens.Colors.border : DesignTokens.Colors.accentStrong, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedSourceIndex == nil)
            .accessibilityHint("Loads another random question from this category")
            .accessibilityIdentifier("next-question-button")

            if selectedSourceIndex == nil {
                Text("Choose an answer to continue.")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
        let question = (try? AppleQuestionShuffle.randomQuestion(from: categoryQuestions, seed: questionSeed)) ?? categoryQuestions.first
        guard let question else {
            currentQuestion = nil
            shuffledAnswers = []
            selectedSourceIndex = nil
            return
        }

        let answerSeed = "practice-answers/\(question.id)/\(answeredCount)/\(UUID().uuidString)"
        do {
            currentQuestion = question
            shuffledAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: answerSeed)
            selectedSourceIndex = nil
            loadError = nil
        } catch {
            currentQuestion = nil
            shuffledAnswers = []
            selectedSourceIndex = nil
            loadError = "Unable to shuffle this question with the shared engine: \(error.localizedDescription)"
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
                chipBackground: DesignTokens.Colors.correctText,
                chipForeground: DesignTokens.Colors.correctBg,
                iconName: "checkmark.circle.fill",
                statusText: "Correct answer",
                isSemantic: true
            )
        }

        if isSelected {
            return AnswerVisualState(
                background: DesignTokens.Colors.incorrectBg,
                border: DesignTokens.Colors.incorrectBorder,
                textColor: DesignTokens.Colors.incorrectText,
                chipBackground: DesignTokens.Colors.incorrectText,
                chipForeground: DesignTokens.Colors.incorrectBg,
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

    private func feedbackAccessibilityLabel(selectedAnswer: ShuffledAnswer, correctAnswer: ShuffledAnswer) -> String {
        if selectedAnswer.isCorrect {
            return "Correct. Source: \(category.name.text(for: language)), \(currentQuestion?.subsectionId ?? "")"
        }

        return "Incorrect. Correct answer: \(correctAnswer.answer.text.text(for: language)). Source: \(category.name.text(for: language)), \(currentQuestion?.subsectionId ?? "")"
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
