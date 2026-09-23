import SwiftUI
import SipStretchCore

/// The floating card. Reminders walk through phases: ask → (guided stretches) → celebrate.
struct NudgeCardView: View {
    let nudge: Nudge
    let close: () -> Void

    static let cardSize = CGSize(width: 384, height: 236)
    static let shadowPadding: CGFloat = 22
    static var panelSize: CGSize {
        CGSize(width: cardSize.width + shadowPadding * 2, height: cardSize.height + shadowPadding * 2)
    }

    enum Phase: Equatable {
        case ask
        /// Stretch roulette spinning to pick an area.
        case spin
        case guide(Int)
        /// Breathing, challenge, posture check or eye rest in progress.
        case activity
        case celebrate(String, xp: Int)
        case snoozed(String)
    }

    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewState private var phase: Phase = .ask
    @ViewState private var confettiStart: Date? = nil
    /// Drip bounces for a few seconds when a card (or phase) appears, then holds still, so a card
    /// left waiting on screen uses no CPU.
    @ViewState private var lively = true

    init(nudge: Nudge, phase: Phase = .ask, close: @escaping () -> Void) {
        self.nudge = nudge
        self.close = close
        _phase = ViewState(wrappedValue: phase)
    }

    private var theme: Theme { model.settings.theme }
    private var accent: Color { theme.accent(for: colorScheme) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .padding(18)
                .frame(width: Self.cardSize.width, height: Self.cardSize.height, alignment: .topLeading)
            if let confettiStart, !reduceMotion {
                ConfettiView(start: confettiStart, colors: theme.confettiColors)
            }
            closeButton
        }
        .background {
            ZStack {
                Rectangle().fill(.background)
                LinearGradient(colors: [theme.light.opacity(0.3), theme.light.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(theme.light.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
        .padding(Self.shadowPadding)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
        .task(id: phase) {
            lively = true
            try? await Task.sleep(for: .seconds(8))
            lively = false
        }
        .onAppear {
            switch nudge.content {
            case .achievement, .levelUp: confettiStart = .now
            default: break
            }
        }
    }

    // MARK: Phases

    @ViewBuilder
    private var content: some View {
        switch (nudge.content, phase) {
        case (_, .celebrate(let message, let xp)):
            celebrate(message: message, xp: xp)
        case (_, .snoozed(let message)):
            snoozed(message: message)
        case (.reminder(let kind, let activity), .ask):
            ask(kind: kind, activity: activity)
        case (.reminder(_, .roulette(let area, _)), .spin):
            RouletteView(target: area, theme: theme) { phase = .guide(0) }
        case (.reminder(let kind, let activity), .guide(let index)):
            let stretches = Self.stretches(in: activity)
            StretchGuideView(stretches: stretches, index: index, theme: theme) {
                if index + 1 < stretches.count { phase = .guide(index + 1) } else { finish(kind) }
            } finish: {
                finish(kind)
            }
        case (.reminder(let kind, .breathing(let cycles)), .activity):
            BreathingView(cycles: cycles, theme: theme) { finish(kind) }
        case (.reminder(let kind, .challenge(let challenge)), .activity):
            ChallengeView(challenge: challenge, theme: theme) { finish(kind) }
        case (.reminder(let kind, .postureCheck(let items)), .activity):
            PostureCheckView(items: items, theme: theme) { finish(kind) }
        case (.reminder(let kind, .eyeRest(let seconds, let tip)), .activity):
            EyeRestView(seconds: seconds, tip: tip, theme: theme) { finish(kind) }
        case (.achievement(let achievement), _):
            achievementView(achievement)
        case (.levelUp(let level), _):
            levelUpView(level)
        case (.welcome, _):
            welcome
        default:
            EmptyView()
        }
    }

    private static func stretches(in activity: BreakActivity) -> [Stretch] {
        switch activity {
        case .guided(let list), .roulette(_, let list): list
        default: []
        }
    }

    private func ask(kind: ReminderKind, activity: BreakActivity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                DripView(mood: askMood(kind), theme: theme, size: 66, animated: lively)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(nudge.title).font(.rounded(21, .bold))
                        if nudge.isPreview { previewTag }
                    }
                    Text(nudge.message)
                        .font(.rounded(13.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 14)
            }
            Spacer(minLength: 8)
            if kind == .water {
                HStack(spacing: 8) {
                    Text("💧 \(model.today.water)/\(model.settings.dailyWaterGoal) today")
                        .font(.rounded(12, .semibold))
                        .foregroundStyle(.secondary)
                    XPBar(progress: model.waterProgress, theme: theme, height: 5)
                }
            } else if let summary = Self.summary(of: activity) {
                Text(summary)
                    .font(.rounded(12, .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 10)
            HStack(spacing: 8) {
                Button("Skip") { skip(kind) }
                    .buttonStyle(.pill(.quiet, theme: theme))
                Spacer()
                Button("Snooze \(model.settings[kind].snoozeMinutes)m") { snooze(kind) }
                    .buttonStyle(.pill(.secondary, theme: theme))
                Button(Self.primaryLabel(for: activity)) { start(kind, activity: activity) }
                    .buttonStyle(.pill(.primary, theme: theme))
            }
        }
    }

    private func askMood(_ kind: ReminderKind) -> DripMood {
        switch kind {
        case .water: model.isBehindOnWater ? .thirsty : .happy
        case .stretch: .stretching
        case .eyes: .sleepy
        case .walk: .excited
        }
    }

    /// One line under the message saying what's about to happen.
    private static func summary(of activity: BreakActivity) -> String? {
        switch activity {
        case .drink: nil
        case .guided(let stretches):
            "\(stretches.map(\.emoji).joined(separator: " "))  \(stretches.count) quick stretch\(stretches.count == 1 ? "" : "es") · about \(stretches.map(\.seconds).reduce(0, +)) s"
        case .roulette: "🎰 Stretch roulette: spin the wheel, stretch whatever it lands on"
        case .breathing(let cycles): "🫁 \(cycles) rounds of box breathing · about \(cycles * 16) s"
        case .challenge(let challenge):
            challenge.isTimed ? "\(challenge.emoji) Mini challenge: \(challenge.name), \(challenge.seconds) s" : "\(challenge.emoji) Mini challenge: \(challenge.reps) × \(challenge.name)"
        case .postureCheck(let items): "🪑 Quick posture check · \(items.count) things to fix"
        case .eyeRest(let seconds, _): "👀 \(seconds) seconds looking far away"
        case .walk(let idea): "💡 \(idea)"
        }
    }

    private static func primaryLabel(for activity: BreakActivity) -> String {
        switch activity {
        case .drink: "💧 Drank it!"
        case .guided: "🤸 Let's stretch"
        case .roulette: "🎰 Spin!"
        case .breathing: "🫁 Breathe"
        case .challenge: "💪 I'm in"
        case .postureCheck: "🪑 Check me"
        case .eyeRest: "👀 Start"
        case .walk: "🚶 Going!"
        }
    }

    private func celebrate(message: String, xp: Int) -> some View {
        HStack(spacing: 16) {
            DripView(mood: .excited, theme: theme, size: 74, animated: lively)
            VStack(alignment: .leading, spacing: 6) {
                Text(nudge.isPreview ? "Nice!" : "+\(xp) XP")
                    .font(.rounded(26, .heavy))
                    .foregroundStyle(theme.gradient)
                Text(message)
                    .font(.rounded(14, .medium))
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                levelRow.padding(.top, 4)
            }
            .padding(.trailing, 12)
        }
        .frame(maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(3.6))
            close()
        }
    }

    private func snoozed(message: String) -> some View {
        HStack(spacing: 16) {
            DripView(mood: .sleepy, theme: theme, size: 70, animated: lively)
            VStack(alignment: .leading, spacing: 6) {
                Text("Snoozed 😴").font(.rounded(22, .bold))
                Text(message)
                    .font(.rounded(13.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.trailing, 12)
        }
        .frame(maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(2.6))
            close()
        }
    }

    private func achievementView(_ achievement: Achievement) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(theme.gradient).shadow(color: theme.deep.opacity(0.4), radius: 8, y: 4)
                Text(achievement.emoji).font(.system(size: 40))
            }
            .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 4) {
                Text("ACHIEVEMENT UNLOCKED")
                    .font(.rounded(11, .heavy))
                    .tracking(1)
                    .foregroundStyle(accent)
                Text(achievement.title).font(.rounded(22, .bold))
                Text(achievement.detail).font(.rounded(13.5)).foregroundStyle(.secondary)
                Button("Woohoo!") { close() }
                    .buttonStyle(.pill(.primary, theme: theme))
                    .padding(.top, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(7))
            close()
        }
    }

    private func levelUpView(_ level: Level) -> some View {
        HStack(spacing: 16) {
            DripView(mood: .excited, theme: theme, size: 76, animated: lively)
            VStack(alignment: .leading, spacing: 4) {
                Text("LEVEL UP!")
                    .font(.rounded(12, .heavy))
                    .tracking(1.2)
                    .foregroundStyle(accent)
                Text("Level \(level.number)").font(.rounded(26, .heavy)).foregroundStyle(theme.gradient)
                Text(level.number <= Level.titles.count ? "New title: \(level.title)" : "Still the one and only \(level.title)")
                    .font(.rounded(14, .medium))
                Button("Let's gooo") { close() }
                    .buttonStyle(.pill(.primary, theme: theme))
                    .padding(.top, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .task {
            try? await Task.sleep(for: .seconds(7))
            close()
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                DripView(mood: .happy, theme: theme, size: 70, animated: lively)
                VStack(alignment: .leading, spacing: 5) {
                    Text(nudge.title).font(.rounded(21, .bold))
                    Text(nudge.message)
                        .font(.rounded(13.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.trailing, 14)
            }
            Spacer(minLength: 10)
            HStack {
                Spacer()
                Button("Customize…") {
                    SettingsWindowController.shared.show()
                    close()
                }
                .buttonStyle(.pill(.secondary, theme: theme))
                Button("Let's go! 🚀") { close() }
                    .buttonStyle(.pill(.primary, theme: theme))
            }
        }
    }

    // MARK: Pieces

    private var levelRow: some View {
        let level = model.stats.level
        return HStack(spacing: 8) {
            Text("Lv \(level.number)").font(.rounded(11, .bold)).foregroundStyle(.secondary)
            XPBar(progress: level.progress, theme: theme, height: 5).frame(maxWidth: 140)
        }
    }

    private var previewTag: some View {
        Text("PREVIEW")
            .font(.rounded(9, .heavy))
            .tracking(0.8)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(theme.light.opacity(0.3)))
    }

    private var closeButton: some View {
        Button {
            switch (nudge.content, phase) {
            case (.reminder(let kind, _), .ask), (.reminder(let kind, _), .spin), (.reminder(let kind, _), .activity): skip(kind)
            // Bailing out during the first stretch doesn't count; later on, the break does.
            case (.reminder(let kind, _), .guide(let index)): index > 0 ? finish(kind) : skip(kind)
            default: close()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.primary.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .padding(10)
        .accessibilityLabel("Close")
    }

    // MARK: Actions

    private func start(_ kind: ReminderKind, activity: BreakActivity) {
        switch activity {
        case .drink, .walk: finish(kind)
        case .guided(let stretches): if stretches.isEmpty { finish(kind) } else { phase = .guide(0) }
        case .roulette: phase = .spin
        case .breathing, .challenge, .postureCheck, .eyeRest: phase = .activity
        }
    }

    private func finish(_ kind: ReminderKind) {
        let message = nudge.isPreview ? "Preview complete. The real thing counts for XP! ✨" : model.completeBreak(kind)
        startCelebration(message: message, xp: kind.xp)
    }

    private func startCelebration(message: String, xp: Int) {
        confettiStart = .now
        phase = .celebrate(message, xp: xp)
    }

    private func snooze(_ kind: ReminderKind) {
        let minutes = model.settings[kind].snoozeMinutes
        let line = nudge.isPreview ? "(Preview) I'd be back in \(minutes) minutes." : model.snooze(kind)
        phase = .snoozed(line)
    }

    private func skip(_ kind: ReminderKind) {
        if !nudge.isPreview { model.skip(kind) }
        close()
    }
}
