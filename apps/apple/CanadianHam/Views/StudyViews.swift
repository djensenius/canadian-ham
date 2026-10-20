import Accessibility
import CanadianHamContent
import CanadianHamEngine
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let revision: Int
    let morseEnabled: Bool
    let startPractice: (PracticeScope) -> Void
    let openMockExam: () -> Void
    let openMorse: () -> Void

#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif
    @State private var summary: HomeSummary?
    @State private var errorMessage: String?

    @ViewBuilder
    private var homeActionButtons: some View {
        tokenButton("Start practice") { startPractice(.all) }
        tokenButton("Mock exam") { openMockExam() }
        if morseEnabled {
            tokenButton("Morse") { openMorse() }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text(bank.courseBankID == .advanced ? "Offline, private Advanced practice" : "Offline, private study") // l10n: localized
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text(bank.courseBankID == .advanced ? "Ready for the Advanced qualification?" : "Ready for Basic with Honours?") // l10n: localized
                        .font(DesignTokens.FontScale.display.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(bank.courseBankID == .advanced ? "Study for the Amateur Radio Operator Certificate with Advanced Qualification using the official ISED question bank. Advanced progress is tracked separately from Basic." : "Study for the Amateur Radio Operator Certificate with Basic Qualification using the official ISED question bank.") // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    homeActionLayout
                }
                .paperCard()

                if let errorMessage {
                    MessagePanel(title: "Readiness unavailable", message: errorMessage, kind: .warning)
                } else if let summary {
                    readinessCard(summary)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Practice categories")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(bank.categories) { category in
                        Button {
                            startPractice(.category(category.id))
                        } label: {
                            CategoryCard(category: category, language: language)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(categoryPracticeAccessibilityLabel(category))) // l10n: content(question)
                        .accessibilityIdentifier("category-\(category.id)-button")
                    }
                }
                .paperCard()
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Home")
        .task(id: revision) { loadSummary() }
    }

    @ViewBuilder
    private var homeActionLayout: some View {
        if usesCompactHomeActions {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                homeActionButtons
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack {
                    homeActionButtons
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    homeActionButtons
                }
            }
        }
    }

    private var usesCompactHomeActions: Bool {
#if os(iOS)
        horizontalSizeClass == .compact
#else
        false
#endif
    }

    @ViewBuilder
    private func readinessCard(_ summary: HomeSummary) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Readiness")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Label {
                Text(summary.title) // l10n: localized
            } icon: {
                Image(systemName: summary.symbol)
            }
            .font(DesignTokens.FontScale.body.weight(.bold))
            .foregroundStyle(summary.tint)
            Text(summary.message) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("Due review: \(summary.dueReviewCount). Weak subsections: \(summary.weakSubsectionCount). Completed mock exams: \(summary.completedExamCount).")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            readinessActionButtons
        }
        .paperCard()
        .accessibilityIdentifier("readiness-card")
    }

    @ViewBuilder
    private var readinessActionButtons: some View {
        HStack {
            tokenButton("Practice weak areas") { startPractice(.weak) }
            tokenButton("Review due questions") { startPractice(.due) }
        }
    }

    private func categoryPracticeAccessibilityLabel(_ category: BankCategory) -> AttributedString {
        var label = AttributedString(String(localized: "Practice"))
        label += AttributedString(" ")
        label += localized(category.name.text(for: language), language: category.name.resolvedLanguage(for: language))
        label += AttributedString(", \(localizedQuestionCount(category.questionCount))")
        return label
    }

    private func loadSummary() {
        do {
            let progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            let attempts = try progressStore.examAttempts().filter { $0.bankId == bank.manifest.bankId }
            let now = try AppleStudyEngine.canonicalNow()
            let readiness = try AppleStudyEngine.readiness(bank: bank, progress: progress, attempts: attempts, now: now)
            let weak = AppleStudyEngine.weakSubsections(progress: progress, latestExam: attempts.sorted { $0.submittedAt > $1.submittedAt }.first)
            summary = HomeSummary(readiness: readiness, hasHonours: bank.courseBankID.hasHonours, dueReviewCount: try dueCount(records: progress, now: now), weakSubsectionCount: weak.count, completedExamCount: attempts.count)
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

private struct HomeSummary {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let symbol: String
    let tint: Color
    let dueReviewCount: Int
    let weakSubsectionCount: Int
    let completedExamCount: Int

    init(readiness: ReadinessResult, hasHonours: Bool, dueReviewCount: Int, weakSubsectionCount: Int, completedExamCount: Int) {
        self.dueReviewCount = dueReviewCount
        self.weakSubsectionCount = weakSubsectionCount
        self.completedExamCount = completedExamCount
        switch readiness.state {
        case .notEnoughData:
            title = "Not enough data"
            message = hasHonours ? "Complete at least two mock exams before Canadian Ham claims pass or honours readiness. Keep practicing by category while you build evidence." : "Complete at least two mock exams before Canadian Ham claims pass readiness. Keep practicing by topic while you build evidence."
            symbol = "chart.bar.doc.horizontal"
            tint = DesignTokens.Colors.ink
        case .needsReview:
            title = "Needs review"
            message = "Your local progress shows weak categories, due reviews, or fewer passing mock exams than needed. Review weak and due questions before relying on exam readiness."
            symbol = "exclamationmark.triangle.fill"
            tint = DesignTokens.Colors.warningText
        case .passReady:
            title = "Pass-ready"
            message = hasHonours ? "At least two recent mock exams meet the 70% pass threshold. Keep working toward 80% for Basic with Honours." : "At least two recent mock exams meet the 70% Advanced pass threshold. There is no Advanced Honours result."
            symbol = "checkmark.seal.fill"
            tint = DesignTokens.Colors.correctText
        case .honoursReady:
            title = "Honours-ready"
            message = "At least two recent mock exams meet the 80% Basic with Honours target with no blocking due-review or weak-category signal."
            symbol = "star.circle.fill"
            tint = DesignTokens.Colors.correctText
        }
    }
}

struct PracticeHubView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let revision: Int
    let startPractice: (PracticeScope) -> Void

    @State private var due = 0
    @State private var weak = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("Practice")
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: DesignTokens.Spacing.md)], spacing: DesignTokens.Spacing.md) {
                    practiceButton(
                        "All questions",
                        detail: String(localized: "Draw from all \(bank.questions.count) questions"),
                        accessibilityLabel: String(localized: "Start all questions. Draw from all \(bank.questions.count) questions"),
                        systemImage: "tray.full",
                        scope: .all
                    )
                    practiceButton(
                        "Weak areas",
                        detail: String(localized: "\(weak) weak subsections"),
                        accessibilityLabel: String(localized: "Start weak areas. \(weak) weak subsections"),
                        systemImage: "exclamationmark.triangle",
                        scope: .weak
                    )
                    practiceButton(
                        "Due review",
                        detail: String(localized: "\(due) due questions; unseen excluded"),
                        accessibilityLabel: String(localized: "Start due review. \(due) due questions; unseen excluded"),
                        systemImage: "calendar.badge.clock",
                        scope: .due
                    )
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Practice categories")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(bank.categories) { category in
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Button { startPractice(.category(category.id)) } label: {
                                CategoryCard(category: category, language: language)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(categoryPracticeAccessibilityLabel(category))) // l10n: content(question)
                            .accessibilityIdentifier("category-\(category.id)-button")

                            DisclosureGroup("Subsections") {
                                ForEach(bank.subsectionsByCategory[category.id] ?? []) { subsection in
                                    Button { startPractice(.subsection(subsection.id)) } label: {
                                        SubsectionCard(subsection: subsection, title: localized(bank.subsectionTitle(subsection, language: language), language: language))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text(subsectionPracticeAccessibilityLabel(subsection))) // l10n: content(question)
                                }
                            }
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        }
                    }
                }
                .paperCard()
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Practice")
        .task(id: revision) { refreshCounts() }
    }

    private func practiceButton(_ title: LocalizedStringKey, detail: String, accessibilityLabel: String, systemImage: String, scope: PracticeScope) -> some View {
        Button { startPractice(scope) } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Label(title, systemImage: systemImage) // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.bold))
                Text(detail) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
            }
            .foregroundStyle(DesignTokens.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .paperCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel)) // l10n: localized
    }

    private func categoryPracticeAccessibilityLabel(_ category: BankCategory) -> AttributedString {
        var label = AttributedString(String(localized: "Practice category"))
        label += AttributedString(" ")
        label += localized(category.name.text(for: language), language: category.name.resolvedLanguage(for: language))
        label += AttributedString(", \(localizedQuestionCount(category.questionCount))")
        return label
    }

    private func subsectionPracticeAccessibilityLabel(_ subsection: BankSubsection) -> AttributedString {
        var label = AttributedString(String(localized: "Practice subsection"))
        label += AttributedString(" ")
        label += localized(bank.subsectionTitle(subsection, language: language), language: language)
        label += AttributedString(", \(localizedQuestionCount(subsection.questionCount))")
        return label
    }

    private func refreshCounts() {
        do {
            let progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            let attempts = try progressStore.examAttempts().filter { $0.bankId == bank.manifest.bankId }
            let now = try AppleStudyEngine.canonicalNow()
            due = try dueCount(records: progress, now: now)
            weak = AppleStudyEngine.weakSubsections(progress: progress, latestExam: attempts.sorted { $0.submittedAt > $1.submittedAt }.first).count
        } catch {
            due = 0
            weak = 0
        }
    }
}

@MainActor
final class PracticeSessionState: ObservableObject {
    @Published var items: [PracticeQuestionItem] = []
    @Published var currentIndex = 0
    @Published var selectedByQuestionId: [String: Int] = [:]
    @Published var hintLevelsByQuestionId: [String: Int] = [:]
    @Published var hintQualifiedQuestionIds: Set<String> = []
    @Published var answeredWithHelpQuestionIds: Set<String> = []
    @Published var committedQuestionIds: Set<String> = []
    @Published var reviewSubmitted = false
    @Published var loadedScope: PracticeScope?
    @Published var loadedPracticeMode: ApplePreferences.PracticeMode?
    @Published var loadedDataRevision = 0
    @Published var loadedLocalDataReplacementRevision = 0
    @Published var answeredCount = 0
    @Published var correctCount = 0
    @Published var errorMessage: String?
    let calculatorViewModel = ExamCalculatorViewModel()

    var hasUnfinishedCourseWork: Bool {
        guard !items.isEmpty, let loadedPracticeMode else { return false }
        switch loadedPracticeMode {
        case .immediate:
            return answeredCount > 0 && answeredCount < items.count
        case .reviewLater:
            return answeredCount > 0 && !reviewSubmitted
        }
    }
}

@MainActor
final class PracticeSessionStateCache: ObservableObject {
    private var states: [PracticeScope: PracticeSessionState] = [:]

