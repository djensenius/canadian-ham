import Foundation
#if canImport(os)
import os

private let questionHintLogger = Logger(subsystem: "org.davidjensenius.CanadianHam", category: "QuestionHints")
#endif

public struct ContentLibrary: Sendable {
    public let manifest: BankManifest
    public let questions: [Question]
    public let subsections: [Subsection]
    public let categories: [Category]
    public let subsectionTitles: [SubsectionTitle]
    public let modules: [LessonModule]
    public let lessons: [Lesson]
    public let quizzes: [LessonQuiz]
    public let explanations: [Explanation]
    public let questionHints: [QuestionHint]

    public let questionsById: [String: Question]
    public let subsectionsById: [String: Subsection]
    public let categoriesById: [String: Category]
    public let subsectionTitlesById: [String: SubsectionTitle]
    public let modulesById: [String: LessonModule]
    public let lessonsById: [String: Lesson]
    public let quizzesById: [String: LessonQuiz]
    public let explanationsByQuestionId: [String: Explanation]
    public let questionHintsByQuestionId: [String: QuestionHint]

    public static func load(from bundle: Bundle = .main, bankId: String = canadianHamDefaultBankId, contentFolderName: String = "content") throws -> ContentLibrary {
        let candidates = [
            bundle.url(forResource: contentFolderName, withExtension: nil),
            bundle.resourceURL?.appendingPathComponent(contentFolderName, isDirectory: true),
            bundle.resourceURL,
        ].compactMap { $0 }

        for candidate in candidates where ContentLayout.isContentRoot(candidate) {
            return try load(fromDirectory: candidate, bankId: bankId)
        }
        throw ContentError("Bundle \(bundle.bundlePath) does not contain a \(contentFolderName) content directory")
    }

    public static func load(fromDirectory directoryURL: URL, bankId: String = canadianHamDefaultBankId) throws -> ContentLibrary {
        let layout = try ContentLayout(directoryURL: directoryURL, bankId: bankId)
        let manifest = try decode(BankManifest.self, at: layout.manifestURL)
        let questions = try decode([Question].self, at: layout.questionsURL)
        let subsections = try decode([Subsection].self, at: layout.subsectionsURL)
        let categories = try decode([Category].self, at: layout.categoriesURL)
        let subsectionTitles = try decode([SubsectionTitle].self, at: layout.subsectionTitlesURL)
        let modulesAndLessons = try loadLessons(from: layout.lessonsRoot, contentRoot: layout.contentRoot)
        let quizzes = try loadJSONFiles(LessonQuiz.self, root: layout.quizzesRoot, fileExtension: "json")
        let explanations = try loadJSONFiles(Explanation.self, root: layout.explanationsRoot, fileExtension: "json")
            .sorted { ordinalLess($0.questionId, $1.questionId) }
        let questionHints = loadQuestionHintsIfValid(layout: layout, bankId: bankId)

        let libraryWithoutHints = try makeLibrary(
            manifest: manifest,
            questions: questions,
            subsections: subsections,
            categories: categories,
            subsectionTitles: subsectionTitles,
            modulesAndLessons: modulesAndLessons,
            quizzes: quizzes,
            explanations: explanations,
            questionHints: []
        )
        try libraryWithoutHints.validate()

        guard !questionHints.isEmpty else { return libraryWithoutHints }
        do {
            let library = try makeLibrary(
                manifest: manifest,
                questions: questions,
                subsections: subsections,
                categories: categories,
                subsectionTitles: subsectionTitles,
                modulesAndLessons: modulesAndLessons,
                quizzes: quizzes,
                explanations: explanations,
                questionHints: questionHints
            )
            try library.validateQuestionHints()
            return library
        } catch {
            #if canImport(os)
            questionHintLogger.warning("Question hints failed validation; continuing without hints: \(String(describing: error), privacy: .public)")
            #endif
            return libraryWithoutHints
        }
    }

