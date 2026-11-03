import CoreFoundation
import Foundation
import XCTest
@testable import CanadianHamEngine

final class FixtureTests: XCTestCase {
    func testEveryEngineFixtureMatchesSwiftEngine() throws {
        let paths = try engineFixturePaths()
        XCTAssertFalse(paths.isEmpty, "expected at least one fixture JSON file")
        for path in paths {
            let data = try Data(contentsOf: path)
            let header = try JSONDecoder().decode(FixtureHeader.self, from: data)
            let fixtureJSON = try fixtureJSONObject(data)
            XCTAssertEqual(header.schemaVersion, 1, path.path(percentEncoded: false).fixtureRelativePath())
            switch header.kind {
            case "rng-vectors":
                try validateRngVectors(data, fixtureJSON: fixtureJSON)
            case "exam-generation":
                try validateExamGeneration(data, fixtureJSON: fixtureJSON)
            case "scoring":
                try validateScoring(data, fixtureJSON: fixtureJSON)
            case "weak-subsections":
                try validateWeakSubsections(data, fixtureJSON: fixtureJSON)
            case "leitner":
                try validateLeitner(data, fixtureJSON: fixtureJSON)
            case "readiness":
                try validateReadiness(data, fixtureJSON: fixtureJSON)
            default:
                XCTFail("unsupported fixture kind: \(header.kind)")
            }
        }
    }

    func testJSONComparatorRejectsExtraExpectedOutputKey() throws {
        struct ProbeOutput: Codable {
            let value: Int
        }

        let actual = try encodedJSONObject(ProbeOutput(value: 1))
        let expected = try jsonObject(#"{"value":1,"extra":"fixture-only"}"#)
        XCTAssertEqual(jsonMismatch(actual: actual, expected: expected)?.description, "$.extra: missing key")
    }

    private func validateRngVectors(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(RngVectorsFixture.self, from: data)
        let expectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "cases")
        for (index, vector) in fixture.cases.enumerated() {
            XCTAssertEqual(vector.rng.algorithm, rngAlgorithm, vector.id)
            try assertFixtureOutput(
                RngVectorsFixture.ExpectedOutput(first8Uint32: try firstUint32Values(seed: vector.rng.seed, count: 8)),
                equals: expectedOutputs[index],
                vector.id
            )
        }
    }

    private func validateExamGeneration(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(ExamGenerationFixture.self, from: data)
        XCTAssertEqual(fixture.rng.algorithm, rngAlgorithm)
        let generated = try generateExam(ExamGenerationInput(
            bankId: fixture.bankId,
            seed: fixture.rng.seed,
            subsections: fixture.input.subsections,
            answerSourceIndexes: fixture.input.answerSourceIndexes,
            requireFullMockExam: fixture.input.requireFullMockExam ?? false
        ))
        let inputSubsectionIds = Set(fixture.input.subsections.map(\.id))
        let outputSubsectionIds = Set(generated.items.map(\.subsectionId))
        let output = ExamGenerationFixture.ExpectedOutput(
            items: generated.items,
            examQuestionCount: generated.items.count,
            oneQuestionPerInputSubsection: outputSubsectionIds.count == inputSubsectionIds.count && outputSubsectionIds == inputSubsectionIds,
            choicePermutationDefinition: choicePermutationDefinition,
            categoryCounts: categoryCounts(generated.items)
        )
        try assertFixtureOutput(output, equals: try expectedOutput(in: fixtureJSON), fixture.id)

        for item in generated.items {
            XCTAssertEqual(item.choicePermutation.sorted(), [0, 1, 2, 3], fixture.id)
        }
    }

