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
}
