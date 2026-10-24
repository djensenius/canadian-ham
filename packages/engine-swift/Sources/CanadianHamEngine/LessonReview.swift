import Foundation

public struct LessonReviewPool: Codable, Equatable, Sendable {
    public let lessonId: String
    public let questionIds: [String]
    public init(lessonId: String, questionIds: [String]) {
        self.lessonId = lessonId
        self.questionIds = questionIds
    }
}
public struct LessonReviewItem: Codable, Equatable, Sendable {
    public let lessonId: String
    public let questionId: String
}

/// Pools follow Learn's recommended order; exclusions include the current taught pool.
public func selectLessonReviewItems(orderedPools: [LessonReviewPool], lessonId: String, excludedQuestionIds: [String], seed: String) throws -> [LessonReviewItem] {
    guard let index = orderedPools.firstIndex(where: { $0.lessonId == lessonId }), index > 0 else { return [] }
    var seen = Set(excludedQuestionIds)
    var recent: [LessonReviewItem] = []
    var older: [LessonReviewItem] = []
    for i in stride(from: index - 1, through: 0, by: -1) {
        let pool = orderedPools[i]
        for questionId in pool.questionIds.sorted() where seen.insert(questionId).inserted {
            let item = LessonReviewItem(lessonId: pool.lessonId, questionId: questionId)
            if i >= index - 3 { recent.append(item) } else { older.append(item) }
        }
    }
    var rng = Pcg32(seed: "\(seed):review:\(lessonId)")
    return Array(try (shuffled(recent, rng: &rng) + shuffled(older, rng: &rng)).prefix(2))
}
