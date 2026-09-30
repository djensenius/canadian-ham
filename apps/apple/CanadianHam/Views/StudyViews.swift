import Accessibility
import CanadianHamEngine
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let revision: Int
    let startPractice: (PracticeScope) -> Void
    let openMockExam: () -> Void

    @State private var summary: HomeSummary?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Offline, private, 2025 bank")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text("Ready for Basic with Honours?")
                        .font(DesignTokens.FontScale.display.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Study with the bundled ISED Basic 2025-07-15 question bank on iPhone, iPad, and Mac. Progress stays on this device unless you export it.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    HStack {
                        tokenButton("Start practice") { startPractice(.all) }
                        tokenButton("Mock exam") { openMockExam() }
                    }
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
                        .accessibilityLabel("Practice \(category.name.text(for: language)), \(category.questionCount) questions")
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
    private func readinessCard(_ summary: HomeSummary) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Readiness")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Label(summary.title, systemImage: summary.symbol)
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(summary.tint)
            Text(summary.message)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("Due review: \(summary.dueReviewCount). Weak subsections: \(summary.weakSubsectionCount). Completed mock exams: \(summary.completedExamCount).")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            HStack {
                tokenButton("Practice weak areas") { startPractice(.weak) }
                tokenButton("Review due questions") { startPractice(.due) }
            }
        }
        .paperCard()
        .accessibilityIdentifier("readiness-card")
    }

    private func loadSummary() {
        do {
            let progress = try progressStore.questionProgressRecords()
            let attempts = try progressStore.examAttempts()
            let now = try AppleStudyEngine.canonicalNow()
            let readiness = try AppleStudyEngine.readiness(progress: progress, attempts: attempts, now: now)
            let weak = AppleStudyEngine.weakSubsections(progress: progress, latestExam: attempts.sorted { $0.submittedAt > $1.submittedAt }.first)
            summary = HomeSummary(readiness: readiness, dueReviewCount: try dueCount(records: progress, now: now), weakSubsectionCount: weak.count, completedExamCount: attempts.count)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct HomeSummary {
    let title: String
    let message: String
    let symbol: String
    let tint: Color
    let dueReviewCount: Int
    let weakSubsectionCount: Int
    let completedExamCount: Int

    init(readiness: ReadinessResult, dueReviewCount: Int, weakSubsectionCount: Int, completedExamCount: Int) {
        self.dueReviewCount = dueReviewCount
        self.weakSubsectionCount = weakSubsectionCount
        self.completedExamCount = completedExamCount
        switch readiness.state {
        case .notEnoughData:
            title = "Not enough data"
            message = "Complete at least two mock exams before Canadian Ham claims pass or honours readiness. Keep practicing by category while you build evidence."
            symbol = "chart.bar.doc.horizontal"
            tint = DesignTokens.Colors.ink
        case .needsReview:
            title = "Needs review"
            message = "Your local progress shows weak categories, due reviews, or fewer passing mock exams than needed. Review weak and due questions before relying on exam readiness."
            symbol = "exclamationmark.triangle.fill"
            tint = DesignTokens.Colors.warningText
        case .passReady:
            title = "Pass-ready"
            message = "At least two recent mock exams meet the 70% pass threshold. Keep working toward 80% for Basic with Honours."
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

struct LearnPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Learn")
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Placeholder for the next lesson lane. Practice, mock exams, progress, export, import, and reset are available now; lesson reading will be wired in a separate task.")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            .paperCard()
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Learn")
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
                    practiceButton("All questions", detail: "Draw from all \(bank.questions.count) questions", systemImage: "tray.full", scope: .all)
                    practiceButton("Weak areas", detail: "\(weak) weak subsections", systemImage: "exclamationmark.triangle", scope: .weak)
                    practiceButton("Due review", detail: "\(due) due questions; unseen excluded", systemImage: "calendar.badge.clock", scope: .due)
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
                            .accessibilityLabel("Practice category \(category.name.text(for: language)), \(category.questionCount) questions")

                            DisclosureGroup("Subsections") {
                                ForEach(bank.subsectionsByCategory[category.id] ?? []) { subsection in
                                    Button { startPractice(.subsection(subsection.id)) } label: {
                                        SubsectionCard(subsection: subsection, title: bank.subsectionTitle(subsection, language: language))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Practice subsection \(bank.subsectionTitle(subsection, language: language)), \(subsection.questionCount) questions")
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

    private func practiceButton(_ title: String, detail: String, systemImage: String, scope: PracticeScope) -> some View {
        Button { startPractice(scope) } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Label(title, systemImage: systemImage)
                    .font(DesignTokens.FontScale.body.weight(.bold))
                Text(detail)
                    .font(DesignTokens.FontScale.caption)
            }
            .foregroundStyle(DesignTokens.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .paperCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(title). \(detail)")
    }

    private func refreshCounts() {
        do {
            let progress = try progressStore.questionProgressRecords()
            let attempts = try progressStore.examAttempts()
            let now = try AppleStudyEngine.canonicalNow()
            due = try dueCount(records: progress, now: now)
            weak = AppleStudyEngine.weakSubsections(progress: progress, latestExam: attempts.sorted { $0.submittedAt > $1.submittedAt }.first).count
        } catch {
            due = 0
            weak = 0
        }
    }
}

struct PracticeSessionView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let scope: PracticeScope
    @Binding var language: BankLanguage
    let onDataChanged: () -> Void

    @State private var items: [PracticeQuestionItem] = []
    @State private var currentIndex = 0
    @State private var selectedByQuestionId: [String: Int] = [:]
    @State private var committedQuestionIds: Set<String> = []
    @State private var reviewSubmitted = false
    @State private var answeredCount = 0
    @State private var correctCount = 0
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                header
                if let errorMessage {
                    MessagePanel(title: "Practice unavailable", message: errorMessage, kind: .warning)
                } else if items.isEmpty {
                    ContentUnavailableView("No questions found", systemImage: "tray", description: Text(emptyMessage))
                        .foregroundStyle(DesignTokens.Colors.ink)
                } else if reviewSubmitted {
                    practiceReview
                } else {
                    questionView(items[currentIndex])
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(scopeTitle)
        .task(id: scope) { loadSession() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(scopeTitle)
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("practice-category-title")
            Text(sessionProgressText)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityIdentifier("practice-session-tally")
                .accessibilityHidden(true)
            Text("Due review excludes unseen questions. Progress updates use the shared engine with an explicit timestamp.")
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
        .accessibilityLabel("\(scopeTitle). \(sessionProgressText). Due review excludes unseen questions. Progress updates use the shared engine with an explicit timestamp.")
    }

    private var sessionProgressText: String {
        switch progressStore.preferences.practiceMode {
        case .immediate:
            "Mode: \(progressStore.preferences.practiceMode.label). Session tally: \(correctCount) correct out of \(answeredCount) answered."
        case .reviewLater:
            if reviewSubmitted {
                "Mode: \(progressStore.preferences.practiceMode.label). Review complete: \(correctCount) correct out of \(answeredCount) answered."
            } else {
                "Mode: \(progressStore.preferences.practiceMode.label). Answered \(answeredCount) of \(items.count); results are hidden until review."
            }
        }
    }

    private var scopeTitle: String {
        switch scope {
        case .all: "All questions"
        case .weak: "Weak areas"
        case .due: "Due review"
        case .category(let id): bank.categories.first { $0.id == id }?.name.text(for: language) ?? id
        case .subsection(let id): bank.subsectionsById[id].map { bank.subsectionTitle($0, language: language) } ?? "Subsection \(id)"
        }
    }

    private var emptyMessage: String {
        switch scope {
        case .due: "No stored progress records are due. Unseen questions are not included in due review."
        case .weak: "No weak subsections are available yet. Complete practice or a mock exam first."
        default: "No bundled questions match this scope."
        }
    }

    private func questionView(_ item: PracticeQuestionItem) -> some View {
        let question = item.question
        let selected = selectedByQuestionId[question.id]
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            QuestionCard(question: question, language: language)
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
                            disabled: selected != nil && progressStore.preferences.practiceMode == .immediate
                        ) {
                            select(sourceIndex: sourceIndex, question: question)
                        }
                    }
                }
            }
            if let selected, progressStore.preferences.practiceMode == .immediate {
                PracticeFeedback(question: question, selectedSourceIndex: selected, language: language, choicePermutation: item.choicePermutation)
                Button(currentIndex + 1 == items.count ? "Finish session" : "Next question") {
                    advanceOrFinish()
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
                .frame(minHeight: 44)
                .accessibilityIdentifier("next-question-button")
            } else if progressStore.preferences.practiceMode == .reviewLater {
                Button(currentIndex + 1 == items.count ? "Submit for review" : "Next question") {
                    advanceReviewLater()
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
                .disabled(selected == nil)
                .accessibilityHint(selected == nil ? "Choose an answer before continuing" : "Continues without feedback until review")
            }
        }
    }

    private var practiceReview: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Practice review")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(item.question.id)
                        .font(DesignTokens.FontScale.body.monospaced())
                    Text(item.question.text.text(for: language))
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                    PracticeFeedback(question: item.question, selectedSourceIndex: selectedByQuestionId[item.question.id], language: language, choicePermutation: item.choicePermutation)
                    Text("Category \(item.question.categoryId) • Subsection \(item.question.subsectionId).")
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
                .paperCard()
            }
            tokenButton("Start another session") { loadSession() }
        }
    }

    private func loadSession() {
        do {
            var progress = try progressStore.questionProgressRecords()
            let attempts = try progressStore.examAttempts()
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
            items = loaded
            currentIndex = 0
            selectedByQuestionId = [:]
            committedQuestionIds = []
            reviewSubmitted = false
            answeredCount = 0
            correctCount = 0
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            items = []
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
        if let previous = selectedByQuestionId[question.id] {
            guard progressStore.preferences.practiceMode == .reviewLater else { return }
            selectedByQuestionId[question.id] = sourceIndex
            if previous == 0, sourceIndex != 0 { correctCount -= 1 }
            if previous != 0, sourceIndex == 0 { correctCount += 1 }
            AccessibilityNotification.Announcement("Selected answer updated").post()
            return
        }
        selectedByQuestionId[question.id] = sourceIndex
        answeredCount += 1
        if sourceIndex == 0 { correctCount += 1 }
        if progressStore.preferences.practiceMode == .immediate {
            commitAnswer(question: question, sourceIndex: sourceIndex)
            AccessibilityNotification.Announcement(sourceIndex == 0 ? "Correct" : "Incorrect").post()
        }
    }

    private func commitAnswer(question: BankQuestion, sourceIndex: Int) {
        guard !committedQuestionIds.contains(question.id) else { return }
        do {
            let now = try AppleStudyEngine.canonicalNow()
            let progress = try progressStore.questionProgressRecords()
            let next = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: sourceIndex, now: now)
            try progressStore.saveQuestionProgress(next)
            committedQuestionIds.insert(question.id)
            onDataChanged()
        } catch {
            errorMessage = "Unable to save progress locally: \(error.localizedDescription)"
        }
    }

    private func advanceOrFinish() {
        if currentIndex + 1 < items.count {
            currentIndex += 1
        } else {
            loadSession()
        }
    }

    private func advanceReviewLater() {
        if currentIndex + 1 < items.count {
            currentIndex += 1
            return
        }
        do {
            var progress = try progressStore.questionProgressRecords()
            let now = try AppleStudyEngine.canonicalNow()
            for item in items {
                guard let selected = selectedByQuestionId[item.question.id] else { continue }
                progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: item.question, selectedSourceIndex: selected, now: now)
            }
            try progressStore.saveQuestionProgress(progress)
            reviewSubmitted = true
            onDataChanged()
        } catch {
            errorMessage = "Unable to save review-later progress: \(error.localizedDescription)"
        }
    }
}