    private func validateScoring(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(ScoringFixture.self, from: data)
        let expectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "cases")
        for (index, testCase) in fixture.cases.enumerated() {
            try assertFixtureOutput(try scoreExam(testCase.input.items, bankId: testCase.input.bankId), equals: expectedOutputs[index], testCase.id)
        }
    }

    private func validateWeakSubsections(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(WeakSubsectionsFixture.self, from: data)
        let recentExpectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "recentResultCases")
        for (index, testCase) in fixture.recentResultCases.enumerated() {
            try assertFixtureOutput(
                RecentResultOutput(recentResults: appendRecentResult(testCase.input.existing, newest: testCase.input.newest)),
                equals: recentExpectedOutputs[index],
                testCase.id
            )
        }
        let expectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "cases")
        for (index, testCase) in fixture.cases.enumerated() {
            try assertFixtureOutput(
                WeakSubsectionsOutput(weakSubsectionIds: weakSubsectionIds(records: testCase.input.records, latestExamItems: testCase.input.latestExamItems)),
                equals: expectedOutputs[index],
                testCase.id
            )
        }
    }

    private func validateLeitner(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(LeitnerFixture.self, from: data)
        let answerExpectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "answerCases")
        for (index, testCase) in fixture.answerCases.enumerated() {
            try assertFixtureOutput(
                LeitnerAnswerOutput(record: try applyAnswer(existing: testCase.input.existing, update: testCase.input.update)),
                equals: answerExpectedOutputs[index],
                testCase.id
            )
        }
        let sequenceExpectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "sequenceCases")
        for (index, testCase) in fixture.sequenceCases.enumerated() {
            try assertFixtureOutput(
                LeitnerSequenceOutput(records: try applyAnswerSequence(initialRecords: testCase.input.initialRecords, updates: testCase.input.updates)),
                equals: sequenceExpectedOutputs[index],
                testCase.id
            )
        }
        let dueExpectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "dueCases")
        for (index, testCase) in fixture.dueCases.enumerated() {
            try assertFixtureOutput(
                LeitnerDueOutput(
                    dueQuestionIds: try dueQuestionIds(records: testCase.input.records, now: testCase.input.now),
                    dueCount: try dueCount(records: testCase.input.records, now: testCase.input.now)
                ),
                equals: dueExpectedOutputs[index],
                testCase.id
            )
        }
    }

    private func validateReadiness(_ data: Data, fixtureJSON: [String: Any]) throws {
        let fixture = try JSONDecoder().decode(ReadinessFixture.self, from: data)
        let expectedOutputs = try caseExpectedOutputs(in: fixtureJSON, arrayKey: "cases")
        for (index, testCase) in fixture.cases.enumerated() {
            try assertFixtureOutput(try computeReadiness(testCase.input), equals: expectedOutputs[index], testCase.id)
        }
    }
}

private let choicePermutationDefinition = "choicePermutation[displayIndex] = sourceIndex; sourceIndex 0 is the correct answer"

private let fixtureOutputEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return encoder
}()

private func assertFixtureOutput<T: Encodable>(
    _ actual: T,
    equals expected: Any,
    _ message: String,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    let actualObject = try encodedJSONObject(actual)
    if let mismatch = jsonMismatch(actual: actualObject, expected: expected) {
        XCTFail("\(message): \(mismatch)", file: file, line: line)
    }
}

private func encodedJSONObject<T: Encodable>(_ value: T) throws -> Any {
    try JSONSerialization.jsonObject(with: fixtureOutputEncoder.encode(value))
}

private func fixtureJSONObject(_ data: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard let fixture = object as? [String: Any] else {
        throw EngineError("fixture root must be a JSON object")
    }
    return fixture
}

private func jsonObject(_ source: String) throws -> Any {
    try JSONSerialization.jsonObject(with: Data(source.utf8))
}

private func expectedOutput(in fixtureJSON: [String: Any]) throws -> Any {
    guard let expectedOutput = fixtureJSON["expectedOutput"] else {
        throw EngineError("fixture is missing expectedOutput")
    }
    return expectedOutput
}

