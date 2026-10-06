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

extension ReminderKind {
    /// Headlines in a character's own voice; everyone else uses the standard `cardTitles`.
    /// Keep them to about 20 characters so they fit on one line of a card.
    public func cardTitles(for personality: Personality) -> [String] {
        switch (personality, self) {
        case (.kratos, .water): ["Drink.", "Hydrate.", "Water. Now.", "Thirst is a foe."]
        case (.kratos, .stretch): ["Rise.", "Stand and stretch.", "Unbend.", "Move."]
        case (.kratos, .eyes): ["Look away.", "Eyes to the horizon.", "Far. Twenty seconds."]
        case (.kratos, .walk): ["March.", "Stand. Walk.", "Leave the chair."]

        case (.kungFuPanda, .water): ["Water time!", "Sip, sip, hooray!", "Hydration, awesome!", "Water first!"]
        case (.kungFuPanda, .stretch): ["Champion stretch!", "Wiggle time!", "Kung fu warm-up!", "Noodle bends!"]
        case (.kungFuPanda, .eyes): ["Look far, warrior!", "Eye break!", "Eagle eyes time!"]
        case (.kungFuPanda, .walk): ["Adventure time!", "Let's stroll!", "Walk it off!"]

        case (.wukong, .water): ["Quench thy thirst!", "A sip, friend!", "Cloud refreshment!", "Drink, hero!"]
        case (.wukong, .stretch): ["Stretch, nimble one!", "Monkey moves!", "Leap and bend!"]
        case (.wukong, .eyes): ["Golden eyes up!", "Gaze far away!", "Eyes up, friend!"]
        case (.wukong, .walk): ["Wander, friend!", "Cloud-walk time!", "Journey west!"]

        case (.hulk, .water): ["HULK SAY DRINK!", "WATER NOW!", "SMASH THIRST!", "GULP GULP!"]
        case (.hulk, .stretch): ["HULK STRETCH!", "UNBEND, PUNY!", "SMASH STIFFNESS!"]
        case (.hulk, .eyes): ["LOOK FAR, PUNY!", "EYES AWAY!", "HULK EYE BREAK!"]
        case (.hulk, .walk): ["HULK WALK!", "STOMP TIME!", "LEAVE CHAIR!"]

        default: cardTitles
        }
    }
}
