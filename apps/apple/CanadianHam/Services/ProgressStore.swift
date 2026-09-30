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

    init(
        schema: String,
        version: Int,
        exportedAt: String,
        bankId: String,
        questionProgress: [QuestionProgressRecord],
        examAttempts: [StoredExamAttempt],
        lessonProgress: [ArchivedJSON],
        lessonQuizAttempts: [ArchivedJSON],
        preferences: ExportedPreferences
    ) {
        self.schema = schema
        self.version = version
        self.exportedAt = exportedAt
        self.bankId = bankId
        self.questionProgress = questionProgress
        self.examAttempts = examAttempts
        self.lessonProgress = lessonProgress
        self.lessonQuizAttempts = lessonQuizAttempts
        self.preferences = preferences
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        version = try container.decode(Int.self, forKey: .version)
        exportedAt = try container.decode(String.self, forKey: .exportedAt)
        bankId = try container.decode(String.self, forKey: .bankId)
        questionProgress = try container.decode([QuestionProgressRecord].self, forKey: .questionProgress)
        examAttempts = try container.decode([StoredExamAttempt].self, forKey: .examAttempts)
        lessonProgress = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonProgress) ?? []
        lessonQuizAttempts = try container.decodeIfPresent([ArchivedJSON].self, forKey: .lessonQuizAttempts) ?? []
        preferences = try container.decode(ExportedPreferences.self, forKey: .preferences)
    }
}

struct LessonProgressRecord: Codable, Equatable, Sendable, Identifiable {
    let lessonId: String
    let readAt: String
    let readCount: Int

    var id: String { lessonId }
}

struct LessonQuizAttempt: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let quizId: String
    let lessonId: String
    let submittedAt: String
    let correct: Int
    let total: Int
    let percent: Double
    let officialQuestionIds: [String]
    let incorrectOfficialQuestionIds: [String]
    let incorrectConceptCheckIds: [String]
}

struct ExportedPreferences: Codable, Equatable, Sendable {
    let practiceMode: String
    let examTimerEnabled: Bool
    let theme: String

    init(practiceMode: String, examTimerEnabled: Bool, theme: String = ApplePreferences.Theme.system.rawValue) {
        self.practiceMode = practiceMode
        self.examTimerEnabled = examTimerEnabled
        self.theme = theme
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        practiceMode = try container.decode(String.self, forKey: .practiceMode)
        examTimerEnabled = try container.decode(Bool.self, forKey: .examTimerEnabled)
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? ApplePreferences.Theme.system.rawValue
    }
}

struct ArchivedJSON: Codable, Equatable, Sendable {
    let storage: [String: JSONValue]

    init(storage: [String: JSONValue]) {
        self.storage = storage
    }

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

    private enum CodingKeys: String, CodingKey {
        case enabled
        case secondsAllowed
        case secondsElapsed
    }

    init(enabled: Bool, secondsAllowed: Int?, secondsElapsed: Int) {
        self.enabled = enabled
        self.secondsAllowed = secondsAllowed
        self.secondsElapsed = secondsElapsed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        secondsAllowed = try Self.decodeOptionalNonNegativeIntegerCompatibleNumber(from: container, forKey: .secondsAllowed)
        secondsElapsed = try Self.decodeNonNegativeIntegerCompatibleNumber(from: container, forKey: .secondsElapsed)
    }

    private static func decodeOptionalNonNegativeIntegerCompatibleNumber(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if !container.contains(key) { return nil }
        if try container.decodeNil(forKey: key) { return nil }
        return try decodeNonNegativeIntegerCompatibleNumber(from: container, forKey: key)
    }

    private static func decodeNonNegativeIntegerCompatibleNumber(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int {
        if let intValue = try? container.decode(Int.self, forKey: key) {
            return intValue
        }
        let doubleValue = try container.decode(Double.self, forKey: key)
        guard doubleValue.isFinite, doubleValue >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a non-negative finite number.")
        }
        let roundedValue = doubleValue.rounded()
        guard let intValue = Int(exactly: roundedValue) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a number within the supported integer range.")
        }
        return intValue
    }
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

