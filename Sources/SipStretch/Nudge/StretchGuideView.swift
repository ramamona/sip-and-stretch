import AppKit
import SwiftUI
import SipStretchCore

/// One guided stretch with a countdown ring. Auto-advances when the timer runs out.
struct StretchGuideView: View {
    let stretches: [Stretch]
    let index: Int
    let theme: Theme
    let advance: () -> Void
    let finish: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @ViewState private var remaining: Int = 0

    init(stretches: [Stretch], index: Int, theme: Theme, advance: @escaping () -> Void, finish: @escaping () -> Void) {
        self.stretches = stretches
        self.index = index
        self.theme = theme
        self.advance = advance
        self.finish = finish
        _remaining = ViewState(wrappedValue: stretches[index].seconds)
    }

    private var stretch: Stretch { stretches[index] }
    private var isLast: Bool { index + 1 >= stretches.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("STRETCH \(index + 1) OF \(stretches.count)")
                    .font(.rounded(10.5, .heavy))
                    .tracking(0.8)
                    .foregroundStyle(theme.accent(for: colorScheme))
                HStack(spacing: 4) {
                    ForEach(stretches.indices, id: \.self) { i in
                        Capsule()
                            .fill(i <= index ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.primary.opacity(0.12)))
                            .frame(width: i == index ? 16 : 6, height: 6)
                    }
                }
            }
            HStack(spacing: 12) {
                Text(stretch.emoji).font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text(stretch.name)
                        .font(.rounded(19, .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("\(stretch.area.emoji) \(stretch.area.displayName)")
                        .font(.rounded(12, .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                ProgressRing(progress: 1 - Double(remaining) / Double(max(1, stretch.seconds)), theme: theme, lineWidth: 5) {
                    Text("\(remaining)")
                        .font(.rounded(17, .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                .frame(width: 50, height: 50)
                .padding(.trailing, 14)
            }
            Text(stretch.steps)
                .font(.rounded(13))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack {
                Button("I'm done") { finish() }
                    .buttonStyle(.pill(.quiet, theme: theme))
                Spacer()
                Button(isLast ? "Finish 🎉" : "Next →") { advance() }
                    .buttonStyle(.pill(.primary, theme: theme))
            }
        }
        .task(id: index) {
            remaining = stretch.seconds
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                withAnimation { remaining -= 1 }
            }
            if model.settings.stretch.sound != .none { model.feedback.play(.tink) }
            advance()
        }
    }
}
