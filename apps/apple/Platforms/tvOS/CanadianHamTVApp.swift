import Accessibility
import CanadianHamContent
import CanadianHamEngine
import SwiftUI
import UIKit

@main
struct CanadianHamTVApp: App {
    private let launchOptions = TVLaunchOptions()

    var body: some Scene {
        WindowGroup {
            CanadianHamTVRootView(launchOptions: launchOptions)
                .preferredColorScheme(launchOptions.colorScheme)
                .environment(\.tvReduceMotionOverride, launchOptions.reduceMotionOverride)
        }
    }
}

private struct TVLaunchOptions {
    let initialScreen: PlatformScreen
    let initialCategoryID: String
    let practiceQuestionID: String?
    let answeredSourceIndex: Int?
    let colorScheme: ColorScheme?
    let reduceMotionOverride: Bool?
    let initialLanguage: BankLanguage
    let evidenceFocus: TVEvidenceFocus?
    let simulateContentLoadFailure: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        #if DEBUG
        initialScreen = PlatformScreen(rawValue: AppLaunchArguments.value(after: "-CanadianHamPlatformInitialScreen", in: arguments) ?? "categories") ?? .categories
        initialCategoryID = AppLaunchArguments.value(after: "-CanadianHamPlatformCategoryID", in: arguments) ?? "B-001"
        practiceQuestionID = AppLaunchArguments.value(after: "-CanadianHamPlatformQuestionID", in: arguments)
        answeredSourceIndex = AppLaunchArguments.value(after: "-CanadianHamPlatformAnsweredSourceIndex", in: arguments).flatMap(Int.init)
        switch AppLaunchArguments.value(after: "-CanadianHamAppearance", in: arguments) {
        case "light": colorScheme = .light
        case "dark": colorScheme = .dark
        default: colorScheme = nil
        }
        switch AppLaunchArguments.value(after: "-CanadianHamReduceMotion", in: arguments) {
        case "enabled", "true", "1": reduceMotionOverride = true
        case "disabled", "false", "0": reduceMotionOverride = false
        default: reduceMotionOverride = nil
        }
        initialLanguage = BankLanguage.resolvedPreference(rawValue: AppLaunchArguments.value(after: "-CanadianHamLanguage", in: arguments))
        evidenceFocus = AppLaunchArguments.value(after: "-CanadianHamTVEvidenceFocus", in: arguments).flatMap(TVEvidenceFocus.init(rawValue:))
        simulateContentLoadFailure = AppLaunchArguments.value(after: "-CanadianHamSimulateContentLoadFailure", in: arguments) == "content"
        #else
        _ = arguments
        initialScreen = .categories
        initialCategoryID = "B-001"
        practiceQuestionID = nil
        answeredSourceIndex = nil
        colorScheme = nil
        reduceMotionOverride = nil
        initialLanguage = BankLanguage.systemPreferred()
        evidenceFocus = nil
        simulateContentLoadFailure = false
        #endif
    }
}

private enum TVEvidenceFocus: String {
    case category
    case answer
    case hint
}

private enum PlatformScreen: String {
    case categories
    case practice
    case lesson
    case morse
    case about
}

private enum TVFocusIndicator {
    static let outerStroke = DesignTokens.Colors.ink
    static let innerStroke = Color.tvDynamicToken(
        light: DesignTokens.RGB(red: 1.000000, green: 0.972549, blue: 0.917647),
        dark: DesignTokens.RGB(red: 0.125490, green: 0.105882, blue: 0.086275)
    )

    static let outerLineWidth: CGFloat = 12
    static let innerLineWidth: CGFloat = 4
    static let scaledEdgeClearance: CGFloat = 32
}

private extension Color {
    static func tvDynamicToken(light: DesignTokens.RGB, dark: DesignTokens.RGB) -> Color {
        Color(UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: color.red, green: color.green, blue: color.blue, alpha: 1)
        })
    }
}

