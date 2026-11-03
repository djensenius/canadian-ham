import CanadianHamCalculatorEngine
import SwiftUI
import XCTest

@MainActor
final class ExamCalculatorViewModelTests: XCTestCase {
    func testKeyHandlingProducesEngineDisplayAndSpokenResult() {
        let viewModel = ExamCalculatorViewModel(locale: .en)

        XCTAssertEqual(viewModel.press(.one), "1")
        _ = viewModel.press(.add)
        _ = viewModel.press(.two)
        let spoken = viewModel.press(.equals)

        XCTAssertEqual(viewModel.display, "3")
        XCTAssertEqual(spoken, viewModel.displayValue.spoken.en)
        XCTAssertEqual(viewModel.spokenResult, "3")
    }

    func testClearForNewExamResetsCurrentCalculationButKeepsRequestedLocale() {
        let viewModel = ExamCalculatorViewModel(locale: .en)
        _ = viewModel.press(.nine)
        _ = viewModel.press(.multiply)
        _ = viewModel.press(.nine)
        XCTAssertEqual(viewModel.display, "9")

        viewModel.clearForNewExam(locale: .fr)

        XCTAssertEqual(viewModel.display, "0")
        XCTAssertEqual(viewModel.locale, .fr)
        _ = viewModel.press(.decimalPoint)
        _ = viewModel.press(.five)
        XCTAssertEqual(viewModel.display, "0,5")
        XCTAssertEqual(viewModel.spokenResult(for: .fr), viewModel.displayValue.spoken.fr)
    }

    func testFrenchLocaleUsesFrenchDecimalDisplayAndSpokenString() {
        let viewModel = ExamCalculatorViewModel(locale: .fr)

        _ = viewModel.press(.one)
        _ = viewModel.press(.decimalPoint)
        _ = viewModel.press(.five)

        XCTAssertEqual(viewModel.display, "1,5")
        XCTAssertEqual(viewModel.spokenResult, viewModel.displayValue.spoken.fr)
        XCTAssertNotEqual(viewModel.displayValue.spoken.fr, viewModel.displayValue.spoken.en)
    }

    func testUpdateLocaleRefreshesDisplayAndSpokenStringImmediately() {
        let viewModel = ExamCalculatorViewModel(locale: .en)
        _ = viewModel.press(.one)
        _ = viewModel.press(.decimalPoint)
        _ = viewModel.press(.five)
        XCTAssertEqual(viewModel.display, "1.5")
        XCTAssertEqual(viewModel.spokenResult, viewModel.displayValue.spoken.en)

        viewModel.updateLocale(.fr)

        XCTAssertEqual(viewModel.locale, .fr)
        XCTAssertEqual(viewModel.display, "1,5")
        XCTAssertEqual(viewModel.spokenResult, viewModel.displayValue.spoken.fr)

        viewModel.updateLocale(.en)
        XCTAssertEqual(viewModel.display, "1.5")
        XCTAssertEqual(viewModel.spokenResult, viewModel.displayValue.spoken.en)
    }

    func testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsBasicSheet() throws {
        let missing = try ReferenceSheetLoader.load(
            configuration: ReferenceSheetConfiguration(resourceName: "missing-reference-sheet", resourceExtension: "md", subdirectory: nil),
            bundle: Bundle(for: Self.self)
        )
        XCTAssertNil(missing)

        let sheet = try XCTUnwrap(try ReferenceSheetLoader.load(configuration: .basic, bundle: Bundle(for: Self.self)))
        XCTAssertTrue(sheet.markdown.contains("Ohm's law"))
    }

