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

func brushedPath(points: [CGPoint], widths: [CGFloat], seed: UInt64, roughness: CGFloat) -> String {
    precondition(points.count == widths.count)
    var noise = SeededNoise(seed)
    var left: [CGPoint] = []
    var right: [CGPoint] = []

    for index in points.indices {
        let t = CGFloat(index) / CGFloat(points.count - 1)
        let n = normal(for: points, at: index)
        let body = pow(max(0, sin(.pi * t)), 0.6)
        let taperGuard: CGFloat = index == 0 || index == points.count - 1 ? 0.2 : 1
        let edgeEnergy = (0.25 + 0.75 * body) * taperGuard
        let leftWidth = max(0.35, widths[index] + noise.next() * roughness * edgeEnergy)
        let rightWidth = max(0.35, widths[index] + noise.next() * roughness * edgeEnergy)
        left.append(CGPoint(x: points[index].x + n.x * leftWidth / 2, y: points[index].y + n.y * leftWidth / 2))
        right.append(CGPoint(x: points[index].x - n.x * rightWidth / 2, y: points[index].y - n.y * rightWidth / 2))
    }

    let commands = ["M \(point(left[0]))"]
        + left.dropFirst().map { "L \(point($0))" }
        + right.reversed().map { "L \(point($0))" }
        + ["Z"]
    return commands.joined(separator: " ")
}

func cubicBrushPath(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, samples: Int, seed: UInt64, roughness: CGFloat, width: (CGFloat) -> CGFloat) -> String {
    var points: [CGPoint] = []
    var widths: [CGFloat] = []
    for step in 0..<samples {
        let t = CGFloat(step) / CGFloat(samples - 1)
        points.append(cubic(p0, p1, p2, p3, t))
        widths.append(max(0.35, width(t)))
    }
    return brushedPath(points: points, widths: widths, seed: seed, roughness: roughness)
}