private struct TVFocusRingModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let isFocused: Bool
    let unfocusedColor: Color
    let unfocusedLineWidth: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                shape
                    .stroke(TVFocusIndicator.outerStroke, lineWidth: TVFocusIndicator.outerLineWidth)
                shape
                    .strokeBorder(TVFocusIndicator.innerStroke, lineWidth: TVFocusIndicator.innerLineWidth)
            } else {
                shape
                    .strokeBorder(unfocusedColor, lineWidth: unfocusedLineWidth)
            }
        }
    }
}

private struct TVReduceMotionOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

private extension EnvironmentValues {
    var tvReduceMotionOverride: Bool? {
        get { self[TVReduceMotionOverrideKey.self] }
        set { self[TVReduceMotionOverrideKey.self] = newValue }
    }
}

extension View {
    func tvFocusRing<S: InsettableShape>(
        _ shape: S,
        isFocused: Bool,
        unfocusedColor: Color,
        unfocusedLineWidth: CGFloat
    ) -> some View {
        modifier(TVFocusRingModifier(
            shape: shape,
            isFocused: isFocused,
            unfocusedColor: unfocusedColor,
            unfocusedLineWidth: unfocusedLineWidth
        ))
    }

}

private struct CanadianHamTVRootView: View {
    let launchOptions: TVLaunchOptions

    @State private var bank: QuestionBank?
    @State private var contentLibrary: ContentLibrary?
    @State private var loadError: String?
    @State private var contentLoadError: String?
    @State private var screen: PlatformScreen
    @State private var selectedCategoryID: String
    @State private var language: BankLanguage
    @State private var morseSettings = MorseTrainerSettings.load()
    @State private var practiceSession = TVPracticeSessionState()
    @State private var activeLessonLink: QuestionHintLessonLink?

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
                evidenceFocus: launchOptions.evidenceFocus,
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
                TVPracticeView(
                    bank: bank,
                    contentLibrary: contentLibrary,
                    category: category,
                    forcedQuestionID: launchOptions.practiceQuestionID,
                    answeredSourceIndex: launchOptions.answeredSourceIndex,
                    language: $language,
                    session: $practiceSession,
                    evidenceFocus: launchOptions.evidenceFocus,
                    onCategories: { screen = .categories },
                    onAbout: { screen = .about },
                    onOpenHintLesson: { link in
                        activeLessonLink = link
                        screen = .lesson
                    }
                )
                .onExitCommand { screen = .categories }
            } else {
                TVMessageView(title: "No categories", message: String(localized: "The bundled question bank has no practice categories."), systemImage: "questionmark.folder")
            }
        case .lesson:
            if let activeLessonLink, let contentLibrary, let lesson = contentLibrary.lessonsById[activeLessonLink.lessonId] {
                TVLessonView(lesson: lesson, sectionAnchor: activeLessonLink.sectionAnchor, onPractice: { screen = .practice })
                    .onExitCommand { screen = .practice }
            } else {
                TVMessageView(title: "Lesson", message: contentLoadError ?? localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: PlatformLessonUnavailableError()), systemImage: "book.closed")
            }
        case .morse:
            TVMorseView(settings: $morseSettings, onCategories: { screen = .categories })
                .onExitCommand { screen = .categories }
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
            return
        }

        guard contentLibrary == nil, contentLoadError == nil else { return }
        do {
            if launchOptions.simulateContentLoadFailure {
                throw PlatformContentLoadSimulationError()
            }
            contentLibrary = try ContentLibrary.load()
        } catch {
            contentLoadError = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

private struct TVCategoryGridView: View {
    let bank: QuestionBank
    @Binding var language: BankLanguage
    let evidenceFocus: TVEvidenceFocus?
    let onSelectCategory: (BankCategory) -> Void
    let onMorse: () -> Void
    let onAbout: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xxl), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                TVTopBar(
                    title: AttributedString("Canadian Ham"),
                    subtitle: Text("Offline Basic question-bank practice"),
                    language: $language,
                    evidenceFocus: evidenceFocus,
                    onAbout: onAbout,
                    layout: .inline
                )

                Button("Morse", action: onMorse) // l10n: localized
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .buttonStyle(TVSecondaryButtonStyle())
                    .accessibilityIdentifier("tv-morse-button")

                Text("Practice categories")
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                LazyVGrid(columns: columns, alignment: .leading, spacing: DesignTokens.Spacing.xxl) {
                    ForEach(bank.categories) { category in
                        TVCategoryButton(
                            category: category,
                            language: language,
                            requestsEvidenceFocus: evidenceFocus == .category && category.id == bank.categories.first?.id
                        ) {
                            onSelectCategory(category)
                        }
                    }
                }
            }
            .padding(TVFocusIndicator.scaledEdgeClearance)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("tv-category-grid")
    }
}