    func state(for scope: PracticeScope) -> PracticeSessionState {
        if let state = states[scope] { return state }
        let state = PracticeSessionState()
        states[scope] = state
        return state
    }

    func clear() {
        states.removeAll()
    }

    var hasUnfinishedCourseWork: Bool {
        states.values.contains { $0.hasUnfinishedCourseWork }
    }
}

struct PracticeSessionView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let scope: PracticeScope
    @Binding var language: BankLanguage
    @ObservedObject private var state: PracticeSessionState
    let dataRevision: Int
    let localDataReplacementRevision: Int
    let headerAccessory: AnyView?
    let onExamToolPresentationChanged: (Bool) -> Void
    let onOpenHintLesson: (QuestionHintLessonLink) -> Void
    let onDataChanged: () -> Void

    @State private var selectedExamTool: ExamTool?
    @State private var calculatorFocused = false
#if os(iOS)
    @State private var duoPostureProvider: (any DuoPostureProviding)?
    @State private var hingePeekStateMachine = HingePeekStateMachine()
    @State private var hingePeekPresentationState = HingeHintPeekPresentationState()
    @State private var hingePeekDwellRecheckTask: Task<Void, Never>?
#if DEBUG
    @State private var debugHingePlaybackTimestamp: TimeInterval = 0
    @State private var debugHingePlaybackTriggerHidden = false
#endif
#endif
    @ObservedObject private var calculatorViewModel: ExamCalculatorViewModel
    @Environment(\.canadianHamContentLibrary) private var contentLibrary

    init(
        bank: QuestionBank,
        progressStore: ProgressStoreService,
        scope: PracticeScope,
        language: Binding<BankLanguage>,
        state: PracticeSessionState,
        dataRevision: Int,
        localDataReplacementRevision: Int,
        headerAccessory: AnyView? = nil,
        onExamToolPresentationChanged: @escaping (Bool) -> Void = { _ in },
        onOpenHintLesson: @escaping (QuestionHintLessonLink) -> Void = { _ in },
        onDataChanged: @escaping () -> Void
    ) {
        self.bank = bank
        self.progressStore = progressStore
        self.scope = scope
        _language = language
        self.state = state
        _calculatorViewModel = ObservedObject(wrappedValue: state.calculatorViewModel)
        self.dataRevision = dataRevision
        self.localDataReplacementRevision = localDataReplacementRevision
        self.headerAccessory = headerAccessory
        self.onExamToolPresentationChanged = onExamToolPresentationChanged
        self.onOpenHintLesson = onOpenHintLesson
        self.onDataChanged = onDataChanged
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                if let headerAccessory {
                    headerAccessory
                }
                header
                if let errorMessage = state.errorMessage {
                    MessagePanel(title: "Practice unavailable", message: errorMessage, kind: .warning)
                } else if hasStalePracticeMode {
                    ProgressView()
                        .controlSize(.large)
                        .accessibilityLabel(Text("Practice")) // l10n: localized
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if state.items.isEmpty {
                    ContentUnavailableView("No questions found", systemImage: "tray", description: Text(emptyMessage)) // l10n: localized
                        .foregroundStyle(DesignTokens.Colors.ink)
                } else if state.reviewSubmitted {
                    practiceReview
                } else {
                    questionView(state.items[state.currentIndex])
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(Text(scopeTitleAttributed)) // l10n: localized
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .lessonReaderOpaqueNavigationBar()
        .examToolPresentation(selectedTool: $selectedExamTool, calculator: calculatorViewModel, calculatorFocused: $calculatorFocused, referenceSheetConfiguration: referenceSheetConfiguration, hintContext: hintToolContext)
        .task(id: sessionReloadKey) { loadSessionIfNeeded() }
        .onAppear { calculatorViewModel.updateLocale(canadianHamInterfaceCalculatorLocale()) }
        .onChange(of: selectedExamTool) { _, next in
#if os(iOS)
            applyHingePeekPresentation(.selectedToolChanged(next))
#endif
            onExamToolPresentationChanged(next != nil)
        }
        .onDisappear { onExamToolPresentationChanged(false) }
#if os(iOS)
        .background {
            if let duoPostureProvider {
                DuoPostureObserverView(provider: duoPostureProvider)
                    .frame(width: 0, height: 0)
            }
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamHingePlaybackDebugStatus") {
                Text(verbatim: "Hinge playback progress") // l10n: verbatim DEBUG-only UI test hook
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("debug-hinge-playback-progress")
                    .accessibilityValue(Text(verbatim: String(format: "%.3f", debugHingePlaybackTimestamp))) // l10n: verbatim
                    .allowsHitTesting(false)
            }
#endif
        }
        .onAppear { configureDuoPostureProviderIfNeeded() }
        .onDisappear { clearDuoPostureProviderCallback() }
        .onChange(of: scope) { _, _ in resetHingePeekForSessionChange() }
        .onChange(of: ObjectIdentifier(state)) { _, _ in resetHingePeekForSessionChange() }
        .onChange(of: state.currentIndex) { _, _ in resetHingePeekForQuestionChange() }
        .onChange(of: state.selectedByQuestionId) { _, _ in applyHingePeekPresentation(.eligibilityChanged) }
        .onChange(of: state.reviewSubmitted) { _, _ in applyHingePeekPresentation(.eligibilityChanged) }
#endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(scopeTitleAttributed) // l10n: localized
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("practice-category-title")
            Text(sessionProgressText) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("practice-session-tally")
                .accessibilityHidden(true)
            Text("Due review excludes unseen questions. Progress is saved locally after each answer.")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .accessibilityIdentifier("practice-category-summary")
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel) // l10n: localized
    }

    private var sessionProgressText: String {
        let mode = progressStore.preferences.practiceMode.localizedString
        let tally = localizedCorrectOutOfAnswered(correct: state.correctCount, answered: state.answeredCount)
        switch progressStore.preferences.practiceMode {
        case .immediate:
            return String(localized: "Mode: \(mode). Session tally: \(tally).")
        case .reviewLater:
            if state.reviewSubmitted {
                return String(localized: "Mode: \(mode). Review complete: \(tally).")
            } else {
                let progress = localizedAnsweredOutOfTotal(answered: state.answeredCount, total: state.items.count)
                return String(localized: "Mode: \(mode). \(progress); results are hidden until review.")
            }
        }
    }

    private var scopeTitle: String {
        switch scope {
        case .all: String(localized: "All questions")
        case .weak: String(localized: "Weak areas")
        case .due: String(localized: "Due review")
        case .category(let id): bank.categories.first { $0.id == id }?.name.text(for: language) ?? id
        case .subsection(let id): bank.subsectionsById[id].map { bank.subsectionTitle($0, language: language) } ?? String(localized: "Subsection \(id)")
        }
    }

    private var scopeTitleAttributed: AttributedString {
        switch scope {
        case .category(let id):
            localized(bank.categories.first { $0.id == id }?.name.text(for: language) ?? id, language: language)
        case .subsection(let id):
            localized(bank.subsectionsById[id].map { bank.subsectionTitle($0, language: language) } ?? String(localized: "Subsection \(id)"), language: language)
        default:
            AttributedString(scopeTitle)
        }
    }

    private var headerAccessibilityLabel: Text {
        var label = scopeTitleAttributed
        label += AttributedString(". \(sessionProgressText). ")
        label += AttributedString(String(localized: "Due review excludes unseen questions. Progress is saved locally after each answer."))
        return Text(label) // l10n: localized
    }

    private var emptyMessage: String {
        switch scope {
        case .due: String(localized: "No stored progress records are due. Unseen questions are not included in due review.")
        case .weak: String(localized: "No weak subsections are available yet. Complete practice or a mock exam first.")
        default: String(localized: "No bundled questions match this scope.")
        }
    }

    private var sessionReloadKey: String {
        "\(scope.title)/\(localDataReplacementRevision)/\(progressStore.preferences.practiceMode.rawValue)"
    }

    private var hasStalePracticeMode: Bool {
        guard let loadedPracticeMode = state.loadedPracticeMode else { return false }
        return loadedPracticeMode != progressStore.preferences.practiceMode && !state.items.isEmpty
    }

    private func questionView(_ item: PracticeQuestionItem) -> some View {
        let question = item.question
        let selected = state.selectedByQuestionId[question.id]
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            ExamToolButtons(availableTools: availableExamTools) { openExamTool($0) }
#if os(iOS) && DEBUG
            if ProcessInfo.processInfo.arguments.contains("-CanadianHamHingePlaybackDebugTrigger"), !debugHingePlaybackTriggerHidden {
                Button {
                    configureDuoPostureProviderIfNeeded()
                    duoPostureProvider?.triggerNextDebugPlaybackSegment()
                    if ProcessInfo.processInfo.arguments.contains("-CanadianHamHingePlaybackDebugTriggerHidesAfterTap") {
                        debugHingePlaybackTriggerHidden = true
                    }
                } label: {
                    Text(verbatim: "Run") // l10n: verbatim DEBUG-only UI test hook
                }
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .frame(minHeight: 44)
                .accessibilityIdentifier("debug-hinge-playback-trigger")
            }
#endif
            QuestionCard(question: question, language: language, onInteraction: clearCalculatorKeyboardFocus)
                .simultaneousGesture(examContentTapGesture)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Answers")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("answers-title")
                ForEach(Array(item.choicePermutation.enumerated()), id: \.offset) { displayIndex, sourceIndex in
                    if let answer = question.answers.first(where: { $0.sourceIndex == sourceIndex }) {
                        AnswerChoiceButton(
                            answer: answer,
                            displayIndex: displayIndex,
                            language: language,
                            selectedSourceIndex: selected,
                            showCorrectness: selected != nil && progressStore.preferences.practiceMode == .immediate,
                            disabled: selected != nil && progressStore.preferences.practiceMode == .immediate,
                            onKeyboardFocus: clearCalculatorKeyboardFocus
                        ) {
                            clearCalculatorKeyboardFocus()
                            select(sourceIndex: sourceIndex, question: question)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            clearCalculatorKeyboardFocus()
                        })
                    }
                }
            }
            .simultaneousGesture(examContentTapGesture)
            if let selected, progressStore.preferences.practiceMode == .immediate {
                PracticeFeedback(question: question, selectedSourceIndex: selected, language: language, choicePermutation: item.choicePermutation)
                Button(state.currentIndex + 1 == state.items.count ? "Finish session" : "Next question") { // l10n: localized
                    advanceOrFinish()
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
                .frame(minHeight: 44)
                .accessibilityIdentifier("next-question-button")
            } else if progressStore.preferences.practiceMode == .reviewLater {
                Button(state.currentIndex + 1 == state.items.count ? "Submit for review" : "Next question") { // l10n: localized
                    advanceReviewLater()
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
                .disabled(selected == nil)
                .accessibilityHint(selected == nil ? Text("Choose an answer before continuing") : Text("Continues without feedback until review")) // l10n: localized
            }
        }
    }

    private var availableExamTools: [ExamTool] {
        var tools = appleExamTools(for: bank, referenceSheetConfiguration: referenceSheetConfiguration)
        if currentQuestionHint != nil {
            tools.insert(.hint, at: min(1, tools.count))
        }
        return tools
    }

    private var currentQuestionHint: QuestionHint? {
        guard let item = state.items[safe: state.currentIndex], bank.courseBankID == .basic else { return nil }
        return contentLibrary?.questionHintsByQuestionId[item.question.id]
    }

    private var hintToolContext: HintToolContext? {
        guard let item = state.items[safe: state.currentIndex], let hint = currentQuestionHint else { return nil }
        let questionID = item.question.id
        return HintToolContext(
            hint: hint,
            language: language,
            visibleLevel: state.hintLevelsByQuestionId[questionID] ?? 0,
            answeredWithHelpQualified: state.hintQualifiedQuestionIds.contains(questionID),
            canRecordHelp: hintCanAffectAnswer(questionID: questionID),
            referenceSheetAvailable: referenceSheetConfiguration.availableOnApple,
            revealLevel: { level in revealHintLevel(questionID: questionID, level: level) },
            hintVisibleLongEnough: { qualifyAnsweredWithHelp(questionID: questionID) },
            openLesson: { link in openHintLesson(link) }
        )
    }

    private func openExamTool(_ tool: ExamTool) {
        selectedExamTool = tool
        calculatorFocused = shouldFocusCalculator(for: tool, calculatorViewModel: calculatorViewModel)
        if tool == .calculator {
            Task { @MainActor in
                calculatorViewModel.acceptHardwareKeyboardInput()
                calculatorFocused = true
            }
        }
    }

    @discardableResult
    private func revealHintLevel(questionID: String, level: Int) -> Bool {
        let previousLevel = state.hintLevelsByQuestionId[questionID] ?? 0
        let nextLevel = max(previousLevel, level)
        state.hintLevelsByQuestionId[questionID] = nextLevel
        return nextLevel > previousLevel
    }

    private func qualifyAnsweredWithHelp(questionID: String) -> Bool {
        let currentQualified = state.hintQualifiedQuestionIds
        let currentAnsweredWithHelp = state.answeredWithHelpQuestionIds
        let result = PracticeHintRules.qualifyingHint(
            questionID: questionID,
            mode: progressStore.preferences.practiceMode,
            alreadySelected: state.selectedByQuestionId[questionID] != nil,
            reviewSubmitted: state.reviewSubmitted,
            qualifiedQuestionIds: currentQualified,
            answeredWithHelpQuestionIds: currentAnsweredWithHelp
        )
        state.hintQualifiedQuestionIds = result.qualifiedQuestionIds
        state.answeredWithHelpQuestionIds = result.answeredWithHelpQuestionIds
        return result.qualifiedQuestionIds != currentQualified || result.answeredWithHelpQuestionIds != currentAnsweredWithHelp
    }

    private func hintCanAffectAnswer(questionID: String) -> Bool {
        PracticeHintRules.canRecordHelp(
            mode: progressStore.preferences.practiceMode,
            alreadySelected: state.selectedByQuestionId[questionID] != nil,
            reviewSubmitted: state.reviewSubmitted
        )
    }

