import SwiftUI
import SipStretchCore

enum DripMood: String, CaseIterable {
    case happy, excited, sleepy, thirsty, stretching
}

/// Drip, the app's mascot: a water droplet whose face and body language follow its mood.
/// Everything is vector-drawn and driven by a single time value, so it animates smoothly
/// and renders the same in snapshots (with `animated: false`).
struct DripView: View {
    var mood: DripMood = .happy
    var theme: Theme = .ocean
    var size: CGFloat = 64
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let live = animated && !reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !live)) { context in
            DripFigure(mood: mood, theme: theme, time: live ? context.date.timeIntervalSinceReferenceDate : 0.6)
        }
        .frame(width: size, height: size * 1.18)
        .accessibilityElement()
        .accessibilityLabel("Drip the water droplet, feeling \(mood.rawValue)")
    }
}

/// Classic teardrop: pointed top, round bottom (bottom radius = half the width).
struct DropletShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width
        let radius = w / 2
        let cy = r.maxY - radius
        let k: CGFloat = 0.5523 // circle-by-Bézier constant
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(
            to: CGPoint(x: r.maxX, y: cy),
            control1: CGPoint(x: r.midX + w * 0.08, y: r.minY + (cy - r.minY) * 0.35),
            control2: CGPoint(x: r.maxX, y: cy - radius * 0.75)
        )
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY), control1: CGPoint(x: r.maxX, y: cy + radius * k), control2: CGPoint(x: r.midX + radius * k, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: cy), control1: CGPoint(x: r.midX - radius * k, y: r.maxY), control2: CGPoint(x: r.minX, y: cy + radius * k))
        p.addCurve(
            to: CGPoint(x: r.midX, y: r.minY),
            control1: CGPoint(x: r.minX, y: cy - radius * 0.75),
            control2: CGPoint(x: r.midX - w * 0.08, y: r.minY + (cy - r.minY) * 0.35)
        )
        p.closeSubpath()
        return p
    }
}

private struct Motion {
    var offsetY: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var tilt: Double = 0
    var armLift: Double = 0 // 0…1, only used while stretching

    init(mood: DripMood, t: Double, w: CGFloat) {
        switch mood {
        case .happy:
            offsetY = CGFloat(sin(t * 2.2)) * w * 0.025
        case .excited:
            offsetY = -CGFloat(abs(sin(t * 5))) * w * 0.09
            scaleY = 1 + CGFloat(sin(t * 10)) * 0.025
        case .sleepy:
            scaleY = 1 + CGFloat(sin(t * 1.3)) * 0.02
            scaleX = 1 - CGFloat(sin(t * 1.3)) * 0.01
            tilt = 7
        case .thirsty:
            scaleY = 0.93 + CGFloat(sin(t * 1.6)) * 0.012
            scaleX = 1.03
            tilt = -3
        case .stretching:
            let s = sin(t * 2.6)
            scaleY = 1 + CGFloat(s) * 0.09
            scaleX = 1 - CGFloat(s) * 0.055
            armLift = (s + 1) / 2
        }
    }
}

private struct DripFigure: View {
    let mood: DripMood
    let theme: Theme
    let time: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height * 0.92
            let motion = Motion(mood: mood, t: time, w: w)
            ZStack {
                Ellipse()
                    .fill(.black.opacity(0.13))
                    .frame(width: w * 0.62 * (1 + motion.offsetY / w), height: w * 0.07)
                    .position(x: w / 2, y: geo.size.height - w * 0.04)

                ZStack {
                    if mood == .stretching { arms(w: w, h: h, lift: motion.armLift) }
                    DropletShape()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.9), theme.light, theme.deep], startPoint: .top, endPoint: .bottom))
                    DropletShape()
                        .fill(LinearGradient(colors: [theme.light.opacity(0.0), theme.light.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                        .blendMode(.plusLighter)
                    DropletShape().stroke(.white.opacity(0.55), lineWidth: max(1, w * 0.018))
                    Ellipse()
                        .fill(.white.opacity(0.6))
                        .frame(width: w * 0.13, height: w * 0.22)
                        .rotationEffect(.degrees(28))
                        .position(x: w * 0.3, y: h * 0.5)
                    Circle()
                        .fill(.white.opacity(0.75))
                        .frame(width: w * 0.06)
                        .position(x: w * 0.37, y: h * 0.36)
                    DripFace(mood: mood, time: time, w: w, cy: h - w / 2)
                }
                .frame(width: w, height: h)
                .scaleEffect(x: motion.scaleX, y: motion.scaleY, anchor: .bottom)
                .rotationEffect(.degrees(motion.tilt), anchor: .bottom)
                .offset(y: motion.offsetY)

                extras(w: w, h: h)
            }
        }
    }

    private func arms(w: CGFloat, h: CGFloat, lift: Double) -> some View {
        let cy = h - w / 2
        return ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule()
                    .fill(theme.light)
                    .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: max(1, w * 0.015)))
                    .frame(width: w * 0.12, height: w * 0.34)
                    .rotationEffect(.degrees(side * (35 + 25 * lift)), anchor: .bottom)
                    .position(x: w / 2 + CGFloat(side) * w * 0.43, y: cy - w * 0.2)
            }
        }
    }

    @ViewBuilder
    private func extras(w: CGFloat, h: CGFloat) -> some View {
        switch mood {
        case .sleepy:
            ForEach(0..<3) { i in
                let phase = (time * 0.45 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                Text("z")
                    .font(.rounded(w * (0.13 + 0.05 * CGFloat(i)), .bold))
                    .foregroundStyle(theme.deep.opacity(0.8 * (1 - phase)))
                    .position(x: w * (0.8 + 0.08 * CGFloat(phase)), y: h * (0.35 - 0.3 * CGFloat(phase)))
            }
        case .excited:
            ForEach(0..<4) { i in
                let angle = time * 1.4 + Double(i) * .pi / 2
                let twinkle = 0.6 + 0.4 * sin(time * 6 + Double(i))
                Image(systemName: "sparkle")
                    .font(.system(size: w * 0.14, weight: .bold))
                    .foregroundStyle(i.isMultiple(of: 2) ? Color.yellow : theme.light)
                    .scaleEffect(twinkle)
                    .position(x: w / 2 + CGFloat(cos(angle)) * w * 0.62, y: h * 0.55 + CGFloat(sin(angle)) * h * 0.45)
            }
        case .thirsty:
            DropletShape()
                .fill(theme.light.opacity(0.85))
                .overlay(DropletShape().stroke(.white.opacity(0.7), lineWidth: 1))
                .frame(width: w * 0.1, height: w * 0.14)
                .position(x: w * 0.86, y: h * 0.42 + CGFloat(sin(time * 3)) * w * 0.03)
        default:
            EmptyView()
        }
    }
}

