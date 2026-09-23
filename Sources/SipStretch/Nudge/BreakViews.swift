import SwiftUI
import SipStretchCore

// The interactive middle of a break card. Each view gets the fixed card area (about 348×200 pt)
// and calls `done` when the break is complete.

/// Small caps label at the top of an activity ("BOX BREATHING").
private struct ActivityHeader: View {
    let text: String
    let theme: Theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text.uppercased())
            .font(.rounded(10.5, .heavy))
            .tracking(0.8)
            .foregroundStyle(theme.accent(for: colorScheme))
    }
}

// MARK: - Stretch roulette

/// A wheel of body areas spins and lands on today's pick, then hands over to the guided stretches.
struct RouletteView: View {
    let target: BodyArea
    let theme: Theme
    let done: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewState private var angle: Double = 0
    @ViewState private var landed = false

    private let areas = BodyArea.allCases

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(theme.light.opacity(0.18))
                Circle().strokeBorder(theme.gradient, lineWidth: 3)
                ForEach(Array(areas.enumerated()), id: \.element) { index, area in
                    Text(area.emoji)
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(-Double(index) * 360 / Double(areas.count) - angle)) // keep emoji upright
                        .offset(y: -44)
                        .rotationEffect(.degrees(Double(index) * 360 / Double(areas.count)))
                }
            }
            .frame(width: 128, height: 128)
            .rotationEffect(.degrees(angle))
            .overlay(alignment: .top) {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.deep)
                    .offset(y: -10)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                ActivityHeader(text: "Stretch roulette", theme: theme)
                Text(landed ? "\(target.emoji) \(target.displayName) it is!" : "Spinning…")
                    .font(.rounded(22, .bold))
                    .contentTransition(.opacity)
                Text(landed ? "A couple of \(target.displayName.lowercased()) stretches coming right up." : "Where will it land? 🥁")
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Let's go →", action: done)
                    .buttonStyle(.pill(.primary, theme: theme))
                    .disabled(!landed)
                    .opacity(landed ? 1 : 0.4)
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .task {
            // Land with the target under the pointer, after a few full turns.
            let index = Double(areas.firstIndex(of: target) ?? 0)
            let finalAngle = 360 * 4 - index * 360 / Double(areas.count)
            let duration = reduceMotion ? 0 : 2.4
            withAnimation(.timingCurve(0.15, 0.85, 0.25, 1, duration: duration)) { angle = finalAngle }
            try? await Task.sleep(for: .seconds(duration + 0.1))
            withAnimation { landed = true }
        }
    }
}

// MARK: - Box breathing

/// 4-4-4-4 box breathing with a circle that grows and shrinks with the breath.
struct BreathingView: View {
    let cycles: Int
    let theme: Theme
    let done: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewState private var step = -1 // counts 4-second phases; -1 = not started

    private static let phases = ["Breathe in", "Hold", "Breathe out", "Hold"]

