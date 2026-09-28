// Renders the KeepAwake app icon (a steaming coffee cup) into an .iconset directory.
// Usage: make-icon <output.iconset>, then `iconutil -c icns <output.iconset>`.
// Drawn with Core Graphics only (works headless in CI). Deliberately not an SF Symbol:
// the SF Symbols license forbids using symbols in app icons.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let canvas: CGFloat = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

func makeContext(_ size: Int) -> CGContext {
    CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
              space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

/// Draws the master artwork on a 1024pt canvas (Core Graphics origin is bottom-left).
func drawIcon(_ ctx: CGContext) {
    // macOS icon grid: 824pt body centered on the 1024 canvas, ~185pt corner radius.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: rgb(0, 0, 0, 0.35))
    ctx.addPath(bodyPath)
    ctx.setFillColor(rgb(0.85, 0.45, 0.2))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let background = CGGradient(colorsSpace: space,
                                colors: [rgb(1.0, 0.78, 0.42), rgb(0.86, 0.43, 0.19)] as CFArray,
                                locations: [0, 1])!
    ctx.drawLinearGradient(background, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    ctx.restoreGState()

    let cream = rgb(1.0, 0.98, 0.95)
    let shade = rgb(0.93, 0.87, 0.8)
    let coffee = rgb(0.4, 0.22, 0.12)

    // Steam: three soft S-curves rising from the cup.
    ctx.saveGState()
    ctx.setStrokeColor(rgb(1, 1, 1, 0.9))
    ctx.setLineWidth(30)
    ctx.setLineCap(.round)
    for x: CGFloat in [410, 490, 570] {
        let steam = CGMutablePath()
        steam.move(to: CGPoint(x: x, y: 640))
        steam.addCurve(to: CGPoint(x: x, y: 760), control1: CGPoint(x: x - 45, y: 680), control2: CGPoint(x: x + 45, y: 720))
        steam.addCurve(to: CGPoint(x: x, y: 820), control1: CGPoint(x: x - 25, y: 780), control2: CGPoint(x: x - 10, y: 805))
        ctx.addPath(steam)
    }
    ctx.strokePath()
    ctx.restoreGState()

    // Saucer: shaded underside, then the top face.
    ctx.setFillColor(shade)
    ctx.fillEllipse(in: CGRect(x: 230, y: 262, width: 540, height: 96))
    ctx.setFillColor(cream)
    ctx.fillEllipse(in: CGRect(x: 230, y: 282, width: 540, height: 90))

    // Handle: a thick ring on the right side of the cup.
    ctx.setStrokeColor(cream)
    ctx.setLineWidth(38)
    ctx.strokeEllipse(in: CGRect(x: 600, y: 410, width: 130, height: 130))

    // Cup body: straight-sided top tapering into a rounded bottom.
    let cup = CGMutablePath()
    cup.move(to: CGPoint(x: 300, y: 580))
    cup.addLine(to: CGPoint(x: 660, y: 580))
    cup.addCurve(to: CGPoint(x: 540, y: 330), control1: CGPoint(x: 660, y: 430), control2: CGPoint(x: 620, y: 345))
    cup.addLine(to: CGPoint(x: 420, y: 330))
    cup.addCurve(to: CGPoint(x: 300, y: 580), control1: CGPoint(x: 340, y: 345), control2: CGPoint(x: 300, y: 430))
    cup.closeSubpath()
    ctx.addPath(cup)
    ctx.setFillColor(cream)
    ctx.fillPath()

    // Rim and coffee surface.
    ctx.setFillColor(shade)
    ctx.fillEllipse(in: CGRect(x: 300, y: 550, width: 360, height: 64))
    ctx.setFillColor(coffee)
    ctx.fillEllipse(in: CGRect(x: 322, y: 558, width: 316, height: 48))
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("failed to write \(url.path)") }
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon <output.iconset>\n".data(using: .utf8)!)
    exit(2)
}
let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

let master = makeContext(Int(canvas))
drawIcon(master)
let masterImage = master.makeImage()!

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let ctx = makeContext(pixels)
        ctx.interpolationQuality = .high
        ctx.draw(masterImage, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        writePNG(ctx.makeImage()!, to: out.appendingPathComponent(name))
    }
}
