import CanadianHamContent
import CanadianHamEngine
import PDFKit
import SwiftUI

private let rbr4CitationURL = "https://ised-isde.canada.ca/site/spectrum-management-telecommunications/en/licences-and-certificates/regulations-reference-rbr/rbr-4-standards-operation-radio-stations-amateur-radio-service"

private struct ContentLibraryEnvironmentKey: EnvironmentKey {
    static let defaultValue: ContentLibrary? = nil
}

extension EnvironmentValues {
    var canadianHamContentLibrary: ContentLibrary? {
        get { self[ContentLibraryEnvironmentKey.self] }
        set { self[ContentLibraryEnvironmentKey.self] = newValue }
    }
}

enum ReferenceSheetKind: String, Identifiable, Sendable {
    case study
    case exam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: "Study reference sheet"
        case .exam: "Exam reference sheet"
        }
    }

    var fileName: String {
        switch self {
        case .study: "Reference Material for Amateur Radio Training Basic EN 2025"
        case .exam: "Reference Material for Amateur Radio Exam Basic EN 2025"
        }
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
    @State private var referenceSheet: ReferenceSheetKind?
    @State private var path: [LearnRoute]

    init(library: ContentLibrary, bank: QuestionBank, progressStore: ProgressStoreService, language: BankLanguage, revision: Int, onDataChanged: @escaping () -> Void) {
        self.library = library
        self.bank = bank
        self.progressStore = progressStore
        self.language = language
        self.revision = revision
        self.onDataChanged = onDataChanged
        let initialLesson = AppLaunchArguments.value(after: "-CanadianHamInitialLessonID")
        _path = State(initialValue: initialLesson.map { [.lesson($0)] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
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
                        Text("Study the eight modules in order. Lessons are currently authored in English, matching the web app; official practice questions still use the language picker.")
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        HStack {
                            ReferenceSheetButton(kind: .study, selectedSheet: $referenceSheet)
                            ReferenceSheetButton(kind: .exam, selectedSheet: $referenceSheet)
                        }
                    }
                    .paperCard()

                    if let errorMessage {
                        MessagePanel(title: "Learn progress unavailable", message: errorMessage, kind: .warning)
                    }

                    if showSimpleLearnForUITests {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            ForEach(library.modules, id: \.id) { module in
                                VStack(alignment: .leading) {
                                    Text("Module \(module.order) · \(module.categoryId)")
                                        .font(.body)
                                    Text(module.title.en)
                                        .font(.headline)
                                    Text("\((module.lessonIds.compactMap { library.lessonsById[$0] }).count) lessons")
                                        .font(.body)
                                }
                            }
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: DesignTokens.Spacing.md)], spacing: DesignTokens.Spacing.md) {
                            ForEach(library.modules, id: \.id) { module in
                                moduleCard(module)
                            }
                        }
                    }
                }
                .pagePadding()
            }
            .background(DesignTokens.Colors.paper)
            .navigationTitle("Learn")
            .navigationDestination(for: LearnRoute.self) { route in
                switch route {
                case .module(let id):
                    if let module = library.modulesById[id] {
                        ModuleLessonListView(module: module, library: library, lessonProgress: lessonProgress)
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
                            onDataChanged: {
                                refreshProgress()
                                onDataChanged()
                            }
                        )
                    } else {
                        ContentUnavailableView("Lesson not found", systemImage: "book.closed")
                    }
                }
            }
        }
        .sheet(item: $referenceSheet) { sheet in
            ReferenceSheetViewer(kind: sheet)
        }
        .task(id: revision) { refreshProgress() }
    }

    private var showSimpleLearnForUITests: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-CanadianHamUITestSimpleLearnList")
#else
        false
