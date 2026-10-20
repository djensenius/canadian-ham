@testable import CanadianHam
import XCTest

final class RootNavigationMappingTests: XCTestCase {
    func testEmptyCompactPathMapsToHome() {
        XCTAssertEqual(RootNavigationMapping.splitState(for: []), SplitNavigationState(selection: .home, path: []))
    }

    func testEveryRootSelectionRoundTrips() {
        let cases: [(SidebarSelection, [RootNavigationRoute])] = [
            (.home, [.section(.home)]),
            (.learn, [.section(.learn)]),
            (.practiceHub, [.section(.practice)]),
            (.practice(.all), [.section(.practice), .practice(.all)]),
            (.practice(.weak), [.section(.practice), .practice(.weak)]),
            (.practice(.due), [.section(.practice), .practice(.due)]),
            (.practice(.category("B-001")), [.section(.practice), .practice(.category("B-001"))]),
            (.practice(.subsection("B-001-002")), [.section(.practice), .practice(.subsection("B-001-002"))]),
            (.mockExam, [.section(.practice), .mockExam]),
            (.morse, [.section(.morse)]),
            (.settings, [.section(.settings)]),
            (.about, [.section(.settings), .about])
        ]
        for (selection, compactPath) in cases {
            let split = SplitNavigationState(selection: selection, path: [])
            XCTAssertEqual(RootNavigationMapping.splitState(for: compactPath), split)
            XCTAssertEqual(RootNavigationMapping.compactPath(for: split), compactPath)
        }
    }

    func testEveryLearnRouteRoundTripsWithItsWholeStack() {
        let routes: [LearnRoute] = [
            .module("M-001"), .lesson("L-001-01"),
            .lessonSection("L-001-01", "exam-day"), .lessonQuiz("QZ-L-001-01-A")
        ]
        for count in 1...routes.count {
            let path = Array(routes.prefix(count))
            let compact: [RootNavigationRoute] = [.section(.learn)] + path.map { .learn($0) }
            let split = SplitNavigationState(selection: .learn, path: path)
            XCTAssertEqual(RootNavigationMapping.splitState(for: compact), split)
            XCTAssertEqual(RootNavigationMapping.compactPath(for: split), compact)
        }
    }

    func testPracticeHintLessonStackKeepsSessionAsSplitSelection() {
        let path: [LearnRoute] = [.lessonSection("L-006-03", "wavelength-and-frequency"), .lessonQuiz("QZ-L-006-03-A")]
        let compact: [RootNavigationRoute] = [.section(.practice), .practice(.all)] + path.map { .learn($0) }
        let split = SplitNavigationState(selection: .practice(.all), path: path)
        XCTAssertEqual(RootNavigationMapping.splitState(for: compact), split)
        XCTAssertEqual(RootNavigationMapping.compactPath(for: split), compact)
    }

    func testCompactHomeSessionAndSectionPushesUseVisibleDestination() {
        XCTAssertEqual(RootNavigationMapping.splitState(for: [.section(.home), .practice(.due)]), SplitNavigationState(selection: .practice(.due), path: []))
        XCTAssertEqual(RootNavigationMapping.splitState(for: [.section(.home), .mockExam]), SplitNavigationState(selection: .mockExam, path: []))
        XCTAssertEqual(RootNavigationMapping.splitState(for: [.section(.settings), .section(.morse)]), SplitNavigationState(selection: .morse, path: []))
    }

    @MainActor
    func testSessionToolStateSurvivesViewOwnershipAndResetsWithNewSession() {
        let cache = PracticeSessionStateCache()
        let practice = cache.state(for: .all)
        practice.selectedExamTool = .hint
        XCTAssertEqual(cache.state(for: .all).selectedExamTool, .hint)
        XCTAssertNil(cache.state(for: .due).selectedExamTool)
        cache.clear()
        XCTAssertNil(cache.state(for: .all).selectedExamTool)

        let exam = MockExamState()
        exam.selectedExamTool = .calculator
        exam.resetSession(localDataReplacementRevision: 1)
        XCTAssertNil(exam.selectedExamTool)
    }
}
