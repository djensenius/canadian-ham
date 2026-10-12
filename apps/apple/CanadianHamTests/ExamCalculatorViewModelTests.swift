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

    func testReferenceSheetLoaderReturnsNilWhenBundledFileIsMissingAndLoadsFixture() throws {
        let missing = try ReferenceSheetLoader.load(
            configuration: ReferenceSheetConfiguration(resourceName: "missing-reference-sheet", resourceExtension: "md", subdirectory: nil),
            bundle: Bundle(for: Self.self)
        )
        XCTAssertNil(missing)

        let fixture = try XCTUnwrap(try ReferenceSheetLoader.load(
            configuration: ReferenceSheetConfiguration(resourceName: "basic-reference-sheet", resourceExtension: "md", subdirectory: nil),
            bundle: Bundle(for: Self.self)
        ))
        XCTAssertTrue(fixture.markdown.contains("Ohm's law"))
    }
}
