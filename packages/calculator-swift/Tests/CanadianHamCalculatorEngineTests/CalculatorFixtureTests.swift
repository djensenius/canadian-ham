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
            if let expectedDisplayValue = testCase.expectedDisplayValue {
                XCTAssertEqual(state.displayValue, expectedDisplayValue, testCase.id)
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

    let schemaVersion: Int
    let kind: String
    let cases: [Case]
}

private struct CalculatorFixtureError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
