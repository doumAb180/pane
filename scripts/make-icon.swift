import AppKit

let directory = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let n = CGFloat(pixels)
        let bounds = NSRect(x: n * 0.07, y: n * 0.07, width: n * 0.86, height: n * 0.86)
        let shape = NSBezierPath(roundedRect: bounds, xRadius: n * 0.2, yRadius: n * 0.2)
        NSGradient(starting: NSColor(calibratedRed: 0.42, green: 0.48, blue: 1, alpha: 1),
                   ending: NSColor(calibratedRed: 0.27, green: 0.25, blue: 0.78, alpha: 1))!.draw(in: shape, angle: -60)
        func pane(_ rect: NSRect, alpha: CGFloat) {
            NSColor.white.withAlphaComponent(alpha).setFill()
            NSBezierPath(roundedRect: rect, xRadius: n * 0.035, yRadius: n * 0.035).fill()
        }
        pane(NSRect(x: n * 0.24, y: n * 0.24, width: n * 0.24, height: n * 0.52), alpha: 1)
        pane(NSRect(x: n * 0.52, y: n * 0.52, width: n * 0.24, height: n * 0.24), alpha: 0.55)
        pane(NSRect(x: n * 0.52, y: n * 0.24, width: n * 0.24, height: n * 0.24), alpha: 0.8)
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: directory).appendingPathComponent(name))
    }
}
