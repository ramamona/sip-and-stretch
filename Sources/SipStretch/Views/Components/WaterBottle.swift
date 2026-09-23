import SwiftUI
import SipStretchCore

/// A little bottle that fills up (with a sloshing wave) as you log glasses.
struct WaterBottle: View {
    var progress: Double
    var marks: Int
    var theme: Theme
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let live = animated && !reduceMotion
        VStack(spacing: 1.5) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(theme.deep)
                .frame(width: 26, height: 8)
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !live)) { context in
                let phase = live ? context.date.timeIntervalSinceReferenceDate * 2.4 : 1
                ZStack {
                    BottleShape().fill(Color.primary.opacity(0.05))
                    WaveShape(level: min(1, progress) * 0.86, phase: phase)
                        .fill(LinearGradient(colors: [theme.light, theme.deep], startPoint: .top, endPoint: .bottom))
                        .clipShape(BottleShape())
                        .animation(.spring(response: 0.6, dampingFraction: 0.65), value: progress)
                    ticks
                    Capsule()
                        .fill(.white.opacity(0.45))
                        .frame(width: 5, height: 36)
                        .offset(x: -16, y: 6)
                    BottleShape().stroke(theme.deep.opacity(0.55), lineWidth: 2)
                    if progress >= 1 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: theme.deep, radius: 2)
                            .offset(y: 10)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Water today")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent of goal")
    }

    /// One notch per glass (skipped when the goal is too big to read).
    private var ticks: some View {
        GeometryReader { geo in
            if marks > 1 && marks <= 12 {
                ForEach(1..<marks, id: \.self) { i in
                    let y = geo.size.height * (1 - 0.86 * CGFloat(i) / CGFloat(marks))
                    Capsule()
                        .fill(theme.deep.opacity(0.35))
                        .frame(width: 7, height: 1.5)
                        .position(x: geo.size.width - 8, y: y)
                }
            }
        }
    }
}

struct BottleShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        let neckW = w * 0.46, neckH = h * 0.1, shoulder = h * 0.24, radius = w * 0.22
        let nl = r.midX - neckW / 2, nr = r.midX + neckW / 2
        var p = Path()
        p.move(to: CGPoint(x: nl, y: r.minY))
        p.addLine(to: CGPoint(x: nr, y: r.minY))
        p.addLine(to: CGPoint(x: nr, y: r.minY + neckH))
        p.addCurve(
            to: CGPoint(x: r.maxX, y: r.minY + shoulder),
            control1: CGPoint(x: nr, y: r.minY + neckH + (shoulder - neckH) * 0.6),
            control2: CGPoint(x: r.maxX, y: r.minY + neckH + (shoulder - neckH) * 0.2)
        )
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        p.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius), control: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + shoulder))
        p.addCurve(
            to: CGPoint(x: nl, y: r.minY + neckH),
            control1: CGPoint(x: r.minX, y: r.minY + neckH + (shoulder - neckH) * 0.2),
            control2: CGPoint(x: nl, y: r.minY + neckH + (shoulder - neckH) * 0.6)
        )
        p.closeSubpath()
        return p
    }
}

struct WaveShape: Shape {
    var level: Double
    var phase: Double
    var amplitude: CGFloat = 2.5

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in r: CGRect) -> Path {
        let clamped = min(max(level, 0), 1)
        let surface = r.maxY - r.height * CGFloat(clamped)
        let wobble = clamped > 0 && clamped < 1 ? amplitude : 0
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        for x in stride(from: r.minX, through: r.maxX, by: 2) {
            let rel = Double((x - r.minX) / r.width)
            p.addLine(to: CGPoint(x: x, y: surface + CGFloat(sin(rel * .pi * 2.4 + phase)) * wobble))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
