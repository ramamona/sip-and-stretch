import Foundation

// The walking 3D avatar: which character it is, how a custom character looks, and how it walks.
// Everything here is plain data (colors are 0xRRGGBB integers), so it persists as JSON with the
// rest of `AppSettings` and stays unit-testable. The SceneKit side lives in `Sources/SipStretch/Avatar`.

/// Who walks onto the screen.
public enum AvatarCharacter: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Drip, the app's water droplet, in 3D.
    case drip
    /// A customizable person: gender, skin, hair, outfit, accessories, or your own face from a photo.
    case human
    case robot
    // Fan-made homages built from simple shapes. No official art, models or audio are included.
    case kratos, kungFuPanda, wukong, hulk
    /// A 3D model file (USDZ, DAE, OBJ, SCN) the user imported.
    case model

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .drip: "Drip"
        case .human: "Custom person"
        case .robot: "Robo Buddy"
        case .kratos: "Kratos"
        case .kungFuPanda: "Kung Fu Panda"
        case .wukong: "Wukong"
        case .hulk: "Hulk"
        case .model: "My 3D model"
        }
    }

    public var emoji: String {
        switch self {
        case .drip: "💧"
        case .human: "🧑"
        case .robot: "🤖"
        case .kratos: "🪓"
        case .kungFuPanda: "🐼"
        case .wukong: "🐵"
        case .hulk: "💚"
        case .model: "🧩"
        }
    }

    public var tagline: String {
        switch self {
        case .drip: "The classic. Now with legs."
        case .human: "Pick a look, or build it from your photo."
        case .robot: "Beep-boop, now in three dimensions."
        case .kratos: "A grim warrior who takes hydration seriously."
        case .kungFuPanda: "A chubby kung fu hero. Snacks are fuel."
        case .wukong: "The mischievous Monkey King with his golden staff."
        case .hulk: "A big green smasher who jumps around."
        case .model: "Bring your own 3D model."
        }
    }

    /// Characters built into the app that are inspired by existing franchises.
    public var isFanMade: Bool {
        switch self {
        case .kratos, .kungFuPanda, .wukong, .hulk: true
        default: false
        }
    }

    /// The personality this character talks like, if it has a signature voice.
    public var voice: Personality? {
        switch self {
        case .robot: .robot
        case .kratos: .kratos
        case .kungFuPanda: .kungFuPanda
        case .wukong: .wukong
        case .hulk: .hulk
        case .drip, .human, .model: nil
        }
    }
}

/// How the custom person is built (proportions, default outfit shapes).
public enum AvatarGender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male, female, nonBinary

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .nonBinary: "Non-binary"
        }
    }
}

public enum HairStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case bald, short, long, ponytail, bun, curly, mohawk, afro

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bald: "Bald"
        case .short: "Short"
        case .long: "Long"
        case .ponytail: "Ponytail"
        case .bun: "Bun"
        case .curly: "Curly"
        case .mohawk: "Mohawk"
        case .afro: "Afro"
        }
    }
}

public enum OutfitStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case tShirt, hoodie, suit, dress, tracksuit

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .tShirt: "T-shirt"
        case .hoodie: "Hoodie"
        case .suit: "Suit"
        case .dress: "Dress"
        case .tracksuit: "Tracksuit"
        }
    }
}

public enum AvatarAccessory: String, Codable, CaseIterable, Identifiable, Sendable {
    case glasses, sunglasses, cap, headphones, scarf

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .glasses: "Glasses"
        case .sunglasses: "Sunglasses"
        case .cap: "Cap"
        case .headphones: "Headphones"
        case .scarf: "Scarf"
        }
    }

    public var emoji: String {
        switch self {
        case .glasses: "👓"
        case .sunglasses: "🕶️"
        case .cap: "🧢"
        case .headphones: "🎧"
        case .scarf: "🧣"
        }
    }
}

public enum AvatarSize: String, Codable, CaseIterable, Identifiable, Sendable {
    case small, medium, large

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }

    /// Multiplier on the avatar's on-screen size.
    public var scale: Double {
        switch self {
        case .small: 0.75
        case .medium: 1
        case .large: 1.35
        }
    }
}

