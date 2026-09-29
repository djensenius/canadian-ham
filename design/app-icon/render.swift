#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("design/app-icon")
let source = root.appendingPathComponent("src")
let exports = root.appendingPathComponent("exports")
try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: exports, withIntermediateDirectories: true)

let paper = "#F6EEDC"
let paperWarm = "#FFF7E8"
let ink = "#000000"

let faviconStrokes: [(width: String, d: String)] = [
    ("6.0", "M19 55 C20 44 23 33 27 23"),
    ("2.2", "M35 18 C38 23 40 29 39 36"),
    ("2.6", "M45 11 C49 19 50 29 48 42"),
    ("3.0", "M56 5 C62 17 63 31 59 48")
]

func faviconPaths(attributes: String) -> String {
    faviconStrokes
        .map { "  <path \(attributes) stroke-width=\"\($0.width)\" d=\"\($0.d)\"/>" }
        .joined(separator: "\n")
}

func adaptiveFaviconSVG() -> String {
    """
    <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\">
      <style>
        .paper { fill: #f6eedc; }
        .ink { fill: none; stroke: #000; stroke-linecap: round; stroke-linejoin: round; }
        @media (prefers-color-scheme: dark) {
          .paper { fill: #201b16; }
          .ink { stroke: #f3e8d2; }
        }
      </style>
      <rect width=\"64\" height=\"64\" rx=\"14\" class=\"paper\"/>
    \(faviconPaths(attributes: "class=\"ink\""))
    </svg>
    """
}

func lightFaviconSVG() -> String {
    """
    <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" width=\"64\" height=\"64\">
      <rect width=\"64\" height=\"64\" rx=\"14\" fill=\"#f6eedc\"/>
    \(faviconPaths(attributes: "fill=\"none\" stroke=\"#000\" stroke-linecap=\"round\" stroke-linejoin=\"round\""))
    </svg>
    """
}

struct SizeSpec {
    let name: String
    let width: Int
    let height: Int
}

struct SeededNoise {
    private var state: UInt64

    init(_ seed: UInt64) { state = seed }

    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = Double((state >> 11) & ((1 << 53) - 1)) / Double(1 << 53)
        return CGFloat(value * 2 - 1)
    }
}

func fmt(_ value: CGFloat) -> String {
    String(format: "%.2f", Double(value))
}

func point(_ p: CGPoint) -> String { "\(fmt(p.x)) \(fmt(p.y))" }

func cubic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGPoint {
    let u = 1 - t
    let a = u * u * u
    let b = 3 * u * u * t
    let c = 3 * u * t * t
    let d = t * t * t
    return CGPoint(x: a * p0.x + b * p1.x + c * p2.x + d * p3.x,
                   y: a * p0.y + b * p1.y + c * p2.y + d * p3.y)
}

func normal(for points: [CGPoint], at index: Int) -> CGPoint {
    let previous = points[max(0, index - 1)]
    let next = points[min(points.count - 1, index + 1)]
    let dx = next.x - previous.x
    let dy = next.y - previous.y
    let length = max(0.001, sqrt(dx * dx + dy * dy))
    return CGPoint(x: -dy / length, y: dx / length)
}

func clamp01(_ value: CGFloat) -> CGFloat {
    min(1, max(0, value))
}

func smoothstep(_ value: CGFloat) -> CGFloat {
    let t = clamp01(value)
    return t * t * (3 - 2 * t)
}