    private var phaseName: String { step < 0 ? "Get comfy…" : Self.phases[step % 4] }
    private var expanded: Bool { step >= 0 && step % 4 < 2 }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().fill(theme.light.opacity(0.15))
                Circle()
                    .fill(RadialGradient(colors: [theme.light, theme.deep], center: .center, startRadius: 4, endRadius: 60))
                    .scaleEffect(expanded ? 1 : 0.5)
                    .opacity(reduceMotion ? 0.8 : 1)
                Text(phaseName)
                    .font(.rounded(12, .bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 124, height: 124)

            VStack(alignment: .leading, spacing: 8) {
                ActivityHeader(text: "Box breathing", theme: theme)
                Text(phaseName).font(.rounded(22, .bold)).contentTransition(.opacity)
                Text("In through the nose for 4, hold 4, out for 4, hold 4. Round \(max(1, step / 4 + 1)) of \(cycles).")
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("I'm done", action: done)
                    .buttonStyle(.pill(.quiet, theme: theme))
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(1))
            for next in 0..<(cycles * 4) {
                if Task.isCancelled { return }
                withAnimation(.easeInOut(duration: 4)) { step = next }
                try? await Task.sleep(for: .seconds(4))
            }
            if !Task.isCancelled { done() }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Mini challenge

/// Tap once per rep, or hold for a timed challenge.
struct ChallengeView: View {
    let challenge: Challenge
    let theme: Theme
    let done: () -> Void

    @ViewState private var count = 0
    @ViewState private var remaining = -1
    @ViewState private var timing = false

    private var progress: Double {
        challenge.isTimed
            ? 1 - Double(max(0, remaining)) / Double(max(1, challenge.seconds))
            : Double(count) / Double(max(1, challenge.reps))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ActivityHeader(text: "Mini challenge", theme: theme)
            HStack(spacing: 14) {
                Text(challenge.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.name).font(.rounded(19, .bold))
                    Text(challenge.tip)
                        .font(.rounded(12.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if challenge.isTimed {
                    ProgressRing(progress: progress, theme: theme, lineWidth: 5) {
                        Text(remaining < 0 ? "\(challenge.seconds)" : "\(remaining)")
                            .font(.rounded(17, .bold))
                            .monospacedDigit()
                    }
                    .frame(width: 54, height: 54)
                    .padding(.trailing, 14)
                }
            }
            Spacer(minLength: 0)
            HStack {
                Button("I'm done", action: done)
                    .buttonStyle(.pill(.quiet, theme: theme))
                Spacer()
                if challenge.isTimed {
                    if remaining < 0 {
                        Button("⏱ Start") { timing = true }
                            .buttonStyle(.pill(.primary, theme: theme))
                    }
                } else {
                    // One big tap target per rep: satisfying, and it keeps count for you.
                    Button {
                        count += 1
                        if count >= challenge.reps { done() }
                    } label: {
                        Text("Rep \(min(count + 1, challenge.reps)) of \(challenge.reps)  ✅")
                            .monospacedDigit()
                    }
                    .buttonStyle(.pill(.primary, theme: theme))
                    .accessibilityLabel("Count a rep. \(count) of \(challenge.reps) done")
                }
            }
        }
        .task(id: timing) { await runTimer() }
    }

    /// Tied to the view's lifetime, so closing the card stops the timer (and awards nothing).
    private func runTimer() async {
        guard timing else { return }
        remaining = challenge.seconds
        while remaining > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            withAnimation { remaining -= 1 }
        }
        done()
    }
}

// MARK: - Posture check

/// Tick off each item as you fix it; all ticked = done.
struct PostureCheckView: View {
    let items: [String]
    let theme: Theme
    let done: () -> Void

    @ViewState private var checked: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ActivityHeader(text: "Posture check · \(checked.count)/\(items.count)", theme: theme)
            ForEach(items, id: \.self) { item in
                let on = checked.contains(item)
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        if on { checked.remove(item) } else { checked.insert(item) }
                    }
                    if checked.count == items.count { done() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: on ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(on ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.secondary))
                            .font(.system(size: 15))
                        Text(item)
                            .font(.rounded(13, on ? .semibold : .regular))
                            .strikethrough(on, color: .secondary)
                            .foregroundStyle(on ? .secondary : .primary)
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button("All good ✓", action: done)
                    .buttonStyle(.pill(.primary, theme: theme))
            }
        }
    }
}

// MARK: - Eye rest

/// 20 seconds looking far away. The card counts down and nudges you to blink halfway.
struct EyeRestView: View {
    let seconds: Int
    let tip: String
    let theme: Theme
    let done: () -> Void

    @ViewState private var remaining: Int

    init(seconds: Int, tip: String, theme: Theme, done: @escaping () -> Void) {
        self.seconds = seconds
        self.tip = tip
        self.theme = theme
        self.done = done
        _remaining = ViewState(wrappedValue: seconds)
    }

    var body: some View {
        HStack(spacing: 18) {
            ProgressRing(progress: 1 - Double(remaining) / Double(max(1, seconds)), theme: theme, lineWidth: 6) {
                VStack(spacing: 0) {
                    Text(remaining == seconds / 2 ? "😌" : "👀").font(.system(size: 30))
                    Text("\(remaining)")
                        .font(.rounded(16, .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            .frame(width: 104, height: 104)

            VStack(alignment: .leading, spacing: 8) {
                ActivityHeader(text: "Eye break · 20-20-20", theme: theme)
                Text(remaining <= seconds / 2 ? "Now blink slowly…" : "Look far away")
                    .font(.rounded(21, .bold))
                    .contentTransition(.opacity)
                Text(tip)
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .task {
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                withAnimation { remaining -= 1 }
            }
            done()
        }
    }
}