    private static func makeLibrary(
        manifest: BankManifest,
        questions: [Question],
        subsections: [Subsection],
        categories: [Category],
        subsectionTitles: [SubsectionTitle],
        modulesAndLessons: (modules: [LessonModule], lessons: [Lesson]),
        quizzes: [LessonQuiz],
        explanations: [Explanation],
        questionHints: [QuestionHint]
    ) throws -> ContentLibrary {
        try ContentLibrary(
            manifest: manifest,
            questions: questions.sorted { ordinalLess($0.id, $1.id) },
            subsections: subsections.sorted { ordinalLess($0.id, $1.id) },
            categories: categories.sorted { ordinalLess($0.id, $1.id) },
            subsectionTitles: subsectionTitles.sorted { ordinalLess($0.id, $1.id) },
            modules: modulesAndLessons.modules.sorted { $0.order == $1.order ? ordinalLess($0.id, $1.id) : $0.order < $1.order },
            lessons: modulesAndLessons.lessons.sorted { ordinalLess($0.id, $1.id) },
            quizzes: quizzes.sorted { ordinalLess($0.id, $1.id) },
            explanations: explanations,
            questionHints: questionHints
        )
    }

    private static func loadQuestionHintsIfValid(layout: ContentLayout, bankId: String) -> [QuestionHint] {
        guard directoryExists(layout.hintsRoot) else { return [] }
        do {
            return try loadJSONFiles(QuestionHint.self, root: layout.hintsRoot, fileExtension: "json")
                .filter { $0.bankId == bankId }
                .sorted { ordinalLess($0.questionId, $1.questionId) }
        } catch {
            #if canImport(os)
            questionHintLogger.warning("Question hint files could not be decoded; continuing without hints: \(String(describing: error), privacy: .public)")
            #endif
            return []
        }
    }

    public init(
        manifest: BankManifest,
        questions: [Question],
        subsections: [Subsection],
        categories: [Category],
        subsectionTitles: [SubsectionTitle],
        modules: [LessonModule],
        lessons: [Lesson],
        quizzes: [LessonQuiz],
        explanations: [Explanation],
        questionHints: [QuestionHint] = []
    ) throws {
        self.manifest = manifest
        self.questions = questions
        self.subsections = subsections
        self.categories = categories
        self.subsectionTitles = subsectionTitles
        self.modules = modules
        self.lessons = lessons
        self.quizzes = quizzes
        self.explanations = explanations
        self.questionHints = questionHints

        self.questionsById = try uniqueDictionary(questions, key: \.id, label: "question id")
        self.subsectionsById = try uniqueDictionary(subsections, key: \.id, label: "subsection id")
        self.categoriesById = try uniqueDictionary(categories, key: \.id, label: "category id")
        self.subsectionTitlesById = try uniqueDictionary(subsectionTitles, key: \.id, label: "subsection title id")
        self.modulesById = try uniqueDictionary(modules, key: \.id, label: "module id")
        self.lessonsById = try uniqueDictionary(lessons, key: \.id, label: "lesson id")
        self.quizzesById = try uniqueDictionary(quizzes, key: \.id, label: "quiz id")
        self.explanationsByQuestionId = try uniqueDictionary(explanations, key: \.questionId, label: "explanation question id")
        self.questionHintsByQuestionId = try uniqueDictionary(questionHints, key: \.questionId, label: "hint question id")
    }

    public func questions(inSubsection subsectionId: String) -> [Question] {
        questions.filter { $0.subsectionId == subsectionId }
    }

    public func questions(inCategory categoryId: String) -> [Question] {
        questions.filter { $0.categoryId == categoryId }
    }

    public func orderedLessons() -> [Lesson] {
        modules.flatMap { module in
            module.lessonIds.compactMap { lessonsById[$0] }
        }
    }

    private func validate() throws {
        try validateManifestCounts()
        try validateQuestionBankReferences()
        try validateSubsectionTitles()
        try validateLessonsAndModules()
        try validateQuizzes()
        try validateExplanations()
        try validateQuestionHints()
    }

    private func validateManifestCounts() throws {
        guard manifest.bankId == canadianHamDefaultBankId else {
            throw ContentError("manifest bankId \(manifest.bankId) does not match expected \(canadianHamDefaultBankId)")
        }
        guard manifest.counts.questions == questions.count else {
            throw ContentError("manifest counts.questions is \(manifest.counts.questions), but loaded \(questions.count) questions")
        }
        guard manifest.counts.categories == categories.count else {
            throw ContentError("manifest counts.categories is \(manifest.counts.categories), but loaded \(categories.count) categories")
        }
        guard manifest.counts.subsections == subsections.count else {
            throw ContentError("manifest counts.subsections is \(manifest.counts.subsections), but loaded \(subsections.count) subsections")
        }
    }

