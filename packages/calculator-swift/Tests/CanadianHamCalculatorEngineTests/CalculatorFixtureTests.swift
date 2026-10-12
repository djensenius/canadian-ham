import Foundation
import XCTest
@testable import CanadianHamCalculatorEngine

final class CalculatorFixtureTests: XCTestCase {
    func testSharedCalculatorFixtureMatchesSwiftEngine() throws {
        let data = try Data(contentsOf: calculatorFixtureURL())
        let fixture = try JSONDecoder().decode(CalculatorFixture.self, from: data)
        XCTAssertEqual(fixture.schemaVersion, 1)
        XCTAssertEqual(fixture.kind, "calculator-sequences")
        XCTAssertGreaterThanOrEqual(fixture.cases.count, 60)

        for testCase in fixture.cases {
            let state = runCalculatorKeys(testCase.keys, locale: testCase.locale ?? .en)
            XCTAssertEqual(state.display, testCase.expectedDisplay, testCase.id)
            XCTAssertLessThanOrEqual(state.display.unicodeScalars.count, 16, "\(testCase.id): display \(state.display) exceeds 16 code points")
            if let expectedDisplayValue = testCase.expectedDisplayValue {
                XCTAssertEqual(state.displayValue, expectedDisplayValue, testCase.id)
            }
        }
    }

    func testSeededCalculatorFuzzKeepsDisplayWithinUIBound() throws {
        let data = try Data(contentsOf: calculatorFixtureURL())
        let fixture = try JSONDecoder().decode(CalculatorFixture.self, from: data)
        let fuzz = try XCTUnwrap(fixture.fuzzDrift)
        XCTAssertEqual(fuzz.seed, 0x44101201)
        XCTAssertEqual(fuzz.steps, 20_000)
        XCTAssertEqual(fuzz.snapshotEvery, 100)
        var snapshotsByStep: [Int: CalculatorFixture.FuzzDrift.Snapshot] = [:]
        for snapshot in fuzz.snapshots {
            snapshotsByStep[snapshot.step] = snapshot
        }

        var seed = fuzz.seed
        var state = createCalculatorState()
        for index in 0..<20_000 {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let key = fuzz.keys[Int(seed % UInt32(fuzz.keys.count))]
            state = applyCalculatorKey(state, key: key)
            let step = index + 1
            XCTAssertLessThanOrEqual(state.display.unicodeScalars.count, 16, "step \(step) key \(key.rawValue) display \(state.display) exceeds 16 code points")
            if let snapshot = snapshotsByStep[step] {
                XCTAssertEqual(key, snapshot.key, "snapshot key drift at step \(step)")
                XCTAssertEqual(state.display, snapshot.display, "snapshot display drift at step \(step)")
            }
        }
    }

    func testCalculatorStateDoesNotRetainFormulaOrTextHistory() throws {
        let state = runCalculatorKeys([.one, .add, .two, .multiply, .three, .equals, .equals])
        XCTAssertEqual(state.display, "27")
        let data = try JSONEncoder().encode(state)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNil(object["formula"])
        XCTAssertNil(object["history"])
        XCTAssertNil(object["text"])
    }

    private func calculatorFixtureURL() throws -> URL {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let fileURL = URL(fileURLWithPath: #filePath).standardizedFileURL
        let starts = [fileURL.deletingLastPathComponent(), currentDirectory]
        for start in starts {
            if let fixtureURL = findCalculatorFixture(startingAt: start) {
                return fixtureURL
            }
        }
        throw CalculatorFixtureError("could not resolve fixtures/calculator/sequences.json relative to #filePath or current directory")
    }

    private func findCalculatorFixture(startingAt start: URL) -> URL? {
        var cursor = start
        for _ in 0..<10 {
            let candidate = cursor
                .appendingPathComponent("fixtures", isDirectory: true)
                .appendingPathComponent("calculator", isDirectory: true)
                .appendingPathComponent("sequences.json", isDirectory: false)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            let parent = cursor.deletingLastPathComponent()
            if parent.path == cursor.path {
                return nil
            }
            cursor = parent
        }
        return nil
    }
}

private struct CalculatorFixture: Decodable {
    struct Case: Decodable {
        let id: String
        let locale: CalculatorLocale?
        let keys: [CalculatorKey]
        let expectedDisplay: String
        let expectedDisplayValue: CalculatorDisplayValue?
    }

    struct FuzzDrift: Decodable {
        struct Snapshot: Decodable {
            let step: Int
            let key: CalculatorKey
            let display: String
        }

        let seed: UInt32
        let steps: Int
        let snapshotEvery: Int
        let keys: [CalculatorKey]
        let snapshots: [Snapshot]
    }

    let schemaVersion: Int
    let kind: String
    let cases: [Case]
    let fuzzDrift: FuzzDrift?
}

private struct CalculatorFixtureError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