private struct TVCategoryButton: View {
    let category: BankCategory
    let language: BankLanguage
    let requestsEvidenceFocus: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride
    @FocusState private var isFocused: Bool

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }
    private static let cardHeight: CGFloat = 380
    private static let titleFont = Font.system(.title3, design: .serif)

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
                    .font(Self.titleFont.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .allowsTightening(false)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "\(localizedQuestionCount(category.questionCount)) • \(localizedSubsectionCount(category.subsectionCount))") // l10n: verbatim
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, minHeight: Self.cardHeight, maxHeight: Self.cardHeight, alignment: .topLeading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
            .tvFocusRing(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous),
                isFocused: isFocused,
                unfocusedColor: DesignTokens.Colors.border,
                unfocusedLineWidth: 2
            )
            .scaleEffect(!reduceMotion && isFocused ? 1.04 : 1)
        }
        .buttonStyle(TVCustomFocusButtonStyle())
        .focused($isFocused)
        .focusEffectDisabled()
        .accessibilityLabel(Text(categoryAccessibilityLabel)) // l10n: content(question)
        .accessibilityIdentifier("category-\(category.id)-button")
        .accessibilityHint(Text("Starts practice for this category")) // l10n: localized
        .onAppear {
            if requestsEvidenceFocus {
                isFocused = true
            }
        }
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
    var hintLevelsByQuestionId: [String: Int] = [:]
    var hintQualifiedQuestionIds: Set<String> = []
    var answeredWithHelpQuestionIds: Set<String> = []

    mutating func reset(for categoryID: String) {
        self.categoryID = categoryID
        sessionID = UUID().uuidString
        currentQuestion = nil
        shuffledAnswers = []
        selectedSourceIndex = nil
        answeredCount = 0
        correctCount = 0
        errorMessage = nil
        hintLevelsByQuestionId = [:]
        hintQualifiedQuestionIds = []
        answeredWithHelpQuestionIds = []
    }

    mutating func resetIfNeeded(for categoryID: String) {
        if self.categoryID != categoryID {
            reset(for: categoryID)
        }
    }
}

private struct TVPracticeView: View {
    let bank: QuestionBank
    let contentLibrary: ContentLibrary?
    let category: BankCategory
    let forcedQuestionID: String?
    let answeredSourceIndex: Int?
    @Binding var language: BankLanguage
    @Binding var session: TVPracticeSessionState
    let evidenceFocus: TVEvidenceFocus?
    let onCategories: () -> Void
    let onAbout: () -> Void
    let onOpenHintLesson: (QuestionHintLessonLink) -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride
    @State private var hintActionFocusRequest = 0

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    private var selectedAnswer: ShuffledAnswer? {
        guard let selectedSourceIndex = session.selectedSourceIndex else { return nil }
        return session.shuffledAnswers.first { $0.sourceIndex == selectedSourceIndex }
    }

    private var correctAnswer: ShuffledAnswer? {
        AppleQuestionShuffle.correctAnswer(in: session.shuffledAnswers)
    }

