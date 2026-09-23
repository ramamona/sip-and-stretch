import SwiftUI

/// A one-shot confetti burst drawn with Canvas. Deterministic per particle index, so it needs
/// no state beyond the start time.
struct ConfettiView: View {
    var start: Date
    var colors: [Color]
    var count = 70
    var duration: TimeInterval = 2.6

    /// Stop the frame clock once the burst is over, so an idle card costs nothing.
    @ViewState private var finished = false

    var body: some View {
        if !finished { burst.task {
            try? await Task.sleep(for: .seconds(max(0, duration - Date().timeIntervalSince(start))))
            finished = true
        } }
    }

    private var burst: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                let t = context.date.timeIntervalSince(start)
                guard t > 0.03, t < duration else { return } // nothing on the launch frame
                let fade = max(0, 1 - t / duration)
                for i in 0..<count {
                    var rng = SplitMix64(seed: UInt64(i + 1))
                    let x0 = size.width * (0.15 + 0.7 * rng.unit())
                    let vx = (rng.unit() - 0.5) * 320
                    let vy = -(160 + rng.unit() * 280)
                    let x = x0 + vx * t
                    let y = size.height * 0.6 + vy * t + 260 * t * t
                    let w = 5 + rng.unit() * 5
                    let h = 3 + rng.unit() * 4
                    let spin = rng.unit() * 12 - 6

                    var particle = canvas
                    particle.opacity = fade
                    particle.translateBy(x: x, y: y)
                    particle.rotate(by: .radians(rng.unit() * 6 + t * spin))
                    let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
                    let shape = i.isMultiple(of: 3) ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
                    particle.fill(shape, with: .color(colors[i % colors.count]))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Tiny deterministic RNG (SplitMix64) for reproducible particle layouts.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}
