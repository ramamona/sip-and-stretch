import AppKit
import Observation
import SipStretchCore

/// What a nudge card is about.
enum NudgeContent {
    case reminder(ReminderKind, BreakActivity)
    case achievement(Achievement)
    case levelUp(Level)
    case welcome

    var reminderKind: ReminderKind? {
        if case .reminder(let kind, _) = self { return kind }
        return nil
    }
}

struct Nudge: Identifiable {
    let id = UUID()
    let content: NudgeContent
    let title: String
    let message: String
    /// Previews (from Settings) look real but don't touch stats or countdowns.
    var isPreview = false
}

/// The app's single source of truth. Cards, the popover, notifications and `sipstretch://` URLs
/// all call the same actions here; the scheduling rules themselves live in `ReminderClock`.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel(store: .standard)

    var settings: AppSettings {
        didSet { if settings != oldValue { settingsChanged(from: oldValue) } }
    }
    private(set) var stats: Stats
    private(set) var dnd: DNDState
    private(set) var clock = ReminderClock()
    /// Refreshed every tick; views read it so countdowns stay live.
    private(set) var now = Date()
    private(set) var isAway = false
    /// Camera or microphone in use (and the user wants reminders held during calls).
    private(set) var inMeeting = false
    private(set) var notificationStatus: NotificationService.Status = .unknown
    private(set) var launchAtLogin = LaunchAtLogin.isEnabled
    var launchAtLoginError: String?
    /// Header line in the popover: a greeting, or the latest cheer.
    var greeting = ""

    @ObservationIgnored let store: Persistence
    @ObservationIgnored let nudges = NudgeController()
    @ObservationIgnored let notifications = NotificationService()
    @ObservationIgnored let feedback = Feedback()
    @ObservationIgnored let presence = PresenceMonitor()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var awaySince: Date?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var lastLines: [String: String] = [:]
    @ObservationIgnored private var recentStretchIDs: [String] = []

    init(store: Persistence) {
        self.store = store
        settings = store.loadSettings()
        stats = store.loadStats()
        dnd = store.loadDND().normalized(at: Date())
        nudges.model = self
        refreshGreeting()
    }

    // MARK: Lifecycle

    func start() {
        guard !started else { return }
        started = true
        now = Date()
        clock.start(now: now, settings: settings)

        notifications.onAction = { [weak self] kind, action in self?.handleNotification(kind, action) }
        notifications.activate()
        Task { await refreshNotificationStatus() }

        presence.onChange = { [weak self] in self?.tick() }
        presence.start()

        // Reminders are minute-grained, so a lazy 30 s tick with generous tolerance is plenty
        // and lets macOS coalesce wake-ups. Lock/sleep changes tick immediately via PresenceMonitor.
        let timer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 10
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        if !store.hasOnboarded {
            store.hasOnboarded = true
            nudges.present(welcomeNudge())
        }
        tick()
    }

    func tick() {
        let now = Date()
        self.now = now
        if dnd != .off, !dnd.isActive(at: now) { setDND(.off) } // a timed DND ran out
        updatePresence(now: now)
        updateMeeting()
        let due = clock.tick(now: now, settings: settings, dndActive: isQuiet, userAway: isAway)
        for kind in due { deliver(kind) }
    }

    private func updatePresence(now: Date) {
        let idle = presence.idleSeconds
        let idleAway = settings.pauseWhenAway && idle >= awayThreshold
        let away = presence.isInactive || idleAway
        guard away != isAway else { return }
        if away {
            awaySince = presence.inactiveSince ?? now.addingTimeInterval(-idle)
        } else {
            clock.userReturned(awayFor: now.timeIntervalSince(awaySince ?? now), now: now, settings: settings)
            awaySince = nil
        }
        isAway = away
    }

    private func updateMeeting() {
        let meeting = settings.pauseDuringMeetings && MeetingDetector.isInMeeting
        guard meeting != inMeeting else { return }
        inMeeting = meeting
        quietChanged()
    }

    private var awayThreshold: TimeInterval { TimeInterval(max(1, settings.awayThresholdMinutes) * 60) }

    // MARK: Delivering reminders

    private func deliver(_ kind: ReminderKind) {
        let nudge = reminderNudge(kind)
        feedback.play(settings[kind].sound)
        if settings.speakReminders { feedback.speak("\(nudge.title) \(nudge.message)") }
        switch settings.delivery {
        case .card:
            nudges.present(nudge)
        case .both:
            nudges.present(nudge)
            if notificationsAllowed { notifications.post(kind: kind, title: nudge.title, body: nudge.message) }
        case .notification:
            // Never let a reminder vanish silently: permission may have been revoked since launch,
            // so check again and fall back to a card if notifications can't be shown.
            Task {
                await refreshNotificationStatus()
                if notificationsAllowed {
                    notifications.post(kind: kind, title: nudge.title, body: nudge.message)
                } else {
                    nudges.present(nudge)
                }
            }
        }
    }

    var notificationsAllowed: Bool { notificationStatus == .allowed }

    func reminderNudge(_ kind: ReminderKind, preview: Bool = false) -> Nudge {
        let personality = settings.personality
        let lines = switch kind {
        case .water: personality.pack.waterReminders
        case .stretch: personality.pack.stretchReminders
        case .eyes: personality.eyeReminders
        case .walk: personality.walkReminders
        }
        let message = line(lines, key: kind.rawValue)
        let activity = BreakPlanner.plan(kind, settings: settings, avoiding: recentStretchIDs)
        let stretches: [Stretch] = switch activity {
        case .guided(let list), .roulette(_, let list): list
        default: []
        }
        if !preview, !stretches.isEmpty { recentStretchIDs = Array((stretches.map(\.id) + recentStretchIDs).prefix(12)) }
        let title = kind.cardTitles.pick(avoiding: lastLines["title-\(kind)"])
        lastLines["title-\(kind)"] = title
        return Nudge(content: .reminder(kind, activity), title: title, message: message, isPreview: preview)
    }

    func welcomeNudge() -> Nudge {
        Nudge(
            content: .welcome,
            title: "Hi, I'm Drip! 💧",
            message: "I'll nudge you to sip and stretch during your active hours (\(settings.schedule.summary())). Click the droplet in your menu bar to find me."
        )
    }

    /// A personality line that isn't the one we said last time, placeholders filled in.
    func line(_ lines: [String], key: String) -> String {
        // "{left}" lines read oddly at the end of the day ("only 0 more!", "1 glasses left").
        let usable = waterLeft <= 1 ? lines.filter { !$0.contains("{left}") } : lines
        let template = (usable.isEmpty ? lines : usable).pick(avoiding: lastLines[key])
        lastLines[key] = template
        return MessagePack.render(template, name: settings.nickname, left: waterLeft)
    }

    func refreshGreeting() {
        greeting = line(settings.personality.pack.greetings, key: "greeting")
    }

    func preview(_ kind: ReminderKind) {
        feedback.play(settings[kind].sound)
        nudges.present(reminderNudge(kind, preview: true))
    }

    // MARK: Actions

    /// Logs a glass and returns the line to celebrate with. Logged anywhere but the water card
    /// itself (popover, URL, notification), a waiting water card is answered too.
    @discardableResult
    func drink(fromCard: Bool = false) -> String {
        if !fromCard { nudges.dismiss(.water) }
        let levelBefore = stats.level
        let wasBelowGoal = today.water < settings.dailyWaterGoal
        stats.logWater(1, at: Date(), goal: settings.dailyWaterGoal, schedule: settings.schedule)
        clock.restart(.water, now: Date(), settings: settings) // just drank: count from now
        notifications.removeDelivered(.water)
        statsChanged(levelBefore: levelBefore)
        let pack = settings.personality.pack
        let cheer = wasBelowGoal && waterLeft == 0 ? line(pack.goalReached, key: "goal") : line(pack.waterCheers, key: "water-cheer")
        greeting = cheer
        return cheer
    }

    func undoDrink() {
        stats.logWater(-1, at: Date(), goal: settings.dailyWaterGoal, schedule: settings.schedule)
        statsChanged(levelBefore: nil)
    }

    /// Finished a stretch break, eye break or walk. Returns the line to celebrate with.
    @discardableResult
    func completeBreak(_ kind: ReminderKind) -> String {
        guard kind != .water else { return drink(fromCard: true) }
        let levelBefore = stats.level
        stats.logBreak(kind, at: Date(), schedule: settings.schedule)
        clock.restart(kind, now: Date(), settings: settings)
        notifications.removeDelivered(kind)
        statsChanged(levelBefore: levelBefore)
        let cheers = kind == .eyes ? Personality.eyeCheers : settings.personality.pack.stretchCheers
        let cheer = line(cheers, key: "\(kind)-cheer")
        greeting = cheer
        return cheer
    }

    @discardableResult
    func snooze(_ kind: ReminderKind) -> String {
        stats.logSnooze(at: Date(), schedule: settings.schedule)
        clock.snooze(kind, now: Date(), settings: settings)
        notifications.removeDelivered(kind)
        statsChanged(levelBefore: nil)
        return line(settings.personality.pack.snoozes, key: "snooze")
    }

    /// Dismissed a reminder without doing it. The countdown already restarted when it fired.
    func skip(_ kind: ReminderKind) {
        stats.logSkip(at: Date(), schedule: settings.schedule)
        notifications.removeDelivered(kind)
        store.save(stats)
    }

    /// Popover "Skip": pass on the upcoming reminder and start the next countdown now.
    func skipUpcoming(_ kind: ReminderKind) {
        clock.restart(kind, now: Date(), settings: settings)
    }

    func remindNow(_ kind: ReminderKind) {
        clock.restart(kind, now: Date(), settings: settings)
        deliver(kind)
    }

    private func statsChanged(levelBefore: Level?) {
        let unlocked = stats.unlockAchievements(goal: settings.dailyWaterGoal, at: Date())
        store.save(stats)
        for achievement in unlocked {
            nudges.present(Nudge(content: .achievement(achievement), title: "Achievement unlocked!", message: achievement.detail))
        }
        if let levelBefore, stats.level.number > levelBefore.number {
            nudges.present(Nudge(content: .levelUp(stats.level), title: "Level up!", message: stats.level.title))
        }
    }

    func resetStats() {
        stats = Stats()
        store.save(stats)
        refreshGreeting()
    }

    // MARK: Do Not Disturb

    var isDNDActive: Bool { dnd.isActive(at: now) }

    /// Reminders wait while this is true: Do Not Disturb or a call in progress.
    var isQuiet: Bool { isDNDActive || inMeeting }

    func setDND(_ state: DNDState) {
        // `dnd != .off` rather than isDNDActive: a timed DND that just ran out still counts as ending.
        let wasQuiet = dnd != .off || inMeeting
        dnd = state.normalized(at: Date())
        store.save(dnd)
        if wasQuiet != isQuiet { quietChanged() }
    }

    private func quietChanged() {
        if isQuiet {
            // Don't leave a reminder card on screen (e.g. over a screen share); it comes back later.
            nudges.stashReminders()
        } else {
            // Held reminders fire a minute later instead of all at once, and stashed cards return.
            clock.deferOverdue(now: Date(), by: 60, settings: settings)
            nudges.showNextIfIdle()
        }
    }

    func startDND(_ preset: DNDPreset) {
        setDND(preset.state(from: Date(), schedule: settings.schedule))
    }

    // MARK: Settings side effects

    private func settingsChanged(from old: AppSettings) {
        store.save(settings)
        let now = Date()
        let scheduleChanged = settings.schedule != old.schedule
        for kind in ReminderKind.allCases {
            let changed = settings[kind].enabled != old[kind].enabled || settings[kind].intervalMinutes != old[kind].intervalMinutes
            if changed || scheduleChanged { clock.restart(kind, now: now, settings: settings) }
        }
        if settings.personality != old.personality || settings.nickname != old.nickname { refreshGreeting() }
        if settings.dailyWaterGoal != old.dailyWaterGoal || scheduleChanged {
            // A new goal or new rest days can complete streaks (and achievements) retroactively.
            stats.refreshBestStreak(goal: settings.dailyWaterGoal, schedule: settings.schedule, today: now)
            statsChanged(levelBefore: nil)
        }
        if settings.delivery != .card && old.delivery == .card {
            Task { await requestNotifications() }
        }
    }

    func refreshNotificationStatus() async {
        notificationStatus = await notifications.status()
    }

    func requestNotifications() async {
        await notifications.requestAuthorization()
        await refreshNotificationStatus()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.set(enabled)
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Couldn't change the login item: \(error.localizedDescription)"
        }
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    // MARK: Notifications & automation

    private func handleNotification(_ kind: ReminderKind, _ action: NotificationService.Action) {
        switch action {
        case .done:
            nudges.dismiss(kind)
            if kind == .water { drink() } else { completeBreak(kind) }
        case .snooze:
            nudges.dismiss(kind)
            snooze(kind)
        case .open:
            // A card of this kind may already be up (card + notification); present() keeps it.
            nudges.present(reminderNudge(kind))
        }
    }

    func perform(_ command: AutomationCommand) {
        switch command {
        case .drink: drink()
        case .undoDrink: undoDrink()
        case .remind(let kind): remindNow(kind)
        case .dnd(let minutes): setDND(minutes.map { .until(Date().addingTimeInterval(TimeInterval($0) * 60)) } ?? .indefinitely)
        case .dndOff: setDND(.off)
        case .openSettings: SettingsWindowController.shared.show()
        }
    }

    // MARK: Derived state for views

    var today: DayLog { stats.today(at: now, schedule: settings.schedule) }
    var waterLeft: Int { max(0, settings.dailyWaterGoal - today.water) }
    var waterProgress: Double { Double(today.water) / Double(max(1, settings.dailyWaterGoal)) }
    var streak: Int { stats.streak(goal: settings.dailyWaterGoal, schedule: settings.schedule, today: now) }

    var mood: DripMood {
        if isQuiet || !settings.schedule.isActive(at: now) { return .sleepy }
        if waterLeft == 0 { return .excited }
        if isBehindOnWater { return .thirsty }
        return .happy
    }

    /// Fewer glasses than the elapsed share of today's active window would suggest (with some slack).
    var isBehindOnWater: Bool {
        guard let window = settings.schedule.currentWindow(at: now) else { return false }
        let elapsed = now.timeIntervalSince(window.start) / window.duration
        return Double(today.water) < Double(settings.dailyWaterGoal) * elapsed - 1.5
    }

    /// Soonest upcoming reminder today (for the menu bar countdown).
    var nextReminder: (kind: ReminderKind, date: Date)? {
        ReminderKind.allCases
            .compactMap { kind in clock.nextDue[kind].map { (kind: kind, date: $0) } }
            .min { $0.date < $1.date }
    }
}

