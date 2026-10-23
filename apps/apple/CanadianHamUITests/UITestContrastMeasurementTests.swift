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
        // Three physical pixels per point, like the exported iPhone element screenshots.
        let context = try bitmapContext(width: 600, height: 144)
        context.scaleBy(x: 3, y: 3)
        context.setFillColor(cream)
        context.fill(CGRect(x: 0, y: 0, width: 200, height: 48))
        context.setShouldAntialias(true)
        context.setShouldSmoothFonts(false)
        let font = CTFontCreateWithName("Helvetica" as CFString, 15, nil)
        let text = NSAttributedString(string: "Correct 820 / 1 000 = 0.82 A", attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): foreground
        ])
        let line = CTLineCreateWithAttributedString(text)
        for baseline in [10.0, 30.0] {
            context.textPosition = CGPoint(x: 2, y: baseline)
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
