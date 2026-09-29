import Accessibility
import SwiftUI

@main
struct CanadianHamVisionApp: App {
    private let launchOptions = VisionLaunchOptions()

    var body: some Scene {
        WindowGroup {
            CanadianHamVisionRootView(launchOptions: launchOptions)
                .preferredColorScheme(launchOptions.colorScheme)
        }
        .defaultSize(width: 1_120, height: 760)
    }
}

private struct VisionLaunchOptions {
    let initialScreen: VisionScreen
    let initialCategoryID: String
    let practiceQuestionID: String?
    let answeredSourceIndex: Int?
    let colorScheme: ColorScheme?
    let initialLanguage: BankLanguage

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        initialScreen = VisionScreen(rawValue: AppLaunchArguments.value(after: "-CanadianHamPlatformInitialScreen", in: arguments) ?? "categories") ?? .categories
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

private enum VisionScreen: String {
    case categories
    case practice
    case about
}

private struct CanadianHamVisionRootView: View {
    let launchOptions: VisionLaunchOptions

    @State private var bank: QuestionBank?
    @State private var loadError: String?
    @State private var screen: VisionScreen
    @State private var selectedCategoryID: String
    @State private var language: BankLanguage
    @State private var practiceSession = VisionPracticeSessionState()

    init(launchOptions: VisionLaunchOptions) {
        self.launchOptions = launchOptions
        _screen = State(initialValue: launchOptions.initialScreen)
        _selectedCategoryID = State(initialValue: launchOptions.initialCategoryID)
        _language = State(initialValue: launchOptions.initialLanguage)
    }

