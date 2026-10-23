import CoreGraphics
import CoreText
import ImageIO
import XCTest

@MainActor
final class UITestContrastMeasurementTests: XCTestCase {
    private let cream = CGColor(srgbRed: 1, green: 248.0 / 255, blue: 232.0 / 255, alpha: 1)
    private let nearBlack = CGColor(srgbRed: 32.0 / 255, green: 28.0 / 255, blue: 24.0 / 255, alpha: 1)
    private let midGrey = CGColor(srgbRed: 154.0 / 255, green: 154.0 / 255, blue: 154.0 / 255, alpha: 1)

    func testNearBlackOnCreamPasses() throws {
        let ratio = try XCTUnwrap(measuredTextContrast(in: panel(background: cream, foreground: nearBlack)))
        XCTAssertGreaterThanOrEqual(ratio, 4.5)
        XCTAssertEqual(ratio, 15.9943, accuracy: 0.01)
    }

    func testMidGreyOnCreamFails() throws {
        let ratio = try XCTUnwrap(measuredTextContrast(in: panel(background: cream, foreground: midGrey)))
        XCTAssertLessThan(ratio, 4.5)
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.01)
    }

    func testPaleOnDarkGreenPasses() throws {
        let background = CGColor(srgbRed: 28.0 / 255, green: 55.0 / 255, blue: 36.0 / 255, alpha: 1)
        let foreground = CGColor(srgbRed: 219.0 / 255, green: 238.0 / 255, blue: 211.0 / 255, alpha: 1)
        let ratio = try XCTUnwrap(measuredTextContrast(in: panel(background: background, foreground: foreground)))
        XCTAssertGreaterThanOrEqual(ratio, 4.5)
        XCTAssertEqual(ratio, 10.5978, accuracy: 0.01)
    }

    func testAntialiased15PointTextMeasuresExpectedContrast() throws {
        let image = try renderedText(foreground: nearBlack)
        let ratio = try XCTUnwrap(measuredTextContrast(in: image))
        // Expected WCAG ratio for #201C18 / #FFF8E8, allowing edge pixels in the quantized clusters.
        XCTAssertEqual(ratio, 15.9943, accuracy: 0.2)
        XCTAssertGreaterThanOrEqual(ratio, 4.5)
    }

    func testAntialiased15PointLowContrastTextStillFails() throws {
        let ratio = try XCTUnwrap(measuredTextContrast(in: renderedText(foreground: midGrey)))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.1)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testTinyHighContrastTailDoesNotRescueLowContrastText() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(midGrey)
        context.fill(CGRect(x: 10, y: 10, width: 80, height: 20))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10)) // 1%, below the 2% text threshold.
        let ratio = try XCTUnwrap(measuredTextContrast(in: XCTUnwrap(context.makeImage())))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.01)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testSignificantNearBlackAndMidGreyBlocksDoNotPass() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 10, y: 10, width: 10, height: 30)) // 3%.
        context.setFillColor(midGrey)
        context.fill(CGRect(x: 50, y: 10, width: 10, height: 30)) // 3%.
        let ratio = try XCTUnwrap(measuredTextContrast(in: XCTUnwrap(context.makeImage())))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.01)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testSolidBlendColourIsNotMistakenForAntialiasing() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 10, y: 10, width: 10, height: 30))
        // Exactly halfway along the cream/near-black colour line, but a separate solid block.
        context.setFillColor(CGColor(srgbRed: 143.5 / 255, green: 138.0 / 255, blue: 128.0 / 255, alpha: 1))
        context.fill(CGRect(x: 50, y: 10, width: 10, height: 30))
        let ratio = try XCTUnwrap(measuredTextContrast(in: XCTUnwrap(context.makeImage())))
        XCTAssertLessThan(ratio, 4.5)
    }

    func testInterleavedNearIdenticalGreysCannotHideEachOtherBesideDarkText() throws {
        let context = try bitmapContext()
        context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 80, y: 10, width: 6, height: 50))
        // Thin strokes of two near-identical greys on either side of a 5-bit bin boundary,
        // mixed pixel by pixel; each is almost on the other's colour line toward white.
        let greyA = CGColor(srgbRed: 151.0 / 255, green: 152.0 / 255, blue: 152.0 / 255, alpha: 1)
        let greyB = CGColor(srgbRed: 152.0 / 255, green: 151.0 / 255, blue: 152.0 / 255, alpha: 1)
        for row in stride(from: 10, to: 60, by: 4) {
            for column in 10..<60 {
                context.setFillColor(column.isMultiple(of: 2) ? greyA : greyB)
                context.fill(CGRect(x: column, y: row, width: 1, height: 2))
            }
        }
        let image = try XCTUnwrap(context.makeImage())
        if let ratio = measuredTextContrast(in: image) {
            XCTAssertLessThan(ratio, 4.5)
        }
    }

    func testChainedBlendsCannotUseAnExcludedCore() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        let lightStroke = CGColor(srgbRed: 144.0 / 255, green: 138.0 / 255, blue: 128.0 / 255, alpha: 1) // #908A80.
        let middleStroke = CGColor(srgbRed: 88.0 / 255, green: 83.0 / 255, blue: 76.0 / 255, alpha: 1) // #58534C.
        for x in [10, 30, 50, 70] {
            for (offset, color) in [lightStroke, middleStroke, nearBlack].enumerated() {
                context.setFillColor(color)
                context.fill(CGRect(x: x + offset * 2, y: 10, width: 1, height: 80))
            }
        }
        // Each tone covers 3.2%. The first is 3.24:1 against cream, four pixels from the dark core.
        if let ratio = measuredTextContrast(in: try XCTUnwrap(context.makeImage())) {
            XCTAssertLessThan(ratio, 4.5)
            XCTAssertEqual(ratio, 3.2357, accuracy: 0.01)
        }
    }

    func testInsetPanelCannotUseTheSurroundingCreamAsTextBackground() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(CGColor(srgbRed: 64.0 / 255, green: 64.0 / 255, blue: 64.0 / 255, alpha: 1)) // #404040.
        context.fill(CGRect(x: 30, y: 30, width: 40, height: 40))
        context.setFillColor(nearBlack) // #201C18.
        context.fill(CGRect(x: 42, y: 40, width: 16, height: 20))
        // 84% cream, 12.8% panel and 3.2% text. Text/panel is only 1.63:1, not 9.80:1.
        if let ratio = measuredTextContrast(in: try XCTUnwrap(context.makeImage())) {
            XCTAssertLessThan(ratio, 4.5)
        }
    }

    func testAntialiased15PointBoldMixedContrastLinesFailAt3x() throws {
        let image = try renderedLines([nearBlack, midGrey], bold: true)
        let ratio = try XCTUnwrap(measuredTextContrast(in: image))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.1)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testDarkIconDoesNotRescueMidGreyText() throws {
        let image = try renderedLines([midGrey, midGrey], includesIcon: true)
        let ratio = try XCTUnwrap(measuredTextContrast(in: image))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.1)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testTwoTonePanelWithDarkTextIsUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(CGColor(srgbRed: 232.0 / 255, green: 241.0 / 255, blue: 221.0 / 255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 40))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 10, y: 10, width: 80, height: 10))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testSignificantNearBackgroundNoiseIsUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(CGColor(srgbRed: 250.0 / 255, green: 247.0 / 255, blue: 231.0 / 255, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 30))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 50, y: 10, width: 30, height: 30))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testEqualLargeTonesAreUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 50))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testBlackOffscreenBandDoesNotRescueMidGreyText() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 3)) // 3% black offscreen fill.
        context.setFillColor(midGrey)
        context.fill(CGRect(x: 10, y: 20, width: 80, height: 20))
        let ratio = try XCTUnwrap(measuredTextContrast(in: XCTUnwrap(context.makeImage())))
        XCTAssertEqual(ratio, 2.6591, accuracy: 0.01)
        XCTAssertLessThan(ratio, 4.5)
    }

    func testSignificantAntialiasedEdgeBandsMeasureCoreContrast() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        for x in [10, 30, 50, 70] {
            context.setFillColor(CGColor(srgbRed: 143.5 / 255, green: 138.0 / 255, blue: 128.0 / 255, alpha: 1))
            context.fill(CGRect(x: x, y: 10, width: 7, height: 80))
            context.setFillColor(nearBlack)
            context.fill(CGRect(x: x + 1, y: 10, width: 5, height: 80))
        }
        // The one-pixel blend bands cover 6.4%, exceed 2%, and are below 4.5:1 themselves.
        let ratio = try XCTUnwrap(measuredTextContrast(in: XCTUnwrap(context.makeImage())))
        XCTAssertEqual(ratio, 15.9943, accuracy: 0.01)
    }

    func testAntialiased15PointBoldEdgeCoverageAt3x() throws {
        let image = try renderedLines([nearBlack, nearBlack], bold: true, text: "IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII")
        let data = try XCTUnwrap(image.dataProvider?.data)
        let pixels = try XCTUnwrap(CFDataGetBytePtr(data))
        var counts: [Int: Int] = [:]
        for y in 0..<image.height {
            for x in 0..<image.width {
                let offset = y * image.bytesPerRow + x * 4
                let key = (Int(pixels[offset] >> 3) << 10) | (Int(pixels[offset + 1] >> 3) << 5) | Int(pixels[offset + 2] >> 3)
                counts[key, default: 0] += 1
            }
        }
        let creamKey = (31 << 10) | (31 << 5) | 29
        let nearBlackKey = (4 << 10) | (3 << 5) | 3
        let edgeCount = counts.filter { $0.key != creamKey && $0.key != nearBlackKey }.values.max() ?? 0
        let edgeCoverage = Double(edgeCount) / Double(image.width * image.height)
        XCTAssertGreaterThanOrEqual(edgeCoverage, 0.02, "A real bold-text edge cluster must exercise the 2% threshold")
        let ratio = try XCTUnwrap(measuredTextContrast(in: image))
        XCTAssertEqual(ratio, 15.9943, accuracy: 0.2)
        XCTContext.runActivity(named: "Bold 15 pt 3x significant edge coverage") { activity in
            let attachment = XCTAttachment(string: "largestEdgeClusterCoverage=\(edgeCoverage) ratio=\(ratio):1")
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    func testContrastMeasurementRejectsInvisibleFrames() {
        let window = CGRect(x: 0, y: 0, width: 400, height: 800)
        XCTAssertTrue(isFullyVisibleForContrastMeasurement(frame: CGRect(x: 20, y: 100, width: 200, height: 40), windowFrame: window, protectedMaxY: 100))
        for frame in [CGRect.zero, CGRect(x: 20, y: 100, width: 0, height: 40),
                      CGRect(x: -1, y: 100, width: 200, height: 40),
                      CGRect(x: 20, y: 780, width: 200, height: 40),
                      CGRect(x: 20, y: 60, width: 200, height: 80),
                      CGRect(x: 20, y: -50, width: 200, height: 40)] {
            XCTAssertFalse(isFullyVisibleForContrastMeasurement(frame: frame, windowFrame: window, protectedMaxY: 100), "\(frame)")
        }
        XCTAssertFalse(isFullyVisibleForContrastMeasurement(frame: CGRect(x: 0, y: 0, width: 10, height: 10), windowFrame: .zero, protectedMaxY: 0))
    }

    func testUniformImageIsUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testOnlyTinyForegroundIsUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testTransparentImageIsUnmeasurable() throws {
        let context = try bitmapContext()
        context.setFillColor(nearBlack)
        context.fill(CGRect(x: 10, y: 10, width: 80, height: 20))
        XCTAssertNil(measuredTextContrast(in: try XCTUnwrap(context.makeImage())))
    }

    func testExportedCorrectFeedbackLightPasses() throws {
        try assertExportedElementPasses("correct-feedback-light")
    }

    func testExportedCorrectFeedbackDarkPasses() throws {
        try assertExportedElementPasses("correct-feedback-dark")
    }

    func testExportedTryItParagraphLightPasses() throws {
        try assertExportedElementPasses("try-it-paragraph-light")
    }

    private func assertExportedElementPasses(_ name: String) throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(
            forResource: name, withExtension: "png", subdirectory: "ContrastMeasurement"
        ))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let ratio = try XCTUnwrap(measuredTextContrast(in: image))
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(name): measured ratio \(ratio):1")
        XCTContext.runActivity(named: "Measured exported element \(name)") { activity in
            let attachment = XCTAttachment(string: "resource=\(name).png ratio=\(ratio):1")
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    private func panel(background: CGColor, foreground: CGColor) throws -> CGImage {
        let context = try bitmapContext()
        context.setFillColor(background)
        context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        context.setFillColor(foreground)
        context.fill(CGRect(x: 10, y: 10, width: 80, height: 20))
        return try XCTUnwrap(context.makeImage())
    }

    private func renderedText(foreground: CGColor) throws -> CGImage {
        try renderedLines([foreground, foreground])
    }

    private func renderedLines(
        _ foregrounds: [CGColor], bold: Bool = false, includesIcon: Bool = false,
        text: String = "Correct 820 / 1 000 = 0.82 A"
    ) throws -> CGImage {
        // Three physical pixels per point, like the exported iPhone element screenshots.
        let context = try bitmapContext(width: 600, height: 144)
        context.scaleBy(x: 3, y: 3)
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 200, height: 48))
        context.setShouldAntialias(true)
        context.setShouldSmoothFonts(false)
        if includesIcon {
            context.setFillColor(nearBlack)
            context.fill(CGRect(x: 2, y: 10, width: 20, height: 26)) // 5.4% dark icon.
        }
        let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, 15, nil)
        for (index, foreground) in foregrounds.enumerated() {
            let attributedText = NSAttributedString(string: text, attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): foreground
            ])
            let line = CTLineCreateWithAttributedString(attributedText)
            context.textPosition = CGPoint(x: includesIcon ? 28 : 2, y: 10 + Double(index) * 20)
            CTLineDraw(line, context)
        }
        return try XCTUnwrap(context.makeImage())
    }

    private func bitmapContext(width: Int = 100, height: Int = 100) throws -> CGContext {
        let colorSpace = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        return try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
    }
}
