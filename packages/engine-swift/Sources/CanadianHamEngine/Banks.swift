public let basicBankId = "basic-2025-07-15"
public let syntheticAdvancedBankId = "advanced-synthetic"

public struct BankRules: Equatable, Sendable {
    public let bankId: String
    public let categoryIds: [String]
    public let mockExamQuestionCount: Int
    public let subsectionCount: Int
    public let passPercent: Double
    public let hasHonours: Bool
    public let honoursPercent: Double?

    public init(
        bankId: String,
        categoryIds: [String],
        mockExamQuestionCount: Int,
        subsectionCount: Int,
        passPercent: Double,
        hasHonours: Bool,
        honoursPercent: Double?
    ) {
        self.bankId = bankId
        self.categoryIds = categoryIds
        self.mockExamQuestionCount = mockExamQuestionCount
        self.subsectionCount = subsectionCount
        self.passPercent = passPercent
        self.hasHonours = hasHonours
        self.honoursPercent = honoursPercent
    }
}

public let basicBankRules = BankRules(
    bankId: basicBankId,
    categoryIds: ["B-001", "B-002", "B-003", "B-004", "B-005", "B-006", "B-007", "B-008"],
    mockExamQuestionCount: 100,
    subsectionCount: 100,
    passPercent: 70,
    hasHonours: true,
    honoursPercent: 80
)

public let advancedBankRules = BankRules(
    bankId: syntheticAdvancedBankId,
    categoryIds: ["A-001", "A-002", "A-003", "A-004", "A-005", "A-006", "A-007"],
    mockExamQuestionCount: 50,
    subsectionCount: 50,
    passPercent: 70,
    hasHonours: false,
    honoursPercent: nil
)

public func rulesForBankId(_ bankId: String = basicBankId) throws -> BankRules {
    if bankId == basicBankId {
        return basicBankRules
    }
    if bankId == syntheticAdvancedBankId || bankId.hasPrefix("advanced-") {
        return BankRules(
            bankId: bankId,
            categoryIds: advancedBankRules.categoryIds,
            mockExamQuestionCount: advancedBankRules.mockExamQuestionCount,
            subsectionCount: advancedBankRules.subsectionCount,
            passPercent: advancedBankRules.passPercent,
            hasHonours: advancedBankRules.hasHonours,
            honoursPercent: advancedBankRules.honoursPercent
        )
    }
    throw EngineError("unsupported bankId \(bankId)")
}
