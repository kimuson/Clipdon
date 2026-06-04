import AppKit
import CoreGraphics

// Renders the Clipdon app icon at a given pixel size and writes a PNG.
// Usage: make-icon <size> <output.png>
let args = CommandLine.arguments
let size = args.count > 1 ? (Int(args[1]) ?? 1024) : 1024
let outPath = args.count > 2 ? args[2] : "icon.png"
let s = CGFloat(size)

let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0, space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("context") }

ctx.setAllowsAntialiasing(true)
ctx.interpolationQuality = .high

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}
func rrect(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// MARK: - Rounded-square body (macOS-style)

let bodySide = s * 0.806
let body = CGRect(x: (s - bodySide) / 2, y: (s - bodySide) / 2, width: bodySide, height: bodySide)
let bodyRadius = bodySide * 0.2237

// Subtle drop shadow cast by the body.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -bodySide * 0.018),
              blur: bodySide * 0.05,
              color: rgb(0, 0, 0, 0.22))
ctx.addPath(rrect(body, bodyRadius))
ctx.setFillColor(rgb(1, 1, 1, 1))
ctx.fillPath()
ctx.restoreGState()

// Blue → indigo gradient, clipped to the rounded square.
ctx.saveGState()
ctx.addPath(rrect(body, bodyRadius))
ctx.clip()
let bg = CGGradient(colorsSpace: space,
                    colors: [rgb(0.31, 0.55, 1.0), rgb(0.227, 0.255, 0.784)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
// Soft highlight across the top.
let hl = CGGradient(colorsSpace: space,
                    colors: [rgb(1, 1, 1, 0.16), rgb(1, 1, 1, 0)] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(hl, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.midY), options: [])
ctx.restoreGState()

// MARK: - Clipboard + history stack

let boardW = bodySide * 0.42
let boardH = bodySide * 0.54
let boardR = boardW * 0.13
let board = CGRect(x: body.midX - boardW / 2 - bodySide * 0.03,
                   y: body.midY - boardH / 2 - bodySide * 0.015,
                   width: boardW, height: boardH)

// Two translucent sheets peeking out behind → "history".
func sheet(_ dx: CGFloat, _ dy: CGFloat, _ alpha: CGFloat) {
    ctx.addPath(rrect(board.offsetBy(dx: dx, dy: dy), boardR))
    ctx.setFillColor(rgb(1, 1, 1, alpha))
    ctx.fillPath()
}
sheet(bodySide * 0.065, bodySide * 0.065, 0.28)
sheet(bodySide * 0.032, bodySide * 0.032, 0.52)

// Main board.
ctx.addPath(rrect(board, boardR))
ctx.setFillColor(rgb(1, 1, 1, 1))
ctx.fillPath()

// Text lines on the board.
let lineColor = rgb(0.76, 0.80, 0.90)
let lineH = boardH * 0.058
let leftX = board.minX + boardW * 0.17
let fullW = boardW * 0.66
let topLineY = board.maxY - boardH * 0.34
let gap = boardH * 0.145
for (i, factor) in [1.0, 1.0, 0.62].enumerated() {
    let w = fullW * CGFloat(factor)
    let r = CGRect(x: leftX, y: topLineY - CGFloat(i) * gap, width: w, height: lineH)
    ctx.addPath(rrect(r, lineH / 2))
    ctx.setFillColor(lineColor)
    ctx.fillPath()
}

// Clip at the top of the board.
let clipW = boardW * 0.44
let clipH = boardH * 0.13
let clip = CGRect(x: board.midX - clipW / 2, y: board.maxY - clipH * 0.58, width: clipW, height: clipH)
ctx.addPath(rrect(clip, clipH * 0.45))
ctx.setFillColor(rgb(0.55, 0.59, 0.72))
ctx.fillPath()
// Hole in the clip.
let holeW = clipW * 0.30, holeH = clipH * 0.40
let hole = CGRect(x: clip.midX - holeW / 2, y: clip.midY - holeH / 2, width: holeW, height: holeH)
ctx.addPath(rrect(hole, holeH / 2))
ctx.setFillColor(rgb(1, 1, 1, 1))
ctx.fillPath()

// MARK: - Write PNG

guard let image = ctx.makeImage() else { fatalError("image") }
let rep = NSBitmapImageRep(cgImage: image)
rep.size = NSSize(width: size, height: size)
guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) (\(size)px)")
