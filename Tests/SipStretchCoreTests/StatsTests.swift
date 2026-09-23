import Foundation
import Testing
@testable import SipStretchCore

@Suite struct StatsTests {
    let cal = calendar()
    let schedule = ActiveSchedule() // Mon–Fri

    private func drink(_ stats: inout Stats, _ glasses: Int, on date: Date, goal: Int = 2) {
        for _ in 0..<glasses { stats.logWater(at: date, goal: goal, schedule: schedule, calendar: cal) }
    }

    @Test func loggingWaterTracksTotalsXPAndFirstGlass() {
        var stats = Stats()
        drink(&stats, 3, on: at(2026, 9, 21, 7, 45))
        #expect(stats.day(at(2026, 9, 21, 12), calendar: cal).water == 3)
        #expect(stats.totalWater == 3)
        #expect(stats.xp == 30)
        #expect(stats.day(at(2026, 9, 21), calendar: cal).firstWaterMinute == 7 * 60 + 45)
    }

    @Test func undoNeverGoesNegative() {
        var stats = Stats()
        drink(&stats, 1, on: at(2026, 9, 21, 10))
        stats.logWater(-5, at: at(2026, 9, 21, 11), goal: 2, schedule: schedule, calendar: cal)
        #expect(stats.day(at(2026, 9, 21), calendar: cal).water == 0)
        #expect(stats.totalWater == 0)
        #expect(stats.xp == 0)
        #expect(stats.day(at(2026, 9, 21), calendar: cal).firstWaterMinute == nil)
    }

    @Test func streakCountsConsecutiveGoalDays() {
        var stats = Stats()
        drink(&stats, 2, on: at(2026, 9, 21, 10)) // Mon
        drink(&stats, 2, on: at(2026, 9, 22, 10)) // Tue
        drink(&stats, 2, on: at(2026, 9, 23, 10)) // Wed
        #expect(stats.streak(goal: 2, schedule: schedule, today: at(2026, 9, 23, 12), calendar: cal) == 3)
        #expect(stats.bestStreak == 3)
        // Thursday not met yet: streak is still alive.
        #expect(stats.streak(goal: 2, schedule: schedule, today: at(2026, 9, 24, 12), calendar: cal) == 3)
        // Friday with Thursday missed: broken.
        #expect(stats.streak(goal: 2, schedule: schedule, today: at(2026, 9, 25, 12), calendar: cal) == 0)
    }

    @Test func restDaysDoNotBreakStreak() {
        var stats = Stats()
        drink(&stats, 2, on: at(2026, 9, 25, 10)) // Fri
        drink(&stats, 2, on: at(2026, 9, 28, 10)) // Mon (weekend skipped)
        #expect(stats.streak(goal: 2, schedule: schedule, today: at(2026, 9, 28, 12), calendar: cal) == 2)

        var everyDay = schedule
        everyDay.weekdays = Set(1...7)
        #expect(stats.streak(goal: 2, schedule: everyDay, today: at(2026, 9, 28, 12), calendar: cal) == 1)
    }

    @Test func oldHistoryIsPruned() {
        var stats = Stats()
        drink(&stats, 1, on: at(2025, 1, 1, 10))
        drink(&stats, 1, on: at(2026, 9, 21, 10))
        #expect(stats.days.count == 1)
        #expect(stats.totalWater == 2, "lifetime totals are kept")
    }

    @Test func recentDaysAreOldestFirst() {
        var stats = Stats()
        drink(&stats, 4, on: at(2026, 9, 23, 10))
        let week = stats.recentDays(7, endingAt: at(2026, 9, 23, 15), calendar: cal)
        #expect(week.count == 7)
        #expect(week.first?.date == at(2026, 9, 17))
        #expect(week.last?.log.water == 4)
    }

    @Test func levelsGetPricierAndHaveTitles() {
        #expect(Level(xp: 0).number == 1)
        #expect(Level(xp: 0).title == "Dusty Cactus 🌵")
        #expect(Level(xp: 149).number == 1)
        #expect(Level(xp: 150).number == 2)
        #expect(Level(xp: 150 + 225).number == 3)
        #expect(Level(xp: 10_000_000).title == "Ocean Overlord 🌊")
        let mid = Level(xp: 200)
        #expect(mid.xpIntoLevel == 50 && mid.xpForNextLevel == 225)
        #expect(abs(mid.progress - 50.0 / 225.0) < 0.0001)
    }