    var body: some View {
        ZStack {
            DesignTokens.Colors.paper.opacity(0.92).ignoresSafeArea()

            if let bank {
                content(for: bank)
                    .padding(DesignTokens.Spacing.xxl)
            } else if let loadError {
                VisionMessageView(title: "Question bank unavailable", message: loadError, systemImage: "exclamationmark.triangle.fill")
                    .padding(DesignTokens.Spacing.xxl)
            } else {
                ProgressView("Loading question bank…")
                    .controlSize(.large)
                    .font(DesignTokens.FontScale.title)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            VisionLanguageOrnament(language: $language)
                .padding(.bottom, DesignTokens.Spacing.md)
        }
        .task { loadBankIfNeeded() }
    }

    @ViewBuilder
    private func content(for bank: QuestionBank) -> some View {
        switch screen {
        case .categories:
            VisionCategoryGridView(
                bank: bank,
                language: language,
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
                VisionPracticeView(
                    bank: bank,
                    category: category,
                    forcedQuestionID: launchOptions.practiceQuestionID,
                    answeredSourceIndex: launchOptions.answeredSourceIndex,
                    language: language,
                    session: $practiceSession,
                    onCategories: { screen = .categories },
                    onAbout: { screen = .about }
                )
            } else {
                VisionMessageView(title: "No categories", message: "The bundled question bank has no practice categories.", systemImage: "questionmark.folder")
            }
        case .about:
            VisionAboutView(bank: bank, onCategories: { screen = .categories })
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

private struct VisionLanguageOrnament: View {
    @Binding var language: BankLanguage

    var body: some View {
        Picker("Question language", selection: $language) {
            ForEach(BankLanguage.allCases) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 320)
        .padding(DesignTokens.Spacing.sm)
        .glassBackgroundEffect()
        .accessibilityLabel("Question language")
        .accessibilityIdentifier("question-language-picker")
    }
}

private struct VisionCategoryGridView: View {
    let bank: QuestionBank
    let language: BankLanguage
    let onSelectCategory: (BankCategory) -> Void
    let onAbout: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.lg), count: 4)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Canadian Ham")
                            .font(DesignTokens.FontScale.display.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Offline Basic question-bank practice for visionOS")
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                    }
                    Spacer()
                    Button("About", action: onAbout)
                        .buttonStyle(.bordered)
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .accessibilityLabel("About Canadian Ham")
                }

                Text("Practice categories")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.lg) {
                    ForEach(bank.categories) { category in
                        VisionCategoryCard(category: category, language: language) {
                            onSelectCategory(category)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("vision-category-grid")
    }
}

private struct VisionCategoryCard: View {
    let category: BankCategory
    let language: BankLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(category.id)
                    .font(DesignTokens.FontScale.caption.monospaced().weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text(category.name.text(for: language))
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Spacer(minLength: DesignTokens.Spacing.sm)
                Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                    .strokeBorder(DesignTokens.Colors.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityLabel("\(category.name.text(for: language)), \(category.questionCount) questions, \(category.subsectionCount) subsections")
        .accessibilityHint("Starts practice for this category")
    }
}

private struct VisionPracticeSessionState {
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

private struct VisionPracticeView: View {
    let bank: QuestionBank
    let category: BankCategory
    let forcedQuestionID: String?
    let answeredSourceIndex: Int?
    let language: BankLanguage
    @Binding var session: VisionPracticeSessionState
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
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(alignment: .center, spacing: DesignTokens.Spacing.lg) {
                    Button("Categories", action: onCategories)
                        .buttonStyle(.bordered)
                        .accessibilityHint("Returns to the category grid")
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(category.name.text(for: language))
                            .font(DesignTokens.FontScale.headline.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("\(session.correctCount) correct out of \(session.answeredCount) answered")
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                    }
                    Spacer()
                    Button("About", action: onAbout)
                        .buttonStyle(.bordered)
                        .accessibilityLabel("About Canadian Ham")
                }

                if let errorMessage = session.errorMessage {
                    VisionMessageView(title: "Practice unavailable", message: errorMessage, systemImage: "exclamationmark.triangle.fill")
                } else if let currentQuestion = session.currentQuestion {
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                        VisionQuestionCard(question: currentQuestion, category: category, language: language)
                            .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("Answers")
                                .font(DesignTokens.FontScale.title.weight(.bold))
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(session.shuffledAnswers) { answer in
                                VisionAnswerButton(
                                    answer: answer,
                                    displayLetter: displayLetter(for: answer.displayIndex),
                                    language: language,
                                    selectedSourceIndex: session.selectedSourceIndex,
                                    action: { select(answer) }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if let selectedAnswer, let correctAnswer {
                        VisionFeedbackPanel(
                            selectedAnswer: selectedAnswer,
                            correctAnswer: correctAnswer,
                            category: category,
                            question: currentQuestion,
                            language: language,
                            onNext: loadNextQuestion
                        )
                    }
                } else {
                    VisionMessageView(title: "No questions", message: "This category has no bundled questions.", systemImage: "questionmark.circle")
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .onAppear {
            session.resetIfNeeded(for: category.id)
            if session.currentQuestion == nil {
                loadNextQuestion()
            }
        }
        .accessibilityIdentifier("vision-practice-screen")
    }

    private func select(_ answer: ShuffledAnswer) {
        guard session.selectedSourceIndex == nil else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            session.selectedSourceIndex = answer.sourceIndex
        }
        session.answeredCount += 1
        if answer.isCorrect { session.correctCount += 1 }
        AccessibilityNotification.Announcement(answer.isCorrect ? "Correct" : "Incorrect").post()
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
                question = try AppleQuestionShuffle.randomQuestion(from: questions, seed: "vision-practice/\(category.id)/\(session.answeredCount)/\(session.sessionID)") ?? questions[0]
                usedForcedQuestion = false
            }
            session.currentQuestion = question
            let answerSeed = usedForcedQuestion ? "vision-answers/\(question.id)/ui-test" : "vision-answers/\(question.id)/\(session.answeredCount)/\(session.sessionID)"
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
            session.errorMessage = "Unable to prepare this question with the shared engine: \(error.localizedDescription)"
        }
    }

    private func displayLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D"]
        return letters.indices.contains(index) ? letters[index] : "\(index + 1)"
    }
}

private struct VisionQuestionCard: View {
    let question: BankQuestion
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(question.id)
                .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localizedVision(question.text.text(for: language), language: language))
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("question-stem")
            Text("Source: \(category.name.text(for: language)) • \(question.subsectionId)")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        .background(DesignTokens.Colors.paperElevated.opacity(0.96), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1.5)
        )
        .glassBackgroundEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var accessibilityLabel: AttributedString {
        var label = englishVision("Question \(question.id). ")
        label += localizedVision(question.text.text(for: language), language: language)
        return label
    }
}

private struct VisionAnswerButton: View {
    let answer: ShuffledAnswer
    let displayLetter: String
    let language: BankLanguage
    let selectedSourceIndex: Int?
    let action: () -> Void

