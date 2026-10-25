import Accessibility
import CanadianHamContent
import CanadianHamEngine
import SwiftUI

private let rbr4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"

var canadianHamUsesFrenchUI: Bool {
    Bundle.main.preferredLocalizations.first?.lowercased().hasPrefix("fr") == true
}

private struct EnglishOnlyNotice: View {
    let text: LocalizedStringKey
    let identifier: String

    var body: some View {
        if canadianHamUsesFrenchUI {
            Text(text) // l10n: localized
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .accessibilityIdentifier(identifier)
        }
    }
}

private struct EnglishOnlyLessonNotice: View {
    var body: some View {
        EnglishOnlyNotice(text: "Lesson offered in English only.", identifier: "english-only-lesson-notice")
    }
}

private struct EnglishOnlyExplanationNotice: View {
    var body: some View {
        EnglishOnlyNotice(text: "Explanation offered in English only.", identifier: "english-only-explanation-notice")
    }
}

private struct ContentLibraryEnvironmentKey: EnvironmentKey {
    static let defaultValue: ContentLibrary? = nil
}

extension EnvironmentValues {
    var canadianHamContentLibrary: ContentLibrary? {
        get { self[ContentLibraryEnvironmentKey.self] }
        set { self[ContentLibraryEnvironmentKey.self] = newValue }
    }
}

struct LearnView: View {
    let library: ContentLibrary
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let revision: Int
    let onDataChanged: () -> Void

    @State private var lessonProgress: [LessonProgressRecord] = []
    @State private var errorMessage: String?

    var body: some View {
        if !bank.courseBankID.hasLessons {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Advanced lessons")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text("Advanced lessons are coming")
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Advanced lessons are coming. Use Advanced practice and mock exams in the meantime.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
                .pagePadding()
            }
            .background(DesignTokens.Colors.paper)
            .navigationTitle("Learn")
        } else {
        ScrollView {

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Structured lessons")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text("Learn")
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Study the eight modules in order. Lessons are currently authored in English; official practice questions follow your Language setting.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    Text("In the real exam you are given ISED's reference sheet of formulas and block diagrams. The lessons teach everything on it.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Exam day") // l10n: localized
                            .font(DesignTokens.FontScale.title.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text("Basic exams are closed book. The Authority, certificates, and exams lesson explains what to bring, allowed calculators, virtual exams, and where to download ISED's English unlabelled Basic reference sheet for practice.") // l10n: localized
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        NavigationLink("Read exam-day guidance", value: RootNavigationRoute.learn(.lesson("L-001-01")))
                            .buttonStyle(AccessibleSecondaryButtonStyle())
                    }
                    .padding(.top, DesignTokens.Spacing.sm)
                    EnglishOnlyLessonNotice()
                }
                .paperCard()

                if let errorMessage {
                    MessagePanel(title: "Learn progress unavailable", message: errorMessage, kind: .warning)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    ForEach(library.modules, id: \.id) { module in
                        moduleCard(module)
                    }
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle("Learn")
        .task(id: revision) { refreshProgress() }
        }
    }

