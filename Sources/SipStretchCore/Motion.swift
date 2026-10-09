import Foundation

// The always-on motions of a skeleton-driven character: how it walks, how it stands around, and how it
// stretches along with you. Everything is a pure function of time, so it's cheap and easy to test.
// Gestures (the signature moves, celebrating, sulking) are keyframed clips; see `MotionClips.swift`.

/// How the character feels while walking.
public enum GaitMood: Sendable {
    case normal, happy, angry
}

/// Whose body language an imported model borrows.
public enum MotionStyle: Sendable, CaseIterable {
    case standard, kratos, panda, hulk, wukong

    public init(personality: Personality) {
        switch personality {
        case .kratos: self = .kratos
        case .kungFuPanda: self = .panda
        case .hulk: self = .hulk
        case .wukong: self = .wukong
        default: self = .standard
        }
    }

    /// How far (radians) the arms hang away from the body once lowered out of a T-pose: bulky
    /// characters need more room.
    public var restAbduction: Double {
        switch self {
        case .kratos: 0.30
        case .panda: 0.35
        case .hulk: 0.38
        case .wukong, .standard: 0.28
        }
    }

    /// Larger for characters that breathe and fidget a lot, smaller for stoic ones.
    var idleIntensity: Double {
        switch self {
        case .kratos: 0.7
        case .panda: 1.3
        case .hulk: 1.5
        case .wukong: 1.2
        case .standard: 1.0
        }
    }

    var gait: Gait {
        switch self {
        case .standard, .wukong:
            Gait(hip: 0.36, knee: 0.95, arm: 0.34, elbow: 0.30, elbowRest: 0.16, twist: 0.07, lean: 0.05, bob: 0.030,
                 sway: 0.025, armSpread: 0.06, legSpread: 0.02, head: -0.03, waddle: 0)
        case .kratos:
            Gait(hip: 0.34, knee: 0.85, arm: 0.22, elbow: 0.18, elbowRest: 0.30, twist: 0.09, lean: 0.07, bob: 0.032,
                 sway: 0.032, armSpread: 0.04, legSpread: 0.05, head: 0.10, waddle: 0)
        case .panda:
            Gait(hip: 0.30, knee: 0.70, arm: 0.40, elbow: 0.25, elbowRest: 0.10, twist: 0.05, lean: 0.03, bob: 0.045,
                 sway: 0.045, armSpread: 0, legSpread: 0.10, head: -0.02, waddle: 0.07)
        case .hulk:
            Gait(hip: 0.36, knee: 0.80, arm: 0.20, elbow: 0.15, elbowRest: 0.20, twist: 0.10, lean: 0.16, bob: 0.035,
                 sway: 0.040, armSpread: 0.10, legSpread: 0.07, head: 0.08, waddle: 0.03)
        }
    }
}

/// How one character walks. Angles in radians; `bob` and `sway` in leg lengths.
struct Gait {
    var hip: Double
    var knee: Double
    var arm: Double
    var elbow: Double
    var elbowRest: Double
    var twist: Double
    var lean: Double
    var bob: Double
    var sway: Double
    var armSpread: Double
    var legSpread: Double
    var head: Double
    var waddle: Double
}

/// How a mood changes the walk, as multipliers and offsets.
private struct MoodFactors {
    var arm: Double
    var bob: Double
    var lean: Double
    var head: Double
    var elbow: Double
    var spread: Double
    var twist: Double
    var knee: Double
}

public enum Motion {
    /// Where the foot is tilted (toes up positive) through one stride: lands on the heel, rolls flat,
    /// pushes off the toes, then lifts clear for the swing.
    private static let footPoints: [(Double, Double)] = [(0, 0.08), (0.25, 0.12), (0.35, 0), (0.5, 0), (0.75, -0.55), (1, 0.08)]

    /// A smooth curve through the points, repeating every 1.0.
    static func curve(_ points: [(Double, Double)], _ value: Double) -> Double {
        let x = value - floor(value)
        for i in 0..<(points.count - 1) where points[i].0 <= x && x <= points[i + 1].0 {
            let u = (x - points[i].0) / (points[i + 1].0 - points[i].0)
            return points[i].1 + (points[i + 1].1 - points[i].1) * u * u * (3 - 2 * u)
        }
        return points[points.count - 1].1
    }

