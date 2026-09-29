public struct ScoreInputItem: Codable, Equatable, Sendable {
    public let questionId: String
    public let categoryId: String?
    public let subsectionId: String?
    public let selectedSourceIndex: Int?

    public init(questionId: String, categoryId: String? = nil, subsectionId: String? = nil, selectedSourceIndex: Int?) {
        self.questionId = questionId
        self.categoryId = categoryId
        self.subsectionId = subsectionId
        self.selectedSourceIndex = selectedSourceIndex
    }
}

public struct CategoryBreakdownEntry: Codable, Equatable, Sendable {
    public let categoryId: String
    public let correct: Int
    public let total: Int
    public let percent: Double

    public init(categoryId: String, correct: Int, total: Int, percent: Double) {
        self.categoryId = categoryId
        self.correct = correct
        self.total = total
        self.percent = percent
    }
}

public struct ExamScore: Codable, Equatable, Sendable {
    public let correct: Int
    public let total: Int
    public let percent: Double
    public let passed: Bool
    public let honours: Bool
    public let categoryBreakdown: [CategoryBreakdownEntry]
    public let incorrectQuestionIds: [String]
    public let weakSubsectionIds: [String]

    public init(
        correct: Int,
        total: Int,
        percent: Double,
        passed: Bool,
        honours: Bool,
        categoryBreakdown: [CategoryBreakdownEntry],
        incorrectQuestionIds: [String],
        weakSubsectionIds: [String]
    ) {
        self.correct = correct
        self.total = total
        self.percent = percent
        self.passed = passed
        self.honours = honours
        self.categoryBreakdown = categoryBreakdown
        self.incorrectQuestionIds = incorrectQuestionIds
        self.weakSubsectionIds = weakSubsectionIds
    }
}

public func scoreExam(_ items: [ScoreInputItem]) -> ExamScore {
    var categoryTotals: [String: (correct: Int, total: Int)] = [:]
    var incorrectQuestionIds: [String] = []
    var weakSubsectionIds = Set<String>()
    var correct = 0

    for item in items {
        let categoryId = item.categoryId ?? categoryIdFromQuestionId(item.questionId)
        let subsectionId = item.subsectionId ?? subsectionIdFromQuestionId(item.questionId)
        let isCorrect = item.selectedSourceIndex == 0
        if isCorrect {
            correct += 1
        } else {
            incorrectQuestionIds.append(item.questionId)
            weakSubsectionIds.insert(subsectionId)
        }

        var entry = categoryTotals[categoryId] ?? (correct: 0, total: 0)
        entry.total += 1
        if isCorrect {
            entry.correct += 1
        }
        categoryTotals[categoryId] = entry
    }

    let total = items.count
    let percent = percentFor(correct: correct, total: total)
    let breakdown = categoryTotals.keys.sorted(by: OrdinalSort.ascending).map { categoryId in
        let value = categoryTotals[categoryId]!
        return CategoryBreakdownEntry(
            categoryId: categoryId,
            correct: value.correct,
            total: value.total,
            percent: percentFor(correct: value.correct, total: value.total)
        )
    }

    return ExamScore(
        correct: correct,
        total: total,
        percent: percent,
        passed: percent >= 70,
        honours: percent >= 80,
        categoryBreakdown: breakdown,
        incorrectQuestionIds: incorrectQuestionIds,
        weakSubsectionIds: Array(weakSubsectionIds).sorted(by: OrdinalSort.ascending)
    )
}

public func percentFor(correct: Int, total: Int) -> Double {
    if total == 0 {
        return 0
    }
    return (Double(correct) / Double(total)) * 100
}