    private func moduleCard(_ module: LessonModule) -> some View {
        let lessons = module.lessonIds.compactMap { library.lessonsById[$0] }
        let read = Set(lessonProgress.map(\.lessonId))
        let readCount = lessons.filter { read.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Module \(module.order) · \(module.categoryId)")
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(module.title.en, language: .english)) // l10n: content(en)
                .font(.headline)
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text(module.status == .outline ? "Outline available" : "Draft lessons available") // l10n: localized
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text(localizedLessonReadProgress(readCount: readCount, totalCount: lessons.count)) // l10n: localized
                .font(.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                NavigationLink("Open module", value: RootNavigationRoute.learn(.module(module.id)))
                    .tint(DesignTokens.Colors.ink)
                if let first = lessons.first {
                    NavigationLink("Start module", value: RootNavigationRoute.learn(.lesson(first.id)))
                        .tint(DesignTokens.Colors.ink)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .paperCard()
    }

    private func refreshProgress() {
        do {
            lessonProgress = try progressStore.lessonProgressRecords()
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

enum LearnRoute: Hashable {
    case module(String)
    case lesson(String)
    case lessonSection(String, String)
    case lessonQuiz(String)
}

struct LearnRouteDestinationView: View {
    let route: LearnRoute
    let library: ContentLibrary
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let onDataChanged: () -> Void
    let onOpenQuizHintLesson: (QuestionHintLessonLink) -> Void

    var body: some View {
        switch route {
        case .module(let id):
            if let module = library.modulesById[id] {
                ModuleLessonListView(module: module, library: library, lessonProgress: tryProgressRecords())
            } else {
                ContentUnavailableView("Module not found", systemImage: "book.closed")
            }
        case .lesson(let id):
            if let lesson = library.lessonsById[id] {
                LessonReaderView(
                    lesson: lesson,
                    library: library,
                    bank: bank,
                    progressStore: progressStore,
                    language: language,
                    targetSectionAnchor: nil,
                    onDataChanged: onDataChanged
                )
            } else {
                ContentUnavailableView("Lesson not found", systemImage: "book.closed")
            }
        case .lessonSection(let id, let anchor):
            if let lesson = library.lessonsById[id] {
                LessonReaderView(
                    lesson: lesson,
                    library: library,
                    bank: bank,
                    progressStore: progressStore,
                    language: language,
                    targetSectionAnchor: anchor,
                    onDataChanged: onDataChanged
                )
            } else {
                ContentUnavailableView("Lesson not found", systemImage: "book.closed")
            }
        case .lessonQuiz(let id):
            if let quiz = library.quizzesById[id], let lesson = library.lessonsById[quiz.lessonId] {
                LessonQuizScreen(
                    quiz: quiz,
                    lesson: lesson,
                    bank: bank,
                    library: library,
                    progressStore: progressStore,
                    language: language,
                    onDataChanged: onDataChanged,
                    onOpenHintLesson: onOpenQuizHintLesson
                )
            } else {
                ContentUnavailableView("Lesson quiz not found", systemImage: "questionmark.circle")
            }
        }
    }

    private func tryProgressRecords() -> [LessonProgressRecord] {
        (try? progressStore.lessonProgressRecords()) ?? []
    }
}

private struct ModuleLessonListView: View {
    let module: LessonModule
    let library: ContentLibrary
    let lessonProgress: [LessonProgressRecord]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Module \(module.order) · \(module.categoryId)")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text(localized(module.title.en, language: .english)) // l10n: content(en)
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    EnglishOnlyLessonNotice()
                    LessonMarkdownView(markdown: module.bodyMarkdown, title: module.title.en)
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Lessons")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(module.lessonIds.compactMap { library.lessonsById[$0] }, id: \.id) { lesson in
                        NavigationLink(value: RootNavigationRoute.learn(.lesson(lesson.id))) {
                            LessonRow(lesson: lesson, isRead: lessonProgress.contains { $0.lessonId == lesson.id })
                        }
                        .buttonStyle(.plain)
                    }
                }
                .paperCard()
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(Text(english(module.title.en))) // l10n: content(en)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isRead: Bool

    private var lessonStatusText: String {
        lesson.status == .outline ? String(localized: "Coming soon") : String(localized: "Ready to read")
    }

    private var readStatusText: String {
        isRead ? String(localized: "Marked read") : String(localized: "Not marked read")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("\(lesson.id) · \(lesson.estimatedMinutes) min · \(lesson.covers.joined(separator: ", "))")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(lesson.title.en, language: .english)) // l10n: content(en)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(lessonStatusText) · \(readStatusText)")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
        .paperCard()
    }
}

private struct LessonReaderView: View {
    let lesson: Lesson
    let library: ContentLibrary
    let bank: QuestionBank
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let targetSectionAnchor: String?
    let onDataChanged: () -> Void

    @State private var lessonProgress: LessonProgressRecord?
    @State private var quizAttempts: [LessonQuizAttempt] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("\(lesson.id) · \(lesson.estimatedMinutes) min · \(lesson.covers.joined(separator: ", "))")
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                        Text(localized(lesson.title.en, language: .english)) // l10n: content(en)
                            .font(DesignTokens.FontScale.headline.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("lesson-reader-title")
                        if let lessonProgress {
                            Text(markedReadText(lessonProgress.readCount)) // l10n: localized
                                .font(DesignTokens.FontScale.caption)
                                .foregroundStyle(DesignTokens.Colors.inkMuted)
                        } else {
                            Text("Not marked read yet.")
                                .font(DesignTokens.FontScale.caption)
                                .foregroundStyle(DesignTokens.Colors.inkMuted)
                        }
                        LessonPrerequisitesSection(prerequisites: prerequisiteLessons)
                    }
                    .paperCard()

                    if let errorMessage {
                        MessagePanel(title: "Lesson progress unavailable", message: errorMessage, kind: .warning)
                    }

                    if lesson.status == .outline {
                        OutlineLessonView(lesson: lesson, library: library)
                    } else {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                            EnglishOnlyLessonNotice()
                            LessonMarkdownView(markdown: lesson.bodyMarkdown, title: lesson.title.en, targetAnchor: targetSectionAnchor)
                        }
                        .paperCard()
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Button { markRead() } label: {
                            lessonActionLabel(Text("Mark lesson read"))
                        }
                        .buttonStyle(.plain)
                        if let firstQuizID = lesson.quizIds.first {
                            NavigationLink("Go to quiz", value: RootNavigationRoute.learn(.lessonQuiz(firstQuizID)))
                                .buttonStyle(AccessiblePrimaryButtonStyle())
                                .accessibilityIdentifier("go-to-lesson-quiz-button")
                        }
                        if let previous = neighbor(offset: -1) {
                            NavigationLink(value: RootNavigationRoute.learn(.lesson(previous.id))) {
                                lessonActionLabel(Text(lessonNavigationTitle(prefix: String(localized: "Previous: "), lessonTitle: previous.title.en))) // l10n: localized
                            }
                            .buttonStyle(.plain)
                        }
                        if let next = neighbor(offset: 1) {
                            NavigationLink(value: RootNavigationRoute.learn(.lesson(next.id))) {
                                lessonActionLabel(Text(lessonNavigationTitle(prefix: String(localized: "Next: "), lessonTitle: next.title.en))) // l10n: localized
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    quizCards
                }
                .pagePadding()
            }
            .onAppear { focusTargetSection(scrollProxy) }
            .onChange(of: targetSectionAnchor) { _, _ in focusTargetSection(scrollProxy) }
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(lessonModuleNavigationTitle) // l10n: localized
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .lessonReaderOpaqueNavigationBar()
        .task { refresh() }
    }

    private var prerequisiteLessons: [Lesson] {
        lesson.prerequisites.compactMap { library.lessonsById[$0] }
    }

    private var lessonModuleNavigationTitle: String {
        guard let module = library.modulesById[lesson.moduleId] else {
            return String(localized: "Lesson")
        }
        return String(localized: "Module \(module.order)")
    }

    private func focusTargetSection(_ scrollProxy: ScrollViewProxy) {
        guard let targetSectionAnchor else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollProxy.scrollTo(targetSectionAnchor, anchor: .top)
            }
            AccessibilityNotification.Announcement(String(localized: "Lesson section opened.")).post()
        }
    }

    private func lessonActionLabel(_ text: Text) -> some View {
        text
            .font(.body.weight(.semibold))
            .foregroundStyle(DesignTokens.Colors.ink)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
            .frame(minHeight: 56, alignment: .leading)
            .background(DesignTokens.Colors.paperInset, in: Capsule())
            .overlay(Capsule().strokeBorder(DesignTokens.Colors.ink, lineWidth: 1))
    }


    private func lessonNavigationTitle(prefix: String, lessonTitle: String) -> AttributedString {
        var label = AttributedString(prefix)
        label += english(lessonTitle)
        return label
    }

    private var quizCards: some View {
        ForEach(lesson.quizIds.compactMap { library.quizzesById[$0] }, id: \.id) { quiz in
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Lesson quiz")
                    .font(DesignTokens.FontScale.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                Text(quiz.id) // l10n: verbatim
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("\((try? buildLessonQuizItems(quiz: quiz, seed: "summary", library: library).count) ?? 0) questions: official bank questions update practice progress; concept checks do not.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                if let latest = quizAttempts.filter({ $0.quizId == quiz.id }).last {
                    Text("Latest result: \(latest.correct) / \(latest.total) (\(latest.percent, format: .number.precision(.fractionLength(0...0)))%). Attempts saved: \(quizAttempts.filter { $0.quizId == quiz.id }.count).")
                        .font(DesignTokens.FontScale.caption)
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                        .accessibilityIdentifier("lesson-quiz-latest-score")
                }
                NavigationLink("Start quiz", value: RootNavigationRoute.learn(.lessonQuiz(quiz.id)))
                    .buttonStyle(AccessiblePrimaryButtonStyle())
            }
            .paperCard()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("lesson-quiz-summary-\(quiz.id)")
        }
    }

    private func refresh() {
        do {
            lessonProgress = try progressStore.lessonProgressRecords().first { $0.lessonId == lesson.id }
            quizAttempts = try progressStore.lessonQuizAttempts().filter { $0.lessonId == lesson.id }
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func markRead() {
        do {
            let existing = try progressStore.lessonProgressRecords().first { $0.lessonId == lesson.id }
            let record = LessonProgressRecord(
                lessonId: lesson.id,
                readAt: try AppleStudyEngine.canonicalNow(),
                readCount: (existing?.readCount ?? 0) + 1
            )
            try progressStore.saveLessonProgress(record)
            lessonProgress = record
            errorMessage = nil
            onDataChanged()
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }

    private func neighbor(offset: Int) -> Lesson? {
        let ordered = library.orderedLessons()
        guard let index = ordered.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        return ordered[safe: index + offset]
    }
}

private struct LessonPrerequisitesSection: View {
    let prerequisites: [Lesson]

    var body: some View {
        if !prerequisites.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Before this lesson") // l10n: localized
                    .font(DesignTokens.FontScale.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("lesson-prerequisites-heading")
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    ForEach(prerequisites, id: \.id) { prerequisite in
                        NavigationLink(value: RootNavigationRoute.learn(.lesson(prerequisite.id))) {
                            Text(localized(prerequisite.title.en, language: .english)) // l10n: content(en)
                                .font(DesignTokens.FontScale.body.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .padding(.horizontal, DesignTokens.Spacing.md)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                                        .strokeBorder(DesignTokens.Colors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Open lesson \(Text(english(prerequisite.title.en)))")) // l10n: localized
                        .accessibilityIdentifier("lesson-prerequisite-link-\(prerequisite.id)")
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("lesson-prerequisites-section")
        }
    }
}

extension View {
    @ViewBuilder
    func lessonReaderOpaqueNavigationBar() -> some View {
#if os(iOS)
        toolbarBackground(DesignTokens.Colors.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
#else
        self
#endif
    }
}

private struct OutlineLessonView: View {
    let lesson: Lesson
    let library: ContentLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Coming soon")
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("This outline is bundled so module order and objectives remain visible offline while the full lesson is authored.")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("Objectives")
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            ForEach(lesson.objectives, id: \.self) { objective in
                Label {
                    Text(localized(objective, language: .english)) // l10n: content(en)
                } icon: {
                    Image(systemName: "circle.fill")
                }
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            }
            Text("Covered subsections")
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            ForEach(lesson.covers, id: \.self) { cover in
                Text(localized("\(cover): \(library.subsectionTitlesById[cover]?.title.en ?? cover)", language: .english)) // l10n: content(en)
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        }
        .paperCard()
    }
}

@MainActor
final class LessonQuizSessionState: ObservableObject {
    let generation = UUID()
    @Published var seed: String
    @Published var items: [LessonQuizRuntimeItem] = []
    @Published var currentIndex = 0
    @Published var checkpointVisible = false
    @Published var selectedByItemId: [String: Int] = [:]
    @Published var submittedAttemptID: String?
    @Published var errorMessage: String?
    @Published var hintLevelsByQuestionId: [String: Int] = [:]
    @Published var hintQualifiedQuestionIds: Set<String> = []
    @Published var answeredWithHelpIds: Set<String> = []

    func next(in quiz: LessonQuiz) {
        if let round = lessonQuizRoundProgress(quiz: quiz, items: items, currentIndex: currentIndex),
           currentIndex == round.endIndex, currentIndex + 1 < items.count {
            checkpointVisible = true
        } else {
            currentIndex = min(items.count - 1, currentIndex + 1)
        }
    }

    func continueRound() {
        guard checkpointVisible, currentIndex + 1 < items.count else { return }
        checkpointVisible = false
        currentIndex += 1
    }

    func previous() {
        if checkpointVisible {
            checkpointVisible = false
        } else {
            currentIndex = max(0, currentIndex - 1)
        }
    }

    func select(_ sourceOrChoiceIndex: Int, for item: LessonQuizRuntimeItem) {
        guard selectedByItemId[item.id] == nil, submittedAttemptID == nil else { return }
        if let questionID = item.questionID {
            answeredWithHelpIds = PracticeHintRules.answeredWithHelpQuestionIdsAfterSelection(
                questionID: questionID,
                qualifiedQuestionIds: hintQualifiedQuestionIds,
                answeredWithHelpQuestionIds: answeredWithHelpIds
            )
        }
        selectedByItemId[item.id] = sourceOrChoiceIndex
    }

    @discardableResult
    func qualifyHint(for item: LessonQuizRuntimeItem) -> Bool {
        guard items[safe: currentIndex]?.id == item.id, let questionID = item.questionID,
              selectedByItemId[item.id] == nil, submittedAttemptID == nil else { return false }
        return hintQualifiedQuestionIds.insert(questionID).inserted
    }

    init() {
#if DEBUG
        seed = AppLaunchArguments.value(after: "-CanadianHamLessonQuizSeed") ?? "lesson-quiz/\(UUID().uuidString)"
#else
        seed = "lesson-quiz/\(UUID().uuidString)"
#endif
    }
}

@MainActor
final class LessonQuizSessionStateCache: ObservableObject {
    private var states: [String: LessonQuizSessionState] = [:]

    func state(for quizID: String) -> LessonQuizSessionState {
        if let state = states[quizID] { return state }
        let state = LessonQuizSessionState()
        states[quizID] = state
        return state
    }

    func clear() {
        objectWillChange.send()
        states.removeAll()
    }
}

struct LessonQuizScreen: View {
    let quiz: LessonQuiz
    let lesson: Lesson
    let bank: QuestionBank
    let library: ContentLibrary
    @ObservedObject var progressStore: ProgressStoreService
    let language: BankLanguage
    let onDataChanged: () -> Void
    let onOpenHintLesson: (QuestionHintLessonLink) -> Void
    @EnvironmentObject private var sessions: LessonQuizSessionStateCache

    @State private var attempts: [LessonQuizAttempt] = []
    @State private var errorMessage: String?

    var body: some View {
        LessonQuizView(
            quiz: quiz,
            lesson: lesson,
            bank: bank,
            library: library,
            language: language,
            progressStore: progressStore,
            attempts: attempts,
            loadErrorMessage: errorMessage,
            state: sessions.state(for: quiz.id),
            onOpenHintLesson: onOpenHintLesson,
            onSaved: {
                refresh()
                onDataChanged()
            }
        )
        .task { refresh() }
    }

    private func refresh() {
        do {
            attempts = try progressStore.lessonQuizAttempts().filter { $0.lessonId == lesson.id && $0.quizId == quiz.id }
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

// Keep one child tree: ViewThatFits candidates can lose audit-node provenance when Dynamic Type changes.
private struct LessonQuizControlLayout: Layout {
    let horizontalAlignment: VerticalAlignment
    let verticalSpacing: CGFloat
    let forceVertical: Bool

    private func fittingLayout(proposal: ProposedViewSize, subviews: Subviews) -> AnyLayout {
        let horizontal = AnyLayout(HStackLayout(alignment: horizontalAlignment))
        var cache = horizontal.makeCache(subviews: subviews)
        let ideal = horizontal.sizeThatFits(proposal: .unspecified, subviews: subviews, cache: &cache)
        if !forceVertical && ideal.width <= (proposal.width ?? .infinity) {
            return horizontal
        }
        return AnyLayout(VStackLayout(alignment: .leading, spacing: verticalSpacing))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = fittingLayout(proposal: proposal, subviews: subviews)
        var layoutCache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &layoutCache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = fittingLayout(proposal: proposal, subviews: subviews)
        var layoutCache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &layoutCache)
    }
}

private struct LessonQuizView: View {
    let quiz: LessonQuiz
    let lesson: Lesson
    let bank: QuestionBank
    let library: ContentLibrary
    let language: BankLanguage
    @ObservedObject var progressStore: ProgressStoreService
    let attempts: [LessonQuizAttempt]
    let loadErrorMessage: String?

    @ObservedObject var state: LessonQuizSessionState
    let onOpenHintLesson: (QuestionHintLessonLink) -> Void
    let onSaved: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedTool: ExamTool?
    // The shared tool presenter requires a calculator model; this quiz exposes only .hint.
    @StateObject private var presentationCalculator = ExamCalculatorViewModel()
    @State private var calculatorFocused = false
    @AccessibilityFocusState private var roundFocus: LessonQuizRoundFocus?
    @State private var previousRoundPosition: LessonQuizRoundPosition?

    private var roundPosition: LessonQuizRoundPosition {
        LessonQuizRoundPosition(roundIndex: roundProgress?.roundIndex, checkpointVisible: state.checkpointVisible)
    }

    private var roundProgress: LessonQuizRoundProgress? {
        lessonQuizRoundProgress(quiz: quiz, items: items, currentIndex: currentIndex)
    }

    private var seed: String {
        get { state.seed }
        nonmutating set { state.seed = newValue }
    }
    private var items: [LessonQuizRuntimeItem] {
        get { state.items }
        nonmutating set { state.items = newValue }
    }
    private var currentIndex: Int {
        get { state.currentIndex }
        nonmutating set { state.currentIndex = newValue }
    }
    private var selectedByItemId: [String: Int] {
        get { state.selectedByItemId }
        nonmutating set { state.selectedByItemId = newValue }
    }
    private var submittedAttemptID: String? {
        get { state.submittedAttemptID }
        nonmutating set { state.submittedAttemptID = newValue }
    }
    private var errorMessage: String? {
        get { state.errorMessage }
        nonmutating set { state.errorMessage = newValue }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    if let loadErrorMessage {
                        MessagePanel(title: "Lesson quiz unavailable", message: loadErrorMessage, kind: .warning)
                    }
                    quizCard
                }
                .pagePadding()
            }
            .background(DesignTokens.Colors.paper)
            .navigationTitle("Lesson quiz")
            .task(id: state.generation) { if items.isEmpty { restart(keepSeed: true) } }
            .examToolPresentation(
                selectedTool: $selectedTool,
                calculator: presentationCalculator,
                calculatorFocused: $calculatorFocused,
                hintContext: hintToolContext
            )
            .onChange(of: currentIndex) { _, _ in selectedTool = nil }
            .task(id: roundPosition) {
                let position = roundPosition
                let target = position.focusTarget(from: previousRoundPosition)
                previousRoundPosition = position
                guard let target else { return }
                selectedTool = nil
                roundFocus = nil
                await Task.yield()
                guard !Task.isCancelled else { return }
                proxy.scrollTo("lesson-quiz-position", anchor: .top)
                roundFocus = target
            }
            .onDisappear { selectedTool = nil }
        }
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            quizHeaderControls

            if let errorMessage {
                MessagePanel(title: "Lesson quiz unavailable", message: errorMessage, kind: .warning)
            }

            if state.checkpointVisible, let round = roundProgress {
                roundCheckpoint(round)
            } else if let item = items[safe: currentIndex] {
                if let round = roundProgress {
                    Text("Round \(round.roundIndex + 1) of \(round.roundCount): \(round.round.title.textAndLanguage(for: canadianHamUsesFrenchUI ? .french : .english).text)") // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("lesson-quiz-round-heading")
                        .accessibilityFocused($roundFocus, equals: .question)
                        .id("lesson-quiz-position")
                }
                if let reviewLessonId = item.reviewLessonId, let reviewLesson = library.lessonsById[reviewLessonId] {
                    Text(lessonQuizReviewHeading(title: reviewLesson.title, language: canadianHamUsesFrenchUI ? .french : .english)) // l10n: localized
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("lesson-quiz-review-heading")
                }
                Text("Question \(currentIndex - (roundProgress?.startIndex ?? 0) + 1) of \(roundProgress?.questionCount ?? items.count)") // l10n: localized
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                if hintToolContext != nil {
                    ExamToolButtons(availableTools: [.hint]) { selectedTool = $0 }
                }
                LessonQuizQuestionView(
                    item: item,
                    bank: bank,
                    library: library,
                    language: language,
                    selectedSourceOrChoiceIndex: selectedByItemId[item.id],
                    answeredWithHelp: item.questionID.map { state.answeredWithHelpIds.contains($0) } ?? false,
                    disabled: selectedByItemId[item.id] != nil || submittedAttemptID != nil
                ) { selected in
                    state.select(selected, for: item)
                }
                quizNavigationControls
                if let submittedAttemptID, let attempt = attempts.first(where: { $0.id == submittedAttemptID }) {
                    Text("Saved result: \(attempt.correct) / \(attempt.total) (\(attempt.percent, format: .number.precision(.fractionLength(0...0)))%).")
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
            } else {
                Text("No quiz items are bundled for this lesson yet.")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        }
        .paperCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("lesson-quiz-card")
    }

    private func roundCheckpoint(_ round: LessonQuizRoundProgress) -> some View {
        let roundItems = Array(items[round.startIndex...round.endIndex])
        let correct = roundItems.filter { selectedByItemId[$0.id] == 0 }.count
        let answered = roundItems.filter { selectedByItemId[$0.id] != nil }.count
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("Round \(round.roundIndex + 1) of \(round.roundCount) checkpoint") // l10n: localized
                .font(DesignTokens.FontScale.title.weight(.bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("lesson-quiz-round-checkpoint")
                .accessibilityFocused($roundFocus, equals: .checkpoint)
                .id("lesson-quiz-position")
            Text(round.round.title.textAndLanguage(for: canadianHamUsesFrenchUI ? .french : .english).text) // l10n: verbatim
                .font(DesignTokens.FontScale.body)
            Text("Score so far: \(correct) / \(round.questionCount). Answered: \(answered) / \(round.questionCount).") // l10n: localized
                .font(DesignTokens.FontScale.body)
                .accessibilityIdentifier("lesson-quiz-round-score")
            Button { state.previous() } label: {
                AccessibleSecondaryButtonLabel(title: "Previous")
            }
            .buttonStyle(AccessibleSecondaryButtonStyle())
            Button("Continue to next round") { state.continueRound() }
                .buttonStyle(AccessiblePrimaryButtonStyle())
                .accessibilityIdentifier("lesson-quiz-round-continue")
        }
        .foregroundStyle(DesignTokens.Colors.ink)
    }

    private var quizHeaderControls: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DesignTokens.Spacing.md))
            : AnyLayout(HStackLayout(alignment: .top))
        return layout {
            quizHeader
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }
            retryButton
        }
    }

    private var quizNavigationControls: some View {
        LessonQuizControlLayout(
            horizontalAlignment: .center,
            verticalSpacing: DesignTokens.Spacing.sm,
            forceVertical: dynamicTypeSize.isAccessibilitySize
        ) { navigationButtons }
    }

    private var quizHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Lesson quiz")
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(quiz.id) // l10n: verbatim
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text("\(items.count) questions: official bank questions update practice progress; concept checks do not.")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            if let latest = attempts.last {
                Text("Latest result: \(latest.correct) / \(latest.total) (\(latest.percent, format: .number.precision(.fractionLength(0...0)))%). Attempts saved: \(attempts.count).")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .accessibilityIdentifier("lesson-quiz-latest-score")
                Text("Answers with help: \(latest.answeredWithHelpIds?.count ?? 0).") // l10n: localized
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityIdentifier("lesson-quiz-help-summary")
            }
        }
    }

    private var retryButton: some View {
        Button { restart() } label: {
            AccessibleSecondaryButtonLabel(title: "Retry quiz")
        }
        .buttonStyle(AccessibleSecondaryButtonStyle())
    }

    private var hintToolContext: HintToolContext? {
        guard let item = items[safe: currentIndex], let questionID = item.questionID,
              bank.courseBankID == .basic, let hint = library.questionHintsByQuestionId[questionID] else { return nil }
        return HintToolContext(
            hint: hint,
            language: language,
            visibleLevel: state.hintLevelsByQuestionId[questionID] ?? 0,
            answeredWithHelpQualified: state.hintQualifiedQuestionIds.contains(questionID),
            canRecordHelp: selectedByItemId[item.id] == nil && submittedAttemptID == nil,
            referenceSheetAvailable: false,
            revealLevel: { state.hintLevelsByQuestionId[questionID] = max(state.hintLevelsByQuestionId[questionID] ?? 0, $0) },
            hintVisibleLongEnough: {
                state.qualifyHint(for: item)
            },
            openLesson: { link in
                selectedTool = nil
                // Dismiss the compact tool sheet before pushing a lesson on its parent stack.
                Task { @MainActor in
                    await Task.yield()
                    onOpenHintLesson(link)
                }
            }
        )
    }

    @ViewBuilder
    private var navigationButtons: some View {
        Button { state.previous() } label: {
            AccessibleSecondaryButtonLabel(title: "Previous")
        }
        .disabled(currentIndex == 0)
        .buttonStyle(AccessibleSecondaryButtonStyle())
        Button { state.next(in: quiz) } label: {
            AccessibleSecondaryButtonLabel(title: "Next")
        }
        .disabled(currentIndex + 1 >= items.count)
        .buttonStyle(AccessibleSecondaryButtonStyle())
        Button("Submit lesson quiz") { submit() }
            .buttonStyle(AccessiblePrimaryButtonStyle())
            .disabled(!allAnswered || submittedAttemptID != nil)
            .accessibilityIdentifier("submit-lesson-quiz-button")
    }

    private var allAnswered: Bool {
        !items.isEmpty && items.allSatisfy { selectedByItemId[$0.id] != nil }
    }

    private func restart(keepSeed: Bool = false) {
        previousRoundPosition = nil
        roundFocus = nil
        if !keepSeed {
            seed = "lesson-quiz/\(quiz.id)/\(attempts.count + 1)/\(UUID().uuidString)"
        }
        do {
            items = try buildLessonQuizItems(quiz: quiz, seed: seed, library: library)
            currentIndex = 0
            state.checkpointVisible = false
            selectedByItemId = [:]
            state.hintLevelsByQuestionId = [:]
            state.hintQualifiedQuestionIds = []
            state.answeredWithHelpIds = []
            selectedTool = nil
            submittedAttemptID = nil
            errorMessage = nil
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
            items = []
        }
    }

    private func submit() {
        do {
            let submittedAt = try AppleStudyEngine.canonicalNow()
            var correct = 0
            var officialQuestionIds: [String] = []
            var reviewQuestionIds: [String] = []
            var incorrectOfficialQuestionIds: [String] = []
            var incorrectConceptCheckIds: [String] = []
            var progress = try progressStore.questionProgressRecords()

            for item in items {
                guard let selected = selectedByItemId[item.id] else { continue }
                switch item {
                case .official(_, let questionId, _, let reviewLessonId):
                    if reviewLessonId == nil { officialQuestionIds.append(questionId) } else { reviewQuestionIds.append(questionId) }
                    if selected == 0 {
                        correct += 1
                    } else {
                        incorrectOfficialQuestionIds.append(questionId)
                    }
                    if let question = bank.question(id: questionId) {
                        progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: selected, now: submittedAt, answeredWithHelp: state.answeredWithHelpIds.contains(questionId))
                    }
                case .concept(_, let conceptCheck, _):
                    if conceptCheck.choices[safe: selected]?.isCorrect == true {
                        correct += 1
                    } else {
                        incorrectConceptCheckIds.append(conceptCheck.id)
                    }
                }
            }

            let attempt = LessonQuizAttempt(
                id: "lesson-quiz-\(submittedAt)-\(quiz.id)-\(seed)",
                quizId: quiz.id,
                lessonId: lesson.id,
                submittedAt: submittedAt,
                correct: correct,
                total: items.count,
                percent: items.isEmpty ? 0 : (Double(correct) / Double(items.count)) * 100,
                officialQuestionIds: officialQuestionIds,
                incorrectOfficialQuestionIds: incorrectOfficialQuestionIds,
                incorrectConceptCheckIds: incorrectConceptCheckIds,
                answeredWithHelpIds: state.answeredWithHelpIds.sorted(),
                reviewQuestionIds: reviewQuestionIds.sorted()
            )
            try progressStore.saveLessonQuizAttempt(attempt, questionProgress: progress)
            submittedAttemptID = attempt.id
            errorMessage = nil
            onSaved()
        } catch {
            errorMessage = localizedErrorMessage(String(localized: "Unable to complete this operation: \("")"), detail: error)
        }
    }
}

