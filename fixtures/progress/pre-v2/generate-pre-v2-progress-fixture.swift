// Regenerates Progress.store for the pre-V2 SwiftData fixture used by task-13.5.
// Run from the repository root:
//   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift fixtures/progress/pre-v2/generate-pre-v2-progress-fixture.swift fixtures/progress/pre-v2/Progress.store
//   sqlite3 fixtures/progress/pre-v2/Progress.store 'PRAGMA wal_checkpoint(TRUNCATE);'
//   rm -f fixtures/progress/pre-v2/Progress.store-shm fixtures/progress/pre-v2/Progress.store-wal

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

    init(questionId: String, bankId: String, attempts: Int, correctAttempts: Int, lastAttemptedAt: String, lastResult: String, recentResultsData: Data, leitnerBox: Int, dueAt: String, notes: String? = nil) {
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

    init(key: String = "preferences", practiceMode: String, examTimerEnabled: Bool, language: String, theme: String, archivedLessonProgressData: Data = Data("[]".utf8), archivedLessonQuizAttemptsData: Data = Data("[]".utf8)) {
        self.key = key
        self.practiceMode = practiceMode
        self.examTimerEnabled = examTimerEnabled
        self.language = language
        self.theme = theme
        self.archivedLessonProgressData = archivedLessonProgressData
        self.archivedLessonQuizAttemptsData = archivedLessonQuizAttemptsData
    }
}

struct StoredExamTimer: Codable {
    let enabled: Bool
    let secondsAllowed: Int?
    let secondsElapsed: Int
}

struct StoredExamScore: Codable {
    let bankId: String
    let correct: Int
    let total: Int
    let percent: Double
    let passed: Bool
    let honours: Bool
    let categoryBreakdown: [String]
    let weakSubsectionIds: [String]
}

struct StoredExamAttempt: Codable {
    let id: String
    let bankId: String
    let mode: String
    let seed: String
    let startedAt: String
    let submittedAt: String
    let timer: StoredExamTimer
    let items: [String]
    let score: StoredExamScore
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "fixtures/progress/pre-v2/Progress.store")
try? FileManager.default.removeItem(at: outputURL)
try? FileManager.default.removeItem(at: URL(fileURLWithPath: outputURL.path + "-shm"))
try? FileManager.default.removeItem(at: URL(fileURLWithPath: outputURL.path + "-wal"))
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

let schema = Schema([QuestionProgressEntity.self, ExamAttemptEntity.self, PreferencesEntity.self])
let configuration = ModelConfiguration(schema: schema, url: outputURL, cloudKitDatabase: .none)
let container = try ModelContainer(for: schema, configurations: [configuration])
let context = ModelContext(container)
let encoder = JSONEncoder()

context.insert(QuestionProgressEntity(
    questionId: "B-001-001-001",
    bankId: "basic-2025-07-15",
    attempts: 2,
    correctAttempts: 1,
    lastAttemptedAt: "2026-01-02T03:04:05.000Z",
    lastResult: "correct",
    recentResultsData: try encoder.encode([false, true]),
    leitnerBox: 1,
    dueAt: "2026-01-03T03:04:05.000Z",
    notes: "pre-v2 fixture"
))
let attempt = StoredExamAttempt(
    id: "fixture-attempt-1",
    bankId: "basic-2025-07-15",
    mode: "mock-exam",
    seed: "pre-v2-fixture",
    startedAt: "2026-01-02T03:04:05.000Z",
    submittedAt: "2026-01-02T04:04:05.000Z",
    timer: StoredExamTimer(enabled: false, secondsAllowed: nil, secondsElapsed: 0),
    items: [],
    score: StoredExamScore(bankId: "basic-2025-07-15", correct: 0, total: 0, percent: 0, passed: false, honours: false, categoryBreakdown: [], weakSubsectionIds: [])
)
context.insert(ExamAttemptEntity(id: attempt.id, bankId: attempt.bankId, seed: attempt.seed, startedAt: attempt.startedAt, submittedAt: attempt.submittedAt, payloadData: try encoder.encode(attempt)))
context.insert(PreferencesEntity(
    practiceMode: "review-later",
    examTimerEnabled: true,
    language: "fr",
    theme: "dark",
    archivedLessonProgressData: Data(#"[{"lessonId":"L-005-01","readAt":"2026-01-02T03:30:00.000Z","readCount":2}]"#.utf8),
    archivedLessonQuizAttemptsData: Data("[]".utf8)
))
try context.save()
print("Wrote \(outputURL.path)")
