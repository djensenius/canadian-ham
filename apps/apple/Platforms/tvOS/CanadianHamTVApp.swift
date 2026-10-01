import Accessibility
import SwiftUI

@main
struct CanadianHamTVApp: App {
    private let launchOptions = TVLaunchOptions()

    var body: some Scene {
        WindowGroup {
            CanadianHamTVRootView(launchOptions: launchOptions)
                .preferredColorScheme(launchOptions.colorScheme)
        }
    }
}

private struct TVLaunchOptions {
    let initialScreen: PlatformScreen
    let initialCategoryID: String
    let practiceQuestionID: String?
    let answeredSourceIndex: Int?
    let colorScheme: ColorScheme?
    let initialLanguage: BankLanguage

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        initialScreen = PlatformScreen(rawValue: AppLaunchArguments.value(after: "-CanadianHamPlatformInitialScreen", in: arguments) ?? "categories") ?? .categories
        initialCategoryID = AppLaunchArguments.value(after: "-CanadianHamPlatformCategoryID", in: arguments) ?? "B-001"
        practiceQuestionID = AppLaunchArguments.value(after: "-CanadianHamPlatformQuestionID", in: arguments)
        answeredSourceIndex = AppLaunchArguments.value(after: "-CanadianHamPlatformAnsweredSourceIndex", in: arguments).flatMap(Int.init)
        switch AppLaunchArguments.value(after: "-CanadianHamAppearance", in: arguments) {
        case "light": colorScheme = .light
        case "dark": colorScheme = .dark
        default: colorScheme = nil
        }
        initialLanguage = BankLanguage(rawValue: AppLaunchArguments.value(after: "-CanadianHamLanguage", in: arguments) ?? "en") ?? .english
    }
}

private enum PlatformScreen: String {
    case categories
    case practice
    case about
}

private struct CanadianHamTVRootView: View {
    let launchOptions: TVLaunchOptions

    @State private var bank: QuestionBank?
    @State private var loadError: String?
    @State private var screen: PlatformScreen
    @State private var selectedCategoryID: String
    @State private var language: BankLanguage
    @State private var practiceSession = TVPracticeSessionState()

    init(launchOptions: TVLaunchOptions) {
        self.launchOptions = launchOptions
        _screen = State(initialValue: launchOptions.initialScreen)
        _selectedCategoryID = State(initialValue: launchOptions.initialCategoryID)
        _language = State(initialValue: launchOptions.initialLanguage)
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.paper.ignoresSafeArea()

            if let bank {
                content(for: bank)
                    .padding(.horizontal, DesignTokens.Spacing.tvSafe)
                    .padding(.vertical, DesignTokens.Spacing.xxl)
            } else if let loadError {
                TVMessageView(
                    title: "Question bank unavailable",
                    message: loadError,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .padding(DesignTokens.Spacing.tvSafe)
            } else {
                ProgressView("Loading question bank…")
                    .controlSize(.large)
                    .font(DesignTokens.FontScale.title)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityLabel("Loading question bank")
            }
        }
        .task { loadBankIfNeeded() }
    }

    @ViewBuilder
    private func content(for bank: QuestionBank) -> some View {
        switch screen {
        case .categories:
            TVCategoryGridView(
                bank: bank,
                language: $language,
                onSelectCategory: { category in
                    if selectedCategoryID != category.id {
                        practiceSession.reset(for: category.id)
                    }
                    selectedCategoryID = category.id
                    screen = .practice
                },
                onAbout: { screen = .about }
            )
        case .practice:
            if let category = bank.categories.first(where: { $0.id == selectedCategoryID }) ?? bank.categories.first {
                TVPracticeView(
                    bank: bank,
                    category: category,
                    forcedQuestionID: launchOptions.practiceQuestionID,
                    answeredSourceIndex: launchOptions.answeredSourceIndex,
                    language: $language,
                    session: $practiceSession,
                    onCategories: { screen = .categories },
                    onAbout: { screen = .about }
                )
                .onExitCommand { screen = .categories }
            } else {
                TVMessageView(title: "No categories", message: String(localized: "The bundled question bank has no practice categories."), systemImage: "questionmark.folder")
            }
        case .about:
            TVAboutView(bank: bank, onCategories: { screen = .categories })
                .onExitCommand { screen = .categories }
        }
    }