enum LessonQuizRuntimeItem: Identifiable, Equatable {
    case official(id: String, questionId: String, choicePermutation: [Int], reviewLessonId: String? = nil)
    case concept(id: String, conceptCheck: ConceptCheck, choicePermutation: [Int])

    var id: String {
        switch self {
        case .official(let id, _, _, _), .concept(let id, _, _): id
        }
    }

    var reviewLessonId: String? {
        if case .official(_, _, _, let lessonId) = self { return lessonId }
        return nil
    }

    var questionID: String? {
        if case .official(_, let questionID, _, _) = self { return questionID }
        return nil
    }
}

enum LessonQuizRoundFocus: Hashable { case question, checkpoint }

struct LessonQuizRoundPosition: Equatable {
    let roundIndex: Int?
    let checkpointVisible: Bool

    func focusTarget(from previous: Self?) -> LessonQuizRoundFocus? {
        guard let roundIndex, let previous, previous.roundIndex != nil else { return nil }
        if checkpointVisible && !previous.checkpointVisible { return .checkpoint }
        return roundIndex != previous.roundIndex ? .question : nil
    }
}

struct LessonQuizRoundProgress {
    let round: LessonQuizRound
    let roundIndex: Int
    let roundCount: Int
    let startIndex: Int
    let endIndex: Int
    var questionCount: Int { endIndex - startIndex + 1 }
}