    private var currentQuestionHint: QuestionHint? {
        guard let question = session.currentQuestion, bank.courseBankID == .basic else { return nil }
        return contentLibrary?.questionHintsByQuestionId[question.id]
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    TVTopBar(
                        title: localized(category.name.text(for: language), language: language),
                        subtitle: Text(localizedCorrectOutOfAnswered(correct: session.correctCount, answered: session.answeredCount)), // l10n: localized
                        language: $language,
                        evidenceFocus: evidenceFocus,
                        onAbout: onAbout,
                        leadingAction: ("Categories", onCategories)
                    )

                    if let errorMessage = session.errorMessage {
                        TVMessageView(title: "Practice unavailable", message: errorMessage, systemImage: "exclamationmark.triangle.fill")
                    } else if let currentQuestion = session.currentQuestion {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.xxl) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                                TVQuestionPanel(question: currentQuestion, category: category, language: language)
                                if let hint = currentQuestionHint {
                                    TVHintPanel(
                                        hint: hint,
                                        language: language,
                                        visibleLevel: session.hintLevelsByQuestionId[currentQuestion.id] ?? 0,
                                        answeredWithHelpQualified: session.hintQualifiedQuestionIds.contains(currentQuestion.id),
                                        canRecordHelp: hintCanAffectAnswer(questionID: currentQuestion.id),
                                        revealLevel: { level in revealHintLevel(questionID: currentQuestion.id, level: level) },
                                        hintVisibleLongEnough: { qualifyAnsweredWithHelp(questionID: currentQuestion.id) },
                                        openLesson: onOpenHintLesson,
                                        requestsEvidenceFocus: evidenceFocus == .hint,
                                        focusActionRequest: hintActionFocusRequest
                                    )
                                    .id(Self.hintAnchorID)
                                }
                            }
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
                                        requestsEvidenceFocus: (evidenceFocus == .answer || evidenceFocus == nil) && answer.displayIndex == 0,
                                        action: { select(answer) }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onMoveCommand { direction in
                                guard direction == .left else { return }
                                focusHintActionFromAnswerColumn(with: scrollProxy)
                            }
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
                .padding(TVFocusIndicator.scaledEdgeClearance)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .onChange(of: session.selectedSourceIndex) { _, selectedSourceIndex in
                guard selectedSourceIndex != nil else { return }
                scrollFeedbackIntoView(with: scrollProxy)
            }
            .onChange(of: currentQuestionHint?.questionId) { _, _ in
                scrollHintActionIntoViewIfRequested(with: scrollProxy)
            }
            .onChange(of: session.hintLevelsByQuestionId[session.currentQuestion?.id ?? ""] ?? 0) { _, _ in
                scrollHintActionIntoViewIfRequested(with: scrollProxy)
            }
            .onAppear {
                scrollHintActionIntoViewIfRequested(with: scrollProxy)
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
    private static let hintAnchorID = "tv-hint-anchor"
    private static let hintActionAnchorID = "tv-hint-action-anchor"

    private func scrollFeedbackIntoView(with proxy: ScrollViewProxy) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
                proxy.scrollTo(Self.feedbackAnchorID, anchor: .bottom)
            }
        }
    }

    private func scrollHintActionIntoViewIfRequested(with proxy: ScrollViewProxy) {
        guard evidenceFocus == .hint, currentQuestionHint != nil else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            scrollHintActionIntoView(with: proxy)
        }
    }

    private func focusHintActionFromAnswerColumn(with proxy: ScrollViewProxy) {
        guard currentQuestionHint != nil else { return }
        Task { @MainActor in
            scrollHintActionIntoView(with: proxy)
            try? await Task.sleep(nanoseconds: 150_000_000)
            hintActionFocusRequest += 1
        }
    }

    private func scrollHintActionIntoView(with proxy: ScrollViewProxy) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            proxy.scrollTo(Self.hintActionAnchorID, anchor: .center)
        }
    }

    private func select(_ answer: ShuffledAnswer) {
        guard session.selectedSourceIndex == nil else { return }
        if let question = session.currentQuestion {
            let selection = PlatformPracticeSelectionLogic.selectAnswer(
                questionID: question.id,
                qualifiedQuestionIds: session.hintQualifiedQuestionIds,
                answeredWithHelpQuestionIds: session.answeredWithHelpQuestionIds
            )
            session.answeredWithHelpQuestionIds = selection.answeredWithHelpQuestionIds
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
            session.selectedSourceIndex = answer.sourceIndex
        }
        session.answeredCount += 1
        if answer.isCorrect { session.correctCount += 1 }
        let announcement = answer.isCorrect ? String(localized: "Correct") : String(localized: "Incorrect")
        AccessibilityNotification.Announcement(announcement).post()
    }

    @discardableResult
    private func revealHintLevel(questionID: String, level: Int) -> Bool {
        let previousLevel = session.hintLevelsByQuestionId[questionID] ?? 0
        let nextLevel = max(previousLevel, level)
        guard nextLevel != previousLevel else { return false }
        session.hintLevelsByQuestionId[questionID] = nextLevel
        return true
    }

    private func qualifyAnsweredWithHelp(questionID: String) -> Bool {
        let result = PracticeHintRules.qualifyingHint(
            questionID: questionID,
            mode: .immediate,
            alreadySelected: session.selectedSourceIndex != nil,
            reviewSubmitted: false,
            qualifiedQuestionIds: session.hintQualifiedQuestionIds,
            answeredWithHelpQuestionIds: session.answeredWithHelpQuestionIds
        )
        let changed = result.qualifiedQuestionIds != session.hintQualifiedQuestionIds || result.answeredWithHelpQuestionIds != session.answeredWithHelpQuestionIds
        session.hintQualifiedQuestionIds = result.qualifiedQuestionIds
        session.answeredWithHelpQuestionIds = result.answeredWithHelpQuestionIds
        return changed
    }

    private func hintCanAffectAnswer(questionID _: String) -> Bool {
        PracticeHintRules.canRecordHelp(mode: .immediate, alreadySelected: session.selectedSourceIndex != nil, reviewSubmitted: false)
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

private struct TVHintPanel: View {
    let hint: QuestionHint
    let language: BankLanguage
    let visibleLevel: Int
    let answeredWithHelpQualified: Bool
    let canRecordHelp: Bool
    let revealLevel: (Int) -> Void
    let hintVisibleLongEnough: () -> Bool
    let openLesson: (QuestionHintLessonLink) -> Void
    let requestsEvidenceFocus: Bool
    let focusActionRequest: Int

    @State private var qualificationTimer = HintVisibilityQualificationTimer()
    @FocusState private var isShowHintFocused: Bool
    @FocusState private var isReviewFocused: Bool

    private var panelState: PlatformHintPanelState {
        PlatformHintPanelState(hint: hint, language: language, visibleLevel: visibleLevel)
    }

    private var nextLevel: Int? { panelState.nextLevel }
    private var visibleHints: [QuestionHintText] { panelState.visibleHints }
    private var showsLessonLink: Bool { panelState.showsLessonLink }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Label {
                Text("Hint") // l10n: localized
            } icon: {
                Image(systemName: "lightbulb")
            }
            .font(DesignTokens.FontScale.title.weight(.bold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .accessibilityAddTraits(.isHeader)

            Text(canRecordHelp ? String(localized: "Use hints when you need help. Answers after a shown hint are saved as answered with help.") : String(localized: "This hint is available for review. Your current answer has already been scored.")) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("hint-tool-intro")

            if visibleHints.isEmpty {
                Text("No hint is shown yet.")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .accessibilityIdentifier("hint-tool-empty")
            }

            ForEach(visibleHints, id: \.level) { entry in
                hintCard(entry)
            }

            if showsLessonLink {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Button("Review in lesson") { openLesson(hint.lessonLink) } // l10n: localized
                        .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                        .buttonStyle(TVSecondaryButtonStyle())
                        .focused($isReviewFocused)
                        .accessibilityIdentifier("hint-review-in-lesson-button")
                    if tvUsesFrenchInterface {
                        Text("Lesson offered in English only.")
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .accessibilityIdentifier("hint-english-only-lesson-notice")
                    }
                }
                .id("tv-hint-action-anchor")
            }

            if let nextLevel {
                Button(nextLevel == 1 ? String(localized: "Show Hint 1") : String(localized: "Show Hint 2")) { // l10n: localized
                    revealLevel(nextLevel)
                    HintAccessibilityAnnouncements.postHintShown(level: nextLevel)
                }
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(TVPrimaryButtonStyle())
                .focused($isShowHintFocused)
                .accessibilityIdentifier("hint-show-level-\(nextLevel)-button")
                .id("tv-hint-action-anchor")
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                .strokeBorder(DesignTokens.Colors.border, lineWidth: 2)
        )
        .onAppear {
            syncQualificationTimer()
            syncActionFocus()
        }
        .onDisappear { qualificationTimer.cancel() }
        .onChange(of: hint.questionId) { _, _ in syncQualificationTimer() }
        .onChange(of: visibleLevel) { _, _ in
            syncQualificationTimer()
            syncActionFocus()
        }
        .onChange(of: focusActionRequest) { _, _ in focusCurrentAction() }
        .onChange(of: canRecordHelp) { _, _ in syncQualificationTimer() }
        .onChange(of: answeredWithHelpQualified) { _, _ in syncQualificationTimer() }
    }

    private func hintCard(_ entry: QuestionHintText) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(String.localizedStringWithFormat(String(localized: "Hint %d"), entry.level)) // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("hint-level-\(entry.level)-title")
            Text(panelState.localizedHintText(entry)) // l10n: content(question)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("hint-level-\(entry.level)-body")
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }

    private func syncActionFocus() {
        if showsLessonLink || requestsEvidenceFocus {
            focusCurrentAction()
        }
    }

    private func focusCurrentAction() {
        if showsLessonLink {
            isReviewFocused = true
        } else if nextLevel != nil {
            isShowHintFocused = true
        }
    }

    private func syncQualificationTimer() {
        guard visibleLevel > 0 else {
            qualificationTimer.cancel()
            return
        }
        qualificationTimer.begin(
            questionID: hint.questionId,
            canRecordHelp: canRecordHelp,
            alreadyQualified: answeredWithHelpQualified
        ) {
            guard hintVisibleLongEnough() else { return }
            AccessibilityNotification.Announcement(String(localized: "Answers to this question will be saved as answered with help.")).post()
        }
    }
}

