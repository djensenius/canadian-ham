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
    case morse
    case about
}

private struct CanadianHamVisionRootView: View {
    let launchOptions: VisionLaunchOptions

    @State private var bank: QuestionBank?
    @State private var loadError: String?
    @State private var screen: VisionScreen
    @State private var selectedCategoryID: String
    @State private var language: BankLanguage
    @State private var morseSettings = MorseTrainerSettings.load()
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
                morseSettings: $morseSettings,
                onSelectCategory: { category in
                    if selectedCategoryID != category.id {
                        practiceSession.reset(for: category.id)
                    }
                    selectedCategoryID = category.id
                    screen = .practice
                },
                onMorse: { screen = .morse },
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
                VisionMessageView(title: "No categories", message: String(localized: "The bundled question bank has no practice categories."), systemImage: "questionmark.folder")
            }
        case .morse:
            VisionMorseView(settings: $morseSettings, onCategories: { screen = .categories })
        case .about:
            VisionAboutView(bank: bank, onCategories: { screen = .categories })
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

private struct VisionLanguageOrnament: View {
    @Binding var language: BankLanguage

    var body: some View {
        Picker("Question language", selection: $language) {
            ForEach(BankLanguage.allCases) { language in
                switch language {
                case .english:
                    Text(localizedVision(language.displayName, language: .english)).tag(language) // l10n: content(en)
                case .french:
                    Text(localizedVision(language.displayName, language: .french)).tag(language) // l10n: content(fr)
                }
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 320)
        .padding(DesignTokens.Spacing.sm)
        .glassBackgroundEffect()
        .accessibilityLabel(Text("Question language")) // l10n: localized
        .accessibilityIdentifier("question-language-picker")
    }
}

private struct VisionCategoryGridView: View {
    let bank: QuestionBank
    let language: BankLanguage
    @Binding var morseSettings: MorseTrainerSettings
    let onSelectCategory: (BankCategory) -> Void
    let onMorse: () -> Void
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
                        .accessibilityLabel(Text("About Canadian Ham")) // l10n: localized
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Toggle("Enable Morse trainer preview", isOn: Binding(
                        get: { morseSettings.isEnabled },
                        set: { enabled in
                            var next = morseSettings
                            next.isEnabled = enabled
                            morseSettings = next.normalized()
                            morseSettings.save()
                        }
                    )) // l10n: localized
                    if morseSettings.isEnabled {
                        Button("Morse trainer (preview)", action: onMorse) // l10n: localized
                            .buttonStyle(.borderedProminent)
                    }
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

    private var categoryAccessibilityLabel: AttributedString {
        var label = localizedVision(category.name.text(for: language), language: language)
        label += AttributedString(", \(localizedVisionQuestionCount(category.questionCount)), \(localizedVisionSubsectionCount(category.subsectionCount))")
        return label
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(category.id) // l10n: verbatim
                    .font(DesignTokens.FontScale.caption.monospaced().weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text(localizedVision(category.name.text(for: language), language: language)) // l10n: content(question)
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Spacer(minLength: DesignTokens.Spacing.sm)
                Text(verbatim: "\(localizedVisionQuestionCount(category.questionCount)) • \(localizedVisionSubsectionCount(category.subsectionCount))") // l10n: verbatim
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
        .accessibilityLabel(Text(categoryAccessibilityLabel)) // l10n: content(question)
        .accessibilityHint(Text("Starts practice for this category")) // l10n: localized
    }
}

private struct VisionMorseView: View {
    @Binding var settings: MorseTrainerSettings
    let onCategories: () -> Void

