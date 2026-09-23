import Foundation
import Testing
@testable import SipStretchCore

@Suite struct SettingsTests {
    @Test func roundTrips() throws {
        var s = AppSettings()
        s.personality = .pirate
        s.schedule.weekdays = [1, 7]
        s.stretchAreas = [.eyes]
        let data = try JSONEncoder().encode(s)
        #expect(AppSettings.decode(from: data) == s)
    }

    @Test func partialJSONKeepsUserChoicesAndFillsDefaults() {
        // As if written by an older version that had no `theme` and no `water.snoozeMinutes`.
        let json = #"{"personality":"zen","water":{"enabled":false,"intervalMinutes":30,"sound":"pop"},"futureKey":1}"#
        let s = AppSettings.decode(from: Data(json.utf8))
        #expect(s.personality == .zen)
        #expect(s.water.enabled == false)
        #expect(s.water.intervalMinutes == 30)
        #expect(s.water.snoozeMinutes == 10)
        #expect(s.theme == .ocean)
        #expect(s.stretch == AppSettings().stretch)
    }

    @Test func garbageFallsBackToDefaults() {
        #expect(AppSettings.decode(from: Data("not json".utf8)) == AppSettings())
        #expect(AppSettings.decode(from: Data(#"{"personality":"klingon"}"#.utf8)) == AppSettings())
    }

    @Test func defaultGoalIsThreeLitresAndDrivesGlassCount() {
        var s = AppSettings()
        #expect(s.dailyGoalML == 3000)
        #expect(s.dailyWaterGoal == 12)
        #expect(s.volumeString(milliliters: s.dailyGoalML) == "3 L")
        s.glassSizeML = 400
        #expect(s.dailyWaterGoal == 8, "rounds up: 3000 / 400 = 7.5")
        s.dailyGoalML = 2250
        s.glassSizeML = 250
        #expect(s.dailyWaterGoal == 9)
    }

    @Test func volumeFormatting() {
        var s = AppSettings()
        #expect(s.volumeString(glasses: 3) == "750 ml")
        #expect(s.volumeString(glasses: 6).hasSuffix(" L"))
        s.useOunces = true
        #expect(s.volumeString(glasses: 1) == "8 oz")
    }

    @Test func subscriptReadsAndWritesPerKind() {
        var s = AppSettings()
        s[.stretch].intervalMinutes = 25
        #expect(s.stretch.intervalMinutes == 25)
        s[.eyes].enabled = false
        s[.walk].snoozeMinutes = 7
        #expect(!s.eyes.enabled && s.walk.snoozeMinutes == 7)
        #expect(s[.water].sound == .bottle)
    }
}

@Suite struct DNDTests {
    let cal = calendar()

    @Test func timedDNDExpires() {
        let now = at(2026, 9, 21, 10)
        let state = DNDPreset.oneHour.state(from: now, schedule: ActiveSchedule(), calendar: cal)
        #expect(state.isActive(at: now.addingTimeInterval(3599)))
        #expect(!state.isActive(at: now.addingTimeInterval(3600)))
        #expect(state.normalized(at: now.addingTimeInterval(3600)) == .off)
        #expect(DNDState.indefinitely.isActive(at: .distantFuture))
        #expect(!DNDState.off.isActive(at: now))
    }

    @Test func untilTomorrowUsesNextActiveWindow() {
        let schedule = ActiveSchedule()
        // Monday → Tuesday 9:00.
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 21, 15), schedule: schedule, calendar: cal) == .until(at(2026, 9, 22, 9)))
        // Friday → Monday 9:00 (the weekend is already quiet).
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 25, 15), schedule: schedule, calendar: cal) == .until(at(2026, 9, 28, 9)))
        // Active hours off → 8:00 tomorrow.
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 25, 15), schedule: ActiveSchedule(isEnabled: false), calendar: cal) == .until(at(2026, 9, 26, 8)))
    }

    @Test func untilTomorrowAfterMidnightMeansThisMorning() {
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 22, 0, 30), schedule: ActiveSchedule(), calendar: cal) == .until(at(2026, 9, 22, 9)))
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 22, 0, 30), schedule: ActiveSchedule(isEnabled: false), calendar: cal) == .until(at(2026, 9, 22, 8)))
        let night = ActiveSchedule(startMinute: 22 * 60, endMinute: 2 * 60, weekdays: Set(1...7))
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 22, 1), schedule: night, calendar: cal) == .until(at(2026, 9, 22, 22)))
    }

    @Test func untilTomorrowSkipsTonightsOvernightWindow() {
        let night = ActiveSchedule(startMinute: 22 * 60, endMinute: 2 * 60, weekdays: Set(1...7))
        #expect(DNDPreset.untilTomorrow.state(from: at(2026, 9, 21, 23), schedule: night, calendar: cal) == .until(at(2026, 9, 22, 22)))
    }

    @Test func codableRoundTrip() throws {
        for state in [DNDState.off, .indefinitely, .until(at(2026, 9, 21, 10))] {
            let data = try JSONEncoder().encode(state)
            #expect(try JSONDecoder().decode(DNDState.self, from: data) == state)
        }
    }
}
