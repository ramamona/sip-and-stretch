import Foundation
@testable import SipStretchCore

/// Fixed Gregorian calendar so tests don't depend on the machine's locale or time zone.
func calendar(_ zone: String = "Europe/Berlin") -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: zone)!
    cal.locale = Locale(identifier: "en_US_POSIX")
    return cal
}

/// 2026-09-21 is a Monday, 2026-09-25 a Friday, 2026-09-26 a Saturday.
func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ cal: Calendar = calendar()) -> Date {
    cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

func minutes(_ m: Double) -> TimeInterval { m * 60 }

/// Deterministic RNG for content-picking tests.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
