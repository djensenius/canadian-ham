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
        XCTAssertEqual(fuzz.displayDigest.algorithm, "FNV-1a-64 over every step display's UTF-8 bytes in order, followed by one separator byte per display")
        XCTAssertEqual(fuzz.displayDigest.separatorByte, "0x00")
        let expectedDigest = try XCTUnwrap(UInt64(fuzz.displayDigest.hex, radix: 16))
        var snapshotsByStep: [Int: CalculatorFixture.FuzzDrift.Snapshot] = [:]
        for snapshot in fuzz.snapshots {
            snapshotsByStep[snapshot.step] = snapshot
        }

        var seed = fuzz.seed
        var state = createCalculatorState()
        var displayDigest = fnv64Offset
        for index in 0..<20_000 {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            let key = fuzz.keys[Int(seed % UInt32(fuzz.keys.count))]
            state = applyCalculatorKey(state, key: key)
            displayDigest = updateDisplayDigest(displayDigest, display: state.display)
            let step = index + 1
            XCTAssertLessThanOrEqual(state.display.unicodeScalars.count, 16, "step \(step) key \(key.rawValue) display \(state.display) exceeds 16 code points")
            if let snapshot = snapshotsByStep[step] {
                XCTAssertEqual(key, snapshot.key, "snapshot key drift at step \(step)")
                XCTAssertEqual(state.display, snapshot.display, "snapshot display drift at step \(step)")
            }
        }
        XCTAssertEqual(displayDigest, expectedDigest, "fuzz display digest drift")
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

    func testUpdateCalculatorLocaleRedrawsCurrentDisplay() throws {
        let englishState = runCalculatorKeys([.one, .decimalPoint, .five], locale: .en)
        XCTAssertEqual(englishState.display, "1.5")
        XCTAssertEqual(englishState.displayValue.visual, "1.5")

        let frenchState = updateCalculatorLocale(englishState, locale: .fr)
        XCTAssertEqual(frenchState.locale, .fr)
        XCTAssertEqual(frenchState.display, "1,5")
        XCTAssertEqual(frenchState.displayValue.visual, "1,5")
        XCTAssertEqual(frenchState.displayValue.spoken.fr, "1,5")
        XCTAssertEqual(frenchState.currentEntry, englishState.currentEntry)
        XCTAssertEqual(frenchState.displayedValue, englishState.displayedValue)
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

private let fnv64Offset: UInt64 = 0xcbf29ce484222325
private let fnv64Prime: UInt64 = 0x100000001b3
private let digestSeparatorByte: UInt8 = 0x00

private func updateDisplayDigest(_ hash: UInt64, display: String) -> UInt64 {
    var next = hash
    for byte in display.utf8 {
        next = fnv64(next, byte: byte)
    }
    return fnv64(next, byte: digestSeparatorByte)
}

private func fnv64(_ hash: UInt64, byte: UInt8) -> UInt64 {
    (hash ^ UInt64(byte)) &* fnv64Prime
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

        struct DisplayDigest: Decodable {
            let algorithm: String
            let separatorByte: String
            let hex: String
        }

        let seed: UInt32
        let steps: Int
        let snapshotEvery: Int
        let displayDigest: DisplayDigest
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
