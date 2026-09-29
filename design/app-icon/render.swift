#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("design/app-icon")
let source = root.appendingPathComponent("src")
let exports = root.appendingPathComponent("exports")
try FileManager.default.createDirectory(at: exports, withIntermediateDirectories: true)

struct SizeSpec {
    let name: String
    let width: Int
    let height: Int
}

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

func iconRect(in rect: CGRect, scale: CGFloat = 0.88) -> CGRect {
    centeredSquare(in: rect, scale: scale)
}

func landscapeIconRect(in rect: CGRect, scale: CGFloat = 0.92) -> CGRect {
    let side = min(rect.height * scale, rect.width * 0.5)
    return CGRect(x: rect.width * 0.18, y: rect.midY - side / 2, width: side, height: side)
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
    write("\(spec.name)-middle.png", width: spec.width, height: spec.height, opaque: false) { rect in draw(waves, in: centeredSquare(in: rect, scale: 0.82)) }
    write("\(spec.name)-front.png", width: spec.width, height: spec.height, opaque: false) { rect in let square = centeredSquare(in: rect, scale: 0.82); draw(mast, in: square); draw(seal, in: square) }
}

func drawTopShelf(in rect: CGRect, wide: Bool) {
    draw(background, in: rect)
    let square = wide ? landscapeIconRect(in: rect, scale: 0.88) : centeredSquare(in: rect, scale: 0.62)
    draw(waves, in: square)
    draw(mast, in: square)
    draw(seal, in: square)
    let textRect = CGRect(x: wide ? rect.width * 0.54 : rect.width * 0.55, y: rect.height * 0.35, width: rect.width * 0.34, height: rect.height * 0.3)
    let title = "Canadian Ham"
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .left
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: max(32, rect.height * 0.085), weight: .semibold),
        .foregroundColor: NSColor(calibratedRed: 0.1216, green: 0.102, blue: 0.0784, alpha: 1),
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
