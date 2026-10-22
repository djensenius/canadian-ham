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

    func testLessonQuizCurrentAndOtherHintLessonStacksPreserveQuizAcrossLayouts() {
        let quizPath: [LearnRoute] = [.lesson("L-005-01"), .lessonQuiz("QZ-L-005-01-A")]
        let lessonLinks: [LearnRoute] = [
            .lessonSection("L-005-01", "the-metric-prefix-ladder"),
            .lessonSection("L-006-03", "wavelength-and-frequency"),
            .lesson("L-006-03")
        ]
        for lessonLink in lessonLinks {
            let path = quizPath + [lessonLink]
            let compact: [RootNavigationRoute] = [.section(.learn)] + path.map { .learn($0) }
            let split = RootNavigationMapping.splitState(for: compact)
            XCTAssertEqual(split, SplitNavigationState(selection: .learn, path: path))
            XCTAssertEqual(RootNavigationMapping.compactPath(for: split), compact)
            XCTAssertEqual(Array(split.path.dropLast()), quizPath, "Back from either lesson must retain the original quiz route")
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

}