    private var isSelected: Bool { selectedSourceIndex == answer.sourceIndex }
    private var isAnswered: Bool { selectedSourceIndex != nil }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(displayLetter)
                    .font(DesignTokens.FontScale.bodyLarge.monospaced().weight(.bold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(chipForeground)
                    .background(chipBackground, in: Circle())
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localizedVision(answer.answer.text.text(for: language), language: language))
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .foregroundStyle(textColor)
                        .accessibilityIdentifier("answer-\(displayLetter)-text")
                    if let statusText {
                        Label(statusText, systemImage: answer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(textColor)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                    .strokeBorder(border, lineWidth: isSelected || semantic ? 3 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .disabled(isAnswered)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier("answer-\(displayLetter)-button")
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
    private var accessibilityLabel: AttributedString {
        var label = englishVision("Answer \(displayLetter), ")
        label += localizedVision(answer.answer.text.text(for: language), language: language)
        if let statusText { label += englishVision(", \(statusText)") }
        return label
    }
}

private struct VisionFeedbackPanel: View {
    let selectedAnswer: ShuffledAnswer
    let correctAnswer: ShuffledAnswer
    let category: BankCategory
    let question: BankQuestion
    let language: BankLanguage
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Label(resultText, systemImage: selectedAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
            Text(sourceText)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(selectedAnswer.isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
            Spacer()
            Button("Next question", action: onNext)
                .buttonStyle(.borderedProminent)
                .font(DesignTokens.FontScale.body.weight(.bold))
                .accessibilityHint("Loads another question from this category")
                .accessibilityIdentifier("next-question-button")
        }
        .padding(DesignTokens.Spacing.lg)
        .background(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2)
        )
        .glassBackgroundEffect()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier("answer-feedback")
    }

    private var resultText: String { selectedAnswer.isCorrect ? "Correct" : "Incorrect" }
    private var sourceText: AttributedString {
        if selectedAnswer.isCorrect {
            var text = englishVision("Source: ")
            text += localizedVision(category.name.text(for: language), language: language)
            text += englishVision(" • \(question.subsectionId)")
            return text
        }

        var text = englishVision("Correct answer: ")
        text += localizedVision(correctAnswer.answer.text.text(for: language), language: language)
        return text
    }

    private var accessibilityLabel: AttributedString {
        if selectedAnswer.isCorrect {
            var label = englishVision("Correct. Your answer: ")
            label += localizedVision(selectedAnswer.answer.text.text(for: language), language: language)
            label += englishVision(". Source: ")
            label += localizedVision(category.name.text(for: language), language: language)
            label += englishVision(", \(question.subsectionId)")
            return label
        }

        var label = englishVision("Incorrect. Correct answer: ")
        label += localizedVision(correctAnswer.answer.text.text(for: language), language: language)
        label += englishVision(". Source: ")
        label += localizedVision(category.name.text(for: language), language: language)
        label += englishVision(", \(question.subsectionId)")
        return label
    }
}

private struct VisionAboutView: View {
    let bank: QuestionBank
    let onCategories: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack {
                    Button("Categories", action: onCategories)
                        .buttonStyle(.bordered)
                    Spacer()
                }

                Text("About Canadian Ham")
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: DesignTokens.Spacing.lg) {
                    VisionPaperSection(title: "Bank") {
                        Text("Active bank: \(bank.manifest.bankId)")
                        Text("Effective date: \(bank.manifest.effectiveDate)")
                        Text("Questions: \(bank.questions.count) • Categories: \(bank.categories.count) • Subsections: \(bank.subsections.count)")
                    }
                    VisionPaperSection(title: "Attribution") {
                        Text("Question-bank material is sourced from Innovation, Science and Economic Development Canada Amateur Radio Operator Certificate Basic Qualification materials.")
                        Text("Canadian Ham is independent and not affiliated with, sponsored by, or endorsed by ISED, RAC, or any accredited examiner.")
                    }
                    VisionPaperSection(title: "Privacy") {
                        Text("This visionOS app works offline with bundled content, includes no networking code, no analytics, no telemetry, and no iCloud sync.")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("vision-about-screen")
    }
}

private struct VisionPaperSection<Content: View>: View {
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
        .frame(maxWidth: .infinity, minHeight: 270, alignment: .topLeading)
        .background(DesignTokens.Colors.paperElevated.opacity(0.96), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1.5)
        )
        .glassBackgroundEffect()
    }
}

private struct VisionMessageView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
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
        .glassBackgroundEffect()
    }
}

private func localizedVision(_ string: String, language: BankLanguage) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = language.accessibilityLanguageCode
    return attributedString
}

private func englishVision(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributedString
}
