import AppKit
import SwiftUI
import SipStretchCore

/// The popover behind the menu bar droplet.
struct MenuContentView: View {
    @Environment(AppModel.self) private var model
    var animated = true
    /// MenuBarExtra keeps this view alive while the popover is closed; only animate while it's open.
    @ViewState private var visible = false

    private var theme: Theme { model.settings.theme }
    private var live: Bool { animated && visible }

    var body: some View {
        VStack(spacing: 10) {
            header
            waterTile
            upcomingTile
            dndTile
            footer
        }
        .padding(14)
        .frame(width: 340)
        // Don't touch the model here: MenuBarExtra re-runs onAppear whenever the menu bar label
        // updates, so a model write in here becomes a redraw loop that burns CPU all day.
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            DripView(mood: model.mood, theme: theme, size: 50, animated: live)
            VStack(alignment: .leading, spacing: 5) {
                Text(model.greeting)
                    .font(.rounded(14, .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                let level = model.stats.level
                HStack(spacing: 6) {
                    Text("Lv \(level.number) · \(level.title)")
                        .font(.rounded(11, .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .layoutPriority(1)
                    XPBar(progress: level.progress, theme: theme, height: 5)
                        .frame(minWidth: 40)
                }
                .help("\(level.xpIntoLevel) / \(level.xpForNextLevel) XP to level \(level.number + 1)")
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: Water

    private var waterTile: some View {
        Tile {
            HStack(spacing: 14) {
                WaterBottle(progress: model.waterProgress, marks: model.settings.dailyWaterGoal, theme: theme, animated: live)
                    .frame(width: 54, height: 84)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(model.today.water) of \(model.settings.dailyWaterGoal) glasses")
                        .font(.rounded(17, .bold))
                        .contentTransition(.numericText())
                    Text(model.waterLeft == 0 ? "Goal smashed · \(model.settings.volumeString(glasses: model.today.water)) 🎉" : "\(model.settings.volumeString(glasses: model.today.water)) so far · \(model.waterLeft) to go")
                        .font(.rounded(12))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Label("\(model.streak)-day streak", systemImage: "flame.fill")
                            .foregroundStyle(model.streak > 0 ? Color.orange : Color.secondary)
                        Text("🤸 \(model.today.stretches) · 👀 \(model.today.eyeBreaks) · 🚶 \(model.today.walks)")
                            .foregroundStyle(.secondary)
                            .help("Stretch breaks, eye breaks and walks today")
                    }
                    .font(.rounded(11, .semibold))
                    .labelStyle(.titleAndIcon)
                    HStack(spacing: 6) {
                        Button {
                            withAnimation(.spring) { _ = model.drink() } // also answers a waiting water card
                        } label: {
                            Label("Glass", systemImage: "plus")
                        }
                        .buttonStyle(.pill(.primary, theme: theme, compact: true))
                        Button {
                            withAnimation(.spring) { model.undoDrink() }
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.pill(.quiet, theme: theme, compact: true))
                        .disabled(model.today.water == 0)
                        .help("Oops, remove a glass")
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    // MARK: Upcoming reminders

    private var upcomingTile: some View {
        Tile {
            VStack(alignment: .leading, spacing: 10) {
                if let status = statusLine {
                    Text(status)
                        .font(.rounded(11.5, .semibold))
                        .foregroundStyle(.secondary)
                }
                let kinds = ReminderKind.allCases.filter { model.settings[$0].enabled }
                if kinds.isEmpty {
                    Text("All reminders are off. Turn them on in Settings.")
                        .font(.rounded(12))
                        .foregroundStyle(.secondary)
                }
                ForEach(kinds) { kind in reminderRow(kind) }
            }
        }
    }

    private func reminderRow(_ kind: ReminderKind) -> some View {
        let due = model.clock.nextDue[kind]
        let interval = model.settings[kind].interval
        let remaining = due.map { $0.timeIntervalSince(model.now) } ?? interval
        return HStack(spacing: 10) {
            ProgressRing(progress: 1 - min(1, max(0, remaining / interval)), theme: theme, lineWidth: 3.5) {
                Text(kind.emoji).font(.system(size: 14))
            }
            .frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(kind.title).font(.rounded(13, .bold))
                Text(detail(for: kind, due: due))
                    .font(.rounded(11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button("Now") { model.remindNow(kind) }
                .buttonStyle(.pill(.secondary, theme: theme, compact: true))
                .help("Show this reminder right now")
            Button("Skip") { model.skipUpcoming(kind) }
                .buttonStyle(.pill(.quiet, theme: theme, compact: true))
                .help("Skip the next one and restart the countdown")
        }
    }

    private func detail(for kind: ReminderKind, due: Date?) -> String {
        guard let due else {
            return model.settings.schedule.weekdays.isEmpty && model.settings.schedule.isEnabled ? "No active days selected" : "Not scheduled"
        }
        let remaining = due.timeIntervalSince(model.now)
        if remaining <= 0 {
            if model.isQuiet { return "On hold" } // the status line above says why
            if model.isAway { return "Waiting for you" }
            return "Due now"
        }
        if !Calendar.current.isDate(due, inSameDayAs: model.now) { return "Next: \(Format.moment(due, relativeTo: model.now))" }
        return "in \(Format.duration(remaining)) · \(Format.time(due))"
    }

    private var statusLine: String? {
        if model.inMeeting { return "🎥 On a call · reminders will wait" }
        if model.isDNDActive {
            if let end = model.dnd.endDate { return "😴 Quiet until \(Format.moment(end, relativeTo: model.now))" }
            return "😴 Quiet until you turn Do Not Disturb off"
        }
        let schedule = model.settings.schedule
        if !schedule.isActive(at: model.now) {
            if let back = schedule.nextActiveStart(after: model.now) { return "🌙 Off the clock · back \(Format.moment(back, relativeTo: model.now))" }
            return "🌙 Off the clock"
        }
        if model.isAway { return "🚶 Paused while you're away" }
        return nil
    }

    // MARK: Do Not Disturb

    private var dndTile: some View {
        Tile {
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: Binding(
                    get: { model.isDNDActive },
                    set: { $0 ? model.startDND(.indefinitely) : model.setDND(.off) }
                )) {
                    Label("Do Not Disturb", systemImage: "moon.zzz.fill")
                        .font(.rounded(13, .bold))
                }
                .toggleStyle(JellyToggleStyle(theme: theme))
                if !model.isDNDActive {
                    HStack(spacing: 5) {
                        Text("Quiet for")
                            .font(.rounded(11.5))
                            .foregroundStyle(.secondary)
                        ForEach([DNDPreset.thirtyMinutes, .oneHour, .twoHours, .untilTomorrow]) { preset in
                            Button(shortTitle(preset)) { model.startDND(preset) }
                                .buttonStyle(.pill(.quiet, theme: theme, compact: true))
                        }
                    }
                }
            }
        }
    }

    private func shortTitle(_ preset: DNDPreset) -> String {
        switch preset {
        case .thirtyMinutes: "30m"
        case .oneHour: "1h"
        case .twoHours: "2h"
        case .untilTomorrow: "Tomorrow"
        case .indefinitely: "∞"
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Button {
                SettingsWindowController.shared.show()
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
            }
            Button {
                SettingsWindowController.shared.show(.trophies)
            } label: {
                Label("Trophies", systemImage: "trophy.fill")
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .buttonStyle(.pill(.quiet, theme: theme, compact: true))
        .padding(.horizontal, 2)
    }
}