    func testOfficialReferenceSheetGateAndBundledPages() throws {
        XCTAssertTrue(ReferenceSheetConfiguration.basic.availableOnApple, "The study fallback is always available for Basic.")
        let bundle = Bundle(for: Self.self)
        if OfficialReferenceSheetLoader.isEnabled {
            let sheet = try XCTUnwrap(try OfficialReferenceSheetLoader.load(bundle: bundle))
            XCTAssertEqual(sheet.pages.count, 5)
            XCTAssertTrue(sheet.markdown.contains("L = 142 / F"))
            XCTAssertTrue(sheet.markdown.contains("L = 71 / F"))
            XCTAssertTrue(sheet.markdown.contains("## Page 5"))
            XCTAssertTrue(sheet.pages.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
        } else {
            XCTAssertNil(try OfficialReferenceSheetLoader.load(bundle: bundle))
            XCTAssertNil(bundle.url(forResource: "page-1", withExtension: "png", subdirectory: "official-basic-exam"))
        }
    }

    func testCalculatorToolLayoutCanRepresentFittingContentWithAndWithoutHelp() {
        let withHelp = CalculatorToolLayout(dynamicTypeSize: .large, contentMode: .fitting(showsHelpText: true, keyHeight: CalculatorToolLayout.expandedKeyHeight))
        XCTAssertFalse(withHelp.usesScrolling)
        XCTAssertTrue(withHelp.showsHelpText)
        XCTAssertEqual(withHelp.displayHeight, 48)
        XCTAssertEqual(withHelp.keyHeight, 64)

        let withoutHelp = CalculatorToolLayout(dynamicTypeSize: .large, contentMode: .fitting(showsHelpText: false, keyHeight: CalculatorToolLayout.minimumKeyHeight))
        XCTAssertFalse(withoutHelp.usesScrolling)
        XCTAssertFalse(withoutHelp.showsHelpText)
        XCTAssertEqual(withoutHelp.keyHeight, 46)
    }

    func testCalculatorToolLayoutFittingCandidatesPreferLargeKeysBeforeMinimumKeys() {
        let candidates = CalculatorToolLayout.fittingCandidateContentModes.map {
            CalculatorToolLayout(dynamicTypeSize: .large, contentMode: $0)
        }

        XCTAssertEqual(candidates.map(\.keyHeight), [64, 64, 46, 46])
        XCTAssertEqual(candidates.map(\.showsHelpText), [true, false, true, false])
        XCTAssertTrue(candidates.allSatisfy { !$0.usesScrolling })
    }

    func testCalculatorToolLayoutUsesExplicitScrollingModeWithoutHeightThresholds() {
        let scrollingLayout = CalculatorToolLayout(dynamicTypeSize: .large, contentMode: .scrolling(showsHelpText: false))

        XCTAssertTrue(scrollingLayout.usesScrolling)
        XCTAssertFalse(scrollingLayout.showsHelpText)
        XCTAssertEqual(scrollingLayout.displayHeight, 48)
        XCTAssertGreaterThanOrEqual(scrollingLayout.keyHeight, 44)
        XCTAssertLessThan(scrollingLayout.keyHeight, 64)

        let scrollingWithHelp = CalculatorToolLayout(dynamicTypeSize: .large, contentMode: .scrolling(showsHelpText: true))
        XCTAssertTrue(scrollingWithHelp.usesScrolling)
        XCTAssertTrue(scrollingWithHelp.showsHelpText)
    }

    func testCalculatorToolLayoutUsesLargeMetricsOnlyForAccessibilitySizes() {
        let accessibilityFittingLayout = CalculatorToolLayout(dynamicTypeSize: .accessibility1, contentMode: .fitting(showsHelpText: true, keyHeight: CalculatorToolLayout.minimumKeyHeight))
        XCTAssertTrue(accessibilityFittingLayout.usesScrolling)
        XCTAssertFalse(accessibilityFittingLayout.showsHelpText)
        XCTAssertEqual(accessibilityFittingLayout.displayHeight, 72)
        XCTAssertEqual(accessibilityFittingLayout.keyHeight, 64)

        let accessibilityScrollingLayout = CalculatorToolLayout(dynamicTypeSize: .accessibility1, contentMode: .scrolling(showsHelpText: false))
        XCTAssertTrue(accessibilityScrollingLayout.usesScrolling)
        XCTAssertEqual(accessibilityScrollingLayout.displayHeight, 72)
        XCTAssertEqual(accessibilityScrollingLayout.keyHeight, 64)
    }

    func testCalculatorToolLayoutKeepsKeyHeightAtLeast44Everywhere() {
        let sizes: [DynamicTypeSize] = [.xSmall, .large, .xxxLarge, .accessibility1, .accessibility5]
        let modes: [CalculatorToolLayout.ContentMode] = CalculatorToolLayout.fittingCandidateContentModes + [.scrolling(showsHelpText: false), .scrolling(showsHelpText: true)]

        for size in sizes {
            for mode in modes {
                let layout = CalculatorToolLayout(dynamicTypeSize: size, contentMode: mode)
                XCTAssertGreaterThanOrEqual(layout.keyHeight, 44, "size \(size), mode \(mode)")
            }
        }
    }

    func testQuestionCardFocusResetKeepsTextSelectionEnabled() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("CanadianHam/Views/StudyViews.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let questionCardBody = try XCTUnwrap(source.slice(from: "struct QuestionCard: View", to: "struct AnswerChoiceButton: View"))

        XCTAssertTrue(questionCardBody.contains(".textSelection(.enabled)"), "Question text should remain selectable.")
        XCTAssertTrue(questionCardBody.contains("var onInteraction: (() -> Void)? = nil"), "Lesson quizzes should not install the exam-only focus-reset gesture by default.")
        XCTAssertTrue(questionCardBody.contains("if let onInteraction"), "The focus-reset gesture should be conditional on exam screens passing a handler.")
        XCTAssertTrue(questionCardBody.contains("including: .all"), "The exam focus-reset tap should not exclude child text-selection gestures.")
        XCTAssertFalse(questionCardBody.contains("including: .gesture"), "The old gesture mask blocked child text-selection gestures.")

        XCTAssertTrue(source.contains("onKeyboardFocus: clearCalculatorKeyboardFocus"), "Keyboard focus moving to answer buttons should clear calculator input focus for Full Keyboard Access users.")
    }
}

private extension String {
    func slice(from start: String, to end: String) -> String? {
        guard let startRange = range(of: start),
              let endRange = range(of: end, range: startRange.upperBound..<endIndex) else { return nil }
        return String(self[startRange.lowerBound..<endRange.lowerBound])
    }
}