func mix(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

func noiseControls(seed: UInt64, count: Int) -> [CGFloat] {
    var noise = SeededNoise(seed)
    return (0..<count).map { _ in noise.next() }
}

func lowFrequencyValue(_ controls: [CGFloat], at t: CGFloat) -> CGFloat {
    guard controls.count > 1 else { return controls.first ?? 0 }
    let scaled = clamp01(t) * CGFloat(controls.count - 1)
    let lower = min(controls.count - 2, max(0, Int(floor(scaled))))
    let local = smoothstep(scaled - CGFloat(lower))
    return mix(controls[lower], controls[lower + 1], local)
}

func brushedPath(points: [CGPoint], widths: [CGFloat], seed: UInt64, roughness: CGFloat) -> String {
    precondition(points.count == widths.count)
    let leftBody = noiseControls(seed: seed ^ 0x510B_0D1E, count: 5)
    let rightBody = noiseControls(seed: seed ^ 0xB01D_FACE, count: 5)
    let leftTail = noiseControls(seed: seed ^ 0xD2A1_BA55, count: 4)
    let rightTail = noiseControls(seed: seed ^ 0xF00D_CAFE, count: 4)
    var left: [CGPoint] = []
    var right: [CGPoint] = []

    for index in points.indices {
        let t = CGFloat(index) / CGFloat(points.count - 1)
        let n = normal(for: points, at: index)
        let body = pow(max(0, sin(.pi * t)), 0.6)
        let dryTail = smoothstep((t - 0.8) / 0.2)
        let bodyEnergy = 0.35 + 0.65 * body
        let tailEnergy = dryTail * (0.3 + 0.7 * body)
        let lowLeft = lowFrequencyValue(leftBody, at: t)
        let lowRight = lowFrequencyValue(rightBody, at: t)
        let dryLeft = lowFrequencyValue(leftTail, at: t)
        let dryRight = lowFrequencyValue(rightTail, at: t)
        let baseWidth = widths[index]
        let leftWidth = max(0.35, baseWidth + baseWidth * 0.07 * lowLeft * bodyEnergy + roughness * dryLeft * tailEnergy)
        let rightWidth = max(0.35, baseWidth + baseWidth * 0.07 * lowRight * bodyEnergy + roughness * dryRight * tailEnergy)
        left.append(CGPoint(x: points[index].x + n.x * leftWidth / 2, y: points[index].y + n.y * leftWidth / 2))
        right.append(CGPoint(x: points[index].x - n.x * rightWidth / 2, y: points[index].y - n.y * rightWidth / 2))
    }

    let commands = ["M \(point(left[0]))"]
        + left.dropFirst().map { "L \(point($0))" }
        + right.reversed().map { "L \(point($0))" }
        + ["Z"]
    return commands.joined(separator: " ")
}

struct BrushStroke {
    let body: String
    let hairs: [String]
}

func tailHairStrokes(points: [CGPoint], widths: [CGFloat], seed: UInt64, count: Int) -> [String] {
    guard count > 0 else { return [] }
    var noise = SeededNoise(seed ^ 0x7A11_5EED)
    return (0..<count).map { index in
        let start = 0.79 + CGFloat(index) * 0.035 + max(0, noise.next()) * 0.018
        let side: CGFloat = noise.next() < 0 ? -1 : 1
        let spread = 0.24 + CGFloat(index) * 0.08 + abs(noise.next()) * 0.08
        let steps = 6
        let hairPoints: [CGPoint] = (0..<steps).map { step in
            let local = CGFloat(step) / CGFloat(steps - 1)
            let t = min(1, start + (1 - start) * local)
            let sample = min(points.count - 1, max(0, Int(round(t * CGFloat(points.count - 1)))))
            let n = normal(for: points, at: sample)
            let offset = side * (widths[sample] * spread + CGFloat(index) * 0.9) + noise.next() * 0.35
            return CGPoint(x: points[sample].x + n.x * offset, y: points[sample].y + n.y * offset)
        }
        return (["M \(point(hairPoints[0]))"] + hairPoints.dropFirst().map { "L \(point($0))" }).joined(separator: " ")
    }
}

func brushElements(_ stroke: BrushStroke, fill: String = ink) -> String {
    (["<path d=\"\(stroke.body)\" fill=\"\(fill)\"/>"]
        + stroke.hairs.map { "<path d=\"\($0)\" fill=\"none\" stroke=\"\(fill)\" stroke-width=\"1.45\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>" })
        .joined(separator: "\n  ")
}

func cubicBrushStroke(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, samples: Int, seed: UInt64, roughness: CGFloat, hairCount: Int = 0, width: (CGFloat) -> CGFloat) -> BrushStroke {
    var points: [CGPoint] = []
    var widths: [CGFloat] = []
    for step in 0..<samples {
        let t = CGFloat(step) / CGFloat(samples - 1)
        points.append(cubic(p0, p1, p2, p3, t))
        widths.append(max(0.35, width(t)))
    }
    return BrushStroke(
        body: brushedPath(points: points, widths: widths, seed: seed, roughness: roughness),
        hairs: tailHairStrokes(points: points, widths: widths, seed: seed, count: hairCount)
    )
}

func arcBrushStroke(center: CGPoint, radius: CGFloat, startDegrees: CGFloat, endDegrees: CGFloat, samples: Int, maxWidth: CGFloat, seed: UInt64, hairCount: Int = 0) -> BrushStroke {
    let start = startDegrees * .pi / 180
    let end = endDegrees * .pi / 180
    var points: [CGPoint] = []
    var widths: [CGFloat] = []
    for step in 0..<samples {
        let t = CGFloat(step) / CGFloat(samples - 1)
        let angle = start + (end - start) * t
        let irregularRadius = radius + sin(t * .pi * 1.5 + CGFloat(seed % 11)) * 1.35
        points.append(CGPoint(x: center.x + cos(angle) * irregularRadius, y: center.y + sin(angle) * irregularRadius))
        let pressure = pow(max(0, sin(.pi * t)), 0.6)
        widths.append(max(0.5, pressure * maxWidth))
    }
    return BrushStroke(
        body: brushedPath(points: points, widths: widths, seed: seed, roughness: maxWidth * 0.05),
        hairs: tailHairStrokes(points: points, widths: widths, seed: seed, count: hairCount)
    )
}

func svgDocument(_ body: String, width: Int = 1024, height: Int = 1024) -> String {
    """
    <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(width) \(height)\" width=\"\(width)\" height=\"\(height)\">
    \(body)
    </svg>
    """
}

func writeText(_ name: String, _ content: String) {
    try! content.write(to: source.appendingPathComponent(name), atomically: true, encoding: .utf8)
}

func generateSourceSVGs() {
    let background = svgDocument("""
      <defs>
        <radialGradient id=\"warmth\" cx=\"46%\" cy=\"42%\" r=\"72%\">
          <stop offset=\"0%\" stop-color=\"\(paperWarm)\"/>
          <stop offset=\"100%\" stop-color=\"\(paper)\"/>
        </radialGradient>
      </defs>
      <rect width=\"1024\" height=\"1024\" fill=\"url(#warmth)\"/>
    """)

    let mastTip = CGPoint(x: 350, y: 455)
    let arcs = [
        arcBrushStroke(center: mastTip, radius: 96, startDegrees: -48, endDegrees: 48, samples: 50, maxWidth: 14, seed: 0xA111),
        arcBrushStroke(center: mastTip, radius: 194, startDegrees: -48, endDegrees: 49, samples: 64, maxWidth: 26, seed: 0xB222, hairCount: 1),
        arcBrushStroke(center: mastTip, radius: 306, startDegrees: -47, endDegrees: 49, samples: 76, maxWidth: 34, seed: 0xC333, hairCount: 1)
    ]
    let waveBody = arcs.map { brushElements($0) }.joined(separator: "\n  ")

    let mastStroke = cubicBrushStroke(
        CGPoint(x: 318, y: 788), CGPoint(x: 330, y: 676), CGPoint(x: 341, y: 558), mastTip,
        samples: 64,
        seed: 0xD444,
        roughness: 2.2,
        hairCount: 2
    ) { t in
        2.5 + pow(1 - t, 0.88) * 48 + sin(.pi * t) * 4
    }
    let mastBody = "  \(brushElements(mastStroke))"

    let sealBody = "<!-- seal intentionally omitted: the maple mark did not remain legible at 60 px -->"

    let landscapeTip = CGPoint(x: 260, y: 284)
    let landscapeBase = cubicBrushStroke(
        CGPoint(x: 170, y: 462), CGPoint(x: 210, y: 448), CGPoint(x: 285, y: 448), CGPoint(x: 330, y: 462),
        samples: 38,
        seed: 0xF666,
        roughness: 1.2
    ) { t in
        pow(max(0, sin(.pi * t)), 0.55) * 12
    }
    let landscapeMast = cubicBrushStroke(
        CGPoint(x: 226, y: 455), CGPoint(x: 235, y: 392), CGPoint(x: 246, y: 332), landscapeTip,
        samples: 44,
        seed: 0xABCD,
        roughness: 1.6,
        hairCount: 1
    ) { t in
        1.2 + pow(1 - t, 0.86) * 28 + sin(.pi * t) * 3
    }
    let landscapeArcs = [
        arcBrushStroke(center: landscapeTip, radius: 150, startDegrees: -20, endDegrees: 22, samples: 36, maxWidth: 14, seed: 0x7711),
        arcBrushStroke(center: landscapeTip, radius: 310, startDegrees: -20, endDegrees: 22, samples: 46, maxWidth: 21, seed: 0x7722),
        arcBrushStroke(center: landscapeTip, radius: 540, startDegrees: -19, endDegrees: 21, samples: 58, maxWidth: 25, seed: 0x7733, hairCount: 1)
    ].map { brushElements($0) }.joined(separator: "\n  ")
    let landscape = svgDocument("""
      \(brushElements(landscapeBase))
      \(landscapeArcs)
      \(brushElements(landscapeMast))
    """, width: 1400, height: 600)

    let favicon = adaptiveFaviconSVG()

    writeText("background.svg", background)
    writeText("waves.svg", svgDocument(waveBody))
    writeText("mast.svg", svgDocument(mastBody))
    writeText("seal.svg", svgDocument(sealBody))
    writeText("landscape.svg", landscape)
    try! favicon.write(to: exports.appendingPathComponent("favicon.svg"), atomically: true, encoding: .utf8)
}

generateSourceSVGs()

func svg(_ name: String) -> NSImage {
    let url = source.appendingPathComponent(name)
    guard let image = NSImage(contentsOf: url) else {
        fatalError("Unable to load SVG source: \(url.path)")
    }
    return image
}

let background = svg("background.svg")
let waves = svg("waves.svg")
let mast = svg("mast.svg")
let seal = svg("seal.svg")
let landscape = svg("landscape.svg")

func makePNG(width: Int, height: Int, opaque: Bool, draw: (CGRect) -> Void) -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let alphaInfo: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    guard let cgContext = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: alphaInfo.rawValue
    ) else { fatalError("Could not allocate bitmap context") }

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(cgContext: cgContext, flipped: false)
    NSGraphicsContext.current = context
    cgContext.interpolationQuality = .high
    let canvas = CGRect(x: 0, y: 0, width: width, height: height)
    if opaque {
        NSColor(calibratedRed: 0.9647, green: 0.9333, blue: 0.8627, alpha: 1).setFill()
        canvas.fill()
    } else {
        cgContext.clear(canvas)
    }
    draw(canvas)
    NSGraphicsContext.restoreGraphicsState()

    guard let cgImage = cgContext.makeImage() else { fatalError("Could not create image") }
    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
    return data
}

