import CanadianHamEngine
import CanadianHamMorseEngine
import Foundation

struct DeviceQuestionProgressRecord: Codable, Equatable, Sendable {
    let deviceId: String
    let record: QuestionProgressRecord
}

struct DeviceExamAttemptRecord: Codable, Equatable, Sendable {
    let deviceId: String
    let attempt: StoredExamAttempt
}

struct DeviceLessonProgressRecord: Codable, Equatable, Sendable {
    let deviceId: String
    let record: LessonProgressRecord
}

struct DeviceLessonQuizAttemptRecord: Codable, Equatable, Sendable {
    let deviceId: String
    let attempt: LessonQuizAttempt
}

struct DeviceMorseCourseProgressRecord: Codable, Equatable, Sendable {
    let deviceId: String
    let progress: MorseCourseProgressExport
}

struct ProgressSyncDeviceRows: Codable, Equatable, Sendable {
    var questionProgress: [DeviceQuestionProgressRecord]
    var examAttempts: [DeviceExamAttemptRecord]
    var lessonProgress: [DeviceLessonProgressRecord]
    var lessonQuizAttempts: [DeviceLessonQuizAttemptRecord]
    var morseCourseProgress: [DeviceMorseCourseProgressRecord]

    static let empty = ProgressSyncDeviceRows(
        questionProgress: [],
        examAttempts: [],
        lessonProgress: [],
        lessonQuizAttempts: [],
        morseCourseProgress: []
    )
}

enum ProgressSyncMerge {
    static func deduplicateQuestionProgress(_ records: [QuestionProgressRecord]) -> [QuestionProgressRecord] {
        deduplicateDeviceQuestionProgress(records.map { DeviceQuestionProgressRecord(deviceId: "local", record: $0) })
    }

    static func deduplicateDeviceQuestionProgress(_ rows: [DeviceQuestionProgressRecord]) -> [QuestionProgressRecord] {
        Dictionary(grouping: rows, by: { "\($0.record.bankId)\u{0}\($0.record.questionId)" })
            .values
            .map(mergeDeviceQuestionProgress)
            .sorted { lhs, rhs in
                if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
                return lhs.questionId < rhs.questionId
            }
    }

    static func mergeQuestionProgress(_ records: [QuestionProgressRecord]) -> QuestionProgressRecord {
        mergeDeviceQuestionProgress(records.map { DeviceQuestionProgressRecord(deviceId: "local", record: $0) })
    }

    static func mergeDeviceQuestionProgress(_ rows: [DeviceQuestionProgressRecord]) -> QuestionProgressRecord {
        precondition(!rows.isEmpty)
        let deviceRows = Dictionary(grouping: rows, by: \.deviceId).values.map { group in
            group.sorted(by: deviceQuestionProgressTieBreak).last!
        }
        let latest = deviceRows.sorted(by: deviceQuestionProgressTieBreak).last!
        return QuestionProgressRecord(
            questionId: latest.record.questionId,
            bankId: latest.record.bankId,
            attempts: deviceRows.map(\.record.attempts).reduce(0, +),
            correctAttempts: deviceRows.map(\.record.correctAttempts).reduce(0, +),
            lastAttemptedAt: latest.record.lastAttemptedAt,
            lastResult: latest.record.lastResult,
            lastAnsweredWithHelp: latest.record.lastAnsweredWithHelp,
            recentResults: Array(latest.record.recentResults.suffix(5)),
            recentAnsweredWithHelp: Array(latest.record.recentAnsweredWithHelp.suffix(5)),
            leitner: latest.record.leitner,
            notes: latest.record.notes
        )
    }

    static func deduplicateExamAttempts(_ attempts: [StoredExamAttempt]) -> [StoredExamAttempt] {
        deduplicateDeviceExamAttempts(attempts.map { DeviceExamAttemptRecord(deviceId: "local", attempt: $0) })
    }

    static func deduplicateDeviceExamAttempts(_ rows: [DeviceExamAttemptRecord]) -> [StoredExamAttempt] {
        Dictionary(grouping: rows, by: { "\($0.attempt.bankId)\u{0}\($0.attempt.submittedAt)" })
            .values
            .map { group in group.sorted(by: deviceExamAttemptTieBreak).last!.attempt }
            .sorted(by: examAttemptTieBreak)
    }

