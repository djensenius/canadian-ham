import CanadianHamEngine
import CanadianHamMorseEngine
import Foundation

enum ProgressSyncMerge {
    static func deduplicateQuestionProgress(_ records: [QuestionProgressRecord]) -> [QuestionProgressRecord] {
        Dictionary(grouping: records, by: { "\($0.bankId)\u{0}\($0.questionId)" })
            .values
            .map(mergeQuestionProgress)
            .sorted { lhs, rhs in
                if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
                return lhs.questionId < rhs.questionId
            }
    }

    static func mergeQuestionProgress(_ records: [QuestionProgressRecord]) -> QuestionProgressRecord {
        precondition(!records.isEmpty)
        let ordered = records.sorted(by: questionProgressTieBreak)
        let latest = ordered.last!
        let recentResults = ordered.flatMap { $0.recentResults }.suffix(5)
        let notes = ordered.compactMap { $0.notes }.last
        return QuestionProgressRecord(
            questionId: latest.questionId,
            bankId: latest.bankId,
            attempts: records.map(\.attempts).reduce(0, +),
            correctAttempts: records.map(\.correctAttempts).reduce(0, +),
            lastAttemptedAt: latest.lastAttemptedAt,
            lastResult: latest.lastResult,
            recentResults: Array(recentResults),
            leitner: latest.leitner,
            notes: notes
        )
    }

    static func deduplicateExamAttempts(_ attempts: [StoredExamAttempt]) -> [StoredExamAttempt] {
        let byIdentity = Dictionary(grouping: attempts, by: { "\($0.bankId)\u{0}\($0.id)" })
            .values
            .map { group in group.sorted(by: examAttemptTieBreak).last! }
            .sorted(by: examAttemptTieBreak)
        var usedSubmittedAtByBank: [String: Set<String>] = [:]
        return byIdentity.map { attempt in
            var used = usedSubmittedAtByBank[attempt.bankId, default: []]
            let uniqueSubmittedAt = uniqueTimestamp(attempt.submittedAt, used: used)
            used.insert(uniqueSubmittedAt)
            usedSubmittedAtByBank[attempt.bankId] = used
            guard uniqueSubmittedAt != attempt.submittedAt else { return attempt }
            return StoredExamAttempt(
                id: attempt.id,
                bankId: attempt.bankId,
                mode: attempt.mode,
                seed: attempt.seed,
                startedAt: attempt.startedAt,
                submittedAt: uniqueSubmittedAt,
                timer: attempt.timer,
                items: attempt.items,
                score: attempt.score
            )
        }
    }

    static func deduplicateLessonProgress(_ records: [LessonProgressRecord]) -> [LessonProgressRecord] {
        Dictionary(grouping: records, by: \.lessonId).values.map { group in
            let ordered = group.sorted { lhs, rhs in
                if lhs.readAt != rhs.readAt { return lhs.readAt < rhs.readAt }
                return lhs.readCount < rhs.readCount
            }
            let latest = ordered.last!
            return LessonProgressRecord(
                lessonId: latest.lessonId,
                readAt: latest.readAt,
                readCount: group.map(\.readCount).reduce(0, +)
            )
        }
        .sorted { $0.lessonId < $1.lessonId }
    }

    static func deduplicateLessonQuizAttempts(_ attempts: [LessonQuizAttempt]) -> [LessonQuizAttempt] {
        Dictionary(grouping: attempts, by: \.id).values.map { group in
            group.sorted { lhs, rhs in
                if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
                return lhs.id < rhs.id
            }.last!
        }
        .sorted { lhs, rhs in
            if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
            return lhs.id < rhs.id
        }
    }

    static func mergeMorseCourseProgress(_ progress: [MorseCourseProgressExport]) -> MorseCourseProgressExport? {
        guard let first = progress.first else { return nil }
        let lessonProgress = Dictionary(grouping: progress.flatMap(\.lessonProgress), by: \.lessonId).values.map { group in
            let latest = group.sorted { lhs, rhs in
                if lhs.lastAttemptedAt != rhs.lastAttemptedAt { return lhs.lastAttemptedAt < rhs.lastAttemptedAt }
                return lhs.lessonId < rhs.lessonId
            }.last!
            let completedAt = group.compactMap(\.completedAt).min()
            return MorseLessonProgressRecord(
                lessonId: latest.lessonId,
                attempts: group.map(\.attempts).reduce(0, +),
                bestAccuracy: group.map(\.bestAccuracy).max() ?? latest.bestAccuracy,
                lastAccuracy: latest.lastAccuracy,
                lastAttemptedAt: latest.lastAttemptedAt,
                completedAt: completedAt
            )
        }.sorted { $0.lessonId < $1.lessonId }
        let characterStats = Dictionary(grouping: progress.flatMap(\.characterStats), by: \.character).values.map { group in
            let latest = group.sorted { lhs, rhs in
                if lhs.lastPracticedAt != rhs.lastPracticedAt { return lhs.lastPracticedAt < rhs.lastPracticedAt }
                return lhs.character < rhs.character
            }.last!
            return MorseCharacterStatRecord(
                character: latest.character,
                attempts: group.map(\.attempts).reduce(0, +),
                correctAttempts: group.map(\.correctAttempts).reduce(0, +),
                recentResults: Array(group.flatMap(\.recentResults).suffix(5)),
                lastPracticedAt: latest.lastPracticedAt
            )
        }.sorted { $0.character < $1.character }
        let dailyActivity = Dictionary(grouping: progress.flatMap(\.dailyActivity), by: \.date).values.map { group in
            MorseDailyActivityRecord(date: group[0].date, lessonsCompleted: group.map(\.lessonsCompleted).reduce(0, +))
        }.sorted { $0.date < $1.date }
        return MorseCourseProgressExport(courseId: first.courseId, lessonProgress: lessonProgress, characterStats: characterStats, dailyActivity: dailyActivity)
    }

    private static func questionProgressTieBreak(_ lhs: QuestionProgressRecord, _ rhs: QuestionProgressRecord) -> Bool {
        if lhs.lastAttemptedAt != rhs.lastAttemptedAt { return lhs.lastAttemptedAt < rhs.lastAttemptedAt }
        if lhs.leitner.dueAt != rhs.leitner.dueAt { return lhs.leitner.dueAt < rhs.leitner.dueAt }
        if lhs.lastResult != rhs.lastResult { return lhs.lastResult.rawValue < rhs.lastResult.rawValue }
        return (lhs.notes ?? "") < (rhs.notes ?? "")
    }

    private static func examAttemptTieBreak(_ lhs: StoredExamAttempt, _ rhs: StoredExamAttempt) -> Bool {
        if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
        if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
        return lhs.id < rhs.id
    }

    private static func uniqueTimestamp(_ timestamp: String, used: Set<String>) -> String {
        guard used.contains(timestamp) else { return timestamp }
        guard let dot = timestamp.lastIndex(of: "."), timestamp.hasSuffix("Z"),
              let milliseconds = Int(timestamp[timestamp.index(after: dot)..<timestamp.index(before: timestamp.endIndex)])
        else { return timestamp }
        let prefix = timestamp[..<timestamp.index(after: dot)]
        for offset in 1...999 {
            let candidateMilliseconds = (milliseconds + offset) % 1000
            let candidate = "\(prefix)\(String(format: "%03d", candidateMilliseconds))Z"
            if !used.contains(candidate) { return candidate }
        }
        return timestamp
    }
}
