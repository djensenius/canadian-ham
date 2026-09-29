import Foundation

enum QuestionBankLoadError: Error, LocalizedError, Sendable {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            "Missing bundled resource: \(name).json"
        }
    }
}

enum QuestionBankStore {
    static func load(from bundle: Bundle = .main) throws -> QuestionBank {
        let decoder = JSONDecoder()
        let questions: [BankQuestion] = try decode("questions", from: bundle, with: decoder)
        let categories: [BankCategory] = try decode("categories", from: bundle, with: decoder)
        let subsections: [BankSubsection] = try decode("subsections", from: bundle, with: decoder)
        let manifest: BankManifest = try decode("manifest", from: bundle, with: decoder)
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
        from bundle: Bundle,
        with decoder: JSONDecoder
    ) throws -> Value {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
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