    static func deduplicateLessonProgress(_ records: [LessonProgressRecord]) -> [LessonProgressRecord] {
        deduplicateDeviceLessonProgress(records.map { DeviceLessonProgressRecord(deviceId: "local", record: $0) })
    }

    static func deduplicateDeviceLessonProgress(_ rows: [DeviceLessonProgressRecord]) -> [LessonProgressRecord] {
        Dictionary(grouping: rows, by: \.record.lessonId).values.map { group in
            let deviceRows = Dictionary(grouping: group, by: \.deviceId).values.map { deviceGroup in
                deviceGroup.sorted(by: deviceLessonProgressTieBreak).last!
            }
            let latest = deviceRows.sorted(by: deviceLessonProgressTieBreak).last!
            return LessonProgressRecord(
                lessonId: latest.record.lessonId,
                readAt: latest.record.readAt,
                readCount: deviceRows.map(\.record.readCount).reduce(0, +)
            )
        }
        .sorted { $0.lessonId < $1.lessonId }
    }

    static func deduplicateLessonQuizAttempts(_ attempts: [LessonQuizAttempt]) -> [LessonQuizAttempt] {
        deduplicateDeviceLessonQuizAttempts(attempts.map { DeviceLessonQuizAttemptRecord(deviceId: "local", attempt: $0) })
    }

    static func deduplicateDeviceLessonQuizAttempts(_ rows: [DeviceLessonQuizAttemptRecord]) -> [LessonQuizAttempt] {
        Dictionary(grouping: rows, by: \.attempt.id).values.map { group in
            group.sorted(by: deviceLessonQuizAttemptTieBreak).last!.attempt
        }
        .sorted { lhs, rhs in
            if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
            return lhs.id < rhs.id
        }
    }

    static func mergeMorseCourseProgress(_ progress: [MorseCourseProgressExport]) -> MorseCourseProgressExport? {
        mergeDeviceMorseCourseProgress(progress.map { DeviceMorseCourseProgressRecord(deviceId: "local", progress: $0) })
    }

    static func mergeDeviceMorseCourseProgress(_ rows: [DeviceMorseCourseProgressRecord]) -> MorseCourseProgressExport? {
        guard !rows.isEmpty else { return nil }
        let deviceRows = Dictionary(grouping: rows, by: \.deviceId).values.compactMap { group -> DeviceMorseCourseProgressRecord? in
            guard let merged = mergeMorseRowsForSingleDevice(group) else { return nil }
            return DeviceMorseCourseProgressRecord(deviceId: group[0].deviceId, progress: merged)
        }
        guard let first = deviceRows.sorted(by: deviceMorseCourseTieBreak).last else { return nil }
        let lessonProgress = Dictionary(grouping: deviceRows.flatMap { row in row.progress.lessonProgress.map { (row.deviceId, $0) } }, by: { $0.1.lessonId }).values.map { group in
            let latest = group.sorted(by: morseLessonProgressTieBreak).last!
            return MorseLessonProgressRecord(
                lessonId: latest.1.lessonId,
                attempts: group.map { $0.1.attempts }.reduce(0, +),
                bestAccuracy: group.map { $0.1.bestAccuracy }.max() ?? latest.1.bestAccuracy,
                lastAccuracy: latest.1.lastAccuracy,
                lastAttemptedAt: latest.1.lastAttemptedAt,
                completedAt: group.compactMap { $0.1.completedAt }.min()
            )
        }.sorted { $0.lessonId < $1.lessonId }
        let characterStats = Dictionary(grouping: deviceRows.flatMap { row in row.progress.characterStats.map { (row.deviceId, $0) } }, by: { $0.1.character }).values.map { group in
            let latest = group.sorted(by: morseCharacterStatTieBreak).last!
            return MorseCharacterStatRecord(
                character: latest.1.character,
                attempts: group.map { $0.1.attempts }.reduce(0, +),
                correctAttempts: group.map { $0.1.correctAttempts }.reduce(0, +),
                recentResults: Array(latest.1.recentResults.suffix(20)),
                lastPracticedAt: latest.1.lastPracticedAt
            )
        }.sorted { $0.character < $1.character }
        let dailyActivity = Dictionary(grouping: deviceRows.flatMap { row in row.progress.dailyActivity.map { (row.deviceId, $0) } }, by: { $0.1.date }).values.map { group in
            MorseDailyActivityRecord(date: group[0].1.date, lessonsCompleted: group.map { $0.1.lessonsCompleted }.reduce(0, +))
        }.sorted { $0.date < $1.date }
        return MorseCourseProgressExport(courseId: first.progress.courseId, lessonProgress: lessonProgress, characterStats: characterStats, dailyActivity: dailyActivity)
    }