func arcBrushPath(center: CGPoint, radius: CGFloat, startDegrees: CGFloat, endDegrees: CGFloat, samples: Int, maxWidth: CGFloat, seed: UInt64) -> String {
    let start = startDegrees * .pi / 180
    let end = endDegrees * .pi / 180
    var points: [CGPoint] = []
    var widths: [CGFloat] = []
    for step in 0..<samples {
        let t = CGFloat(step) / CGFloat(samples - 1)
        let angle = start + (end - start) * t
        let irregularRadius = radius + sin(t * .pi * 4 + CGFloat(seed % 11)) * 2.0
        points.append(CGPoint(x: center.x + cos(angle) * irregularRadius, y: center.y + sin(angle) * irregularRadius))
        let pressure = pow(max(0, sin(.pi * t)), 0.6)
        widths.append(max(0.5, pressure * maxWidth))
    }
    return brushedPath(points: points, widths: widths, seed: seed, roughness: maxWidth * 0.11)
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

    let arcs = [
        arcBrushPath(center: CGPoint(x: 427, y: 430), radius: 142, startDegrees: -50, endDegrees: 42, samples: 58, maxWidth: 22, seed: 0xA111),
        arcBrushPath(center: CGPoint(x: 427, y: 430), radius: 265, startDegrees: -55, endDegrees: 50, samples: 72, maxWidth: 38, seed: 0xB222),
        arcBrushPath(center: CGPoint(x: 427, y: 430), radius: 380, startDegrees: -52, endDegrees: 52, samples: 80, maxWidth: 47, seed: 0xC333)
    ]
    let waveBody = arcs.map { "<path d=\"\($0)\" fill=\"\(ink)\"/>" }.joined(separator: "\n  ")

    let mastPath = cubicBrushPath(
        CGPoint(x: 312, y: 746), CGPoint(x: 335, y: 610), CGPoint(x: 369, y: 380), CGPoint(x: 413, y: 224),
        samples: 56,
        seed: 0xD444,
        roughness: 4
    ) { t in
        1.2 + pow(1 - t, 0.82) * 58 + sin(.pi * t) * 8
    }
    let groundPath = cubicBrushPath(
        CGPoint(x: 235, y: 758), CGPoint(x: 308, y: 725), CGPoint(x: 423, y: 728), CGPoint(x: 519, y: 744),
        samples: 38,
        seed: 0xE555,
        roughness: 3
    ) { t in
        pow(max(0, sin(.pi * t)), 0.55) * 26
    }
    let mastBody = """
      <path d=\"\(groundPath)\" fill=\"\(ink)\"/>
      <path d=\"\(mastPath)\" fill=\"\(ink)\"/>
    """

    let sealBody = "<!-- seal intentionally omitted: the maple mark did not remain legible at 60 px -->"

    let landscapeGround = cubicBrushPath(
        CGPoint(x: 120, y: 430), CGPoint(x: 390, y: 380), CGPoint(x: 790, y: 430), CGPoint(x: 1120, y: 395),
        samples: 74,
        seed: 0xF666,
        roughness: 4
    ) { t in
        pow(max(0, sin(.pi * t)), 0.5) * 28
    }
    let landscapeMast = cubicBrushPath(
        CGPoint(x: 365, y: 415), CGPoint(x: 386, y: 330), CGPoint(x: 416, y: 205), CGPoint(x: 452, y: 105),
        samples: 42,
        seed: 0xABCD,
        roughness: 3
    ) { t in
        1 + pow(1 - t, 0.82) * 38 + sin(.pi * t) * 5
    }
    let landscapeArcs = [
        arcBrushPath(center: CGPoint(x: 460, y: 235), radius: 118, startDegrees: -38, endDegrees: 44, samples: 30, maxWidth: 19, seed: 0x7711),
        arcBrushPath(center: CGPoint(x: 460, y: 235), radius: 198, startDegrees: -34, endDegrees: 38, samples: 36, maxWidth: 27, seed: 0x7722),
        arcBrushPath(center: CGPoint(x: 460, y: 235), radius: 286, startDegrees: -28, endDegrees: 32, samples: 42, maxWidth: 32, seed: 0x7733)
    ].map { "<path d=\"\($0)\" fill=\"\(ink)\"/>" }.joined(separator: "\n  ")
    let landscape = svgDocument("""
      <path d=\"\(landscapeGround)\" fill=\"\(ink)\" opacity=\"0.95\"/>
      \(landscapeArcs)
      <path d=\"\(landscapeMast)\" fill=\"\(ink)\"/>
    """, width: 1400, height: 600)

    let favicon = """
    <svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\">
      <style>
        .paper { fill: #f6eedc; }
        .ink { fill: #000; }
        @media (prefers-color-scheme: dark) {
          .paper { fill: #201b16; }
          .ink { fill: #f3e8d2; }
        }
      </style>
      <rect width=\"64\" height=\"64\" rx=\"14\" class=\"paper\"/>
      <path class=\"ink\" d=\"M22 49 C24 39 26 28 30 12 C32 8 36 9 35 14 C32 29 30 40 29 51 C28 56 20 55 22 49 Z\"/>
      <path class=\"ink\" d=\"M16 50 C24 45 35 45 44 49 C48 51 46 55 42 54 C33 51 25 51 18 54 C14 55 12 52 16 50 Z\"/>
      <path class=\"ink\" d=\"M38 18 C47 22 53 30 55 41 C56 46 49 47 48 42 C47 34 42 28 34 25 C30 23 33 16 38 18 Z\"/>
      <path class=\"ink\" d=\"M39 29 C44 32 47 36 48 42 C48 46 42 47 41 43 C40 39 37 36 34 35 C30 33 34 27 39 29 Z\" opacity=\"0.92\"/>
    </svg>
    """

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

func centeredSquare(in rect: CGRect, scale: CGFloat = 1) -> CGRect {
    let side = min(rect.width, rect.height) * scale
    return CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
}

func iconRect(in rect: CGRect, scale: CGFloat = 1) -> CGRect {
    centeredSquare(in: rect, scale: scale)
}

func landscapeRect(in rect: CGRect, wide: Bool) -> CGRect {
    let heightScale: CGFloat = wide ? 0.78 : 0.72
    let height = rect.height * heightScale
    let width = min(rect.width * (wide ? 0.48 : 0.44), height * 2.2)
    return CGRect(x: rect.width * 0.08, y: rect.midY - height / 2, width: width, height: height)
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
    NSFont(name: "NewYork-Regular", size: size)
        ?? NSFont(name: "IowanOldStyle-Roman", size: size)
        ?? NSFont(name: "Georgia", size: size)
        ?? NSFont.systemFont(ofSize: size, weight: .semibold)
}

func drawTopShelf(in rect: CGRect, wide: Bool) {
    draw(background, in: rect)
    draw(landscape, in: landscapeRect(in: rect, wide: wide))
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
