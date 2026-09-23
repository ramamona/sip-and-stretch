import Foundation

public enum AlertSound: String, Codable, CaseIterable, Identifiable, Sendable {
    case none, basso, blow, bottle, frog, funk, glass, hero, morse, ping, pop, purr, sosumi, submarine, tink

    public var id: String { rawValue }

    /// Name of the built-in macOS sound (`NSSound(named:)`), nil for silence.
    public var systemName: String? { self == .none ? nil : rawValue.capitalized }

    public var displayName: String { self == .none ? "No sound" : rawValue.capitalized }
}

public enum DeliveryStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case card, notification, both

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .card: "Nudge card"
        case .notification: "System notification"
        case .both: "Card + notification"
        }
    }
}

public enum CardPosition: String, Codable, CaseIterable, Identifiable, Sendable {
    case topRight, topLeft, bottomRight, bottomLeft, center

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .topRight: "Top right"
        case .topLeft: "Top left"
        case .bottomRight: "Bottom right"
        case .bottomLeft: "Bottom left"
        case .center: "Center stage"
        }
    }
}

public enum MenuBarDisplay: String, Codable, CaseIterable, Identifiable, Sendable {
    case iconOnly, countdown, waterProgress

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .iconOnly: "Icon only"
        case .countdown: "Countdown to next reminder"
        case .waterProgress: "Glasses today (3/8)"
        }
    }
}

public enum Theme: String, Codable, CaseIterable, Identifiable, Sendable {
    case ocean, sunset, mint, grape, bubblegum

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }

    /// Gradient stops as 0xRRGGBB (light → deep). UI maps these to colors.
    public var hexStops: (UInt32, UInt32) {
        switch self {
        case .ocean: (0x4FC3F7, 0x1565C0)
        case .sunset: (0xFFB74D, 0xE8505B)
        case .mint: (0x7EE8C7, 0x0F9D76)
        case .grape: (0xC3A6FF, 0x6A3FD8)
        case .bubblegum: (0xFFA8D5, 0xE0457B)
        }
    }
}

public struct ReminderSettings: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var intervalMinutes: Int
    public var snoozeMinutes: Int
    public var sound: AlertSound

    public init(enabled: Bool = true, intervalMinutes: Int = 60, snoozeMinutes: Int = 10, sound: AlertSound) {
        self.enabled = enabled
        self.intervalMinutes = intervalMinutes
        self.snoozeMinutes = snoozeMinutes
        self.sound = sound
    }

    public var interval: TimeInterval { TimeInterval(max(1, intervalMinutes) * 60) }
}

/// Everything the user can customize. Persisted as JSON; see `AppSettings.decode(from:)`
/// for how older/partial JSON is upgraded without losing the user's choices.
public struct AppSettings: Codable, Equatable, Sendable {
    public var water = ReminderSettings(sound: .bottle)
    public var stretch = ReminderSettings(sound: .purr)
    /// 20-20-20: every 20 minutes, look 20 feet away for 20 seconds.
    public var eyes = ReminderSettings(intervalMinutes: 20, snoozeMinutes: 5, sound: .tink)
    public var walk = ReminderSettings(intervalMinutes: 120, snoozeMinutes: 15, sound: .hero)

    /// Daily water target. Glasses are derived from it (see `dailyWaterGoal`).
    public var dailyGoalML = 3000
    public var glassSizeML = 250
    public var useOunces = false

    public var stretchesPerBreak = 2
    public var stretchAreas: Set<BodyArea> = Set(BodyArea.allCases)
    /// Which kinds of stretch break Drip mixes in.
    public var stretchFormats: Set<StretchFormat> = Set(StretchFormat.allCases)

    public var schedule = ActiveSchedule()

    public var pauseWhenAway = true
    public var awayThresholdMinutes = 5
    /// Hold reminders while the camera or microphone is in use (calls, recordings).
    public var pauseDuringMeetings = true

    public var delivery: DeliveryStyle = .card
    public var cardPosition: CardPosition = .topRight
    public var menuBarDisplay: MenuBarDisplay = .countdown
    public var speakReminders = false

    public var personality: Personality = .cheerful
    public var theme: Theme = .ocean
    public var nickname = ""

    public init() {}

    public subscript(kind: ReminderKind) -> ReminderSettings {
        get {
            switch kind {
            case .water: water
            case .stretch: stretch
            case .eyes: eyes
            case .walk: walk
            }
        }
        set {
            switch kind {
            case .water: water = newValue
            case .stretch: stretch = newValue
            case .eyes: eyes = newValue
            case .walk: walk = newValue
            }
        }
    }

    /// Glasses needed to reach `dailyGoalML` (rounded up).
    public var dailyWaterGoal: Int {
        let glass = max(1, glassSizeML)
        return max(1, (dailyGoalML + glass - 1) / glass)
    }

    /// Water volume formatted in the user's unit, e.g. "1.5 L" or "51 oz".
    public func volumeString(glasses: Int) -> String {
        volumeString(milliliters: glasses * glassSizeML)
    }

    /// "3 L", "750 ml" or "101 oz".
    public func volumeString(milliliters: Int) -> String {
        let ml = Double(milliliters)
        if useOunces { return "\(Int((ml / 29.5735).rounded())) oz" }
        if ml < 1000 { return "\(Int(ml)) ml" }
        return "\((ml / 1000).formatted(.number.precision(.fractionLength(0...2)))) L"
    }

    /// Decodes settings, filling any missing keys (e.g. from an older app version) with defaults.
    /// Returns defaults if the data is unreadable, so a bad blob can never brick the app.
    public static func decode(from data: Data) -> AppSettings {
        guard
            let stored = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let defaultsData = try? JSONEncoder().encode(AppSettings()),
            let defaults = try? JSONSerialization.jsonObject(with: defaultsData) as? [String: Any],
            let merged = try? JSONSerialization.data(withJSONObject: deepMerge(defaults, stored))
        else { return AppSettings() }
        return (try? JSONDecoder().decode(AppSettings.self, from: merged)) ?? AppSettings()
    }

    private static func deepMerge(_ base: [String: Any], _ overlay: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in overlay {
            if let b = base[key] as? [String: Any], let o = value as? [String: Any] {
                result[key] = deepMerge(b, o)
            } else if base[key] != nil {
                result[key] = value // keys the current version doesn't know are dropped
            }
        }
        return result
    }
}