func draw(_ image: NSImage, in rect: CGRect, fraction: CGFloat = 1) {
    let sourceRect = CGRect(origin: .zero, size: image.size)
    image.draw(in: rect, from: sourceRect, operation: .sourceOver, fraction: fraction, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high.rawValue])
}

func aspectFitRect(for image: NSImage, in rect: CGRect) -> CGRect {
    let imageAspect = image.size.width / image.size.height
    let rectAspect = rect.width / rect.height
    if rectAspect > imageAspect {
        let width = rect.height * imageAspect
        return CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: rect.height)
    }
    let height = rect.width / imageAspect
    return CGRect(x: rect.minX, y: rect.midY - height / 2, width: rect.width, height: height)
}

func drawAspectFit(_ image: NSImage, in rect: CGRect, fraction: CGFloat = 1) {
    draw(image, in: aspectFitRect(for: image, in: rect), fraction: fraction)
}

func centeredSquare(in rect: CGRect, scale: CGFloat = 1) -> CGRect {
    let side = min(rect.width, rect.height) * scale
    return CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
}

func iconRect(in rect: CGRect, scale: CGFloat = 1) -> CGRect {
    centeredSquare(in: rect, scale: scale)
}

func landscapeRect(in rect: CGRect, wide: Bool) -> CGRect {
    let sourceAspect: CGFloat = 1400 / 600
    let maxHeight = rect.height * (wide ? 0.55 : 0.52)
    let maxWidth = rect.width * (wide ? 0.42 : 0.46)
    let height = min(maxHeight, maxWidth / sourceAspect)
    let width = height * sourceAspect
    return CGRect(x: rect.width * 0.04, y: rect.midY - height / 2, width: width, height: height)
}

