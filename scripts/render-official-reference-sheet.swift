// Offline reproduction of the unlabelled exam PDF; do not redraw or annotate pages.
// Usage: swift scripts/render-official-reference-sheet.swift <source PDF> <output directory>
import AppKit
import PDFKit

let document = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
let output = CommandLine.arguments[2]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
for index in 0..<document.pageCount {
    let page = document.page(at: index)!
    let bounds = page.bounds(for: .mediaBox)
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(bounds.width * 2), pixelsHigh: Int(bounds.height * 2),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
    context.setFillColor(NSColor.white.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: bitmap.pixelsWide, height: bitmap.pixelsHigh))
    context.scaleBy(x: 2, y: 2)
    page.draw(with: .mediaBox, to: context)
    try bitmap.representation(using: .png, properties: [:])!.write(
        to: URL(fileURLWithPath: "\(output)/page-\(index + 1).png")
    )
}
