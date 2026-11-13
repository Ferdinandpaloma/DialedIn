import SwiftUI

/// The hero element: brushed-metal ring, dark glass face, 270° gradient arc, knob at the set-point.
struct DialView: View {
    var setPoint: Int
    var waterTemp: Double
    var cap: Int
    var status: ShowerStatus
    var units: TemperatureUnit = .fahrenheit
    /// When set, the dial is draggable. Receives the temperature under the finger (may exceed the cap).
    var onDrag: ((Int) -> Void)? = nil

    static let scaleMin = Double(ShowerController.minSetPoint)
    static let scaleMax = Double(ShowerController.scaleMax)
    static let sweep = 270.0
    static let startAngle = 135.0

    private var isRunning: Bool { status.isRunning }
    private var isReady: Bool { status == .ready }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                metalRing(size)
                face(size)
                arc(size)
                capTick(size)
                knob(size)
                readout(size)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(dragGesture(size), including: onDrag == nil ? .none : .all)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shower dial")
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        if isRunning {
            "Water \(units.spoken(waterTemp)). Set to \(units.spoken(setPoint)). \(status.spokenLabel). Safety cap \(units.spoken(cap))."
        } else {
            "Set to \(units.spoken(setPoint)). Off. Safety cap \(units.spoken(cap))."
        }
    }

    // MARK: Geometry

    static func fraction(for temp: Double) -> Double {
        min(max((temp - scaleMin) / (scaleMax - scaleMin), 0), 1)
    }

    private func point(fraction: Double, radius: CGFloat, size: CGFloat) -> CGPoint {
        let angle = Angle.degrees(Self.startAngle + Self.sweep * fraction).radians
        return CGPoint(x: size / 2 + radius * cos(angle), y: size / 2 + radius * sin(angle))
    }

    private var arcFraction: Double {
        Self.fraction(for: isRunning ? waterTemp : Double(setPoint))
    }

    // MARK: Layers

    /// Satin (not mirror) metal: a narrow tonal range so the ring doesn't glare.
    private static let metalColors: [Color] = [
        Color(white: 0.90), Color(white: 0.78), Color(white: 0.92), Color(white: 0.76),
        Color(white: 0.89), Color(white: 0.80), Color(white: 0.90),
    ]

    private func metalRing(_ s: CGFloat) -> some View {
        let shadowColor: Color = isReady ? Theme.green.opacity(0.35) : Theme.navy.opacity(0.12)
        let shadowRadius: CGFloat = isReady ? s * 0.06 : s * 0.04
        let shadowY: CGFloat = isReady ? 0 : s * 0.015
        let vignette = RadialGradient(colors: [Color.clear, Color.black.opacity(0.10)],
                                      center: .center, startRadius: s * 0.40, endRadius: s * 0.5)
        return Circle()
            .fill(AngularGradient(colors: Self.metalColors, center: .center))
            .overlay(Circle().fill(vignette))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
            .animation(.easeInOut(duration: 0.6), value: isReady)
    }

    private static let faceColors: [Color] = [Color(hex: 0x1F3D54), Color(hex: 0x0B1C29), Color(hex: 0x040B11)]
    private static let glassColors: [Color] = [Color.white.opacity(0.07), Color.clear]

    private func face(_ s: CGFloat) -> some View {
        let fill = RadialGradient(colors: Self.faceColors, center: UnitPoint(x: 0.42, y: 0.3),
                                  startRadius: 0, endRadius: s * 0.48)
        let glass = LinearGradient(colors: Self.glassColors, startPoint: .top, endPoint: .bottom)
        let rimColor: Color = isReady ? Theme.green.opacity(0.85) : Color.black.opacity(0.4)
        let rimWidth: CGFloat = isReady ? s * 0.009 : 1.5
        let highlight = Ellipse()
            .fill(glass)
            .frame(width: s * 0.66, height: s * 0.34)
            .offset(y: -s * 0.2)
        return Circle()
            .fill(fill)
            .overlay(highlight)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(rimColor, lineWidth: rimWidth))
            .frame(width: s * 0.86, height: s * 0.86)
            .animation(.easeInOut(duration: 0.5), value: isReady)
    }

    private func arc(_ s: CGFloat) -> some View {
        let diameter = s * 0.72
        let width = s * 0.045
        let gradient = AngularGradient(
            gradient: Gradient(stops: [
                .init(color: Theme.blue, location: 0),
                .init(color: Theme.yellow, location: 0.42),
                .init(color: Theme.orange, location: 0.75),
                .init(color: Theme.orange, location: 0.85),
                .init(color: Theme.blue, location: 0.95),
            ]),
            center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
        return ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: width, lineCap: .round))
            Circle()
                .trim(from: 0, to: 0.75 * arcFraction)
                .stroke(gradient, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .opacity(isRunning ? 1 : 0.6)
                .animation(.easeOut(duration: 0.25), value: arcFraction)
        }
        .frame(width: diameter, height: diameter)
        .rotationEffect(.degrees(Self.startAngle))
    }

    private func capTick(_ s: CGFloat) -> some View {
        let f = Self.fraction(for: Double(cap))
        let p = point(fraction: f, radius: s * 0.36, size: s)
        return Capsule()
            .fill(Theme.red)
            .frame(width: s * 0.014, height: s * 0.075)
            .rotationEffect(.degrees(Self.startAngle + Self.sweep * f - 90))
            .position(p)
    }

    private func knob(_ s: CGFloat) -> some View {
        let p = point(fraction: Self.fraction(for: Double(setPoint)), radius: s * 0.36, size: s)
        return Circle()
            .fill(.white)
            .frame(width: s * 0.078, height: s * 0.078)
            .overlay(Circle().fill(Theme.orange).frame(width: s * 0.026, height: s * 0.026))
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            .position(p)
            .animation(.snappy(duration: 0.2), value: setPoint)
    }

    private func readout(_ s: CGFloat) -> some View {
        let main = isRunning ? waterTemp : Double(setPoint)
        let mainText = units.number(main)
        return VStack(spacing: s * 0.008) {
            Text("MAX \(units.short(cap))")
                .font(.system(size: s * 0.052, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color.white.opacity(0.75))
            HStack(alignment: .top, spacing: 2) {
                Text(mainText)
                    .font(.system(size: max(72, s * 0.27), weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: main))
                    .animation(.snappy, value: mainText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(units.symbol)
                    .font(.system(size: s * 0.07, weight: .regular, design: .rounded))
                    .padding(.top, s * 0.05)
            }
            .foregroundStyle(.white)
            Text(isRunning ? "SET \(units.short(setPoint))" : "WATER \(units.short(waterTemp))")
                .font(.system(size: s * 0.052, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.75))
            Text(status.label)
                .font(.system(size: s * 0.062, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(statusColor)
                .padding(.top, s * 0.01)
        }
        .frame(width: s * 0.6)
    }

    private var statusColor: Color {
        switch status {
        case .off: Theme.offGray
        case .warming: Theme.orange
        case .ready: Theme.green
        case .correcting: Theme.yellow
        }
    }

    // MARK: Interaction

    private func dragGesture(_ s: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let dx = value.location.x - s / 2
                let dy = value.location.y - s / 2
                guard hypot(dx, dy) > s * 0.18 else { return }
                let degrees = atan2(dy, dx) * 180 / .pi
                var relative = degrees - Self.startAngle
                while relative < 0 { relative += 360 }
                if relative > Self.sweep {
                    // In the gap at the bottom: snap to the nearest end.
                    relative = relative > Self.sweep + 45 ? 0 : Self.sweep
                }
                let temp = Self.scaleMin + relative / Self.sweep * (Self.scaleMax - Self.scaleMin)
                onDrag?(Int(temp.rounded()))
            }
    }
}

/// Small static dial used in the logo and device rows.
struct DialGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(AngularGradient(colors: [Color(white: 0.95), Color(white: 0.6), Color(white: 0.95),
                                                       Color(white: 0.6), Color(white: 0.95)], center: .center))
                Circle().fill(Theme.navy).frame(width: s * 0.78, height: s * 0.78)
                Circle()
                    .trim(from: 0, to: 0.55)
                    .stroke(AngularGradient(colors: [Theme.blue, Theme.yellow, Theme.orange], center: .center,
                                            startAngle: .degrees(0), endAngle: .degrees(200)),
                            style: StrokeStyle(lineWidth: s * 0.1, lineCap: .round))
                    .frame(width: s * 0.54, height: s * 0.54)
                    .rotationEffect(.degrees(135))
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 24) {
        DialView(setPoint: 102, waterTemp: 68, cap: 110, status: .off)
        DialView(setPoint: 102, waterTemp: 102, cap: 110, status: .ready)
    }
    .padding()
}