func write(_ name: String, width: Int, height: Int, opaque: Bool, drawBlock: @escaping (CGRect) -> Void) {
    let data = makePNG(width: width, height: height, opaque: opaque, draw: drawBlock)
    try! data.write(to: exports.appendingPathComponent(name))
}

func drawFullIcon(in rect: CGRect) {
    let square = iconRect(in: rect)
    draw(background, in: rect)
    draw(waves, in: square)
    draw(mast, in: square)
    draw(seal, in: square)
}

func drawMiddle(in rect: CGRect) { draw(waves, in: iconRect(in: rect)) }
func drawFront(in rect: CGRect) { let square = iconRect(in: rect); draw(mast, in: square); draw(seal, in: square) }
func drawBack(in rect: CGRect) { draw(background, in: rect) }

write("app-icon-1024.png", width: 1024, height: 1024, opaque: true) { drawFullIcon(in: $0) }
write("app-icon-60.png", width: 60, height: 60, opaque: true) { drawFullIcon(in: $0) }
write("app-icon-120.png", width: 120, height: 120, opaque: true) { drawFullIcon(in: $0) }
write("visionos-back-1024.png", width: 1024, height: 1024, opaque: true) { drawBack(in: $0) }
write("visionos-middle-1024.png", width: 1024, height: 1024, opaque: false) { drawMiddle(in: $0) }
write("visionos-front-1024.png", width: 1024, height: 1024, opaque: false) { drawFront(in: $0) }

