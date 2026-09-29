private let secondsPerDay = 86_400
private let leitnerIntervalsByBox = [
    1: 1 * secondsPerDay,
    2: 3 * secondsPerDay,
    3: 7 * secondsPerDay,
    4: 14 * secondsPerDay,
    5: 30 * secondsPerDay,
]

public struct LeitnerState: Codable, Equatable, Sendable {
    public let box: Int
    public let dueAt: String

    public init(box: Int, dueAt: String) {
        self.box = box
        self.dueAt = dueAt
    }
}

public enum AnswerResult: String, Codable, Equatable, Sendable {
    case correct
    case incorrect
}

public struct QuestionProgressRecord: Codable, Equatable, Sendable {
    public let questionId: String
    public let bankId: String
    public let attempts: Int
    public let correctAttempts: Int
    public let lastAttemptedAt: String
    public let lastResult: AnswerResult
    public let recentResults: [Bool]
    public let leitner: LeitnerState
    public let notes: String?

    public init(
        questionId: String,
        bankId: String,
        attempts: Int,
        correctAttempts: Int,
        lastAttemptedAt: String,
        lastResult: AnswerResult,
        recentResults: [Bool],
        leitner: LeitnerState,
        notes: String? = nil
    ) {
        self.questionId = questionId
        self.bankId = bankId
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.lastAttemptedAt = lastAttemptedAt
        self.lastResult = lastResult
        self.recentResults = recentResults
        self.leitner = leitner
        self.notes = notes
    }
}

public struct AnswerUpdate: Codable, Equatable, Sendable {
    public let questionId: String
    public let bankId: String
    public let isCorrect: Bool
    public let now: String

    public init(questionId: String, bankId: String, isCorrect: Bool, now: String) {
        self.questionId = questionId
        self.bankId = bankId
        self.isCorrect = isCorrect
        self.now = now
    }
}

public struct LatestExamResultItem: Codable, Equatable, Sendable {
    public let questionId: String
    public let subsectionId: String?
    public let selectedSourceIndex: Int?

    public init(questionId: String, subsectionId: String? = nil, selectedSourceIndex: Int?) {
        self.questionId = questionId
        self.subsectionId = subsectionId
        self.selectedSourceIndex = selectedSourceIndex
    }
}

public func applyAnswer(existing: QuestionProgressRecord?, update: AnswerUpdate) throws -> QuestionProgressRecord {
    try CanonicalTimestamp.require(update.now, fieldName: "update.now")
    let previousBox = existing?.leitner.box ?? 0
    let nextBox = update.isCorrect ? min(previousBox + 1, 5) : 0
    let dueAt: String
    if update.isCorrect {
        dueAt = try CanonicalTimestamp.addSeconds(update.now, seconds: leitnerIntervalsByBox[nextBox]!, fieldName: "update.now")
    } else {
        dueAt = update.now
    }

    return QuestionProgressRecord(
        questionId: update.questionId,
        bankId: update.bankId,
        attempts: (existing?.attempts ?? 0) + 1,
        correctAttempts: (existing?.correctAttempts ?? 0) + (update.isCorrect ? 1 : 0),
        lastAttemptedAt: update.now,
        lastResult: update.isCorrect ? .correct : .incorrect,
        recentResults: appendRecentResult(existing?.recentResults ?? [], newest: update.isCorrect),
        leitner: LeitnerState(box: nextBox, dueAt: dueAt),
        notes: existing?.notes ?? nil
    )
}

public func applyAnswerSequence(initialRecords: [QuestionProgressRecord], updates: [AnswerUpdate]) throws -> [QuestionProgressRecord] {
    var byQuestionId: [String: QuestionProgressRecord] = [:]
    for record in initialRecords {
        byQuestionId[record.questionId] = record
    }
    for update in updates {
        byQuestionId[update.questionId] = try applyAnswer(existing: byQuestionId[update.questionId], update: update)
    }
    return byQuestionId.values.sorted { OrdinalSort.ascending($0.questionId, $1.questionId) }
}

public func appendRecentResult(_ existing: [Bool], newest: Bool) -> [Bool] {
    let combined = existing + [newest]
    if combined.count <= 5 {
        return combined
    }
    return Array(combined.suffix(5))
}

public func isDue(_ record: QuestionProgressRecord, now: String) throws -> Bool {
    try CanonicalTimestamp.epochMilliseconds(record.leitner.dueAt, fieldName: "record.leitner.dueAt") <= CanonicalTimestamp.epochMilliseconds(now, fieldName: "now")
}

public func dueQuestionIds(records: [QuestionProgressRecord], now: String) throws -> [String] {
    var dueIds: [String] = []
    for record in records {
        if try isDue(record, now: now) {
            dueIds.append(record.questionId)
        }
    }
    return dueIds.sorted(by: OrdinalSort.ascending)
}

public func dueCount(records: [QuestionProgressRecord], now: String) throws -> Int {
    try dueQuestionIds(records: records, now: now).count
}

public func weakSubsectionIds(records: [QuestionProgressRecord], latestExamItems: [LatestExamResultItem] = []) -> [String] {
    var subsectionAttempts: [String: (correct: Int, total: Int)] = [:]
    for record in records {
        let subsectionId = subsectionIdFromQuestionId(record.questionId)
        var current = subsectionAttempts[subsectionId] ?? (correct: 0, total: 0)
        for result in record.recentResults {
            current.total += 1
            if result {
                current.correct += 1
            }
        }
        subsectionAttempts[subsectionId] = current
    }

    var weak = Set<String>()
    for (subsectionId, attempts) in subsectionAttempts {
        if attempts.total >= 2, Double(attempts.correct) / Double(attempts.total) < 0.7 {
            weak.insert(subsectionId)
        }
    }

    for item in latestExamItems {
        if item.selectedSourceIndex != 0 {
            weak.insert(item.subsectionId ?? subsectionIdFromQuestionId(item.questionId))
        }
    }

    return Array(weak).sorted(by: OrdinalSort.ascending)
}
