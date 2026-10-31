// Draws the BrowserChooser app icon (a white globe on a blue rounded square)
// and writes Resources/AppIcon.icns.
//
// Usage: swift Scripts/make-icon.swift   (or: make icon)

import AppKit
import CoreGraphics

let projectDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let outputURL = projectDir.appendingPathComponent("Resources/AppIcon.icns")

/// Draws the icon into a square context of `size` pixels, using a 1024-point design grid.
func drawIcon(in ctx: CGContext, size: CGFloat) {
    let s = size / 1024
    ctx.scaleBy(x: s, y: s)

    // Background: rounded square on Apple's macOS icon grid (824pt body, 100pt margin).
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24,
                  color: CGColor(gray: 0, alpha: 0.3))
    ctx.addPath(bodyPath)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let colors = [
        CGColor(red: 0.29, green: 0.66, blue: 1.00, alpha: 1),  // top
        CGColor(red: 0.05, green: 0.36, blue: 0.85, alpha: 1),  // bottom
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()

    // Globe: outline, two meridian ellipses, a central meridian, equator and two parallels.
    let c = CGPoint(x: 512, y: 512)
    let r: CGFloat = 270
    let globe = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)

    ctx.saveGState()
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
    ctx.setLineCap(.round)

    // Inner lines, clipped to the globe so they meet the outline cleanly.
    ctx.saveGState()
    ctx.addEllipse(in: globe)
    ctx.clip()
    ctx.setLineWidth(26)
    for w in [0.45 * r] {
        ctx.strokeEllipse(in: CGRect(x: c.x - w, y: c.y - r, width: 2 * w, height: 2 * r))
    }
    ctx.move(to: CGPoint(x: c.x, y: c.y - r))
    ctx.addLine(to: CGPoint(x: c.x, y: c.y + r))
    for dy in [-0.5 * r, 0, 0.5 * r] {
        ctx.move(to: CGPoint(x: c.x - r, y: c.y + dy))
        ctx.addLine(to: CGPoint(x: c.x + r, y: c.y + dy))
    }
    ctx.strokePath()
    ctx.restoreGState()

    ctx.setLineWidth(34)
    ctx.strokeEllipse(in: globe)
    ctx.restoreGState()
}

func pngData(pixels: Int) -> Data {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawIcon(in: ctx, size: CGFloat(pixels))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let iconset = FileManager.default.temporaryDirectory
    .appendingPathComponent("AppIcon-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: iconset) }

for base in [16, 32, 128, 256, 512] {
    try pngData(pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try pngData(pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write("iconutil failed\n".data(using: .utf8)!)
    exit(1)
}
print("Wrote \(outputURL.path)")