func lessonQuizRoundProgress(quiz: LessonQuiz, items: [LessonQuizRuntimeItem], currentIndex: Int) -> LessonQuizRoundProgress? {
    guard quiz.conceptChecks.isEmpty, let id = items[safe: currentIndex]?.questionID, var rounds = quiz.rounds else { return nil }
    let reviewIds = items.filter { $0.reviewLessonId != nil }.compactMap(\.questionID)
    if !reviewIds.isEmpty {
        rounds.append(LessonQuizRound(sectionAnchor: "review", title: LocalizedNullableText(en: "Review", fr: "Révision"), officialQuestionIds: reviewIds))
    }
    guard let roundIndex = rounds.firstIndex(where: { $0.officialQuestionIds.contains(id) }) else { return nil }
    let round = rounds[roundIndex]
    let indices = items.indices.filter { index in
        items[index].questionID.map { round.officialQuestionIds.contains($0) } ?? false
    }
    guard let startIndex = indices.first, let endIndex = indices.last else { return nil }
    return LessonQuizRoundProgress(round: round, roundIndex: roundIndex, roundCount: rounds.count, startIndex: startIndex, endIndex: endIndex)
}

func lessonQuizReviewHeading(title: LocalizedNullableText, language: BankLanguage, bundle: Bundle = .main) -> AttributedString {
    let localizedTitle = title.textAndLanguage(for: language)
    var attributedTitle = AttributedString(localizedTitle.text)
    attributedTitle.languageIdentifier = localizedTitle.language == .english ? "en" : "fr"
    return AttributedString(localized: "Review question from \(attributedTitle)", bundle: bundle)
}