private struct TVLessonView: View {
    let lesson: Lesson
    let sectionAnchor: String?
    let onPractice: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    Button("Practice", action: onPractice) // l10n: localized
                        .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                        .buttonStyle(TVSecondaryButtonStyle())
                        .accessibilityIdentifier("lesson-return-to-practice-button")
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(english(lesson.id)) // l10n: content(en)
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                        Text(english(lesson.title.en)) // l10n: content(en)
                            .font(DesignTokens.FontScale.display.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("lesson-reader-title")
                        if tvUsesFrenchInterface {
                            Text("Lesson offered in English only.")
                                .font(DesignTokens.FontScale.body.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.inkMuted)
                                .accessibilityIdentifier("hint-english-only-lesson-notice")
                        }
                    }
                    .padding(DesignTokens.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))

                    LessonMarkdownView(lesson: lesson, targetAnchor: sectionAnchor)
                        .padding(DesignTokens.Spacing.xl)
                        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous))
                }
                .padding(TVFocusIndicator.scaledEdgeClearance)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onAppear { scrollToTarget(with: scrollProxy) }
            .onChange(of: sectionAnchor) { _, _ in scrollToTarget(with: scrollProxy) }
        }
        .accessibilityIdentifier("tv-lesson-screen")
    }

    private func scrollToTarget(with proxy: ScrollViewProxy) {
        guard let sectionAnchor else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: DesignTokens.Motion.fast)) {
                proxy.scrollTo(sectionAnchor, anchor: .top)
            }
            AccessibilityNotification.Announcement(String(localized: "Lesson section opened.")).post()
        }
    }
}

