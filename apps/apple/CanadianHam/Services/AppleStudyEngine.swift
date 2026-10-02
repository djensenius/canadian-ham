import CanadianHamEngine
import Foundation

enum PracticeScope: Hashable, Sendable {
    case all
    case category(String)
    case subsection(String)
    case weak
    case due

    var title: String {
        switch self {
        case .all: "All questions"
        case .category(let id): "Category \(id)"
        case .subsection(let id): "Subsection \(id)"
        case .weak: "Weak areas"
        case .due: "Due review"
        }
    }
}

struct PracticeQuestionItem: Identifiable, Equatable, Sendable {
    let question: BankQuestion
    let choicePermutation: [Int]

    var id: String { question.id }
}

enum AppleStudyEngine {
    static func canonicalNow(_ date: Date = Date()) throws -> String {
        try CanonicalTimestamp.string(fromEpochMilliseconds: Int64((date.timeIntervalSince1970 * 1_000).rounded()))
    }

    static func questionRecords(from bank: QuestionBank) -> [QuestionRecordLike] {
        bank.questions.map { QuestionRecordLike(id: $0.id, categoryId: $0.categoryId, subsectionId: $0.subsectionId) }
    }

    static func generatedMockExam(bank: QuestionBank, seed: String) throws -> GeneratedExam {
        try generateExam(ExamGenerationInput(
            bankId: bank.manifest.bankId,
            seed: seed,
            subsections: buildSubsectionsFromQuestions(questionRecords(from: bank)),
            requireFullMockExam: true
        ))
    }

    static func buildPracticeItems(
        bank: QuestionBank,
        scope: PracticeScope,
        progress: [QuestionProgressRecord],
        latestExamItems: [StoredExamAttemptItem],
        seed: String,
        now: String,
        limit: Int = 10
    ) throws -> [PracticeQuestionItem] {
        let eligible = try eligibleQuestions(bank: bank, scope: scope, progress: progress, latestExamItems: latestExamItems, now: now)
        let progressByQuestionId = Dictionary(uniqueKeysWithValues: progress.map { ($0.questionId, $0) })
        let due = Set(try dueQuestionIds(records: progress, now: now))
        let weak = Set(weakSubsectionIds(records: progress, latestExamItems: latestExamItems.map {
            LatestExamResultItem(questionId: $0.questionId, subsectionId: $0.subsectionId, selectedSourceIndex: $0.selectedSourceIndex)
        }))
        var rng = Pcg32(seed: seed)

        let prioritized = eligible.map { question in
            let priority: Int
            if due.contains(question.id) {
                priority = 0
            } else if progressByQuestionId[question.id] == nil {
                priority = 1
            } else if weak.contains(question.subsectionId) {
                priority = 2
            } else {
                priority = 3
            }
            return (question: question, priority: priority, tie: rng.nextUint32())
        }
        .sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            if lhs.tie != rhs.tie { return lhs.tie < rhs.tie }
            return lhs.question.id < rhs.question.id
        }

