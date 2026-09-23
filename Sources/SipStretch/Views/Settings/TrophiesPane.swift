import Charts
import SwiftUI
import SipStretchCore

struct TrophiesPane: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @ViewState private var confirmingReset = false

    private var theme: Theme { model.settings.theme }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    DripView(mood: .excited, theme: theme, size: 60)
                    VStack(alignment: .leading, spacing: 6) {
                        let level = model.stats.level
                        Text("Level \(level.number) · \(level.title)").font(.rounded(18, .bold))
                        XPBar(progress: level.progress, theme: theme, height: 8)
                        Text("\(level.xpIntoLevel) / \(level.xpForNextLevel) XP to level \(level.number + 1) · \(model.stats.xp) XP total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                HStack {
                    stat("\(model.streak)", "day streak", "🔥")
                    stat("\(model.stats.bestStreak)", "best streak", "🏅")
                    stat("\(model.stats.totalWater)", "glasses", "💧")
                    stat("\(model.stats.totalStretches)", "stretch breaks", "🤸")
                }
            }

            Section("Last 14 days") {
                chart.frame(height: 160).padding(.vertical, 6)
            }

            Section("Achievements · \(model.stats.unlocked.count) of \(Achievement.all.count)") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 10)], spacing: 10) {
                    ForEach(Achievement.all) { achievement in
                        badge(achievement, unlockedAt: model.stats.unlocked[achievement.id])
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Reset all stats…", role: .destructive) { confirmingReset = true }
            } footer: {
                Text("Streaks don't break on days outside your active hours (weekends, by default).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset all stats?", isPresented: $confirmingReset) {
            Button("Reset everything", role: .destructive) { model.resetStats() }
        } message: {
            Text("This clears your history, XP, streaks and achievements. Drip will be sad. 🥲")
        }
    }

    private var chart: some View {
        let days = model.stats.recentDays(14, endingAt: model.now)
        return Chart {
            ForEach(days, id: \.date) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Glasses", day.log.water))
                    .foregroundStyle(day.log.water >= model.settings.dailyWaterGoal ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(theme.light.opacity(0.55)))
                    .cornerRadius(4)
            }
            RuleMark(y: .value("Goal", model.settings.dailyWaterGoal))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .foregroundStyle(theme.deep)
                .annotation(position: .top, alignment: .leading) {
                    Text("goal").font(.caption2).foregroundStyle(theme.accent(for: colorScheme))
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .accessibilityLabel("Glasses of water per day for the last 14 days")
    }

    private func stat(_ value: String, _ label: String, _ emoji: String) -> some View {
        VStack(spacing: 2) {
            Text("\(emoji) \(value)").font(.rounded(18, .bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func badge(_ achievement: Achievement, unlockedAt: Date?) -> some View {
        let unlocked = unlockedAt != nil
        return HStack(spacing: 10) {
            Text(unlocked ? achievement.emoji : "🔒")
                .font(.system(size: 26))
                .frame(width: 44, height: 44)
                .background(Circle().fill(unlocked ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.primary.opacity(0.06))))
                .grayscale(unlocked ? 0 : 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title).font(.rounded(12.5, .bold))
                Text(unlockedAt.map { "Unlocked \($0.formatted(date: .abbreviated, time: .omitted))" } ?? achievement.detail)
                    .font(.rounded(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(unlocked ? 1 : 0.7)
        .help(achievement.detail)
        .accessibilityElement(children: .combine)
    }
}
