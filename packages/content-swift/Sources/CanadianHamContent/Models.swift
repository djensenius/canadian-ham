import Foundation

public let canadianHamDefaultBankId = "basic-2025-07-15"

public struct LocalizedText: Codable, Equatable, Sendable {
    public let en: String
    public let fr: String
}

public struct LocalizedNullableText: Codable, Equatable, Sendable {
    public let en: String
    public let fr: String?
}

public struct LocalizedOptionalText: Codable, Equatable, Sendable {
    public let en: String?
    public let fr: String?
}

public struct Answer: Codable, Equatable, Sendable {
    public let sourceIndex: Int
    public let isCorrect: Bool
    public let text: LocalizedText
}

public struct Question: Codable, Equatable, Sendable {
    public let id: String
    public let bankId: String
    public let categoryId: String
    public let subsectionId: String
    public let sourceOrder: Int
    public let text: LocalizedText
    public let answers: [Answer]
}

public struct Category: Codable, Equatable, Sendable {
    public let id: String
    public let bankId: String
    public let name: LocalizedNullableText
    public let frenchNameStatus: String
    public let questionCount: Int
    public let subsectionCount: Int
    public let examQuestionCount: Int
    public let nameSource: String
}

public struct Subsection: Codable, Equatable, Sendable {
    public let id: String
    public let bankId: String
    public let categoryId: String
    public let questionIds: [String]
    public let questionCount: Int
    public let lessonIds: [String]
    public let title: LocalizedOptionalText
}

public struct SubsectionTitle: Codable, Equatable, Sendable {
    public let id: String
    public let title: LocalizedNullableText
    public let status: String
}

public struct BankManifest: Codable, Equatable, Sendable {
    public let bankId: String
    public let certificate: String
    public let effectiveDate: String
    public let source: BankManifestSource
    public let importer: BankManifestImporter
    public let counts: BankManifestCounts
}

public struct BankManifestSource: Codable, Equatable, Sendable {
    public let path: String
    public let sha256: String
    public let url: String
    public let encoding: String
    public let lineEndings: String
}

public struct BankManifestImporter: Codable, Equatable, Sendable {
    public let name: String
    public let version: String
}

public struct BankManifestCounts: Codable, Equatable, Sendable {
    public let questions: Int
    public let categories: Int
    public let subsections: Int
}

public enum ContentStatus: String, Codable, Equatable, Sendable {
    case outline
    case draft
    case review
    case published
}

public struct LessonModule: Codable, Equatable, Sendable {
    public let type: String
    public let id: String
    public let categoryId: String
    public let order: Int
    public let title: LocalizedNullableText
    public let lessonIds: [String]
    public let status: ContentStatus
    public let bodyMarkdown: String
    public let path: String
}

public struct Lesson: Codable, Equatable, Sendable {
    public let type: String
    public let id: String
    public let moduleId: String
    public let categoryIds: [String]
    public let title: LocalizedNullableText
    public let covers: [String]
    public let objectives: [String]
    public let prerequisites: [String]
    public let estimatedMinutes: Int
    public let quizIds: [String]
    public let status: ContentStatus
    public let bodyMarkdown: String
    public let path: String
}

public struct ConceptCheckChoice: Codable, Equatable, Sendable {
    public let text: LocalizedNullableText
    public let isCorrect: Bool
}

public struct ConceptCheck: Codable, Equatable, Sendable {
    public let id: String
    public let prompt: LocalizedNullableText
    public let choices: [ConceptCheckChoice]
    public let explanation: LocalizedNullableText
}

public struct LessonQuiz: Codable, Equatable, Sendable {
    public let id: String
    public let lessonId: String
    public let officialQuestionIds: [String]
    public let conceptChecks: [ConceptCheck]
}

public struct ExplanationCitation: Codable, Equatable, Sendable {
    public let type: String
    public let id: String?
    public let url: String?
}

public struct Explanation: Codable, Equatable, Sendable {
    public let id: String
    public let questionId: String
    public let bankId: String
    public let status: String
    public let body: LocalizedNullableText
    public let citations: [ExplanationCitation]
    public let licenseClass: String
}
