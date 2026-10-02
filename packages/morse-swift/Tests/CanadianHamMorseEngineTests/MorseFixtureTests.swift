import Foundation
import XCTest
@testable import CanadianHamMorseEngine

final class MorseFixtureTests: XCTestCase {
    func testEveryMorseFixtureMatchesSwiftEngine() throws {
        let paths = try morseFixturePaths()
        XCTAssertFalse(paths.isEmpty, "expected at least one fixture JSON file")
        for path in paths {
            let data = try Data(contentsOf: path)
            let header = try JSONDecoder().decode(FixtureHeader.self, from: data)
            XCTAssertEqual(header.schemaVersion, 1, path.path(percentEncoded: false).fixtureRelativePath())
            switch header.kind {
            case "morse-timing":
                try validateTimingFixture(data)
            case "morse-word-weighting":
                try validateWordWeightingFixture(data)
            case "morse-scoring":
                try validateScoringFixture(data)
            case "morse-validation":
                try validateValidationFixture(data)
            default:
                XCTFail("unsupported fixture kind: \(header.kind)")
            }
        }
    }

    private func validateTimingFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(TimingFixture.self, from: data)
        for testCase in fixture.cases {
            let profile = try profile(from: testCase.input.profile)
            let sequence = try textToTimedMorse(testCase.input.text, profile: profile)
            XCTAssertEqual(sequence.totalDurationSeconds, testCase.expectedOutput.totalDurationSeconds, accuracy: 1e-9, testCase.id)
            XCTAssertEqual(sequence.profile.effectiveWpm, testCase.expectedOutput.effectiveWpm, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.dotSeconds, testCase.expectedOutput.durationsSeconds.dot, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.dashSeconds, testCase.expectedOutput.durationsSeconds.dash, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.intraCharacterGapSeconds, testCase.expectedOutput.durationsSeconds.intraCharacterGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.interCharacterGapSeconds, testCase.expectedOutput.durationsSeconds.interCharacterGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(sequence.profile.wordGapSeconds, testCase.expectedOutput.durationsSeconds.wordGap, accuracy: 1e-12, testCase.id)
            XCTAssertEqual(symbolCounts(sequence.symbols), testCase.expectedOutput.symbolCounts, testCase.id)
            XCTAssertEqual(sequence.symbols.last?.kind.rawValue, testCase.expectedOutput.lastSymbolKind, testCase.id)
        }
    }

    private func validateWordWeightingFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(WordWeightingFixture.self, from: data)
        for testCase in fixture.cases {
            let output = try weightedCharacterCount(testCase.input.text)
            XCTAssertEqual(output.weightedCharacters, testCase.expectedOutput.weightedCharacters, testCase.id)
            XCTAssertEqual(output.unweightedCharacters, testCase.expectedOutput.unweightedCharacters, testCase.id)
        }
    }

    private func validateScoringFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ScoringFixture.self, from: data)
        for testCase in fixture.cases {
            let output = try scoreMorseCopy(expected: testCase.input.expected, received: testCase.input.received)
            XCTAssertEqual(output, testCase.expectedOutput, testCase.id)
        }
    }

    private func validateValidationFixture(_ data: Data) throws {
        let fixture = try JSONDecoder().decode(ValidationFixture.self, from: data)
        for testCase in fixture.cases {
            let output = validateMorseText(testCase.input.text)
            XCTAssertEqual(output, testCase.expectedOutput, testCase.id)
        }
    }

    private func profile(from input: TimingProfileInput) throws -> MorseTimingProfile {
        if let name = input.name {
            guard let profileName = MorseProfileName(rawValue: name) else {
                throw MorseEngineError.unknownProfile(name)
            }
            return profileForName(profileName)
        }
        guard let characterWpm = input.characterWpm, let effectiveWpm = input.effectiveWpm else {
            throw MorseEngineError.invalidSpeed("fixture profile must name a profile or provide characterWpm/effectiveWpm")
        }
        return try farnsworthTiming(characterWpm: characterWpm, effectiveWpm: effectiveWpm)
    }
}

