@testable import CanadianHam
import CanadianHamEngine
import CoreGraphics
import SwiftUI
import XCTest

@MainActor
final class DuoLayoutPolicyTests: XCTestCase {
    func testUnfoldedIPhoneSizeUsesInspectorLayout() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 669, height: 951),
            verticalSizeClass: .regular
        ))
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 669, height: 951),
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ))
    }

    func testClosedAndLandscapeIPhoneSizesKeepSheetLayout() {
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 382, height: 644),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 852, height: 393),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ), "Forced-regular iPhone landscape keeps the task-44.3 sheet path because its vertical size class is compact.")
    }

    func testIPadInspectorRuleRemainsSizeClassDriven() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .pad,
            containerSize: CGSize(width: 744, height: 1_132),
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .pad,
            containerSize: CGSize(width: 744, height: 1_132),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ))
    }

    func testPracticeSessionStateCacheSurvivesLayoutReclassification() {
        let cache = PracticeSessionStateCache()
        let practiceState = cache.state(for: .all)
        practiceState.currentIndex = 3
        practiceState.selectedByQuestionId = ["B-001-002-002": 0]

        _ = AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 669, height: 951),
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        _ = AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 382, height: 644),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )

        let samePracticeState = cache.state(for: .all)
        XCTAssertTrue(samePracticeState === practiceState)
        XCTAssertEqual(samePracticeState.currentIndex, 3)
        XCTAssertEqual(samePracticeState.selectedByQuestionId["B-001-002-002"]!, 0)
    }

    func testMockExamStateSurvivesLayoutReclassification() {
        let state = MockExamState()
        state.seed = "duo-state"
        state.generatedItems = [GeneratedExamItem(position: 1, questionId: "B-001-002-002", subsectionId: "B-001-002", categoryId: "B-001", choicePermutation: [0, 1, 2, 3])]
        state.currentIndex = 0
        state.selectedByQuestionId = ["B-001-002-002": 0]
        state.flagged = ["B-001-002-002"]

        _ = AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 669, height: 951),
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        )
        _ = AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 382, height: 644),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        )

        XCTAssertEqual(state.seed, "duo-state")
        XCTAssertEqual(state.selectedByQuestionId["B-001-002-002"]!, 0)
        XCTAssertEqual(state.flagged, ["B-001-002-002"])
        XCTAssertTrue(state.hasUnfinishedCourseWork)
    }
}
