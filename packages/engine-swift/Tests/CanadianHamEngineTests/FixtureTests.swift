import XCTest
@testable import CanadianHamEngine

final class FixtureTests: XCTestCase {
    func testEveryEngineFixtureMatchesSwiftEngine() throws {
        let paths = try engineFixturePaths()
        XCTAssertFalse(paths.isEmpty, "expected at least one fixture JSON file")
        for path in paths {
            let data = try Data(contentsOf: path)
            let header = try JSONDecoder().decode(FixtureHeader.self, from: data)
            XCTAssertEqual(header.schemaVersion, 1, path.path(percentEncoded: false).fixtureRelativePath())
            switch header.kind {
            case "rng-vectors":
                try validateRngVectors(data)
            case "exam-generation":
                try validateExamGeneration(data)
            case "scoring":
                try validateScoring(data)
            case "weak-subsections":
                try validateWeakSubsections(data)
            case "leitner":
                try validateLeitner(data)
            case "readiness":
                try validateReadiness(data)
            default:
                XCTFail("unsupported fixture kind: \(header.kind)")
            }
        }
    }

    private func validateRngVectors(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(RngVectorsFixture.self, from: data)
        for vector in fixture.cases {
            XCTAssertEqual(vector.rng.algorithm, rngAlgorithm, vector.id)
            XCTAssertEqual(try firstUint32Values(seed: vector.rng.seed, count: 8), vector.expectedOutput.first8Uint32, vector.id)
        }
    }

    private func validateExamGeneration(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ExamGenerationFixture.self, from: data)
        XCTAssertEqual(fixture.rng.algorithm, rngAlgorithm)
        let generated = try generateExam(ExamGenerationInput(
            bankId: fixture.bankId,
            seed: fixture.rng.seed,
            subsections: fixture.input.subsections,
            answerSourceIndexes: fixture.input.answerSourceIndexes,
            requireFullMockExam: fixture.input.requireFullMockExam ?? false
        ))
        XCTAssertEqual(generated.items, fixture.expectedOutput.items, fixture.id)
        XCTAssertEqual(generated.items.count, fixture.expectedOutput.examQuestionCount, fixture.id)
        XCTAssertEqual(categoryCounts(generated.items), fixture.expectedOutput.categoryCounts, fixture.id)

        if fixture.expectedOutput.oneQuestionPerInputSubsection {
            let inputSubsectionIds = Set(fixture.input.subsections.map(\.id))
            let outputSubsectionIds = Set(generated.items.map(\.subsectionId))
            XCTAssertEqual(outputSubsectionIds.count, inputSubsectionIds.count, fixture.id)
            XCTAssertEqual(Array(outputSubsectionIds).sorted(by: OrdinalSort.ascending), Array(inputSubsectionIds).sorted(by: OrdinalSort.ascending), fixture.id)
        }

        for item in generated.items {
            XCTAssertEqual(item.choicePermutation.sorted(), [0, 1, 2, 3], fixture.id)
        }
    }

    private func validateScoring(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ScoringFixture.self, from: data)
        for testCase in fixture.cases {
            XCTAssertEqual(scoreExam(testCase.input.items), testCase.expectedOutput, testCase.id)
        }
    }

    private func validateWeakSubsections(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(WeakSubsectionsFixture.self, from: data)
        for testCase in fixture.recentResultCases {
            XCTAssertEqual(
                RecentResultOutput(recentResults: appendRecentResult(testCase.input.existing, newest: testCase.input.newest)),
                testCase.expectedOutput,
                testCase.id
            )
        }
        for testCase in fixture.cases {
            XCTAssertEqual(
                WeakSubsectionsOutput(weakSubsectionIds: weakSubsectionIds(records: testCase.input.records, latestExamItems: testCase.input.latestExamItems)),
                testCase.expectedOutput,
                testCase.id
            )
        }
    }

    private func validateLeitner(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(LeitnerFixture.self, from: data)
        for testCase in fixture.answerCases {
            XCTAssertEqual(
                LeitnerAnswerOutput(record: try applyAnswer(existing: testCase.input.existing, update: testCase.input.update)),
                testCase.expectedOutput,
                testCase.id
            )
        }
        for testCase in fixture.sequenceCases {
            XCTAssertEqual(
                LeitnerSequenceOutput(records: try applyAnswerSequence(initialRecords: testCase.input.initialRecords, updates: testCase.input.updates)),
                testCase.expectedOutput,
                testCase.id
            )
        }
        for testCase in fixture.dueCases {
            XCTAssertEqual(
                LeitnerDueOutput(
                    dueQuestionIds: try dueQuestionIds(records: testCase.input.records, now: testCase.input.now),
                    dueCount: try dueCount(records: testCase.input.records, now: testCase.input.now)
                ),
                testCase.expectedOutput,
                testCase.id
            )
        }
    }

    private func validateReadiness(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ReadinessFixture.self, from: data)
        for testCase in fixture.cases {
            XCTAssertEqual(try computeReadiness(testCase.input), testCase.expectedOutput, testCase.id)
        }
    }
}