func buildLessonQuizItems(quiz: LessonQuiz, seed: String, library: ContentLibrary? = nil) throws -> [LessonQuizRuntimeItem] {
    let official = try quiz.officialQuestionIds.enumerated().map { index, questionId in
        var rng = Pcg32(seed: "\(seed):official:\(index):\(questionId)")
        return LessonQuizRuntimeItem.official(
            id: "\(quiz.id):official:\(questionId)",
            questionId: questionId,
            choicePermutation: try CanadianHamEngine.shuffled([0, 1, 2, 3], rng: &rng)
        )
    }
    let concepts = try quiz.conceptChecks.enumerated().map { index, check in
        var rng = Pcg32(seed: "\(seed):concept:\(index):\(check.id)")
        return LessonQuizRuntimeItem.concept(
            id: "\(quiz.id):concept:\(check.id)",
            conceptCheck: check,
            choicePermutation: try CanadianHamEngine.shuffled(Array(check.choices.indices), rng: &rng)
        )
    }
    var rng = Pcg32(seed: "\(seed):items:\(quiz.id)")
    let seededItems = try CanadianHamEngine.shuffled(official + concepts, rng: &rng)
    // Group the existing seeded order without changing choice permutations.
    var shuffled = (quiz.conceptChecks.isEmpty ? quiz.rounds : nil).map { rounds in
        rounds.flatMap { round in seededItems.filter { item in
            item.questionID.map { round.officialQuestionIds.contains($0) } ?? false
        } }
    } ?? seededItems
#if DEBUG
    // Keep the existing total-prefix control unchanged; this control exercises the final review round.
    if let value = AppLaunchArguments.value(after: "-CanadianHamLessonQuizCoreLimit"), let limit = Int(value), limit > 0 {
        shuffled = Array(shuffled.prefix(limit))
    }
#endif
    if let library {
        let pools = library.orderedLessons().map { lesson in
            LessonReviewPool(lessonId: lesson.id, questionIds: library.questions.filter { lesson.covers.contains($0.subsectionId) }.map(\.id))
        }
        let excluded = quiz.officialQuestionIds + library.questions.filter { library.lessonsById[quiz.lessonId]?.covers.contains($0.subsectionId) == true }.map(\.id)
        let reviews = try selectLessonReviewItems(orderedPools: pools, lessonId: quiz.lessonId, excludedQuestionIds: excluded, seed: seed)
        shuffled += try reviews.enumerated().map { index, review in
            var rng = Pcg32(seed: "\(seed):review-choice:\(index):\(review.questionId)")
            return .official(id: "\(quiz.id):review:\(review.questionId)", questionId: review.questionId, choicePermutation: try CanadianHamEngine.shuffled([0, 1, 2, 3], rng: &rng), reviewLessonId: review.lessonId)
        }
    }
#if DEBUG
    if let value = AppLaunchArguments.value(after: "-CanadianHamLessonQuizLimit"), let limit = Int(value), limit > 0 {
        return Array(shuffled.prefix(limit))
    }
#endif
    return shuffled
}

