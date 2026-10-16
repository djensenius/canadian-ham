import CanadianHamCalculatorEngine
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