    @Test func achievementsUnlockOnce() {
        var stats = Stats()
        #expect(stats.unlockAchievements(goal: 2, at: at(2026, 9, 21)).isEmpty)

        drink(&stats, 1, on: at(2026, 9, 21, 7, 30))
        let first = stats.unlockAchievements(goal: 2, at: at(2026, 9, 21, 7, 30)).map(\.id)
        #expect(Set(first) == ["first-sip", "early-bird"])

        drink(&stats, 1, on: at(2026, 9, 21, 9))
        #expect(stats.unlockAchievements(goal: 2, at: at(2026, 9, 21, 9)).map(\.id) == ["goal-getter"])
        #expect(stats.unlockAchievements(goal: 2, at: at(2026, 9, 21, 9)).isEmpty, "no double unlocks")

        for _ in 0..<5 { stats.logBreak(.stretch, at: at(2026, 9, 21, 15), schedule: schedule, calendar: cal) }
        #expect(stats.unlockAchievements(goal: 2, at: at(2026, 9, 21, 15)).map(\.id) == ["perfect-day"])
        #expect(stats.xp == 20 + 5 * 15)
    }

    @Test func overnightSessionsCountTowardsTheDayTheyStarted() {
        // Night owl: 22:00–06:00, Mon–Fri. Glasses after midnight belong to the evening before.
        let night = ActiveSchedule(startMinute: 22 * 60, endMinute: 6 * 60)
        var stats = Stats()
        for day in 21...25 { // Mon…Fri sessions
            for hour in [22, 23] { stats.logWater(at: at(2026, 9, day, hour), goal: 4, schedule: night, calendar: cal) }
            for hour in [1, 2] { stats.logWater(at: at(2026, 9, day + 1, hour), goal: 4, schedule: night, calendar: cal) }
        }
        #expect(stats.today(at: at(2026, 9, 22, 2), schedule: night, calendar: cal).water == 4, "Monday's session")
        #expect(stats.streak(goal: 4, schedule: night, today: at(2026, 9, 26, 3), calendar: cal) == 5)
        #expect(stats.bestStreak == 5)
    }

    @Test func dayKeysAreGregorianWhateverTheSystemCalendar() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = cal.timeZone
        #expect(Stats.dayKey(at(2026, 9, 21, 10), calendar: buddhist) == "2026-09-21")
    }

    @Test func olderSavedStatsStillDecode() throws {
        // As written by a version without totalSnoozes / bestStreak / skipped.
        let json = #"{"days":{"2026-09-21":{"water":3,"stretches":1}},"totalWater":3,"totalStretches":1,"xp":45,"unlocked":{}}"#
        let stats = try JSONDecoder().decode(Stats.self, from: Data(json.utf8))
        #expect(stats.totalWater == 3 && stats.xp == 45 && stats.totalSnoozes == 0)
        #expect(stats.day(at(2026, 9, 21, 12), calendar: cal).water == 3)
    }

    @Test func eyeBreaksAndWalksAreCountedWithTheirOwnXP() {
        var stats = Stats()
        stats.logBreak(.eyes, at: at(2026, 9, 21, 10), schedule: schedule, calendar: cal)
        stats.logBreak(.walk, at: at(2026, 9, 21, 11), schedule: schedule, calendar: cal)
        stats.logBreak(.water, at: at(2026, 9, 21, 11), schedule: schedule, calendar: cal) // water goes through logWater
        let day = stats.day(at(2026, 9, 21), calendar: cal)
        #expect(day.eyeBreaks == 1 && day.walks == 1 && day.water == 0)
        #expect(stats.totalEyeBreaks == 1 && stats.totalWalks == 1)
        #expect(stats.xp == ReminderKind.eyes.xp + ReminderKind.walk.xp)
    }

    @Test func achievementIDsAreUnique() {
        let ids = Achievement.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }
}
