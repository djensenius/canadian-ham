import CoreGraphics
import XCTest

/// Measures an opaque text-element rendering, not a whole screen or a multi-background view.
/// The dominant 5-bit RGB cluster is the background; clusters below 2% coverage cannot be text.
func measuredTextContrast(in image: CGImage) -> Double? {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0,
          let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
          ) else { return nil }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let data = context.data else { return nil }
    let pixels = data.assumingMemoryBound(to: UInt8.self)

    struct Cluster {
        var count = 0
        var red = 0.0
        var green = 0.0
        var blue = 0.0

        var luminance: Double {
            func linearized(_ sum: Double) -> Double {
                let component = sum / Double(count) / 255
                return component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
        }
    }

    var clusters: [Int: Cluster] = [:]
    for row in 0..<height {
        for column in 0..<width {
            let offset = row * context.bytesPerRow + column * 4
            // Transparency has no defined background, so do not infer contrast by compositing it.
            guard pixels[offset + 3] == 255 else { return nil }
            let red = pixels[offset]
            let green = pixels[offset + 1]
            let blue = pixels[offset + 2]
            let key = (Int(red >> 3) << 10) | (Int(green >> 3) << 5) | Int(blue >> 3)
            var cluster = clusters[key, default: Cluster()]
            cluster.count += 1
            cluster.red += Double(red)
            cluster.green += Double(green)
            cluster.blue += Double(blue)
            clusters[key] = cluster
        }
    }

    // Sort keys so equal-coverage background choices are deterministic.
    let keys = clusters.keys.sorted()
    guard let backgroundKey = keys.max(by: { clusters[$0]!.count < clusters[$1]!.count }),
          let background = clusters[backgroundKey] else { return nil }
    let minimumCoverage = Double(width) * Double(height) * 0.02
    let backgroundLuminance = background.luminance
    let textLuminances = keys.filter { $0 != backgroundKey }.compactMap { key -> Double? in
        guard let cluster = clusters[key], Double(cluster.count) >= minimumCoverage else { return nil }
        return cluster.luminance
    }
    guard let textLuminance = textLuminances.max(by: {
        abs($0 - backgroundLuminance) < abs($1 - backgroundLuminance)
    }) else { return nil }
    return (max(backgroundLuminance, textLuminance) + 0.05) / (min(backgroundLuminance, textLuminance) + 0.05)
}

/// Owner-delegated decision 2026-10-22, TASK-71: only new TASK-46.5/TASK-46.6.1 audits may use this.
@MainActor
func auditVerifyingMeasuredContrast(app: XCUIApplication) throws {
    try app.performAccessibilityAudit { issue in
        guard issue.auditType == .contrast,
              let element = issue.element,
              let image = element.screenshot().image.cgImage,
              let ratio = measuredTextContrast(in: image),
              ratio >= 4.5 else { return false }

        XCTContext.runActivity(named: "Verified contrast audit finding with measured WCAG contrast") { activity in
            let attachment = XCTAttachment(string: "label=\(element.label) frame=\(element.frame) ratio=\(ratio):1")
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
        return true
    }
}
