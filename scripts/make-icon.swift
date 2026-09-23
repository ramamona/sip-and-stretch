#!/usr/bin/env swift
// Renders the Sip & Stretch app icon (Drip the water droplet) and builds AppIcon.icns.
//
// Usage: swift scripts/make-icon.swift <output-dir>
// Writes <output-dir>/AppIcon.icns and <output-dir>/AppIcon-1024.png.
// Needs only the Command Line Tools (AppKit + CoreGraphics + /usr/bin/iconutil).
//
// Everything is drawn as vectors in a 1024x1024 design space (y points up) and
// re-rendered at every pixel size, so small sizes stay crisp instead of being
// downscaled from the big one.

import AppKit

let S: CGFloat = 1024
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
/// At 16/32 px fine detail turns to mush, so those sizes get a simplified drawing.
var tiny = false

// MARK: - Helpers

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func gradient(_ stops: [(CGColor, CGFloat)]) -> CGGradient {
    CGGradient(colorsSpace: sRGB, colors: stops.map(\.0) as CFArray, locations: stops.map(\.1))!
}

/// CoreGraphics shadows ignore the CTM, so scale them by the current render scale.
func setShadow(_ ctx: CGContext, dy: CGFloat, blur: CGFloat, _ c: CGColor) {
    let s = ctx.ctm.a
    ctx.setShadow(offset: CGSize(width: 0, height: dy * s), blur: blur * s, color: c)
}

func fillEllipse(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h))
}

/// Rounded rect with continuous ("squircle") corners, like the macOS icon mask.
/// Uses the well-known Bezier approximation of Apple's continuous corner curve.
func squircle(_ rect: CGRect, radius r: CGFloat) -> CGPath {
    // One corner, in units of r: (distance along incoming edge, distance along outgoing edge).
    let pts: [(CGFloat, CGFloat)] = [
        (1.52866, 0), (1.08849, 0), (0.86841, 0), (0.63149, 0.07491),
        (0.37282, 0.16906), (0.16906, 0.37282), (0.07491, 0.63149),
        (0, 0.86841), (0, 1.08849), (0, 1.52866),
    ]
    // (corner, unit vector back along incoming edge, unit vector along outgoing edge), counter-clockwise.
    let corners: [(CGPoint, CGVector, CGVector)] = [
        (CGPoint(x: rect.maxX, y: rect.minY), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: 1)),
        (CGPoint(x: rect.maxX, y: rect.maxY), CGVector(dx: 0, dy: -1), CGVector(dx: -1, dy: 0)),
        (CGPoint(x: rect.minX, y: rect.maxY), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: -1)),
        (CGPoint(x: rect.minX, y: rect.minY), CGVector(dx: 0, dy: 1), CGVector(dx: 1, dy: 0)),
    ]
    let path = CGMutablePath()
    for (c, u, v) in corners {
        let p = pts.map { a, b in
            CGPoint(x: c.x + (a * u.dx + b * v.dx) * r, y: c.y + (a * u.dy + b * v.dy) * r)
        }
        if path.isEmpty { path.move(to: p[0]) } else { path.addLine(to: p[0]) }
        for i in stride(from: 1, to: 10, by: 3) {
            path.addCurve(to: p[i + 2], control1: p[i], control2: p[i + 1])
        }
    }
    path.closeSubpath()
    return path
}

/// A sine wave filled down to the bottom of the canvas.
func wave(baseY: CGFloat, amp: CGFloat, length: CGFloat, phase: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: 0, y: 0))
    for x in stride(from: CGFloat(0), through: S, by: 8) {
        p.addLine(to: CGPoint(x: x, y: baseY + amp * sin(x / length * 2 * .pi + phase)))
    }
    p.addLine(to: CGPoint(x: S, y: 0))
    p.closeSubpath()
    return p
}

/// Four-pointed twinkle star.
func sparkle(_ ctx: CGContext, x: CGFloat, y: CGFloat, size s: CGFloat, alpha: CGFloat = 1) {
    let k = s * 0.16
    let p = CGMutablePath()
    p.move(to: CGPoint(x: x, y: y + s))
    p.addQuadCurve(to: CGPoint(x: x + s, y: y), control: CGPoint(x: x + k, y: y + k))
    p.addQuadCurve(to: CGPoint(x: x, y: y - s), control: CGPoint(x: x + k, y: y - k))
    p.addQuadCurve(to: CGPoint(x: x - s, y: y), control: CGPoint(x: x - k, y: y - k))
    p.addQuadCurve(to: CGPoint(x: x, y: y + s), control: CGPoint(x: x - k, y: y + k))
    ctx.addPath(p)
    ctx.setFillColor(color(0xFFFFFF, alpha))
    ctx.fillPath()
}

// MARK: - Drip