    private func loadBankIfNeeded() {
        guard bank == nil, loadError == nil else { return }
        do {
            bank = try QuestionBankStore.load()
        } catch {
            loadError = localizedErrorMessage(String(localized: "Unable to load question bank: \("")"), detail: error)
        }
    }
}

private struct TVCategoryGridView: View {
    let bank: QuestionBank
    @Binding var language: BankLanguage
    let onSelectCategory: (BankCategory) -> Void
    let onAbout: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xl), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                TVTopBar(title: AttributedString("Canadian Ham"), subtitle: Text("Offline Basic question-bank practice"), language: $language, onAbout: onAbout)

                Text("Practice categories")
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    ForEach(bank.categories) { category in
                        TVCategoryButton(category: category, language: language) {
                            onSelectCategory(category)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("tv-category-grid")
    }
}

private struct TVCategoryButton: View {
    let category: BankCategory
    let language: BankLanguage
    let action: () -> Void

    @FocusState private var isFocused: Bool

    private var categoryAccessibilityLabel: AttributedString {
        var label = localized(category.name.text(for: language), language: language)
        label += AttributedString(", \(localizedQuestionCount(category.questionCount)), \(localizedSubsectionCount(category.subsectionCount))")
        return label
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(category.id) // l10n: verbatim
                    .font(DesignTokens.FontScale.caption.monospaced().weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text(localized(category.name.text(for: language), language: language)) // l10n: content(question)
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(verbatim: "\(localizedQuestionCount(category.questionCount)) • \(localizedSubsectionCount(category.subsectionCount))") // l10n: verbatim
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .strokeBorder(isFocused ? DesignTokens.Colors.focus : DesignTokens.Colors.border, lineWidth: isFocused ? 6 : 2)
            )
            .scaleEffect(isFocused ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .accessibilityLabel(Text(categoryAccessibilityLabel)) // l10n: content(question)
        .accessibilityHint(Text("Starts practice for this category")) // l10n: localized
    }
}

private struct TVPracticeSessionState {
    var categoryID: String?
    var sessionID = UUID().uuidString
    var currentQuestion: BankQuestion?
    var shuffledAnswers: [ShuffledAnswer] = []
    var selectedSourceIndex: Int?
    var answeredCount = 0
    var correctCount = 0
    var errorMessage: String?

    mutating func reset(for categoryID: String) {
        self.categoryID = categoryID
        sessionID = UUID().uuidString
        currentQuestion = nil
        shuffledAnswers = []
        selectedSourceIndex = nil
        answeredCount = 0
        correctCount = 0
        errorMessage = nil
    }

    mutating func resetIfNeeded(for categoryID: String) {
        if self.categoryID != categoryID {
            reset(for: categoryID)
        }
    }
}

private struct TVPracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    let forcedQuestionID: String?
    let answeredSourceIndex: Int?
    @Binding var language: BankLanguage
    @Binding var session: TVPracticeSessionState
    let onCategories: () -> Void
    let onAbout: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedAnswer: ShuffledAnswer? {
        guard let selectedSourceIndex = session.selectedSourceIndex else { return nil }
        return session.shuffledAnswers.first { $0.sourceIndex == selectedSourceIndex }
    }

