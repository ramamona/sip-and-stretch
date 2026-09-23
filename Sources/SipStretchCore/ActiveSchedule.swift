import Foundation

/// "Active hours": the part of the week when reminders are allowed.
///
/// A window runs from `startMinute` to `endMinute` (minutes after midnight) on each enabled weekday.
/// - `start < end`: a normal daytime window, e.g. 9:00–18:00.
/// - `start > end`: an overnight window that belongs to the day it *starts* on,
///   e.g. Fri 22:00 → Sat 02:00 is active because Friday is enabled.
/// - `start == end`: all day.
public struct ActiveSchedule: Codable, Equatable, Sendable {
    /// When false, reminders are allowed around the clock.
    public var isEnabled = true
    public var startMinute = 9 * 60
    public var endMinute = 18 * 60
    /// `Calendar` weekday numbers: 1 = Sunday … 7 = Saturday.
    public var weekdays: Set<Int> = [2, 3, 4, 5, 6]

    public init(isEnabled: Bool = true, startMinute: Int = 9 * 60, endMinute: Int = 18 * 60, weekdays: Set<Int> = [2, 3, 4, 5, 6]) {
        self.isEnabled = isEnabled
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.weekdays = weekdays
    }

    public var isAllDay: Bool { startMinute == endMinute }
    public var isOvernight: Bool { startMinute > endMinute }

    /// Length of one window in minutes.
    public var windowMinutes: Int {
        if isAllDay { return 24 * 60 }
        return isOvernight ? 24 * 60 - startMinute + endMinute : endMinute - startMinute
    }

    public func isActive(at date: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return true }
        let parts = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let weekday = parts.weekday ?? 1
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if isAllDay { return weekdays.contains(weekday) }
        if !isOvernight { return weekdays.contains(weekday) && minute >= startMinute && minute < endMinute }
        let yesterday = weekday == 1 ? 7 : weekday - 1
        return (minute >= startMinute && weekdays.contains(weekday))
            || (minute < endMinute && weekdays.contains(yesterday))
    }

    /// The first moment at or after `date` when the schedule is active, or nil if no weekday is enabled.
    public func nextActiveStart(after date: Date, calendar: Calendar = .current) -> Date? {
        if isActive(at: date, calendar: calendar) { return date }
        // If `date` is inactive, activity can only resume at some window's start.
        let today = calendar.startOfDay(for: date)
        for offset in 0...7 {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: today),
                weekdays.contains(calendar.component(.weekday, from: day)),
                let start = windowStart(on: day, calendar: calendar),
                start >= date
            else { continue }
            return start
        }
        return nil
    }

    /// The window that contains `date`, or nil if the schedule is disabled or inactive at `date`.
    public func currentWindow(at date: Date, calendar: Calendar = .current) -> DateInterval? {
        guard isEnabled, isActive(at: date, calendar: calendar) else { return nil }
        // Only today's or yesterday's (overnight) window can contain `date`.
        let today = calendar.startOfDay(for: date)
        for offset in [0, -1] {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: today),
                weekdays.contains(calendar.component(.weekday, from: day)),
                let window = window(on: day, calendar: calendar),
                window.start <= date, date < window.end
            else { continue }
            return window
        }
        return nil
    }

    private func windowStart(on day: Date, calendar: Calendar) -> Date? {
        if isAllDay { return day }
        return calendar.date(bySettingHour: startMinute / 60, minute: startMinute % 60, second: 0, of: day)
    }

    /// Wall-clock window starting on `day` (DST-safe: built from calendar components, not by adding seconds).
    private func window(on day: Date, calendar: Calendar) -> DateInterval? {
        guard let start = windowStart(on: day, calendar: calendar) else { return nil }
        let endDay = isAllDay || isOvernight ? calendar.date(byAdding: .day, value: 1, to: day) : day
        guard
            let endDay,
            let end = isAllDay ? endDay : calendar.date(bySettingHour: endMinute / 60, minute: endMinute % 60, second: 0, of: endDay),
            end > start
        else { return nil }
        return DateInterval(start: start, end: end)
    }

    /// Human summary, e.g. "Mon–Fri · 9:00 AM – 6:00 PM".
    public func summary(calendar: Calendar = .current) -> String {
        guard isEnabled else { return "Around the clock" }
        guard !weekdays.isEmpty else { return "No active days" }
        let days = Self.weekdaySummary(weekdays, calendar: calendar)
        if isAllDay { return "\(days) · all day" }
        return "\(days) · \(Self.timeString(startMinute)) – \(Self.timeString(endMinute))"
    }

    public static func timeString(_ minute: Int) -> String {
        var parts = DateComponents(year: 2001, month: 1, day: 1)
        parts.hour = minute / 60
        parts.minute = minute % 60
        let date = Calendar(identifier: .gregorian).date(from: parts) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    static func weekdaySummary(_ days: Set<Int>, calendar: Calendar) -> String {
        let names = calendar.shortWeekdaySymbols // index 0 = Sunday
        if days.count == 7 { return "Every day" }
        if days == [2, 3, 4, 5, 6] { return "\(names[1])–\(names[5])" }
        if days == [1, 7] { return "Weekends" }
        // Order starting from the locale's first weekday.
        let ordered = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }.filter(days.contains)
        return ordered.map { names[$0 - 1] }.joined(separator: ", ")
    }
}
