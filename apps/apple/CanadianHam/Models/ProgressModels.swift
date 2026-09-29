import Foundation
import SwiftData

@Model
final class QuestionProgressEntity {
    @Attribute(.unique) var questionId: String
    var bankId: String
    var attempts: Int
    var correctAttempts: Int
    var lastAttemptedAt: String
    var lastResult: String
    var recentResultsData: Data
    var leitnerBox: Int
    var dueAt: String
    var notes: String?

    init(
        questionId: String,
        bankId: String,
        attempts: Int,
        correctAttempts: Int,
        lastAttemptedAt: String,
        lastResult: String,
        recentResultsData: Data,
        leitnerBox: Int,
        dueAt: String,
        notes: String? = nil
    ) {
        self.questionId = questionId
        self.bankId = bankId
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.lastAttemptedAt = lastAttemptedAt
        self.lastResult = lastResult
        self.recentResultsData = recentResultsData
        self.leitnerBox = leitnerBox
        self.dueAt = dueAt
        self.notes = notes
    }
}

@Model
final class ExamAttemptEntity {
    @Attribute(.unique) var id: String
    var bankId: String
    var seed: String
    var startedAt: String
    var submittedAt: String
    var payloadData: Data

    init(id: String, bankId: String, seed: String, startedAt: String, submittedAt: String, payloadData: Data) {
        self.id = id
        self.bankId = bankId
        self.seed = seed
        self.startedAt = startedAt
        self.submittedAt = submittedAt
        self.payloadData = payloadData
    }
}

@Model
final class PreferencesEntity {
    @Attribute(.unique) var key: String
    var practiceMode: String
    var examTimerEnabled: Bool
    var language: String
    var theme: String
    var archivedLessonProgressData: Data
    var archivedLessonQuizAttemptsData: Data

    init(
        key: String = PreferencesEntity.defaultKey,
        practiceMode: String,
        examTimerEnabled: Bool,
        language: String,
        theme: String,
        archivedLessonProgressData: Data = Data("[]".utf8),
        archivedLessonQuizAttemptsData: Data = Data("[]".utf8)
    ) {
        self.key = key
        self.practiceMode = practiceMode
        self.examTimerEnabled = examTimerEnabled
        self.language = language
        self.theme = theme
        self.archivedLessonProgressData = archivedLessonProgressData
        self.archivedLessonQuizAttemptsData = archivedLessonQuizAttemptsData
    }

    static let defaultKey = "preferences"
}

enum CanadianHamProgressSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [QuestionProgressEntity.self, ExamAttemptEntity.self, PreferencesEntity.self]
    }
}

enum CanadianHamProgressMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CanadianHamProgressSchemaV1.self]
    }

    // Stub for future schema changes. The first schema has no migration stages.
    static var stages: [MigrationStage] { [] }
}