public enum WalkSpeed: String, Codable, CaseIterable, Identifiable, Sendable {
    case slow, normal, fast

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }

    /// How fast the avatar walks, in points per second.
    public var pointsPerSecond: Double {
        switch self {
        case .slow: 70
        case .normal: 110
        case .fast: 180
        }
    }
}

/// Frame-rate cap while the avatar animates. The scene is paused entirely (0% CPU) while it stands still.
public enum AvatarQuality: String, Codable, CaseIterable, Identifiable, Sendable {
    case batterySaver, balanced, smooth

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .batterySaver: "Battery saver (15 fps)"
        case .balanced: "Balanced (24 fps)"
        case .smooth: "Smooth (30 fps)"
        }
    }

    public var framesPerSecond: Int {
        switch self {
        case .batterySaver: 15
        case .balanced: 24
        case .smooth: 30
        }
    }
}

/// Color presets for the custom person, plus helpers to snap a sampled color (from a photo) to them.
public enum AvatarPalette {
    public static let skinTones: [UInt32] = [0xFFE0C8, 0xF5CBA7, 0xE0AC84, 0xC68642, 0x9B6B43, 0x6B4423, 0x4A2F1B]

    /// Natural shades first, then a few fun ones.
    public static let hairColors: [UInt32] = [
        0x1B1B1B, 0x3B2417, 0x6A4326, 0x9C5A2E, 0xC9722B, 0xE8C26A, 0xA8A8A8, 0xF2F2F2,
        0x4C6FE0, 0xE05CA3, 0x2FBF8F,
    ]
    /// How many of `hairColors` count as natural when snapping a photo's hair color.
    public static let naturalHairCount = 8

    public static let outfitColors: [UInt32] = [0x4FC3F7, 0xE8505B, 0x7EE8C7, 0xC3A6FF, 0xFFB74D, 0x2F3A56, 0xF5F5F5, 0x3B3B3B]

    /// The palette entry closest to `hex` (plain RGB distance; plenty for a cartoon avatar).
    public static func nearest(to hex: UInt32, in palette: [UInt32]) -> UInt32 {
        palette.min { distance($0, hex) < distance($1, hex) } ?? hex
    }

    public static func nearestSkin(to hex: UInt32) -> UInt32 { nearest(to: hex, in: skinTones) }

    public static func nearestNaturalHair(to hex: UInt32) -> UInt32 {
        nearest(to: hex, in: Array(hairColors.prefix(naturalHairCount)))
    }

    private static func distance(_ a: UInt32, _ b: UInt32) -> Int {
        func channel(_ value: UInt32, _ shift: UInt32) -> Int { Int((value >> shift) & 0xFF) }
        return [16, 8, 0].reduce(0) { sum, shift in
            let delta = channel(a, UInt32(shift)) - channel(b, UInt32(shift))
            return sum + delta * delta
        }
    }
}

/// A 3D model file the user imported for one character. The file itself lives in Application Support.
public struct ModelSlot: Codable, Equatable, Sendable {
    public var character: AvatarCharacter
    public var fileName: String
    public var displayName: String
    /// 0, 90, 180 or 270: turn a model that faces the wrong way.
    public var rotation: Int

    public init(character: AvatarCharacter, fileName: String, displayName: String, rotation: Int = 0) {
        self.character = character
        self.fileName = fileName
        self.displayName = displayName
        self.rotation = rotation
    }
}

/// Everything about the walking avatar. Persisted inside `AppSettings`.
///
/// Note: keep every property non-optional with a default. `AppSettings.decode` merges stored JSON
/// onto the defaults' keys, and a nil optional would have no key to merge into.
public struct AvatarSettings: Codable, Equatable, Sendable {
    /// Deliver card reminders by having the avatar walk onto the screen first.
    public var walkOnScreen = true
    public var character: AvatarCharacter = .drip
    /// Talk like the chosen character (Kratos growls, the panda cracks jokes…). Off = use the personality picked in Settings.
    public var matchVoiceToCharacter = true