#if DEBUG
enum ProgressStoreInjectedFailure: Error, Equatable {
    case importAfterDelete
    case lessonQuizSave
}
#endif

private struct ProgressStoreSnapshot {
    let questionProgress: [QuestionProgressRecord]
    let examAttempts: [StoredExamAttempt]
    let preferences: ApplePreferences
    let archivedLessonProgressData: Data
    let archivedLessonQuizAttemptsData: Data
}

@MainActor
final class ProgressStoreService: ObservableObject {
    @Published private(set) var preferences: ApplePreferences = .default

    let container: ModelContainer
    private let context: ModelContext
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
#if DEBUG
    var failNextImportAfterDeleteForTesting = false
    var failNextLessonQuizSaveForTesting = false
#endif

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
            let configuration = ModelConfiguration(schema: schema, url: persistentStoreURL, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: CanadianHamProgressMigrationPlan.self, configurations: [configuration])
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

    func lessonProgressRecords() throws -> [LessonProgressRecord] {
        let entity = try preferencesEntity(createIfMissing: true)
        return try decoder.decode([LessonProgressRecord].self, from: entity.archivedLessonProgressData)
            .sorted { $0.lessonId < $1.lessonId }
    }

    func lessonQuizAttempts() throws -> [LessonQuizAttempt] {
        let entity = try preferencesEntity(createIfMissing: true)
        return try decoder.decode([LessonQuizAttempt].self, from: entity.archivedLessonQuizAttemptsData)
            .sorted { $0.submittedAt < $1.submittedAt }
    }

    func saveLessonProgress(_ record: LessonProgressRecord) throws {
        let entity = try preferencesEntity(createIfMissing: true)
        let current = try lessonProgressRecords().filter { $0.lessonId != record.lessonId }
        entity.archivedLessonProgressData = try encoder.encode((current + [record]).sorted { $0.lessonId < $1.lessonId })
        try context.save()
        objectWillChange.send()
    }

