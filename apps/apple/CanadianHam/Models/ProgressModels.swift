import Foundation
import SwiftData

enum CanadianHamProgressSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [QuestionProgressEntity.self, ExamAttemptEntity.self, PreferencesEntity.self]
    }

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
            key: String = defaultKey,
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
}

enum CanadianHamProgressSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [QuestionProgressEntity.self, ExamAttemptEntity.self, PreferencesEntity.self]
    }

    @Model
    final class QuestionProgressEntity {
        var questionId: String = ""
        var bankId: String = ""
        var attempts: Int = 0
        var correctAttempts: Int = 0
        var lastAttemptedAt: String = ""
        var lastResult: String = "incorrect"
        var recentResultsData: Data = Data("[]".utf8)
        var leitnerBox: Int = 0
        var dueAt: String = ""
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
        var id: String = ""
        var bankId: String = ""
        var seed: String = ""
        var startedAt: String = ""
        var submittedAt: String = ""
        var payloadData: Data = Data()

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
        var key: String = defaultKey
        var practiceMode: String = "immediate"
        var examTimerEnabled: Bool = false
        var language: String = "en"
        var theme: String = "system"
        var archivedLessonProgressData: Data = Data("[]".utf8)
        var archivedLessonQuizAttemptsData: Data = Data("[]".utf8)

        init(
            key: String = defaultKey,
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
}

enum CanadianHamProgressSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            QuestionProgressEntity.self,
            ExamAttemptEntity.self,
            PreferencesEntity.self,
            LessonProgressEntity.self,
            LessonQuizAttemptEntity.self,
            MorseCourseProgressEntity.self,
        ]
    }

    @Model
    final class QuestionProgressEntity {
        var questionId: String = ""
        var bankId: String = ""
        var attempts: Int = 0
        var correctAttempts: Int = 0
        var lastAttemptedAt: String = ""
        var lastResult: String = "incorrect"
        var recentResultsData: Data = Data("[]".utf8)
        var leitnerBox: Int = 0
        var dueAt: String = ""
        var notes: String?
        var deviceId: String = ""

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
            notes: String? = nil,
            deviceId: String = ""
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
            self.deviceId = deviceId
        }
    }

    @Model
    final class ExamAttemptEntity {
        var id: String = ""
        var bankId: String = ""
        var seed: String = ""
        var startedAt: String = ""
        var submittedAt: String = ""
        var payloadData: Data = Data()
        var deviceId: String = ""

        init(id: String, bankId: String, seed: String, startedAt: String, submittedAt: String, payloadData: Data, deviceId: String = "") {
            self.id = id
            self.bankId = bankId
            self.seed = seed
            self.startedAt = startedAt
            self.submittedAt = submittedAt
            self.payloadData = payloadData
            self.deviceId = deviceId
        }
    }

    @Model
    final class PreferencesEntity {
        var key: String = defaultKey
        var practiceMode: String = "immediate"
        var examTimerEnabled: Bool = false
        var language: String = "system"
        var theme: String = "system"
        var archivedLessonProgressData: Data = Data("[]".utf8)
        var archivedLessonQuizAttemptsData: Data = Data("[]".utf8)

        init(
            key: String = defaultKey,
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

    @Model
    final class LessonProgressEntity {
        var lessonId: String = ""
        var readAt: String = ""
        var readCount: Int = 0
        var deviceId: String = ""

        init(lessonId: String, readAt: String, readCount: Int, deviceId: String = "") {
            self.lessonId = lessonId
            self.readAt = readAt
            self.readCount = readCount
            self.deviceId = deviceId
        }
    }

    @Model
    final class LessonQuizAttemptEntity {
        var id: String = ""
        var quizId: String = ""
        var lessonId: String = ""
        var submittedAt: String = ""
        var payloadData: Data = Data()
        var deviceId: String = ""

        init(id: String, quizId: String, lessonId: String, submittedAt: String, payloadData: Data, deviceId: String = "") {
            self.id = id
            self.quizId = quizId
            self.lessonId = lessonId
            self.submittedAt = submittedAt
            self.payloadData = payloadData
            self.deviceId = deviceId
        }
    }

    @Model
    final class MorseCourseProgressEntity {
        var key: String = defaultKey
        var payloadData: Data = Data()
        var deviceId: String = ""

        init(key: String = defaultKey, payloadData: Data, deviceId: String = "") {
            self.key = key
            self.payloadData = payloadData
            self.deviceId = deviceId
        }

        static let defaultKey = "default"
    }
}

typealias QuestionProgressEntity = CanadianHamProgressSchemaV3.QuestionProgressEntity
typealias ExamAttemptEntity = CanadianHamProgressSchemaV3.ExamAttemptEntity
typealias PreferencesEntity = CanadianHamProgressSchemaV3.PreferencesEntity
typealias LessonProgressEntity = CanadianHamProgressSchemaV3.LessonProgressEntity
typealias LessonQuizAttemptEntity = CanadianHamProgressSchemaV3.LessonQuizAttemptEntity
typealias MorseCourseProgressEntity = CanadianHamProgressSchemaV3.MorseCourseProgressEntity

enum CanadianHamProgressMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CanadianHamProgressSchemaV1.self, CanadianHamProgressSchemaV2.self, CanadianHamProgressSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: CanadianHamProgressSchemaV1.self,
        toVersion: CanadianHamProgressSchemaV2.self
    )

    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: CanadianHamProgressSchemaV2.self,
        toVersion: CanadianHamProgressSchemaV3.self
    )
}