    // Custom person
    public var gender: AvatarGender = .nonBinary
    public var skinHex: UInt32 = AvatarPalette.skinTones[2]
    public var hairStyle: HairStyle = .short
    public var hairHex: UInt32 = AvatarPalette.hairColors[2]
    public var outfit: OutfitStyle = .tShirt
    public var topHex: UInt32 = AvatarPalette.outfitColors[0]
    public var bottomHex: UInt32 = AvatarPalette.outfitColors[5]
    public var accessories: Set<AvatarAccessory> = []

    // Photo (the cropped face lives in Application Support, never in UserDefaults)
    public var hasPhoto = false
    /// Show the photo on the custom person's face.
    public var usePhotoFace = true
    /// Bumped whenever the photo changes, so views know to reload it.
    public var photoRevision = 0

    /// Imported 3D models. Any character can have its own (a detailed Kratos for Kratos, say); the
    /// `.model` character is the one for models that don't replace a built-in character.
    /// An array rather than a dictionary: `AppSettings.decode` only keeps keys it already knows.
    public var modelSlots: [ModelSlot] = []

    // Walking
    public var size: AvatarSize = .medium
    public var speed: WalkSpeed = .normal
    /// Minutes before an unanswered reminder makes the character storm off (0 = never).
    public var patienceMinutes = 10
    public var quality: AvatarQuality = .balanced

    public init() {}

    /// The face photo should be shown (a photo exists, the user wants it, and the avatar is the custom person).
    public var showsPhotoFace: Bool { character == .human && hasPhoto && usePhotoFace }

    /// The imported model for `character`, if there is one.
    public func modelSlot(for character: AvatarCharacter) -> ModelSlot? {
        modelSlots.first { $0.character == character }
    }

    /// The imported model that replaces the built-in look of the selected character, if any.
    public var activeModel: ModelSlot? { modelSlot(for: character) }

    /// Adds, replaces or (with nil) removes the model for `character`.
    public mutating func setModel(_ slot: ModelSlot?, for character: AvatarCharacter) {
        modelSlots.removeAll { $0.character == character }
        if var slot {
            slot.character = character
            modelSlots.append(slot)
        }
    }

    /// Turns a model that faces the wrong way (0, 90, 180 or 270 degrees).
    public mutating func setModelRotation(_ degrees: Int, for character: AvatarCharacter) {
        guard let index = modelSlots.firstIndex(where: { $0.character == character }) else { return }
        modelSlots[index].rotation = ((degrees % 360) + 360) % 360
    }
}

extension AppSettings {
    /// The voice actually used for reminders: the character's own if it has one and the user wants it,
    /// otherwise the personality picked in Settings.
    public var effectivePersonality: Personality {
        if avatar.matchVoiceToCharacter, let voice = avatar.character.voice { return voice }
        return personality
    }
}

/// How a character reacts when you don't do what it asked.
public enum AvatarReaction: String, CaseIterable, Sendable {
    /// Dismissed or skipped the reminder.
    case skipped
    /// Pushed the reminder back.
    case snoozed
    /// Still waiting for an answer.
    case impatient
    /// Waited too long and gave up.
    case timedOut
}

/// When an unanswered character gets restless and when it finally storms off.
public struct PatienceTimeline: Equatable, Sendable {
    /// Seconds after the character appears at which it shows impatience, in increasing anger.
    public var grumbles: [TimeInterval]
    /// Seconds after which it gives up and leaves, or nil if it waits forever.
    public var timeout: TimeInterval?
}

extension AvatarSettings {
    /// `speedUp` compresses time so previews don't take ten minutes.
    public func patienceTimeline(speedUp: Double = 1) -> PatienceTimeline {
        guard patienceMinutes > 0 else { return PatienceTimeline(grumbles: [], timeout: nil) }
        let total = TimeInterval(patienceMinutes * 60) / max(1, speedUp)
        return PatienceTimeline(grumbles: [0.15, 0.4, 0.7].map { $0 * total }, timeout: total)
    }
}
