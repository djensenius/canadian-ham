import CoreGraphics
import XCTest

/// Measures an opaque text-element rendering, not a whole screen or a multi-background view.
/// Reports the minimum significant foreground ratio; ambiguous backgrounds fail closed.
/// A colour-line blend is an antialiased edge only if its pixels also border the core and background.
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

        var color: SIMD3<Double> {
            SIMD3(red, green, blue) / Double(count)
        }

        var luminance: Double {
            func linearized(_ sum: Double) -> Double {
                let component = sum / Double(count) / 255
                return component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
        }
    }

    var clusters: [Int: Cluster] = [:]
    var pixelKeys = [Int](repeating: 0, count: width * height)
    for row in 0..<height {
        for column in 0..<width {
            let offset = row * context.bytesPerRow + column * 4
            // Transparency has no defined background, so do not infer contrast by compositing it.
            guard pixels[offset + 3] == 255 else { return nil }
            let red = pixels[offset]
            let green = pixels[offset + 1]
            let blue = pixels[offset + 2]
            let key = (Int(red >> 3) << 10) | (Int(green >> 3) << 5) | Int(blue >> 3)
            pixelKeys[row * width + column] = key
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
    let pixelCount = Double(width) * Double(height)
    // Do not guess which of two large tones is the text's local background.
    guard Double(background.count) > pixelCount * 0.5 else { return nil }
    let foregroundKeys = keys.filter { $0 != backgroundKey && Double(clusters[$0]!.count) >= pixelCount * 0.02 }
    guard !foregroundKeys.isEmpty,
          foregroundKeys.allSatisfy({ Double(clusters[$0]!.count) < pixelCount * 0.25 }) else { return nil }

    func contrast(_ cluster: Cluster) -> Double {
        let first = background.luminance
        let second = cluster.luminance
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }

    // Significant background noise/bin splits are ambiguous, not evidence of passing text.
    guard foregroundKeys.allSatisfy({ contrast(clusters[$0]!) > 1.1 }) else { return nil }

    func dot(_ first: SIMD3<Double>, _ second: SIMD3<Double>) -> Double {
        first.x * second.x + first.y * second.y + first.z * second.z
    }

    func isAntialiasedEdge(_ key: Int, toward coreKey: Int) -> Bool {
        let offset = clusters[key]!.color - background.color
        let line = clusters[coreKey]!.color - background.color
        let fraction = dot(offset, line) / dot(line, line)
        // The core must be clearly further from the background than the blend, so two near-identical
        // colours split across a bin boundary can never each be dropped as an edge of the other.
        guard fraction > 0, fraction <= 0.9 else { return false }
        let residual = offset - fraction * line
        // Eight 8-bit RGB units allow quantization error, not arbitrary different text colours.
        guard dot(residual, residual) <= 8 * 8 else { return false }

        // Colour alone cannot distinguish grey text from a black/cream blend. Every pixel must
        // also lie in a thin edge band beside BOTH that core and the background (native pixels).
        for index in pixelKeys.indices where pixelKeys[index] == key {
            let x = index % width
            let y = index / width
            var bordersCore = false
            var bordersBackground = false
            for row in max(0, y - 2)...min(height - 1, y + 2) {
                for column in max(0, x - 2)...min(width - 1, x + 2) {
                    let neighbor = pixelKeys[row * width + column]
                    bordersCore = bordersCore || neighbor == coreKey
                    bordersBackground = bordersBackground || neighbor == backgroundKey
                }
            }
            if !bordersCore || !bordersBackground { return false }
        }
        return true
    }

    let foregroundRatios = foregroundKeys.compactMap { key -> Double? in
        if foregroundKeys.contains(where: { $0 != key && isAntialiasedEdge(key, toward: $0) }) {
            return nil
        }
        return contrast(clusters[key]!)
    }
    return foregroundRatios.min()
}

func isFullyVisibleForContrastMeasurement(frame: CGRect, windowFrame: CGRect, protectedMaxY: CGFloat) -> Bool {
    !frame.isEmpty && !windowFrame.isEmpty && windowFrame.contains(frame) && frame.minY >= protectedMaxY
}

/// Owner-delegated decision 2026-10-22, TASK-71: only new TASK-46.5/TASK-46.6.1 audits may use this.
@MainActor
func auditVerifyingMeasuredContrast(app: XCUIApplication) throws {
    let windowFrame = app.windows.firstMatch.frame
    let navigationBar = app.navigationBars.firstMatch
    let statusBar = app.statusBars.firstMatch
    let protectedMaxY = max(
        navigationBar.exists ? navigationBar.frame.maxY : windowFrame.minY,
        statusBar.exists ? statusBar.frame.maxY : windowFrame.minY
    )
    try app.performAccessibilityAudit { issue in
        guard issue.auditType == .contrast else { return false }
        let element = issue.element
        let frame = element?.frame
        var ratio: Double?
        if let element, let frame,
           isFullyVisibleForContrastMeasurement(frame: frame, windowFrame: windowFrame, protectedMaxY: protectedMaxY),
           let image = element.screenshot().image.cgImage {
            ratio = measuredTextContrast(in: image)
        }
        let verified = ratio.map { $0 >= 4.5 } ?? false
        let activityName = verified ? "Verified contrast audit finding with measured WCAG contrast" : "Failed contrast audit finding"
        XCTContext.runActivity(named: activityName) { activity in
            let measurement = ratio.map { "\($0):1" } ?? "unmeasurable"
            let attachment = XCTAttachment(string: "label=\(element?.label ?? "<nil>") frame=\(frame.map { "\($0)" } ?? "<nil>") ratio=\(measurement)")
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
        return verified
    }
}