private struct FixtureHeader: Decodable {
    let schemaVersion: Int
    let kind: String
}

private struct TimingFixture: Decodable {
    let cases: [TimingCase]
}

private struct TimingCase: Decodable {
    let id: String
    let input: TimingInput
    let expectedOutput: TimingOutput
}

private struct TimingInput: Decodable {
    let text: String
    let profile: TimingProfileInput
}

private struct TimingProfileInput: Decodable {
    let name: String?
    let characterWpm: Double?
    let effectiveWpm: Double?
}

private struct TimingOutput: Decodable {
    let totalDurationSeconds: Double
    let durationsSeconds: TimingDurations
    let effectiveWpm: Double
    let symbolCounts: SymbolCounts
    let lastSymbolKind: String
}

private struct TimingDurations: Decodable {
    let dot: Double
    let dash: Double
    let intraCharacterGap: Double
    let interCharacterGap: Double
    let wordGap: Double
}

private struct SymbolCounts: Decodable, Equatable {
    let dot: Int
    let dash: Int
    let intraCharacterGap: Int
    let interCharacterGap: Int
    let wordGap: Int
}

private struct WordWeightingFixture: Decodable {
    let cases: [WordWeightingCase]
}

private struct WordWeightingCase: Decodable {
    let id: String
    let input: TextInput
    let expectedOutput: WordWeightingOutput
}

private struct TextInput: Decodable {
    let text: String
}

private struct WordWeightingOutput: Decodable {
    let weightedCharacters: Int
    let unweightedCharacters: Int
    let needsOfficialRic1Section83Sample: Bool
}

private struct ScoringFixture: Decodable {
    let cases: [ScoringCase]
}

private struct ScoringCase: Decodable {
    let id: String
    let input: ScoringInput
    let expectedOutput: MorseExamScore
}

private struct ScoringInput: Decodable {
    let expected: String
    let received: String
}

private struct ValidationFixture: Decodable {
    let cases: [ValidationCase]
}

private struct ValidationCase: Decodable {
    let id: String
    let input: TextInput
    let expectedOutput: ValidationResult
}

private func symbolCounts(_ symbols: [TimedMorseSymbol]) -> SymbolCounts {
    SymbolCounts(
        dot: symbols.filter { $0.kind == .dot }.count,
        dash: symbols.filter { $0.kind == .dash }.count,
        intraCharacterGap: symbols.filter { $0.kind == .intraCharacterGap }.count,
        interCharacterGap: symbols.filter { $0.kind == .interCharacterGap }.count,
        wordGap: symbols.filter { $0.kind == .wordGap }.count
    )
}

private func morseFixturePaths() throws -> [URL] {
    let root = try repositoryRoot()
    return try jsonFiles(in: root.appending(path: "fixtures/morse")).sorted { lhs, rhs in
        lhs.path(percentEncoded: false) < rhs.path(percentEncoded: false)
    }
}

private func repositoryRoot() throws -> URL {
    var cursor = URL(fileURLWithPath: #filePath)
    while cursor.path(percentEncoded: false) != "/" {
        let candidate = cursor.appending(path: "fixtures/morse")
        if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            return cursor
        }
        cursor.deleteLastPathComponent()
    }
    throw MorseEngineError.invalidSpeed("could not locate repository root from #filePath")
}

private func jsonFiles(in directory: URL) throws -> [URL] {
    let entries = try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey]
    )
    var paths: [URL] = []
    for entry in entries {
        let values = try entry.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
        if values.isDirectory == true {
            paths.append(contentsOf: try jsonFiles(in: entry))
        } else if values.isRegularFile == true, entry.pathExtension == "json" {
            paths.append(entry)
        }
    }
    return paths
}

private extension String {
    func fixtureRelativePath() -> String {
        guard let range = range(of: "fixtures/") else { return self }
        return String(self[range.lowerBound...])
    }
}