#if os(iOS)
    private func configureDuoPostureProviderIfNeeded() {
        if duoPostureProvider == nil {
            duoPostureProvider = DuoPostureProviderFactory.makeProvider()
        }
        applyHingePeekPresentation(.viewAppeared)
        duoPostureProvider?.onPostureChanged = { sample in
            handleDuoPosture(sample)
        }
        if let sample = duoPostureProvider?.sample {
            handleDuoPosture(sample)
        }
    }

    private func clearDuoPostureProviderCallback() {
        applyHingePeekPresentation(.viewDisappeared)
        duoPostureProvider?.onPostureChanged = nil
        hingePeekStateMachine.reset()
        cancelHingePeekDwellRecheck()
    }

    private func handleDuoPosture(_ sample: DuoPostureSample) {
#if DEBUG
        debugHingePlaybackTimestamp = sample.timestamp
#endif
        var receivedSample = sample
        receivedSample.timestamp = ProcessInfo.processInfo.systemUptime
        let result = hingePeekStateMachine.update(sample: receivedSample)
        applyHingePeekUpdateResult(result, lastSampleTimestamp: receivedSample.timestamp)
    }

    private func applyHingePeekUpdateResult(_ result: HingePeekUpdateResult, lastSampleTimestamp: TimeInterval) {
        if let deadline = result.pendingDwellDeadline {
            scheduleHingePeekDwellRecheck(deadline: deadline, lastSampleTimestamp: lastSampleTimestamp)
        } else {
            cancelHingePeekDwellRecheck()
        }

        if result.startedPeeking {
            applyHingePeekPresentation(.postureStarted)
        } else if result.endedByPostureReset {
            applyHingePeekPresentation(.postureEnded)
        }
    }

    private func scheduleHingePeekDwellRecheck(deadline: TimeInterval, lastSampleTimestamp: TimeInterval) {
        hingePeekDwellRecheckTask?.cancel()
        let delayNanoseconds = UInt64(max(0, deadline - lastSampleTimestamp) * 1_000_000_000)
        hingePeekDwellRecheckTask = Task { @MainActor in
            if delayNanoseconds > 0 {
                try? await Task.sleep(nanoseconds: delayNanoseconds)
            }
            guard !Task.isCancelled else { return }
            let result = hingePeekStateMachine.recheck(timestamp: deadline)
            applyHingePeekUpdateResult(result, lastSampleTimestamp: deadline)
        }
    }

    private func cancelHingePeekDwellRecheck() {
        hingePeekDwellRecheckTask?.cancel()
        hingePeekDwellRecheckTask = nil
    }

    private var hingePeekPresentationContext: HingeHintPeekPresentationContext {
        guard let item = state.items[safe: state.currentIndex] else {
            return HingeHintPeekPresentationContext(questionID: nil, canPeek: false, selectedTool: selectedExamTool)
        }
        let questionID = item.question.id
        let canPeek = HingeHintPeekRules.canPeekHint(
            sessionKind: .practice(progressStore.preferences.practiceMode),
            hasHint: currentQuestionHint != nil,
            alreadySelected: state.selectedByQuestionId[questionID] != nil,
            reviewSubmitted: state.reviewSubmitted
        )
        return HingeHintPeekPresentationContext(questionID: questionID, canPeek: canPeek, selectedTool: selectedExamTool)
    }

    private func applyHingePeekPresentation(_ action: HingeHintPeekPresentationAction) {
        let effects = HingeHintPeekPresentationReducer.reduce(
            state: &hingePeekPresentationState,
            action: action,
            context: hingePeekPresentationContext
        )
        for effect in effects {
            applyHingePeekPresentationEffect(effect)
        }
    }

    private func applyHingePeekPresentationEffect(_ effect: HingeHintPeekPresentationEffect) {
        switch effect {
        case .presentHint(let questionID):
            let revealedNewLevel = revealHintLevel(questionID: questionID, level: 1)
            if revealedNewLevel {
                HintAccessibilityAnnouncements.postHintShown(level: 1)
            }
            calculatorFocused = false
            calculatorViewModel.suspendHardwareKeyboardInput()
            if selectedExamTool != .hint {
                selectedExamTool = .hint
            }
        case .closeHint:
            if selectedExamTool == .hint {
                selectedExamTool = nil
            }
        }
    }

    private func resetHingePeekForQuestionChange() {
        applyHingePeekPresentation(.questionChanged)
        hingePeekStateMachine.reset()
        cancelHingePeekDwellRecheck()
    }

    private func resetHingePeekForSessionChange() {
        hingePeekPresentationState = HingeHintPeekPresentationState()
        hingePeekStateMachine.reset()
        cancelHingePeekDwellRecheck()
        configureDuoPostureProviderIfNeeded()
    }