    func saveLessonQuizAttempt(_ attempt: LessonQuizAttempt, questionProgress: [QuestionProgressRecord]) throws {
        do {
            let entity = try preferencesEntity(createIfMissing: true, saveIfCreated: false)
            let attempts = try decoder.decode([LessonQuizAttempt].self, from: entity.archivedLessonQuizAttemptsData)
            entity.archivedLessonQuizAttemptsData = try encoder.encode((attempts + [attempt]).sorted { $0.submittedAt < $1.submittedAt })
            for record in questionProgress {
                try upsertQuestionProgress(record)
            }
#if DEBUG
            if failNextLessonQuizSaveForTesting {
                failNextLessonQuizSaveForTesting = false
                throw ProgressStoreInjectedFailure.lessonQuizSave
            }
#endif
            try context.save()
            objectWillChange.send()
        } catch {
            context.rollback()
            throw error
        }
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
        // Web exports may regenerate local IDs; submittedAt is canonical and import validation forbids duplicates.
        if let existing = try examAttemptEntity(id: attempt.id) ?? examAttemptEntity(submittedAt: attempt.submittedAt) {
            existing.id = attempt.id
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

        let previousSnapshot = try snapshotForRollback()
        do {
            try context.delete(model: QuestionProgressEntity.self)
            try context.delete(model: ExamAttemptEntity.self)
            try context.delete(model: PreferencesEntity.self)
#if DEBUG
            if failNextImportAfterDeleteForTesting {
                failNextImportAfterDeleteForTesting = false
                throw ProgressStoreInjectedFailure.importAfterDelete
            }
#endif
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
            let entity = PreferencesEntity(
                practiceMode: nextPreferences.practiceMode.rawValue,
                examTimerEnabled: nextPreferences.examTimerEnabled,
                language: nextPreferences.language.rawValue,
                theme: nextPreferences.theme.rawValue
            )
            entity.archivedLessonProgressData = try encoder.encode(data.lessonProgress)
            entity.archivedLessonQuizAttemptsData = try encoder.encode(data.lessonQuizAttempts)
            context.insert(entity)
            try context.save()
            preferences = nextPreferences
            objectWillChange.send()
        } catch {
            context.rollback()
            try restore(previousSnapshot)
            throw error
        }
    }

    func validate(_ data: ProgressExportV1, bank: QuestionBank) -> [String] {
        var errors: [String] = []
        let knownQuestionIds = Set(bank.questions.map(\.id))
        let knownCategoryIds = Set(bank.categories.map(\.id))
        let knownSubsectionIds = Set(bank.subsections.map(\.id))

        if data.schema != "canadian-ham.progress-export" { errors.append(String(localized: "Import file schema is not canadian-ham.progress-export.")) }
        if data.version != 1 { errors.append(String(localized: "Import file version must be 1.")) }
        if data.bankId != bank.manifest.bankId { errors.append(String(localized: "Import bankId must be \(bank.manifest.bankId).")) }
        appendTimestampError(&errors, value: data.exportedAt, field: "exportedAt")

        var questionProgressIds = Set<String>()
        for (index, record) in data.questionProgress.enumerated() {
            let prefix = "Import questionProgress[\(index)]"
            if !knownQuestionIds.contains(record.questionId) { errors.append(String(localized: "\(prefix).questionId must be a known question ID.")) }
            if !questionProgressIds.insert(record.questionId).inserted { errors.append(String(localized: "\(prefix).questionId duplicates another question progress record.")) }
            if record.bankId != bank.manifest.bankId { errors.append(String(localized: "\(prefix).bankId must be \(bank.manifest.bankId).")) }
            if record.attempts < 0 { errors.append(String(localized: "\(prefix).attempts must be a non-negative integer.")) }
            if record.correctAttempts < 0 || record.correctAttempts > record.attempts { errors.append(String(localized: "\(prefix).correctAttempts must be between 0 and attempts.")) }
            appendTimestampError(&errors, value: record.lastAttemptedAt, field: "\(prefix).lastAttemptedAt")
            if record.recentResults.count > 5 { errors.append(String(localized: "\(prefix).recentResults must contain at most five booleans.")) }
            if !(0...5).contains(record.leitner.box) { errors.append(String(localized: "\(prefix).leitner.box must be an integer between 0 and 5.")) }
            appendTimestampError(&errors, value: record.leitner.dueAt, field: "\(prefix).leitner.dueAt")
        }

        var submittedAt = Set<String>()
        for (index, attempt) in data.examAttempts.enumerated() {
            let prefix = "Import examAttempts[\(index)]"
            if attempt.id.isEmpty { errors.append(String(localized: "\(prefix).id must be a non-empty string.")) }
            if attempt.bankId != bank.manifest.bankId { errors.append(String(localized: "\(prefix).bankId must be \(bank.manifest.bankId).")) }
            if attempt.mode != "mock-exam" { errors.append(String(localized: "\(prefix).mode must be mock-exam.")) }
            appendTimestampError(&errors, value: attempt.startedAt, field: "\(prefix).startedAt")
            appendTimestampError(&errors, value: attempt.submittedAt, field: "\(prefix).submittedAt")
            if !submittedAt.insert(attempt.submittedAt).inserted { errors.append(String(localized: "\(prefix).submittedAt duplicates another exam attempt.")) }
            if attempt.timer.secondsAllowed != nil && attempt.timer.secondsAllowed! < 0 { errors.append(String(localized: "\(prefix).timer.secondsAllowed must be null or non-negative.")) }
            if attempt.timer.secondsElapsed < 0 { errors.append(String(localized: "\(prefix).timer.secondsElapsed must be non-negative.")) }
            validateScore(attempt.score, prefix: "\(prefix).score", knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            for (itemIndex, item) in attempt.items.enumerated() {
                validateAttemptItem(item, prefix: "\(prefix).items[\(itemIndex)]", knownQuestionIds: knownQuestionIds, knownCategoryIds: knownCategoryIds, knownSubsectionIds: knownSubsectionIds, errors: &errors)
            }
        }

        validateLessonProgress(data.lessonProgress, knownLessonIds: bank.knownLessonIds, errors: &errors)
        validateLessonQuizAttempts(
            data.lessonQuizAttempts,
            knownQuestionIds: knownQuestionIds,
            knownLessonIds: bank.knownLessonIds,
            lessonQuizzesById: bank.lessonQuizzesById,
            errors: &errors
        )

        if ApplePreferences.PracticeMode(rawValue: data.preferences.practiceMode) == nil {
            errors.append(String(localized: "Import preferences.practiceMode is invalid."))
        }
        if ApplePreferences.Theme(rawValue: data.preferences.theme) == nil {
            errors.append(String(localized: "Import preferences.theme is invalid."))
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

    private func examAttemptEntity(submittedAt: String) throws -> ExamAttemptEntity? {
        var descriptor = FetchDescriptor<ExamAttemptEntity>(predicate: #Predicate { $0.submittedAt == submittedAt })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func existingPreferencesEntity() throws -> PreferencesEntity? {
        let defaultKey = PreferencesEntity.defaultKey
        var descriptor = FetchDescriptor<PreferencesEntity>(predicate: #Predicate { $0.key == defaultKey })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func preferencesEntity(createIfMissing: Bool, saveIfCreated: Bool = true) throws -> PreferencesEntity {
        if let existing = try existingPreferencesEntity() {
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
            if saveIfCreated {
                try context.save()
            }
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

    private func snapshotForRollback() throws -> ProgressStoreSnapshot {
        let entity = try existingPreferencesEntity()
        return ProgressStoreSnapshot(
            questionProgress: try questionProgressRecords(),
            examAttempts: try examAttempts(),
            preferences: preferences,
            archivedLessonProgressData: entity?.archivedLessonProgressData ?? Data("[]".utf8),
            archivedLessonQuizAttemptsData: entity?.archivedLessonQuizAttemptsData ?? Data("[]".utf8)
        )
    }

    private func restore(_ snapshot: ProgressStoreSnapshot) throws {
        try context.delete(model: QuestionProgressEntity.self)
        try context.delete(model: ExamAttemptEntity.self)
        try context.delete(model: PreferencesEntity.self)
        let entity = PreferencesEntity(
            practiceMode: snapshot.preferences.practiceMode.rawValue,
            examTimerEnabled: snapshot.preferences.examTimerEnabled,
            language: snapshot.preferences.language.rawValue,
            theme: snapshot.preferences.theme.rawValue
        )
        entity.archivedLessonProgressData = snapshot.archivedLessonProgressData
        entity.archivedLessonQuizAttemptsData = snapshot.archivedLessonQuizAttemptsData
        context.insert(entity)
        for record in snapshot.questionProgress {
            try upsertQuestionProgress(record)
        }
        for attempt in snapshot.examAttempts {
            try saveExamAttemptWithoutSave(attempt)
        }
        try context.save()
        preferences = snapshot.preferences
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
        errors.append(String(localized: "\(field) must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ."))
    }
}

private func validateScore(
    _ score: StoredExamScore,
    prefix: String,
    knownCategoryIds: Set<String>,
    knownSubsectionIds: Set<String>,
    errors: inout [String]
) {
    if score.correct < 0 { errors.append(String(localized: "\(prefix).correct must be non-negative.")) }
    if score.total < 0 { errors.append(String(localized: "\(prefix).total must be non-negative.")) }
    if score.correct > score.total { errors.append(String(localized: "\(prefix).correct must not exceed total.")) }
    if score.percent < 0 { errors.append(String(localized: "\(prefix).percent must be non-negative.")) }
    for (index, entry) in score.categoryBreakdown.enumerated() {
        let entryPrefix = "\(prefix).categoryBreakdown[\(index)]"
        if !knownCategoryIds.contains(entry.categoryId) { errors.append(String(localized: "\(entryPrefix).categoryId must be a known category ID.")) }
        if entry.correct < 0 || entry.total < 0 || entry.correct > entry.total { errors.append(String(localized: "\(entryPrefix) counts are invalid.")) }
    }
    for id in score.weakSubsectionIds where !knownSubsectionIds.contains(id) {
        errors.append(String(localized: "\(prefix).weakSubsectionIds contains unknown subsection ID \(id)."))
    }
}

private func validateLessonProgress(_ records: [ArchivedJSON], knownLessonIds: Set<String>, errors: inout [String]) {
    var lessonIds = Set<String>()
    for (index, record) in records.enumerated() {
        let prefix = "Import lessonProgress[\(index)]"
        guard let lessonId = record.storage["lessonId"]?.stringValue, !lessonId.isEmpty else {
            errors.append(String(localized: "\(prefix).lessonId must be a non-empty string."))
            continue
        }
        if !knownLessonIds.contains(lessonId) {
            errors.append(String(localized: "\(prefix).lessonId must be a known lesson ID."))
        }
        if !lessonIds.insert(lessonId).inserted {
            errors.append(String(localized: "\(prefix).lessonId duplicates another lesson progress record."))
        }
        if let readAt = record.storage["readAt"]?.stringValue {
            appendTimestampError(&errors, value: readAt, field: "\(prefix).readAt")
        } else {
            errors.append(String(localized: "\(prefix).readAt must be a canonical UTC timestamp string."))
        }
        if let readCount = record.storage["readCount"]?.numberValue, readCount.rounded() == readCount, readCount > 0 {
            continue
        }
        errors.append(String(localized: "\(prefix).readCount must be a positive integer."))
    }
}

private func validateLessonQuizAttempts(
    _ attempts: [ArchivedJSON],
    knownQuestionIds: Set<String>,
    knownLessonIds: Set<String>,
    lessonQuizzesById: [String: BankLessonQuiz],
    errors: inout [String]
) {
    var ids = Set<String>()
    for (index, attempt) in attempts.enumerated() {
        let prefix = "Import lessonQuizAttempts[\(index)]"
        guard let id = attempt.storage["id"]?.stringValue, !id.isEmpty else {
            errors.append(String(localized: "\(prefix).id must be a non-empty string."))
            continue
        }
        if !ids.insert(id).inserted {
            errors.append(String(localized: "\(prefix).id duplicates another lesson quiz attempt."))
        }

        let quiz: BankLessonQuiz?
        if let quizId = attempt.storage["quizId"]?.nonEmptyStringValue {
            quiz = lessonQuizzesById[quizId]
            if quiz == nil {
                errors.append(String(localized: "\(prefix).quizId must be a known lesson quiz ID."))
            }
        } else {
            quiz = nil
            errors.append(String(localized: "\(prefix).quizId must be a non-empty string."))
        }

        if let lessonId = attempt.storage["lessonId"]?.nonEmptyStringValue {
            if !knownLessonIds.contains(lessonId) || (quiz != nil && lessonId != quiz?.lessonId) {
                errors.append(String(localized: "\(prefix).lessonId must match the known lesson quiz."))
            }
        } else {
            errors.append(String(localized: "\(prefix).lessonId must be a non-empty string."))
        }

        if let submittedAt = attempt.storage["submittedAt"]?.stringValue {
            appendTimestampError(&errors, value: submittedAt, field: "\(prefix).submittedAt")
        } else {
            errors.append(String(localized: "\(prefix).submittedAt must be a canonical UTC timestamp string."))
        }
        guard let correct = attempt.storage["correct"]?.numberValue, correct.rounded() == correct, correct >= 0 else {
            errors.append(String(localized: "\(prefix).correct must be a non-negative integer."))
            continue
        }
        guard let total = attempt.storage["total"]?.numberValue, total.rounded() == total, total > 0 else {
            errors.append(String(localized: "\(prefix).total must be a positive integer."))
            continue
        }
        if correct > total { errors.append(String(localized: "\(prefix).correct must not exceed total.")) }
        if let percent = attempt.storage["percent"]?.numberValue, percent.isFinite, percent >= 0, percent <= 100 {
            let expectedPercent = (correct / total) * 100
            if abs(percent - expectedPercent) > 1e-9 {
                errors.append(String(localized: "\(prefix).percent must match correct divided by total."))
            }
        } else {
            errors.append(String(localized: "\(prefix).percent must be a number between 0 and 100."))
        }

        if let officialQuestionIds = stringArray(attempt.storage["officialQuestionIds"]) {
            let quizQuestionIds = Set(quiz?.officialQuestionIds ?? [])
            if !officialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                errors.append(String(localized: "\(prefix).officialQuestionIds must contain known question IDs."))
            } else if quiz != nil && !officialQuestionIds.allSatisfy(quizQuestionIds.contains) {
                errors.append(String(localized: "\(prefix).officialQuestionIds must belong to the lesson quiz."))
            }

            if let incorrectOfficialQuestionIds = stringArray(attempt.storage["incorrectOfficialQuestionIds"]) {
                if !incorrectOfficialQuestionIds.allSatisfy(knownQuestionIds.contains) {
                    errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must contain known question IDs."))
                } else {
                    let officialSet = Set(officialQuestionIds)
                    if !incorrectOfficialQuestionIds.allSatisfy(officialSet.contains) {
                        errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be a subset of officialQuestionIds."))
                    }
                }
            } else {
                errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be an array of strings."))
            }
        } else {
            errors.append(String(localized: "\(prefix).officialQuestionIds must be an array of strings."))
            if stringArray(attempt.storage["incorrectOfficialQuestionIds"]) == nil {
                errors.append(String(localized: "\(prefix).incorrectOfficialQuestionIds must be an array of strings."))
            }
        }

        if let incorrectConceptCheckIds = stringArray(attempt.storage["incorrectConceptCheckIds"]) {
            let conceptCheckIds = quiz?.conceptCheckIds ?? []
            if quiz != nil && !incorrectConceptCheckIds.allSatisfy(conceptCheckIds.contains) {
                errors.append(String(localized: "\(prefix).incorrectConceptCheckIds must contain known concept check IDs for the quiz."))
            }
        } else {
            errors.append(String(localized: "\(prefix).incorrectConceptCheckIds must be an array of strings."))
        }
    }
}

private func stringArray(_ value: JSONValue?) -> [String]? {
    guard case .array(let values) = value else { return nil }
    return values.allSatisfy { $0.stringValue != nil } ? values.compactMap(\.stringValue) : nil
}

private extension JSONValue {
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var nonEmptyStringValue: String? {
        guard let value = stringValue, !value.isEmpty else { return nil }
        return value
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
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
    if item.position < 1 { errors.append(String(localized: "\(prefix).position must be positive.")) }
    if !knownQuestionIds.contains(item.questionId) { errors.append(String(localized: "\(prefix).questionId must be a known question ID.")) }
    if !knownSubsectionIds.contains(item.subsectionId) || item.subsectionId != String(item.questionId.prefix(9)) {
        errors.append(String(localized: "\(prefix).subsectionId must match the known question subsection."))
    }
    if !knownCategoryIds.contains(item.categoryId) || item.categoryId != String(item.questionId.prefix(5)) {
        errors.append(String(localized: "\(prefix).categoryId must match the known question category."))
    }
    if Set(item.choicePermutation) != Set([0, 1, 2, 3]) || item.choicePermutation.count != 4 {
        errors.append(String(localized: "\(prefix).choicePermutation must be a permutation of 0, 1, 2, 3."))
    }
    if let selected = item.selectedSourceIndex, !(0...3).contains(selected) {
        errors.append(String(localized: "\(prefix).selectedSourceIndex must be null or an answer source index between 0 and 3."))
    }
}
