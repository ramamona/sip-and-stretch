import Foundation

/// The scheduling brain, kept pure so it can be unit tested without timers.
///
/// Rules:
/// - Countdowns only run inside active hours. When a countdown would cross the end of a window,
///   the reminder moves to one interval after the next window opens.
/// - Water and stretch never land within a few minutes of each other; the one being
///   rescheduled is pushed back by half its interval (at most 30 minutes).
/// - A due reminder is *held* (not dropped) while Do Not Disturb is on or the user is away,
///   and fires on the first tick after that ends.
/// - If a reminder was due in an earlier window (e.g. the Mac slept overnight), it is stale:
///   the countdown restarts instead of firing a leftover reminder at 9:00 sharp.
public struct ReminderClock: Equatable, Sendable {
    public private(set) var nextDue: [ReminderKind: Date] = [:]

    /// Reminders closer together than this get pulled apart.
    static let collisionWindow: TimeInterval = 5 * 60

    public init() {}

    /// Starts every enabled countdown (water first, so stretch staggers after it).
    public mutating func start(now: Date, settings: AppSettings, calendar: Calendar = .current) {
        for kind in ReminderKind.allCases {
            restart(kind, now: now, settings: settings, calendar: calendar)
        }
    }

    /// Begins a fresh countdown for `kind` from `now` (or clears it if the reminder is off).
    public mutating func restart(_ kind: ReminderKind, now: Date, settings: AppSettings, calendar: Calendar = .current) {
        let config = settings[kind]
        guard config.enabled, var due = Self.nextFire(from: now, interval: config.interval, schedule: settings.schedule, calendar: calendar) else {
            nextDue[kind] = nil
            return
        }
        let others = Array(nextDue.filter { $0.key != kind }.values)
        let collides = { (date: Date) in others.contains { abs($0.timeIntervalSince(date)) < Self.collisionWindow } }
        if collides(due) {
            // Push back by half the interval (at most 30 min), then in small steps until the slot is free.
            // Near the end of the window, pull it a little earlier instead. Never leave the window or
            // go into the past; if nothing fits, a shared slot beats a lost reminder.
            let window = settings.schedule.currentWindow(at: due, calendar: calendar)
            let earliest = max(now, window?.start ?? now)
            let latest = window?.end ?? .distantFuture
            let first = min(config.interval / 2, 30 * 60)
            let later = (0..<12).map { due.addingTimeInterval(first + Double($0) * Self.collisionWindow) }
            let earlier = (1...6).map { due.addingTimeInterval(-Double($0) * Self.collisionWindow) }
            if let free = (later + earlier).first(where: { $0 > earliest && $0 < latest && !collides($0) }) { due = free }
        }
        nextDue[kind] = due
    }

    public mutating func snooze(_ kind: ReminderKind, now: Date, settings: AppSettings) {
        guard settings[kind].enabled else { return }
        nextDue[kind] = now.addingTimeInterval(TimeInterval(max(1, settings[kind].snoozeMinutes) * 60))
    }

    /// Moves reminders that are due within `delay` to `now + delay`, so held reminders don't
    /// pop the instant DND ends or the user sits back down. Stale ones restart instead.
    public mutating func deferOverdue(now: Date, by delay: TimeInterval, settings: AppSettings, calendar: Calendar = .current) {
        // Fixed order (not dictionary order) so the stagger always pushes the same reminder back.
        for kind in ReminderKind.allCases {
            guard let due = nextDue[kind], due < now.addingTimeInterval(delay) else { continue }
            if !restartIfStale(kind, due: due, now: now, settings: settings, calendar: calendar) {
                nextDue[kind] = now.addingTimeInterval(delay)
            }
        }
    }

    /// The user is back after `awayFor` seconds. Being away from the desk already rested the eyes
    /// and got the legs moving, so a long enough absence restarts those countdowns; a held water
    /// reminder fires shortly after.
    public mutating func userReturned(awayFor: TimeInterval, now: Date, settings: AppSettings, calendar: Calendar = .current) {
        if awayFor >= TimeInterval(max(1, settings.awayThresholdMinutes) * 60) {
            for kind in [ReminderKind.stretch, .eyes, .walk] {
                restart(kind, now: now, settings: settings, calendar: calendar)
            }
        }
        deferOverdue(now: now, by: 60, settings: settings, calendar: calendar)
    }

    /// Advances the clock. Returns the reminders to deliver now (already rescheduled).
    public mutating func tick(now: Date, settings: AppSettings, dndActive: Bool, userAway: Bool, calendar: Calendar = .current) -> [ReminderKind] {
        var fire: [ReminderKind] = []
        for kind in ReminderKind.allCases {
            guard settings[kind].enabled else { nextDue[kind] = nil; continue }
            guard let due = nextDue[kind] else {
                // Just enabled, or nothing was schedulable before (e.g. no active weekdays).
                restart(kind, now: now, settings: settings, calendar: calendar)
                continue
            }
            guard now >= due else { continue }
            if restartIfStale(kind, due: due, now: now, settings: settings, calendar: calendar) { continue }
            if dndActive || userAway { continue } // held until unblocked

            fire.append(kind)
            restart(kind, now: now, settings: settings, calendar: calendar)
        }
        return fire
    }

    /// A due reminder is stale when the window it belonged to has closed: either we're outside
    /// active hours now, or it was due before the current window opened (slept through it).
    /// Stale reminders start a fresh countdown. Returns whether that happened.
    private mutating func restartIfStale(_ kind: ReminderKind, due: Date, now: Date, settings: AppSettings, calendar: Calendar) -> Bool {
        let schedule = settings.schedule
        let windowClosed = !schedule.isActive(at: now, calendar: calendar)
        let fromEarlierWindow = schedule.currentWindow(at: now, calendar: calendar).map { due < $0.start } ?? false
        guard windowClosed || fromEarlierWindow else { return false }
        restart(kind, now: now, settings: settings, calendar: calendar)
        return true
    }

    /// When a countdown of `interval` started at `now` should fire, honouring active hours.
    /// Returns nil when the schedule has no active days.
    public static func nextFire(from now: Date, interval: TimeInterval, schedule: ActiveSchedule, calendar: Calendar = .current) -> Date? {
        guard schedule.isEnabled else { return now.addingTimeInterval(interval) }
        // An interval that can't fit inside a window at all fires mid-window instead.
        let windowLength = TimeInterval(schedule.windowMinutes * 60)
        let step = interval < windowLength ? interval : windowLength / 2
        guard var start = schedule.nextActiveStart(after: now, calendar: calendar) else { return nil }
        var candidate = start.addingTimeInterval(step)
        for _ in 0..<8 {
            guard let window = schedule.currentWindow(at: start, calendar: calendar) else { return nil }
            if candidate < window.end { return candidate }
            guard let next = schedule.nextActiveStart(after: window.end, calendar: calendar) else { return nil }
            // Back-to-back windows (e.g. all-day, every day) keep counting; a gap restarts the countdown.
            if next > window.end { candidate = next.addingTimeInterval(step) }
            start = next
        }
        return nil
    }
}