    private var correctAnswer: ShuffledAnswer? {
        AppleQuestionShuffle.correctAnswer(in: session.shuffledAnswers)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    TVTopBar(
                        title: localized(category.name.text(for: language), language: language),
                        subtitle: Text(localizedCorrectOutOfAnswered(correct: session.correctCount, answered: session.answeredCount)), // l10n: localized
                        language: $language,
                        onAbout: onAbout,
                        leadingAction: ("Categories", onCategories)
                    )

                    if let errorMessage = session.errorMessage {
                        TVMessageView(title: "Practice unavailable", message: errorMessage, systemImage: "exclamationmark.triangle.fill")
                    } else if let currentQuestion = session.currentQuestion {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.xxl) {
                            TVQuestionPanel(question: currentQuestion, category: category, language: language)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                Text("Answers")
                                    .font(DesignTokens.FontScale.title.weight(.bold))
                                    .foregroundStyle(DesignTokens.Colors.ink)
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(session.shuffledAnswers) { answer in
                                    TVAnswerButton(
                                        answer: answer,
                                        displayLetter: displayLetter(for: answer.displayIndex),
                                        language: language,
                                        selectedSourceIndex: session.selectedSourceIndex,
                                        action: { select(answer) }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let selectedAnswer, let correctAnswer {
                            TVFeedbackBar(
                                selectedAnswer: selectedAnswer,
                                correctAnswer: correctAnswer,
                                category: category,
                                question: currentQuestion,
                                language: language,
                                onNext: loadNextQuestion
                            )
                            .id(Self.feedbackAnchorID)
                        }
                    } else {
                        TVMessageView(title: "No questions", message: String(localized: "This category has no bundled questions."), systemImage: "questionmark.circle")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .onChange(of: session.selectedSourceIndex) { _, selectedSourceIndex in
                guard selectedSourceIndex != nil else { return }
                scrollFeedbackIntoView(with: scrollProxy)
            }
        }
        .onAppear {
            session.resetIfNeeded(for: category.id)
            if session.currentQuestion == nil {
                loadNextQuestion()
            }
        }
        .accessibilityIdentifier("tv-practice-screen")
    }

    private static let feedbackAnchorID = "tv-feedback-anchor"

    private func scrollFeedbackIntoView(with proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
                proxy.scrollTo(Self.feedbackAnchorID, anchor: .bottom)
            }
        }
    }

    private func select(_ answer: ShuffledAnswer) {
        guard session.selectedSourceIndex == nil else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            session.selectedSourceIndex = answer.sourceIndex
        }
        session.answeredCount += 1
        if answer.isCorrect { session.correctCount += 1 }
        let announcement = answer.isCorrect ? String(localized: "Correct") : String(localized: "Incorrect")
        AccessibilityNotification.Announcement(announcement).post()
    }

    private func loadNextQuestion() {
        let questions = bank.questions(in: category)
        guard !questions.isEmpty else {
            session.currentQuestion = nil
            session.shuffledAnswers = []
            session.selectedSourceIndex = nil
            return
        }

        let requestedQuestionID = session.answeredCount == 0 ? forcedQuestionID : nil
        do {
            let question: BankQuestion
            let usedForcedQuestion: Bool
            if let requestedQuestionID, let forced = questions.first(where: { $0.id == requestedQuestionID }) {
                question = forced
                usedForcedQuestion = true
            } else {
                question = try AppleQuestionShuffle.randomQuestion(from: questions, seed: "tvos-practice/\(category.id)/\(session.answeredCount)/\(session.sessionID)") ?? questions[0]
                usedForcedQuestion = false
            }
            session.currentQuestion = question
            let answerSeed = usedForcedQuestion ? "tvos-answers/\(question.id)/ui-test" : "tvos-answers/\(question.id)/\(session.answeredCount)/\(session.sessionID)"
            session.shuffledAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: answerSeed)
            if session.answeredCount == 0, let answeredSourceIndex {
                session.selectedSourceIndex = answeredSourceIndex
                session.answeredCount = 1
                if question.answers.first(where: { $0.sourceIndex == answeredSourceIndex })?.isCorrect == true {
                    session.correctCount = 1
                }
            } else {
                session.selectedSourceIndex = nil
            }
            session.errorMessage = nil
        } catch {
            session.errorMessage = localizedErrorMessage(String(localized: "Unable to prepare this question: \("")"), detail: error)
        }
    }

    private func displayLetter(for index: Int) -> String {
        ["A", "B", "C", "D"].indices.contains(index) ? ["A", "B", "C", "D"][index] : "\(index + 1)"
    }
}