private func engineFixturePaths() throws -> [URL] {
    let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let fileURL = URL(fileURLWithPath: #filePath, relativeTo: currentDirectory).standardizedFileURL
    let starts = [fileURL.deletingLastPathComponent(), currentDirectory]
    let fixturesRoot = try starts.compactMap(findFixturesRoot(startingAt:)).first.unwrapOrThrow(
        EngineError("could not resolve fixtures/engine relative to #filePath or current directory")
    )
    let enumerator = FileManager.default.enumerator(at: fixturesRoot, includingPropertiesForKeys: [.isRegularFileKey])
    var paths: [URL] = []
    while let path = enumerator?.nextObject() as? URL {
        let resourceValues = try path.resourceValues(forKeys: [.isRegularFileKey])
        if resourceValues.isRegularFile == true, path.pathExtension == "json" {
            paths.append(path)
        }
    }
    return paths.sorted { OrdinalSort.ascending($0.path(percentEncoded: false), $1.path(percentEncoded: false)) }
}

private func findFixturesRoot(startingAt start: URL) -> URL? {
    var cursor = start
    for _ in 0..<10 {
        let candidate = cursor.appending(path: "fixtures/engine", directoryHint: .isDirectory)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false), isDirectory: &isDirectory), isDirectory.boolValue {
            return candidate
        }
        let parent = cursor.deletingLastPathComponent()
        if parent.path(percentEncoded: false) == cursor.path(percentEncoded: false) {
            return nil
        }
        cursor = parent
    }
    return nil
}

private extension Optional {
    func unwrapOrThrow(_ error: Error) throws -> Wrapped {
        guard let value = self else { throw error }
        return value
    }
}

private extension String {
    func fixtureRelativePath() -> String {
        guard let range = range(of: "fixtures/engine/") else { return self }
        return String(self[range.lowerBound...])
    }
}

private struct FixtureHeader: Decodable {
    let schemaVersion: Int
    let kind: String
}

private struct RngVectorsFixture: Decodable {
    struct Case: Decodable {
        let id: String
        let rng: RngDescriptor
        let expectedOutput: ExpectedOutput
    }

    struct ExpectedOutput: Decodable {
        let first8Uint32: [UInt32]
    }

    let cases: [Case]
}

private struct ExamGenerationFixture: Decodable {
    struct Input: Decodable {
        let sourceQuestionBankPath: String?
        let subsections: [ExamSubsectionInput]
        let answerSourceIndexes: [Int]?
        let requireFullMockExam: Bool?
    }

    struct ExpectedOutput: Decodable {
        let items: [GeneratedExamItem]
        let examQuestionCount: Int
        let oneQuestionPerInputSubsection: Bool
        let choicePermutationDefinition: String?
        let categoryCounts: [String: Int]
    }

    let id: String
    let bankId: String
    let rng: RngDescriptor
    let input: Input
    let expectedOutput: ExpectedOutput
}

private struct ScoringFixture: Decodable {
    struct Case: Decodable {
        struct Input: Decodable {
            let items: [ScoreInputItem]
        }
        let id: String
        let input: Input
        let expectedOutput: ExamScore
    }

    let cases: [Case]
}

private struct WeakSubsectionsFixture: Decodable {
    struct RecentResultCase: Decodable {
        struct Input: Decodable {
            let existing: [Bool]
            let newest: Bool
        }
        let id: String
        let input: Input
        let expectedOutput: RecentResultOutput
    }

    struct Case: Decodable {
        struct Input: Decodable {
            let records: [QuestionProgressRecord]
            let latestExamItems: [LatestExamResultItem]
        }
        let id: String
        let input: Input
        let expectedOutput: WeakSubsectionsOutput
    }

    let recentResultCases: [RecentResultCase]
    let cases: [Case]
}

private struct RecentResultOutput: Codable, Equatable {
    let recentResults: [Bool]
}

private struct WeakSubsectionsOutput: Codable, Equatable {
    let weakSubsectionIds: [String]
}

private struct LeitnerFixture: Decodable {
    struct AnswerCase: Decodable {
        struct Input: Decodable {
            let existing: QuestionProgressRecord?
            let update: AnswerUpdate
        }
        let id: String
        let input: Input
        let expectedOutput: LeitnerAnswerOutput
    }

    struct SequenceCase: Decodable {
        struct Input: Decodable {
            let initialRecords: [QuestionProgressRecord]
            let updates: [AnswerUpdate]
        }
        let id: String
        let input: Input
        let expectedOutput: LeitnerSequenceOutput
    }

    struct DueCase: Decodable {
        struct Input: Decodable {
            let records: [QuestionProgressRecord]
            let now: String
        }
        let id: String
        let input: Input
        let expectedOutput: LeitnerDueOutput
    }

    let answerCases: [AnswerCase]
    let sequenceCases: [SequenceCase]
    let dueCases: [DueCase]
}

private struct LeitnerAnswerOutput: Codable, Equatable {
    let record: QuestionProgressRecord
}

private struct LeitnerSequenceOutput: Codable, Equatable {
    let records: [QuestionProgressRecord]
}

private struct LeitnerDueOutput: Codable, Equatable {
    let dueQuestionIds: [String]
    let dueCount: Int
}

private struct ReadinessFixture: Decodable {
    struct Case: Decodable {
        let id: String
        let input: ReadinessInput
        let expectedOutput: ReadinessResult
    }

    let cases: [Case]
}