#endif
    }

    private func moduleCard(_ module: LessonModule) -> some View {
        let lessons = module.lessonIds.compactMap { library.lessonsById[$0] }
        let read = Set(lessonProgress.map(\.lessonId))
        let readCount = lessons.filter { read.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Module \(module.order) · \(module.categoryId)")
                .font(DesignTokens.FontScale.caption.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(module.title.en)
                .font(DesignTokens.FontScale.title.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text(module.status == .outline ? "Outline available" : "Draft lessons available")
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(readCount) of \(lessons.count) lessons marked read")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            HStack {
                NavigationLink(value: LearnRoute.module(module.id)) {
                    Text("Open module")
                        .font(DesignTokens.FontScale.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(DesignTokens.Colors.ink)
                if let first = lessons.first {
                    NavigationLink(value: LearnRoute.lesson(first.id)) {
                        Text("Start module")
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(DesignTokens.Colors.ink)
                }
            }
        }
        .paperCard()
    }

    private func refreshProgress() {
        do {
            lessonProgress = try progressStore.lessonProgressRecords()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum LearnRoute: Hashable {
    case module(String)
    case lesson(String)
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
                    Text(module.title.en)
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    LessonMarkdownView(markdown: module.bodyMarkdown, title: module.title.en)
                }
                .paperCard()

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Lessons")
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(module.lessonIds.compactMap { library.lessonsById[$0] }, id: \.id) { lesson in
                        NavigationLink(value: LearnRoute.lesson(lesson.id)) {
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
        .navigationTitle(module.title.en)
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isRead: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("\(lesson.id) · \(lesson.estimatedMinutes) min · \(lesson.covers.joined(separator: ", "))")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(lesson.title.en)
                .font(DesignTokens.FontScale.body.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            Text("\(lesson.status == .outline ? "Coming soon" : "Ready to read") · \(isRead ? "Marked read" : "Not marked read")")
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
    let onDataChanged: () -> Void

    @State private var lessonProgress: LessonProgressRecord?
    @State private var quizAttempts: [LessonQuizAttempt] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("\(lesson.id) · \(lesson.estimatedMinutes) min · \(lesson.covers.joined(separator: ", "))")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text(lesson.title.en)
                        .font(DesignTokens.FontScale.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("lesson-reader-title")
                    if let lessonProgress {
                        Text("Marked read \(lessonProgress.readCount) time\(lessonProgress.readCount == 1 ? "" : "s").")
                            .font(DesignTokens.FontScale.caption)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                    } else {
                        Text("Not marked read yet.")
                            .font(DesignTokens.FontScale.caption)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                    }
                }
                .paperCard()

                if let errorMessage {
                    MessagePanel(title: "Lesson progress unavailable", message: errorMessage, kind: .warning)
                }

                if showQuizFirstForUITests {
                    quizzes
                }

                if lesson.status == .outline {
                    OutlineLessonView(lesson: lesson, library: library)
                } else {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        LessonMarkdownView(markdown: lesson.bodyMarkdown, title: lesson.title.en)
                    }
                    .paperCard()
                }

                HStack {
                    Button("Mark lesson read") { markRead() }
                        .buttonStyle(.bordered)
                        .tint(DesignTokens.Colors.ink)
                    if let previous = neighbor(offset: -1) {
                        NavigationLink("Previous: \(previous.title.en)", value: LearnRoute.lesson(previous.id))
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.ink)
                    }
                    if let next = neighbor(offset: 1) {
                        NavigationLink("Next: \(next.title.en)", value: LearnRoute.lesson(next.id))
                            .buttonStyle(.bordered)
                            .tint(DesignTokens.Colors.ink)
                    }
                }

                if !showQuizFirstForUITests {
                    quizzes
                }
            }
            .pagePadding()
        }
        .background(DesignTokens.Colors.paper)
        .navigationTitle(lesson.title.en)
        .task { refresh() }
    }

    private var quizzes: some View {
        ForEach(lesson.quizIds.compactMap { library.quizzesById[$0] }, id: \.id) { quiz in
            LessonQuizView(
                quiz: quiz,
                lesson: lesson,
                bank: bank,
                library: library,
                language: language,
                progressStore: progressStore,
                attempts: quizAttempts.filter { $0.quizId == quiz.id },
                onSaved: {
                    refresh()
                    onDataChanged()
                }
            )
        }
    }

    private var showQuizFirstForUITests: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-CanadianHamUITestShowLessonQuizFirst")
#else
        false
#endif
    }

    private func refresh() {
        do {
            lessonProgress = try progressStore.lessonProgressRecords().first { $0.lessonId == lesson.id }
            quizAttempts = try progressStore.lessonQuizAttempts().filter { $0.lessonId == lesson.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }
    }

    private func neighbor(offset: Int) -> Lesson? {
        let ordered = library.orderedLessons()
        guard let index = ordered.firstIndex(where: { $0.id == lesson.id }) else { return nil }
        return ordered[safe: index + offset]
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
                Label(objective, systemImage: "circle.fill")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
            Text("Covered subsections")
                .font(DesignTokens.FontScale.body.weight(.bold))
                .foregroundStyle(DesignTokens.Colors.ink)
            ForEach(lesson.covers, id: \.self) { cover in
                Text("\(cover): \(library.subsectionTitlesById[cover]?.title.en ?? cover)")
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
            }
        }
        .paperCard()
    }
}

private struct LessonMarkdownView: View {
    let markdown: String
    let title: String?

    init(markdown: String, title: String? = nil) {
        self.markdown = markdown
        self.title = title
    }

    var body: some View {
        let rendered = (try? LessonMarkdownRenderer.render(markdown)) ?? RenderedLessonMarkdown(blocks: [.paragraph(AttributedString(markdown))])
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(Array(rendered.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: LessonBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            if !(level == 1 && title != nil && plainString(text) == title) {
                Text(text)
                    .font(level <= 2 ? DesignTokens.FontScale.title.weight(.bold) : DesignTokens.FontScale.bodyLarge.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
            }
        case .paragraph(let text):
            Text(text)
                .font(DesignTokens.FontScale.body)
                .foregroundStyle(DesignTokens.Colors.ink)
                .textSelection(.enabled)
        case .list(let ordered, let items):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        Text(ordered ? "\(index + 1)." : "•")
                            .font(DesignTokens.FontScale.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text(item)
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .textSelection(.enabled)
                    }
                }
            }
        case .code(_, let text):
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .textSelection(.enabled)
                    .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm, style: .continuous))
        case .table(let table):
            LessonTableView(table: table)
        case .illustrationBrief(let brief):
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Label("Illustration brief", systemImage: "paintbrush")
                    .font(DesignTokens.FontScale.body.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(brief.description)
                    .font(DesignTokens.FontScale.body)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text("Alt text: \(brief.altText)")
                    .font(DesignTokens.FontScale.caption)
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Illustration brief. \(brief.altText). \(brief.description)")
        case .blockquote(let text):
            Text(text)
                .font(DesignTokens.FontScale.body.italic())
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        }
    }

    private func plainString(_ value: AttributedString) -> String {
        String(value.characters)
    }
}

private struct LessonTableView: View {
    let table: MarkdownTable

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: DesignTokens.Spacing.md, verticalSpacing: DesignTokens.Spacing.sm) {
                GridRow {
                    ForEach(Array(table.headers.enumerated()), id: \.offset) { _, header in
                        Text(header)
                            .font(DesignTokens.FontScale.caption.weight(.bold))
                            .foregroundStyle(DesignTokens.Colors.ink)
                    }
                }
                Divider().gridCellColumns(max(table.headers.count, 1))
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                            Text(cell)
                                .font(DesignTokens.FontScale.caption)
                                .foregroundStyle(DesignTokens.Colors.ink)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.paperInset, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lesson table")
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
    let onSaved: () -> Void

    @State private var seed: String = AppLaunchArguments.value(after: "-CanadianHamLessonQuizSeed") ?? "lesson-quiz/\(UUID().uuidString)"
    @State private var items: [LessonQuizRuntimeItem] = []
    @State private var currentIndex = 0
    @State private var selectedByItemId: [String: Int] = [:]
    @State private var submittedAttemptID: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Lesson quiz")
                        .font(DesignTokens.FontScale.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.inkMuted)
                    Text(quiz.id)
                        .font(DesignTokens.FontScale.title.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(items.count) questions: official bank questions update Leitner progress; concept checks do not.")
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    if let latest = attempts.last {
                        Text("Latest score: \(latest.correct) / \(latest.total) (\(latest.percent, format: .number.precision(.fractionLength(0...0)))%). Attempts saved: \(attempts.count).")
                            .font(DesignTokens.FontScale.caption)
                            .foregroundStyle(DesignTokens.Colors.inkMuted)
                            .accessibilityIdentifier("lesson-quiz-latest-score")
                    }
                }
                Spacer()
                Button("Retry quiz") { restart() }
                    .buttonStyle(.bordered)
                    .tint(DesignTokens.Colors.ink)
            }

            if let errorMessage {
                MessagePanel(title: "Lesson quiz unavailable", message: errorMessage, kind: .warning)
            }

            if let item = items[safe: currentIndex] {
                Text("Question \(currentIndex + 1) of \(items.count)")
                    .font(DesignTokens.FontScale.body.weight(.semibold))
                    .foregroundStyle(DesignTokens.Colors.ink)
                LessonQuizQuestionView(
                    item: item,
                    bank: bank,
                    library: library,
                    language: language,
                    selectedSourceOrChoiceIndex: selectedByItemId[item.id],
                    disabled: selectedByItemId[item.id] != nil || submittedAttemptID != nil
                ) { selected in
                    selectedByItemId[item.id] = selected
                }
                HStack {
                    Button("Previous") { currentIndex = max(0, currentIndex - 1) }
                        .buttonStyle(.bordered)
                        .disabled(currentIndex == 0)
                    Button("Next") { currentIndex = min(items.count - 1, currentIndex + 1) }
                        .buttonStyle(.bordered)
                        .disabled(currentIndex + 1 >= items.count)
                    Button("Submit lesson quiz") { submit() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!allAnswered || submittedAttemptID != nil)
                        .accessibilityIdentifier("submit-lesson-quiz-button")
                }
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
        .task { if items.isEmpty { restart(keepSeed: true) } }
    }

    private var allAnswered: Bool {
        !items.isEmpty && items.allSatisfy { selectedByItemId[$0.id] != nil }
    }

    private func restart(keepSeed: Bool = false) {
        if !keepSeed {
            seed = "lesson-quiz/\(quiz.id)/\(attempts.count + 1)/\(UUID().uuidString)"
        }
        do {
            items = try buildLessonQuizItems(quiz: quiz, seed: seed)
            currentIndex = 0
            selectedByItemId = [:]
            submittedAttemptID = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
    }

    private func buildLessonQuizItems(quiz: LessonQuiz, seed: String) throws -> [LessonQuizRuntimeItem] {
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
        let shuffled = try CanadianHamEngine.shuffled(official + concepts, rng: &rng)
#if DEBUG
        if let value = AppLaunchArguments.value(after: "-CanadianHamLessonQuizLimit"), let limit = Int(value), limit > 0 {
            return Array(shuffled.prefix(limit))
        }
#endif
        return shuffled
    }

    private func submit() {
        do {
            let submittedAt = try AppleStudyEngine.canonicalNow()
            var correct = 0
            var officialQuestionIds: [String] = []
            var incorrectOfficialQuestionIds: [String] = []
            var incorrectConceptCheckIds: [String] = []
            var progress = try progressStore.questionProgressRecords()

            for item in items {
                guard let selected = selectedByItemId[item.id] else { continue }
                switch item {
                case .official(_, let questionId, _):
                    officialQuestionIds.append(questionId)
                    if selected == 0 {
                        correct += 1
                    } else {
                        incorrectOfficialQuestionIds.append(questionId)
                    }
                    if let question = bank.question(id: questionId) {
                        progress = try AppleStudyEngine.applyPracticeAnswer(progress: progress, question: question, selectedSourceIndex: selected, now: submittedAt)
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
                incorrectConceptCheckIds: incorrectConceptCheckIds
            )
            try progressStore.saveLessonQuizAttempt(attempt, questionProgress: progress)
            submittedAttemptID = attempt.id
            errorMessage = nil
            onSaved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum LessonQuizRuntimeItem: Identifiable, Equatable {
    case official(id: String, questionId: String, choicePermutation: [Int])
    case concept(id: String, conceptCheck: ConceptCheck, choicePermutation: [Int])

    var id: String {
        switch self {
        case .official(let id, _, _), .concept(let id, _, _): id
        }
    }
}

private struct LessonQuizQuestionView: View {
    let item: LessonQuizRuntimeItem
    let bank: QuestionBank
    let library: ContentLibrary
    let language: BankLanguage
    let selectedSourceOrChoiceIndex: Int?
    let disabled: Bool
    let onChoose: (Int) -> Void

    var body: some View {
        switch item {
        case .official(_, let questionId, let permutation):
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
                        PracticeFeedback(question: question, selectedSourceIndex: selectedSourceOrChoiceIndex, language: language, choicePermutation: permutation)
                    }
                }
            } else {
                Text("Official question \(questionId) is loading from the bundled bank.")
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

    var body: some View {
        let prompt = check.prompt.text(for: language)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Concept check · \(check.id)")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
            Text(localized(prompt, language: language))
                .font(DesignTokens.FontScale.bodyLarge.weight(.semibold))
                .foregroundStyle(DesignTokens.Colors.ink)
            ForEach(Array(permutation.enumerated()), id: \.offset) { displayIndex, choiceIndex in
                if let choice = check.choices[safe: choiceIndex] {
                    ConceptChoiceButton(choice: choice, displayIndex: displayIndex, sourceIndex: choiceIndex, language: language, selectedChoiceIndex: selectedChoiceIndex, showCorrectness: selectedChoiceIndex != nil, disabled: disabled) {
                        onChoose(choiceIndex)
                    }
                }
            }
            if let selectedChoiceIndex {
                let isCorrect = check.choices[safe: selectedChoiceIndex]?.isCorrect == true
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(isCorrect ? "Correct" : "Incorrect")
                        .font(DesignTokens.FontScale.body.weight(.bold))
                        .foregroundStyle(isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                    Text(localized(check.explanation.text(for: language), language: language))
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(isCorrect ? DesignTokens.Colors.correctText : DesignTokens.Colors.incorrectText)
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isCorrect ? DesignTokens.Colors.correctBg : DesignTokens.Colors.incorrectBg, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(isCorrect ? DesignTokens.Colors.correctBorder : DesignTokens.Colors.incorrectBorder, lineWidth: 2))
                .accessibilityIdentifier("lesson-quiz-feedback")
            }
        }
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
                Text(letter)
                    .font(DesignTokens.FontScale.body.monospaced().weight(.bold))
                    .frame(minWidth: 34, minHeight: 34)
                    .padding(DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.ink, in: Circle())
                    .foregroundStyle(DesignTokens.Colors.paperElevated)
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(localized(choice.text.text(for: language), language: language))
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    if showCorrectness && choice.isCorrect { Label("Correct answer", systemImage: "checkmark.circle.fill") }
                    if showCorrectness && selected && !choice.isCorrect { Label("Your answer, incorrect", systemImage: "xmark.circle.fill") }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(border, lineWidth: selected || (showCorrectness && choice.isCorrect) ? 2 : 1))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!disabled)
        .accessibilityLabel("Answer \(letter), \(choice.text.text(for: language))")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("lesson-quiz-choice-\(letter)-button")
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
                if let parsed {
                    Text(parsed.correctAnswerParagraph)
                        .font(DesignTokens.FontScale.body)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .textSelection(.enabled)
                    if !parsed.distractorNotes.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            ForEach(parsed.distractorNotes, id: \.sourceIndex) { note in
                                Text("\(label(for: note.sourceIndex)): \(note.note)")
                                    .font(DesignTokens.FontScale.caption)
                                    .foregroundStyle(DesignTokens.Colors.ink)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                } else {
                    Text(explanation.body.text(for: language))
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
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.paperElevated, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous).strokeBorder(DesignTokens.Colors.border, lineWidth: 1))
            .accessibilityIdentifier("explanation-panel")
        } else {
            Text("No project explanation is bundled for this question yet.")
                .font(DesignTokens.FontScale.caption)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
        }
    }

    private func label(for sourceIndex: Int) -> String {
        if let index = choicePermutation?.firstIndex(of: sourceIndex) {
            return "Displayed choice \(["A", "B", "C", "D"][safe: index] ?? "\(index + 1)")"
        }
        return "sourceIndex \(sourceIndex)"
    }

    @ViewBuilder
    private func citationView(_ citation: ExplanationCitation) -> some View {
        if citation.type == "lesson", let id = citation.id {
            Text(id)
                .font(DesignTokens.FontScale.caption)
        } else if citation.url == rbr4CitationURL, let url = URL(string: rbr4CitationURL) {
            Link(citation.id ?? "RBR-4", destination: url)
                .font(DesignTokens.FontScale.caption)
        } else {
            Text(citation.id ?? citation.type)
                .font(DesignTokens.FontScale.caption)
        }
    }
}

struct ReferenceSheetButton: View {
    let kind: ReferenceSheetKind
    @Binding var selectedSheet: ReferenceSheetKind?

    var body: some View {
        Button { selectedSheet = kind } label: {
            Text(kind.title)
                .font(DesignTokens.FontScale.body.weight(.semibold))
        }
        .buttonStyle(.bordered)
            .tint(DesignTokens.Colors.ink)
            .accessibilityHint("Opens the bundled PDF in an offline viewer")
    }
}

struct ReferenceSheetViewer: View {
    let kind: ReferenceSheetKind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if simpleReferenceViewerForUITests {
                    Text("Bundled offline PDF viewer for \(kind.title).")
                        .font(.body)
                        .padding()
                } else if let url = ReferenceSheetLocator.url(for: kind) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Bundled offline PDF: \(kind.title)")
                            .font(DesignTokens.FontScale.body)
                            .foregroundStyle(DesignTokens.Colors.ink)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        PDFKitView(url: url)
                            .accessibilityHidden(true)
                    }
                } else {
                    ContentUnavailableView("Reference sheet unavailable", systemImage: "doc.richtext", description: Text("The bundled PDF could not be found."))
                }
            }
            .navigationTitle(kind.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("reference-viewer-done-button")
                }
            }
        }
    }

    private var simpleReferenceViewerForUITests: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-CanadianHamUITestSimpleReferenceViewer")
#else
        false
#endif
    }
}

enum ReferenceSheetLocator {
    static func url(for kind: ReferenceSheetKind, bundle: Bundle = .main) -> URL? {
        let file = kind.fileName
        let candidates = [
            bundle.url(forResource: file, withExtension: "pdf"),
            bundle.resourceURL?.appendingPathComponent("reference", isDirectory: true).appendingPathComponent("\(file).pdf"),
            bundle.resourceURL?.appendingPathComponent("content/sources/ised/basic-2025-07-15/reference", isDirectory: true).appendingPathComponent("\(file).pdf")
        ].compactMap { $0 }
        return candidates.first { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
    }
}

#if os(iOS)
private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
#elseif os(macOS)
private struct PDFKitView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document?.documentURL != url {
            nsView.document = PDFDocument(url: url)
        }
    }
}
#endif

private func localized(_ string: String, language: BankLanguage) -> AttributedString {
    var attributed = AttributedString(string)
    attributed.languageIdentifier = language.accessibilityLanguageCode
    return attributed
}

private extension LocalizedNullableText {
    func text(for language: BankLanguage) -> String {
        switch language {
        case .english:
            en
        case .french:
            fr ?? en
        }
    }
}
