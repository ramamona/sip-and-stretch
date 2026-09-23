import SwiftUI
import SipStretchCore

struct RemindersPane: View {
    @Environment(AppModel.self) private var model

    private static let intervals = [10, 15, 20, 30, 45, 60, 75, 90, 120, 150, 180, 240]
    private static let snoozes = [5, 10, 15, 20, 30]
    private static let glassSizes = [150, 200, 250, 300, 350, 400, 500]

    var body: some View {
        @Bindable var model = model
        Form {
            reminderSection(.water, settings: $model.settings.water) {
                Stepper(value: $model.settings.dailyGoalML, in: 500...6000, step: 250) {
                    LabeledContent("Daily goal", value: "\(model.settings.volumeString(milliliters: model.settings.dailyGoalML)) · \(model.settings.dailyWaterGoal) glasses")
                }
                Picker("Glass size", selection: $model.settings.glassSizeML) {
                    ForEach(Self.glassSizes, id: \.self) { ml in
                        Text(glassLabel(ml)).tag(ml)
                    }
                }
                Toggle("Show volumes in fluid ounces", isOn: $model.settings.useOunces)
            }

            reminderSection(.stretch, settings: $model.settings.stretch) {
                Stepper(value: $model.settings.stretchesPerBreak, in: 1...5) {
                    LabeledContent("Stretches per break", value: "\(model.settings.stretchesPerBreak)")
                }
                LabeledContent("Focus on") {
                    FlowChips(
                        items: BodyArea.allCases,
                        isOn: { model.settings.stretchAreas.contains($0) },
                        toggle: { area in
                            // Keep at least one; an empty set would mean "everything" anyway.
                            if model.settings.stretchAreas.contains(area) {
                                if model.settings.stretchAreas.count > 1 { model.settings.stretchAreas.remove(area) }
                            } else {
                                model.settings.stretchAreas.insert(area)
                            }
                        },
                        label: { "\($0.emoji) \($0.displayName)" },
                        theme: model.settings.theme
                    )
                }
                LabeledContent("Mix in") {
                    FlowChips(
                        items: StretchFormat.allCases,
                        isOn: { model.settings.stretchFormats.contains($0) },
                        toggle: { format in
                            if model.settings.stretchFormats.contains(format) {
                                if model.settings.stretchFormats.count > 1 { model.settings.stretchFormats.remove(format) }
                            } else {
                                model.settings.stretchFormats.insert(format)
                            }
                        },
                        label: { "\($0.emoji) \($0.displayName)" },
                        theme: model.settings.theme
                    )
                }
            }

            reminderSection(.eyes, settings: $model.settings.eyes) {
                Text("Every so often, look at something about 6 m (20 ft) away for 20 seconds. The card counts it down for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            reminderSection(.walk, settings: $model.settings.walk) {
                Text("A few minutes on your feet, with an idea for where to go. Being away from your desk resets this countdown too.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func reminderSection<Extra: View>(
        _ kind: ReminderKind,
        settings: Binding<ReminderSettings>,
        @ViewBuilder extra: () -> Extra
    ) -> some View {
        Section {
            Toggle("Remind me to \(kind.verb)", isOn: settings.enabled)
            Group {
                Picker("Every", selection: settings.intervalMinutes) {
                    ForEach(Self.intervals, id: \.self) { Text(Format.duration(TimeInterval($0 * 60))).tag($0) }
                    if !Self.intervals.contains(settings.wrappedValue.intervalMinutes) {
                        Text(Format.duration(TimeInterval(settings.wrappedValue.intervalMinutes * 60))).tag(settings.wrappedValue.intervalMinutes)
                    }
                }
                Picker("Snooze for", selection: settings.snoozeMinutes) {
                    ForEach(Self.snoozes, id: \.self) { Text("\($0) min").tag($0) }
                }
                HStack {
                    Picker("Sound", selection: settings.sound) {
                        ForEach(AlertSound.allCases) { Text($0.displayName).tag($0) }
                    }
                    Button {
                        model.feedback.play(settings.wrappedValue.sound)
                    } label: {
                        Image(systemName: "play.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Play sound")
                    .disabled(settings.wrappedValue.sound == .none)
                }
                extra()
            }
            .disabled(!settings.wrappedValue.enabled)
        } header: {
            Text("\(kind.emoji) \(kind.title)")
        }
    }

    private func glassLabel(_ ml: Int) -> String {
        model.settings.useOunces ? "\(Int((Double(ml) / 29.5735).rounded())) oz" : "\(ml) ml"
    }
}

/// Toggleable capsule chips that wrap onto several lines.
struct FlowChips<Item: Identifiable>: View {
    let items: [Item]
    let isOn: (Item) -> Bool
    let toggle: (Item) -> Void
    let label: (Item) -> String
    let theme: Theme

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(items) { item in
                let on = isOn(item)
                Button(label(item)) { toggle(item) }
                    .buttonStyle(.pill(on ? .primary : .quiet, theme: theme, compact: true))
                    .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// Minimal wrapping layout (left-aligned rows).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map { $0.width }.max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].indices.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
