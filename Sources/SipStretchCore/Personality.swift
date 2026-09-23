import Foundation

/// The voice Drip uses when talking to you. Every personality ships a full `MessagePack`
/// (see `Messages.swift`). Adding a new one = add a case here + a pack there.
public enum Personality: String, Codable, CaseIterable, Identifiable, Sendable {
    case cheerful, sassy, pirate, zen, dramatic, robot, grandma, gymBro

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cheerful: "Cheerful Coach"
        case .sassy: "Sassy Bestie"
        case .pirate: "Captain Hydro"
        case .zen: "Zen Master"
        case .dramatic: "Dramatic Narrator"
        case .robot: "Robo Buddy"
        case .grandma: "Grandma"
        case .gymBro: "Gym Bro"
        }
    }

    public var emoji: String {
        switch self {
        case .cheerful: "🤗"
        case .sassy: "💅"
        case .pirate: "🏴‍☠️"
        case .zen: "🪷"
        case .dramatic: "🎭"
        case .robot: "🤖"
        case .grandma: "👵"
        case .gymBro: "💪"
        }
    }

    public var tagline: String {
        switch self {
        case .cheerful: "Relentlessly positive. Believes in you."
        case .sassy: "Loves you. Judges you. Mostly loves you."
        case .pirate: "Arr! Speaks only in nautical nonsense."
        case .zen: "Calm, wise, occasionally cryptic."
        case .dramatic: "Every sip is an epic saga."
        case .robot: "BEEP. HYDRATION PROTOCOL ENGAGED."
        case .grandma: "Worries about you. Brought snacks."
        case .gymBro: "Hydrate or diedrate, bro."
        }
    }
}

/// All the lines one personality can say.
///
/// Templates may contain these placeholders, filled in by `MessagePack.render`:
/// - `{name}`: the nickname the user chose (defaults to "friend")
/// - `{left}`: glasses still to go today (only meaningful in water lines)
public struct MessagePack: Sendable {
    public let waterReminders: [String]
    public let stretchReminders: [String]
    public let waterCheers: [String]
    public let stretchCheers: [String]
    public let snoozes: [String]
    public let greetings: [String]
    public let goalReached: [String]

    public init(
        waterReminders: [String], stretchReminders: [String],
        waterCheers: [String], stretchCheers: [String],
        snoozes: [String], greetings: [String], goalReached: [String]
    ) {
        self.waterReminders = waterReminders
        self.stretchReminders = stretchReminders
        self.waterCheers = waterCheers
        self.stretchCheers = stretchCheers
        self.snoozes = snoozes
        self.greetings = greetings
        self.goalReached = goalReached
    }

    public static func render(_ template: String, name: String, left: Int) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return template
            .replacingOccurrences(of: "{name}", with: trimmed.isEmpty ? "friend" : trimmed)
            .replacingOccurrences(of: "{left}", with: String(max(0, left)))
    }
}

extension Array where Element == String {
    /// A random line that isn't `last` (when there is a choice), so Drip doesn't repeat itself.
    public func pick<G: RandomNumberGenerator>(avoiding last: String?, using rng: inout G) -> String {
        let pool = count > 1 ? filter { $0 != last } : self
        return pool.randomElement(using: &rng) ?? ""
    }

    public func pick(avoiding last: String? = nil) -> String {
        var rng = SystemRandomNumberGenerator()
        return pick(avoiding: last, using: &rng)
    }
}