struct MockExamView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let onDataChanged: () -> Void

    @State private var seed = ""
    @State private var startedAt = ""
    @State private var generatedItems: [GeneratedExamItem] = []
    @State private var currentIndex = 0
    @State private var selectedByQuestionId: [String: Int?] = [:]
    @State private var flagged: Set<String> = []
    @State private var secondsElapsed = 0
    @State private var timerRunning = false
    @State private var result: StoredExamAttempt?
    @State private var errorMessage: String?
    @State private var confirmingSubmit = false
    @State private var isSubmitting = false
    @State private var timerStatus = "Timer off"
    @State private var showingNavigator = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                if let result {
                    examResults(result)
                } else if generatedItems.isEmpty {
                    startCard
                } else if let currentItem = generatedItems[safe: currentIndex], let question = bank.question(id: currentItem.questionId) {
                    examQuestion(item: currentItem, question: question)
                }
                if let errorMessage {
                    MessagePanel(title: "Mock exam unavailable", message: errorMessage, kind: .warning)
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Mock exam")
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
        .onReceive(timer) { _ in
            if timerRunning {
                secondsElapsed += 1
                timerStatus = "Timer running, \(secondsElapsed) seconds elapsed"
            }
        }
        .alert("Submit mock exam?", isPresented: $confirmingSubmit) {
            Button("Cancel", role: .cancel) {}
            Button("Submit", role: .destructive) { submitExam() }
        } message: {
            Text(submitConfirmationText)
        }
    }

    private var startCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Mock exam")
                .font(DesignTokens.FontScale.headline.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Generate 100 shared-engine questions: one from each subsection, shuffled by seed. The optional timer is off by default.")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("In the real exam you are given ISED's reference sheet of formulas and block diagrams. The lessons teach everything on it.")
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
                Text("Seed: \(seed)")
                    .font(DesignTokens.FontScale.caption.monospaced())
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("mock-exam-seed")
                Text("Question \(currentIndex + 1) of \(generatedItems.count)")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Answered \(selectedByQuestionId.count) of \(generatedItems.count). \(timerStatus).")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                examHeaderControls(questionID: question.id)
            }
            .paperCard()

            QuestionCard(question: question, language: language)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Answers")
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(item.choicePermutation.enumerated()), id: \.offset) { displayIndex, sourceIndex in
                    if let answer = question.answers.first(where: { $0.sourceIndex == sourceIndex }) {
                        AnswerChoiceButton(
                            answer: answer,
                            displayIndex: displayIndex,
                            language: language,
                            selectedSourceIndex: selectedByQuestionId[question.id] ?? nil,
                            showCorrectness: false,
                            disabled: false
                        ) {
                            selectedByQuestionId[question.id] = sourceIndex
                        }
                    }
                }
            }

            HStack {
                Button { currentIndex = max(0, currentIndex - 1) } label: {
                    AccessibleSecondaryButtonLabel(title: "Previous")
                }
                .disabled(currentIndex == 0)
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .accessibilityIdentifier("mock-previous-button")
                Button { currentIndex = min(generatedItems.count - 1, currentIndex + 1) } label: {
                    AccessibleSecondaryButtonLabel(title: "Next")
                }
                .disabled(currentIndex + 1 >= generatedItems.count)
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
        }
    }

    private var usesNavigatorSheet: Bool {
#if os(iOS)
        horizontalSizeClass == .compact
#else
        false
#endif
    }

    private func examHeaderControls(questionID: String) -> some View {
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

    private func flagAndNavigatorControls(questionID: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Button { toggleFlag(questionID) } label: {
                AccessibleSecondaryButtonLabel(title: flagged.contains(questionID) ? "Flagged for review" : "Flag for review")
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            .accessibilityIdentifier("mock-flag-button")
            if usesNavigatorSheet {
                Button { showingNavigator = true } label: {
                    AccessibleSecondaryButtonLabel(title: "Questions")
                }
                .buttonStyle(AccessibleSecondaryButtonStyle())
                .accessibilityIdentifier("mock-questions-button")
            }
        }
    }

    @ViewBuilder
    private var timerControls: some View {
        if progressStore.preferences.examTimerEnabled {
            HStack {
                tokenButton(timerRunning ? "Pause timer" : secondsElapsed == 0 ? "Start timer" : "Resume timer") {
                    timerRunning.toggle()
                    timerStatus = timerRunning ? "Timer running, \(secondsElapsed) seconds elapsed" : "Timer paused, \(secondsElapsed) seconds elapsed"
                    AccessibilityNotification.Announcement(timerStatus).post()
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
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: DesignTokens.Spacing.sm)], spacing: DesignTokens.Spacing.sm) {
                ForEach(generatedItems.indices, id: \.self) { index in
                    let item = generatedItems[index]
                    Button { currentIndex = index } label: {
                        Text(navigatorLabel(for: index, item: item))
                            .font(DesignTokens.FontScale.body.monospaced().weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .frame(minWidth: 48, minHeight: 44)
                            .padding(.horizontal, DesignTokens.Spacing.xs)
                            .background(navigatorBackground(for: item), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous).strokeBorder(navigatorBorder(for: index, item: item), lineWidth: index == currentIndex ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Question \(index + 1), \(selectedByQuestionId[item.questionId] != nil ? "answered" : "unanswered")\(flagged.contains(item.questionId) ? ", flagged" : "")\(index == currentIndex ? ", current" : "")")
                }
            }
        }
        .paperCard()
    }

    private func navigatorLabel(for index: Int, item: GeneratedExamItem) -> String {
        var label = "\(index + 1)"
        if index == currentIndex { label += " ●" }
        if selectedByQuestionId[item.questionId] != nil { label += " ✓" }
        if flagged.contains(item.questionId) { label += " ⚑" }
        return label
    }

    private func navigatorBackground(for item: GeneratedExamItem) -> Color {
        selectedByQuestionId[item.questionId] != nil ? DesignTokens.Colors.paperInset : DesignTokens.Colors.paperElevated
    }

    private func navigatorBorder(for index: Int, item: GeneratedExamItem) -> Color {
        if index == currentIndex || selectedByQuestionId[item.questionId] != nil || flagged.contains(item.questionId) {
            return DesignTokens.Colors.inkMuted
        }
        return DesignTokens.Colors.border
    }

    private var submitConfirmationText: String {
        let unanswered = generatedItems.filter { selectedByQuestionId[$0.questionId] == nil }
        let listed = unanswered.prefix(10).map { String($0.position) }.joined(separator: ", ")
        if unanswered.isEmpty {
            return "All questions are answered. You can submit now."
        }
        return "\(unanswered.count) unanswered questions count as incorrect. Unanswered positions: \(listed)\(unanswered.count > 10 ? ", …" : "")."
    }

    private func examResults(_ attempt: StoredExamAttempt) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(attempt.score.honours ? "Basic with Honours" : attempt.score.passed ? "Pass" : "Needs review")
                    .font(DesignTokens.FontScale.headline.weight(.bold))
                    .foregroundStyle(attempt.score.passed ? DesignTokens.Colors.correctText : DesignTokens.Colors.warningText)
                    .accessibilityAddTraits(.isHeader)
                Text("Score: \(attempt.score.correct) / \(attempt.score.total) (\(attempt.score.percent, format: .number.precision(.fractionLength(0...1)))%). Pass is 70%; honours is 80%.")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text("Seed: \(attempt.seed)")
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
                            Text("\(item.position). \(question.id)")
                                .font(DesignTokens.FontScale.body.monospaced())
                            Text(question.text.text(for: language))
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

    private func startExam() {
        do {
            seed = AppLaunchArguments.value(after: "-CanadianHamMockExamSeed") ?? "mock-exam/\(UUID().uuidString)"
            startedAt = try AppleStudyEngine.canonicalNow()
            generatedItems = try AppleStudyEngine.generatedMockExam(bank: bank, seed: seed).items
#if DEBUG
            if let forcedQuestionID = AppLaunchArguments.value(after: "-CanadianHamMockExamQuestionID"), let question = bank.question(id: forcedQuestionID) {
                let forcedAnswers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "mock-answers/\(question.id)/ui-test")
                let forced = GeneratedExamItem(position: 1, questionId: question.id, subsectionId: question.subsectionId, categoryId: question.categoryId, choicePermutation: forcedAnswers.map(\.sourceIndex))
                generatedItems.removeAll { $0.questionId == question.id }
                generatedItems.insert(forced, at: 0)
                generatedItems = generatedItems.enumerated().map { index, item in
                    GeneratedExamItem(position: index + 1, questionId: item.questionId, subsectionId: item.subsectionId, categoryId: item.categoryId, choicePermutation: item.choicePermutation)
                }
            }
            if let value = AppLaunchArguments.value(after: "-CanadianHamMockExamLimit"), let limit = Int(value), limit > 0 {
                generatedItems = Array(generatedItems.prefix(limit))
            }
#endif
            currentIndex = 0
            selectedByQuestionId = [:]
            flagged = []
            secondsElapsed = 0
            timerRunning = progressStore.preferences.examTimerEnabled
            timerStatus = progressStore.preferences.examTimerEnabled ? "Timer running, 0 seconds elapsed" : "Timer off"
            result = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitExam() {
        guard result == nil, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let submittedAt = try AppleStudyEngine.canonicalNow()
            let attempt = AppleStudyEngine.buildExamAttempt(
                bank: bank,
                seed: seed,
                startedAt: startedAt,
                submittedAt: submittedAt,
                timerEnabled: progressStore.preferences.examTimerEnabled,
                secondsElapsed: secondsElapsed,
                generatedItems: generatedItems,
                selectedByQuestionId: selectedByQuestionId,
                flaggedQuestionIds: flagged
            )
            var progress = try progressStore.questionProgressRecords()
            for item in attempt.items {
                if let question = bank.question(id: item.questionId) {
                    progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: item.selectedSourceIndex ?? -1, now: submittedAt)
                }
            }
            try progressStore.saveExamAttempt(attempt)
            try progressStore.saveQuestionProgress(progress)
            result = attempt
            timerRunning = false
            onDataChanged()
        } catch {
            errorMessage = "Unable to save mock exam: \(error.localizedDescription)"
        }
    }

    private func toggleFlag(_ questionId: String) {
        if flagged.contains(questionId) { flagged.remove(questionId) } else { flagged.insert(questionId) }
    }

    private func resetExam() {
        seed = ""
        startedAt = ""
        generatedItems = []
        result = nil
        selectedByQuestionId = [:]
        flagged = []
        currentIndex = 0
    }
}

struct SettingsView: View {
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let onDataChanged: () -> Void

    @State private var statusMessage = ""
    @State private var errorMessage: String?
    @State private var exportDocument: ProgressExportDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingImport: ProgressExportV1?
    @State private var confirmingImport = false
    @State private var confirmingReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Settings")
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Picker("Practice mode", selection: Binding(
                        get: { progressStore.preferences.practiceMode },
                        set: { mode in savePreferences { $0.practiceMode = mode } }
                    )) {
                        ForEach(ApplePreferences.PracticeMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Enable optional mock-exam timer", isOn: Binding(
                        get: { progressStore.preferences.examTimerEnabled },
                        set: { enabled in savePreferences { $0.examTimerEnabled = enabled } }
                    ))
                    Picker("Theme", selection: Binding(
                        get: { progressStore.preferences.theme },
                        set: { theme in savePreferences { $0.theme = theme } }
                    )) {
                        ForEach(ApplePreferences.Theme.allCases) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                    Picker("Question language", selection: Binding(
                        get: { progressStore.preferences.language },
                        set: { language in savePreferences { $0.language = language } }
                    )) {
                        ForEach(BankLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Local data")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Progress is stored locally with SwiftData. Export, import, and reset are user-initiated only.")
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
                    Text("No accounts, networking, analytics, telemetry, third-party SDKs, or iCloud sync. Import and export use local files you choose.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
                .paperCard()

                if !statusMessage.isEmpty { MessagePanel(title: "Settings", message: statusMessage, kind: .success) }
                if let errorMessage { MessagePanel(title: "Settings error", message: errorMessage, kind: .warning) }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Settings")
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: "canadian-ham-progress.json") { result in
            switch result {
            case .success: statusMessage = "Progress export prepared."
            case .failure(let error): errorMessage = error.localizedDescription
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
    }

    private func savePreferences(_ mutate: (inout ApplePreferences) -> Void) {
        var next = progressStore.preferences
        mutate(&next)
        do {
            try progressStore.updatePreferences(next)
            statusMessage = "Preferences saved locally."
            errorMessage = nil
            onDataChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func prepareExport() {
        do {
            let text = try progressStore.serializedExport(bank: bank, exportedAt: AppleStudyEngine.canonicalNow())
            exportDocument = ProgressExportDocument(text: text)
            showingExporter = true
        } catch {
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
    }

    private func confirmImport() {
        guard let pendingImport else { return }
        do {
            try progressStore.importData(pendingImport, bank: bank)
            self.pendingImport = nil
            statusMessage = "Progress imported."
            errorMessage = nil
            onDataChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetAllData() {
        do {
            try progressStore.resetAllData()
            statusMessage = "All local progress was reset."
            errorMessage = nil
            onDataChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
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

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(question.id)
                .font(DesignTokens.FontScale.body.monospaced())
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .accessibilityIdentifier("question-identifier")
            Text(localized(question.text.text(for: language), language: language))
                .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .textSelection(.enabled)
                .accessibilityIdentifier("question-stem")
        }
        .paperCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("question-card")
    }
}

struct AnswerChoiceButton: View {
    let answer: BankAnswer
    let displayIndex: Int
    let language: BankLanguage
    let selectedSourceIndex: Int?
    let showCorrectness: Bool
    let disabled: Bool
    let action: () -> Void

    private var letter: String { ["A", "B", "C", "D"][safe: displayIndex] ?? "\(displayIndex + 1)" }
    private var isSelected: Bool { selectedSourceIndex == answer.sourceIndex }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(letter)
                    .font(DesignTokens.FontScale.body.monospaced().weight(.bold))
                    .frame(minWidth: 34, minHeight: 34)
                    .padding(DesignTokens.Spacing.xs)
                    .background(chipColor, in: Circle())
                    .foregroundStyle(chipForeground)
                    .accessibilityIdentifier("answer-\(letter)-chip")
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized(answer.text.text(for: language), language: language))
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("answer-\(letter)-text")
                    if let statusText {
                        Label(statusText, systemImage: statusIcon)
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("answer-\(letter)-button")
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
        var value = "Answer \(letter), \(answer.text.text(for: language))"
        if let statusText { value += ", \(statusText)" }
        return Text(value)
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
            Text(isCorrect ? "Correct" : "Incorrect")
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                .accessibilityIdentifier("answer-feedback-title")
            if !isCorrect, let correct = question.answers.first(where: { $0.sourceIndex == 0 }) {
                Text("Correct answer: \(correct.text.text(for: language))")
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.incorrectText)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("answer-feedback-correct-answer")
            }
            Text("Source: \(question.categoryId) • \(question.subsectionId).")
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
}

private struct SubsectionCard: View {
    let subsection: BankSubsection
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(subsection.questionCount) questions • \(subsection.id)")
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
            Text(category.name.text(for: language))
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(category.questionCount) questions • \(category.subsectionCount) subsections")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }
}

struct MessagePanel: View {
    enum Kind { case warning, success }
    let title: String
    let message: String
    let kind: Kind

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(title).font(DesignTokens.FontScale.title.weight(.bold))
                Text(message).font(DesignTokens.FontScale.body)
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

@MainActor
private func tokenButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(title)
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
