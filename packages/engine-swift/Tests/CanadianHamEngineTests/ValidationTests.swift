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