let dropCenter = CGPoint(x: 512, y: 450)  // center of the round bottom
let dropRadius: CGFloat = 220
let dropTipY: CGFloat = 850

func dropletPath() -> CGPath {
    let (cx, cy, r) = (dropCenter.x, dropCenter.y, dropRadius)
    let k = r * 0.5523  // quarter-circle Bezier constant
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx, y: dropTipY))
    p.addCurve(to: CGPoint(x: cx + r, y: cy),
               control1: CGPoint(x: cx + 50, y: dropTipY - 95), control2: CGPoint(x: cx + r, y: cy + 175))
    p.addCurve(to: CGPoint(x: cx, y: cy - r),
               control1: CGPoint(x: cx + r, y: cy - k), control2: CGPoint(x: cx + k, y: cy - r))
    p.addCurve(to: CGPoint(x: cx - r, y: cy),
               control1: CGPoint(x: cx - k, y: cy - r), control2: CGPoint(x: cx - r, y: cy - k))
    p.addCurve(to: CGPoint(x: cx, y: dropTipY),
               control1: CGPoint(x: cx - r, y: cy + 175), control2: CGPoint(x: cx - 50, y: dropTipY - 95))
    p.closeSubpath()
    return p
}

/// Fills a shape as glossy water: soft shadow, white-to-pale-blue radial fill, faint inner rim.
func drawWater(_ ctx: CGContext, _ shape: CGPath) {
    ctx.saveGState()
    setShadow(ctx, dy: -18, blur: 36, color(0x0B3A82, 0.5))
    ctx.addPath(shape)
    ctx.setFillColor(color(0xD8F1FF))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.drawRadialGradient(
        gradient([(color(0xF7FCFF), 0), (color(0xD8F1FF), 0.5), (color(0x8CCFF4), 1)]),
        startCenter: CGPoint(x: 430, y: 580), startRadius: 0,
        endCenter: CGPoint(x: 470, y: 520), endRadius: 420, options: [.drawsAfterEndLocation])
    ctx.addPath(shape)
    ctx.setStrokeColor(color(0x4FB3EA, 0.35))
    ctx.setLineWidth(22)  // half of it is clipped away, leaving an 11pt inner rim
    ctx.strokePath()
    ctx.restoreGState()
}

func drawDrip(_ ctx: CGContext) {
    let ink = color(0x1B2A4A)

    // Chubby arms raised in a happy stretch, drawn first so the body hides the joints.
    if !tiny {
        let arms = CGMutablePath()
        for side: CGFloat in [-1, 1] {
            let x = { (dx: CGFloat) in dropCenter.x + side * dx }
            arms.move(to: CGPoint(x: x(170), y: 480))
            arms.addCurve(to: CGPoint(x: x(282), y: 598),
                          control1: CGPoint(x: x(232), y: 498), control2: CGPoint(x: x(274), y: 545))
        }
        drawWater(ctx, arms.copy(strokingWithWidth: 64, lineCap: .round, lineJoin: .round, miterLimit: 10))
    }
    drawWater(ctx, dropletPath())

    // Gloss: a crescent along the upper-left edge and a little dot below it.
    let gloss = CGMutablePath()
    gloss.move(to: CGPoint(x: 345, y: 560))
    gloss.addCurve(to: CGPoint(x: 480, y: 775), control1: CGPoint(x: 342, y: 660), control2: CGPoint(x: 430, y: 735))
    gloss.addCurve(to: CGPoint(x: 345, y: 560), control1: CGPoint(x: 420, y: 690), control2: CGPoint(x: 388, y: 620))
    ctx.addPath(gloss)
    ctx.setFillColor(color(0xFFFFFF, 0.95))
    ctx.fillPath()
    if tiny { // tiny sizes: just a bold pair of eyes, everything else is noise
        for x in [dropCenter.x - 76, dropCenter.x + 76] { fillEllipse(ctx, cx: x, cy: 470, w: 74, h: 104, ink) }
        return
    }
    fillEllipse(ctx, cx: 340, cy: 515, w: 30, h: 30, color(0xFFFFFF, 0.95))

    // Rosy cheeks (soft radial blush squashed into ellipses).
    for x in [dropCenter.x - 136, dropCenter.x + 136] {
        ctx.saveGState()
        ctx.translateBy(x: x, y: 432)
        ctx.scaleBy(x: 1, y: 0.62)
        ctx.drawRadialGradient(gradient([(color(0xFF7FA8, 0.8), 0), (color(0xFF7FA8, 0), 1)]),
                               startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 50, options: [])
        ctx.restoreGState()
    }

    // Eyes with sparkly highlights.
    for x in [dropCenter.x - 72, dropCenter.x + 72] {
        fillEllipse(ctx, cx: x, cy: 488, w: 54, h: 76, ink)
        fillEllipse(ctx, cx: x - 9, cy: 507, w: 22, h: 22, color(0xFFFFFF))
        fillEllipse(ctx, cx: x + 10, cy: 469, w: 10, h: 10, color(0xFFFFFF))
    }

    // Big open smile with a pink tongue.
    let mouth = CGMutablePath()
    mouth.move(to: CGPoint(x: 470, y: 424))
    mouth.addCurve(to: CGPoint(x: 554, y: 424), control1: CGPoint(x: 474, y: 358), control2: CGPoint(x: 550, y: 358))
    mouth.addQuadCurve(to: CGPoint(x: 470, y: 424), control: CGPoint(x: 512, y: 436))
    ctx.saveGState()
    ctx.addPath(mouth)
    ctx.setFillColor(ink)
    ctx.fillPath()
    ctx.addPath(mouth)
    ctx.clip()
    fillEllipse(ctx, cx: 512, cy: 380, w: 52, h: 34, color(0xFF7A9C))
    ctx.restoreGState()
}

