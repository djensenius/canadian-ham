import Foundation
import XCTest
@testable import CanadianHamEngine

final class LessonReviewTests: XCTestCase {
    func testSharedLessonReviewFixtures() throws {
        struct Fixture: Decodable {
            struct Case: Decodable {
                let id: String
                let orderedPools: [LessonReviewPool]
                let lessonId: String
                let excludedQuestionIds: [String]
                let seed: String
                let expected: [LessonReviewItem]
            }
            let cases: [Case]
        }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let fixture = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: root.appendingPathComponent("fixtures/lesson-review.json")))
        for item in fixture.cases {
            XCTAssertEqual(try selectLessonReviewItems(orderedPools: item.orderedPools, lessonId: item.lessonId, excludedQuestionIds: item.excludedQuestionIds, seed: item.seed), item.expected, item.id)
        }
    }
}
