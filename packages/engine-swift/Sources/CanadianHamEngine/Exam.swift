public struct RngDescriptor: Codable, Equatable, Sendable {
    public let algorithm: String
    public let seed: String

    public init(algorithm: String, seed: String) {
        self.algorithm = algorithm
        self.seed = seed
    }
}

public struct ExamSubsectionInput: Codable, Equatable, Sendable {
    public let id: String
    public let questionIds: [String]

    public init(id: String, questionIds: [String]) {
        self.id = id
        self.questionIds = questionIds
    }
}

public struct QuestionRecordLike: Codable, Equatable, Sendable {
    public let id: String
    public let categoryId: String
    public let subsectionId: String

    public init(id: String, categoryId: String, subsectionId: String) {
        self.id = id
        self.categoryId = categoryId
        self.subsectionId = subsectionId
    }
}

public struct ExamGenerationInput: Codable, Equatable, Sendable {
    public let bankId: String
    public let seed: String
    public let subsections: [ExamSubsectionInput]
    public let answerSourceIndexes: [Int]?
    public let requireFullMockExam: Bool?

    public init(
        bankId: String,
        seed: String,
        subsections: [ExamSubsectionInput],
        answerSourceIndexes: [Int]? = nil,
        requireFullMockExam: Bool? = nil
    ) {
        self.bankId = bankId
        self.seed = seed
        self.subsections = subsections
        self.answerSourceIndexes = answerSourceIndexes
        self.requireFullMockExam = requireFullMockExam
    }
}

public struct GeneratedExamItem: Codable, Equatable, Sendable {
    public let position: Int
    public let questionId: String
    public let subsectionId: String
    public let categoryId: String
    public let choicePermutation: [Int]

    public init(position: Int, questionId: String, subsectionId: String, categoryId: String, choicePermutation: [Int]) {
        self.position = position
        self.questionId = questionId
        self.subsectionId = subsectionId
        self.categoryId = categoryId
        self.choicePermutation = choicePermutation
    }
}

public struct GeneratedExam: Codable, Equatable, Sendable {
    public let bankId: String
    public let rng: RngDescriptor
    public let items: [GeneratedExamItem]

    public init(bankId: String, rng: RngDescriptor, items: [GeneratedExamItem]) {
        self.bankId = bankId
        self.rng = rng
        self.items = items
    }
}

private struct SelectedExamItem: Sendable {
    let questionId: String
    let subsectionId: String
    let categoryId: String
}

public func categoryIdFromQuestionId(_ questionId: String) -> String {
    String(questionId.prefix(5))
}

public func subsectionIdFromQuestionId(_ questionId: String) -> String {
    String(questionId.prefix(9))
}

public func buildSubsectionsFromQuestions(_ questions: [QuestionRecordLike]) -> [ExamSubsectionInput] {
    var grouped: [String: [String]] = [:]
    for question in questions {
        grouped[question.subsectionId, default: []].append(question.id)
    }
    return grouped.map { id, questionIds in
        ExamSubsectionInput(id: id, questionIds: questionIds.sortedOrdinal())
    }.sorted { OrdinalSort.ascending($0.id, $1.id) }
}

public func generateExam(_ input: ExamGenerationInput) throws -> GeneratedExam {
    let answerSourceIndexes = input.answerSourceIndexes ?? [0, 1, 2, 3]
    guard isCanonicalAnswerSourceIndexes(answerSourceIndexes) else {
        throw EngineError("answerSourceIndexes must be exactly [0,1,2,3]")
    }

    let sortedSubsections = input.subsections.map { subsection in
        ExamSubsectionInput(id: subsection.id, questionIds: subsection.questionIds.sortedOrdinal())
    }.sorted { OrdinalSort.ascending($0.id, $1.id) }

    if input.requireFullMockExam == true {
        let bankRules = try rulesForBankId(input.bankId)
        if sortedSubsections.count != bankRules.subsectionCount {
            throw EngineError("full mock exam generation for \(input.bankId) requires exactly \(bankRules.subsectionCount) subsections; received \(sortedSubsections.count)")
        }
    }

    var uniqueSubsectionIds = Set<String>()
    for subsection in sortedSubsections {
        if uniqueSubsectionIds.contains(subsection.id) {
            throw EngineError("duplicate subsection id \(subsection.id)")
        }
        uniqueSubsectionIds.insert(subsection.id)
        if subsection.questionIds.isEmpty {
            throw EngineError("subsection \(subsection.id) has no questionIds")
        }
    }

    var rng = Pcg32(seed: input.seed)
    var selected: [SelectedExamItem] = []
    selected.reserveCapacity(sortedSubsections.count)
    for subsection in sortedSubsections {
        let selectedIndex = try rng.bounded(subsection.questionIds.count)
        let questionId = subsection.questionIds[selectedIndex]
        selected.append(SelectedExamItem(
            questionId: questionId,
            subsectionId: subsection.id,
            categoryId: categoryIdFromQuestionId(questionId)
        ))
    }

    let ordered = try shuffled(selected, rng: &rng)
    let items = try ordered.enumerated().map { index, item in
        GeneratedExamItem(
            position: index + 1,
            questionId: item.questionId,
            subsectionId: item.subsectionId,
            categoryId: item.categoryId,
            choicePermutation: try shuffled(answerSourceIndexes, rng: &rng)
        )
    }

    return GeneratedExam(
        bankId: input.bankId,
        rng: RngDescriptor(algorithm: rngAlgorithm, seed: input.seed),
        items: items
    )
}

public func categoryCounts(_ items: [GeneratedExamItem]) -> [String: Int] {
    var counts: [String: Int] = [:]
    for item in items {
        counts[item.categoryId, default: 0] += 1
    }
    return counts
}

private func isCanonicalAnswerSourceIndexes(_ value: [Int]) -> Bool {
    value == [0, 1, 2, 3]
}