let tvSpecs = [
    SizeSpec(name: "tvos-small-400x240", width: 400, height: 240),
    SizeSpec(name: "tvos-small-800x480", width: 800, height: 480),
    SizeSpec(name: "tvos-app-store-1280x768", width: 1280, height: 768)
]
for spec in tvSpecs {
    write("\(spec.name)-back.png", width: spec.width, height: spec.height, opaque: true) { rect in draw(background, in: rect) }
    write("\(spec.name)-middle.png", width: spec.width, height: spec.height, opaque: false) { rect in draw(waves, in: centeredSquare(in: rect, scale: 0.9)) }
    write("\(spec.name)-front.png", width: spec.width, height: spec.height, opaque: false) { rect in let square = centeredSquare(in: rect, scale: 0.9); draw(mast, in: square); draw(seal, in: square) }
}

func serifFont(size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .semibold)
    if let descriptor = base.fontDescriptor.withDesign(.serif),
       let font = NSFont(descriptor: descriptor, size: size) {
        return font
    }
    return NSFont(name: "IowanOldStyle-Roman", size: size)
        ?? NSFont(name: "Georgia", size: size)
        ?? base
}

func drawTopShelf(in rect: CGRect, wide: Bool) {
    draw(background, in: rect)
    drawAspectFit(landscape, in: landscapeRect(in: rect, wide: wide))
    let textX = rect.width * (wide ? 0.58 : 0.57)
    let textRect = CGRect(x: textX, y: rect.height * 0.36, width: rect.width * 0.34, height: rect.height * 0.3)
    let title = "Canadian Ham"
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    let attributes: [NSAttributedString.Key: Any] = [
        .font: serifFont(size: max(54, rect.height * 0.12)),
        .foregroundColor: NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1),
        .paragraphStyle: paragraph
    ]
    title.draw(in: textRect, withAttributes: attributes)
}

write("tvos-top-shelf-1920x720.png", width: 1920, height: 720, opaque: true) { drawTopShelf(in: $0, wide: false) }
write("tvos-top-shelf-3840x1440.png", width: 3840, height: 1440, opaque: true) { drawTopShelf(in: $0, wide: false) }
write("tvos-top-shelf-wide-2320x720.png", width: 2320, height: 720, opaque: true) { drawTopShelf(in: $0, wide: true) }
write("tvos-top-shelf-wide-4640x1440.png", width: 4640, height: 1440, opaque: true) { drawTopShelf(in: $0, wide: true) }

