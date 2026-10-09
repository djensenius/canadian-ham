import Foundation
import XCTest
@testable import CanadianHamEngine

final class ValidationTests: XCTestCase {
    private let oneSubsection = [ExamSubsectionInput(id: "B-001-001", questionIds: ["B-001-001-001"])]

    func testExamGenerationRequiresCanonicalAnswerSourceIndexes() {
        XCTAssertThrowsError(try generateExam(ExamGenerationInput(
            bankId: "basic-2025-07-15",
            seed: "seed",
            subsections: oneSubsection,
            answerSourceIndexes: [3, 2, 1, 0]
        ))) { error in
            XCTAssertEqual((error as? EngineError)?.message, "answerSourceIndexes must be exactly [0,1,2,3]")
        }

        XCTAssertThrowsError(try generateExam(ExamGenerationInput(
            bankId: "basic-2025-07-15",
            seed: "seed",
            subsections: oneSubsection,
            answerSourceIndexes: [0, 5, 6, 7]
        ))) { error in
            XCTAssertEqual((error as? EngineError)?.message, "answerSourceIndexes must be exactly [0,1,2,3]")
        }
    }

    func testFullMockExamGenerationUsesActiveBankSubsectionCount() {
        XCTAssertThrowsError(try generateExam(ExamGenerationInput(
            bankId: syntheticAdvancedBankId,
            seed: "seed",
            subsections: makeSubsections(prefix: "A", count: 100),
            requireFullMockExam: true
        ))) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "full mock exam generation for advanced-synthetic requires exactly 50 subsections; received 100"
            )
        }

        XCTAssertThrowsError(try generateExam(ExamGenerationInput(
            bankId: basicBankId,
            seed: "seed",
            subsections: makeSubsections(prefix: "B", count: 50),
            requireFullMockExam: true
        ))) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "full mock exam generation for basic-2025-07-15 requires exactly 100 subsections; received 50"
            )
        }
    }

    func testPracticeExamGenerationDoesNotRequireKnownBankRulesUnlessFullMockIsRequested() throws {
        let generated = try generateExam(ExamGenerationInput(bankId: "unknown-bank", seed: "seed", subsections: oneSubsection))
        XCTAssertEqual(generated.bankId, "unknown-bank")
        XCTAssertEqual(generated.items.count, 1)

        XCTAssertThrowsError(try generateExam(ExamGenerationInput(
            bankId: "unknown-bank",
            seed: "seed",
            subsections: oneSubsection,
            requireFullMockExam: true
        ))) { error in
            XCTAssertEqual((error as? EngineError)?.message, "unsupported bankId unknown-bank")
        }
    }

    func testBankRulesAcceptFutureSchemaValidBasicIds() throws {
        let rules = try rulesForBankId("basic-2026-09-30")
        XCTAssertEqual(rules.bankId, "basic-2026-09-30")
        XCTAssertEqual(rules.mockExamQuestionCount, 100)
        XCTAssertEqual(rules.subsectionCount, 100)
        XCTAssertEqual(rules.hasHonours, true)
    }

    func testBankRulesAcceptOnlySchemaValidBasicAndAdvancedIds() throws {
        XCTAssertEqual(try rulesForBankId("advanced-2026-01-15").bankId, "advanced-2026-01-15")
        for bankId in ["basic-", "basic-2026-1-15", "basic-2026_01_15", "basic-2026-01-15-extra", "advanced-", "advanced-X", "advanced-2026_01", "advanced-2026 01"] {
            XCTAssertThrowsError(try rulesForBankId(bankId)) { error in
                XCTAssertEqual((error as? EngineError)?.message, "unsupported bankId \(bankId)")
            }
        }
    }

    func testScoreExamRejectsUnsupportedBankIds() {
        XCTAssertThrowsError(try scoreExam([ScoreInputItem(questionId: "B-001-001-001", selectedSourceIndex: 0)], bankId: "unknown-bank")) { error in
            XCTAssertEqual((error as? EngineError)?.message, "unsupported bankId unknown-bank")
        }
    }

    func testAdvancedReadinessTreatsSeventyPercentPassThresholdAsInclusive() throws {
        let categoryBreakdown = [CategoryBreakdownEntry(categoryId: "A-001", correct: 50, total: 50, percent: 100)]
        let result = try computeReadiness(ReadinessInput(
            bankId: syntheticAdvancedBankId,
            completedExams: [
                ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 35, total: 50, percent: 70), categoryBreakdown: categoryBreakdown),
                ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 35, total: 50, percent: 70), categoryBreakdown: categoryBreakdown),
            ],
            dueReviewCount: 0
        ))

        XCTAssertEqual(result.state, .passReady)
        XCTAssertEqual(result.consideredExamCount, 2)
        XCTAssertEqual(result.consideredSubmittedAt, ["2026-01-03T00:00:00.000Z", "2026-01-02T00:00:00.000Z"])
        XCTAssertEqual(result.reasons, [.examThreshold(threshold: 70, countAtOrAbove: 2)])
    }

    func testAdvancedReadinessDoesNotCountExamsBelowSeventyPercent() throws {
        let categoryBreakdown = [CategoryBreakdownEntry(categoryId: "A-001", correct: 50, total: 50, percent: 100)]
        let result = try computeReadiness(ReadinessInput(
            bankId: syntheticAdvancedBankId,
            completedExams: [
                ReadinessExamAttempt(submittedAt: "2026-01-03T00:00:00.000Z", score: ReadinessScore(correct: 35, total: 50, percent: 70), categoryBreakdown: categoryBreakdown),
                ReadinessExamAttempt(submittedAt: "2026-01-02T00:00:00.000Z", score: ReadinessScore(correct: 34, total: 50, percent: 68), categoryBreakdown: categoryBreakdown),
            ],
            dueReviewCount: 0
        ))

        XCTAssertEqual(result.state, .needsReview)
        XCTAssertEqual(result.consideredExamCount, 2)
        XCTAssertEqual(result.consideredSubmittedAt, ["2026-01-03T00:00:00.000Z", "2026-01-02T00:00:00.000Z"])
        XCTAssertEqual(result.reasons, [])
    }

    func testSharedBankRulesFixtureAgreesWithSwiftEngine() throws {
        let fixture = try JSONDecoder().decode(SharedBankRulesFixture.self, from: Data(contentsOf: sharedBankRulesFixtureURL()))
        XCTAssertEqual(fixture.schemaVersion, 1)
        for expected in fixture.banks {
            let actual = try rulesForBankId(expected.bankId)
            XCTAssertEqual(actual.bankId, expected.bankId)
            XCTAssertEqual(actual.categoryIds, expected.categoryIds)
            XCTAssertEqual(actual.mockExamQuestionCount, expected.mockExamQuestionCount)
            XCTAssertEqual(actual.subsectionCount, expected.subsectionCount)
            XCTAssertEqual(actual.passPercent, expected.passPercent)
            XCTAssertEqual(actual.hasHonours, expected.hasHonours)
            XCTAssertEqual(actual.honoursPercent, expected.honoursPercent)
        }
    }

    func testReadinessRejectsDuplicateSubmittedAtTimestamps() {
        let attempt = ReadinessExamAttempt(
            submittedAt: "2026-01-05T00:00:00.000Z",
            score: ReadinessScore(correct: 90, total: 100, percent: 90),
            categoryBreakdown: [CategoryBreakdownEntry(categoryId: "B-001", correct: 9, total: 10, percent: 90)]
        )

        XCTAssertThrowsError(try computeReadiness(ReadinessInput(completedExams: [attempt, attempt], dueReviewCount: 0))) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "completedExams must not contain duplicate submittedAt timestamp 2026-01-05T00:00:00.000Z"
            )
        }
    }

    func testEngineTimestampInputsRequireCanonicalMillisecondUTCFormat() {
        XCTAssertThrowsError(try applyAnswer(
            existing: nil,
            update: AnswerUpdate(
                questionId: "B-006-004-001",
                bankId: "basic-2025-07-15",
                isCorrect: true,
                now: "2026-01-02T00:00:00Z"
            )
        )) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "update.now must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ"
            )
        }
    }

    func testTimestampParserRejectsImpossibleDatesAndNonAsciiDigits() {
        assertInvalidTimestamp("2023-02-29T00:00:00.000Z")
        assertInvalidTimestamp("1900-02-29T00:00:00.000Z")
        assertInvalidTimestamp("2026-02-30T00:00:00.000Z")
        assertInvalidTimestamp("2026-01-02T24:00:00.000Z")
        assertInvalidTimestamp("２０２６-01-02T00:00:00.000Z")
    }

    func testTimestampParserAcceptsLeapDayInLeapYears() {
        XCTAssertNoThrow(try CanonicalTimestamp.require("2024-02-29T00:00:00.000Z", fieldName: "timestamp"))
        XCTAssertNoThrow(try CanonicalTimestamp.require("2000-02-29T00:00:00.000Z", fieldName: "timestamp"))
    }

    func testTimestampAdditionCrossesMonthAndYearBoundaries() throws {
        XCTAssertEqual(
            try CanonicalTimestamp.addSeconds("2026-01-31T00:00:00.000Z", seconds: 86_400),
            "2026-02-01T00:00:00.000Z"
        )
        XCTAssertEqual(
            try CanonicalTimestamp.addSeconds("2026-12-31T00:00:00.000Z", seconds: 86_400),
            "2027-01-01T00:00:00.000Z"
        )
    }

    func testTimestampFormattingRejectsYearsOutsideCanonicalRange() {
        XCTAssertThrowsError(try CanonicalTimestamp.addSeconds("9999-12-31T00:00:00.000Z", seconds: 86_400)) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "timestamp year 10000 is outside supported canonical UTC range 0000...9999"
            )
        }
    }

    func testApplyAnswerRejectsOutOfRangeLeitnerBoxes() {
        let update = AnswerUpdate(
            questionId: "B-006-004-001",
            bankId: "basic-2025-07-15",
            isCorrect: true,
            now: "2026-01-02T00:00:00.000Z"
        )

        XCTAssertThrowsError(try applyAnswer(existing: progressRecord(box: -1), update: update)) { error in
            XCTAssertEqual((error as? EngineError)?.message, "leitner.box out of range: -1")
        }
        XCTAssertThrowsError(try applyAnswer(existing: progressRecord(box: 6), update: update)) { error in
            XCTAssertEqual((error as? EngineError)?.message, "leitner.box out of range: 6")
        }
    }

    private func makeSubsections(prefix: String, count: Int) -> [ExamSubsectionInput] {
        (1...count).map { index in
            let ordinal = String(format: "%03d", index)
            let subsectionId = "\(prefix)-001-\(ordinal)"
            return ExamSubsectionInput(id: subsectionId, questionIds: ["\(subsectionId)-001"])
        }
    }

    private func assertInvalidTimestamp(_ value: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try CanonicalTimestamp.require(value, fieldName: "timestamp"), file: file, line: line) { error in
            XCTAssertEqual(
                (error as? EngineError)?.message,
                "timestamp must use canonical UTC timestamp format YYYY-MM-DDTHH:MM:SS.sssZ",
                file: file,
                line: line
            )
        }
    }

    private func progressRecord(box: Int) -> QuestionProgressRecord {
        QuestionProgressRecord(
            questionId: "B-006-004-001",
            bankId: "basic-2025-07-15",
            attempts: 1,
            correctAttempts: 1,
            lastAttemptedAt: "2026-01-01T00:00:00.000Z",
            lastResult: .correct,
            recentResults: [true],
            leitner: LeitnerState(box: box, dueAt: "2026-01-02T00:00:00.000Z")
        )
    }
}

private struct SharedBankRulesFixture: Decodable {
    let schemaVersion: Int
    let banks: [SharedBankRules]
}

private struct SharedBankRules: Decodable {
    let bankId: String
    let categoryIds: [String]
    let mockExamQuestionCount: Int
    let subsectionCount: Int
    let passPercent: Double
    let hasHonours: Bool
    let honoursPercent: Double?
}

private func sharedBankRulesFixtureURL() throws -> URL {
    var cursor = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    for _ in 0..<10 {
        let candidate = cursor.appending(path: "fixtures/banks/rules.json")
        if FileManager.default.fileExists(atPath: candidate.path(percentEncoded: false)) {
            return candidate
        }
        let parent = cursor.deletingLastPathComponent()
        if parent.path(percentEncoded: false) == cursor.path(percentEncoded: false) {
            break
        }
        cursor = parent
    }
    throw EngineError("could not resolve fixtures/banks/rules.json relative to #filePath")
}
