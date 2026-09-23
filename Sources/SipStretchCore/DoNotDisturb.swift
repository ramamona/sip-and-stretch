import Foundation

/// App-level Do Not Disturb. While active, due reminders wait instead of firing.
public enum DNDState: Codable, Equatable, Sendable {
    case off
    case until(Date)
    case indefinitely

    public func isActive(at date: Date) -> Bool {
        switch self {
        case .off: false
        case .until(let end): date < end
        case .indefinitely: true
        }
    }

    /// A timed DND that has run out becomes `.off`.
    public func normalized(at date: Date) -> DNDState {
        if case .until(let end) = self, end <= date { return .off }
        return self
    }

    public var endDate: Date? {
        if case .until(let end) = self { return end }
        return nil
    }
}

public enum DNDPreset: String, CaseIterable, Identifiable, Sendable {
    case thirtyMinutes, oneHour, twoHours, untilTomorrow, indefinitely

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .thirtyMinutes: "30 minutes"
        case .oneHour: "1 hour"
        case .twoHours: "2 hours"
        case .untilTomorrow: "Until tomorrow"
        case .indefinitely: "Until I turn it off"
        }
    }

    public func state(from now: Date, schedule: ActiveSchedule, calendar: Calendar = .current) -> DNDState {
        switch self {
        case .thirtyMinutes: return .until(now.addingTimeInterval(30 * 60))
        case .oneHour: return .until(now.addingTimeInterval(60 * 60))
        case .twoHours: return .until(now.addingTimeInterval(2 * 60 * 60))
        case .indefinitely: return .indefinitely
        case .untilTomorrow:
            return .until(Self.tomorrowMorning(after: now, schedule: schedule, calendar: calendar))
        }
    }

    /// When "tomorrow" begins: the first active-hours window that opens on a later day,
    /// or 8:00 AM tomorrow when active hours are off or all-day.
    /// The small hours still count as "tonight": at 00:30, tomorrow means this morning.
    static func tomorrowMorning(after now: Date, schedule: ActiveSchedule, calendar: Calendar) -> Date {
        let usesWindows = schedule.isEnabled && !schedule.isAllDay
        let anchor = usesWindows ? schedule.currentWindow(at: now, calendar: calendar)?.start : nil
        let today = calendar.startOfDay(for: anchor ?? now.addingTimeInterval(-6 * 3600))
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(86_400)
        let fallback = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        guard usesWindows else { return fallback }
        // At midnight we may still be inside tonight's overnight window; skip past it.
        let searchFrom = schedule.currentWindow(at: tomorrow, calendar: calendar)?.end ?? tomorrow
        return schedule.nextActiveStart(after: searchFrom, calendar: calendar) ?? fallback
    }
}
