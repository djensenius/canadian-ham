@testable import CanadianHam
import CoreGraphics
import SwiftUI
import XCTest

final class DuoLayoutPolicyTests: XCTestCase {
    func testUnfoldedIPhoneEntryBoundaries() {
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 799, height: 600),
            verticalSizeClass: .regular
        ))
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 800, height: 600),
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 800, height: 599),
            verticalSizeClass: .regular
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 669, height: 951),
            verticalSizeClass: .regular
        ), "Unfolded Duo portrait is not wide enough for a 420 pt exam column beside the 380 pt inspector.")
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 951, height: 669),
            verticalSizeClass: .regular
        ), "Unfolded Duo landscape is wide enough for the split/inspector layout.")
    }

    func testUnfoldedIPhoneHysteresisPreventsSmallSizeJitterFromClosingLayout() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 799, height: 599),
            verticalSizeClass: .regular,
            wasUsingUnfoldedLayout: true
        ), "An already-unfolded layout should not collapse for one-point window-size jitter around the entry threshold.")
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 780, height: 580),
            verticalSizeClass: .regular,
            wasUsingUnfoldedLayout: true
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 779, height: 580),
            verticalSizeClass: .regular,
            wasUsingUnfoldedLayout: true
        ))
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 780, height: 579),
            verticalSizeClass: .regular,
            wasUsingUnfoldedLayout: true
        ))
    }

    func testOrdinaryIPhoneProMaxSizesKeepCompactSheetLayout() {
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 440, height: 956),
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ), "Pro Max portrait is below the unfolded width threshold.")
        XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
            idiom: .phone,
            containerSize: CGSize(width: 956, height: 440),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ), "Pro Max landscape keeps the task-44.3 sheet path because its vertical size class is compact and its height is below the unfolded threshold.")
    }

    func testNilVerticalSizeClassDoesNotBlockWidthDrivenUnfoldedLandscapeLayout() {
        XCTAssertTrue(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
            idiom: .phone,
            containerSize: CGSize(width: 951, height: 669),
            verticalSizeClass: nil
        ))
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

    func testMacAndOtherIdiomsNeverUseUnfoldedIPhoneRule() {
        for idiom in [PlatformUserInterfaceIdiom.mac, .other] {
            XCTAssertFalse(AdaptiveExamLayoutPolicy.usesUnfoldedIPhoneLayout(
                idiom: idiom,
                containerSize: CGSize(width: 669, height: 951),
                verticalSizeClass: .regular
            ))
            XCTAssertFalse(AdaptiveExamLayoutPolicy.usesInspectorPresentation(
                idiom: idiom,
                containerSize: CGSize(width: 669, height: 951),
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            ))
        }
    }
}
