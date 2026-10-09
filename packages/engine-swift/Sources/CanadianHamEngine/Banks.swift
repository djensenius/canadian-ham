public let basicBankId = "basic-2025-07-15"
public let advancedBankId = "advanced-2025-02-04"
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
    bankId: advancedBankId,
    categoryIds: ["A-001", "A-002", "A-003", "A-004", "A-005", "A-006", "A-007"],
    mockExamQuestionCount: 50,
    subsectionCount: 50,
    passPercent: 70,
    hasHonours: false,
    honoursPercent: nil
)

/// Matches packages/schemas/common.schema.json (`^basic-[0-9]{4}-[0-9]{2}-[0-9]{2}$`): the whole id, not just the prefix.
func isValidBasicBankId(_ bankId: String) -> Bool {
    let prefix = "basic-"
    guard bankId.hasPrefix(prefix) else { return false }
    let rest = bankId.dropFirst(prefix.count)
    guard rest.count == 10 else { return false }
    let scalars = Array(rest.unicodeScalars)
    for index in scalars.indices {
        if index == 4 || index == 7 {
            guard scalars[index] == "-" else { return false }
        } else if !("0"..."9").contains(scalars[index]) {
            return false
        }
    }
    return true
}

/// Matches packages/schemas/common.schema.json (`^advanced-[a-z0-9-]+$`): the whole id, not just the prefix.
func isValidAdvancedBankId(_ bankId: String) -> Bool {
    let prefix = "advanced-"
    guard bankId.hasPrefix(prefix) else { return false }
    let rest = bankId.dropFirst(prefix.count)
    return !rest.isEmpty && rest.unicodeScalars.allSatisfy { scalar in
        ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar) || scalar == "-"
    }
}

public func rulesForBankId(_ bankId: String = basicBankId) throws -> BankRules {
    if isValidBasicBankId(bankId) {
        return BankRules(
            bankId: bankId,
            categoryIds: basicBankRules.categoryIds,
            mockExamQuestionCount: basicBankRules.mockExamQuestionCount,
            subsectionCount: basicBankRules.subsectionCount,
            passPercent: basicBankRules.passPercent,
            hasHonours: basicBankRules.hasHonours,
            honoursPercent: basicBankRules.honoursPercent
        )
    }
    if bankId == syntheticAdvancedBankId || isValidAdvancedBankId(bankId) {
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