write("apple-touch-icon-180.png", width: 180, height: 180, opaque: true) { drawFullIcon(in: $0) }
write("pwa-icon-192.png", width: 192, height: 192, opaque: true) { drawFullIcon(in: $0) }
write("pwa-icon-512.png", width: 512, height: 512, opaque: true) { drawFullIcon(in: $0) }

guard let faviconLightData = lightFaviconSVG().data(using: .utf8),
      let faviconLightImage = NSImage(data: faviconLightData) else {
    fatalError("Unable to load inline light favicon SVG")
}
write("favicon-16.png", width: 16, height: 16, opaque: true) { draw(faviconLightImage, in: $0) }
write("favicon-32.png", width: 32, height: 32, opaque: true) { draw(faviconLightImage, in: $0) }
write("favicon-64.png", width: 64, height: 64, opaque: true) { draw(faviconLightImage, in: $0) }

let previewItems = [
    SizeSpec(name: "app-icon-1024.png", width: 160, height: 160),
    SizeSpec(name: "app-icon-60.png", width: 60, height: 60),
    SizeSpec(name: "app-icon-120.png", width: 120, height: 120),
    SizeSpec(name: "visionos-back-1024.png", width: 110, height: 110),
    SizeSpec(name: "visionos-middle-1024.png", width: 110, height: 110),
    SizeSpec(name: "visionos-front-1024.png", width: 110, height: 110),
    SizeSpec(name: "apple-touch-icon-180.png", width: 90, height: 90),
    SizeSpec(name: "pwa-icon-192.png", width: 90, height: 90),
    SizeSpec(name: "pwa-icon-512.png", width: 90, height: 90),
    SizeSpec(name: "favicon-16.png", width: 16, height: 16),
    SizeSpec(name: "favicon-32.png", width: 32, height: 32),
    SizeSpec(name: "favicon-64.png", width: 64, height: 64),
    SizeSpec(name: "tvos-small-400x240-back.png", width: 150, height: 90),
    SizeSpec(name: "tvos-small-400x240-middle.png", width: 150, height: 90),
    SizeSpec(name: "tvos-small-400x240-front.png", width: 150, height: 90),
    SizeSpec(name: "tvos-app-store-1280x768-back.png", width: 150, height: 90),
    SizeSpec(name: "tvos-app-store-1280x768-middle.png", width: 150, height: 90),
    SizeSpec(name: "tvos-app-store-1280x768-front.png", width: 150, height: 90),
    SizeSpec(name: "tvos-top-shelf-1920x720.png", width: 240, height: 90),
    SizeSpec(name: "tvos-top-shelf-wide-2320x720.png", width: 290, height: 90)
]
let sheetWidth = 980
let rowHeight = 190
let columns = 3
let rows = Int(ceil(Double(previewItems.count) / Double(columns)))
write("preview-sheet.png", width: sheetWidth, height: rows * rowHeight + 80, opaque: true) { rect in
    NSColor(calibratedRed: 0.9647, green: 0.9333, blue: 0.8627, alpha: 1).setFill()
    rect.fill()
    for (index, item) in previewItems.enumerated() {
        guard let img = NSImage(contentsOf: exports.appendingPathComponent(item.name)) else { continue }
        let col = index % columns
        let row = index / columns
        let cellX = CGFloat(col) * CGFloat(sheetWidth / columns) + 20
        let cellY = CGFloat(rows - row - 1) * CGFloat(rowHeight) + 20
        let imageRect = CGRect(x: cellX, y: cellY + 44, width: CGFloat(item.width), height: CGFloat(item.height))
        NSColor.white.withAlphaComponent(0.45).setFill()
        imageRect.insetBy(dx: -6, dy: -6).fill()
        draw(img, in: imageRect)
        let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.black]
        item.name.draw(in: CGRect(x: cellX, y: cellY + 8, width: 290, height: 24), withAttributes: attrs)
    }
}

print("Rendered app icon exports to \(exports.path)")