        return try prioritized.prefix(limit).enumerated().map { index, entry in
            var answerRng = Pcg32(seed: "\(seed):answer:\(index):\(entry.question.id)")
            let permutation = try shuffled([0, 1, 2, 3], rng: &answerRng)
            return PracticeQuestionItem(question: entry.question, choicePermutation: permutation)
        }
    }

    static func applyPracticeAnswer(
        progress: [QuestionProgressRecord],
        question: BankQuestion,
        selectedSourceIndex: Int,
        now: String
    ) throws -> [QuestionProgressRecord] {
        let existing = progress.first { $0.questionId == question.id }
        let updated = try applyAnswer(existing: existing, update: AnswerUpdate(
            questionId: question.id,
            bankId: question.bankId,
            isCorrect: selectedSourceIndex == 0,
            now: now
        ))
        return (progress.filter { $0.questionId != question.id } + [updated]).sorted { $0.questionId < $1.questionId }
    }

    static func buildExamAttempt(
        bank: QuestionBank,
        seed: String,
        startedAt: String,
        submittedAt: String,
        timerEnabled: Bool,
        secondsElapsed: Int,
        generatedItems: [GeneratedExamItem],
        selectedByQuestionId: [String: Int?],
        flaggedQuestionIds: Set<String>
    ) -> StoredExamAttempt {
        let items = generatedItems.map { item in
            let selected = selectedByQuestionId[item.questionId] ?? nil
            return StoredExamAttemptItem(
                position: item.position,
                questionId: item.questionId,
                subsectionId: item.subsectionId,
                categoryId: item.categoryId,
                choicePermutation: item.choicePermutation,
                selectedSourceIndex: selected,
                isCorrect: selected == 0,
                flagged: flaggedQuestionIds.contains(item.questionId)
            )
        }
        let score = scoreExam(items.map {
            ScoreInputItem(
                questionId: $0.questionId,
                categoryId: $0.categoryId,
                subsectionId: $0.subsectionId,
                selectedSourceIndex: $0.selectedSourceIndex
            )
        }, bankId: bank.manifest.bankId)
        return StoredExamAttempt(
            id: "attempt-\(submittedAt)-local-\(seed)",
            bankId: bank.manifest.bankId,
            mode: "mock-exam",
            seed: seed,
            startedAt: startedAt,
            submittedAt: submittedAt,
            timer: StoredExamTimer(enabled: timerEnabled, secondsAllowed: nil, secondsElapsed: secondsElapsed),
            items: items,
            score: StoredExamScore(
                bankId: score.bankId,
                correct: score.correct,
                total: score.total,
                percent: score.percent,
                passed: score.passed,
                honours: score.honours,
                categoryBreakdown: score.categoryBreakdown,
                weakSubsectionIds: score.weakSubsectionIds
            )
        )
    }

    static func readiness(bank: QuestionBank, progress: [QuestionProgressRecord], attempts: [StoredExamAttempt], now: String) throws -> ReadinessResult {
        let readinessAttempts = attempts.map { attempt in
            ReadinessExamAttempt(
                submittedAt: attempt.submittedAt,
                score: ReadinessScore(correct: attempt.score.correct, total: attempt.score.total, percent: attempt.score.percent),
                categoryBreakdown: attempt.score.categoryBreakdown
            )
        }
        return try computeReadiness(ReadinessInput(
            bankId: bank.manifest.bankId,
            completedExams: readinessAttempts,
            dueReviewCount: dueCount(records: progress, now: now)
        ))
    }

    static func weakSubsections(progress: [QuestionProgressRecord], latestExam: StoredExamAttempt?) -> [String] {
        weakSubsectionIds(records: progress, latestExamItems: (latestExam?.items ?? []).map {
            LatestExamResultItem(questionId: $0.questionId, subsectionId: $0.subsectionId, selectedSourceIndex: $0.selectedSourceIndex)
        })
    }

    private static func eligibleQuestions(
        bank: QuestionBank,
        scope: PracticeScope,
        progress: [QuestionProgressRecord],
        latestExamItems: [StoredExamAttemptItem],
        now: String
    ) throws -> [BankQuestion] {
        switch scope {
        case .all:
            return bank.questions
        case .category(let categoryId):
            return bank.questions.filter { $0.categoryId == categoryId }
        case .subsection(let subsectionId):
            return bank.questions.filter { $0.subsectionId == subsectionId }
        case .due:
            let due = Set(try dueQuestionIds(records: progress, now: now))
            return bank.questions.filter { due.contains($0.id) }
        case .weak:
            let weak = Set(weakSubsectionIds(records: progress, latestExamItems: latestExamItems.map {
                LatestExamResultItem(questionId: $0.questionId, subsectionId: $0.subsectionId, selectedSourceIndex: $0.selectedSourceIndex)
            }))
            return bank.questions.filter { weak.contains($0.subsectionId) }
        }
    }
}
