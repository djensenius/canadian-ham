import CanadianHamEngine
import Foundation
import SwiftData

struct ApplePreferences: Codable, Equatable, Sendable {
    enum PracticeMode: String, Codable, CaseIterable, Identifiable, Sendable {
        case immediate
        case reviewLater = "review-later"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .immediate: "Immediate feedback"
            case .reviewLater: "Review later"
            }
        }
    }

    enum Theme: String, Codable, CaseIterable, Identifiable, Sendable {
        case system
        case light
        case dark

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var practiceMode: PracticeMode
    var examTimerEnabled: Bool
    var language: BankLanguage
    var theme: Theme

    static let `default` = ApplePreferences(
        practiceMode: .immediate,
        examTimerEnabled: false,
        language: .english,
        theme: .system
    )
}

extension BankLanguage: Codable {}

struct ProgressExportV1: Codable, Equatable, Sendable {
    let schema: String
    let version: Int
    let exportedAt: String
    let bankId: String
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let lessonProgress: [ArchivedJSON]
    let lessonQuizAttempts: [ArchivedJSON]
    let preferences: ExportedPreferences
}

struct ExportedPreferences: Codable, Equatable, Sendable {
    let practiceMode: String
    let examTimerEnabled: Bool
    let theme: String
}

struct ArchivedJSON: Codable, Equatable, Sendable {
    let storage: [String: JSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        storage = try container.decode([String: JSONValue].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}

enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            self = .array(try container.decode([JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

struct StoredExamAttemptItem: Codable, Equatable, Sendable, Identifiable {
    let position: Int
    let questionId: String
    let subsectionId: String
    let categoryId: String
    let choicePermutation: [Int]
    let selectedSourceIndex: Int?
    let isCorrect: Bool
    let flagged: Bool

    var id: String { questionId }
}

struct StoredExamTimer: Codable, Equatable, Sendable {
    let enabled: Bool
    let secondsAllowed: Int?
    let secondsElapsed: Int
}

struct StoredExamScore: Codable, Equatable, Sendable {
    let correct: Int
    let total: Int
    let percent: Double
    let passed: Bool
    let honours: Bool
    let categoryBreakdown: [CategoryBreakdownEntry]
    let weakSubsectionIds: [String]
}

struct StoredExamAttempt: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let bankId: String
    let mode: String
    let seed: String
    let startedAt: String
    let submittedAt: String
    let timer: StoredExamTimer
    let items: [StoredExamAttemptItem]
    let score: StoredExamScore
}

enum ProgressStoreError: LocalizedError, Equatable {
    case validationFailed([String])
    case openFailed(String)

    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            errors.joined(separator: "\n")
        case .openFailed(let message):
            message
        }
    }
}

@MainActor
final class ProgressStoreService: ObservableObject {
    @Published private(set) var preferences: ApplePreferences = .default

    let container: ModelContainer
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(container: ModelContainer) throws {
        self.container = container
        self.context = ModelContext(container)
        self.preferences = try loadPreferences()
    }

    static func open() throws -> ProgressStoreService {
        do {
            let schema = Schema([
                QuestionProgressEntity.self,
                ExamAttemptEntity.self,
                PreferencesEntity.self,
            ])
            let configuration = ModelConfiguration(schema: schema, url: persistentStoreURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return try ProgressStoreService(container: container)
        } catch {
            throw ProgressStoreError.openFailed(error.localizedDescription)
        }
    }

    static func inMemoryForTests() throws -> ProgressStoreService {
        let schema = Schema([
            QuestionProgressEntity.self,
            ExamAttemptEntity.self,
            PreferencesEntity.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return try ProgressStoreService(container: container)
    }

    static var persistentStoreURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = base.appending(path: "CanadianHam", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "Progress.store")
    }

    static func resetPersistentStoreFiles() {
        let url = persistentStoreURL
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    func questionProgressRecords() throws -> [QuestionProgressRecord] {
        let descriptor = FetchDescriptor<QuestionProgressEntity>(sortBy: [SortDescriptor(\.questionId)])
        return try context.fetch(descriptor).map { try questionProgressRecord(from: $0) }
    }

    func examAttempts() throws -> [StoredExamAttempt] {
        let descriptor = FetchDescriptor<ExamAttemptEntity>(sortBy: [SortDescriptor(\.submittedAt)])
        return try context.fetch(descriptor).map { try decoder.decode(StoredExamAttempt.self, from: $0.payloadData) }
    }

    func latestExamAttempt() throws -> StoredExamAttempt? {
        try examAttempts().sorted { $0.submittedAt > $1.submittedAt }.first
    }

    func saveQuestionProgress(_ records: [QuestionProgressRecord]) throws {
        for record in records {
            try upsertQuestionProgress(record)
        }
        try context.save()
        objectWillChange.send()
    }

    func saveExamAttempt(_ attempt: StoredExamAttempt) throws {
        let data = try encoder.encode(attempt)
        if let existing = try examAttemptEntity(id: attempt.id) {
            existing.bankId = attempt.bankId
            existing.seed = attempt.seed
            existing.startedAt = attempt.startedAt
            existing.submittedAt = attempt.submittedAt
            existing.payloadData = data
        } else {
            context.insert(ExamAttemptEntity(
                id: attempt.id,
                bankId: attempt.bankId,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: attempt.submittedAt,
                payloadData: data
            ))
        }
        try context.save()
        objectWillChange.send()
    }

    func updatePreferences(_ preferences: ApplePreferences) throws {
        let entity = try preferencesEntity(createIfMissing: true)
        entity.practiceMode = preferences.practiceMode.rawValue
        entity.examTimerEnabled = preferences.examTimerEnabled
        entity.language = preferences.language.rawValue
        entity.theme = preferences.theme.rawValue
        self.preferences = preferences
        try context.save()
    }

    func resetAllData() throws {
        try context.delete(model: QuestionProgressEntity.self)
        try context.delete(model: ExamAttemptEntity.self)
        try context.delete(model: PreferencesEntity.self)
        preferences = .default
        try context.save()
        objectWillChange.send()
    }

    func exportData(bank: QuestionBank, exportedAt: String) throws -> ProgressExportV1 {
        try CanonicalTimestamp.require(exportedAt, fieldName: "exportedAt")
        let entity = try preferencesEntity(createIfMissing: true)
        let lessonProgress = try decoder.decode([ArchivedJSON].self, from: entity.archivedLessonProgressData)
        let lessonQuizAttempts = try decoder.decode([ArchivedJSON].self, from: entity.archivedLessonQuizAttemptsData)
        return ProgressExportV1(
            schema: "canadian-ham.progress-export",
            version: 1,
            exportedAt: exportedAt,
            bankId: bank.manifest.bankId,
            questionProgress: try questionProgressRecords(),
            examAttempts: try examAttempts(),
            lessonProgress: lessonProgress,
            lessonQuizAttempts: lessonQuizAttempts,
            preferences: ExportedPreferences(
                practiceMode: preferences.practiceMode.rawValue,
                examTimerEnabled: preferences.examTimerEnabled,
                theme: preferences.theme.rawValue
            )
        )
    }

    func serializedExport(bank: QuestionBank, exportedAt: String) throws -> String {
        let data = try exportData(bank: bank, exportedAt: exportedAt)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(data), as: UTF8.self) + "\n"
    }

    func importData(_ data: ProgressExportV1, bank: QuestionBank) throws {
        let errors = validate(data, bank: bank)
        if !errors.isEmpty {
            throw ProgressStoreError.validationFailed(errors)
        }

        try resetAllData()
        for record in data.questionProgress {
            try upsertQuestionProgress(record)
        }
        for attempt in data.examAttempts {
            try saveExamAttemptWithoutSave(attempt)
        }
        var nextPreferences = ApplePreferences.default
        if let mode = ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) {
            nextPreferences.practiceMode = mode
        }
        nextPreferences.examTimerEnabled = data.preferences.examTimerEnabled
        if let theme = ApplePreferences.Theme(rawValue: data.preferences.theme) {
            nextPreferences.theme = theme
        }
        let entity = try preferencesEntity(createIfMissing: true)
        entity.practiceMode = nextPreferences.practiceMode.rawValue
        entity.examTimerEnabled = nextPreferences.examTimerEnabled
        entity.language = nextPreferences.language.rawValue
        entity.theme = nextPreferences.theme.rawValue
        entity.archivedLessonProgressData = try encoder.encode(data.lessonProgress)
        entity.archivedLessonQuizAttemptsData = try encoder.encode(data.lessonQuizAttempts)
        preferences = nextPreferences
        try context.save()
        objectWillChange.send()
    }

    func validate(_ data: ProgressExportV1, bank: QuestionBank) -> [String] {
        var errors: [String] = []
        let knownQuestionIds = Set(bank.questions.map(\.id))
        let knownCategoryIds = Set(bank.categories.map(\.id))
        let knownSubsectionIds = Set(bank.subsections.map(\.id))

        if data.schema != "canadian-ham.progress-export" { errors.append("Import file schema is not canadian-ham.progress-export.") }
        if data.version != 1 { errors.append("Import file version must be 1.") }
        if data.bankId != bank.manifest.bankId { errors.append("Import bankId must be \(bank.manifest.bankId).") }
        appendTimestampError(&errors, value: data.exportedAt, field: "exportedAt")

        var questionProgressIds = Set<String>()
        for (index, record) in data.questionProgress.enumerated() {
            let prefix = "Import questionProgress[\(index)]"
            if !knownQuestionIds.contains(record.questionId) { errors.append("\(prefix).questionId must be a known question ID.") }
            if !questionProgressIds.insert(record.questionId).inserted { errors.append("\(prefix).questionId duplicates another question progress record.") }
            if record.bankId != bank.manifest.bankId { errors.append("\(prefix).bankId must be \(bank.manifest.bankId).") }
            if record.attempts < 0 { errors.append("\(prefix).attempts must be a non-negative integer.") }
            if record.correctAttempts < 0 || record.correctAttempts > record.attempts { errors.append("\(prefix).correctAttempts must be between 0 and attempts.") }
            appendTimestampError(&errors, value: record.lastAttemptedAt, field: "\(prefix).lastAttemptedAt")
            if record.recentResults.count > 5 { errors.append("\(prefix).recentResults must contain at most five booleans.") }
            if !(0...5).contains(record.leitner.box) { errors.append("\(prefix).leitner.box must be an integer between 0 and 5.") }
            appendTimestampError(&errors, value: record.leitner.dueAt, field: "\(prefix).leitner.dueAt")
        }

        var submittedAt = Set<String>()
        for (index, attempt) in data.examAttempts.enumerated() {
            let prefix = "Import examAttempts[\(index)]"
            if attempt.id.isEmpty { errors.append("\(prefix).id must be a non-empty string.") }
            if attempt.bankId != bank.manifest.bankId { errors.append("\(prefix).bankId must be \(bank.manifest.bankId).") }
            if attempt.mode != "mock-exam" { errors.append("\(prefix).mode must be mock-exam.") }
            appendTimestampError(&errors, value: attempt.startedAt, field: "\(prefix).startedAt")
            appendTimestampError(&errors, value: attempt.submittedAt, field: "\(prefix).submittedAt")
            if !submittedAt.insert(attempt.submittedAt).inserted { errors.append("\(prefix).submittedAt duplicates another exam attempt.") }
            if attempt.timer.secondsAllowed != nil && attempt.timer.secondsAllowed! < 0 { errors.append("\(prefix).timer.secondsAllowed must be null or non-negative.") }
            if attempt.timer.secondsElapsed < 0 { errors.append("\(prefix).timer.secondsElapsed must be non-negative.") }
            validateScore(attempt.score, prefix: "\(prefix).score", knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            for (itemIndex, item) in attempt.items.enumerated() {
                validateAttemptItem(item, prefix: "\(prefix).items[\(itemIndex)]", knownQuestionIds: knownQuestionIds, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            }
        }

        if ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) == nil {
            errors.append("Import preferences.practiceMode is invalid.")
        }
        if ApplePreferences.Theme(rawValue: data.preferences.theme) == nil {
            errors.append("Import preferences.theme is invalid.")
        }
        return errors
    }

    private func upsertQuestionProgress(_ record: QuestionProgressRecord) throws {
        let data = try encoder.encode(record.recentResults)
        if let entity = try questionProgressEntity(questionId: record.questionId) {
            entity.bankId = record.bankId
            entity.attempts = record.attempts
            entity.correctAttempts = record.correctAttempts
            entity.lastAttemptedAt = record.lastAttemptedAt
            entity.lastResult = record.lastResult.rawValue
            entity.recentResultsData = data
            entity.leitnerBox = record.leitner.box
            entity.dueAt = record.leitner.dueAt
            entity.notes = record.notes
        } else {
            context.insert(QuestionProgressEntity(
                questionId: record.questionId,
                bankId: record.bankId,
                attempts: record.attempts,
                correctAttempts: record.correctAttempts,
                lastAttemptedAt: record.lastAttemptedAt,
                lastResult: record.lastResult.rawValue,
                recentResultsData: data,
                leitnerBox: record.leitner.box,
                dueAt: record.leitner.dueAt,
                notes: record.notes
            ))
        }
    }

    private func questionProgressEntity(questionId: String) throws -> QuestionProgressEntity? {
        var descriptor = FetchDescriptor<QuestionProgressEntity>(predicate: #Predicate { $0.questionId == questionId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func examAttemptEntity(id: String) throws -> ExamAttemptEntity? {
        var descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func preferencesEntity(createIfMissing: Bool) throws -> PreferencesEntity {
        let defaultKey = PreferencesEntity.defaultKey
        var descriptor = FetchDescriptor<PreferencesEntity>(predicate: #Predicate { $0.key == defaultKey })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let entity = PreferencesEntity(
            practiceMode: ApplePreferences.default.practiceMode.rawValue,
            examTimerEnabled: ApplePreferences.default.examTimerEnabled,
            language: ApplePreferences.default.language.rawValue,
            theme: ApplePreferences.default.theme.rawValue
        )
        if createIfMissing {
            context.insert(entity)
            try context.save()
        }
        return entity
    }

    private func loadPreferences() throws -> ApplePreferences {
        let entity = try preferencesEntity(createIfMissing: true)
        return ApplePreferences(
            practiceMode: ApplePreferences.PracticeMode(rawValue: entity.practiceMode) ?? .immediate,
            examTimerEnabled: entity.examTimerEnabled,
            language: BankLanguage(rawValue: entity.language) ?? .english,
            theme: ApplePreferences.Theme(rawValue: entity.theme) ?? .system
        )
    }

    private func saveExamAttemptWithoutSave(_ attempt: StoredExamAttempt) throws {
        let data = try encoder.encode(attempt)
        context.insert(ExamAttemptEntity(
            id: attempt.id,
            bankId: attempt.bankId,
            seed: attempt.seed,
            startedAt: attempt.startedAt,
            submittedAt: attempt.submittedAt,
            payloadData: data
        ))
    }

    private func questionProgressRecord(from entity: QuestionProgressEntity) throws -> QuestionProgressRecord {
        let recentResults = try decoder.decode([Bool].self, from: entity.recentResultsData)
        return QuestionProgressRecord(
            questionId: entity.questionId,
            bankId: entity.bankId,
            attempts: entity.attempts,
            correctAttempts: entity.correctAttempts,
            lastAttemptedAt: entity.lastAttemptedAt,
            lastResult: AnswerResult(rawValue: entity.lastResult) ?? .incorrect,
            recentResults: recentResults,
            leitner: LeitnerState(box: entity.leitnerBox, dueAt: entity.dueAt),
            notes: entity.notes
        )
    }
}

private func appendTimestampError(_ errors: inout [String], value: String, field: String) {
    do {
        try CanonicalTimestamp.require(value, fieldName: field)
    } catch {
        errors.append("\(field) must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ.")
    }
}

private func validateScore(
    _ score: StoredExamScore,
    prefix: String,
    knownCategoryIds: Set<String>,
    knownSubsectionIds: Set<String>,
    errors: inout [String]
) {
    if score.correct < 0 { errors.append("\(prefix).correct must be non-negative.") }
    if score.total < 0 { errors.append("\(prefix).total must be non-negative.") }
    if score.correct > score.total { errors.append("\(prefix).correct must not exceed total.") }
    if score.percent < 0 { errors.append("\(prefix).percent must be non-negative.") }
    for (index, entry) in score.categoryBreakdown.enumerated() {
        let entryPrefix = "\(prefix).categoryBreakdown[\(index)]"
        if !knownCategoryIds.contains(entry.categoryId) { errors.append("\(entryPrefix).categoryId must be a known category ID.") }
        if entry.correct < 0 || entry.total < 0 || entry.correct > entry.total { errors.append("\(entryPrefix) counts are invalid.") }
    }
    for id in score.weakSubsectionIds where !knownSubsectionIds.contains(id) {
        errors.append("\(prefix).weakSubsectionIds contains unknown subsection ID \(id).")
    }
}

private func validateAttemptItem(
    _ item: StoredExamAttemptItem,
    prefix: String,
    knownQuestionIds: Set<String>,
    knownCategoryIds: Set<String>,
    knownSubsectionIds: Set<String>,
    errors: inout [String]
) {
    if item.position < 1 { errors.append("\(prefix).position must be positive.") }
    if !knownQuestionIds.contains(item.questionId) { errors.append("\(prefix).questionId must be a known question ID.") }
    if !knownSubsectionIds.contains(item.subsectionId) || item.subsectionId != String(item.questionId.prefix(9)) {
        errors.append("\(prefix).subsectionId must match the known question subsection.")
    }
    if !knownCategoryIds.contains(item.categoryId) || item.categoryId != String(item.questionId.prefix(5)) {
        errors.append("\(prefix).categoryId must match the known question category.")
    }
    if Set(item.choicePermutation) != Set([0, 1, 2, 3]) || item.choicePermutation.count != 4 {
        errors.append("\(prefix).choicePermutation must be a permutation of 0, 1, 2, 3.")
    }
    if let selected = item.selectedSourceIndex, !(0...3).contains(selected) {
        errors.append("\(prefix).selectedSourceIndex must be null or an answer source index between 0 and 3.")
    }
}
