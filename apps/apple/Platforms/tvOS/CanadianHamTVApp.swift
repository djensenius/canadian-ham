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
                    onCategories: { screen = .categories },
                    onAbout: { screen = .about }
                )
                .id(category.id)
            } else {
                TVMessageView(title: "No categories", message: "The bundled question bank has no practice categories.", systemImage: "questionmark.folder")
            }
        case .about:
            TVAboutView(bank: bank, onCategories: { screen = .categories })
        }
    }

    private func loadBankIfNeeded() {
        guard bank == nil, loadError == nil else { return }
        do {
            bank = try QuestionBankStore.load()
        } catch {
            loadError = error.localizedDescription
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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
            TVTopBar(title: "Canadian Ham", subtitle: "Offline Basic question-bank practice", language: $language, onAbout: onAbout)

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
        .accessibilityIdentifier("tv-category-grid")
    }
}

private struct TVCategoryButton: View {
    let category: BankCategory
    let language: BankLanguage
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(category.id)
                    .font(DesignTokens.FontScale.caption.monospaced().weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text(category.name.text(for: language))
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .lineLimit(3)
                Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
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
        .accessibilityLabel("\(category.name.text(for: language)), \(category.questionCount) questions, \(category.subsectionCount) subsections")
        .accessibilityHint("Starts practice for this category")
    }
}

private struct TVPracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    let forcedQuestionID: String?
    let answeredSourceIndex: Int?
    @Binding var language: BankLanguage
    let onCategories: () -> Void
    let onAbout: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentQuestion: BankQuestion?
    @State private var shuffledAnswers: [ShuffledAnswer] = []
    @State private var selectedSourceIndex: Int?
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var errorMessage: String?

    private var selectedAnswer: ShuffledAnswer? {
        guard let selectedSourceIndex else { return nil }
        return shuffledAnswers.first { $0.sourceIndex == selectedSourceIndex }
    }

    private var correctAnswer: ShuffledAnswer? {
        AppleQuestionShuffle.correctAnswer(in: shuffledAnswers)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            TVTopBar(
                title: category.name.text(for: language),
                subtitle: "\(correctCount) correct out of \(answeredCount) answered",
                language: $language,
                onAbout: onAbout,
                leadingAction: ("Categories", onCategories)
            )

            if let errorMessage {
                TVMessageView(title: "Practice unavailable", message: errorMessage, systemImage: "exclamationmark.triangle.fill")
            } else if let currentQuestion {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.xxl) {
                    TVQuestionPanel(question: currentQuestion, category: category, language: language)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Answers")
                            .font(DesignTokens.FontScale.title.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(shuffledAnswers) { answer in
                            TVAnswerButton(
                                answer: answer,
                                displayLetter: displayLetter(for: answer.displayIndex),
                                language: language,
                                selectedSourceIndex: selectedSourceIndex,
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
                }
            } else {
                TVMessageView(title: "No questions", message: "This category has no bundled questions.", systemImage: "questionmark.circle")
            }
        }
        .onAppear {
            if currentQuestion == nil {
                loadNextQuestion()
            }
        }
        .accessibilityIdentifier("tv-practice-screen")
    }

    private func select(_ answer: ShuffledAnswer) {
        guard selectedSourceIndex == nil else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            selectedSourceIndex = answer.sourceIndex
        }
        answeredCount += 1
        if answer.isCorrect { correctCount += 1 }
        AccessibilityNotification.Announcement(answer.isCorrect ? "Correct" : "Incorrect").post()
    }

    private func loadNextQuestion() {
        let questions = bank.questions(in: category)
        guard !questions.isEmpty else {
            currentQuestion = nil
            shuffledAnswers = []
            selectedSourceIndex = nil
            return
        }

        let requestedQuestionID = answeredCount == 0 ? forcedQuestionID : nil
        do {
            let question: BankQuestion
            if let requestedQuestionID, let forced = questions.first(where: { $0.id == requestedQuestionID }) {
                question = forced
            } else {
                question = try AppleQuestionShuffle.randomQuestion(from: questions, seed: "tvos-practice/\(category.id)/\(answeredCount)") ?? questions[0]
            }
            currentQuestion = question
            shuffledAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "tvos-answers/\(question.id)/\(answeredCount)")
            if answeredCount == 0, let answeredSourceIndex {
                selectedSourceIndex = answeredSourceIndex
                answeredCount = 1
                if question.answers.first(where: { $0.sourceIndex == answeredSourceIndex })?.isCorrect == true {
                    correctCount = 1
                }
            } else {
                selectedSourceIndex = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = "Unable to prepare this question with the shared engine: \(error.localizedDescription)"
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
            Text(question.id)
                .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(question.text.text(for: language), language: language))
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .lineLimit(5)
            Text("Source: \(category.name.text(for: language)) • \(question.subsectionId)")
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
        .accessibilityLabel("Question \(question.id). \(question.text.text(for: language))")
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
                Text(displayLetter)
                    .font(DesignTokens.FontScale.title.monospaced().weight(.bold))
                    .frame(width: 54, height: 54)
                    .foregroundStyle(chipForeground)
                    .background(chipBackground, in: Circle())
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized(answer.answer.text.text(for: language), language: language))
                        .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                        .foregroundStyle(textColor)
                        .lineLimit(3)
                    if let statusText {
                        Label(statusText, systemImage: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isAnswered ? "Question already answered. Use Next question to continue." : "Selects this answer")
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
    private var accessibilityLabel: String {
        var label = "Answer \(displayLetter), \(answer.answer.text.text(for: language))"
        if let statusText { label += ", \(statusText)" }
        return label
    }
}

