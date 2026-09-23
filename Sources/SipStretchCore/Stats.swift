import Foundation

public struct DayLog: Codable, Equatable, Sendable {
    public var water = 0
    /// Completed stretch breaks (not individual stretches).
    public var stretches = 0
    public var eyeBreaks = 0
    public var walks = 0
    public var skipped = 0
    public var snoozed = 0
    /// Minutes after midnight of the day's first glass (for the Early Bird achievement).
    public var firstWaterMinute: Int?

    public init(water: Int = 0, stretches: Int = 0, skipped: Int = 0, snoozed: Int = 0, firstWaterMinute: Int? = nil) {
        self.water = water
        self.stretches = stretches
        self.skipped = skipped
        self.snoozed = snoozed
        self.firstWaterMinute = firstWaterMinute
    }

    // Hand-written so fields added in later versions decode from older data instead of failing.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        water = try c.decodeIfPresent(Int.self, forKey: .water) ?? 0
        stretches = try c.decodeIfPresent(Int.self, forKey: .stretches) ?? 0
        eyeBreaks = try c.decodeIfPresent(Int.self, forKey: .eyeBreaks) ?? 0
        walks = try c.decodeIfPresent(Int.self, forKey: .walks) ?? 0
        skipped = try c.decodeIfPresent(Int.self, forKey: .skipped) ?? 0
        snoozed = try c.decodeIfPresent(Int.self, forKey: .snoozed) ?? 0
        firstWaterMinute = try c.decodeIfPresent(Int.self, forKey: .firstWaterMinute)
    }
}

/// Everything Drip remembers about your habits. Persisted as JSON.
public struct Stats: Codable, Equatable, Sendable {
    /// Keyed by `Stats.dayKey` ("yyyy-MM-dd"). Pruned to the last `historyDays`.
    public var days: [String: DayLog] = [:]
    public var totalWater = 0
    public var totalStretches = 0
    public var totalEyeBreaks = 0
    public var totalWalks = 0
    public var totalSnoozes = 0
    public var xp = 0
    public var bestStreak = 0
    /// Achievement id → unlock date.
    public var unlocked: [String: Date] = [:]

    public static let historyDays = 400

    public init() {}