    private func validateQuestionBankReferences() throws {
        for category in categories {
            guard category.bankId == manifest.bankId else {
                throw ContentError("category \(category.id) bankId \(category.bankId) does not match manifest \(manifest.bankId)")
            }
        }

        for subsection in subsections {
            guard subsection.bankId == manifest.bankId else {
                throw ContentError("subsection \(subsection.id) bankId \(subsection.bankId) does not match manifest \(manifest.bankId)")
            }
            guard categoriesById[subsection.categoryId] != nil else {
                throw ContentError("subsection \(subsection.id) references unknown categoryId \(subsection.categoryId)")
            }
            guard subsection.questionCount == subsection.questionIds.count else {
                throw ContentError("subsection \(subsection.id) questionCount \(subsection.questionCount) does not match \(subsection.questionIds.count) questionIds")
            }
            for questionId in subsection.questionIds {
                guard let question = questionsById[questionId] else {
                    throw ContentError("subsection \(subsection.id) references unknown questionId \(questionId)")
                }
                guard question.subsectionId == subsection.id else {
                    throw ContentError("subsection \(subsection.id) contains question \(questionId), but question subsectionId is \(question.subsectionId)")
                }
            }
        }

        for question in questions {
            guard question.bankId == manifest.bankId else {
                throw ContentError("question \(question.id) bankId \(question.bankId) does not match manifest \(manifest.bankId)")
            }
            guard categoriesById[question.categoryId] != nil else {
                throw ContentError("question \(question.id) references unknown categoryId \(question.categoryId)")
            }
            guard subsectionsById[question.subsectionId] != nil else {
                throw ContentError("question \(question.id) references unknown subsectionId \(question.subsectionId)")
            }
            guard question.answers.count == 4 else {
                throw ContentError("question \(question.id) has \(question.answers.count) answers; expected 4")
            }
            let correctAnswers = question.answers.filter(\.isCorrect)
            guard correctAnswers.count == 1, correctAnswers.first?.sourceIndex == 0 else {
                throw ContentError("question \(question.id) must have exactly one correct answer at sourceIndex 0")
            }
        }
    }

    private func validateSubsectionTitles() throws {
        for title in subsectionTitles {
            guard subsectionsById[title.id] != nil else {
                throw ContentError("subsection title \(title.id) does not match a generated subsection")
            }
        }
    }

    private func validateLessonsAndModules() throws {
        let orders = modules.map(\.order)
        guard modules.count == 8, Set(orders) == Set(1...8) else {
            throw ContentError("module order values must be unique 1 through 8")
        }
        for module in modules {
            guard categoriesById[module.categoryId] != nil else {
                throw ContentError("module \(module.id) references unknown categoryId \(module.categoryId)")
            }
            for lessonId in module.lessonIds {
                guard let lesson = lessonsById[lessonId] else {
                    throw ContentError("module \(module.id) references unknown lessonId \(lessonId)")
                }
                guard lesson.moduleId == module.id else {
                    throw ContentError("module \(module.id) lists lesson \(lesson.id), but lesson moduleId is \(lesson.moduleId)")
                }
            }
        }
        for lesson in lessons {
            guard modulesById[lesson.moduleId] != nil else {
                throw ContentError("lesson \(lesson.id) references unknown moduleId \(lesson.moduleId)")
            }
            for categoryId in lesson.categoryIds {
                guard categoriesById[categoryId] != nil else {
                    throw ContentError("lesson \(lesson.id) references unknown categoryId \(categoryId)")
                }
            }
            for prerequisiteId in lesson.prerequisites {
                guard lessonsById[prerequisiteId] != nil else {
                    throw ContentError("lesson \(lesson.id) prerequisites references unknown lesson \(prerequisiteId)")
                }
            }
            for subsectionId in lesson.covers {
                guard subsectionsById[subsectionId] != nil else {
                    throw ContentError("lesson \(lesson.id) covers unknown subsectionId \(subsectionId)")
                }
                guard lesson.categoryIds.contains(where: { subsectionId.hasPrefix("\($0)-") }) else {
                    throw ContentError("lesson \(lesson.id) covers \(subsectionId) does not match categoryIds \(lesson.categoryIds.joined(separator: ", "))")
                }
            }
        }

        let coveredSubsectionIds = Set(lessons.flatMap(\.covers))
        let missingSubsectionIds = subsections.map(\.id).filter { !coveredSubsectionIds.contains($0) }
        guard missingSubsectionIds.isEmpty else {
            throw ContentError("missing lesson coverage for subsectionIds \(missingSubsectionIds.joined(separator: ", "))")
        }
    }

