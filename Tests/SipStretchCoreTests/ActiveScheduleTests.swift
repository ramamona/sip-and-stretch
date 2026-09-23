import Foundation
import Testing
@testable import SipStretchCore

@Suite struct ActiveScheduleTests {
    let cal = calendar()
    let workday = ActiveSchedule() // Mon–Fri 9:00–18:00

    @Test func daytimeWindow() {
        #expect(workday.isActive(at: at(2026, 9, 21, 9, 0), calendar: cal))
        #expect(workday.isActive(at: at(2026, 9, 21, 17, 59), calendar: cal))
        #expect(!workday.isActive(at: at(2026, 9, 21, 18, 0), calendar: cal), "end is exclusive")
        #expect(!workday.isActive(at: at(2026, 9, 21, 8, 59), calendar: cal))
        #expect(!workday.isActive(at: at(2026, 9, 26, 12, 0), calendar: cal), "Saturday is off")
    }

    @Test func disabledScheduleIsAlwaysActive() {
        var s = workday
        s.isEnabled = false
        #expect(s.isActive(at: at(2026, 9, 26, 3, 0), calendar: cal))
        #expect(s.nextActiveStart(after: at(2026, 9, 26, 3, 0), calendar: cal) == at(2026, 9, 26, 3, 0))
        #expect(s.currentWindow(at: at(2026, 9, 26, 3, 0), calendar: cal) == nil)
    }

    @Test func overnightWindowBelongsToStartDay() {
        // Friday only, 22:00 → 02:00.
        let s = ActiveSchedule(startMinute: 22 * 60, endMinute: 2 * 60, weekdays: [6])
        #expect(s.isActive(at: at(2026, 9, 25, 23, 0), calendar: cal))
        #expect(s.isActive(at: at(2026, 9, 26, 1, 30), calendar: cal), "Saturday 01:30 is Friday's window")
        #expect(!s.isActive(at: at(2026, 9, 26, 2, 0), calendar: cal))
        #expect(!s.isActive(at: at(2026, 9, 26, 23, 0), calendar: cal), "Saturday itself is off")
        #expect(!s.isActive(at: at(2026, 9, 25, 1, 0), calendar: cal), "Friday 01:00 belongs to Thursday")

        let window = s.currentWindow(at: at(2026, 9, 26, 1, 0), calendar: cal)
        #expect(window == DateInterval(start: at(2026, 9, 25, 22, 0), end: at(2026, 9, 26, 2, 0)))
        #expect(s.windowMinutes == 240)
    }

    @Test func allDayWindow() {
        let s = ActiveSchedule(startMinute: 0, endMinute: 0, weekdays: [2])
        #expect(s.isAllDay)
        #expect(s.isActive(at: at(2026, 9, 21, 0, 0), calendar: cal))
        #expect(s.isActive(at: at(2026, 9, 21, 23, 59), calendar: cal))
        #expect(!s.isActive(at: at(2026, 9, 22, 0, 0), calendar: cal))
        #expect(s.nextActiveStart(after: at(2026, 9, 22, 10, 0), calendar: cal) == at(2026, 9, 28, 0, 0))
    }

    @Test func nextActiveStart() {
        #expect(workday.nextActiveStart(after: at(2026, 9, 21, 7, 0), calendar: cal) == at(2026, 9, 21, 9, 0))
        #expect(workday.nextActiveStart(after: at(2026, 9, 21, 12, 0), calendar: cal) == at(2026, 9, 21, 12, 0), "already active")
        #expect(workday.nextActiveStart(after: at(2026, 9, 21, 18, 0), calendar: cal) == at(2026, 9, 22, 9, 0))
        #expect(workday.nextActiveStart(after: at(2026, 9, 25, 18, 30), calendar: cal) == at(2026, 9, 28, 9, 0), "Friday evening → Monday")

        var none = workday
        none.weekdays = []
        #expect(none.nextActiveStart(after: at(2026, 9, 21, 7, 0), calendar: cal) == nil)
    }

    @Test func windowsSurviveDaylightSavingChange() {
        // US spring-forward: 2026-03-08 02:00 → 03:00. A 01:00–04:00 window is only 2 real hours long.
        let ny = calendar("America/New_York")
        let s = ActiveSchedule(startMinute: 60, endMinute: 240, weekdays: [1])
        let window = s.currentWindow(at: at(2026, 3, 8, 1, 30, ny), calendar: ny)
        #expect(window?.duration == TimeInterval(2 * 3600))
        #expect(s.isActive(at: at(2026, 3, 8, 3, 30, ny), calendar: ny))
        #expect(!s.isActive(at: at(2026, 3, 8, 4, 0, ny), calendar: ny))
    }

    @Test func summaries() {
        #expect(workday.summary(calendar: cal).hasPrefix("Mon–Fri · "))
        #expect(ActiveSchedule.weekdaySummary([1, 7], calendar: cal) == "Weekends")
        #expect(ActiveSchedule.weekdaySummary(Set(1...7), calendar: cal) == "Every day")
        #expect(ActiveSchedule.weekdaySummary([2, 4], calendar: cal) == "Mon, Wed")
        #expect(ActiveSchedule(isEnabled: false).summary(calendar: cal) == "Around the clock")
    }
}
