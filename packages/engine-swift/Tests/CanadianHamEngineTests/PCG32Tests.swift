import Foundation
import XCTest
@testable import CanadianHamEngine

final class PCG32Tests: XCTestCase {
    func testPCG32SrandomDemoMatchesPublishedCOutputs() {
        let hexValues = pcg32DemoValues().map { String(format: "0x%08x", $0) }
        XCTAssertEqual(hexValues, [
            "0xa15c02b7",
            "0x7b47f409",
            "0xba1d3330",
            "0x83d2f293",
            "0xbfa4784b",
            "0xcbed606e",
        ])
    }
}
