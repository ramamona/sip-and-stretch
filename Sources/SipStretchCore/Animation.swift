import Foundation

// A tiny keyframe animation engine for skeleton-driven characters.
//
// A `Pose` is a flat list of numbers: a body offset, a lean of the whole body, and three angles
// (pitch, yaw, roll) for each `Joint`. A `Clip` is a set of keyframes over those numbers with easing
// between them. Clips are *additive*: they describe a gesture on top of whatever the character is
// doing anyway (breathing, shifting its weight), and always start and end at zero so they blend in
// and out without a pop.
//
// Conventions, from the character's point of view (it faces the camera; "left" is its own left):
// - Pitch is forward-positive everywhere. For the knee it means "bent" (the shin swings back); for
//   the ankle, "toes up".
// - Roll tilts a body part to the character's left. For limbs it moves them away from the body
//   (outward-positive on both sides), and negative roll crosses them over the chest.
// - Yaw turns toward the character's left; for limbs it twists outward-positive on both sides.
// - Root offsets are in leg lengths: x to the left, y up, z forward.

/// The joints a pose can bend.
public enum Joint: Int, CaseIterable, Sendable {
    case spine, chest, head
    case shoulderL, shoulderR, elbowL, elbowR
    case hipL, hipR, kneeL, kneeR, ankleL, ankleR

    /// The short name used in pose strings, like "shL.p".
    public var code: String {
        switch self {
        case .spine: "spine"
        case .chest: "chest"
        case .head: "head"
        case .shoulderL: "shL"
        case .shoulderR: "shR"
        case .elbowL: "elL"
        case .elbowR: "elR"
        case .hipL: "hipL"
        case .hipR: "hipR"
        case .kneeL: "knL"
        case .kneeR: "knR"
        case .ankleL: "anL"
        case .ankleR: "anR"
        }
    }

    /// What this joint hangs from (nil: the body itself).
    public var parent: Joint? {
        switch self {
        case .spine, .hipL, .hipR: nil
        case .chest: .spine
        case .head, .shoulderL, .shoulderR: .chest
        case .elbowL: .shoulderL
        case .elbowR: .shoulderR
        case .kneeL: .hipL
        case .kneeR: .hipR
        case .ankleL: .kneeL
        case .ankleR: .kneeR
        }
    }

    /// +1 for the character's left side (+X), -1 for the right, 0 for joints on the midline.
    public var side: Double {
        switch self {
        case .shoulderL, .elbowL, .hipL, .kneeL, .ankleL: 1
        case .shoulderR, .elbowR, .hipR, .kneeR, .ankleR: -1
        default: 0
        }
    }

    /// Whether rotating about the X axis by a positive pitch swings the part forward: a limb hanging
    /// down swings forward with a negative rotation, an upright part with a positive one, and a bent
    /// knee swings the shin back.
    public var pitchSign: Double {
        switch self {
        case .spine, .chest, .head, .kneeL, .kneeR: 1
        default: -1
        }
    }

    public static func named(_ code: String) -> Joint? { allCases.first { $0.code == code } }
}

public enum PoseAxis: Int, Sendable {
    case pitch = 0, yaw = 1, roll = 2
}

/// Every number that describes a body position, in one flat list so blending is just arithmetic.
public struct Pose: Equatable, Sendable {
    public static let rootX = 0, rootY = 1, rootZ = 2
    public static let leanPitch = 3, leanYaw = 4, leanRoll = 5
    public static let channelCount = 6 + 3 * Joint.allCases.count

    public var values: [Double]

    public init() {
        values = Array(repeating: 0, count: Self.channelCount)
    }

    public static func index(_ joint: Joint, _ axis: PoseAxis) -> Int {
        6 + joint.rawValue * 3 + axis.rawValue
    }

    public subscript(_ joint: Joint, _ axis: PoseAxis) -> Double {
        get { values[Self.index(joint, axis)] }
        set { values[Self.index(joint, axis)] = newValue }
    }

    /// "root.y", "lean.p", "shL.r"… to a channel number, or nil if the name makes no sense.
    public static func channel(named name: String) -> Int? {
        let parts = name.split(separator: ".")
        guard parts.count == 2 else { return nil }
        let part = String(parts[0])
        let axis = String(parts[1])
        if part == "root" {
            guard let i = ["x", "y", "z"].firstIndex(of: axis) else { return nil }
            return rootX + i
        }
        if part == "lean" {
            guard let i = ["p", "y", "r"].firstIndex(of: axis) else { return nil }
            return leanPitch + i
        }
        guard let joint = Joint.named(part), let i = ["p", "y", "r"].firstIndex(of: axis) else { return nil }
        return 6 + joint.rawValue * 3 + i
    }

    /// Adds `other * scale` to this pose.
    public mutating func add(_ other: Pose, scale: Double = 1) {
        for i in values.indices { values[i] += other.values[i] * scale }
    }

    /// `self` at 0 to `other` at 1.
    public func blended(to other: Pose, _ amount: Double) -> Pose {
        var result = self
        for i in values.indices { result.values[i] += (other.values[i] - values[i]) * amount }
        return result
    }
}

/// How a keyframe is approached from the one before it.
public enum Ease: Sendable {
    /// Slow in, slow out. The default.
    case inOut
    /// Gets going quickly, then lands gently (a reach, a raise).
    case out
    /// Slow start, speeding up.
    case accelerate
    /// Overshoots a little and settles back (a flourish).
    case back
    /// Barely moves, then arrives hard (a punch, a slam).
    case snap
    case linear
    /// A smooth curve through this key and its neighbours, with no stop at the key (glances, waves).
    case flow

