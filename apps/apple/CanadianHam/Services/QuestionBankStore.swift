import Foundation

enum QuestionBankLoadError: Error, LocalizedError, Sendable {
    case missingResource(String)

    var errorDescription: String? {
        localizedMessage(bundle: .main)
    }

    func localizedMessage(bundle: Bundle) -> String {
        switch self {
        case .missingResource(let name):
            String(localized: "Missing bundled resource: \(name).json", bundle: bundle)
        }
    }
}

enum QuestionBankStore {
    static func load(bankId: CourseBankID = .basic, from bundle: Bundle = .main) throws -> QuestionBank {
        let decoder = JSONDecoder()
        let questions: [BankQuestion] = try decode("questions", bankId: bankId, from: bundle, with: decoder)
        let categories: [BankCategory] = try decode("categories", bankId: bankId, from: bundle, with: decoder)
        let subsections: [BankSubsection] = try decode("subsections", bankId: bankId, from: bundle, with: decoder)
        let manifest: BankManifest = try decode("manifest", bankId: bankId, from: bundle, with: decoder)
        let lessonQuizzes = try decodeLessonQuizzes(from: bundle, with: decoder)

        return QuestionBank(
            questions: questions,
            categories: categories,
            subsections: subsections,
            manifest: manifest,
            lessonQuizzes: lessonQuizzes
        )
    }

    private static func decode<Value: Decodable>(
        _ resourceName: String,
        bankId: CourseBankID,
        from bundle: Bundle,
        with decoder: JSONDecoder
    ) throws -> Value {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json")
            ?? bundle.resourceURL?
                .appendingPathComponent("generated", isDirectory: true)
                .appendingPathComponent(bankId.rawValue, isDirectory: true)
                .appendingPathComponent("\(resourceName).json")
        else {
            throw QuestionBankLoadError.missingResource(resourceName)
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(Value.self, from: data)
    }

    private static func decodeLessonQuizzes(from bundle: Bundle, with decoder: JSONDecoder) throws -> [BankLessonQuiz] {
        guard let quizzesURL = bundle.url(forResource: "quizzes", withExtension: nil) else {
            return []
        }
        let quizURLs = try FileManager.default.contentsOfDirectory(
            at: quizzesURL,
            includingPropertiesForKeys: nil
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try quizURLs.map { url in
            let data = try Data(contentsOf: url)
            return try decoder.decode(BankLessonQuiz.self, from: data)
        }
    }
}
