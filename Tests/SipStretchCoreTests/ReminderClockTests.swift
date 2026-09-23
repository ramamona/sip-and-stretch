import Foundation
import Testing
@testable import SipStretchCore

@Suite struct ReminderClockTests {
    let cal = calendar()
    /// Water + stretch hourly, Mon–Fri 9–18 (eyes and walk off to keep timelines readable).
    var settings: AppSettings = {
        var s = AppSettings()
        s.eyes.enabled = false
        s.walk.enabled = false
        return s
    }()

    // MARK: nextFire

    @Test func midWindowCountsDownNormally() {
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 10, 0), interval: minutes(60), schedule: settings.schedule, calendar: cal)
        #expect(next == at(2026, 9, 21, 11, 0))
    }

    @Test func crossingWindowEndMovesToNextDayPlusInterval() {
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 17, 30), interval: minutes(60), schedule: settings.schedule, calendar: cal)
        #expect(next == at(2026, 9, 22, 10, 0))
    }

    @Test func beforeWindowCountsFromWindowStart() {
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 8, 30), interval: minutes(60), schedule: settings.schedule, calendar: cal)
        #expect(next == at(2026, 9, 21, 10, 0))
    }

    @Test func weekendSkipsToMonday() {
        let next = ReminderClock.nextFire(from: at(2026, 9, 25, 17, 45), interval: minutes(30), schedule: settings.schedule, calendar: cal)
        #expect(next == at(2026, 9, 28, 9, 30))
    }

    @Test func disabledScheduleIsPlainInterval() {
        let s = ActiveSchedule(isEnabled: false)
        let next = ReminderClock.nextFire(from: at(2026, 9, 26, 3, 0), interval: minutes(45), schedule: s, calendar: cal)
        #expect(next == at(2026, 9, 26, 3, 45))
    }

    @Test func intervalLongerThanWindowFiresMidWindow() {
        let short = ActiveSchedule(startMinute: 9 * 60, endMinute: 10 * 60)
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 7, 0), interval: minutes(180), schedule: short, calendar: cal)
        #expect(next == at(2026, 9, 21, 9, 30))
    }

    @Test func backToBackAllDayWindowsKeepCounting() {
        let always = ActiveSchedule(startMinute: 0, endMinute: 0, weekdays: Set(1...7))
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 23, 30), interval: minutes(60), schedule: always, calendar: cal)
        #expect(next == at(2026, 9, 22, 0, 30), "midnight is not a gap")
    }

    @Test func noActiveDaysMeansNoReminder() {
        let never = ActiveSchedule(weekdays: [])
        #expect(ReminderClock.nextFire(from: at(2026, 9, 21, 10, 0), interval: minutes(60), schedule: never, calendar: cal) == nil)
    }

    @Test func overnightWindowCountdown() {
        let night = ActiveSchedule(startMinute: 22 * 60, endMinute: 2 * 60, weekdays: Set(1...7))
        #expect(ReminderClock.nextFire(from: at(2026, 9, 21, 23, 30), interval: minutes(60), schedule: night, calendar: cal) == at(2026, 9, 22, 0, 30))
        #expect(ReminderClock.nextFire(from: at(2026, 9, 22, 1, 30), interval: minutes(60), schedule: night, calendar: cal) == at(2026, 9, 22, 23, 0))
    }

    // MARK: tick

    @Test func startStaggersStretchAfterWater() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal)
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 10, 0))
        #expect(clock.nextDue[.stretch] == at(2026, 9, 21, 10, 30))
    }

    @Test func firesWhenDueAndReschedules() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal)
        #expect(clock.tick(now: at(2026, 9, 21, 9, 59), settings: settings, dndActive: false, userAway: false, calendar: cal).isEmpty)
        let fired = clock.tick(now: at(2026, 9, 21, 10, 0), settings: settings, dndActive: false, userAway: false, calendar: cal)
        #expect(fired == [.water])
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 11, 0))
    }

    @Test func holdsDuringDNDThenFiresAfterGrace() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal)
        #expect(clock.tick(now: at(2026, 9, 21, 10, 5), settings: settings, dndActive: true, userAway: false, calendar: cal).isEmpty)
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 10, 0), "held, not dropped")

        // DND ends at 10:20: held reminders get a one-minute grace period.
        clock.deferOverdue(now: at(2026, 9, 21, 10, 20), by: 60, settings: settings, calendar: cal)
        #expect(clock.tick(now: at(2026, 9, 21, 10, 20).addingTimeInterval(30), settings: settings, dndActive: false, userAway: false, calendar: cal).isEmpty)
        #expect(clock.tick(now: at(2026, 9, 21, 10, 21), settings: settings, dndActive: false, userAway: false, calendar: cal) == [.water])
    }

    @Test func heldReminderRollsOverWhenWindowCloses() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 16, 0), settings: settings, calendar: cal)
        _ = clock.tick(now: at(2026, 9, 21, 17, 10), settings: settings, dndActive: true, userAway: false, calendar: cal)
        let fired = clock.tick(now: at(2026, 9, 21, 18, 5), settings: settings, dndActive: false, userAway: false, calendar: cal)
        #expect(fired.isEmpty, "never fire outside active hours")
        #expect(clock.nextDue[.water] == at(2026, 9, 22, 10, 0))
    }

    @Test func staleReminderAfterSleepRestartsInsteadOfFiring() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 17, 0), settings: settings, calendar: cal) // water due 18:00 → moved to Tue 10:00
        clock.snooze(.water, now: at(2026, 9, 21, 17, 45), settings: settings)       // due 17:55
        // Mac sleeps at 17:50 and wakes Tuesday 9:05: the 17:55 reminder is from yesterday's window.
        let fired = clock.tick(now: at(2026, 9, 22, 9, 5), settings: settings, dndActive: false, userAway: false, calendar: cal)
        #expect(fired.isEmpty)
        #expect(clock.nextDue[.water] == at(2026, 9, 22, 10, 5))
    }

    @Test func awayHoldsAndReturnCountsAsStretch() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal) // water 10:00, stretch 10:30
        #expect(clock.tick(now: at(2026, 9, 21, 10, 40), settings: settings, dndActive: false, userAway: true, calendar: cal).isEmpty)

        clock.userReturned(awayFor: minutes(20), now: at(2026, 9, 21, 10, 45), settings: settings, calendar: cal)
        #expect(clock.nextDue[.stretch] == at(2026, 9, 21, 11, 45), "walking away was the stretch")
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 10, 46), "water catches up a minute later")
    }

    @Test func shortAbsenceDoesNotCountAsStretch() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal)
        clock.userReturned(awayFor: minutes(1), now: at(2026, 9, 21, 9, 30), settings: settings, calendar: cal)
        #expect(clock.nextDue[.stretch] == at(2026, 9, 21, 10, 30))
    }

    @Test func staggerSurvivesOvernightRollover() {
        // Regression: both countdowns used to roll over to Tuesday 10:00 and fire together all day.
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: settings, calendar: cal)
        var fired: [Date: [ReminderKind]] = [:]
        var now = at(2026, 9, 21, 9, 0)
        while now < at(2026, 9, 22, 13, 0) {
            let kinds = clock.tick(now: now, settings: settings, dndActive: false, userAway: false, calendar: cal)
            if !kinds.isEmpty { fired[now] = kinds }
            now.addTimeInterval(60)
        }
        #expect(fired.values.allSatisfy { $0.count == 1 }, "water and stretch never share a tick")
        #expect(fired[at(2026, 9, 22, 10, 0)] == [.water])
        #expect(fired[at(2026, 9, 22, 10, 30)] == [.stretch])
    }

    @Test func allFourRemindersNeverShareATickWithDefaults() {
        let defaults = AppSettings()
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: defaults, calendar: cal)
        var now = at(2026, 9, 21, 9, 0)
        var kindsFired = Set<ReminderKind>()
        while now < at(2026, 9, 22, 18, 0) {
            let fired = clock.tick(now: now, settings: defaults, dndActive: false, userAway: false, calendar: cal)
            #expect(fired.count <= 1, "collision at \(now): \(fired)")
            kindsFired.formUnion(fired)
            now.addTimeInterval(60)
        }
        #expect(kindsFired == Set(ReminderKind.allCases))
    }

    @Test func returningFromAwayResetsMovementAndEyes() {
        var all = AppSettings()
        all.walk.intervalMinutes = 90
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: all, calendar: cal)
        clock.userReturned(awayFor: minutes(15), now: at(2026, 9, 21, 11, 0), settings: all, calendar: cal)
        for kind in [ReminderKind.stretch, .eyes, .walk] {
            #expect(clock.nextDue[kind]! > at(2026, 9, 21, 11, 0))
            #expect(clock.nextDue[kind]! <= at(2026, 9, 21, 11, 0).addingTimeInterval(all[kind].interval + 30 * 60))
        }
    }

    @Test func catchUpAfterDNDDoesNotReviveYesterdaysReminder() {
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 16, 0), settings: settings, calendar: cal) // water due 17:00
        // DND "until tomorrow" ends Tue 09:00; the Mac slept through Monday evening.
        clock.deferOverdue(now: at(2026, 9, 22, 9, 20), by: 60, settings: settings, calendar: cal)
        #expect(clock.nextDue[.water] == at(2026, 9, 22, 10, 20), "stale: restart, don't catch up")
        #expect(clock.tick(now: at(2026, 9, 22, 9, 21), settings: settings, dndActive: false, userAway: false, calendar: cal).isEmpty)
    }

    @Test func intervalThatFitsTheWindowIsHonoured() {
        let sixHours = ActiveSchedule(startMinute: 9 * 60, endMinute: 15 * 60)
        let next = ReminderClock.nextFire(from: at(2026, 9, 21, 9, 0), interval: minutes(240), schedule: sixHours, calendar: cal)
        #expect(next == at(2026, 9, 21, 13, 0))
    }

    @Test func snoozeAndDisable() {
        var s = settings
        var clock = ReminderClock()
        clock.start(now: at(2026, 9, 21, 9, 0), settings: s, calendar: cal)
        clock.snooze(.water, now: at(2026, 9, 21, 10, 0), settings: s)
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 10, 10))

        s.water.enabled = false
        _ = clock.tick(now: at(2026, 9, 21, 10, 1), settings: s, dndActive: false, userAway: false, calendar: cal)
        #expect(clock.nextDue[.water] == nil)

        s.water.enabled = true
        _ = clock.tick(now: at(2026, 9, 21, 10, 2), settings: s, dndActive: false, userAway: false, calendar: cal)
        #expect(clock.nextDue[.water] == at(2026, 9, 21, 11, 2), "re-enabling starts a fresh countdown")
    }
}