private struct TVAnswerButton: View {
    let answer: ShuffledAnswer
    let displayLetter: String
    let language: BankLanguage
    let selectedSourceIndex: Int?
    let requestsEvidenceFocus: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride
    @FocusState private var isFocused: Bool

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

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
            .tvFocusRing(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous),
                isFocused: isFocused,
                unfocusedColor: border,
                unfocusedLineWidth: isSelected || semantic ? 4 : 2
            )
            .scaleEffect(!reduceMotion && isFocused ? 1.025 : 1)
        }
        .buttonStyle(TVCustomFocusButtonStyle())
        .focused($isFocused)
        .focusEffectDisabled()
        .disabled(isAnswered)
        .accessibilityLabel(Text(accessibilityLabel)) // l10n: content(question)
        .accessibilityIdentifier("answer-\(displayLetter)-button")
        .accessibilityHint(isAnswered ? Text("Question already answered. Use Next question to continue.") : Text("Selects this answer")) // l10n: localized
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onAppear {
            if requestsEvidenceFocus {
                isFocused = true
            }
        }
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

private struct TVCustomFocusButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

private struct TVPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? DesignTokens.Colors.paper : DesignTokens.Colors.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .frame(minHeight: 72)
            .background(isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.paperInset, in: Capsule())
            .tvFocusRing(
                Capsule(),
                isFocused: isFocused,
                unfocusedColor: isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.inkMuted,
                unfocusedLineWidth: 2
            )
            .contentShape(Capsule())
            .focusEffectDisabled()
            .overlay {
                if !isEnabled {
                    Capsule()
                        .stroke(DesignTokens.Colors.inkMuted, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                        .padding(5)
                }
            }
            .scaleEffect(reduceMotion ? 1 : (isFocused ? 1.04 : (configuration.isPressed ? 0.97 : 1)))
    }
}