    private static func mergeMorseRowsForSingleDevice(_ rows: [DeviceMorseCourseProgressRecord]) -> MorseCourseProgressExport? {
        guard let first = rows.sorted(by: deviceMorseCourseTieBreak).last else { return nil }
        let lessonProgress = Dictionary(grouping: rows.flatMap { row in row.progress.lessonProgress.map { (row.deviceId, $0) } }, by: { $0.1.lessonId }).values.map { group in
            let latest = group.sorted(by: morseLessonProgressTieBreak).last!
            return MorseLessonProgressRecord(
                lessonId: latest.1.lessonId,
                attempts: group.map { $0.1.attempts }.max() ?? latest.1.attempts,
                bestAccuracy: group.map { $0.1.bestAccuracy }.max() ?? latest.1.bestAccuracy,
                lastAccuracy: latest.1.lastAccuracy,
                lastAttemptedAt: latest.1.lastAttemptedAt,
                completedAt: group.compactMap { $0.1.completedAt }.min()
            )
        }.sorted { $0.lessonId < $1.lessonId }
        let characterStats = Dictionary(grouping: rows.flatMap { row in row.progress.characterStats.map { (row.deviceId, $0) } }, by: { $0.1.character }).values.map { group in
            let latest = group.sorted(by: morseCharacterStatTieBreak).last!
            return MorseCharacterStatRecord(
                character: latest.1.character,
                attempts: group.map { $0.1.attempts }.max() ?? latest.1.attempts,
                correctAttempts: group.map { $0.1.correctAttempts }.max() ?? latest.1.correctAttempts,
                recentResults: Array(latest.1.recentResults.suffix(20)),
                lastPracticedAt: latest.1.lastPracticedAt
            )
        }.sorted { $0.character < $1.character }
        let dailyActivity = Dictionary(grouping: rows.flatMap { row in row.progress.dailyActivity.map { (row.deviceId, $0) } }, by: { $0.1.date }).values.map { group in
            MorseDailyActivityRecord(date: group[0].1.date, lessonsCompleted: group.map { $0.1.lessonsCompleted }.max() ?? group[0].1.lessonsCompleted)
        }.sorted { $0.date < $1.date }
        return MorseCourseProgressExport(courseId: first.progress.courseId, lessonProgress: lessonProgress, characterStats: characterStats, dailyActivity: dailyActivity)
    }

    private static func deviceQuestionProgressTieBreak(_ lhs: DeviceQuestionProgressRecord, _ rhs: DeviceQuestionProgressRecord) -> Bool {
        let l = lhs.record
        let r = rhs.record
        if l.lastAttemptedAt != r.lastAttemptedAt { return l.lastAttemptedAt < r.lastAttemptedAt }
        if lhs.deviceId != rhs.deviceId { return lhs.deviceId < rhs.deviceId }
        if l.leitner.dueAt != r.leitner.dueAt { return l.leitner.dueAt < r.leitner.dueAt }
        if l.leitner.box != r.leitner.box { return l.leitner.box < r.leitner.box }
        if l.lastResult != r.lastResult { return l.lastResult.rawValue < r.lastResult.rawValue }
        if l.lastAnsweredWithHelp != r.lastAnsweredWithHelp { return !l.lastAnsweredWithHelp && r.lastAnsweredWithHelp }
        let lResults = l.recentResults.map { $0 ? "1" : "0" }.joined()
        let rResults = r.recentResults.map { $0 ? "1" : "0" }.joined()
        if lResults != rResults { return lResults < rResults }
        let lHelp = l.recentAnsweredWithHelp.map { $0 ? "1" : "0" }.joined()
        let rHelp = r.recentAnsweredWithHelp.map { $0 ? "1" : "0" }.joined()
        if lHelp != rHelp { return lHelp < rHelp }
        return (l.notes ?? "") < (r.notes ?? "")
    }

    private static func examAttemptTieBreak(_ lhs: StoredExamAttempt, _ rhs: StoredExamAttempt) -> Bool {
        if lhs.bankId != rhs.bankId { return lhs.bankId < rhs.bankId }
        if lhs.submittedAt != rhs.submittedAt { return lhs.submittedAt < rhs.submittedAt }
        return lhs.id < rhs.id
    }

