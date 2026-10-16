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
    public let lastAnsweredWithHelp: Bool
    public let recentResults: [Bool]
    public let recentAnsweredWithHelp: [Bool]
    public let leitner: LeitnerState
    public let notes: String?

    private enum CodingKeys: String, CodingKey {
        case questionId
        case bankId
        case attempts
        case correctAttempts
        case lastAttemptedAt
        case lastResult
        case lastAnsweredWithHelp
        case recentResults
        case recentAnsweredWithHelp
        case leitner
        case notes
    }

    public init(
        questionId: String,
        bankId: String,
        attempts: Int,
        correctAttempts: Int,
        lastAttemptedAt: String,
        lastResult: AnswerResult,
        lastAnsweredWithHelp: Bool = false,
        recentResults: [Bool],
        recentAnsweredWithHelp: [Bool]? = nil,
        leitner: LeitnerState,
        notes: String? = nil
    ) {
        self.questionId = questionId
        self.bankId = bankId
        self.attempts = attempts
        self.correctAttempts = correctAttempts
        self.lastAttemptedAt = lastAttemptedAt
        self.lastResult = lastResult
        self.lastAnsweredWithHelp = lastAnsweredWithHelp
        self.recentResults = recentResults
        self.recentAnsweredWithHelp = recentAnsweredWithHelp ?? Array(repeating: false, count: recentResults.count)
        self.leitner = leitner
        self.notes = notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decode(String.self, forKey: .questionId)
        bankId = try container.decodeIfPresent(String.self, forKey: .bankId) ?? basicBankId
        attempts = try container.decode(Int.self, forKey: .attempts)
        correctAttempts = try container.decode(Int.self, forKey: .correctAttempts)
        lastAttemptedAt = try container.decode(String.self, forKey: .lastAttemptedAt)
        lastResult = try container.decode(AnswerResult.self, forKey: .lastResult)
        lastAnsweredWithHelp = try container.decodeIfPresent(Bool.self, forKey: .lastAnsweredWithHelp) ?? false
        recentResults = try container.decode([Bool].self, forKey: .recentResults)
        recentAnsweredWithHelp = try container.decodeIfPresent([Bool].self, forKey: .recentAnsweredWithHelp) ?? Array(repeating: false, count: recentResults.count)
        leitner = try container.decode(LeitnerState.self, forKey: .leitner)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(questionId, forKey: .questionId)
        try container.encode(bankId, forKey: .bankId)
        try container.encode(attempts, forKey: .attempts)
        try container.encode(correctAttempts, forKey: .correctAttempts)
        try container.encode(lastAttemptedAt, forKey: .lastAttemptedAt)
        try container.encode(lastResult, forKey: .lastResult)
        try container.encode(lastAnsweredWithHelp, forKey: .lastAnsweredWithHelp)
        try container.encode(recentResults, forKey: .recentResults)
        try container.encode(recentAnsweredWithHelp, forKey: .recentAnsweredWithHelp)
        try container.encode(leitner, forKey: .leitner)
        if let notes {
            try container.encode(notes, forKey: .notes)
        } else {
            try container.encodeNil(forKey: .notes)
        }
    }
}

public struct AnswerUpdate: Codable, Equatable, Sendable {
    public let questionId: String
    public let bankId: String
    public let isCorrect: Bool
    public let now: String
    public let answeredWithHelp: Bool

    private enum CodingKeys: String, CodingKey {
        case questionId
        case bankId
        case isCorrect
        case now
        case answeredWithHelp
    }

    public init(questionId: String, bankId: String, isCorrect: Bool, now: String, answeredWithHelp: Bool = false) {
        self.questionId = questionId
        self.bankId = bankId
        self.isCorrect = isCorrect
        self.now = now
        self.answeredWithHelp = answeredWithHelp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try container.decode(String.self, forKey: .questionId)
        bankId = try container.decode(String.self, forKey: .bankId)
        isCorrect = try container.decode(Bool.self, forKey: .isCorrect)
        now = try container.decode(String.self, forKey: .now)
        answeredWithHelp = try container.decodeIfPresent(Bool.self, forKey: .answeredWithHelp) ?? false
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
    guard (0...5).contains(previousBox) else {
        throw EngineError("leitner.box out of range: \(previousBox)")
    }
    let givesMasteryCredit = update.isCorrect && !update.answeredWithHelp
    let nextBox = givesMasteryCredit ? min(previousBox + 1, 5) : 0
    let dueAt: String
    if givesMasteryCredit {
        guard let interval = leitnerIntervalsByBox[nextBox] else {
            throw EngineError("leitner.box out of range: \(nextBox)")
        }
        dueAt = try CanonicalTimestamp.addSeconds(update.now, seconds: interval, fieldName: "update.now")
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
        lastAnsweredWithHelp: update.answeredWithHelp,
        recentResults: appendRecentResult(existing?.recentResults ?? [], newest: update.isCorrect),
        recentAnsweredWithHelp: appendRecentResult(existing?.recentAnsweredWithHelp ?? [], newest: update.answeredWithHelp),
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
        for (index, result) in record.recentResults.enumerated() {
            current.total += 1
            if result, record.recentAnsweredWithHelp.indices.contains(index), !record.recentAnsweredWithHelp[index] {
                current.correct += 1
            } else if result, !record.recentAnsweredWithHelp.indices.contains(index) {
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