private struct LessonQuizQuestionView: View {
    let item: LessonQuizRuntimeItem
    let bank: QuestionBank
    let library: ContentLibrary
    let language: BankLanguage
    let selectedSourceOrChoiceIndex: Int?
    let answeredWithHelp: Bool
    let disabled: Bool
    let onChoose: (Int) -> Void

    var body: some View {
        switch item {
        case .official(_, let questionId, let permutation, _):
            if let question = bank.question(id: questionId) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    QuestionCard(question: question, language: language)
                    ForEach(Array(permutation.enumerated()), id: \.offset) { displayIndex, sourceIndex in
                        if let answer = question.answers.first(where: { $0.sourceIndex == sourceIndex }) {
                            AnswerChoiceButton(
                                answer: answer,
                                displayIndex: displayIndex,
                                language: language,
                                selectedSourceIndex: selectedSourceOrChoiceIndex,
                                showCorrectness: selectedSourceOrChoiceIndex != nil,
                                disabled: disabled
                            ) { onChoose(sourceIndex) }
                        }
                    }
                    if let selectedSourceOrChoiceIndex {
                        if answeredWithHelp {
                            Text("Answered with help")
                                .font(DesignTokens.FontScale.body.weight(.semibold))
                                .foregroundStyle(DesignTokens.Colors.ink)
                                .accessibilityIdentifier("lesson-quiz-with-help-marker")
                        }
                        PracticeFeedback(question: question, selectedSourceIndex: selectedSourceOrChoiceIndex, language: language, choicePermutation: permutation)
                    }
                }
            } else {
                Text("Official question \(questionId) is loading from the bundled bank.") // l10n: localized
                    .font(DesignTokens.FontScale.body)
            }
        case .concept(_, let check, let permutation):
            ConceptCheckQuestionView(check: check, permutation: permutation, language: language, selectedChoiceIndex: selectedSourceOrChoiceIndex, disabled: disabled, onChoose: onChoose)
        }
    }
}