private func caseExpectedOutputs(in fixtureJSON: [String: Any], arrayKey: String) throws -> [Any] {
    guard let cases = fixtureJSON[arrayKey] as? [[String: Any]] else {
        throw EngineError("fixture is missing \(arrayKey)")
    }
    return try cases.enumerated().map { index, testCase in
        guard let expectedOutput = testCase["expectedOutput"] else {
            throw EngineError("fixture \(arrayKey)[\(index)] is missing expectedOutput")
        }
        return expectedOutput
    }
}

private struct JSONMismatch: CustomStringConvertible {
    let path: String
    let message: String

    var description: String {
        "\(path): \(message)"
    }
}

private func jsonMismatch(actual: Any, expected: Any, path: String = "$") -> JSONMismatch? {
    if let actualDictionary = actual as? [String: Any], let expectedDictionary = expected as? [String: Any] {
        let actualKeys = Set(actualDictionary.keys)
        let expectedKeys = Set(expectedDictionary.keys)
        if let missing = expectedKeys.subtracting(actualKeys).sorted().first {
            return JSONMismatch(path: "\(path).\(missing)", message: "missing key")
        }
        if let unexpected = actualKeys.subtracting(expectedKeys).sorted().first {
            return JSONMismatch(path: "\(path).\(unexpected)", message: "unexpected key")
        }
        for key in expectedKeys.sorted() {
            if let mismatch = jsonMismatch(actual: actualDictionary[key]!, expected: expectedDictionary[key]!, path: "\(path).\(key)") {
                return mismatch
            }
        }
        return nil
    }

    if let actualArray = actual as? [Any], let expectedArray = expected as? [Any] {
        guard actualArray.count == expectedArray.count else {
            return JSONMismatch(path: path, message: "array count \(actualArray.count) != \(expectedArray.count)")
        }
        for index in expectedArray.indices {
            if let mismatch = jsonMismatch(actual: actualArray[index], expected: expectedArray[index], path: "\(path)[\(index)]") {
                return mismatch
            }
        }
        return nil
    }

    if actual is NSNull, expected is NSNull {
        return nil
    }

    if isJSONBoolean(actual) || isJSONBoolean(expected) {
        guard isJSONBoolean(actual), isJSONBoolean(expected), (actual as! NSNumber).boolValue == (expected as! NSNumber).boolValue else {
            return JSONMismatch(path: path, message: "\(describeJSONValue(actual)) != \(describeJSONValue(expected))")
        }
        return nil
    }

    if let actualNumber = actual as? NSNumber, let expectedNumber = expected as? NSNumber {
        if isFloatingPointJSONNumber(actualNumber) || isFloatingPointJSONNumber(expectedNumber) {
            return actualNumber.doubleValue == expectedNumber.doubleValue
                ? nil
                : JSONMismatch(path: path, message: "\(actualNumber.doubleValue) != \(expectedNumber.doubleValue)")
        }
        return actualNumber.int64Value == expectedNumber.int64Value
            ? nil
            : JSONMismatch(path: path, message: "\(actualNumber.int64Value) != \(expectedNumber.int64Value)")
    }

    if let actualString = actual as? String, let expectedString = expected as? String {
        return actualString == expectedString
            ? nil
            : JSONMismatch(path: path, message: "\(describeJSONValue(actualString)) != \(describeJSONValue(expectedString))")
    }

    return JSONMismatch(path: path, message: "\(describeJSONValue(actual)) != \(describeJSONValue(expected))")
}

private func isJSONBoolean(_ value: Any) -> Bool {
    guard let number = value as? NSNumber else { return false }
    return CFGetTypeID(number) == CFBooleanGetTypeID()
}

private func isFloatingPointJSONNumber(_ number: NSNumber) -> Bool {
    let type = String(cString: number.objCType)
    return type == "f" || type == "d"
}

private func describeJSONValue(_ value: Any) -> String {
    if value is NSNull { return "null" }
    if isJSONBoolean(value) { return (value as! NSNumber).boolValue ? "true" : "false" }
    if let string = value as? String { return "\"\(string)\"" }
    return String(describing: value)
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

    struct ExpectedOutput: Codable {
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

    struct ExpectedOutput: Codable {
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
            let bankId: String
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