    @State private var driver = MorseAudioDriver()
    @State private var isPlaying = false
    @State private var revealed = false
    @State private var status = ""
    @State private var stopTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            Button("Categories", action: onCategories) // l10n: localized
                .buttonStyle(.bordered)
            Text("Morse trainer (preview)") // l10n: localized
                .font(DesignTokens.FontScale.display.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Play a short practice group. The text is revealed only after playback.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            HStack {
                Button("Play") { play() } // l10n: localized
                    .disabled(isPlaying)
                Button("Stop") { stop(reveal: false, message: String(localized: "Morse playback stopped.")) } // l10n: localized
                    .disabled(!isPlaying)
            }
            Text(status) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            if revealed {
                Text(verbatim: "KMRSU PARIS") // l10n: verbatim
                    .font(.title.weight(.bold).monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
            } else {
                Text("Hidden until playback finishes.") // l10n: localized
                    .font(.title.weight(.bold).monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        }
        .padding(DesignTokens.Spacing.xxl)
        .glassBackgroundEffect()
        .accessibilityIdentifier("vision-morse-screen")
        .onDisappear { stop(reveal: false, message: "") }
    }

    private func play() {
        do {
            revealed = false
            let duration = try driver.play(text: "KMRSU PARIS", settings: settings.normalized())
            isPlaying = true
            status = String(localized: "Morse playback started.")
            stopTask?.cancel()
            stopTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(Int((duration * 1000).rounded(.up)) + 60))
                guard !Task.isCancelled else { return }
                stop(reveal: true, message: String(localized: "Morse playback finished."))
            }
        } catch {
            status = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func stop(reveal: Bool, message: String) {
        stopTask?.cancel()
        driver.stop()
        isPlaying = false
        if reveal { revealed = true }
        status = message
        if !message.isEmpty {
            AccessibilityNotification.Announcement(message).post()
        }
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
                        .accessibilityHint(Text("Returns to the category grid")) // l10n: localized
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(localizedVision(category.name.text(for: language), language: language)) // l10n: content(question)
                            .font(DesignTokens.FontScale.headline.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(localizedVisionCorrectOutOfAnswered(correct: session.correctCount, answered: session.answeredCount)) // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                    }
                    Spacer()
                    Button("About", action: onAbout)
                        .buttonStyle(.bordered)
                        .accessibilityLabel(Text("About Canadian Ham")) // l10n: localized
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
                    VisionMessageView(title: "No questions", message: String(localized: "This category has no bundled questions."), systemImage: "questionmark.circle")
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
            session.errorMessage = localizedErrorMessage(String(localized: "Unable to prepare this question: \("")"), detail: error)
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
            Text(question.id) // l10n: verbatim
                .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localizedVision(question.text.text(for: language), language: language)) // l10n: content(question)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("question-stem")
            Text(sourceText) // l10n: content(question)
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
        .accessibilityLabel(Text(accessibilityLabel)) // l10n: content(question)
    }

    private var sourceText: AttributedString {
        var text = AttributedString(String(localized: "Source: "))
        text += localizedVision(category.name.text(for: language), language: language)
        text += englishVision(" • \(question.subsectionId)")
        return text
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
                Text(displayLetter) // l10n: verbatim
                    .font(DesignTokens.FontScale.bodyLarge.monospaced().weight(.bold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(chipForeground)
                    .background(chipBackground, in: Circle())
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localizedVision(answer.answer.text.text(for: language), language: language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.body.weight(.semibold))
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
        label += localizedVision(answer.answer.text.text(for: language), language: language)
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

private struct VisionPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? DesignTokens.Colors.paper : DesignTokens.Colors.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 52)
            .background(isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.paperInset, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.inkMuted,
                        style: StrokeStyle(lineWidth: 1.5, dash: isEnabled ? [] : [5, 4])
                    )
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
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
            HStack(spacing: DesignTokens.Spacing.lg) {
                Label {
                    Text(resultText) // l10n: localized
                } icon: {
                    Image(systemName: selectedAnswer.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                }
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
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
                .buttonStyle(VisionPrimaryButtonStyle())
                .font(DesignTokens.FontScale.body.weight(.bold))
                .hoverEffect(.highlight)
                .accessibilityHint(Text("Loads another question from this category")) // l10n: localized
                .accessibilityIdentifier("next-question-button")
        }
        .padding(DesignTokens.Spacing.lg)
        .background(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(selectedAnswer.isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2)
        )
        .glassBackgroundEffect()
    }

    private var resultText: String {
        selectedAnswer.isCorrect ? String(localized: "Correct") : String(localized: "Incorrect")
    }
    private var sourceText: AttributedString {
        if selectedAnswer.isCorrect {
            var text = AttributedString(String(localized: "Source: "))
            text += localizedVision(category.name.text(for: language), language: language)
            text += englishVision(" • \(question.subsectionId)")
            return text
        }

        var text = AttributedString(String(localized: "Correct answer: "))
        text += localizedVision(correctAnswer.answer.text.text(for: language), language: language)
        return text
    }

    private var accessibilityLabel: AttributedString {
        if selectedAnswer.isCorrect {
            var label = AttributedString(String(localized: "Correct. Your answer: "))
            label += localizedVision(selectedAnswer.answer.text.text(for: language), language: language)
            label += AttributedString(String(localized: ". Source: "))
            label += localizedVision(category.name.text(for: language), language: language)
            label += englishVision(", \(question.subsectionId)")
            return label
        }

        var label = AttributedString(String(localized: "Incorrect. Correct answer: "))
        label += localizedVision(correctAnswer.answer.text.text(for: language), language: language)
        label += AttributedString(String(localized: ". Source: "))
        label += localizedVision(category.name.text(for: language), language: language)
        label += englishVision(", \(question.subsectionId)")
        return label
    }
}

private let visionAboutRBR4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"

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

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    VisionPaperSection(title: "Bank") {
                        Text("Active bank: \(bank.manifest.bankId), effective \(bank.manifest.effectiveDate).")
                        Text("Questions: \(bank.questions.count); categories: \(bank.categories.count); subsections: \(bank.subsections.count).") // l10n: localized
                    }
                    VisionPaperSection(title: "Sources") {
                        Text("ISED Amateur Radio Operator Certificate Basic Qualification question bank, effective \(bank.manifest.effectiveDate).")
                        Text("Question bank source URL: \(verbatimVisionText(bank.manifest.source.url))")
                        Text("RBR-4, Standards for the Operation of Radio Stations in the Amateur Radio Service: \(verbatimVisionText(visionAboutRBR4CitationURL))")
                        Text("ISED provides the Basic exam reference sheet with formulas and block diagrams at the exam; the reference PDFs are source artifacts and are not shipped in the apps.")
                    }
                    VisionPaperSection(title: "Attribution") {
                        // TODO(task-1.1): Replace this draft attribution with the exact wording from the recorded ISED permission before public release. Permission remains pending: requested 2026-10-02; granted pending.
                        Text("Draft attribution, not in effect: ISED written permission has been requested and has not yet been granted. Replace this draft with the wording from the recorded permission (task-1.1) before public release.")
                            .accessibilityLabel(Text(englishVision("Draft attribution, not in effect: ISED written permission has been requested and has not yet been granted. Replace this draft with the wording from the recorded permission (task-1.1) before public release."))) // l10n: content(en)
                        Text("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.")
                            .accessibilityLabel(Text(englishVision("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page."))) // l10n: content(en)
                    }
                    VisionPaperSection(title: "Disclaimer") {
                        Text("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.")
                            .accessibilityLabel(Text(englishVision("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner."))) // l10n: content(en)
                    }
                    VisionPaperSection(title: "Privacy") {
                        Text("This Apple Vision Pro app works fully offline with bundled content and has no accounts, analytics, telemetry, ads, networking code, iCloud sync, push notifications, remote config, or third-party SDKs. Practice sessions are kept only while the app is open; nothing is saved or sent.")
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
        .frame(maxWidth: .infinity, minHeight: 270, alignment: .topLeading)
        .background(DesignTokens.Colors.paperElevated.opacity(0.96), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 1.5)
        )
        .glassBackgroundEffect()
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

private struct VisionMessageView: View {
    let title: LocalizedStringKey
    let message: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
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
        .glassBackgroundEffect()
    }
}

private func localizedVisionCorrectOutOfAnswered(correct: Int, answered: Int) -> String {
    let correctText = String.localizedStringWithFormat(String(localized: "%lld correct answer"), correct)
    let answeredText = String.localizedStringWithFormat(String(localized: "%lld answered question"), answered)
    return String(localized: "\(correctText) out of \(answeredText)")
}

private func localizedVisionQuestionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld questions"), count)
}

private func localizedVisionSubsectionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld subsections"), count)
}

private func localizedVision(_ string: String, language: BankLanguage) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = language.accessibilityLanguageCode
    return attributedString
}

private func verbatimVisionText(_ string: String) -> Text {
    Text(verbatim: string) // l10n: verbatim
}

private func englishVision(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributedString
}
