@testable import CanadianHam
import SwiftUI
import XCTest

final class DuoLayoutPolicyTests: XCTestCase {
    func testRegularWidthIPhoneUsesUnfoldedInspectorPolicyWhenVerticalIsNotCompact() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesRegularWidthIPhoneLayout(
            idiom: .phone,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ))
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ))
    }

    func testCompactWidthIPhoneKeepsSheetPolicy() {
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesRegularWidthIPhoneLayout(
            idiom: .phone,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ))
    }

    func testForcedRegularIPhoneLandscapeKeepsSheetPolicyWhenVerticalIsCompact() {
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesRegularWidthIPhoneLayout(
            idiom: .phone,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ))
    }

    func testNilVerticalSizeClassDoesNotBlockRegularWidthIPhonePolicy() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesRegularWidthIPhoneLayout(
            idiom: .phone,
            horizontalSizeClass: .regular,
            verticalSizeClass: nil
        ))
    }

    func testIPadInspectorRuleRemainsSizeClassDriven() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .pad,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .pad,
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ))
    }

    func testMacAndOtherIdiomsNeverUseIPhonePolicy() {
        for idiom in [PlatformUserInterfaceIdiom.mac, .other] {
            XCTAssertFalse(AdaptiveExamLayoutPolicy.usesRegularWidthIPhoneLayout(
                idiom: idiom,
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            ))
            XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
                idiom: idiom,
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            ))
        }
    }
}