private struct TVSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.tvReduceMotionOverride) private var reduceMotionOverride
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(DesignTokens.Colors.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
            .frame(minHeight: 64)
            .background(DesignTokens.Colors.paperInset, in: Capsule())
            .tvFocusRing(
                Capsule(),
                isFocused: isFocused,
                unfocusedColor: isEnabled ? DesignTokens.Colors.border : DesignTokens.Colors.inkMuted,
                unfocusedLineWidth: 2
            )
            .contentShape(Capsule())
            .focusEffectDisabled()
            .scaleEffect(reduceMotion ? 1 : (isFocused ? 1.035 : (configuration.isPressed ? 0.97 : 1)))
            .opacity(isEnabled ? 1 : 0.75)
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

private enum TVTopBarLayout {
    case inline
    case stacked
}

private struct TVTopBar: View {
    let title: AttributedString
    let subtitle: Text
    @Binding var language: BankLanguage
    let evidenceFocus: TVEvidenceFocus?
    let onAbout: () -> Void
    var leadingAction: (title: LocalizedStringKey, action: () -> Void)? = nil
    var layout: TVTopBarLayout = .stacked

    var body: some View {
        switch layout {
        case .inline:
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)
                compactControls
            }
        case .stacked:
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                titleBlock
                    .frame(maxWidth: .infinity, alignment: .leading)
                expandedControls
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: content(question)
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .allowsTightening(false)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .accessibilityAddTraits(.isHeader)
            subtitle
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
    }

    private var compactControls: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            if let leadingAction {
                leadingButton(leadingAction)
            }
            Button("About", action: onAbout)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(TVSecondaryButtonStyle())
                .accessibilityLabel(Text("About Canadian Ham")) // l10n: localized
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var expandedControls: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            if let leadingAction {
                leadingButton(leadingAction)
            }
            Spacer()
            Button("About", action: onAbout)
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(TVSecondaryButtonStyle())
                .accessibilityLabel(Text("About Canadian Ham")) // l10n: localized
        }
    }

    private func leadingButton(_ leadingAction: (title: LocalizedStringKey, action: () -> Void)) -> some View {
        Button(leadingAction.title, action: leadingAction.action) // l10n: localized
            .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
            .buttonStyle(TVSecondaryButtonStyle())
            .accessibilityHint(Text("Returns to the category grid")) // l10n: localized
    }
}