private struct TVQuestionPanel: View {
    let question: BankQuestion
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text(question.id) // l10n: verbatim
                .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(question.text.text(for: language), language: language)) // l10n: content(question)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("question-stem")
            Text(sourceText) // l10n: content(question)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 390, alignment: .topLeading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel)) // l10n: content(question)
    }

    private var sourceText: AttributedString {
        var text = AttributedString(String(localized: "Source: "))
        text += localized(category.name.text(for: language), language: language)
        text += english(" • \(question.subsectionId)")
        return text
    }

    private var accessibilityLabel: AttributedString {
        var label = english("Question \(question.id). ")
        label += localized(question.text.text(for: language), language: language)
        return label
    }
}

private struct TVAnswerButton: View {
    let answer: ShuffledAnswer
    let displayLetter: String
    let language: BankLanguage
    let selectedSourceIndex: Int?
    let action: () -> Void

    @FocusState private var isFocused: Bool

    private var isSelected: Bool { selectedSourceIndex == answer.sourceIndex }
    private var isAnswered: Bool { selectedSourceIndex != nil }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.lg) {
                Text(displayLetter) // l10n: verbatim
                    .font(DesignTokens.FontScale.title.monospaced().weight(.bold))
                    .frame(width: 54, height: 54)
                    .foregroundStyle(chipForeground)
                    .background(chipBackground, in: Circle())
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized(answer.answer.text.text(for: language), language: language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                        .foregroundStyle(textColor)
                        .accessibilityIdentifier("answer-\(displayLetter)-text")
                    if let statusText {
                        Label {
                            Text(localizedStatusText(statusText)) // l10n: localized
                        } icon: {
                            Image(systemName: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        }
                        .font(DesignTokens.FontScale.caption.weight(.bold))
                        .foregroundStyle(textColor)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 106, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(isFocused ? DesignTokens.Colors.focus : border, lineWidth: isFocused ? 6 : (isSelected || semantic ? 4 : 2))
            )
            .scaleEffect(isFocused ? 1.025 : 1)
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .disabled(isAnswered)
        .accessibilityLabel(Text(accessibilityLabel)) // l10n: content(question)
        .accessibilityIdentifier("answer-\(displayLetter)-button")
        .accessibilityHint(isAnswered ? Text("Question already answered. Use Next question to continue.") : Text("Selects this answer")) // l10n: localized
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var semantic: Bool { isAnswered && (answer.isCorrect || isSelected) }
    private var background: Color {
        guard isAnswered else { return DesignTokens.Colors.paperElevated }
        if answer.isCorrect { return DesignTokens.Colors.correctBg }
        if isSelected { return DesignTokens.Colors.incorrectBg }
        return DesignTokens.Colors.paperInset
    }
    private var border: Color {
        guard isAnswered else { return DesignTokens.Colors.border }
        if answer.isCorrect { return DesignTokens.Colors.correctBorder }
        if isSelected { return DesignTokens.Colors.incorrectBorder }
        return DesignTokens.Colors.border
    }
    private var textColor: Color {
        guard isAnswered else { return DesignTokens.Colors.ink }
        if answer.isCorrect { return DesignTokens.Colors.correctText }
        if isSelected { return DesignTokens.Colors.incorrectText }
        return DesignTokens.Colors.ink
    }
    private var chipBackground: Color { textColor }
    private var chipForeground: Color { isAnswered ? background : DesignTokens.Colors.paperElevated }
    private var statusText: String? {
        guard isAnswered else { return nil }
        if answer.isCorrect { return isSelected ? "Your answer, correct answer" : "Correct answer" }
        if isSelected { return "Your answer, incorrect" }
        return nil
    }
    private var accessibilityLabel: AttributedString {
        var label = AttributedString(String(localized: "Answer \(displayLetter), "))
        label += localized(answer.answer.text.text(for: language), language: language)
        if let statusText {
            label += AttributedString(String(localized: ", \(localizedStatusText(statusText))"))
        }
        return label
    }

    private func localizedStatusText(_ statusText: String) -> String {
        switch statusText {
        case "Your answer, correct answer": String(localized: "Your answer, correct answer")
        case "Correct answer": String(localized: "Correct answer")
        case "Your answer, incorrect": String(localized: "Your answer, incorrect")
        default: statusText
        }
    }
}

private struct TVPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? DesignTokens.Colors.paper : DesignTokens.Colors.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .frame(minHeight: 72)
            .background(isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.paperInset, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isFocused ? DesignTokens.Colors.focus : isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.inkMuted,
                        style: StrokeStyle(lineWidth: isFocused ? 6 : 2, dash: isEnabled ? [] : [6, 5])
                    )
            }
            .contentShape(Capsule())
            .scaleEffect(isFocused ? 1.04 : (configuration.isPressed ? 0.97 : 1))
    }
}

