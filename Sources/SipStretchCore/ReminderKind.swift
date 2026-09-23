import Foundation

public enum ReminderKind: String, Codable, CaseIterable, Identifiable, Sendable {
    // Order matters: when two reminders would collide, the later one here gets staggered.
    case water, stretch, eyes, walk

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .water: "Water"
        case .stretch: "Stretch"
        case .eyes: "Eye break"
        case .walk: "Walk"
        }
    }

    public var emoji: String {
        switch self {
        case .water: "💧"
        case .stretch: "🤸"
        case .eyes: "👀"
        case .walk: "🚶"
        }
    }

    /// SF Symbol name.
    public var symbol: String {
        switch self {
        case .water: "drop.fill"
        case .stretch: "figure.flexibility"
        case .eyes: "eye.fill"
        case .walk: "figure.walk"
        }
    }

    /// "Remind me to …"
    public var verb: String {
        switch self {
        case .water: "drink water"
        case .stretch: "stretch"
        case .eyes: "rest my eyes (20-20-20)"
        case .walk: "take a walk"
        }
    }

    /// Headlines for nudge cards; the body text comes from the personality pack.
    public var cardTitles: [String] {
        switch self {
        case .water: ["Sip o'clock!", "Hydration station!", "Refill time!", "Glug glug?", "Water break!"]
        case .stretch: ["Stretch break!", "Wiggle time!", "Unfold yourself!", "Posture patrol!", "Move it, move it!"]
        case .eyes: ["Eye break!", "Look away!", "20-20-20!", "Blink break!", "Eyes off the screen!"]
        case .walk: ["Walk break!", "Go for a wander!", "Leg day (lite)!", "Take a stroll!", "Out of the chair!"]
        }
    }

    /// XP granted when the reminder is completed.
    public var xp: Int {
        switch self {
        case .water: 10
        case .stretch: 15
        case .eyes: 5
        case .walk: 20
        }
    }
}