private struct TVFeedbackBar: View {
    let selectedAnswer: ShuffledAnswer
    let correctAnswer: ShuffledAnswer
    let category: BankCategory
    let question: BankQuestion
    let language: BankLanguage
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Label(resultText, systemImage: selectedAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
            Text(sourceText)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
            Spacer()
            Button("Next question", action: onNext)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Loads another question from this category")
        }
        .padding(DesignTokens.Spacing.xl)
        .background(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("answer-feedback")
    }

    private var resultText: String { selectedAnswer.isCorrect ? "Correct" : "Incorrect" }
    private var sourceText: String {
        selectedAnswer.isCorrect
            ? "Source: \(category.name.text(for: language)) • \(question.subsectionId)"
            : "Correct answer: \(correctAnswer.answer.text.text(for: language))"
    }
}

private struct TVTopBar: View {
    let title: String
    let subtitle: String
    @Binding var language: BankLanguage
    let onAbout: () -> Void
    var leadingAction: (title: String, action: () -> Void)? = nil

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            if let leadingAction {
                Button(leadingAction.title, action: leadingAction.action)
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .buttonStyle(.bordered)
                    .accessibilityHint("Returns to the category grid")
            }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            Spacer()
            Picker("Question language", selection: $language) {
                ForEach(BankLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 420)
            .accessibilityLabel("Question language")
            .accessibilityIdentifier("question-language-picker")
            Button("About", action: onAbout)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(.bordered)
                .accessibilityLabel("About Canadian Ham")
        }
    }
}

private struct TVAboutView: View {
    let bank: QuestionBank
    let onCategories: () -> Void

    var body: some View {
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
                    Text("Questions: \(bank.questions.count) • Categories: \(bank.categories.count) • Subsections: \(bank.subsections.count)")
                }
                TVPaperSection(title: "Attribution") {
                    Text("Question-bank material is sourced from Innovation, Science and Economic Development Canada Amateur Radio Operator Certificate Basic Qualification materials.")
                    Text("Canadian Ham is independent and not affiliated with, sponsored by, or endorsed by ISED, RAC, or any accredited examiner.")
                }
                TVPaperSection(title: "Privacy") {
                    Text("This tvOS app works offline with bundled content, includes no networking code, no analytics, no telemetry, and no iCloud sync.")
                }
            }
        }
        .accessibilityIdentifier("tv-about-screen")
    }
}

private struct TVPaperSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
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

private struct TVMessageView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(title)
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                Text(message)
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

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = language.accessibilityLanguageCode
    return attributedString
}