private struct ConceptCheckQuestionView: View {
    let check: ConceptCheck
    let permutation: [Int]
    let language: BankLanguage
    let selectedChoiceIndex: Int?
    let disabled: Bool
    let onChoose: (Int) -> Void
    @AccessibilityFocusState private var feedbackFocused: Bool
    @State private var feedbackFocusRequest = ConceptCheckFeedbackFocusRequest()

    var body: some View {
        let prompt = check.prompt.textAndLanguage(for: language)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Concept check · \(check.id)")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(prompt.text, language: prompt.language)) // l10n: content(question)
                .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            ForEach(Array(permutation.enumerated()), id: \.offset) { displayIndex, choiceIndex in
                if let choice = check.choices[safe: choiceIndex] {
                    ConceptChoiceButton(choice: choice, displayIndex: displayIndex, sourceIndex: choiceIndex, language: language, selectedChoiceIndex: selectedChoiceIndex, showCorrectness: selectedChoiceIndex != nil, disabled: disabled) {
                        feedbackFocusRequest.pendingCheckID = check.id
                        onChoose(choiceIndex)
                    }
                }
            }
            if let selectedChoiceIndex {
                let isCorrect = check.choices[safe: selectedChoiceIndex]?.isCorrect == true
                let feedbackTextColor = isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    if let status = conceptCheckAnswerStatus(check: check, selectedSourceIndex: selectedChoiceIndex, language: language) {
                        Text(status) // l10n: content(question)
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(feedbackTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("lesson-quiz-feedback-status")
                            .accessibilityFocused($feedbackFocused)
                            .task(id: selectedChoiceIndex) {
                                guard feedbackFocusRequest.consume(for: check.id) else { return }
                                await Task.yield()
                                guard !Task.isCancelled else { return }
                                feedbackFocused = true
                            }
                    }
                    let explanation = check.explanation.textAndLanguage(for: language)
                    Text(localized(explanation.text, language: explanation.language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(feedbackTextColor)
                        .accessibilityIdentifier("lesson-quiz-feedback-explanation")
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("lesson-quiz-feedback")
            }
        }
        .onChange(of: check.id) {
            feedbackFocusRequest.pendingCheckID = nil
            feedbackFocused = false
        }
        .onDisappear {
            feedbackFocusRequest.pendingCheckID = nil
            feedbackFocused = false
        }
    }
}

// A restored answer must not request focus; only a choice action arms this one-shot flag.
struct ConceptCheckFeedbackFocusRequest {
    var pendingCheckID: String?

    mutating func consume(for checkID: String) -> Bool {
        defer { pendingCheckID = nil }
        return pendingCheckID == checkID
    }
}

private struct ConceptChoiceButton: View {
    let choice: ConceptCheckChoice
    let displayIndex: Int
    let sourceIndex: Int
    let language: BankLanguage
    let selectedChoiceIndex: Int?
    let showCorrectness: Bool
    let disabled: Bool
    let action: () -> Void

    private var letter: String { ["A", "B", "C", "D"][safe: displayIndex] ?? "\(displayIndex + 1)" }
    private var selected: Bool { selectedChoiceIndex == sourceIndex }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(letter) // l10n: verbatim
                    .font(DesignTokens.FontScale.body.monospaced().weight(.bold))
                    .frame(minWidth: 34, minHeight: 34)
                    .padding(DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.ink, in: Circle())
                    .foregroundStyle(DesignTokens.Colors.paperElevated)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    let choiceText = choice.text.textAndLanguage(for: language)
                    Text(localized(choiceText.text, language: choiceText.language)) // l10n: content(question)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    if showCorrectness && choice.isCorrect {
                        Label("Correct answer", systemImage: "checkmark.circle.fill")
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.correctText)
                    }
                    if showCorrectness && selected && !choice.isCorrect {
                        Label("Your answer, incorrect", systemImage: "xmark.circle.fill")
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.incorrectText)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(border, lineWidth: selected || (showCorrectness && choice.isCorrect) ? 2 : 1))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!disabled)
        .accessibilityLabel(accessibilityLabel) // l10n: content(question)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("lesson-quiz-choice-\(letter)-button")
    }

    private var statusText: String? {
        guard showCorrectness else { return nil }
        if choice.isCorrect { return "Correct answer" }
        if selected { return "Your answer, incorrect" }
        return nil
    }

    private var accessibilityLabel: Text {
        var value = AttributedString(String(localized: "Answer \(letter), "))
        let choiceText = choice.text.textAndLanguage(for: language)
        value += localized(choiceText.text, language: choiceText.language)
        if let statusText {
            value += AttributedString(String(localized: ", \(localizedStatusText(statusText))"))
        }
        return Text(value) // l10n: content(question)
    }

    private func localizedStatusText(_ statusText: String) -> String {
        switch statusText {
        case "Correct answer": String(localized: "Correct answer")
        case "Your answer, incorrect": String(localized: "Your answer, incorrect")
        default: statusText
        }
    }

    private var background: Color {
        if showCorrectness && choice.isCorrect { return DesignTokens.Colors.correctBg }
        if showCorrectness && selected && !choice.isCorrect { return DesignTokens.Colors.incorrectBg }
        return selected ? DesignTokens.Colors.paperInset : DesignTokens.Colors.paperElevated
    }

    private var border: Color {
        if showCorrectness && choice.isCorrect { return DesignTokens.Colors.correctBorder }
        if showCorrectness && selected && !choice.isCorrect { return DesignTokens.Colors.incorrectBorder }
        return DesignTokens.Colors.border
    }
}