    private static func smoothstep(_ u: Double) -> Double { u * u * (3 - 2 * u) }

    func apply(_ u: Double) -> Double {
        switch self {
        case .inOut, .flow: Self.smoothstep(u)
        case .out: Self.smoothstep(pow(u, 0.7))
        case .accelerate: pow(u, 2.2)
        case .back: Self.smoothstep(u) + 0.35 * sin(Double.pi * u) * u * u
        case .snap: u * u * u
        case .linear: u
        }
    }
}

/// Something that happens at an instant of a gesture, besides the body moving.
public struct ClipEvent: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Something heavy hits the ground (strength about 0.3 to 1.6).
        case impact(Double)
        /// Feet touching down after a jump.
        case land
    }

    public var time: Double
    public var kind: Kind
}

/// Collects keyframes written as text, then makes a `Clip`.
///
///     var c = ClipBuilder(2.0)
///     c.at(0.5, .out, "shL.p 2.9  shR.p 2.9  chest.p -0.3")
///     c.event(0.8, .impact(1))
public struct ClipBuilder {
    fileprivate struct Entry {
        var time: Double
        var ease: Ease
        var values: [(channel: Int, value: Double)]
    }

    public var duration: Double
    fileprivate var entries: [Entry] = []
    fileprivate var events: [ClipEvent] = []
    /// Channel names in the pose text that don't exist (a typo), for tests to catch.
    public private(set) var unrecognized: [String] = []

    public init(_ duration: Double) {
        self.duration = duration
    }

    /// A keyframe at `time`: channel/value pairs separated by spaces.
    public mutating func at(_ time: Double, _ ease: Ease, _ pose: String) {
        let tokens = pose.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).map(String.init)
        var values: [(channel: Int, value: Double)] = []
        var i = 0
        while i + 1 < tokens.count {
            if let channel = Pose.channel(named: tokens[i]), let value = Double(tokens[i + 1]) {
                values.append((channel, value))
            } else {
                unrecognized.append(tokens[i])
            }
            i += 2
        }
        entries.append(Entry(time: time, ease: ease, values: values))
    }

    public mutating func event(_ time: Double, _ kind: ClipEvent.Kind) {
        events.append(ClipEvent(time: time, kind: kind))
    }

    public func build() -> Clip { Clip(self) }
}

/// A gesture: keyframes over `Pose` channels, plus events. Every channel starts and ends at 0.
public struct Clip: Sendable {
    struct Track: Sendable {
        var channel: Int
        var times: [Double]
        var values: [Double]
        var eases: [Ease]

        func value(at t: Double) -> Double {
            guard let first = times.first, let last = times.last else { return 0 }
            if t <= first { return values[0] }
            if t >= last { return values[values.count - 1] }
            var i = 0
            while i + 2 < times.count && times[i + 1] < t { i += 1 }
            let t0 = times[i], t1 = times[i + 1]
            let v0 = values[i], v1 = values[i + 1]
            let u = t1 > t0 ? (t - t0) / (t1 - t0) : 1
            let ease = eases[i + 1]
            if ease == .flow {
                let m0 = tangent(i) * (t1 - t0)
                let m1 = tangent(i + 1) * (t1 - t0)
                let h00 = 2 * u * u * u - 3 * u * u + 1
                let h10 = u * u * u - 2 * u * u + u
                let h01 = -2 * u * u * u + 3 * u * u
                let h11 = u * u * u - u * u
                return h00 * v0 + h10 * m0 + h01 * v1 + h11 * m1
            }
            return v0 + (v1 - v0) * ease.apply(u)
        }

        private func tangent(_ j: Int) -> Double {
            if j <= 0 || j >= times.count - 1 { return 0 }
            let span = times[j + 1] - times[j - 1]
            return span > 0 ? (values[j + 1] - values[j - 1]) / span : 0
        }
    }

    public let duration: Double
    public let events: [ClipEvent]
    /// See `ClipBuilder.unrecognized`.
    public let unrecognized: [String]
    let tracks: [Track]

    init(_ builder: ClipBuilder) {
        let lastKey = builder.entries.filter { !$0.values.isEmpty }.map { $0.time }.max() ?? 0
        let total = max(builder.duration, lastKey + 0.45)
        duration = total
        events = builder.events.sorted { $0.time < $1.time }
        unrecognized = builder.unrecognized
        var grouped: [Int: [(time: Double, value: Double, ease: Ease)]] = [:]
        for entry in builder.entries {
            for item in entry.values {
                grouped[item.channel, default: []].append((entry.time, item.value, entry.ease))
            }
        }
        var built: [Track] = []
        for channel in grouped.keys.sorted() {
            var keys = grouped[channel] ?? []
            keys.sort { $0.time < $1.time }
            if let first = keys.first, first.time > 1e-9 { keys.insert((0, 0, .inOut), at: 0) }
            if let last = keys.last, last.time < total - 1e-9 { keys.append((total, 0, .inOut)) }
            built.append(Track(
                channel: channel,
                times: keys.map { $0.time },
                values: keys.map { $0.value },
                eases: keys.map { $0.ease }
            ))
        }
        tracks = built
    }

    /// Adds the gesture's pose at `time` (scaled by `scale`) onto `pose`.
    public func add(to pose: inout Pose, at time: Double, scale: Double = 1) {
        for track in tracks {
            pose.values[track.channel] += track.value(at: time) * scale
        }
    }

    public func sample(at time: Double) -> Pose {
        var pose = Pose()
        add(to: &pose, at: time)
        return pose
    }
}