private struct TVFeedbackBar: View {
    let selectedAnswer: ShuffledAnswer
    let correctAnswer: ShuffledAnswer
    let category: BankCategory
    let question: BankQuestion
    let language: BankLanguage
    let onNext: () -> Void

    @FocusState private var isNextQuestionFocused: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            HStack(spacing: DesignTokens.Spacing.xl) {
                Label {
                    Text(resultText) // l10n: localized
                } icon: {
                    Image(systemName: selectedAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                }
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                Text(sourceText) // l10n: content(question)
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityLabel)) // l10n: content(question)
            .accessibilityIdentifier("answer-feedback")

            Spacer()

            Button("Next question", action: onNext)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(TVPrimaryButtonStyle())
                .focused($isNextQuestionFocused)
                .accessibilityHint(Text("Loads another question from this category")) // l10n: localized
                .accessibilityIdentifier("next-question-button")
        }
        .padding(DesignTokens.Spacing.xl)
        .background(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 3)
        )
        .onAppear {
            isNextQuestionFocused = true
        }
    }

    private var resultText: String {
        selectedAnswer.isCorrect ? String(localized: "Correct") : String(localized: "Incorrect")
    }
    private var sourceText: AttributedString {
        if selectedAnswer.isCorrect {
            var text = AttributedString(String(localized: "Source: "))
            text += localized(category.name.text(for: language), language: language)
            text += english(" • \(question.subsectionId)")
            return text
        }

        var text = AttributedString(String(localized: "Correct answer: "))
        text += localized(correctAnswer.answer.text.text(for: language), language: language)
        return text
    }

    private var accessibilityLabel: AttributedString {
        if selectedAnswer.isCorrect {
            var label = AttributedString(String(localized: "Correct. Your answer: "))
            label += localized(selectedAnswer.answer.text.text(for: language), language: language)
            label += AttributedString(String(localized: ". Source: "))
            label += localized(category.name.text(for: language), language: language)
            label += english(", \(question.subsectionId)")
            return label
        }

        var label = AttributedString(String(localized: "Incorrect. Correct answer: "))
        label += localized(correctAnswer.answer.text.text(for: language), language: language)
        label += AttributedString(String(localized: ". Source: "))
        label += localized(category.name.text(for: language), language: language)
        label += english(", \(question.subsectionId)")
        return label
    }
}

