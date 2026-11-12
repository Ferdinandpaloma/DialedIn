// Renders the ONDO app icon: swift scripts/make-icon.swift Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
import AppKit

let size = 1024
let out = CommandLine.arguments.dropFirst().first ?? "AppIcon.png"
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}
func lerp(_ a: UInt32, _ b: UInt32, _ t: CGFloat) -> CGColor {
    func c(_ h: UInt32, _ s: UInt32) -> CGFloat { CGFloat((h >> s) & 0xFF) / 255 }
    return CGColor(srgbRed: c(a,16) + (c(b,16)-c(a,16))*t, green: c(a,8) + (c(b,8)-c(a,8))*t,
                   blue: c(a,0) + (c(b,0)-c(a,0))*t, alpha: 1)
}
let s = CGFloat(size), mid = s / 2
ctx.setFillColor(rgb(0x0F2A3D)); ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

// Brushed-metal ring: thin wedges in alternating grays.
let ringR = s * 0.40
for i in 0..<360 {
    let a0 = CGFloat(i) * .pi / 180, a1 = CGFloat(i + 1) * .pi / 180 + 0.01
    let g = 0.62 + 0.33 * abs(cos(CGFloat(i) * .pi / 90))
    ctx.setFillColor(CGColor(gray: g, alpha: 1))
    ctx.move(to: CGPoint(x: mid, y: mid))
    ctx.addArc(center: CGPoint(x: mid, y: mid), radius: ringR, startAngle: a0, endAngle: a1, clockwise: false)
    ctx.fillPath()
}
// Dark face.
ctx.setFillColor(rgb(0x081722))
ctx.fillEllipse(in: CGRect(x: mid - ringR * 0.86, y: mid - ringR * 0.86, width: ringR * 1.72, height: ringR * 1.72))

// 270° gradient arc (CG y-up: start at bottom-left 225°, go clockwise).
let arcR = ringR * 0.68, lw = s * 0.05
let steps = 200, filled = 0.78
for i in 0..<Int(Double(steps) * filled) {
    let t = CGFloat(i) / CGFloat(steps)
    let color = t < 0.5 ? lerp(0x2A78D6, 0xF2C230, t / 0.5) : lerp(0xF2C230, 0xEB6834, (t - 0.5) / 0.5)
    let a0 = (225 - 270 * t) * .pi / 180
    let a1 = (225 - 270 * (t + 1 / CGFloat(steps)) - 0.6) * .pi / 180
    ctx.setStrokeColor(color); ctx.setLineWidth(lw); ctx.setLineCap(i == 0 ? .round : .butt)
    ctx.addArc(center: CGPoint(x: mid, y: mid), radius: arcR, startAngle: a0, endAngle: a1, clockwise: true)
    ctx.strokePath()
}
// Knob.
let ka = (225 - 270 * CGFloat(filled)) * .pi / 180
let kp = CGPoint(x: mid + arcR * cos(ka), y: mid + arcR * sin(ka))
ctx.setFillColor(CGColor(gray: 1, alpha: 1))
ctx.fillEllipse(in: CGRect(x: kp.x - s * 0.04, y: kp.y - s * 0.04, width: s * 0.08, height: s * 0.08))
ctx.setFillColor(rgb(0xEB6834))
ctx.fillEllipse(in: CGRect(x: kp.x - s * 0.014, y: kp.y - s * 0.014, width: s * 0.028, height: s * 0.028))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