    private static func deviceExamAttemptTieBreak(_ lhs: DeviceExamAttemptRecord, _ rhs: DeviceExamAttemptRecord) -> Bool {
        if lhs.attempt.bankId != rhs.attempt.bankId { return lhs.attempt.bankId < rhs.attempt.bankId }
        if lhs.attempt.submittedAt != rhs.attempt.submittedAt { return lhs.attempt.submittedAt < rhs.attempt.submittedAt }
        if lhs.deviceId != rhs.deviceId { return lhs.deviceId < rhs.deviceId }
        if lhs.attempt.startedAt != rhs.attempt.startedAt { return lhs.attempt.startedAt < rhs.attempt.startedAt }
        return lhs.attempt.id < rhs.attempt.id
    }

    private static func deviceLessonProgressTieBreak(_ lhs: DeviceLessonProgressRecord, _ rhs: DeviceLessonProgressRecord) -> Bool {
        if lhs.record.readAt != rhs.record.readAt { return lhs.record.readAt < rhs.record.readAt }
        if lhs.deviceId != rhs.deviceId { return lhs.deviceId < rhs.deviceId }
        if lhs.record.readCount != rhs.record.readCount { return lhs.record.readCount < rhs.record.readCount }
        return lhs.record.lessonId < rhs.record.lessonId
    }

    private static func deviceLessonQuizAttemptTieBreak(_ lhs: DeviceLessonQuizAttemptRecord, _ rhs: DeviceLessonQuizAttemptRecord) -> Bool {
        if lhs.attempt.submittedAt != rhs.attempt.submittedAt { return lhs.attempt.submittedAt < rhs.attempt.submittedAt }
        if lhs.deviceId != rhs.deviceId { return lhs.deviceId < rhs.deviceId }
        return lhs.attempt.id < rhs.attempt.id
    }

    private static func deviceMorseCourseTieBreak(_ lhs: DeviceMorseCourseProgressRecord, _ rhs: DeviceMorseCourseProgressRecord) -> Bool {
        if latestMorseTimestamp(lhs.progress) != latestMorseTimestamp(rhs.progress) { return latestMorseTimestamp(lhs.progress) < latestMorseTimestamp(rhs.progress) }
        if lhs.deviceId != rhs.deviceId { return lhs.deviceId < rhs.deviceId }
        return lhs.progress.courseId < rhs.progress.courseId
    }

    private static func morseLessonProgressTieBreak(_ lhs: (String, MorseLessonProgressRecord), _ rhs: (String, MorseLessonProgressRecord)) -> Bool {
        if lhs.1.lastAttemptedAt != rhs.1.lastAttemptedAt { return lhs.1.lastAttemptedAt < rhs.1.lastAttemptedAt }
        if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
        if lhs.1.completedAt != rhs.1.completedAt { return (lhs.1.completedAt ?? "") < (rhs.1.completedAt ?? "") }
        if lhs.1.bestAccuracy != rhs.1.bestAccuracy { return lhs.1.bestAccuracy < rhs.1.bestAccuracy }
        if lhs.1.lastAccuracy != rhs.1.lastAccuracy { return lhs.1.lastAccuracy < rhs.1.lastAccuracy }
        return lhs.1.lessonId < rhs.1.lessonId
    }

    private static func morseCharacterStatTieBreak(_ lhs: (String, MorseCharacterStatRecord), _ rhs: (String, MorseCharacterStatRecord)) -> Bool {
        if lhs.1.lastPracticedAt != rhs.1.lastPracticedAt { return lhs.1.lastPracticedAt < rhs.1.lastPracticedAt }
        if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
        let lResults = lhs.1.recentResults.map { $0 ? "1" : "0" }.joined()
        let rResults = rhs.1.recentResults.map { $0 ? "1" : "0" }.joined()
        if lResults != rResults { return lResults < rResults }
        return lhs.1.character < rhs.1.character
    }

    private static func latestMorseTimestamp(_ progress: MorseCourseProgressExport) -> String {
        ([progress.lessonProgress.map(\.lastAttemptedAt), progress.characterStats.map(\.lastPracticedAt)].flatMap { $0 }).max() ?? ""
    }
}
