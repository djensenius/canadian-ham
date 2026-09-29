import Foundation

enum BankLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .french:
            "Français"
        }
    }

    var accessibilityLanguageCode: String {
        switch self {
        case .english:
            "en-CA"
        case .french:
            "fr-CA"
        }
    }
}

struct LocalizedText: Decodable, Hashable, Sendable {
    let en: String?
    let fr: String?

    func text(for language: BankLanguage) -> String {
        switch language {
        case .english:
            en ?? fr ?? ""
        case .french:
            fr ?? en ?? ""
        }
    }
}

struct BankAnswer: Decodable, Hashable, Identifiable, Sendable {
    let sourceIndex: Int
    let isCorrect: Bool
    let text: LocalizedText

    var id: Int { sourceIndex }
}

struct BankQuestion: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let bankId: String
    let categoryId: String
    let subsectionId: String
    let sourceOrder: Int
    let text: LocalizedText
    let answers: [BankAnswer]

    var correctAnswer: BankAnswer? {
        answers.first { $0.isCorrect }
    }
}

struct BankCategory: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let bankId: String
    let name: LocalizedText
    let frenchNameStatus: String
    let questionCount: Int
    let subsectionCount: Int
    let examQuestionCount: Int
    let nameSource: String
}

struct BankSubsection: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let bankId: String
    let categoryId: String
    let questionIds: [String]
    let questionCount: Int
    let lessonIds: [String]
    let title: LocalizedText
}

struct BankManifest: Decodable, Hashable, Sendable {
    struct Source: Decodable, Hashable, Sendable {
        let path: String
        let sha256: String
        let url: String
        let encoding: String
        let lineEndings: String
    }

    struct Importer: Decodable, Hashable, Sendable {
        let name: String
        let version: String
    }

    struct Counts: Decodable, Hashable, Sendable {
        let questions: Int
        let categories: Int
        let subsections: Int
    }

    let bankId: String
    let certificate: String
    let effectiveDate: String
    let source: Source
    let importer: Importer
    let counts: Counts
}

struct QuestionBank: Sendable {
    let questions: [BankQuestion]
    let categories: [BankCategory]
    let subsections: [BankSubsection]
    let manifest: BankManifest
    let questionsByCategory: [String: [BankQuestion]]
    let questionsById: [String: BankQuestion]
    let subsectionsByCategory: [String: [BankSubsection]]
    let subsectionsById: [String: BankSubsection]

    init(
        questions: [BankQuestion],
        categories: [BankCategory],
        subsections: [BankSubsection],
        manifest: BankManifest
    ) {
        self.questions = questions
        self.categories = categories
        self.subsections = subsections
        self.manifest = manifest
        self.questionsByCategory = Dictionary(grouping: questions, by: \.categoryId)
        self.questionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
        self.subsectionsByCategory = Dictionary(grouping: subsections, by: \.categoryId)
        self.subsectionsById = Dictionary(uniqueKeysWithValues: subsections.map { ($0.id, $0) })
    }

    func questions(in category: BankCategory) -> [BankQuestion] {
        questionsByCategory[category.id] ?? []
    }

    func question(id: String) -> BankQuestion? {
        questionsById[id]
    }

    func subsectionTitle(_ subsection: BankSubsection, language: BankLanguage) -> String {
        let authored = subsection.title.text(for: language)
        return authored.isEmpty ? subsection.id : authored
    }
}