    private func validateQuizzes() throws {
        for quiz in quizzes {
            guard let lesson = lessonsById[quiz.lessonId] else {
                throw ContentError("quiz \(quiz.id) references unknown lessonId \(quiz.lessonId)")
            }
            guard lesson.quizIds.contains(quiz.id) else {
                throw ContentError("quiz \(quiz.id) is not listed by lesson \(lesson.id)")
            }
            for questionId in quiz.officialQuestionIds {
                guard questionsById[questionId] != nil else {
                    throw ContentError("quiz \(quiz.id) references unknown official questionId \(questionId)")
                }
            }
            for conceptCheck in quiz.conceptChecks {
                let correctCount = conceptCheck.choices.filter(\.isCorrect).count
                guard correctCount == 1 else {
                    throw ContentError("quiz \(quiz.id) conceptCheck \(conceptCheck.id) must have exactly one correct choice")
                }
            }
        }
        for lesson in lessons {
            for quizId in lesson.quizIds {
                guard quizzesById[quizId] != nil else {
                    throw ContentError("lesson \(lesson.id) references missing quizId \(quizId)")
                }
            }
        }
    }

    private func validateExplanations() throws {
        var explainedQuestionIds: Set<String> = []
        for explanation in explanations {
            guard explanation.id == "EXP-\(explanation.questionId)" else {
                throw ContentError("explanation \(explanation.id) id must be EXP-\(explanation.questionId)")
            }
            guard explanation.bankId == manifest.bankId else {
                throw ContentError("explanation \(explanation.id) bankId \(explanation.bankId) does not match manifest \(manifest.bankId)")
            }
            guard let question = questionsById[explanation.questionId] else {
                throw ContentError("explanation \(explanation.id) references unknown questionId \(explanation.questionId)")
            }
            explainedQuestionIds.insert(explanation.questionId)
            let parsed = try ExplanationBodyParser.parse(explanation)
            let expectedSourceIndexes = Set(question.answers.filter { !$0.isCorrect }.map(\.sourceIndex))
            let parsedSourceIndexes = Set(parsed.distractorNotes.map(\.sourceIndex))
            guard parsedSourceIndexes == expectedSourceIndexes else {
                throw ContentError("explanation \(explanation.id) distractor notes have sourceIndexes \(parsedSourceIndexes.sorted()), expected \(expectedSourceIndexes.sorted())")
            }
        }
        let missingExplanationIds = questions.map(\.id).filter { !explainedQuestionIds.contains($0) }
        guard missingExplanationIds.isEmpty else {
            throw ContentError("missing explanations for questionIds \(missingExplanationIds.joined(separator: ", "))")
        }
    }

    private func validateQuestionHints() throws {
        for hint in questionHints {
            guard hint.id == "HINT-\(hint.questionId)" else {
                throw ContentError("hint \(hint.id) id must be HINT-\(hint.questionId)")
            }
            guard hint.bankId == manifest.bankId else {
                throw ContentError("hint \(hint.id) bankId \(hint.bankId) does not match manifest \(manifest.bankId)")
            }
            guard questionsById[hint.questionId] != nil else {
                throw ContentError("hint \(hint.id) references unknown questionId \(hint.questionId)")
            }
            guard (1...2).contains(hint.hints.count) else {
                throw ContentError("hint \(hint.id) must contain one or two levels")
            }
            guard hint.hints.map(\.level) == Array(1...hint.hints.count) else {
                throw ContentError("hint \(hint.id) levels must start at 1 and be contiguous")
            }
            guard lessonsById[hint.lessonLink.lessonId] != nil else {
                throw ContentError("hint \(hint.id) references unknown lessonId \(hint.lessonLink.lessonId)")
            }
            if hint.hints.count == 1, hint.singleLevelReason == nil {
                throw ContentError("hint \(hint.id) with one level must include singleLevelReason")
            }
        }
    }
}

private struct ContentLayout {
    let contentRoot: URL
    let bankId: String

