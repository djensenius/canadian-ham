import XCTest

final class CanadianHamVisionTests: XCTestCase {
    func testAppBundleContainsOnlyBasicQuestionBankResources() throws {
        let appBundle = try builtAppBundle(named: "CanadianHamVision")
        let bank = try QuestionBankStore.load(from: appBundle)

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.manifest.bankId, "basic-2025-07-15")
        XCTAssertEqual(try bundledGeneratedBankIDs(in: appBundle), [])
        XCTAssertEqual(try bundledReadmePaths(in: appBundle), [], "visionOS app bundle must not contain README.md files")
        XCTAssertTrue(try bundledAdvancedResourcePaths(in: appBundle).isEmpty, "visionOS app bundle must not contain Advanced generated resources")
    }

    func testBundledQuestionBankLoadsForVisionApp() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))

        XCTAssertEqual(bank.questions.count, 984)
        XCTAssertEqual(bank.categories.count, 8)
        XCTAssertEqual(bank.subsections.count, 100)
        XCTAssertEqual(bank.manifest.bankId, "basic-2025-07-15")
    }

    func testVisionPracticeQuestionDrawStaysInCategoryAndShufflesAnswers() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let category = try XCTUnwrap(bank.categories.first { $0.id == "B-001" })
        let question = try XCTUnwrap(
            try AppleQuestionShuffle.randomQuestion(from: bank.questions(in: category), seed: "vision-unit/category-draw"),
            "Expected a deterministic visionOS practice draw"
        )
        let answers = try AppleQuestionShuffle.shuffledAnswers(for: question, seed: "vision-unit/answers/\(question.id)")

        XCTAssertEqual(question.categoryId, category.id)
        XCTAssertEqual(answers.count, 4)
        XCTAssertEqual(Set(answers.map(\.sourceIndex)), Set(question.answers.map(\.sourceIndex)))
        XCTAssertEqual(answers.filter(\.isCorrect).count, 1)
    }

    private func builtAppBundle(named name: String) throws -> Bundle {
        let productsDirectory = Bundle(for: Self.self).bundleURL.deletingLastPathComponent()
        let appURL = productsDirectory.appendingPathComponent("\(name).app", isDirectory: true)
        return try XCTUnwrap(Bundle(url: appURL), "Expected built app bundle at \(appURL.path)")
    }

    private func bundledReadmePaths(in bundle: Bundle) throws -> [String] {
        let resourceURL = try XCTUnwrap(bundle.resourceURL)
        let urls = FileManager.default.enumerator(
            at: resourceURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        )?.compactMap { $0 as? URL } ?? []

        return try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true, url.lastPathComponent.caseInsensitiveCompare("README.md") == .orderedSame else {
                return nil
            }
            return url.path.replacingOccurrences(of: resourceURL.path + "/", with: "")
        }
        .sorted()
    }

    private func bundledGeneratedBankIDs(in bundle: Bundle) throws -> Set<String> {
        guard let generatedURL = bundle.resourceURL?.appendingPathComponent("generated", isDirectory: true), FileManager.default.fileExists(atPath: generatedURL.path) else {
            return []
        }
        let resourceValues = try generatedURL.resourceValues(forKeys: [.isDirectoryKey])
        XCTAssertEqual(resourceValues.isDirectory, true, "Expected generated resources path to be a directory in \(bundle.bundleURL.path)")
        let urls = try FileManager.default.contentsOfDirectory(at: generatedURL, includingPropertiesForKeys: [.isDirectoryKey])
        return Set(try urls.compactMap { url in
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            return values.isDirectory == true ? url.lastPathComponent : nil
        })
    }

    private func bundledAdvancedResourcePaths(in bundle: Bundle) throws -> [String] {
        let resourceURL = try XCTUnwrap(bundle.resourceURL)
        let urls = FileManager.default.enumerator(at: resourceURL, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey])?.compactMap { $0 as? URL } ?? []
        return urls
            .map { $0.path.replacingOccurrences(of: resourceURL.path + "/", with: "") }
            .filter { $0.contains("advanced-") || $0.contains("A-001") }
            .sorted()
    }

    func testVisionPracticeSeedsVaryAcrossSessionIDs() throws {
        let bank = try QuestionBankStore.load(from: Bundle(for: Self.self))
        let category = try XCTUnwrap(bank.categories.first { $0.id == "B-001" })
        let questions = bank.questions(in: category)
        let sessionIDs = (0..<6).map { "vision-session-\($0)" }

        let questionIDs = try Set(sessionIDs.compactMap { sessionID in
            try AppleQuestionShuffle.randomQuestion(
                from: questions,
                seed: "vision-practice/\(category.id)/0/\(sessionID)"
            )?.id
        })
        let firstQuestion = try XCTUnwrap(questions.first)
        let answerOrders = try Set(sessionIDs.map { sessionID in
            try AppleQuestionShuffle.shuffledAnswers(
                for: firstQuestion,
                seed: "vision-answers/\(firstQuestion.id)/0/\(sessionID)"
            )
            .map(\.sourceIndex)
        })

        XCTAssertGreaterThan(questionIDs.count, 1, "Practice question seeds should vary when the per-session launch ID changes")
        XCTAssertGreaterThan(answerOrders.count, 1, "Answer shuffle seeds should vary when the per-session launch ID changes")
    }
}