// MARK: - Demo data (README screenshots)

extension AppModel {
    /// A lived-in model on a throwaway defaults suite, frozen at `now`.
    static func demo(now: Date) -> AppModel {
        let suite = "com.sipstretch.snapshots"
        UserDefaults().removePersistentDomain(forName: suite)
        let model = AppModel(store: Persistence(defaults: UserDefaults(suiteName: suite)!))
        model.settings.nickname = "Sam"
        let calendar = Calendar.current
        for daysAgo in (1...6).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let glasses = [8, 9, 6, 8, 10, 8][daysAgo - 1]
            for _ in 0..<glasses { model.stats.logWater(at: day, goal: 8, schedule: ActiveSchedule(weekdays: Set(1...7))) }
            for _ in 0..<(3 + daysAgo % 3) { model.stats.logBreak(.stretch, at: day, schedule: model.settings.schedule) }
        }
        for _ in 0..<5 { model.stats.logWater(at: now, goal: 8, schedule: ActiveSchedule(weekdays: Set(1...7))) }
        for _ in 0..<3 { model.stats.logBreak(.stretch, at: now, schedule: model.settings.schedule) }
        _ = model.stats.unlockAchievements(goal: 8, at: now)
        model.clock.start(now: now.addingTimeInterval(-37 * 60), settings: model.settings)
        model.now = now
        model.greeting = "Hey Sam, you're doing amazing today! 🌟"
        return model
    }
}