    var bankRoot: URL { contentRoot.appendingPathComponent("generated", isDirectory: true).appendingPathComponent(bankId, isDirectory: true) }
    var manifestURL: URL { bankRoot.appendingPathComponent("manifest.json") }
    var questionsURL: URL { bankRoot.appendingPathComponent("questions.json") }
    var subsectionsURL: URL { bankRoot.appendingPathComponent("subsections.json") }
    var categoriesURL: URL { bankRoot.appendingPathComponent("categories.json") }
    var subsectionTitlesURL: URL { contentRoot.appendingPathComponent("subsection-titles.json") }
    var lessonsRoot: URL { contentRoot.appendingPathComponent("lessons", isDirectory: true) }
    var quizzesRoot: URL { contentRoot.appendingPathComponent("quizzes", isDirectory: true) }
    var explanationsRoot: URL { contentRoot.appendingPathComponent("explanations", isDirectory: true) }
    var hintsRoot: URL { contentRoot.appendingPathComponent("hints", isDirectory: true) }

    init(directoryURL: URL, bankId: String) throws {
        self.bankId = bankId
        if Self.isContentRoot(directoryURL) {
            self.contentRoot = directoryURL
        } else {
            let nested = directoryURL.appendingPathComponent("content", isDirectory: true)
            guard Self.isContentRoot(nested) else {
                throw ContentError("\(directoryURL.path(percentEncoded: false)) is neither a content directory nor a repository root containing content/")
            }
            self.contentRoot = nested
        }
    }

    static func isContentRoot(_ url: URL) -> Bool {
        directoryExists(url.appendingPathComponent("generated", isDirectory: true))
            && directoryExists(url.appendingPathComponent("lessons", isDirectory: true))
            && fileExists(url.appendingPathComponent("subsection-titles.json"))
    }
}

private func loadLessons(from lessonsRoot: URL, contentRoot: URL) throws -> (modules: [LessonModule], lessons: [Lesson]) {
    let urls = try recursiveFiles(under: lessonsRoot, fileExtension: "md")
        .filter { $0.lastPathComponent != "README.md" }
    var modules: [LessonModule] = []
    var lessons: [Lesson] = []
    for url in urls {
        let raw: String
        do {
            raw = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ContentError.readFailure(url, error)
        }
        let path = relativePath(for: url, from: contentRoot)
        let type = try LessonMarkdownLoader.documentType(markdown: raw, path: path)
        switch type {
        case "module":
            modules.append(try LessonMarkdownLoader.parseModule(markdown: raw, path: path))
        case "lesson":
            lessons.append(try LessonMarkdownLoader.parseLesson(markdown: raw, path: path))
        default:
            throw ContentError("\(path): unknown lesson document type \(type)")
        }
    }
    return (modules, lessons)
}

private func loadJSONFiles<T: Decodable>(_ type: T.Type, root: URL, fileExtension: String) throws -> [T] {
    try recursiveFiles(under: root, fileExtension: fileExtension).map { url in
        try decode(T.self, at: url)
    }
}

private func decode<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        throw ContentError.readFailure(url, error)
    }
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw ContentError.decodeFailure(url, error)
    }
}

private func recursiveFiles(under root: URL, fileExtension: String) throws -> [URL] {
    guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
        throw ContentError("Unable to enumerate \(root.path(percentEncoded: false))")
    }
    var urls: [URL] = []
    for case let url as URL in enumerator {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey])
        if values.isRegularFile == true, url.pathExtension == fileExtension {
            urls.append(url)
        }
    }
    return urls.sorted { ordinalLess($0.path(percentEncoded: false), $1.path(percentEncoded: false)) }
}

private func directoryExists(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) && isDirectory.boolValue
}

private func fileExists(_ url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) && !isDirectory.boolValue
}

private func uniqueDictionary<T>(_ values: [T], key: KeyPath<T, String>, label: String) throws -> [String: T] {
    var result: [String: T] = [:]
    for value in values {
        let id = value[keyPath: key]
        if result[id] != nil {
            throw ContentError("duplicate \(label) \(id)")
        }
        result[id] = value
    }
    return result
}

private func relativePath(for url: URL, from baseURL: URL) -> String {
    let path = url.path(percentEncoded: false)
    let base = baseURL.path(percentEncoded: false)
    if path.hasPrefix(base + "/") {
        return String(path.dropFirst(base.count + 1))
    }
    return path
}

private func ordinalLess(_ lhs: String, _ rhs: String) -> Bool {
    var left = lhs.utf8.makeIterator()
    var right = rhs.utf8.makeIterator()
    while true {
        let a = left.next()
        let b = right.next()
        switch (a, b) {
        case let (x?, y?):
            if x < y { return true }
            if x > y { return false }
        case (nil, nil):
            return false
        case (nil, _?):
            return true
        case (_?, nil):
            return false
        }
    }
}