struct ExplanationPanelView: View {
    let questionId: String
    let selectedSourceIndex: Int?
    let language: BankLanguage
    let choicePermutation: [Int]?

    @Environment(\.canadianHamContentLibrary) private var library

    var body: some View {
        if let explanation = library?.explanationsByQuestionId[questionId] {
            let parsed = try? ExplanationBodyParser.parse(explanation, language: language.rawValue)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Explanation")
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("explanation-panel")
                EnglishOnlyExplanationNotice()
                if let parsed {
                    Text(localized(parsed.correctAnswerParagraph, language: .english)) // l10n: content(en)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .textSelection(.enabled)
                    if !parsed.distractorNotes.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            ForEach(parsed.distractorNotes, id: \.sourceIndex) { note in
                                Text(distractorNoteText(note)) // l10n: localized
                                    .font(DesignTokens.FontScale.caption)
                                    .foregroundStyle(DesignTokens.Colors.ink)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                } else {
                    let explanationBody = explanation.body.textAndLanguage(for: .english)
                    Text(localized(explanationBody.text, language: explanationBody.language)) // l10n: content(en)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .textSelection(.enabled)
                }
                if !explanation.citations.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Citations:")
                            .font(DesignTokens.FontScale.caption.weight(.semibold))
                        ForEach(Array(explanation.citations.enumerated()), id: \.offset) { _, citation in
                            citationView(citation)
                        }
                    }
                    .foregroundStyle(DesignTokens.Colors.ink)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        } else {
            Text("No Canadian Ham explanation is bundled for this question yet.")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
    }

    private func distractorNoteText(_ note: ParsedDistractorNote) -> AttributedString {
        var text = AttributedString(String.localizedStringWithFormat(String(localized: "%@: "), label(for: note.sourceIndex)))
        text += english(note.note)
        return text
    }

    private func label(for sourceIndex: Int) -> String {
        if let index = choicePermutation?.firstIndex(of: sourceIndex) {
            let letter = ["A", "B", "C", "D"][safe: index] ?? "\(index + 1)"
            return String(localized: "Displayed choice \(letter)")
        }
        return String(localized: "Source choice \(sourceIndex + 1)")
    }

    @ViewBuilder
    private func citationView(_ citation: ExplanationCitation) -> some View {
        if citation.type == "lesson", let id = citation.id {
            NavigationLink(value: RootNavigationRoute.learn(.lesson(id))) {
                Text(id) // l10n: verbatim
                    .font(DesignTokens.FontScale.caption)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open lesson \(id)")
        } else if citation.url == rbr4CitationURL, let url = URL(string: rbr4CitationURL) {
            Link(citation.id ?? "RBR-4", destination: url)
                .font(DesignTokens.FontScale.caption)
                .frame(minHeight: 44, alignment: .leading)
        } else {
            Text(citation.id ?? citation.type) // l10n: verbatim
                .font(DesignTokens.FontScale.caption)
        }
    }
}

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}

private func english(_ string: String) -> AttributedString {
    localized(string, language: .english)
}

private func english(_ attributed: AttributedString) -> AttributedString {
    var copy = attributed
    let ranges = copy.runs.map(\.range)
    for range in ranges {
        copy[range].languageIdentifier = BankLanguage.english.accessibilityLanguageCode
    }
    return copy
}

private func localizedLessonReadProgress(readCount: Int, totalCount: Int) -> String {
    let read = String.localizedStringWithFormat(String(localized: "%lld lesson marked read"), readCount)
    let total = String.localizedStringWithFormat(String(localized: "%lld lesson"), totalCount)
    return String(localized: "\(read) out of \(total)")
}

private func markedReadText(_ count: Int) -> String {
    String.localizedStringWithFormat(String(localized: "Marked read %lld times."), count)
}

// Quiz selections store source indices, never shuffled display positions.
func conceptCheckAnswerStatus(check: ConceptCheck, selectedSourceIndex: Int?, language: BankLanguage) -> AttributedString? {
    guard let selectedSourceIndex, let choice = check.choices[safe: selectedSourceIndex] else { return nil }
    var status = AttributedString(choice.isCorrect ? String(localized: "Correct.") : String(localized: "Incorrect."))
    status.inlinePresentationIntent = .stronglyEmphasized
    if let feedback = choice.feedback?.textAndLanguage(for: language) {
        status += AttributedString(" ")
        status += localized(feedback.text, language: feedback.language)
    }
    return status
}

struct LocalizedNullableResolvedText {
    let text: String
    let language: BankLanguage
}

extension LocalizedNullableText {
    func textAndLanguage(for language: BankLanguage) -> LocalizedNullableResolvedText {
        switch language {
        case .english:
            LocalizedNullableResolvedText(text: en, language: .english)
        case .french:
            if let fr {
                LocalizedNullableResolvedText(text: fr, language: .french)
            } else {
                LocalizedNullableResolvedText(text: en, language: .english)
            }
        }
    }
}