#endif

    private func openHintLesson(_ link: QuestionHintLessonLink) {
        calculatorFocused = false
        calculatorViewModel.suspendHardwareKeyboardInput()
        selectedExamTool = nil
        onOpenHintLesson(link)
    }

    private func clearCalculatorKeyboardFocus() {
        calculatorFocused = false
        calculatorViewModel.suspendHardwareKeyboardInput()
    }

    private var examContentTapGesture: some Gesture {
        TapGesture().onEnded {
            clearCalculatorKeyboardFocus()
        }
    }

    private var referenceSheetConfiguration: ReferenceSheetConfiguration {
        appleReferenceSheetConfigurationFromLaunchArguments()
    }

    private var practiceReview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Practice review")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(state.items) { item in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(item.question.id) // l10n: verbatim
                        .font(DesignTokens.FontScale.body.monospaced())
                    Text(localized(item.question.text.text(for: language), language: language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    PracticeFeedback(question: item.question, selectedSourceIndex: state.selectedByQuestionId[item.question.id], language: language, choicePermutation: item.choicePermutation)
                    Text("Category \(item.question.categoryId) • Subsection \(item.question.subsectionId).") // l10n: localized
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
                .paperCard()
            }
            tokenButton("Start another session") { loadSession() }
        }
    }

    private func loadSessionIfNeeded() {
        let localDataWasReplaced = state.loadedLocalDataReplacementRevision != localDataReplacementRevision
        let practiceModeChanged = state.loadedPracticeMode != progressStore.preferences.practiceMode
        guard state.loadedScope != scope || state.items.isEmpty || localDataWasReplaced || practiceModeChanged else { return }
        loadSession()
    }

    private func loadSession() {
        do {
            var progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            let attempts = try progressStore.examAttempts().filter { $0.bankId == bank.manifest.bankId }
            let latest = attempts.sorted { $0.submittedAt > $1.submittedAt }.first
            let seed = AppLaunchArguments.value(after: "-CanadianHamPracticeSeed") ?? "practice/\(scopeTitle)/\(UUID().uuidString)"
            let now = try AppleStudyEngine.canonicalNow()
            var loaded = try AppleStudyEngine.buildPracticeItems(
                bank: bank,
                scope: scope,
                progress: progress,
                latestExamItems: latest?.items ?? [],
                seed: seed,
                now: now,
                limit: practiceLimit
            )
            if let forcedQuestionID = AppLaunchArguments.value(after: "-CanadianHamPracticeQuestionID"),
               let question = bank.question(id: forcedQuestionID),
               loaded.contains(where: { $0.question.id == forcedQuestionID }) || scopeContains(question) {
                let forcedAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "practice-answers/\(question.id)/ui-test")
                let forced = PracticeQuestionItem(question: question, choicePermutation: forcedAnswers.map(\.sourceIndex))
                loaded.removeAll { $0.question.id == forcedQuestionID }
                loaded.insert(forced, at: 0)
                loaded = Array(loaded.prefix(practiceLimit))
            }
            // Touch progress so Swift does not warn about the explicit engine-record load in this flow.
            progress.sort { $0.questionId < $1.questionId }
            state.items = loaded
            state.loadedScope = scope
            state.loadedPracticeMode = progressStore.preferences.practiceMode
            state.loadedDataRevision = dataRevision
            state.loadedLocalDataReplacementRevision = localDataReplacementRevision
            state.currentIndex = 0
            state.selectedByQuestionId = [:]
            state.hintLevelsByQuestionId = [:]
            state.hintQualifiedQuestionIds = []
            state.answeredWithHelpQuestionIds = []
            state.committedQuestionIds = []
            state.reviewSubmitted = false
            state.answeredCount = 0
            state.correctCount = 0
            state.errorMessage = nil
            selectedExamTool = nil
            calculatorFocused = false
#if os(iOS)
            hingePeekStateMachine.reset()
            hingePeekPresentationState = HingeHintPeekPresentationState()
            cancelHingePeekDwellRecheck()
#endif
            calculatorViewModel.clearForNewExam(locale: canadianHamInterfaceCalculatorLocale())
        } catch {
            state.errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            state.items = []
            state.loadedScope = nil
            state.loadedPracticeMode = nil
            state.loadedDataRevision = dataRevision
            state.loadedLocalDataReplacementRevision = localDataReplacementRevision
        }
    }

    private var practiceLimit: Int {
#if DEBUG
        if let value = AppLaunchArguments.value(after: "-CanadianHamPracticeLimit"), let limit = Int(value), limit > 0 {
            return limit
        }
#endif
        return 10
    }

    private func scopeContains(_ question: BankQuestion) -> Bool {
        switch scope {
        case .all: true
        case .category(let id): question.categoryId == id
        case .subsection(let id): question.subsectionId == id
        case .weak, .due: false
        }
    }

    private func select(sourceIndex: Int, question: BankQuestion) {
        if let previous = state.selectedByQuestionId[question.id] {
            guard progressStore.preferences.practiceMode == .reviewLater else { return }
            state.selectedByQuestionId[question.id] = sourceIndex
            state.answeredWithHelpQuestionIds = PracticeHintRules.answeredWithHelpQuestionIdsAfterSelection(
                questionID: question.id,
                qualifiedQuestionIds: state.hintQualifiedQuestionIds,
                answeredWithHelpQuestionIds: state.answeredWithHelpQuestionIds
            )
            if previous == 0, sourceIndex != 0 { state.correctCount -= 1 }
            if previous != 0, sourceIndex == 0 { state.correctCount += 1 }
            AccessibilityNotification.Announcement(String(localized: "Selected answer updated")).post()
            return
        }
        state.selectedByQuestionId[question.id] = sourceIndex
        state.answeredWithHelpQuestionIds = PracticeHintRules.answeredWithHelpQuestionIdsAfterSelection(
            questionID: question.id,
            qualifiedQuestionIds: state.hintQualifiedQuestionIds,
            answeredWithHelpQuestionIds: state.answeredWithHelpQuestionIds
        )
        state.answeredCount += 1
        if sourceIndex == 0 { state.correctCount += 1 }
        if progressStore.preferences.practiceMode == .immediate {
            commitAnswer(question: question, sourceIndex: sourceIndex)
            let announcement = sourceIndex == 0 ? String(localized: "Correct") : String(localized: "Incorrect")
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private func commitAnswer(question: BankQuestion, sourceIndex: Int) {
        guard !state.committedQuestionIds.contains(question.id) else { return }
        do {
            let now = try AppleStudyEngine.canonicalNow()
            let progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            let answeredWithHelp = PracticeHintRules.shouldCommitAnswerWithHelp(
                questionID: question.id,
                qualifiedQuestionIds: state.hintQualifiedQuestionIds,
                answeredWithHelpQuestionIds: state.answeredWithHelpQuestionIds
            )
            let next = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: sourceIndex, now: now, answeredWithHelp: answeredWithHelp)
            try progressStore.saveQuestionProgress(next)
            state.committedQuestionIds.insert(question.id)
            onDataChanged()
        } catch {
            state.errorMessage = localizedErrorMessage(String(localized: "Unable to save progress locally: \("")"), detail: error)
        }
    }

    private func advanceOrFinish() {
        if state.currentIndex + 1 < state.items.count {
            state.currentIndex += 1
        } else {
            loadSession()
        }
    }

    private func advanceReviewLater() {
        if state.currentIndex + 1 < state.items.count {
            state.currentIndex += 1
            return
        }
        do {
            var progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            let now = try AppleStudyEngine.canonicalNow()
            for item in state.items {
                guard let selected = state.selectedByQuestionId[item.question.id] else { continue }
                let answeredWithHelp = PracticeHintRules.shouldSubmitAnswerWithHelp(questionID: item.question.id, qualifiedQuestionIds: state.hintQualifiedQuestionIds, answeredWithHelpQuestionIds: state.answeredWithHelpQuestionIds)
                progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: item.question, selectedSourceIndex: selected, now: now, answeredWithHelp: answeredWithHelp)
            }
            try progressStore.saveQuestionProgress(progress)
            state.reviewSubmitted = true
            onDataChanged()
        } catch {
            state.errorMessage = localizedErrorMessage(String(localized: "Unable to save review-later progress: \("")"), detail: error)
        }
    }
}

@MainActor
final class MockExamState: ObservableObject {
    @Published var seed = ""
    @Published var startedAt = ""
    @Published var generatedItems: [GeneratedExamItem] = []
    @Published var currentIndex = 0
    @Published var selectedByQuestionId: [String: Int?] = [:]
    @Published var flagged: Set<String> = []
    @Published var secondsElapsed = 0
    @Published var timerRunning = false
    @Published var timerRunStartedAt: Date?
    @Published var result: StoredExamAttempt?
    @Published var errorMessage: String?
    @Published var timerStatus = String(localized: "Timer off")
    @Published var loadedLocalDataReplacementRevision = 0
    let calculatorViewModel = ExamCalculatorViewModel()

    var hasUnfinishedCourseWork: Bool {
        !generatedItems.isEmpty && result == nil
    }

    func resetSession(localDataReplacementRevision: Int) {
        calculatorViewModel.clearForNewExam()
        seed = ""
        startedAt = ""
        generatedItems = []
        currentIndex = 0
        selectedByQuestionId = [:]
        flagged = []
        secondsElapsed = 0
        timerRunning = false
        timerRunStartedAt = nil
        result = nil
        errorMessage = nil
        timerStatus = String(localized: "Timer off")
        loadedLocalDataReplacementRevision = localDataReplacementRevision
    }

    func refreshTimer(now: Date = Date(), timerEnabled: Bool) {
        guard !generatedItems.isEmpty, result == nil else { return }
        guard timerEnabled else {
            timerRunning = false
            timerRunStartedAt = nil
            timerStatus = String(localized: "Timer off")
            return
        }
        guard timerRunning else {
            timerRunStartedAt = nil
            timerStatus = String(localized: "Timer paused, \(secondsElapsed) seconds elapsed")
            return
        }
        guard let timerRunStartedAt else {
            self.timerRunStartedAt = now
            timerStatus = String(localized: "Timer running, \(secondsElapsed) seconds elapsed")
            return
        }
        let additionalSeconds = max(0, Int(now.timeIntervalSince(timerRunStartedAt)))
        if additionalSeconds > 0 {
            secondsElapsed += additionalSeconds
            self.timerRunStartedAt = timerRunStartedAt.addingTimeInterval(TimeInterval(additionalSeconds))
        }
        timerStatus = String(localized: "Timer running, \(secondsElapsed) seconds elapsed")
    }
}

