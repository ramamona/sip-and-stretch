import Foundation

public enum BodyArea: String, Codable, CaseIterable, Identifiable, Sendable {
    case neck, shoulders, back, wrists, legs, eyes

    public var id: String { rawValue }

    public var displayName: String { rawValue.capitalized }

    public var emoji: String {
        switch self {
        case .neck: "🦒"
        case .shoulders: "🤷"
        case .back: "🐈"
        case .wrists: "✋"
        case .legs: "🦵"
        case .eyes: "👀"
        }
    }
}

/// One guided desk stretch. The catalogue lives in `StretchLibrary.all` (StretchLibrary+Data.swift).
public struct Stretch: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let area: BodyArea
    /// How long the guided countdown runs.
    public let seconds: Int
    /// One or two short sentences, imperative voice.
    public let steps: String

    public init(id: String, name: String, emoji: String, area: BodyArea, seconds: Int, steps: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.area = area
        self.seconds = seconds
        self.steps = steps
    }
}

public enum StretchLibrary {
    /// Picks `count` distinct stretches from the chosen areas, preferring ones not in `recent`
    /// and spreading picks across areas. Falls back to every area if `areas` is empty.
    public static func pick<G: RandomNumberGenerator>(
        count: Int, areas: Set<BodyArea>, avoiding recent: [String] = [], using rng: inout G
    ) -> [Stretch] {
        let allowed = areas.isEmpty ? Set(BodyArea.allCases) : areas
        let pool = all.filter { allowed.contains($0.area) }.shuffled(using: &rng)
        let fresh = pool.filter { !recent.contains($0.id) }
        let ordered = fresh + pool.filter { recent.contains($0.id) }

        // Round-robin over areas so a 3-stretch break isn't three neck rolls.
        var byArea: [BodyArea: [Stretch]] = [:]
        var areaOrder: [BodyArea] = []
        for stretch in ordered {
            if byArea[stretch.area] == nil { areaOrder.append(stretch.area) }
            byArea[stretch.area, default: []].append(stretch)
        }
        var result: [Stretch] = []
        while result.count < min(count, ordered.count) {
            for area in areaOrder where result.count < count {
                if var list = byArea[area], !list.isEmpty {
                    result.append(list.removeFirst())
                    byArea[area] = list
                }
            }
        }
        return result
    }

    public static func pick(count: Int, areas: Set<BodyArea>, avoiding recent: [String] = []) -> [Stretch] {
        var rng = SystemRandomNumberGenerator()
        return pick(count: count, areas: areas, avoiding: recent, using: &rng)
    }
}