private struct TVTopBar: View {
    let title: AttributedString
    let subtitle: Text
    @Binding var language: BankLanguage
    let onAbout: () -> Void
    var leadingAction: (title: LocalizedStringKey, action: () -> Void)? = nil

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            if let leadingAction {
                Button(leadingAction.title, action: leadingAction.action) // l10n: localized
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .buttonStyle(.bordered)
                    .accessibilityHint(Text("Returns to the category grid")) // l10n: localized
            }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title) // l10n: content(question)
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                subtitle
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            Spacer()
            Picker("Question language", selection: $language) {
                ForEach(BankLanguage.allCases) { language in
                    switch language {
                    case .english:
                        Text(localized(language.displayName, language: .english)).tag(language) // l10n: content(en)
                    case .french:
                        Text(localized(language.displayName, language: .french)).tag(language) // l10n: content(fr)
                    }
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 420)
            .accessibilityLabel(Text("Question language")) // l10n: localized
            .accessibilityIdentifier("question-language-picker")
            Button("About", action: onAbout)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(.bordered)
                .accessibilityLabel(Text("About Canadian Ham")) // l10n: localized
        }
    }
}

private struct TVAboutView: View {
    let bank: QuestionBank
    let onCategories: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack {
                    Button("Categories", action: onCategories)
                        .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                        .buttonStyle(.bordered)
                    Spacer()
                }

                Text("About Canadian Ham")
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                    TVPaperSection(title: "Bank") {
                        Text("Active bank: \(bank.manifest.bankId)")
                        Text("Effective date: \(bank.manifest.effectiveDate)")
                        Text("Questions: \(bank.questions.count) • Categories: \(bank.categories.count) • Subsections: \(bank.subsections.count)") // l10n: localized
                    }
                    TVPaperSection(title: "Attribution") {
                        Text(english("Question-bank material is sourced from Innovation, Science and Economic Development Canada Amateur Radio Operator Certificate Basic Qualification materials.")) // l10n: content(en)
                        Text(english("Canadian Ham is independent and not affiliated with, sponsored by, or endorsed by ISED, RAC, or any accredited examiner.")) // l10n: content(en)
                    }
                    TVPaperSection(title: "Privacy") {
                        Text("This tvOS app works offline with bundled content, includes no networking code, no analytics, no telemetry, and no iCloud sync.")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("tv-about-screen")
    }
}

private struct TVPaperSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            content()
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 290, alignment: .topLeading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 2)
        )
    }
}

private let localizedErrorDetailSeparator = "\u{1E}"

private func localizedErrorMessage(_ localizedPrefix: String, detail error: Error) -> String {
    localizedPrefix + localizedErrorDetailSeparator + error.localizedDescription
}

private func localizedErrorMessageParts(_ message: String) -> (summary: String, detail: String?) {
    guard let separatorRange = message.range(of: localizedErrorDetailSeparator) else {
        return (message, nil)
    }
    let summary = String(message[..<separatorRange.lowerBound])
    let detail = String(message[separatorRange.upperBound...])
    return (summary, detail.isEmpty ? nil : detail)
}

private struct LocalizedErrorMessageText: View {
    let message: String

    var body: some View {
        let parts = localizedErrorMessageParts(message)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(parts.summary) // l10n: localized
            if let detail = parts.detail {
                Text(detail) // l10n: localized
            }
        }
    }
}

private struct TVMessageView: View {
    let title: LocalizedStringKey
    let message: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(title) // l10n: localized
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                LocalizedErrorMessageText(message: message)
                    .font(DesignTokens.FontScale.body)
            }
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(DesignTokens.Colors.warningText)
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.warningBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.warningBorder, lineWidth: 2)
        )
    }
}

private func localizedCorrectOutOfAnswered(correct: Int, answered: Int) -> String {
    let correctText = String.localizedStringWithFormat(String(localized: "%lld correct answer"), correct)
    let answeredText = String.localizedStringWithFormat(String(localized: "%lld answered question"), answered)
    return String(localized: "\(correctText) out of \(answeredText)")
}

private func localizedQuestionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld questions"), count)
}

private func localizedSubsectionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld subsections"), count)
}

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = language.accessibilityLanguageCode
    return attributedString
}

private func english(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributedString
}
