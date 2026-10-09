import Foundation

struct ExportedMorseSettings: Codable, Equatable, Sendable {
    let toneHz: Int
    let characterWpm: Int
    let effectiveWpm: Int
    let timingProfile: String
    let volume: Double
    let outputMode: String

    static let `default` = ExportedMorseSettings(toneHz: 650, characterWpm: 15, effectiveWpm: 5, timingProfile: "isedParis", volume: 0.6, outputMode: "audio")

    init(toneHz: Int, characterWpm: Int, effectiveWpm: Int, timingProfile: String, volume: Double, outputMode: String = "audio") {
        self.toneHz = toneHz
        self.characterWpm = characterWpm
        self.effectiveWpm = effectiveWpm
        self.timingProfile = timingProfile
        self.volume = volume
        self.outputMode = outputMode
    }
}

enum CourseBankID: String, CaseIterable, Identifiable, Codable, Sendable {
    case basic = "basic-2025-07-15"
    case advanced = "advanced-2025-02-04"

    var id: String { rawValue }

    var localizedName: LocalizedStringResource {
        switch self {
        case .basic: "Basic"
        case .advanced: "Advanced"
        }
    }

    var hasLessons: Bool { self == .basic }
    var hasHonours: Bool { self == .basic }
    var mockExamQuestionCount: Int { self == .advanced ? 50 : 100 }
    var passPercent: Int { 70 }
}

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

    func resolvedLanguage(for language: BankLanguage) -> BankLanguage {
        switch language {
        case .english:
            en != nil ? .english : .french
        case .french:
            fr != nil ? .french : .english
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

struct BankConceptCheck: Decodable, Hashable, Identifiable, Sendable {
    let id: String

    private enum CodingKeys: String, CodingKey {
        case id
    }
}

struct BankLessonQuiz: Decodable, Hashable, Identifiable, Sendable {
    let id: String
    let lessonId: String
    let officialQuestionIds: [String]
    let conceptChecks: [BankConceptCheck]

    var conceptCheckIds: Set<String> { Set(conceptChecks.map(\.id)) }
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
    let lessonQuizzes: [BankLessonQuiz]
    let questionsByCategory: [String: [BankQuestion]]
    let questionsById: [String: BankQuestion]
    let subsectionsByCategory: [String: [BankSubsection]]
    let subsectionsById: [String: BankSubsection]
    let lessonQuizzesById: [String: BankLessonQuiz]
    let knownLessonIds: Set<String>

    init(
        questions: [BankQuestion],
        categories: [BankCategory],
        subsections: [BankSubsection],
        manifest: BankManifest,
        lessonQuizzes: [BankLessonQuiz] = [],
        knownLessonIds: Set<String>? = nil
    ) {
        self.questions = questions
        self.categories = categories
        self.subsections = subsections
        self.manifest = manifest
        self.lessonQuizzes = lessonQuizzes
        self.questionsByCategory = Dictionary(grouping: questions, by: \.categoryId)
        self.questionsById = Dictionary(uniqueKeysWithValues: questions.map { ($0.id, $0) })
        self.subsectionsByCategory = Dictionary(grouping: subsections, by: \.categoryId)
        self.subsectionsById = Dictionary(uniqueKeysWithValues: subsections.map { ($0.id, $0) })
        self.lessonQuizzesById = Dictionary(uniqueKeysWithValues: lessonQuizzes.map { ($0.id, $0) })
        if let knownLessonIds {
            self.knownLessonIds = knownLessonIds
        } else {
            let lessonIdsFromQuizzes = lessonQuizzes.map(\.lessonId).filter { !$0.isEmpty }
            let lessonIdsFromSubsections = subsections.flatMap(\.lessonIds).filter { !$0.isEmpty }
            self.knownLessonIds = Set(lessonIdsFromQuizzes).union(lessonIdsFromSubsections)
        }
    }

    func withKnownLessonIds(_ lessonIds: Set<String>) -> QuestionBank {
        QuestionBank(
            questions: questions,
            categories: categories,
            subsections: subsections,
            manifest: manifest,
            lessonQuizzes: lessonQuizzes,
            knownLessonIds: lessonIds
        )
    }

    func questions(in category: BankCategory) -> [BankQuestion] {
        questionsByCategory[category.id] ?? []
    }

    func question(id: String) -> BankQuestion? {
        questionsById[id]
    }

    var courseBankID: CourseBankID {
        CourseBankID(rawValue: manifest.bankId) ?? .basic
    }

    func subsectionTitle(_ subsection: BankSubsection, language: BankLanguage) -> String {
        let authored = subsection.title.text(for: language)
        return authored.isEmpty ? subsection.id : authored
    }
}