private struct TVMorseView: View {
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
                .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                .buttonStyle(TVSecondaryButtonStyle())
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
                Text("Morse") // l10n: localized
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Preview") // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            Text("Quick listen plays a short practice group. The text is revealed only after playback.") // l10n: localized
                .font(DesignTokens.FontScale.bodyLarge)
                .foregroundStyle(DesignTokens.Colors.ink)
            HStack(spacing: DesignTokens.Spacing.xl) {
                Button("Play") { play() } // l10n: localized
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .buttonStyle(TVSecondaryButtonStyle())
                    .disabled(isPlaying)
                Button("Stop") { stop(reveal: false, message: String(localized: "Morse playback stopped.")) } // l10n: localized
                    .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .buttonStyle(TVSecondaryButtonStyle())
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
        .accessibilityIdentifier("tv-morse-screen")
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

private let tvAboutRBR4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"

private struct TVAboutView: View {
    let bank: QuestionBank
    let onCategories: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack {
                    Button("Categories", action: onCategories)
                        .font(DesignTokens.FontScale.bodyLarge.weight(.bold))
                        .buttonStyle(TVSecondaryButtonStyle())
                    Spacer()
                }

                Text("About Canadian Ham")
                    .font(DesignTokens.FontScale.display.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    TVPaperSection(title: "Bank", accessibilityIdentifier: "tv-about-bank-section") {
                        Text("Active bank: \(bank.manifest.bankId), effective \(bank.manifest.effectiveDate).")
                        Text("Questions: \(bank.questions.count); categories: \(bank.categories.count); subsections: \(bank.subsections.count).") // l10n: localized
                    }
                    TVPaperSection(title: "Sources", accessibilityIdentifier: "tv-about-sources-section") {
                        Text("ISED Amateur Radio Operator Certificate Basic Qualification question bank, effective \(bank.manifest.effectiveDate).")
                        Text("Question bank source URL: \(verbatimTVText(bank.manifest.source.url))")
                        Text("RBR-4, Standards for the Operation of Radio Stations in the Amateur Radio Service: \(verbatimTVText(tvAboutRBR4CitationURL))")
                        Text("ISED provides the Basic exam reference sheet with formulas and block diagrams at the exam; the reference PDFs are source artifacts and are not shipped in the apps.")
                    }
                    TVPaperSection(title: "Attribution", accessibilityIdentifier: "tv-about-attribution-section") {
                        // TODO(task-1.1): Replace this draft attribution with the exact wording from the recorded ISED permission before public release. Permission remains pending: requested 2026-10-02; granted pending.
                        Text("Draft attribution, not in effect: ISED written permission has been requested and has not yet been granted. Replace this draft with the wording from the recorded permission (task-1.1) before public release.")
                            .accessibilityLabel(Text(english("Draft attribution, not in effect: ISED written permission has been requested and has not yet been granted. Replace this draft with the wording from the recorded permission (task-1.1) before public release."))) // l10n: content(en)
                        Text("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page.")
                            .accessibilityLabel(Text(english("Contains information reproduced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification question bank, used with permission. Source materials are available from ISED's Amateur Radio Operator Certificate Services downloads page."))) // l10n: content(en)
                    }
                    TVPaperSection(title: "Disclaimer", accessibilityIdentifier: "tv-about-disclaimer-section") {
                        Text("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.")
                            .accessibilityLabel(Text(english("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner."))) // l10n: content(en)
                    }
                    TVPaperSection(title: "Privacy", accessibilityIdentifier: "tv-about-privacy-section") {
                        Text("Canadian Ham works fully offline with bundled content and has no accounts, analytics, telemetry, ads, networking code, iCloud sync, push notifications, remote config, or third-party SDKs. Practice sessions are kept only while the app is open; nothing is saved or sent.")
                    }
                }
            }
            .padding(TVFocusIndicator.scaledEdgeClearance)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .accessibilityIdentifier("tv-about-screen")
    }
}

private struct TVPaperSection<Content: View>: View {
    let title: LocalizedStringKey
    let accessibilityIdentifier: String
    @ViewBuilder let content: () -> Content

    @FocusState private var isFocused: Bool

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
        .tvFocusRing(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous),
            isFocused: isFocused,
            unfocusedColor: DesignTokens.Colors.border,
            unfocusedLineWidth: 2
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier)
        .focusable(true)
        .focused($isFocused)
        .focusEffectDisabled()
    }
}

private struct PlatformContentLoadSimulationError: LocalizedError {
    var errorDescription: String? { "Content library unavailable for testing." }
}

private struct PlatformLessonUnavailableError: LocalizedError {
    var errorDescription: String? { "Lesson content is unavailable." }
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

private func verbatimTVText(_ string: String) -> Text {
    Text(verbatim: string) // l10n: verbatim
}

private var tvUsesFrenchInterface: Bool {
    Bundle.main.preferredLocalizations.first?.lowercased().hasPrefix("fr") == true
}

private func english(_ string: String) -> AttributedString {
    var attributedString = AttributedString(string)
    attributedString.languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    return attributedString
}