private struct DripFace: View {
    let mood: DripMood
    let time: Double
    let w: CGFloat
    let cy: CGFloat // centre of the round part of the droplet

    var body: some View {
        let eyeY = cy - w * 0.07
        let blinking = time.truncatingRemainder(dividingBy: 4.2) > 4.05
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                let x = w / 2 + CGFloat(side) * w * 0.15
                eye(blinking: blinking).position(x: x, y: eyeY)
                Ellipse()
                    .fill(Color.cheek.opacity(mood == .sleepy ? 0.25 : 0.45))
                    .frame(width: w * 0.12, height: w * 0.07)
                    .position(x: w / 2 + CGFloat(side) * w * 0.27, y: cy + w * 0.04)
            }
            mouth.position(x: w / 2, y: cy + w * 0.11)
        }
    }

    @ViewBuilder
    private func eye(blinking: Bool) -> some View {
        switch mood {
        case .sleepy:
            Arc(up: false).stroke(Color.dripInk, style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
                .frame(width: w * 0.11, height: w * 0.05)
        case .excited:
            Arc(up: true).stroke(Color.dripInk, style: StrokeStyle(lineWidth: w * 0.035, lineCap: .round))
                .frame(width: w * 0.11, height: w * 0.06)
        default:
            Ellipse()
                .fill(Color.dripInk)
                .frame(width: w * 0.085, height: w * 0.12)
                .overlay(alignment: .topTrailing) {
                    Circle().fill(.white).frame(width: w * 0.035).offset(x: -w * 0.008, y: w * 0.015)
                }
                .scaleEffect(y: blinking ? 0.1 : 1)
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .happy:
            Arc(up: false).stroke(Color.dripInk, style: StrokeStyle(lineWidth: w * 0.03, lineCap: .round))
                .frame(width: w * 0.16, height: w * 0.07)
        case .excited:
            HalfDisc()
                .fill(Color.dripInk)
                .overlay(alignment: .bottom) { Ellipse().fill(Color.cheek).frame(width: w * 0.09, height: w * 0.045).offset(y: -w * 0.012) }
                .clipShape(HalfDisc())
                .frame(width: w * 0.2, height: w * 0.11)
        case .sleepy:
            Ellipse().fill(Color.dripInk.opacity(0.8)).frame(width: w * 0.05, height: w * 0.035 + CGFloat(sin(time * 1.3) + 1) * w * 0.01)
        case .thirsty:
            Wave().stroke(Color.dripInk, style: StrokeStyle(lineWidth: w * 0.028, lineCap: .round, lineJoin: .round))
                .frame(width: w * 0.18, height: w * 0.04)
        case .stretching:
            Ellipse().fill(Color.dripInk).frame(width: w * 0.08, height: w * 0.07)
        }
    }
}

/// A shallow arc: `up: false` is a smile (∪), `up: true` a happy closed eye (∩).
private struct Arc: Shape {
    var up: Bool
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: up ? r.maxY : r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: up ? r.maxY : r.minY), control: CGPoint(x: r.midX, y: up ? r.minY - r.height : r.maxY + r.height))
        return p
    }
}

private struct HalfDisc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + r.height))
        p.closeSubpath()
        return p
    }
}

private struct Wave: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        let step = r.width / 4
        for i in 0..<4 {
            p.addQuadCurve(
                to: CGPoint(x: r.minX + step * CGFloat(i + 1), y: r.midY),
                control: CGPoint(x: r.minX + step * (CGFloat(i) + 0.5), y: i.isMultiple(of: 2) ? r.minY : r.maxY)
            )
        }
        return p
    }
}