    // Hand-written so a field added in a later version never wipes someone's history on upgrade.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        days = try c.decodeIfPresent([String: DayLog].self, forKey: .days) ?? [:]
        totalWater = try c.decodeIfPresent(Int.self, forKey: .totalWater) ?? 0
        totalStretches = try c.decodeIfPresent(Int.self, forKey: .totalStretches) ?? 0
        totalEyeBreaks = try c.decodeIfPresent(Int.self, forKey: .totalEyeBreaks) ?? 0
        totalWalks = try c.decodeIfPresent(Int.self, forKey: .totalWalks) ?? 0
        totalSnoozes = try c.decodeIfPresent(Int.self, forKey: .totalSnoozes) ?? 0
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        unlocked = try c.decodeIfPresent([String: Date].self, forKey: .unlocked) ?? [:]
    }

    /// "yyyy-MM-dd" in the Gregorian calendar (whatever calendar the user's Mac uses), so keys
    /// always sort chronologically.
    public static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The day a moment counts towards. With an overnight window (say 22:00–02:00), glasses
    /// after midnight still belong to the session that started the evening before.
    public static func sessionDay(for date: Date, schedule: ActiveSchedule, calendar: Calendar = .current) -> Date {
        guard schedule.isOvernight else { return date }
        return schedule.currentWindow(at: date, calendar: calendar)?.start ?? date
    }

    /// The log for one calendar day.
    public func day(_ date: Date, calendar: Calendar = .current) -> DayLog {
        days[Self.dayKey(date, calendar: calendar)] ?? DayLog()
    }

    /// The log for the day `date` counts towards (see `sessionDay`).
    public func today(at date: Date, schedule: ActiveSchedule, calendar: Calendar = .current) -> DayLog {
        day(Self.sessionDay(for: date, schedule: schedule, calendar: calendar), calendar: calendar)
    }

    public var level: Level { Level(xp: xp) }

    // MARK: Events

    /// Adds (or with a negative `delta`, undoes) glasses. Never drops below zero.
    public mutating func logWater(_ delta: Int = 1, at date: Date, goal: Int, schedule: ActiveSchedule, calendar: Calendar = .current) {
        var applied = 0
        update(date, schedule: schedule, calendar: calendar) { log in
            applied = max(-log.water, delta)
            log.water += applied
            if log.water == 0 {
                log.firstWaterMinute = nil
            } else if applied > 0, log.firstWaterMinute == nil {
                let c = calendar.dateComponents([.hour, .minute], from: date)
                log.firstWaterMinute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }
        }
        totalWater = max(0, totalWater + applied)
        xp = max(0, xp + applied * ReminderKind.water.xp)
        refreshBestStreak(goal: goal, schedule: schedule, today: date, calendar: calendar)
    }

    /// A finished stretch break, eye break or walk. (Water goes through `logWater`.)
    public mutating func logBreak(_ kind: ReminderKind, at date: Date, schedule: ActiveSchedule, calendar: Calendar = .current) {
        switch kind {
        case .water: return
        case .stretch:
            update(date, schedule: schedule, calendar: calendar) { $0.stretches += 1 }
            totalStretches += 1
        case .eyes:
            update(date, schedule: schedule, calendar: calendar) { $0.eyeBreaks += 1 }
            totalEyeBreaks += 1
        case .walk:
            update(date, schedule: schedule, calendar: calendar) { $0.walks += 1 }
            totalWalks += 1
        }
        xp += kind.xp
    }

    public mutating func logSkip(at date: Date, schedule: ActiveSchedule, calendar: Calendar = .current) {
        update(date, schedule: schedule, calendar: calendar) { $0.skipped += 1 }
    }

    public mutating func logSnooze(at date: Date, schedule: ActiveSchedule, calendar: Calendar = .current) {
        update(date, schedule: schedule, calendar: calendar) { $0.snoozed += 1 }
        totalSnoozes += 1
    }

    /// Re-checks the best streak, e.g. after the goal or active days change.
    public mutating func refreshBestStreak(goal: Int, schedule: ActiveSchedule, today: Date, calendar: Calendar = .current) {
        bestStreak = max(bestStreak, streak(goal: goal, schedule: schedule, today: today, calendar: calendar))
    }

    private mutating func update(_ date: Date, schedule: ActiveSchedule, calendar: Calendar, _ change: (inout DayLog) -> Void) {
        let key = Self.dayKey(Self.sessionDay(for: date, schedule: schedule, calendar: calendar), calendar: calendar)
        var log = days[key] ?? DayLog()
        change(&log)
        days[key] = log
        if let cutoff = calendar.date(byAdding: .day, value: -Self.historyDays, to: date) {
            let cutoffKey = Self.dayKey(cutoff, calendar: calendar)
            days = days.filter { $0.key >= cutoffKey } // "yyyy-MM-dd" sorts chronologically
        }
    }

    // MARK: Streaks

    /// Consecutive days meeting the water goal, ending today. Today only counts once it's met,
    /// but an unmet today doesn't break the streak (the day isn't over). Days outside the active
    /// weekdays are rest days: they extend the streak if met and never break it.
    public func streak(goal: Int, schedule: ActiveSchedule, today: Date, calendar: Calendar = .current) -> Int {
        let goal = max(1, goal)
        let hasRestDays = schedule.isEnabled && !schedule.weekdays.isEmpty && schedule.weekdays.count < 7
        let session = Self.sessionDay(for: today, schedule: schedule, calendar: calendar)
        var count = day(session, calendar: calendar).water >= goal ? 1 : 0
        var cursor = calendar.startOfDay(for: session)
        for _ in 0..<Self.historyDays {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
            if day(cursor, calendar: calendar).water >= goal {
                count += 1
            } else if !(hasRestDays && !schedule.weekdays.contains(calendar.component(.weekday, from: cursor))) {
                break
            }
        }
        return count
    }

    /// Last `count` days (oldest first), for charts.
    public func recentDays(_ count: Int, endingAt today: Date, calendar: Calendar = .current) -> [(date: Date, log: DayLog)] {
        let start = calendar.startOfDay(for: today)
        return (0..<count).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: start).map { ($0, day($0, calendar: calendar)) }
        }
    }

    // MARK: Achievements

    /// Records newly earned achievements and returns them (for celebration UI).
    public mutating func unlockAchievements(goal: Int, at date: Date) -> [Achievement] {
        let fresh = Achievement.all.filter { unlocked[$0.id] == nil && $0.isEarned(self, goal) }
        for achievement in fresh { unlocked[achievement.id] = date }
        return fresh
    }
}

/// XP → level with a silly title. Each level costs a bit more than the last.
public struct Level: Equatable, Sendable {
    public let number: Int
    public let xpIntoLevel: Int
    public let xpForNextLevel: Int

    public static let titles = [
        "Dusty Cactus 🌵", "Puddle Rookie 💧", "Sip Apprentice 🥤", "Stretchy Sprout 🌱",
        "Hydro Homie 🫗", "Bendy Wizard 🧙", "Wave Rider 🏄", "Aqua Legend 🐳", "Ocean Overlord 🌊",
    ]

    public static func cost(ofLevel n: Int) -> Int { 150 + 75 * (n - 1) }

    public init(xp: Int) {
        var number = 1
        var remaining = max(0, xp)
        while remaining >= Self.cost(ofLevel: number) {
            remaining -= Self.cost(ofLevel: number)
            number += 1
        }
        self.number = number
        self.xpIntoLevel = remaining
        self.xpForNextLevel = Self.cost(ofLevel: number)
    }

    public var title: String { Self.titles[min(number, Self.titles.count) - 1] }
    public var progress: Double { Double(xpIntoLevel) / Double(xpForNextLevel) }
}
