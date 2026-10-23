import CoreGraphics
import XCTest

/// Measures an opaque text-element rendering, not a whole screen or a multi-background view.
/// Reports the minimum significant foreground ratio; ambiguous backgrounds fail closed.
/// Blends must border an already retained core and background; each core component must face that background.
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
    var pixelIndicesByKey: [Int: [Int]] = [:]
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
            let index = row * width + column
            pixelKeys[index] = key
            pixelIndicesByKey[key, default: []].append(index)
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

    func contrast(_ first: Cluster, _ second: Cluster) -> Double {
        let firstLuminance = first.luminance
        let secondLuminance = second.luminance
        return (max(firstLuminance, secondLuminance) + 0.05) / (min(firstLuminance, secondLuminance) + 0.05)
    }

    func contrast(_ cluster: Cluster) -> Double {
        contrast(background, cluster)
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
        // The retained core must be clearly further from the background than the blend.
        guard fraction > 0, fraction <= 0.9 else { return false }
        let residual = offset - fraction * line
        // Eight 8-bit RGB units allow quantization error, not arbitrary different text colours.
        guard dot(residual, residual) <= 8 * 8 else { return false }

        // Colour alone cannot distinguish grey text from a black/cream blend. Every pixel must
        // also lie in a thin edge band beside BOTH that core and the background (native pixels).
        for index in pixelIndicesByKey[key]! {
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

    // Never let an excluded blend support another exclusion. Cores are retained permanently,
    // farthest from the background luminance first (with deterministic ties).
    let orderedForegroundKeys = foregroundKeys.sorted {
        let first = abs(clusters[$0]!.luminance - background.luminance)
        let second = abs(clusters[$1]!.luminance - background.luminance)
        return first == second ? $0 < $1 : first > second
    }
    var retainedKeys: [Int] = []
    var blendCores: [Int: Int] = [:]
    for key in orderedForegroundKeys {
        if let core = retainedKeys.first(where: { isAntialiasedEdge(key, toward: $0) }) {
            blendCores[key] = core
        } else {
            retainedKeys.append(key)
        }
    }

    // Subthreshold colours never affect the reported ratio, but may supply spatial edge evidence
    // under the SAME strict blend tests. A support pixel must also be four-connected through
    // blends assigned to the SAME core colour to background; another core's edge is not evidence.
    // Small low-contrast content remains a known limit: see docs/testing/task-71-measured-contrast.md.
    var boundarySupportCores = blendCores
    for key in keys where key != backgroundKey && Double(clusters[key]!.count) < pixelCount * 0.02 {
        if let core = retainedKeys.first(where: { isAntialiasedEdge(key, toward: $0) }) {
            boundarySupportCores[key] = core
        }
    }
    var backgroundConnectedBlend = [Bool](repeating: false, count: pixelKeys.count)
    var pendingBlends: [Int] = []
    for index in pixelKeys.indices where boundarySupportCores[pixelKeys[index]] != nil {
        let x = index % width
        let y = index / width
        for (column, row) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            where column >= 0 && column < width && row >= 0 && row < height {
            if pixelKeys[row * width + column] == backgroundKey {
                backgroundConnectedBlend[index] = true
                pendingBlends.append(index)
                break
            }
        }
    }
    var blendCursor = 0
    while blendCursor < pendingBlends.count {
        let index = pendingBlends[blendCursor]
        blendCursor += 1
        let coreKey = boundarySupportCores[pixelKeys[index]]!
        let x = index % width
        let y = index / width
        for (column, row) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            where column >= 0 && column < width && row >= 0 && row < height {
            let neighbor = row * width + column
            if !backgroundConnectedBlend[neighbor] && boundarySupportCores[pixelKeys[neighbor]] == coreKey {
                backgroundConnectedBlend[neighbor] = true
                pendingBlends.append(neighbor)
            }
        }
    }

    // Four-connected core components stay separate even when they share a colour. Otherwise a
    // block on cream could lend its supported boundary to low-contrast text inside an inset panel.
    struct Component {
        let key: Int
        var pixelCount = 0
        var boundaryCount = 0
        var backgroundSupportedCount = 0
        var foregroundBorderedCount = 0
    }
    let retainedKeySet = Set(retainedKeys)
    var componentIDs = [Int](repeating: -1, count: pixelKeys.count)
    var components: [Component] = []
    for seed in pixelKeys.indices where componentIDs[seed] == -1 && retainedKeySet.contains(pixelKeys[seed]) {
        let key = pixelKeys[seed]
        let componentID = components.count
        var pending = [seed]
        componentIDs[seed] = componentID
        var cursor = 0
        while cursor < pending.count {
            let index = pending[cursor]
            cursor += 1
            let x = index % width
            let y = index / width
            for (column, row) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                where column >= 0 && column < width && row >= 0 && row < height {
                let neighbor = row * width + column
                if componentIDs[neighbor] == -1 && pixelKeys[neighbor] == key {
                    componentIDs[neighbor] = componentID
                    pending.append(neighbor)
                }
            }
        }
        components.append(Component(key: key, pixelCount: pending.count))
    }

    // Attach each excluded blend pixel to its nearest supporting CORE component in the same
    // radius-two neighbourhood used above. Squared-distance ties use the first row-major core
    // pixel. Never use another blend as support or merge disconnected cores through their blends.
    for index in pixelKeys.indices {
        guard let coreKey = blendCores[pixelKeys[index]] else { continue }
        let x = index % width
        let y = index / width
        var nearestComponentID: Int?
        var nearestDistance = Int.max
        for row in max(0, y - 2)...min(height - 1, y + 2) {
            for column in max(0, x - 2)...min(width - 1, x + 2) {
                let neighbor = row * width + column
                let distance = (column - x) * (column - x) + (row - y) * (row - y)
                if pixelKeys[neighbor] == coreKey && distance < nearestDistance {
                    nearestComponentID = componentIDs[neighbor]
                    nearestDistance = distance
                }
            }
        }
        guard let componentID = nearestComponentID else { return nil }
        componentIDs[index] = componentID
        components[componentID].pixelCount += 1
    }

    // A dominant colour need not be the text's LOCAL background. Inspect each component's
    // boundary, not filled interiors: thick text/solid blocks may legitimately be wide.
    let regionKeys = pixelKeys.map { blendCores[$0] ?? $0 }
    for index in pixelKeys.indices where componentIDs[index] >= 0 {
        let componentID = componentIDs[index]
        let x = index % width
        let y = index / width
        var isBoundary = false
        var bordersForeground = false
        for (column, row) in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            where column >= 0 && column < width && row >= 0 && row < height {
            let neighbor = row * width + column
            isBoundary = isBoundary || componentIDs[neighbor] != componentID
            let neighborKey = regionKeys[neighbor]
            if neighborKey != components[componentID].key && retainedKeySet.contains(neighborKey) {
                // Even a short low-contrast overlap can hide part of a glyph. The 50% boundary
                // thresholds below cannot establish safety for two directly adjoining cores.
                guard contrast(clusters[components[componentID].key]!, clusters[neighborKey]!) >= 4.5 else { return nil }
                bordersForeground = true
            }
        }
        guard isBoundary else { continue }
        components[componentID].boundaryCount += 1
        if bordersForeground { components[componentID].foregroundBorderedCount += 1 }
        var bordersBackground = false
        for row in max(0, y - 2)...min(height - 1, y + 2) {
            for column in max(0, x - 2)...min(width - 1, x + 2) {
                let neighbor = row * width + column
                let isSupportedBlend = backgroundConnectedBlend[neighbor]
                    && boundarySupportCores[pixelKeys[neighbor]] == components[componentID].key
                bordersBackground = bordersBackground || pixelKeys[neighbor] == backgroundKey || isSupportedBlend
            }
        }
        if bordersBackground { components[componentID].backgroundSupportedCount += 1 }
    }
    // Four native pixels (including assigned blends) suffice, regardless of image area: small
    // glyphs and dots must count. Only one-to-three-pixel specks skip spatial validation; all
    // retained clusters still contribute to the minimum contrast ratio below.
    for component in components where component.pixelCount >= 4 {
        guard component.boundaryCount > 0,
              component.backgroundSupportedCount * 2 >= component.boundaryCount,
              component.foregroundBorderedCount * 2 <= component.boundaryCount else { return nil }
    }
    return retainedKeys.map { contrast(clusters[$0]!) }.min()
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
           let image = contrastMeasurementCGImage(from: element.screenshot()) {
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

/// XCUIScreenshot.image is UIImage on iOS and NSImage on macOS; the UI-test target also
/// compiles in the documented macOS unit-test command, so bridge both.
func contrastMeasurementCGImage(from screenshot: XCUIScreenshot) -> CGImage? {
#if os(macOS)
    screenshot.image.cgImage(forProposedRect: nil, context: nil, hints: nil)
#else
    screenshot.image.cgImage
#endif
}