struct MockExamView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    @ObservedObject private var state: MockExamState
    let localDataReplacementRevision: Int
    let onExamToolPresentationChanged: (Bool) -> Void
    let onDataChanged: () -> Void

    init(
        bank: QuestionBank,
        progressStore: ProgressStoreService,
        language: BankLanguage,
        state: MockExamState,
        localDataReplacementRevision: Int,
        onExamToolPresentationChanged: @escaping (Bool) -> Void = { _ in },
        onDataChanged: @escaping () -> Void
    ) {
        self.bank = bank
        self.progressStore = progressStore
        self.language = language
        self.state = state
        _calculatorViewModel = ObservedObject(wrappedValue: state.calculatorViewModel)
        self.localDataReplacementRevision = localDataReplacementRevision
        self.onExamToolPresentationChanged = onExamToolPresentationChanged
        self.onDataChanged = onDataChanged
    }

    @AccessibilityFocusState private var resultFocus: MockExamAccessibilityFocus?
    @State private var confirmingSubmit = false
    @State private var confirmingEndExam = false
    @State private var isSubmitting = false
    @State private var showingNavigator = false
    @State private var pendingNavigatorPresentation = false
    @State private var shouldFocusResultsHeading = false
    @State private var selectedExamTool: ExamTool?
    @State private var calculatorFocused = false
    @ObservedObject private var calculatorViewModel: ExamCalculatorViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private enum MockExamAccessibilityFocus: Hashable {
        case resultsHeading
    }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                if let result = state.result {
                    examResults(result)
                } else if state.generatedItems.isEmpty {
                    startCard
                } else if let currentItem = state.generatedItems[safe: state.currentIndex], let question = bank.question(id: currentItem.questionId) {
                    examQuestion(item: currentItem, question: question)
                }
                if let errorMessage = state.errorMessage {
                    MessagePanel(title: "Mock exam unavailable", message: errorMessage, kind: .warning)
                }
            }
            .pagePadding()
        }
        .id(state.result?.id ?? "mock-exam-active")
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Mock exam")
        .lessonReaderOpaqueNavigationBar()
        .examToolPresentation(
            selectedTool: $selectedExamTool,
            calculator: calculatorViewModel,
            calculatorFocused: $calculatorFocused,
            referenceSheetConfiguration: referenceSheetConfiguration,
            onDismiss: presentPendingNavigatorSheetIfNeeded
        )
        .sheet(isPresented: $showingNavigator) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                navigator
                Button { showingNavigator = false } label: {
                    AccessibleSecondaryButtonLabel(title: "Done")
                }
                .buttonStyle(AccessibleSecondaryButtonStyle())
            }
            .pagePadding()
            .background(DesignTokens.Colors.paper)
        }
        .onAppear {
            calculatorViewModel.updateLocale(canadianHamInterfaceCalculatorLocale())
            refreshForCurrentTimerState()
        }
        .onChange(of: selectedExamTool) { _, next in onExamToolPresentationChanged(next != nil) }
        .onDisappear { onExamToolPresentationChanged(false) }
        .task(id: localDataReplacementRevision) { resetIfLocalDataWasReplaced() }
        .onReceive(timer) { _ in
            refreshForCurrentTimerState()
        }
        .alert("Submit mock exam?", isPresented: $confirmingSubmit) {
            Button("Cancel", role: .cancel) {}
            Button("Submit", role: .destructive) { submitExam() }
        } message: {
            Text(submitConfirmationText) // l10n: localized
        }
        .alert("End mock exam?", isPresented: $confirmingEndExam) {
            Button("Cancel", role: .cancel) {}
            Button("End exam", role: .destructive) { resetExam() }
        } message: {
            Text("Discard this in-progress mock exam and return to the start screen.")
        }
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Mock exam")
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text(bank.courseBankID == .advanced ? "Generate 50 Advanced questions: one from each topic area, mixed into a repeatable order. The optional timer is off by default." : "Generate 100 questions: one from each subsection, mixed into a repeatable order. The optional timer is off by default.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(bank.courseBankID == .advanced ? "No ISED reference sheet is provided for the Advanced exam. Do not use the Basic reference sheet as Advanced exam-allowed material." : "In the real exam you are given ISED's reference sheet of formulas and block diagrams. The lessons teach everything on it.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            tokenButton("Start mock exam") { startExam() }
                .accessibilityIdentifier("start-mock-exam-button")
        }
        .paperCard()
    }

    private func examQuestion(item: GeneratedExamItem, question: BankQuestion) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Exam code: \(state.seed)")
                    .font(DesignTokens.FontScale.caption.monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("mock-exam-seed")
                Text("Question \(state.currentIndex + 1) of \(state.generatedItems.count)")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("\(localizedAnsweredOutOfTotal(answered: state.selectedByQuestionId.count, total: state.generatedItems.count)). \(state.timerStatus).") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                examHeaderControls(questionID: question.id)
            }
            .paperCard()

            ExamToolButtons(availableTools: availableExamTools) { openExamTool($0) }

            QuestionCard(question: question, language: language, onInteraction: clearCalculatorKeyboardFocus)
                .simultaneousGesture(examContentTapGesture)
                .accessibilityAction(named: Text("Next unanswered")) {
                    jumpToNextUnanswered()
                }
                .accessibilityAction(named: Text("Next flagged")) {
                    jumpToNextFlagged()
                }
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Answers")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("mock-answers-title")
                ForEach(Array(item.choicePermutation.enumerated()), id: \.offset) { displayIndex, sourceIndex in
                    if let answer = question.answers.first(where: { $0.sourceIndex == sourceIndex }) {
                        AnswerChoiceButton(
                            answer: answer,
                            displayIndex: displayIndex,
                            language: language,
                            selectedSourceIndex: state.selectedByQuestionId[question.id] ?? nil,
                            showCorrectness: false,
                            disabled: false,
                            onKeyboardFocus: clearCalculatorKeyboardFocus
                        ) {
                            clearCalculatorKeyboardFocus()
                            state.selectedByQuestionId[question.id] = sourceIndex
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            clearCalculatorKeyboardFocus()
                        })
                    }
                }
            }
            .simultaneousGesture(examContentTapGesture)

            HStack {
                Button { state.currentIndex = max(0, state.currentIndex - 1) } label: {
                    AccessibleSecondaryButtonLabel(title: "Previous")
                }
                .disabled(state.currentIndex == 0)
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .accessibilityIdentifier("mock-previous-button")
                Button { state.currentIndex = min(state.generatedItems.count - 1, state.currentIndex + 1) } label: {
                    AccessibleSecondaryButtonLabel(title: "Next")
                }
                .disabled(state.currentIndex + 1 >= state.generatedItems.count)
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .accessibilityIdentifier("mock-next-button")
            }

            if !usesNavigatorSheet {
                navigator
            }

            Button("Submit exam") { confirmingSubmit = true }
                .buttonStyle(AccessiblePrimaryButtonStyle())
                .disabled(isSubmitting)
                .accessibilityIdentifier("submit-mock-exam-button")

            Button("End exam", role: .destructive) { confirmingEndExam = true }
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .accessibilityIdentifier("end-mock-exam-button")
        }
    }

    private var usesNavigatorSheet: Bool {
#if os(iOS)
        horizontalSizeClass == .compact
#else
        false
#endif
    }

    private var availableExamTools: [ExamTool] {
        appleExamTools(for: bank, referenceSheetConfiguration: referenceSheetConfiguration)
    }

    private func openExamTool(_ tool: ExamTool) {
        selectedExamTool = tool
        calculatorFocused = shouldFocusCalculator(for: tool, calculatorViewModel: calculatorViewModel)
        if tool == .calculator {
            Task { @MainActor in
                calculatorViewModel.acceptHardwareKeyboardInput()
                calculatorFocused = true
            }
        }
    }

    private func clearCalculatorKeyboardFocus() {
        calculatorFocused = false
        calculatorViewModel.suspendHardwareKeyboardInput()
    }

    private var examContentTapGesture: some Gesture {
        TapGesture().onEnded {
            clearCalculatorKeyboardFocus()
        }
    }

    private var referenceSheetConfiguration: ReferenceSheetConfiguration {
        appleReferenceSheetConfigurationFromLaunchArguments()
    }

    @ViewBuilder
    private func examHeaderControls(questionID: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                flagAndNavigatorControls(questionID: questionID)
                timerControls
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
                    flagAndNavigatorControls(questionID: questionID)
                    timerControls
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    flagAndNavigatorControls(questionID: questionID)
                    timerControls
                }
            }
        }
    }

    @ViewBuilder
    private func flagAndNavigatorControls(questionID: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                flagButton(questionID: questionID)
                questionsButton
                quickJumpControls
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    flagButton(questionID: questionID)
                    questionsButton
                    quickJumpControls
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    flagButton(questionID: questionID)
                    questionsButton
                    quickJumpControls
                }
            }
        }
    }

    private func flagButton(questionID: String) -> some View {
        Button { toggleFlag(questionID) } label: {
            AccessibleSecondaryButtonLabel(title: state.flagged.contains(questionID) ? "Flagged for review" : "Flag for review")
        }
        .buttonStyle(AccessibleSecondaryButtonStyle())
        .accessibilityIdentifier("mock-flag-button")
    }

    @ViewBuilder
    private var questionsButton: some View {
        if usesNavigatorSheet {
            Button { presentNavigatorSheet() } label: {
                AccessibleSecondaryButtonLabel(title: "Questions")
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            .accessibilityIdentifier("mock-questions-button")
        }
    }

    private func presentNavigatorSheet() {
        guard usesNavigatorSheet else { return }
        if selectedExamTool != nil {
            pendingNavigatorPresentation = true
            calculatorFocused = false
            calculatorViewModel.suspendHardwareKeyboardInput()
            selectedExamTool = nil
        } else {
            showingNavigator = true
        }
    }


    private func presentPendingNavigatorSheetIfNeeded() {
        guard pendingNavigatorPresentation else { return }
        pendingNavigatorPresentation = false
        showingNavigator = true
    }

    @ViewBuilder
    private var quickJumpControls: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                nextUnansweredButton
                nextFlaggedButton
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    nextUnansweredButton
                    nextFlaggedButton
                }
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    nextUnansweredButton
                    nextFlaggedButton
                }
            }
        }
    }

    private var nextUnansweredButton: some View {
        Button { jumpToNextUnanswered() } label: {
            AccessibleSecondaryButtonLabel(title: "Next unanswered")
        }
        .buttonStyle(AccessibleSecondaryButtonStyle())
        .disabled(nextUnansweredIndex == nil)
        .accessibilityIdentifier("mock-next-unanswered-button")
    }

    private var nextFlaggedButton: some View {
        Button { jumpToNextFlagged() } label: {
            AccessibleSecondaryButtonLabel(title: "Next flagged")
        }
        .buttonStyle(AccessibleSecondaryButtonStyle())
        .disabled(nextFlaggedIndex == nil)
        .accessibilityIdentifier("mock-next-flagged-button")
    }

    @ViewBuilder
    private var timerControls: some View {
        if progressStore.preferences.examTimerEnabled {
            HStack {
                let buttonTitle: LocalizedStringKey = state.timerRunning ? "Pause timer" : state.secondsElapsed == 0 ? "Start timer" : "Resume timer"
                tokenButton(buttonTitle) {
                    toggleTimer()
                    AccessibilityNotification.Announcement(state.timerStatus).post()
                }
            }
        } else {
            Text("Timer off by default")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.ink)
        }
    }

    private var navigator: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Question navigator")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            quickJumpControls
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: DesignTokens.Spacing.sm)], spacing: DesignTokens.Spacing.sm) {
                ForEach(state.generatedItems.indices, id: \.self) { index in
                    let item = state.generatedItems[index]
                    Button { state.currentIndex = index } label: {
                        Text(navigatorLabel(for: index, item: item)) // l10n: verbatim
                            .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .frame(minWidth: 48, minHeight: 44)
                            .padding(.horizontal, DesignTokens.Spacing.xs)
                            .background(navigatorBackground(for: item), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous).strokeBorder(navigatorBorder(for: index, item: item), lineWidth: index == state.currentIndex ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(mockNavigatorAccessibilityLabel(for: index, item: item)) // l10n: localized
                }
            }
        }
        .paperCard()
    }

    private func navigatorLabel(for index: Int, item: GeneratedExamItem) -> String {
        var label = "\(index + 1)"
        if index == state.currentIndex { label += " ●" }
        if state.selectedByQuestionId[item.questionId] != nil { label += " ✓" }
        if state.flagged.contains(item.questionId) { label += " ⚑" }
        return label
    }

    private func mockNavigatorAccessibilityLabel(for index: Int, item: GeneratedExamItem) -> Text {
        let answerState = state.selectedByQuestionId[item.questionId] != nil ? String(localized: "answered") : String(localized: "unanswered")
        var label = String(localized: "Question \(index + 1), \(answerState)")
        if state.flagged.contains(item.questionId) { label += String(localized: ", flagged") }
        if index == state.currentIndex { label += String(localized: ", current") }
        return Text(label) // l10n: localized
    }

    private func navigatorBackground(for item: GeneratedExamItem) -> Color {
        state.selectedByQuestionId[item.questionId] != nil ? DesignTokens.Colors.paperInset : DesignTokens.Colors.paperElevated
    }

    private func navigatorBorder(for index: Int, item: GeneratedExamItem) -> Color {
        if index == state.currentIndex || state.selectedByQuestionId[item.questionId] != nil || state.flagged.contains(item.questionId) {
            return DesignTokens.Colors.inkMuted
        }
        return DesignTokens.Colors.border
    }

    private var nextUnansweredIndex: Int? {
        nextIndex { item in
            state.selectedByQuestionId[item.questionId] == nil
        }
    }

    private var nextFlaggedIndex: Int? {
        nextIndex { item in
            state.flagged.contains(item.questionId)
        }
    }

    private func nextIndex(matching predicate: (GeneratedExamItem) -> Bool) -> Int? {
        guard !state.generatedItems.isEmpty else { return nil }
        for offset in 1..<state.generatedItems.count {
            let index = (state.currentIndex + offset) % state.generatedItems.count
            if predicate(state.generatedItems[index]) {
                return index
            }
        }
        return nil
    }

    private func jumpToNextUnanswered() {
        if let nextUnansweredIndex {
            state.currentIndex = nextUnansweredIndex
            showingNavigator = false
        }
    }

    private func jumpToNextFlagged() {
        if let nextFlaggedIndex {
            state.currentIndex = nextFlaggedIndex
            showingNavigator = false
        }
    }

    private var submitConfirmationText: String {
        let unanswered = state.generatedItems.filter { state.selectedByQuestionId[$0.questionId] == nil }
        let listed = unanswered.prefix(10).map { String($0.position) }.joined(separator: ", ")
        if unanswered.isEmpty {
            return String(localized: "All questions are answered. You can submit now.")
        }
        let unansweredText = localizedUnansweredQuestionCount(unanswered.count)
        let suffix = unanswered.count > 10 ? ", …" : ""
        return String(localized: "\(unansweredText) Unanswered positions: \(listed)\(suffix).")
    }

    private func examResults(_ attempt: StoredExamAttempt) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(attempt.score.honours ? "Basic with Honours" : attempt.score.passed ? "Pass" : "Needs review") // l10n: localized
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(attempt.score.passed ? DesignTokens.Colors.correctText : DesignTokens.Colors.warningText)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("mock-results-heading")
                    .accessibilityLabel(Text(mockExamSubmissionAnnouncement(for: attempt))) // l10n: localized
                    .accessibilityFocused($resultFocus, equals: .resultsHeading)
                    .onAppear { focusResultsHeadingAfterLayout() }
                Text(bank.courseBankID == .advanced ? "Score: \(attempt.score.correct) / \(attempt.score.total) (\(attempt.score.percent, format: .number.precision(.fractionLength(0...1)))%). Pass is 70%; there is no Advanced Honours." : "Score: \(attempt.score.correct) / \(attempt.score.total) (\(attempt.score.percent, format: .number.precision(.fractionLength(0...1)))%). Pass is 70%; honours is 80%.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text("Exam code: \(attempt.seed)")
                    .font(DesignTokens.FontScale.caption.monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            .paperCard()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Category breakdown")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("mock-results-category-breakdown")
                ForEach(attempt.score.categoryBreakdown, id: \.categoryId) { entry in
                    Text("\(entry.categoryId): \(entry.correct) / \(entry.total) (\(entry.percent, format: .number.precision(.fractionLength(0...1)))%)")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
            .paperCard()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Wrong-answer review")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("mock-results-wrong-answer-review")
                ForEach(attempt.items.filter { $0.selectedSourceIndex != 0 }) { item in
                    if let question = bank.question(id: item.questionId) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(verbatim: "\(item.position). \(question.id)") // l10n: verbatim
                                .font(DesignTokens.FontScale.body.monospaced())
                            Text(localized(question.text.text(for: language), language: language)) // l10n: content(question)
                                .font(DesignTokens.FontScale.body)
                                .foregroundStyle(DesignTokens.Colors.ink)
                            PracticeFeedback(question: question, selectedSourceIndex: item.selectedSourceIndex, language: language, choicePermutation: item.choicePermutation)
                        }
                        .paperCard()
                    }
                }
            }
            Button("Start another mock exam") { resetExam() }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
        }
    }

    private func resetIfLocalDataWasReplaced() {
        guard state.loadedLocalDataReplacementRevision != localDataReplacementRevision else { return }
        state.resetSession(localDataReplacementRevision: localDataReplacementRevision)
        confirmingSubmit = false
        confirmingEndExam = false
        showingNavigator = false
        pendingNavigatorPresentation = false
        selectedExamTool = nil
        shouldFocusResultsHeading = false
        isSubmitting = false
        calculatorFocused = false
        calculatorViewModel.clearForNewExam(locale: canadianHamInterfaceCalculatorLocale())
    }

    private func refreshForCurrentTimerState(now: Date = Date()) {
        state.refreshTimer(now: now, timerEnabled: progressStore.preferences.examTimerEnabled)
    }

    private func toggleTimer() {
        refreshForCurrentTimerState()
        if state.timerRunning {
            state.timerRunning = false
            state.timerRunStartedAt = nil
            state.timerStatus = String(localized: "Timer paused, \(state.secondsElapsed) seconds elapsed")
        } else {
            state.timerRunning = true
            state.timerRunStartedAt = Date()
            state.timerStatus = String(localized: "Timer running, \(state.secondsElapsed) seconds elapsed")
        }
    }

    private func startExam() {
        do {
            state.seed = AppLaunchArguments.value(after: "-CanadianHamMockExamSeed") ?? "mock-exam/\(UUID().uuidString)"
            state.startedAt = try AppleStudyEngine.canonicalNow()
            state.generatedItems = try AppleStudyEngine.generatedMockExam(bank: bank, seed: state.seed).items
#if DEBUG
            if let forcedQuestionID = AppLaunchArguments.value(after: "-CanadianHamMockExamQuestionID"), let question = bank.question(id: forcedQuestionID) {
                let forcedAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "mock-answers/\(question.id)/ui-test")
                let forced = GeneratedExamItem(position: 1, questionId: question.id, subsectionId: question.subsectionId, categoryId: question.categoryId, choicePermutation: forcedAnswers.map(\.sourceIndex))
                state.generatedItems.removeAll { $0.questionId == question.id }
                state.generatedItems.insert(forced, at: 0)
                state.generatedItems = state.generatedItems.enumerated().map { index, item in
                    GeneratedExamItem(position: index + 1, questionId: item.questionId, subsectionId: item.subsectionId, categoryId: item.categoryId, choicePermutation: item.choicePermutation)
                }
            }
            if let value = AppLaunchArguments.value(after: "-CanadianHamMockExamLimit"), let limit = Int(value), limit > 0 {
                state.generatedItems = Array(state.generatedItems.prefix(limit))
            }
#endif
            state.currentIndex = 0
            state.selectedByQuestionId = [:]
            state.flagged = []
            state.secondsElapsed = 0
            state.timerRunning = progressStore.preferences.examTimerEnabled
            state.timerRunStartedAt = progressStore.preferences.examTimerEnabled ? Date() : nil
            state.timerStatus = progressStore.preferences.examTimerEnabled ? String(localized: "Timer running, 0 seconds elapsed") : String(localized: "Timer off")
            state.loadedLocalDataReplacementRevision = localDataReplacementRevision
            state.result = nil
            state.errorMessage = nil
            selectedExamTool = nil
            calculatorFocused = false
            calculatorViewModel.clearForNewExam(locale: canadianHamInterfaceCalculatorLocale())
        } catch {
            state.errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func submitExam() {
        guard state.result == nil, !isSubmitting else { return }
        refreshForCurrentTimerState()
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let submittedAt = try AppleStudyEngine.canonicalNow()
            let attempt = try AppleStudyEngine.buildExamAttempt(
                bank: bank,
                seed: state.seed,
                startedAt: state.startedAt,
                submittedAt: submittedAt,
                timerEnabled: progressStore.preferences.examTimerEnabled,
                secondsElapsed: state.secondsElapsed,
                generatedItems: state.generatedItems,
                selectedByQuestionId: state.selectedByQuestionId,
                flaggedQuestionIds: state.flagged
            )
            var progress = try progressStore.questionProgressRecords().filter { $0.bankId == bank.manifest.bankId }
            for item in attempt.items {
                if let question = bank.question(id: item.questionId) {
                    progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: item.selectedSourceIndex ?? -1, now: submittedAt)
                }
            }
            try progressStore.saveExamAttempt(attempt)
            try progressStore.saveQuestionProgress(progress)
            shouldFocusResultsHeading = true
            state.result = attempt
            state.timerRunning = false
            state.timerRunStartedAt = nil
            onDataChanged()
        } catch {
            state.errorMessage = localizedErrorMessage(String(localized: "Unable to save mock exam: \("")"), detail: error)
        }
    }

    private func mockExamSubmissionAnnouncement(for attempt: StoredExamAttempt) -> String {
        let status = attempt.score.honours ? String(localized: "Basic with Honours") : attempt.score.passed ? String(localized: "Pass") : String(localized: "Needs review")
        return String.localizedStringWithFormat(
            String(localized: "Mock exam submitted. %@, %lld of %lld."),
            status,
            Int64(attempt.score.correct),
            Int64(attempt.score.total)
        )
    }

    private func focusResultsHeadingAfterLayout() {
        guard shouldFocusResultsHeading else { return }
        Task { @MainActor in
            // Let SwiftUI finish replacing the active exam view before requesting VoiceOver focus.
            try? await Task.sleep(nanoseconds: 150_000_000)
            resultFocus = .resultsHeading
            shouldFocusResultsHeading = false
        }
    }

    private func toggleFlag(_ questionId: String) {
        if state.flagged.contains(questionId) { state.flagged.remove(questionId) } else { state.flagged.insert(questionId) }
    }

    private func resetExam() {
        state.resetSession(localDataReplacementRevision: localDataReplacementRevision)
        confirmingSubmit = false
        confirmingEndExam = false
        showingNavigator = false
        pendingNavigatorPresentation = false
        selectedExamTool = nil
        shouldFocusResultsHeading = false
        isSubmitting = false
        calculatorFocused = false
        calculatorViewModel.clearForNewExam(locale: canadianHamInterfaceCalculatorLocale())
    }
}