// MARK: - Icon

func drawIcon(_ ctx: CGContext) {
    let plate = squircle(CGRect(x: 100, y: 100, width: 824, height: 824), radius: 185)

    // Plate + drop shadow.
    ctx.saveGState()
    setShadow(ctx, dy: -12, blur: 28, color(0x000000, 0.35))
    ctx.addPath(plate)
    ctx.setFillColor(color(0x1565C0))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(plate)
    ctx.clip()

    // Ocean gradient, top to bottom.
    ctx.drawLinearGradient(
        gradient([(color(0x4FC3F7), 0), (color(0x2196F3), 0.55), (color(0x1565C0), 1)]),
        start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])

    // Soft glow behind Drip.
    ctx.drawRadialGradient(gradient([(color(0xFFFFFF, 0.32), 0), (color(0xFFFFFF, 0), 1)]),
                           startCenter: CGPoint(x: 512, y: 540), startRadius: 0,
                           endCenter: CGPoint(x: 512, y: 540), endRadius: 420, options: [])

    // Lighter aqua wave bands near the bottom (tinted, so they don't wash out to grey).
    ctx.addPath(wave(baseY: 290, amp: 22, length: 420, phase: 0))
    ctx.setFillColor(color(0x80DEFF, 0.28))
    ctx.fillPath()
    ctx.addPath(wave(baseY: 290, amp: 22, length: 420, phase: 0))
    ctx.setStrokeColor(color(0xFFFFFF, 0.35))
    ctx.setLineWidth(6)
    ctx.strokePath()
    ctx.addPath(wave(baseY: 215, amp: 18, length: 340, phase: 1.9))
    ctx.setFillColor(color(0x9BE7FF, 0.3))
    ctx.fillPath()

    // Bubbles (skipped at tiny sizes).
    for (x, y, r) in tiny ? [] : [(190.0, 400.0, 18.0), (840.0, 450.0, 24.0), (800.0, 345.0, 12.0)] {
        let rect = CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r)
        ctx.setFillColor(color(0xFFFFFF, 0.18))
        ctx.fillEllipse(in: rect)
        ctx.setStrokeColor(color(0xFFFFFF, 0.55))
        ctx.setLineWidth(5)
        ctx.strokeEllipse(in: rect)
    }

    // Twinkles.
    if !tiny {
        sparkle(ctx, x: 752, y: 800, size: 46)
        sparkle(ctx, x: 842, y: 735, size: 22, alpha: 0.85)
        sparkle(ctx, x: 262, y: 735, size: 28, alpha: 0.9)
    }

    drawDrip(ctx)
    ctx.restoreGState()
}

// MARK: - Rendering

func png(_ px: Int) -> Data {
    tiny = px <= 32
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!.retagging(with: .sRGB)!
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    g.cgContext.scaleBy(x: CGFloat(px) / S, y: CGFloat(px) / S)
    drawIcon(g.cgContext)
    g.flushGraphics()
    return rep.representation(using: .png, properties: [:])!
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: swift scripts/make-icon.swift <output-dir>\n".data(using: .utf8)!)
    exit(1)
}

let fm = FileManager.default
let out = URL(fileURLWithPath: CommandLine.arguments[1])
let tmp = fm.temporaryDirectory.appendingPathComponent("sipstretch-icon-\(UUID().uuidString)")
let iconset = tmp.appendingPathComponent("AppIcon.iconset")
try fm.createDirectory(at: out, withIntermediateDirectories: true)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try png(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try png(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try png(1024).write(to: out.appendingPathComponent("AppIcon-1024.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", out.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
try? fm.removeItem(at: tmp)

guard iconutil.terminationStatus == 0 else {
    FileHandle.standardError.write("iconutil failed with status \(iconutil.terminationStatus)\n".data(using: .utf8)!)
    exit(1)
}
print("Wrote \(out.path)/AppIcon.icns and \(out.path)/AppIcon-1024.png")
