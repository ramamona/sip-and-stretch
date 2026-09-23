import Foundation

/// The flavours of stretch break Drip mixes in, so they don't all feel the same.
public enum StretchFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case guided, roulette, breathing, challenge, posture

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .guided: "Guided stretches"
        case .roulette: "Stretch roulette"
        case .breathing: "Box breathing"
        case .challenge: "Mini challenge"
        case .posture: "Posture check"
        }
    }

    public var emoji: String {
        switch self {
        case .guided: "🧘"
        case .roulette: "🎰"
        case .breathing: "🫁"
        case .challenge: "💪"
        case .posture: "🪑"
        }
    }
}

/// A tiny desk workout: either a rep count (tap to count) or a timed hold.
public struct Challenge: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    /// Reps to tap through; 0 means it's a timed hold of `seconds`.
    public let reps: Int
    public let seconds: Int
    public let tip: String

    public var isTimed: Bool { reps == 0 }

    public static let all: [Challenge] = [
        Challenge(id: "desk-squats", name: "Desk Squats", emoji: "🏋️", reps: 10, seconds: 0, tip: "Stand, sit back like there's a chair, rise. Knees over toes."),
        Challenge(id: "calf-raises", name: "Calf Raises", emoji: "🦶", reps: 15, seconds: 0, tip: "Hold the desk, rise onto your toes, lower slowly."),
        Challenge(id: "wall-sit", name: "Wall Sit", emoji: "🧱", reps: 0, seconds: 30, tip: "Back flat on a wall, thighs as level as feels okay. Breathe."),
        Challenge(id: "desk-pushups", name: "Desk Push-ups", emoji: "🙌", reps: 8, seconds: 0, tip: "Hands on a sturdy desk edge, body straight, chest to the desk."),
        Challenge(id: "arm-circles", name: "Arm Circles", emoji: "🌀", reps: 20, seconds: 0, tip: "Arms out wide, small circles. Switch direction halfway."),
        Challenge(id: "march", name: "March in Place", emoji: "🥁", reps: 0, seconds: 40, tip: "Knees up, arms swinging. Bonus points for humming a marching tune."),
        Challenge(id: "shoulder-shrugs", name: "Shoulder Shrugs", emoji: "🤷", reps: 12, seconds: 0, tip: "Ears up to the shoulders, hold a beat, drop them all the way down."),
        Challenge(id: "chair-plank", name: "Chair Plank", emoji: "🪵", reps: 0, seconds: 20, tip: "Hands on a steady chair seat or desk, body in one line. No sagging."),
        Challenge(id: "heel-toe", name: "Heel-Toe Rocks", emoji: "🎢", reps: 16, seconds: 0, tip: "Seated or standing: rock heels up, then toes up. Easy rhythm."),
        Challenge(id: "glute-squeeze", name: "Secret Glute Squeeze", emoji: "🍑", reps: 10, seconds: 0, tip: "Squeeze for three seconds, release. Nobody in the meeting will know."),
    ]
}

/// What a nudge card walks you through.
public enum BreakActivity: Equatable, Sendable {
    case drink
    case guided([Stretch])
    case roulette(BodyArea, [Stretch])
    case breathing(cycles: Int)
    case challenge(Challenge)
    case postureCheck([String])
    case eyeRest(seconds: Int, tip: String)
    case walk(idea: String)
}

public enum BreakPlanner {
    public static let postureItems = [
        "🦶 Feet flat on the floor",
        "🪑 Lower back against the chair",
        "🖥️ Top of the screen at eye level",
        "🤷 Shoulders down, away from your ears",
        "💪 Elbows at about 90°, close to your sides",
        "🐢 Head stacked over shoulders, not poking forward",
        "⌨️ Wrists straight and floating, not bent up",
    ]

    public static let eyeTips = [
        "Find the farthest thing you can see (out a window is best) and just look at it.",
        "Look at something about 6 metres (20 feet) away and let your eyes go soft.",
        "Gaze at the horizon, a tree, a rooftop, or the far end of the room.",
        "Look far away and blink slowly a few times. Screens make us forget to blink.",
        "Pick a distant object and trace its outline with your eyes.",
    ]

    public static let walkIdeas = [
        "Refill your water at the farthest tap in the building. Two birds, one bottle.",
        "Take the stairs: one floor up, one floor down.",
        "Walk a lap of your home or office and find something you've never noticed.",
        "Step outside for five minutes of daylight. Your body clock will thank you.",
        "Take your next call as a walk-and-talk.",
        "Walk to a window, look outside, walk back the long way.",
        "Put on one song and walk until it ends.",
        "Go say hi to a coworker, a plant, or a pet in person.",
        "Loop the block. Bonus points for spotting a dog.",
        "Make a cup of tea the slow way: walk while the kettle boils.",
    ]

    /// Decides what a break for `kind` will look like. Pass a seeded generator in tests.
    public static func plan<G: RandomNumberGenerator>(
        _ kind: ReminderKind, settings: AppSettings, avoiding recent: [String] = [], using rng: inout G
    ) -> BreakActivity {
        switch kind {
        case .water:
            return .drink
        case .eyes:
            return .eyeRest(seconds: 20, tip: eyeTips.randomElement(using: &rng) ?? eyeTips[0])
        case .walk:
            return .walk(idea: walkIdeas.randomElement(using: &rng) ?? walkIdeas[0])
        case .stretch:
            // Guided stretches are the staple, so they're twice as likely as each novelty format.
            let enabled = StretchFormat.allCases.filter(settings.stretchFormats.contains)
            let pool = enabled.isEmpty ? [.guided] : enabled + (enabled.contains(.guided) ? [.guided] : [])
            let count = max(1, settings.stretchesPerBreak)
            switch pool.randomElement(using: &rng) ?? .guided {
            case .guided:
                return .guided(StretchLibrary.pick(count: count, areas: settings.stretchAreas, avoiding: recent, using: &rng))
            case .roulette:
                let areas = settings.stretchAreas.isEmpty ? BodyArea.allCases : BodyArea.allCases.filter(settings.stretchAreas.contains)
                let area = areas.randomElement(using: &rng) ?? .neck
                return .roulette(area, StretchLibrary.pick(count: count, areas: [area], avoiding: recent, using: &rng))
            case .breathing:
                return .breathing(cycles: 4)
            case .challenge:
                return .challenge(Challenge.all.randomElement(using: &rng) ?? Challenge.all[0])
            case .posture:
                return .postureCheck(Array(postureItems.shuffled(using: &rng).prefix(4)))
            }
        }
    }

    public static func plan(_ kind: ReminderKind, settings: AppSettings, avoiding recent: [String] = []) -> BreakActivity {
        var rng = SystemRandomNumberGenerator()
        return plan(kind, settings: settings, avoiding: recent, using: &rng)
    }
}