struct SettingsView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    @Binding var morseSettings: MorseTrainerSettings
    let openMorse: () -> Void
    let openAbout: () -> Void
    let hasUnfinishedCourseWork: () -> Bool
    let localDataReplacementRevision: Int
    let onDataChanged: (_ replacesLocalData: Bool) -> Void

    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var exportDocument: ProgressExportDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingImport: ProgressExportV1?
    @State private var pendingCourseSwitch: CourseBankID?
    @State private var confirmingImport = false
    @State private var confirmingReset = false
#if ICLOUD_SYNC
    @State private var confirmingICloudDelete = false
#endif
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var coursePickerFocused: Bool
    @AccessibilityFocusState private var courseSwitchConfirmationFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                if pendingCourseSwitch != nil {
                    courseSwitchConfirmationPanel
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Settings")
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Picker("Course", selection: Binding(
                        get: { progressStore.preferences.activeBankId },
                        set: { bankId in requestCourseSwitch(to: bankId) }
                    )) {
                        ForEach(CourseBankID.allCases) { bankId in
                            Text(bankId.localizedName).tag(bankId) // l10n: localized
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("course-picker")
                    .accessibilityLabel(Text("Course")) // l10n: localized
                    .accessibilityFocused($coursePickerFocused)

                    Picker("Practice mode", selection: Binding(
                        get: { progressStore.preferences.practiceMode },
                        set: { mode in savePreferences { $0.practiceMode = mode } }
                    )) {
                        ForEach(ApplePreferences.PracticeMode.allCases) { mode in
                            Text(mode.localizedLabel).tag(mode) // l10n: localized
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("practice-mode-picker")
                    Toggle("Enable optional mock-exam timer", isOn: Binding(
                        get: { progressStore.preferences.examTimerEnabled },
                        set: { enabled in savePreferences { $0.examTimerEnabled = enabled } }
                    ))
                    .accessibilityIdentifier("mock-exam-timer-toggle")
                    Picker("Theme", selection: Binding(
                        get: { progressStore.preferences.theme },
                        set: { theme in savePreferences { $0.theme = theme } }
                    )) {
                        ForEach(ApplePreferences.Theme.allCases) { theme in
                            Text(theme.localizedLabel).tag(theme) // l10n: localized
                        }
                    }
                    languagePreferencePicker
                    if progressStore.preferences.language.requiresInterfaceRestart() {
                        Text("Restart Canadian Ham to change the interface language.") // l10n: localized
                            .font(DesignTokens.FontScale.caption)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .accessibilityIdentifier("language-restart-note")
                    }
                }
                .paperCard()

#if ICLOUD_SYNC
                iCloudSyncCard
#endif

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Local data")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Progress is stored on this device. Export, import, and reset are user-initiated only.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    HStack {
                        tokenButton("Export progress JSON") { prepareExport() }
                        tokenButton("Import progress JSON") { showingImporter = true }
                        tokenButton("Reset all data") { confirmingReset = true }
                    }
                    Text("Active bank: \(bank.manifest.bankId), effective \(bank.manifest.effectiveDate).")
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Privacy")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
#if ICLOUD_SYNC
                    Text(ICloudSyncCopy.settingsPrivacySummary) // l10n: localized
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
#else
                    Text("No accounts, networking, analytics, telemetry, third-party SDKs, or iCloud sync. Import and export use local files you choose.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
#endif
                    tokenButton("About Canadian Ham") { openAbout() }
                }
                .paperCard()

                    if let statusMessage { MessagePanel(title: "Settings", message: statusMessage, kind: .success) }
                    if let errorMessage { MessagePanel(title: "Settings error", message: errorMessage, kind: .warning) }
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Settings")
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: "canadian-ham-progress.json") { result in
            switch result {
            case .success: statusMessage = String(localized: "Progress export prepared.")
            case .failure(let error): errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        .alert("Import progress?", isPresented: $confirmingImport) {
            Button("Cancel", role: .cancel) { pendingImport = nil }
            Button("Import", role: .destructive) { confirmImport() }
        } message: {
            Text("Import replaces local progress, mock exams, and preferences with the selected valid JSON file.")
        }
        .alert("Reset all local data?", isPresented: $confirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { resetAllData() }
        } message: {
            Text("Deletes local progress, mock exams, and preferences. Bundled content remains installed.")
        }
#if ICLOUD_SYNC
        .alert(ICloudSyncCopy.deleteProgressTitle, isPresented: $confirmingICloudDelete) {
            Button("Cancel", role: .cancel) {}
            Button(ICloudSyncCopy.deleteProgressKeepLocal, role: .destructive) { deleteICloudProgress(.keepLocal) } // l10n: localized
            Button(ICloudSyncCopy.deleteProgressDeleteLocal, role: .destructive) { deleteICloudProgress(.deleteLocal) } // l10n: localized
        } message: {
            Text(ICloudSyncCopy.deleteProgressMessage) // l10n: localized
        }
#endif
        .onChange(of: pendingCourseSwitch) { _, next in
            if next != nil {
                focusCourseSwitchConfirmationAfterLayout()
            }
        }
        .onChange(of: localDataReplacementRevision) { _, _ in
            pendingCourseSwitch = nil
        }
        .onChange(of: progressStore.preferences.activeBankId) { _, _ in
            pendingCourseSwitch = nil
        }
    }

    @ViewBuilder
    private var languagePreferencePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            languagePreferencePickerContent
                .pickerStyle(.menu)
                .accessibilityIdentifier("language-setting-picker")
                .accessibilityLabel(Text("Language")) // l10n: localized
        } else {
            languagePreferencePickerContent
                .pickerStyle(.segmented)
                .accessibilityIdentifier("language-setting-picker")
                .accessibilityLabel(Text("Language")) // l10n: localized
        }
    }

    private var languagePreferencePickerContent: some View {
        Picker("Language", selection: Binding(
            get: { progressStore.preferences.language },
            set: { language in savePreferences { $0.language = language } }
        )) {
            ForEach(ApplePreferences.LanguagePreference.allCases) { language in
                switch language {
                case .system:
                    Text("System default").tag(language) // l10n: localized
                case .english:
                    Text(localized(BankLanguage.english.displayName, language: .english)).tag(language) // l10n: content(en)
                case .french:
                    Text(localized(BankLanguage.french.displayName, language: .french)).tag(language) // l10n: content(fr)
                }
            }
        }
    }

#if ICLOUD_SYNC
    private var iCloudSyncCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(ICloudSyncCopy.title) // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Toggle(ICloudSyncCopy.toggleLabel, isOn: Binding(
                get: { progressStore.isICloudSyncEnabled },
                set: { enabled in updateICloudSync(enabled) }
            )) // l10n: localized
            .accessibilityIdentifier("icloud-sync-toggle")
            Text(ICloudSyncCopy.deviceExplanation) // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let accountSignalError = progressStore.iCloudAccountSignalError {
                Text(ICloudSyncCopy.accountSignalError) // l10n: localized
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.warningText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(accountSignalError) // l10n: verbatim
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.warningText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            tokenButton("Delete iCloud Progress") { confirmingICloudDelete = true }
                .accessibilityIdentifier("icloud-delete-progress-button")
        }
        .paperCard()
    }
