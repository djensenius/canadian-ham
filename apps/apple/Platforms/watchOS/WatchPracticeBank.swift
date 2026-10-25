import Foundation
import CanadianHamContent
import CanadianHamEngine

/// The watch deliberately decodes bank data without ContentLibrary's lesson dependencies.
struct WatchPracticeBank {
    let questions: [Question]
    let explanations: [String: Explanation]

    static func load(bundle: Bundle = .main) throws -> WatchPracticeBank {
        guard let root = bundle.resourceURL else { throw WatchPracticeError.unavailable }
        return try load(resourceRoot: root)
    }

    static func load(resourceRoot: URL) throws -> WatchPracticeBank {
        let decoder = JSONDecoder()
        let bankRoot = resourceRoot.appendingPathComponent(basicBankId, isDirectory: true)
        func decode<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
            try decoder.decode(type, from: Data(contentsOf: bankRoot.appendingPathComponent(name + ".json")))
        }
        let questions = try decode("questions", as: [Question].self)
        let categories = try decode("categories", as: [CanadianHamContent.Category].self)
        let subsections = try decode("subsections", as: [Subsection].self)
        let manifest = try decode("manifest", as: BankManifest.self)
        guard manifest.bankId == basicBankId, manifest.counts.questions == 984,
              questions.count == 984, Set(questions.map(\.id)).count == 984,
              categories.count == manifest.counts.categories,
              subsections.count == manifest.counts.subsections,
              Set(subsections.flatMap(\.questionIds)) == Set(questions.map(\.id)),
              questions.allSatisfy({ question in
                  question.bankId == basicBankId && question.answers.count == 4 &&
                  Set(question.answers.map(\.sourceIndex)) == Set(0...3) &&
                  question.answers.filter(\.isCorrect).count == 1 &&
                  !question.text.en.isEmpty && !question.text.fr.isEmpty &&
                  question.answers.allSatisfy { !$0.text.en.isEmpty && !$0.text.fr.isEmpty }
              }) else { throw WatchPracticeError.unavailable }

        var explanations: [String: Explanation] = [:]
        let explanationRoot = resourceRoot.appendingPathComponent("explanations", isDirectory: true)
        for question in questions {
            let url = explanationRoot.appendingPathComponent(question.categoryId.lowercased(), isDirectory: true)
                .appendingPathComponent(question.id.lowercased() + ".json")
            let explanation = try decoder.decode(Explanation.self, from: Data(contentsOf: url))
            guard explanation.questionId == question.id, explanation.bankId == basicBankId else {
                throw WatchPracticeError.unavailable
            }
            _ = try ExplanationBodyParser.parse(explanation)
            explanations[question.id] = explanation
        }
        return WatchPracticeBank(questions: questions, explanations: explanations)
    }
}

enum WatchPracticeError: Error {
    case unavailable
    case empty
}

/// No scores, history, settings or session identifiers leave this value's lifetime.
struct WatchPracticeSession {
    private let bank: WatchPracticeBank
    private var rng: Pcg32
    private(set) var question: Question?
    private(set) var choices: [Answer] = []
    private(set) var submittedSourceIndex: Int?
    private(set) var failed = false

    init(load: () throws -> WatchPracticeBank = { try WatchPracticeBank.load() }, seed: String = UUID().uuidString) {
        rng = Pcg32(seed: seed)
        do {
            bank = try load()
        } catch {
            bank = WatchPracticeBank(questions: [], explanations: [:])
            failed = true
        }
        next()
    }

    var isCorrect: Bool { choices.first { $0.sourceIndex == submittedSourceIndex }?.isCorrect == true }
    var explanation: Explanation? { question.flatMap { bank.explanations[$0.id] } }

    mutating func submit(sourceIndex: Int) {
        guard submittedSourceIndex == nil, choices.contains(where: { $0.sourceIndex == sourceIndex }) else { return }
        submittedSourceIndex = sourceIndex
    }

    mutating func next() {
        submittedSourceIndex = nil
        do {
            guard !bank.questions.isEmpty else { throw WatchPracticeError.empty }
            // Avoid an immediate repeat, while still allowing a one-question test bank.
            let candidates = bank.questions.count > 1 ? bank.questions.filter { $0.id != question?.id } : bank.questions
            let drawn = candidates[try rng.bounded(candidates.count)]
            choices = try shuffled(drawn.answers, rng: &rng)
            question = drawn
        } catch {
            question = nil
            choices = []
            failed = true
        }
    }
}

struct WatchExplanationText {
    let body: String
    let languageIdentifier: String
    let isEnglishFallback: Bool

    init(explanation: Explanation, french: Bool) {
        isEnglishFallback = french && explanation.body.fr == nil
        body = french ? (explanation.body.fr ?? explanation.body.en) : explanation.body.en
        languageIdentifier = french && !isEnglishFallback ? "fr-CA" : "en-CA"
    }

    var attributedBody: AttributedString {
        var text = AttributedString(body)
        text.languageIdentifier = languageIdentifier
        return text
    }
}
