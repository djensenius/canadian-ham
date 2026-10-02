public enum ReadinessState: String, Codable, Equatable, Sendable {
    case notEnoughData = "not-enough-data"
    case needsReview = "needs-review"
    case passReady = "pass-ready"
    case honoursReady = "honours-ready"
}

public struct ReadinessScore: Codable, Equatable, Sendable {
    public let correct: Int
    public let total: Int
    public let percent: Double?

    public init(correct: Int, total: Int, percent: Double? = nil) {
        self.correct = correct
        self.total = total
        self.percent = percent
    }
}

public struct ReadinessExamAttempt: Codable, Equatable, Sendable {
    public let submittedAt: String
    public let score: ReadinessScore
    public let categoryBreakdown: [CategoryBreakdownEntry]

    public init(submittedAt: String, score: ReadinessScore, categoryBreakdown: [CategoryBreakdownEntry]) {
        self.submittedAt = submittedAt
        self.score = score
        self.categoryBreakdown = categoryBreakdown
    }
}

public struct ReadinessInput: Codable, Equatable, Sendable {
    public let bankId: String?
    public let completedExams: [ReadinessExamAttempt]
    public let dueReviewCount: Int

    public init(bankId: String? = nil, completedExams: [ReadinessExamAttempt], dueReviewCount: Int) {
        self.bankId = bankId
        self.completedExams = completedExams
        self.dueReviewCount = dueReviewCount
    }
}

public struct ReadinessResult: Codable, Equatable, Sendable {
    public let state: ReadinessState
    public let consideredExamCount: Int
    public let consideredSubmittedAt: [String]
    public let reasons: [ReadinessReason]

    public init(state: ReadinessState, consideredExamCount: Int, consideredSubmittedAt: [String], reasons: [ReadinessReason]) {
        self.state = state
        self.consideredExamCount = consideredExamCount
        self.consideredSubmittedAt = consideredSubmittedAt
        self.reasons = reasons
    }
}

public enum ReadinessReason: Codable, Equatable, Sendable {
    case notEnoughExams(completedExamCount: Int)
    case weakCategories(categoryIds: [String])
    case dueReview(dueReviewCount: Int)
    case examThreshold(threshold: Int, countAtOrAbove: Int)

    private enum CodingKeys: String, CodingKey {
        case type
        case completedExamCount
        case categoryIds
        case dueReviewCount
        case threshold
        case countAtOrAbove
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "not-enough-exams":
            self = .notEnoughExams(completedExamCount: try container.decode(Int.self, forKey: .completedExamCount))
        case "weak-categories":
            self = .weakCategories(categoryIds: try container.decode([String].self, forKey: .categoryIds))
        case "due-review":
            self = .dueReview(dueReviewCount: try container.decode(Int.self, forKey: .dueReviewCount))
        case "exam-threshold":
            self = .examThreshold(
                threshold: try container.decode(Int.self, forKey: .threshold),
                countAtOrAbove: try container.decode(Int.self, forKey: .countAtOrAbove)
            )
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "unsupported readiness reason type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .notEnoughExams(completedExamCount):
            try container.encode("not-enough-exams", forKey: .type)
            try container.encode(completedExamCount, forKey: .completedExamCount)
        case let .weakCategories(categoryIds):
            try container.encode("weak-categories", forKey: .type)
            try container.encode(categoryIds, forKey: .categoryIds)
        case let .dueReview(dueReviewCount):
            try container.encode("due-review", forKey: .type)
            try container.encode(dueReviewCount, forKey: .dueReviewCount)
        case let .examThreshold(threshold, countAtOrAbove):
            try container.encode("exam-threshold", forKey: .type)
            try container.encode(threshold, forKey: .threshold)
            try container.encode(countAtOrAbove, forKey: .countAtOrAbove)
        }
    }
}

public func computeReadiness(_ input: ReadinessInput) throws -> ReadinessResult {
    let bankRules = try rulesForBankId(input.bankId ?? basicBankId)
    try assertUniqueSubmittedAt(input.completedExams)
    let completed = try input.completedExams.sorted { lhs, rhs in
        try CanonicalTimestamp.epochMilliseconds(lhs.submittedAt, fieldName: "submittedAt") > CanonicalTimestamp.epochMilliseconds(rhs.submittedAt, fieldName: "submittedAt")
    }

    if completed.count < 2 {
        return ReadinessResult(
            state: .notEnoughData,
            consideredExamCount: completed.count,
            consideredSubmittedAt: completed.map(\.submittedAt),
            reasons: [.notEnoughExams(completedExamCount: completed.count)]
        )
    }

    let considered = Array(completed.prefix(3))
    let weakCategories = aggregateWeakCategories(considered)
    if !weakCategories.isEmpty {
        return ReadinessResult(
            state: .needsReview,
            consideredExamCount: considered.count,
            consideredSubmittedAt: considered.map(\.submittedAt),
            reasons: [.weakCategories(categoryIds: weakCategories)]
        )
    }

    if input.dueReviewCount >= 5 {
        return ReadinessResult(
            state: .needsReview,
            consideredExamCount: considered.count,
            consideredSubmittedAt: considered.map(\.submittedAt),
            reasons: [.dueReview(dueReviewCount: input.dueReviewCount)]
        )
    }

    if bankRules.hasHonours, let honoursPercent = bankRules.honoursPercent {
        let honoursCount = considered.filter { scorePercent($0) >= honoursPercent }.count
        if honoursCount >= 2 {
            return ReadinessResult(
                state: .honoursReady,
                consideredExamCount: considered.count,
                consideredSubmittedAt: considered.map(\.submittedAt),
                reasons: [.examThreshold(threshold: 80, countAtOrAbove: honoursCount)]
            )
        }
    }

    let passCount = considered.filter { scorePercent($0) >= bankRules.passPercent }.count
    if passCount >= 2 {
        return ReadinessResult(
            state: .passReady,
            consideredExamCount: considered.count,
            consideredSubmittedAt: considered.map(\.submittedAt),
            reasons: [.examThreshold(threshold: 70, countAtOrAbove: passCount)]
        )
    }

    return ReadinessResult(
        state: .needsReview,
        consideredExamCount: considered.count,
        consideredSubmittedAt: considered.map(\.submittedAt),
        reasons: []
    )
}

private func assertUniqueSubmittedAt(_ attempts: [ReadinessExamAttempt]) throws {
    var seen = Set<String>()
    for attempt in attempts {
        try CanonicalTimestamp.require(attempt.submittedAt, fieldName: "submittedAt")
        if seen.contains(attempt.submittedAt) {
            throw EngineError("completedExams must not contain duplicate submittedAt timestamp \(attempt.submittedAt)")
        }
        seen.insert(attempt.submittedAt)
    }
}

private func aggregateWeakCategories(_ attempts: [ReadinessExamAttempt]) -> [String] {
    var aggregate: [String: (correct: Int, total: Int)] = [:]
    for attempt in attempts {
        for category in attempt.categoryBreakdown {
            var current = aggregate[category.categoryId] ?? (correct: 0, total: 0)
            current.correct += category.correct
            current.total += category.total
            aggregate[category.categoryId] = current
        }
    }

    return aggregate.keys
        .filter { categoryId in
            let value = aggregate[categoryId]!
            return value.total > 0 && percentFor(correct: value.correct, total: value.total) < 70
        }
        .sorted(by: OrdinalSort.ascending)
}

private func scorePercent(_ attempt: ReadinessExamAttempt) -> Double {
    attempt.score.percent ?? percentFor(correct: attempt.score.correct, total: attempt.score.total)
}