#endif

    private var courseSwitchConfirmationPanel: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Switch course?") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($courseSwitchConfirmationFocused)
            Text("Switching courses will discard the unfinished practice or mock exam session. Saved progress remains on this device.") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                tokenButton("Cancel") { cancelCourseSwitch() }
                tokenButton("Switch course") { confirmCourseSwitch() }
            }
        }
        .paperCard()
    }

    private func focusCourseSwitchConfirmationAfterLayout() {
        DispatchQueue.main.async {
            courseSwitchConfirmationFocused = true
        }
    }

    private func requestCourseSwitch(to bankId: CourseBankID) {
        guard bankId != progressStore.preferences.activeBankId else { return }
        if hasUnfinishedCourseWork() {
            pendingCourseSwitch = bankId
        } else {
            saveCourseSwitch(to: bankId)
        }
    }

    private func cancelCourseSwitch() {
        pendingCourseSwitch = nil
        DispatchQueue.main.async {
            coursePickerFocused = true
        }
    }

    private func confirmCourseSwitch() {
        guard let pendingCourseSwitch else { return }
        self.pendingCourseSwitch = nil
        saveCourseSwitch(to: pendingCourseSwitch)
        focusCoursePickerAfterLayout()
    }

    private func focusCoursePickerAfterLayout() {
        DispatchQueue.main.async {
            coursePickerFocused = true
        }
    }

    private func saveCourseSwitch(to bankId: CourseBankID) {
        savePreferences { $0.activeBankId = bankId }
    }

#if ICLOUD_SYNC
    private func updateICloudSync(_ enabled: Bool) {
        progressStore.updateICloudSyncOptIn(enabled)
        statusMessage = enabled
            ? ICloudSyncCopy.enabledAfterRestart
            : ICloudSyncCopy.disabledAfterRestart
        errorMessage = nil
        onDataChanged(false)
    }