    /// One frame of a walk cycle. `phase` runs 0…1 over two steps (it wraps), and `stride` overrides
    /// how far the legs swing (radians) so the feet match the speed the character actually travels at.
    public static func walk(phase: Double, style: MotionStyle, mood: GaitMood = .normal, stride: Double? = nil) -> Pose {
        var g = style.gait
        if let stride { g.hip = stride }
        let m: MoodFactors
        switch mood {
        case .normal: m = MoodFactors(arm: 1, bob: 1, lean: 0, head: 0, elbow: 0, spread: 0, twist: 1, knee: 1)
        case .happy: m = MoodFactors(arm: 1.7, bob: 1.8, lean: -0.03, head: -0.07, elbow: 0.05, spread: 0.04, twist: 1.3, knee: 1.1)
        case .angry: m = MoodFactors(arm: 0.45, bob: 1.25, lean: 0.10, head: 0.22, elbow: 0.55, spread: 0.12, twist: 1.4, knee: 0.9)
        }

        let wrapped = phase - floor(phase)
        let w = 2 * Double.pi * wrapped
        let s = sin(w)
        let c = cos(w)
        var pose = Pose()
        let swing = g.arm * m.arm
        for left in [true, false] {
            let legPhase = left ? wrapped : wrapped + 0.5
            let sp = sin(2 * Double.pi * legPhase)
            let hip = g.hip * sp + 0.04
            let bend = 0.07 + g.knee * m.knee * pow(max(0, cos(2 * Double.pi * (legPhase - 0.89))), 1.4)
            let foot = curve(footPoints, legPhase)
            let hipJoint: Joint = left ? .hipL : .hipR
            let kneeJoint: Joint = left ? .kneeL : .kneeR
            let ankleJoint: Joint = left ? .ankleL : .ankleR
            let shoulder: Joint = left ? .shoulderL : .shoulderR
            let elbowJoint: Joint = left ? .elbowL : .elbowR
            pose[hipJoint, .pitch] = hip
            pose[kneeJoint, .pitch] = bend
            pose[hipJoint, .roll] = g.legSpread
            pose[ankleJoint, .pitch] = foot - (hip - bend)
            // The arm swings against the leg on its own side, and bends more the further forward it goes.
            pose[shoulder, .pitch] = -swing * sp + 0.02
            pose[shoulder, .roll] = g.armSpread + m.spread
            pose[elbowJoint, .pitch] = g.elbowRest + m.elbow + g.elbow * (0.5 - 0.5 * sp) * sqrt(m.arm)
        }
        pose.values[Pose.rootY] = 0.35 * g.bob * (m.bob - 1) * max(0, cos(2 * w))
        pose.values[Pose.rootX] = -g.sway * c
        let turn = g.twist * m.twist
        pose.values[Pose.leanYaw] = -turn * s
        pose[.spine, .yaw] = 0.8 * turn * s
        pose[.chest, .yaw] = 1.4 * turn * s * 0.8
        let net = -turn * s + 0.8 * turn * s + 1.12 * turn * s
        pose[.head, .yaw] = -0.75 * net
        pose.values[Pose.leanRoll] = g.waddle * s
        pose[.spine, .roll] = -0.5 * g.waddle * s
        pose.values[Pose.leanPitch] = g.lean + m.lean
        pose[.chest, .pitch] = 0.03
        pose[.head, .pitch] = g.head + m.head - 0.02 * cos(2 * w) - (g.lean + m.lean) * 0.8
        return pose
    }

    /// Standing around alive: breathing, shifting weight, glancing about, arms never quite still.
    public static func idle(time t: Double, style: MotionStyle) -> Pose {
        let k = style.idleIntensity
        var pose = Pose()
        let breath = sin(2 * Double.pi * t / 3.8)
        pose[.chest, .pitch] = -0.02 * breath * k
        pose[.spine, .pitch] = 0.006 * breath * k
        pose[.head, .pitch] = 0.012 * breath * k
        pose[.shoulderL, .roll] = 0.02 * breath * k
        pose[.shoulderR, .roll] = 0.02 * breath * k
        let shift = sin(2 * Double.pi * t / 8.3)
        pose.values[Pose.rootX] = 0.012 * shift
        pose.values[Pose.leanRoll] = -0.010 * shift
        pose[.spine, .roll] = 0.018 * shift
        pose[.chest, .roll] = -0.01 * shift
        pose[.hipL, .roll] = 0.012 * shift
        pose[.hipR, .roll] = -0.012 * shift
        let glance = sin(2 * Double.pi * t / 13) + 0.5 * sin(2 * Double.pi * t / 5.3 + 1)
        pose[.head, .yaw] = 0.22 * tanh(1.6 * glance)
        pose[.head, .pitch] += 0.04 * sin(2 * Double.pi * t / 9.1 + 0.5)
        pose[.shoulderL, .pitch] = 0.03 * sin(2 * Double.pi * t / 6.1)
        pose[.shoulderR, .pitch] = 0.03 * sin(2 * Double.pi * t / 6.1 + 1.3)
        return pose
    }

    /// A guided stretch: arms up overhead, a lean to one side and then the other, arms down. Loops every 4.8 s.
    public static func stretch(time t: Double) -> Pose {
        let x = t / 4.8 - floor(t / 4.8)
        let reach = curve([(0, 0), (0.22, 1), (0.78, 1), (1, 0)], x)
        let tilt = curve([(0, 0), (0.25, 0), (0.40, 1), (0.52, 1), (0.62, -1), (0.74, -1), (0.82, 0), (1, 0)], x)
        var pose = Pose()
        for shoulder in [Joint.shoulderL, .shoulderR] {
            pose[shoulder, .pitch] = 3.0 * reach
            pose[shoulder, .roll] = -0.28 * reach
        }
        for elbow in [Joint.elbowL, .elbowR] { pose[elbow, .pitch] = 0.35 * reach }
        pose[.chest, .pitch] = -0.15 * reach
        pose[.head, .pitch] = -0.05 * reach
        pose[.spine, .roll] = 0.14 * tilt * reach
        pose[.chest, .roll] = 0.14 * tilt * reach
        pose.values[Pose.rootX] = -0.03 * tilt * reach
        return pose
    }
}
