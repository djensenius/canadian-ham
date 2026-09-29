import Foundation

public let canadianHamDefaultBankId = "basic-2025-07-15"

public struct LocalizedText: Codable, Equatable, Sendable {
    public let en: String
    public let fr: String

    public init(en: String, fr: String) {
        self.en = en
        self.fr = fr
    }
}

public struct LocalizedNullableText: Codable, Equatable, Sendable {
    public let en: String
    public let fr: String?

    public init(en: String, fr: String?) {
        self.en = en
        self.fr = fr
    }
}

public struct LocalizedOptionalText: Codable, Equatable, Sendable {
    public let en: String?
    public let fr: String?

    public init(en: String?, fr: String?) {
        self.en = en
        self.fr = fr
    }
}

public struct Answer: Codable, Equatable, Sendable {
    public let sourceIndex: Int
    public let isCorrect: Bool
    public let text: LocalizedText

    public init(sourceIndex: Int, isCorrect: Bool, text: LocalizedText) {
        self.sourceIndex = sourceIndex
        self.isCorrect = isCorrect
        self.text = text
    }
}

public struct Question: Codable, Equatable, Sendable {
    public let id: String
    public let bankId: String
    public let categoryId: String
    public let subsectionId: String
    public let sourceOrder: Int
    public let text: LocalizedText
    public let answers: [Answer]

    public init(id: String, bankId: String, categoryId: String, subsectionId: String, sourceOrder: Int, text: LocalizedText, answers: [Answer]) {
        self.id = id
        self.bankId = bankId
        self.categoryId = categoryId
        self.subsectionId = subsectionId
        self.sourceOrder = sourceOrder
        self.text = text
        self.answers = answers
    }
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

    public init(id: String, bankId: String, name: LocalizedNullableText, frenchNameStatus: String, questionCount: Int, subsectionCount: Int, examQuestionCount: Int, nameSource: String) {
        self.id = id
        self.bankId = bankId
        self.name = name
        self.frenchNameStatus = frenchNameStatus
        self.questionCount = questionCount
        self.subsectionCount = subsectionCount
        self.examQuestionCount = examQuestionCount
        self.nameSource = nameSource
    }
}

public struct Subsection: Codable, Equatable, Sendable {
    public let id: String
    public let bankId: String
    public let categoryId: String
    public let questionIds: [String]
    public let questionCount: Int
    public let lessonIds: [String]
    public let title: LocalizedOptionalText

    public init(id: String, bankId: String, categoryId: String, questionIds: [String], questionCount: Int, lessonIds: [String], title: LocalizedOptionalText) {
        self.id = id
        self.bankId = bankId
        self.categoryId = categoryId
        self.questionIds = questionIds
        self.questionCount = questionCount
        self.lessonIds = lessonIds
        self.title = title
    }
}

public struct SubsectionTitle: Codable, Equatable, Sendable {
    public let id: String
    public let title: LocalizedNullableText
    public let status: String

    public init(id: String, title: LocalizedNullableText, status: String) {
        self.id = id
        self.title = title
        self.status = status
    }
}

public struct BankManifest: Codable, Equatable, Sendable {
    public let bankId: String
    public let certificate: String
    public let effectiveDate: String
    public let source: BankManifestSource
    public let importer: BankManifestImporter
    public let counts: BankManifestCounts

    public init(bankId: String, certificate: String, effectiveDate: String, source: BankManifestSource, importer: BankManifestImporter, counts: BankManifestCounts) {
        self.bankId = bankId
        self.certificate = certificate
        self.effectiveDate = effectiveDate
        self.source = source
        self.importer = importer
        self.counts = counts
    }
}

public struct BankManifestSource: Codable, Equatable, Sendable {
    public let path: String
    public let sha256: String
    public let url: String
    public let encoding: String
    public let lineEndings: String

    public init(path: String, sha256: String, url: String, encoding: String, lineEndings: String) {
        self.path = path
        self.sha256 = sha256
        self.url = url
        self.encoding = encoding
        self.lineEndings = lineEndings
    }
}

public struct BankManifestImporter: Codable, Equatable, Sendable {
    public let name: String
    public let version: String

    public init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

public struct BankManifestCounts: Codable, Equatable, Sendable {
    public let questions: Int
    public let categories: Int
    public let subsections: Int

    public init(questions: Int, categories: Int, subsections: Int) {
        self.questions = questions
        self.categories = categories
        self.subsections = subsections
    }
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

    public init(type: String, id: String, categoryId: String, order: Int, title: LocalizedNullableText, lessonIds: [String], status: ContentStatus, bodyMarkdown: String, path: String) {
        self.type = type
        self.id = id
        self.categoryId = categoryId
        self.order = order
        self.title = title
        self.lessonIds = lessonIds
        self.status = status
        self.bodyMarkdown = bodyMarkdown
        self.path = path
    }
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

    public init(type: String, id: String, moduleId: String, categoryIds: [String], title: LocalizedNullableText, covers: [String], objectives: [String], prerequisites: [String], estimatedMinutes: Int, quizIds: [String], status: ContentStatus, bodyMarkdown: String, path: String) {
        self.type = type
        self.id = id
        self.moduleId = moduleId
        self.categoryIds = categoryIds
        self.title = title
        self.covers = covers
        self.objectives = objectives
        self.prerequisites = prerequisites
        self.estimatedMinutes = estimatedMinutes
        self.quizIds = quizIds
        self.status = status
        self.bodyMarkdown = bodyMarkdown
        self.path = path
    }
}

public struct ConceptCheckChoice: Codable, Equatable, Sendable {
    public let text: LocalizedNullableText
    public let isCorrect: Bool

    public init(text: LocalizedNullableText, isCorrect: Bool) {
        self.text = text
        self.isCorrect = isCorrect
    }
}

public struct ConceptCheck: Codable, Equatable, Sendable {
    public let id: String
    public let prompt: LocalizedNullableText
    public let choices: [ConceptCheckChoice]
    public let explanation: LocalizedNullableText

    public init(id: String, prompt: LocalizedNullableText, choices: [ConceptCheckChoice], explanation: LocalizedNullableText) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.explanation = explanation
    }
}

public struct LessonQuiz: Codable, Equatable, Sendable {
    public let id: String
    public let lessonId: String
    public let officialQuestionIds: [String]
    public let conceptChecks: [ConceptCheck]

    public init(id: String, lessonId: String, officialQuestionIds: [String], conceptChecks: [ConceptCheck]) {
        self.id = id
        self.lessonId = lessonId
        self.officialQuestionIds = officialQuestionIds
        self.conceptChecks = conceptChecks
    }
}

public struct ExplanationCitation: Codable, Equatable, Sendable {
    public let type: String
    public let id: String?
    public let url: String?

    public init(type: String, id: String? = nil, url: String? = nil) {
        self.type = type
        self.id = id
        self.url = url
    }
}

public struct Explanation: Codable, Equatable, Sendable {
    public let id: String
    public let questionId: String
    public let bankId: String
    public let status: String
    public let body: LocalizedNullableText
    public let citations: [ExplanationCitation]
    public let licenseClass: String

    public init(id: String, questionId: String, bankId: String, status: String, body: LocalizedNullableText, citations: [ExplanationCitation], licenseClass: String) {
        self.id = id
        self.questionId = questionId
        self.bankId = bankId
        self.status = status
        self.body = body
        self.citations = citations
        self.licenseClass = licenseClass
    }
}