#endif

    private func savePreferences(_ mutate: (inout ApplePreferences) -> Void) {
        var next = progressStore.preferences
        mutate(&next)
        do {
            try progressStore.updatePreferences(next)
            statusMessage = String(localized: "Preferences saved locally.")
            errorMessage = nil
            onDataChanged(false)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func prepareExport() {
        do {
            let text = try progressStore.serializedExport(bank: bank, exportedAt: AppleStudyEngine.canonicalNow(), morseSettings: morseSettings.exportedPreferences)
            exportDocument = ProgressExportDocument(text: text)
            showingExporter = true
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ProgressExportV1.self, from: data)
            let errors = progressStore.validate(decoded, bank: bank)
            if errors.isEmpty {
                pendingImport = decoded
                confirmingImport = true
            } else {
                errorMessage = errors.joined(separator: "\n")
            }
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func confirmImport() {
        guard let pendingImport else { return }
        do {
            try progressStore.importData(pendingImport, bank: bank)
            morseSettings = MorseTrainerSettings(exported: pendingImport.preferences.morse).normalized()
            morseSettings.save()
            self.pendingImport = nil
            statusMessage = String(localized: "Progress imported.")
            errorMessage = nil
            onDataChanged(true)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func resetAllData() {
#if ICLOUD_SYNC
        Task { @MainActor in
            do {
                try await progressStore.resetAllData(client: .cloudKit())
                MorseTrainerSettings.reset()
                morseSettings = .default
                statusMessage = String(localized: "All local progress was reset.")
                errorMessage = nil
                onDataChanged(true)
            } catch {
                errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            }
        }
        return
#endif
        do {
            try progressStore.resetAllData()
            MorseTrainerSettings.reset()
            morseSettings = .default
            statusMessage = String(localized: "All local progress was reset.")
            errorMessage = nil
            onDataChanged(true)
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

#if ICLOUD_SYNC
    private func deleteICloudProgress(_ localDataChoice: ICloudLocalDataChoice) {
        Task { @MainActor in
            do {
                try await progressStore.deleteICloudProgress(localDataChoice: localDataChoice, client: .cloudKit())
                if localDataChoice == .deleteLocal {
                    MorseTrainerSettings.reset()
                    morseSettings = .default
                }
                statusMessage = ICloudSyncCopy.deleteProgressSuccess
                errorMessage = nil
                onDataChanged(localDataChoice == .deleteLocal)
            } catch {
                errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            }
        }
    }
#endif
}

struct ProgressExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct QuestionCard: View {
    let question: BankQuestion
    let language: BankLanguage
    var onInteraction: (() -> Void)? = nil

    var body: some View {
        let card = VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(question.id) // l10n: verbatim
                .font(DesignTokens.FontScale.body.monospaced())
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .accessibilityIdentifier("question-identifier")
            Text(localized(question.text.text(for: language), language: language)) // l10n: content(question)
                .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .textSelection(.enabled)
                .accessibilityIdentifier("question-stem")
        }
        .paperCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("question-card")

        if let onInteraction {
            card.simultaneousGesture(TapGesture().onEnded { onInteraction() }, including: .all)
        } else {
            card
        }
    }
}

struct AnswerChoiceButton: View {
    let answer: BankAnswer
    let displayIndex: Int
    let language: BankLanguage
    let selectedSourceIndex: Int?
    let showCorrectness: Bool
    let disabled: Bool
    var onKeyboardFocus: (() -> Void)? = nil
    let action: () -> Void
    @FocusState private var isKeyboardFocused: Bool

    private var letter: String { ["A", "B", "C", "D"][safe: displayIndex] ?? "\(displayIndex + 1)" }
    private var isSelected: Bool { selectedSourceIndex == answer.sourceIndex }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(letter) // l10n: verbatim
                    .font(DesignTokens.FontScale.body.monospaced().weight(.bold))
                    .frame(minWidth: 34, minHeight: 34)
                    .padding(DesignTokens.Spacing.xs)
                    .background(chipColor, in: Circle())
                    .foregroundStyle(chipForeground)
                    .accessibilityIdentifier("answer-\(letter)-chip")
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized(answer.text.text(for: language), language: language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("answer-\(letter)-text")
                    if let statusText {
                        Label {
                            Text(localizedStatusText(statusText)) // l10n: localized
                        } icon: {
                            Image(systemName: statusIcon)
                        }
                        .font(DesignTokens.FontScale.caption.weight(.bold))
                        .foregroundStyle(textColor)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(border, lineWidth: isSelected || visualState.isSemantic ? 2 : 1))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!disabled)
        .accessibilityRespondsToUserInteraction(!disabled)
        .accessibilityLabel(accessibilityLabel) // l10n: content(question)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("answer-\(letter)-button")
        .focused($isKeyboardFocused)
        .onChange(of: isKeyboardFocused) { _, isFocused in
            if isFocused {
                onKeyboardFocus?()
            }
        }
    }

    private var statusText: String? {
        guard selectedSourceIndex != nil else { return nil }
        guard showCorrectness else { return isSelected ? "Selected" : nil }
        if answer.sourceIndex == 0 { return isSelected ? "Your answer, correct answer" : "Correct answer" }
        if isSelected { return "Your answer, incorrect" }
        return nil
    }

    private var statusIcon: String { answer.sourceIndex == 0 ? "checkmark.circle.fill" : "xmark.circle.fill" }
    private var background: Color { visualState.background }
    private var border: Color { visualState.border }
    private var textColor: Color { visualState.textColor }
    private var chipColor: Color { visualState.chipBackground }
    private var chipForeground: Color { visualState.chipForeground }

    private var visualState: AnswerChoiceVisualState {
        guard selectedSourceIndex != nil else {
            return AnswerChoiceVisualState(
                background: DesignTokens.Colors.paperElevated,
                border: DesignTokens.Colors.border,
                textColor: DesignTokens.Colors.ink,
                chipBackground: DesignTokens.Colors.ink,
                chipForeground: DesignTokens.Colors.paperElevated,
                isSemantic: false
            )
        }

        if showCorrectness, answer.sourceIndex == 0 {
            return AnswerChoiceVisualState(
                background: DesignTokens.Colors.correctBg,
                border: DesignTokens.Colors.correctBorder,
                textColor: DesignTokens.Colors.correctText,
                chipBackground: DesignTokens.Colors.correctText,
                chipForeground: DesignTokens.Colors.correctBg,
                isSemantic: true
            )
        }

        if showCorrectness, isSelected {
            return AnswerChoiceVisualState(
                background: DesignTokens.Colors.incorrectBg,
                border: DesignTokens.Colors.incorrectBorder,
                textColor: DesignTokens.Colors.incorrectText,
                chipBackground: DesignTokens.Colors.incorrectText,
                chipForeground: DesignTokens.Colors.incorrectBg,
                isSemantic: true
            )
        }

        if isSelected {
            return AnswerChoiceVisualState(
                background: DesignTokens.Colors.paperInset,
                border: DesignTokens.Colors.inkMuted,
                textColor: DesignTokens.Colors.ink,
                chipBackground: DesignTokens.Colors.ink,
                chipForeground: DesignTokens.Colors.paperInset,
                isSemantic: false
            )
        }

        return AnswerChoiceVisualState(
            background: DesignTokens.Colors.paperInset,
            border: DesignTokens.Colors.border,
            textColor: DesignTokens.Colors.ink,
            chipBackground: DesignTokens.Colors.ink,
            chipForeground: DesignTokens.Colors.paperInset,
            isSemantic: false
        )
    }

    private var accessibilityLabel: Text {
        var accessibleText = AttributedString(String(localized: "Answer \(letter), "))
        accessibleText += localized(answer.text.text(for: language), language: language)
        if let statusText {
            accessibleText += AttributedString(String(localized: ", \(localizedStatusText(statusText))"))
        }
        return Text(accessibleText) // l10n: content(question)
    }

    private func localizedStatusText(_ statusText: String) -> String {
        switch statusText {
        case "Your answer, correct answer": String(localized: "Your answer, correct answer")
        case "Correct answer": String(localized: "Correct answer")
        case "Your answer, incorrect": String(localized: "Your answer, incorrect")
        case "Selected": String(localized: "Selected")
        default: statusText
        }
    }
}

struct PracticeFeedback: View {
    let question: BankQuestion
    let selectedSourceIndex: Int?
    let language: BankLanguage
    let choicePermutation: [Int]?

    init(question: BankQuestion, selectedSourceIndex: Int?, language: BankLanguage, choicePermutation: [Int]? = nil) {
        self.question = question
        self.selectedSourceIndex = selectedSourceIndex
        self.language = language
        self.choicePermutation = choicePermutation
    }

    var body: some View {
        let isCorrect = selectedSourceIndex == 0
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(isCorrect ? "Correct" : "Incorrect") // l10n: localized
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                .accessibilityIdentifier("answer-feedback-title")
            if !isCorrect, let correct = question.answers.first(where: { $0.sourceIndex == 0 }) {
                Text(correctAnswerText(correct)) // l10n: content(question)
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.incorrectText)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("answer-feedback-correct-answer")
            }
            Text("Source: \(question.categoryId) • \(question.subsectionId).") // l10n: localized
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                .accessibilityIdentifier("answer-feedback-source")
            ExplanationPanelView(questionId: question.id, selectedSourceIndex: selectedSourceIndex, language: language, choicePermutation: choicePermutation)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("answer-feedback")
    }

    private func correctAnswerText(_ answer: BankAnswer) -> AttributedString {
        var text = AttributedString(String(localized: "Correct answer: "))
        text += localized(answer.text.text(for: language), language: language)
        return text
    }
}

private struct SubsectionCard: View {
    let subsection: BankSubsection
    let title: AttributedString

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title) // l10n: content(question)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(verbatim: "\(localizedQuestionCount(subsection.questionCount)) • \(subsection.id)") // l10n: verbatim
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
        .padding(.leading, DesignTokens.Spacing.lg)
    }
}

private struct CategoryCard: View {
    let category: BankCategory
    let language: BankLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(localized(category.name.text(for: language), language: category.name.resolvedLanguage(for: language))) // l10n: content(question)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(verbatim: "\(localizedQuestionCount(category.questionCount)) • \(localizedSubsectionCount(category.subsectionCount))") // l10n: verbatim
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }
}

private let localizedErrorDetailSeparator = "\u{1E}"

func localizedErrorMessage(_ localizedPrefix: String, detail error: Error) -> String {
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

struct LocalizedErrorMessageText: View {
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

struct MessagePanel: View {
    enum Kind { case warning, success }
    let title: LocalizedStringKey
    let message: String
    let kind: Kind

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(title).font(DesignTokens.FontScale.title.weight(.bold)) // l10n: localized
                LocalizedErrorMessageText(message: message)
                    .font(DesignTokens.FontScale.body)
            }
        } icon: {
            Image(systemName: kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
        }
        .foregroundStyle(kind == .success ? DesignTokens.Colors.correctText : DesignTokens.Colors.warningText)
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(kind == .success ? DesignTokens.Colors.correctBg : DesignTokens.Colors.warningBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(kind == .success ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.warningBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

private func appleExamTools(for bank: QuestionBank, referenceSheetConfiguration: ReferenceSheetConfiguration) -> [ExamTool] {
    var tools: [ExamTool] = [.calculator]
    if bank.courseBankID != .advanced, referenceSheetConfiguration.availableOnApple {
        tools.append(.referenceSheet)
    }
    return tools
}

@MainActor
private func shouldFocusCalculator(for tool: ExamTool, calculatorViewModel: ExamCalculatorViewModel) -> Bool {
    if tool == .calculator {
        calculatorViewModel.acceptHardwareKeyboardInput()
        return true
    }
    calculatorViewModel.suspendHardwareKeyboardInput()
    return false
}

private func appleReferenceSheetConfigurationFromLaunchArguments() -> ReferenceSheetConfiguration {
#if DEBUG
    if let resourceName = AppLaunchArguments.value(after: "-CanadianHamReferenceSheetResourceName") {
        return ReferenceSheetConfiguration(resourceName: resourceName, resourceExtension: "md", subdirectory: "reference-sheet")
    }
#endif
    return .basic
}

private extension ApplePreferences.PracticeMode {
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .immediate: "Immediate feedback"
        case .reviewLater: "Review later"
        }
    }

    var localizedString: String {
        switch self {
        case .immediate: String(localized: "Immediate feedback")
        case .reviewLater: String(localized: "Review later")
        }
    }
}

private extension ApplePreferences.Theme {
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

private struct AnswerChoiceVisualState {
    let background: Color
    let border: Color
    let textColor: Color
    let chipBackground: Color
    let chipForeground: Color
    let isSemantic: Bool
}

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}

private func localizedCorrectOutOfAnswered(correct: Int, answered: Int) -> String {
    let correctText = String.localizedStringWithFormat(String(localized: "%lld correct answer"), correct)
    let answeredText = String.localizedStringWithFormat(String(localized: "%lld answered question"), answered)
    return String(localized: "\(correctText) out of \(answeredText)")
}

func localizedAnsweredOutOfTotal(answered: Int, total: Int) -> String {
    String.localizedStringWithFormat(String(localized: "Answered %lld of %lld"), answered, total)
}

func localizedQuestionCount(_ count: Int, bundle: Bundle = .main, locale: Locale = .current) -> String {
    let format = String(localized: "%lld questions", bundle: bundle, locale: locale)
    return String(format: format, locale: locale, Int64(count))
}

func localizedUnansweredQuestionCount(_ count: Int, bundle: Bundle = .main, locale: Locale = .current) -> String {
    let format = String(localized: "%lld unanswered questions count as incorrect.", bundle: bundle, locale: locale)
    return String(format: format, locale: locale, Int64(count))
}

private func localizedSubsectionCount(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "%lld subsections"), count)
}

@MainActor
private func tokenButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title) // l10n: localized
            .font(DesignTokens.FontScale.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 44)
            .background(DesignTokens.Colors.paperInset, in: Capsule())
            .overlay(Capsule().strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }
    .buttonStyle(.plain)
}

extension View {
    func paperCard() -> some View {
        self
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
    }

    func pagePadding() -> some View {
        self
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
