import Foundation

// The gestures: what each character does when it arrives, celebrates, sulks and grumbles.
//
// Each clip is a list of keyframes, one per `c.at(time, easing, "channel value …")` line. Channels are
// `joint.axis` (p pitch, y yaw, r roll; see `Animation.swift` for the conventions), plus `root.x/y/z` for
// the body and `lean.p/y/r` for tipping the whole body about its feet. Channels a key doesn't mention keep
// easing between the keys that do, and every channel returns to rest by the end of the clip.
// `c.event` marks something heavy hitting the ground, for the dust ring and the jolt.

extension MotionStyle {
    /// Shows off on arrival: the character's signature move.
    public var signature: Clip {
        switch self {
        case .kratos: Self.kratosSignature
        case .panda: Self.pandaSignature
        case .hulk: Self.hulkSignature
        case .wukong: Self.wukongSignature
        case .standard: Self.standardSignature
        }
    }

    /// You did it: celebrate.
    public var pleased: Clip {
        switch self {
        case .kratos: Self.kratosPleased
        case .panda: Self.pandaPleased
        case .hulk: Self.hulkPleased
        case .wukong: Self.wukongPleased
        case .standard: Self.standardPleased
        }
    }

    /// You skipped it: a tantrum, in character.
    public var angry: Clip {
        switch self {
        case .kratos: Self.kratosAngry
        case .panda: Self.pandaAngry
        case .hulk: Self.hulkAngry
        case .wukong: Self.wukongAngry
        case .standard: Self.standardAngry
        }
    }

    /// Getting impatient. Level 1 is a sulk with crossed arms; level 2 adds a sigh or a stomp.
    public func grumble(level: Int) -> Clip {
        level >= 2 ? grumbleHard : grumbleSoft
    }

    private var grumbleSoft: Clip {
        switch self {
        case .kratos: Self.kratosGrumbleSoft
        case .panda: Self.pandaGrumbleSoft
        case .hulk: Self.hulkGrumbleSoft
        case .wukong: Self.wukongGrumbleSoft
        case .standard: Self.standardGrumbleSoft
        }
    }

    private var grumbleHard: Clip {
        switch self {
        case .kratos: Self.kratosGrumbleHard
        case .panda: Self.pandaGrumbleHard
        case .hulk: Self.hulkGrumbleHard
        case .wukong: Self.wukongGrumbleHard
        case .standard: Self.standardGrumbleHard
        }
    }
}

private extension MotionStyle {
    static let kratosSignature: Clip = {
        var c = ClipBuilder(4)
        c.at(0.22, .inOut, """
            lean.y 0.15  chest.p 0.12  head.p 0.05  shL.p 0.45  shL.r 0  shR.p 0.45  shR.r 0
            elL.p 0.5  elR.p 0.5  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24  anL.p 0.12
            anR.p 0.12
            """)
        c.at(0.62, .out, """
            lean.p -0.1  lean.y 0.3  spine.p -0.08  chest.p -0.3  head.p -0.12  shL.p 2.9
            shL.r -0.28  shR.p 2.9  shR.r -0.28  elL.p 0.55  elR.p 0.55  hipL.p -0.04
            hipR.p -0.04  anL.p -0.1  anR.p -0.1
            """)
        c.at(0.72, .inOut, """
            lean.p -0.11  lean.y 0.3  spine.p -0.088  chest.p -0.33  head.p -0.12  shL.p 2.9
            shL.r -0.28  shR.p 2.9  shR.r -0.28  elL.p 0.55  elR.p 0.55  hipL.p -0.04
            hipR.p -0.04  anL.p -0.1  anR.p -0.1
            """)
        c.at(0.88, .snap, """
            lean.p 0.12  lean.y 0.22  spine.p 0.25  chest.p 0.55  head.p 0.14  shL.p 0.55
            shL.r -0.28  shR.p 0.55  shR.r -0.28  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipR.p 0.55
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.at(1.1, .out, """
            lean.p 0.13  lean.y 0.2  spine.p 0.28  chest.p 0.62  head.p 0.16  shL.p 0.15
            shL.r -0.2  shR.p 0.15  shR.r -0.2  elL.p 0.6  elR.p 0.6  hipL.p 0.58  hipR.p 0.58
            knL.p 1.16  knR.p 1.16  anL.p 0.58  anR.p 0.58
            """)
        c.at(1.3, .inOut, """
            lean.p 0.13  lean.y 0.2  spine.p 0.28  chest.p 0.62  head.p 0.16  shL.p 0.15
            shL.r -0.2  shR.p 0.15  shR.r -0.2  elL.p 0.6  elR.p 0.6  hipL.p 0.58  hipR.p 0.58
            knL.p 1.16  knR.p 1.16  anL.p 0.58  anR.p 0.58
            """)
        c.at(1.72, .out, """
            lean.p -0.125  lean.y 0.3  spine.p -0.1  chest.p -0.375  head.p -0.12  shL.p 2.9
            shL.r -0.28  shR.p 2.9  shR.r -0.28  elL.p 0.55  elR.p 0.55  hipL.p -0.04
            hipR.p -0.04  anL.p -0.1  anR.p -0.1
            """)
        c.at(1.82, .inOut, """
            lean.p -0.13  lean.y 0.3  spine.p -0.104  chest.p -0.39  head.p -0.12  shL.p 2.9
            shL.r -0.28  shR.p 2.9  shR.r -0.28  elL.p 0.55  elR.p 0.55  hipL.p -0.04
            hipR.p -0.04  anL.p -0.1  anR.p -0.1
            """)
        c.at(1.98, .snap, """
            lean.p 0.138  lean.y 0.22  spine.p 0.2875  chest.p 0.6325  head.p 0.14  shL.p 0.55
            shL.r -0.28  shR.p 0.55  shR.r -0.28  elL.p 0.7  elR.p 0.7  hipL.p 0.6325
            hipR.p 0.6325  knL.p 1.265  knR.p 1.265  anL.p 0.6325  anR.p 0.6325
            """)
        c.at(2.22, .out, """
            lean.p 0.1495  lean.y 0.2  spine.p 0.322  chest.p 0.713  head.p 0.16  shL.p 0.15
            shL.r -0.2  shR.p 0.15  shR.r -0.2  elL.p 0.6  elR.p 0.6  hipL.p 0.667  hipR.p 0.667
            knL.p 1.334  knR.p 1.334  anL.p 0.667  anR.p 0.667
            """)
        c.at(2.65, .inOut, """
            lean.p 0.143  lean.y 0.2  spine.p 0.308  chest.p 0.682  head.p 0.16  shL.p 0.15
            shL.r -0.2  shR.p 0.15  shR.r -0.2  elL.p 0.6  elR.p 0.6  hipL.p 0.638  hipR.p 0.638
            knL.p 1.276  knR.p 1.276  anL.p 0.638  anR.p 0.638
            """)
        c.at(3.15, .inOut, """
            lean.y 0.12  chest.p -0.1  head.p 0.08  shL.p 0.2  shL.r 0.05  shR.p 0.2  shR.r 0.05
            elL.p 0.7  elR.p 0.7
            """)
        c.at(3.55, .inOut, "chest.p -0.04")
        c.event(0.88, .impact(1.0))
        c.event(1.98, .impact(1.4))
        return c.build()
    }()

    static let kratosPleased: Clip = {
        var c = ClipBuilder(1.9)
        c.at(0.35, .out, "chest.p -0.05  head.p 0  shL.p 0.15  shR.p 1.05  shR.r -0.75  elR.p 2.15")
        c.at(0.55, .inOut, """
            spine.p 0.08  chest.p 0.12  head.p 0.38  shL.p 0.15  shR.p 1.05  shR.r -0.75
            elR.p 2.15
            """)
        c.at(1.05, .inOut, """
            spine.p 0.08  chest.p 0.12  head.p 0.38  shL.p 0.15  shR.p 1.05  shR.r -0.75
            elR.p 2.15
            """)
        c.at(1.35, .inOut, "chest.p -0.03  head.p 0  shR.p 1.05  shR.r -0.75  elR.p 2.15")
        return c.build()
    }()

    static let kratosAngry: Clip = {
        var c = ClipBuilder(2.75)
        c.at(0.3, .out, """
            root.z 0  lean.p 0.1  spine.p 0.08  chest.p 0.16  head.p 0.32  shL.p -0.05  shL.r 0.14
            shR.p -0.05  shR.r 0.14  elL.p 1.05  elR.p 1.05  hipL.p 0  hipR.p 0
            """)
        c.at(0.75, .inOut, """
            lean.p 0.12  spine.p 0.1  chest.p 0.18  head.p 0.34  head.y 0  shL.p -0.05  shL.r 0.14
            shR.p -0.05  shR.r 0.14  elL.p 1.05  elR.p 1.05
            """)
        c.at(0.85, .inOut, """
            lean.p 0.12  chest.p 0.18  head.p 0.34  head.y -0.3  shL.p -0.05  shL.r 0.14
            shR.p -0.05  shR.r 0.14  elL.p 1.05  elR.p 1.05
            """)
        c.at(1.05, .inOut, """
            lean.p 0.12  chest.p 0.18  head.p 0.34  head.y 0.3  shL.p -0.05  shL.r 0.14
            shR.p -0.05  shR.r 0.14  elL.p 1.05  elR.p 1.05
            """)
        c.at(1.25, .inOut, """
            lean.p 0.1  chest.p 0.15  head.p 0.3  head.y 0  shL.p -0.05  shL.r 0.14  shR.p -0.05
            shR.r 0.14  elL.p 1.05  elR.p 1.05
            """)
        c.at(1.5, .out, """
            lean.p -0.12  spine.p -0.1  chest.p -0.34  head.p -0.38  shL.p 0.35  shL.r 0.55
            shR.p 0.35  shR.r 0.55  elL.p 0.35  elR.p 0.35  hipL.p 0.2  hipR.p 0.2  knL.p 0.4
            knR.p 0.4  anL.p 0.2  anR.p 0.2
            """)
        c.at(1.95, .inOut, """
            lean.p 0  chest.p -0.12  head.p 0.2  shL.p 0.1  shL.r 0.3  shR.p 0.1  shR.r 0.3
            elL.p 0.8  elR.p 0.8
            """)
        c.at(2.3, .inOut, """
            chest.p 0.1  head.p 0.3  shL.p -0.05  shL.r 0.14  shR.p -0.05  shR.r 0.14  elL.p 1
            elR.p 1
            """)
        c.event(1.5, .impact(1.0))
        return c.build()
    }()

    static let kratosGrumbleSoft: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.4, .out, """
            lean.p 0.04  chest.p 0.05  head.p 0.12  head.y 0.35  head.r 0  shL.p 0.95  shL.r -0.6
            shR.p 0.95  shR.r -0.6  elL.p 2.3  elR.p 2.3
            """)
        c.at(1, .inOut, """
            chest.p 0.04  head.p 0.14  head.y 0.4  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6
            elL.p 2.3  elR.p 2.3
            """)
        c.at(1.4, .inOut, """
            chest.p 0.05  head.p 0.1  head.y -0.1  head.r 0.1  shL.p 0.95  shL.r -0.6  shR.p 0.95
            shR.r -0.6  elL.p 2.3  elR.p 2.3
            """)
        c.at(2, .inOut, """
            head.p 0.1  head.y 0  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6  elL.p 2.3
            elR.p 2.3
            """)
        return c.build()
    }()

    static let kratosGrumbleHard: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.3, .out, """
            lean.p 0.08  chest.p 0.1  head.p 0.22  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6
            elL.p 2.3  elR.p 2.3
            """)
        c.at(0.6, .inOut, """
            chest.p 0.1  head.p 0.22  head.y -0.4  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6
            elL.p 2.3  elR.p 2.3
            """)
        c.at(0.8, .inOut, """
            chest.p 0.1  head.p 0.22  head.y 0.4  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6
            elL.p 2.3  elR.p 2.3
            """)
        c.at(1, .inOut, """
            spine.p -0.05  chest.p -0.18  head.p 0.2  head.y 0  shL.p 0.95  shL.r -0.6  shR.p 0.95
            shR.r -0.6  elL.p 2.3  elR.p 2.3
            """)
        c.at(1.5, .inOut, """
            spine.p 0.06  chest.p 0.16  head.p 0.3  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6
            elL.p 2.3  elR.p 2.3
            """)
        c.at(2, .inOut, """
            chest.p 0.08  head.p 0.24  shL.p 0.95  shL.r -0.6  shR.p 0.95  shR.r -0.6  elL.p 2.3
            elR.p 2.3
            """)
        return c.build()
    }()

    static let pandaSignature: Clip = {
        var c = ClipBuilder(4.75)
        c.at(0.55, .out, """
            spine.p 0.08  chest.p 0.32  head.p 0.3  shL.p 1  shL.r -0.55  shR.p 1  shR.r -0.55
            elL.p 1.95  elR.p 1.95  hipL.p 0.05  hipR.p 0.05  knL.p 0.1  knR.p 0.1  anL.p 0.05
            anR.p 0.05
            """)
        c.at(0.9, .inOut, """
            spine.p 0.08  chest.p 0.32  head.p 0.3  shL.p 1  shL.r -0.55  shR.p 1  shR.r -0.55
            elL.p 1.95  elR.p 1.95  hipL.p 0.05  hipR.p 0.05  knL.p 0.1  knR.p 0.1  anL.p 0.05
            anR.p 0.05
            """)
        c.at(1.25, .out, """
            spine.y 0  chest.p -0.05  chest.y 0  head.p -0.05  shL.p 0.25  shL.r -0.25  shR.p 0.25
            shR.r -0.25  elL.p 2.3  elR.p 2.3  hipL.p 0.38  hipL.r 0.42  hipR.p 0.38  hipR.r 0.42
            knL.p 0.76  knR.p 0.76  anL.p 0.38  anR.p 0.38
            """)
        c.at(1.52, .snap, """
            spine.y 0.2  chest.y 0.4  shL.p 0.2  shL.r -0.25  shR.p 1.52  shR.r -0.2  elL.p 2.4
            elR.p 0.08
            """)
        c.at(1.68, .out, """
            spine.y 0.075  chest.p -0.05  chest.y 0.15  head.p -0.05  shL.p 0.25  shL.r -0.25
            shR.p 0.25  shR.r -0.25  elL.p 2.3  elR.p 2.3  hipL.p 0.38  hipL.r 0.42  hipR.p 0.38
            hipR.r 0.42  knL.p 0.76  knR.p 0.76  anL.p 0.38  anR.p 0.38
            """)
        c.at(1.82, .snap, """
            spine.y -0.2  chest.y -0.4  shL.p 1.52  shL.r -0.2  shR.p 0.2  shR.r -0.25  elL.p 0.08
            elR.p 2.4
            """)
        c.at(1.98, .out, """
            spine.y -0.075  chest.p -0.05  chest.y -0.15  head.p -0.05  shL.p 0.25  shL.r -0.25
            shR.p 0.25  shR.r -0.25  elL.p 2.3  elR.p 2.3  hipL.p 0.38  hipL.r 0.42  hipR.p 0.38
            hipR.r 0.42  knL.p 0.76  knR.p 0.76  anL.p 0.38  anR.p 0.38
            """)
        c.at(2.12, .snap, """
            spine.y 0.21  chest.y 0.42  shL.p 0.2  shL.r -0.25  shR.p 1.52  shR.r -0.2  elL.p 2.4
            elR.p 0.08
            """)
        c.at(2.3, .out, """
            spine.y 0.05  chest.p -0.05  chest.y 0.1  head.p -0.05  shL.p 0.25  shL.r -0.25
            shR.p 0.25  shR.r -0.25  elL.p 2.3  elR.p 2.3  hipL.p 0.38  hipL.r 0.42  hipR.p 0.38
            hipR.r 0.42  knL.p 0.76  knR.p 0.76  anL.p 0.38  anR.p 0.38
            """)
        c.at(2.62, .inOut, """
            root.x 0.07  lean.p -0.04  lean.r 0.1  chest.p -0.18  head.p -0.05  shL.p 0.2
            shL.r 0.9  shR.p 0.2  shR.r 0.9  elL.p 0.3  elR.p 0.3  hipL.p 0.05  hipR.p 1.05
            knR.p 1.65  anR.p 0.1
            """)
        c.at(2.82, .snap, """
            root.x 0.08  lean.p -0.12  lean.r 0.12  spine.p -0.1  chest.p -0.32  head.p -0.1
            shL.p 0.3  shL.r 1  shR.p 0.3  shR.r 1  elL.p 0.2  elR.p 0.2  hipL.p 0.05  hipR.p 1.5
            knR.p 0.12  anR.p 0.35
            """)
        c.at(3.25, .inOut, """
            root.x 0.08  lean.p -0.12  lean.r 0.12  spine.p -0.1  chest.p -0.32  head.p -0.1
            shL.p 0.3  shL.r 1  shR.p 0.3  shR.r 1  elL.p 0.2  elR.p 0.2  hipL.p 0.05  hipR.p 1.5
            knR.p 0.12  anR.p 0.35
            """)
        c.at(3.58, .inOut, """
            chest.p -0.05  head.p -0.05  shL.p 0.25  shL.r -0.25  shR.p 0.25  shR.r -0.25
            elL.p 2.3  elR.p 2.3  hipL.p 0.38  hipL.r 0.42  hipR.p 0.38  hipR.r 0.42  knL.p 0.76
            knR.p 0.76  anL.p 0.38  anR.p 0.38
            """)
        c.at(3.95, .back, """
            chest.p -0.1  head.p -0.05  head.y 0  shL.p 0.35  shL.r 1.05  shR.p 0.35  shR.r 1.05
            elL.p 0.25  elR.p 0.25  hipL.p 0.08  hipR.p 0.08  knL.p 0.16  knR.p 0.16  anL.p 0.08
            anR.p 0.08
            """)
        c.at(4.3, .inOut, """
            chest.p -0.1  head.p -0.05  head.y 0  shL.p 0.35  shL.r 1.05  shR.p 0.35  shR.r 1.05
            elL.p 0.25  elR.p 0.25  hipL.p 0.08  hipR.p 0.08  knL.p 0.16  knR.p 0.16  anL.p 0.08
            anR.p 0.08
            """)
        c.event(1.52, .impact(0.3))
        c.event(1.82, .impact(0.3))
        c.event(2.12, .impact(0.4))
        c.event(2.82, .impact(0.7))
        return c.build()
    }()

    static let pandaPleased: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.18, .inOut, """
            chest.p 0.15  shL.p 0.5  shL.r 0  shR.p 0.5  shR.r 0  elL.p 0.6  elR.p 0.6  hipL.p 0.3
            hipR.p 0.3  knL.p 0.6  knR.p 0.6  anL.p 0.3  anR.p 0.3
            """)
        c.at(0.4, .out, """
            root.y 0.22  chest.p -0.15  shL.p 2  shL.r 0.7  shR.p 2  shR.r 0.7  elL.p 0.3
            elR.p 0.3  hipL.p 0.35  hipR.p 0.35  knL.p 0.8  knR.p 0.8  anL.p -0.2  anR.p -0.2
            """)
        c.at(0.64, .accelerate, "root.y 0  chest.p 0  shL.p 1.5  shL.r 0.5  shR.p 1.5  shR.r 0.5  elL.p 0.3  elR.p 0.3")
        c.at(0.74, .out, """
            chest.p 0.15  shL.p 0.6  shL.r 0.1  shR.p 0.6  shR.r 0.1  elL.p 0.6  elR.p 0.6
            hipL.p 0.3  hipR.p 0.3  knL.p 0.6  knR.p 0.6  anL.p 0.3  anR.p 0.3
            """)
        c.at(0.95, .out, """
            root.y 0.25  chest.p -0.15  shL.p 2  shL.r 0.7  shR.p 2  shR.r 0.7  elL.p 0.3
            elR.p 0.3  hipL.p 0.35  hipR.p 0.35  knL.p 0.8  knR.p 0.8  anL.p -0.2  anR.p -0.2
            """)
        c.at(1.2, .accelerate, "root.y 0  shL.p 1.5  shL.r 0.5  shR.p 1.5  shR.r 0.5  elL.p 0.3  elR.p 0.3")
        c.at(1.32, .out, """
            chest.p 0.25  head.p 0.25  shL.p 1  shL.r -0.55  shR.p 1  shR.r -0.55  elL.p 1.95
            elR.p 1.95  hipL.p 0.2  hipR.p 0.2  knL.p 0.4  knR.p 0.4  anL.p 0.2  anR.p 0.2
            """)
        c.at(1.95, .inOut, """
            chest.p 0.28  head.p 0.28  shL.p 1  shL.r -0.55  shR.p 1  shR.r -0.55  elL.p 1.95
            elR.p 1.95
            """)
        c.event(0.64, .land)
        c.event(1.2, .land)
        return c.build()
    }()

    static let pandaAngry: Clip = {
        var c = ClipBuilder(2.65)
        c.at(0.28, .inOut, """
            root.x -0.05  chest.y -0.2  shL.p 0.5  shL.y 0  shL.r 0.1  shR.p 0.5  shR.y 0
            shR.r 0.1  elL.p 1.3  elR.p 1.3  hipR.p 0.75  knR.p 1.2
            """)
        c.at(0.4, .snap, """
            root.y -0.03  chest.p 0.15  chest.y -0.2  shL.p 0.15  shL.r 0.1  shR.p 0.15  shR.r 0.1
            elL.p 1.1  elR.p 1.1  hipR.p 0.1  knR.p 0.05
            """)
        c.at(0.63, .inOut, """
            root.x 0.05  chest.y 0.2  shL.p 0.5  shL.y 0  shL.r 0.1  shR.p 0.5  shR.y 0  shR.r 0.1
            elL.p 1.3  elR.p 1.3  hipL.p 0.75  knL.p 1.2
            """)
        c.at(0.75, .snap, """
            root.y -0.03  chest.p 0.15  chest.y 0.2  shL.p 0.15  shL.r 0.1  shR.p 0.15  shR.r 0.1
            elL.p 1.1  elR.p 1.1  hipL.p 0.1  knL.p 0.05
            """)
        c.at(0.98, .inOut, """
            root.x -0.05  chest.y -0.2  shL.p 0.5  shL.y 0  shL.r 0.1  shR.p 0.5  shR.y 0
            shR.r 0.1  elL.p 1.3  elR.p 1.3  hipR.p 0.75  knR.p 1.2
            """)
        c.at(1.1, .snap, """
            root.y -0.03  chest.p 0.15  chest.y -0.2  shL.p 0.15  shL.r 0.1  shR.p 0.15  shR.r 0.1
            elL.p 1.1  elR.p 1.1  hipR.p 0.1  knR.p 0.05
            """)
        c.at(1.33, .inOut, """
            root.x 0.05  chest.y 0.2  shL.p 0.5  shL.y 0  shL.r 0.1  shR.p 0.5  shR.y 0  shR.r 0.1
            elL.p 1.3  elR.p 1.3  hipL.p 0.75  knL.p 1.2
            """)
        c.at(1.45, .snap, """
            root.y -0.03  chest.p 0.15  chest.y 0.2  shL.p 0.15  shL.r 0.1  shR.p 0.15  shR.r 0.1
            elL.p 1.1  elR.p 1.1  hipL.p 0.1  knL.p 0.05
            """)
        c.at(1.75, .inOut, "chest.p 0.1  head.p 0.2  shL.p 1  shL.r -0.5  shR.p 1  shR.r -0.5  elL.p 2  elR.p 2")
        c.at(2.2, .inOut, "head.p 0.2  shL.p 1  shL.r -0.5  shR.p 1  shR.r -0.5  elL.p 2  elR.p 2")
        c.event(0.4, .impact(0.5))
        c.event(0.75, .impact(0.5))
        c.event(1.1, .impact(0.6))
        c.event(1.45, .impact(0.6))
        return c.build()
    }()

    static let pandaGrumbleSoft: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.4, .out, """
            chest.p 0.05  head.p 0.1  head.y 0.4  head.r 0.12  shL.p 0.95  shL.r -0.55  shR.p 0.95
            shR.r -0.55  elL.p 2.3  elR.p 2.3
            """)
        c.at(1.2, .inOut, """
            head.p 0.1  head.y 0.45  head.r 0.12  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55
            elL.p 2.3  elR.p 2.3
            """)
        c.at(1.8, .inOut, "head.y -0.1  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()

    static let pandaGrumbleHard: Clip = {
        var c = ClipBuilder(2.65)
        c.at(0.3, .out, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(0.5, .inOut, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipR.p 0.5  knR.p 0.9
            """)
        c.at(0.64, .accelerate, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(0.78, .inOut, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipR.p 0.5  knR.p 0.9
            """)
        c.at(0.92, .accelerate, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.06, .inOut, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipR.p 0.5  knR.p 0.9
            """)
        c.at(1.2, .accelerate, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.34, .inOut, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipR.p 0.5  knR.p 0.9
            """)
        c.at(1.48, .accelerate, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.62, .inOut, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipR.p 0.5  knR.p 0.9
            """)
        c.at(1.76, .accelerate, """
            chest.p 0.1  head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(2.2, .inOut, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()

    static let hulkSignature: Clip = {
        var c = ClipBuilder(5.37)
        c.at(0.45, .out, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(0.75, .inOut, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  head.y 0  shL.p 0.35
            shL.r 0.95  shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12
            hipR.p 0.14  hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(0.95, .inOut, """
            lean.p -0.12  lean.y 0.2  spine.p -0.12  chest.p -0.5  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(1.05, .inOut, """
            lean.p -0.132  lean.y 0.2  spine.p -0.12  chest.p -0.55  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(1.22, .snap, """
            lean.p 0.17  lean.y 0.12  spine.p 0.3  chest.p 0.68  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.62  hipR.p 0.62
            knL.p 1.24  knR.p 1.24  anL.p 0.62  anR.p 0.62
            """)
        c.at(1.42, .out, """
            lean.p 0.1785  lean.y 0.12  spine.p 0.315  chest.p 0.714  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.651
            hipR.p 0.651  knL.p 1.302  knR.p 1.302  anL.p 0.651  anR.p 0.651
            """)
        c.at(1.64, .inOut, """
            lean.p 0.1785  lean.y 0.12  spine.p 0.315  chest.p 0.714  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.651
            hipR.p 0.651  knL.p 1.302  knR.p 1.302  anL.p 0.651  anR.p 0.651
            """)
        c.at(2.1, .inOut, """
            lean.p -0.144  lean.y 0.2  spine.p -0.12  chest.p -0.6  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(2.2, .inOut, """
            lean.p -0.15  lean.y 0.2  spine.p -0.12  chest.p -0.625  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(2.38, .snap, """
            lean.p 0.204  lean.y 0.12  spine.p 0.36  chest.p 0.816  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.744
            hipR.p 0.744  knL.p 1.488  knR.p 1.488  anL.p 0.744  anR.p 0.744
            """)
        c.at(2.6, .out, """
            lean.p 0.2125  lean.y 0.12  spine.p 0.375  chest.p 0.85  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.775
            hipR.p 0.775  knL.p 1.55  knR.p 1.55  anL.p 0.775  anR.p 0.775
            """)
        c.at(2.9, .inOut, """
            lean.p 0.204  lean.y 0.12  spine.p 0.36  chest.p 0.816  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.744
            hipR.p 0.744  knL.p 1.488  knR.p 1.488  anL.p 0.744  anR.p 0.744
            """)
        c.at(3.3, .inOut, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(3.42, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(3.54, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(3.66, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(3.78, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(3.9, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(4.02, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(4.42, .inOut, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(4.92, .inOut, "chest.p -0.05")
        c.event(1.22, .impact(1.2))
        c.event(2.38, .impact(1.6))
        return c.build()
    }()

    static let hulkPleased: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.12, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(0.32, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(0.52, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(0.72, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(0.92, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 1  shL.r -0.5  shR.p 0.6  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(1.12, .out, """
            spine.p -0.06  chest.p -0.25  head.p -0.45  shL.p 0.6  shL.r -0.5  shR.p 1  shR.r -0.5
            elL.p 2  elR.p 2  hipL.p 0.1  hipR.p 0.1  knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(1.5, .out, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(1.95, .inOut, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        return c.build()
    }()

    static let hulkAngry: Clip = {
        var c = ClipBuilder(3.15)
        c.at(0.3, .out, """
            lean.p -0.096  lean.y 0.2  spine.p -0.12  chest.p -0.4  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(0.4, .inOut, """
            lean.p -0.108  lean.y 0.2  spine.p -0.12  chest.p -0.45  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(0.56, .snap, """
            lean.p 0.17  lean.y 0.12  spine.p 0.3  chest.p 0.68  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.62  hipR.p 0.62
            knL.p 1.24  knR.p 1.24  anL.p 0.62  anR.p 0.62
            """)
        c.at(0.78, .out, """
            lean.p 0.187  lean.y 0.12  spine.p 0.33  chest.p 0.748  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.682
            hipR.p 0.682  knL.p 1.364  knR.p 1.364  anL.p 0.682  anR.p 0.682
            """)
        c.at(1.1, .inOut, """
            lean.p 0.1785  lean.y 0.12  spine.p 0.315  chest.p 0.714  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.651
            hipR.p 0.651  knL.p 1.302  knR.p 1.302  anL.p 0.651  anR.p 0.651
            """)
        c.at(1.45, .inOut, """
            lean.p -0.132  lean.y 0.2  spine.p -0.12  chest.p -0.55  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(1.55, .inOut, """
            lean.p -0.138  lean.y 0.2  spine.p -0.12  chest.p -0.575  head.p -0.18  shL.p 2.85
            shL.r -0.28  shR.p 2.85  shR.r -0.28  elL.p 0.5  elR.p 0.5  hipL.p 0.06  hipR.p 0.06
            knL.p 0.12  knR.p 0.12  anL.p 0.06  anR.p 0.06
            """)
        c.at(1.71, .snap, """
            lean.p 0.204  lean.y 0.12  spine.p 0.36  chest.p 0.816  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.744
            hipR.p 0.744  knL.p 1.488  knR.p 1.488  anL.p 0.744  anR.p 0.744
            """)
        c.at(1.95, .out, """
            lean.p 0.2125  lean.y 0.12  spine.p 0.375  chest.p 0.85  head.p 0.15  shL.p 0.35
            shL.r -0.25  shR.p 0.35  shR.r -0.25  elL.p 0.55  elR.p 0.55  hipL.p 0.775
            hipR.p 0.775  knL.p 1.55  knR.p 1.55  anL.p 0.775  anR.p 0.775
            """)
        c.at(2.3, .inOut, """
            lean.p -0.1  spine.p -0.12  chest.p -0.5  head.p -0.55  shL.p 0.35  shL.r 0.95
            shR.p 0.35  shR.r 0.95  elL.p 0.55  elR.p 0.55  hipL.p 0.14  hipL.r 0.12  hipR.p 0.14
            hipR.r 0.12  knL.p 0.28  knR.p 0.28  anL.p 0.14  anR.p 0.14
            """)
        c.at(2.7, .inOut, """
            chest.p 0.12  head.p 0.25  shL.p 0.1  shL.r 0.4  shR.p 0.1  shR.r 0.4  elL.p 0.9
            elR.p 0.9
            """)
        c.event(0.56, .impact(1.2))
        c.event(1.71, .impact(1.6))
        return c.build()
    }()

    static let hulkGrumbleSoft: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.4, .out, """
            chest.p -0.05  head.p 0.15  head.y 0.4  shL.p 0.1  shL.r 0.45  shR.p 0.1  shR.r 0.45
            elL.p 1.35  elR.p 1.35
            """)
        c.at(1.4, .inOut, """
            head.p 0.15  head.y 0.45  shL.p 0.1  shL.r 0.45  shR.p 0.1  shR.r 0.45  elL.p 1.35
            elR.p 1.35
            """)
        c.at(1.9, .inOut, "head.y -0.1  shL.p 0.1  shL.r 0.45  shR.p 0.1  shR.r 0.45  elL.p 1.35  elR.p 1.35")
        return c.build()
    }()

    static let hulkGrumbleHard: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.3, .out, """
            lean.p 0.1  chest.p 0.12  head.p 0.28  shL.p 0.1  shL.r 0.5  shR.p 0.1  shR.r 0.5
            elL.p 1.4  elR.p 1.4
            """)
        c.at(0.7, .inOut, """
            chest.p 0.14  head.p 0.28  head.y -0.4  shL.p 0.1  shL.r 0.5  shR.p 0.1  shR.r 0.5
            elL.p 1.4  elR.p 1.4
            """)
        c.at(0.95, .inOut, """
            head.p 0.28  head.y 0.4  shL.p 0.1  shL.r 0.5  shR.p 0.1  shR.r 0.5  elL.p 1.4
            elR.p 1.4
            """)
        c.at(1.4, .out, """
            spine.p -0.1  chest.p -0.3  head.p -0.2  shL.p 0.1  shL.r 0.55  shR.p 0.1  shR.r 0.55
            elL.p 1.4  elR.p 1.4
            """)
        c.at(2, .inOut, """
            chest.p 0.1  head.p 0.25  shL.p 0.1  shL.r 0.5  shR.p 0.1  shR.r 0.5  elL.p 1.4
            elR.p 1.4
            """)
        return c.build()
    }()

    static let wukongSignature: Clip = {
        var c = ClipBuilder(4)
        c.at(0.45, .out, """
            spine.p 0.1  chest.p 0.34  head.p -0.25  shL.p 0.55  shL.r 0.15  shR.p 0.55
            shR.r 0.15  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipL.r 0.32  hipR.p 0.55  hipR.r 0.32
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.at(0.7, .inOut, """
            spine.p 0.1  chest.p 0.34  head.p -0.25  shL.p 0.55  shL.r 0.15  shR.p 0.55
            shR.r 0.15  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipL.r 0.32  hipR.p 0.55  hipR.r 0.32
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.at(0.95, .inOut, """
            chest.p 0.08  head.p 0  head.y -0.15  head.r 0.18  shL.p 0.7  shL.r 0.1  shR.p 3
            shR.r -0.2  elL.p 1  elR.p 2.3  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24
            anL.p 0.12  anR.p 0.12
            """)
        c.at(1.15, .flow, """
            chest.p 0.08  head.p 0  head.y -0.15  head.r 0.18  shL.p 0.7  shL.r 0.1  shR.p 3
            shR.r -0.2  elL.p 1  elR.p 1.7  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24
            anL.p 0.12  anR.p 0.12
            """)
        c.at(1.35, .flow, """
            chest.p 0.08  head.p 0  head.y -0.15  head.r 0.18  shL.p 0.7  shL.r 0.1  shR.p 3
            shR.r -0.2  elL.p 1  elR.p 2.3  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24
            anL.p 0.12  anR.p 0.12
            """)
        c.at(1.55, .flow, """
            chest.p 0.08  head.p 0  head.y -0.15  head.r 0.18  shL.p 0.7  shL.r 0.1  shR.p 3
            shR.r -0.2  elL.p 1  elR.p 1.7  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24
            anL.p 0.12  anR.p 0.12
            """)
        c.at(1.75, .inOut, """
            chest.p 0.08  head.p 0  head.y -0.15  head.r 0.18  shL.p 0.7  shL.r 0.1  shR.p 3
            shR.r -0.2  elL.p 1  elR.p 2.1  hipL.p 0.12  hipR.p 0.12  knL.p 0.24  knR.p 0.24
            anL.p 0.12  anR.p 0.12
            """)
        c.at(2.1, .inOut, """
            lean.p 0.12  chest.p 0.35  shL.p 0.2  shL.r 0  shR.p 0.2  shR.r 0  elL.p 0.6
            elR.p 0.6  hipL.p 0.7  hipR.p 0.7  knL.p 1.4  knR.p 1.4  anL.p 0.7  anR.p 0.7
            """)
        c.at(2.28, .out, """
            root.y 0.34  chest.p 0.2  head.p -0.1  shL.p 2.7  shL.r 0.6  shR.p 2.7  shR.r 0.6
            elL.p 0.5  elR.p 0.5  hipL.p 1  hipR.p 1  knL.p 1.7  knR.p 1.7  anL.p 0.2  anR.p 0.2
            """)
        c.at(2.62, .inOut, """
            root.y 0.34  chest.p 0.2  head.p -0.1  shL.p 2.7  shL.r 0.6  shR.p 2.7  shR.r 0.6
            elL.p 0.5  elR.p 0.5  hipL.p 1  hipR.p 1  knL.p 1.7  knR.p 1.7  anL.p 0.2  anR.p 0.2
            """)
        c.at(2.95, .accelerate, """
            chest.p 0.3  head.p -0.15  shL.p 0.6  shL.r 0.35  shR.p 0.6  shR.r 0.35  elL.p 0.5
            elR.p 0.5  hipL.p 0.6  hipL.r 0.2  hipR.p 0.6  hipR.r 0.2  knL.p 1.2  knR.p 1.2
            anL.p 0.6  anR.p 0.6
            """)
        c.at(3.15, .out, """
            lean.y 0.2  chest.p -0.12  head.p -0.1  head.r 0.12  shL.p 3  shL.r 0.1  shR.p 0.2
            shR.r 0.75  elL.p 0.35  elR.p 1.7  hipL.p 0.1  hipL.r 0.15  hipR.p 0.1  hipR.r 0.15
            knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(3.55, .inOut, """
            lean.y 0.2  chest.p -0.12  head.p -0.1  head.r 0.12  shL.p 3  shL.r 0.1  shR.p 0.2
            shR.r 0.75  elL.p 0.35  elR.p 1.7  hipL.p 0.1  hipL.r 0.15  hipR.p 0.1  hipR.r 0.15
            knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.event(2.95, .land)
        return c.build()
    }()

    static let wukongPleased: Clip = {
        var c = ClipBuilder(2.2)
        c.at(0.2, .inOut, """
            lean.p 0.12  chest.p 0.35  shL.p 0.2  shL.r 0  shR.p 0.2  shR.r 0  elL.p 0.6
            elR.p 0.6  hipL.p 0.7  hipR.p 0.7  knL.p 1.4  knR.p 1.4  anL.p 0.7  anR.p 0.7
            """)
        c.at(0.38, .out, """
            root.y 0.34  chest.p 0.2  head.p -0.1  shL.p 2.7  shL.r 0.6  shR.p 2.7  shR.r 0.6
            elL.p 0.5  elR.p 0.5  hipL.p 1  hipR.p 1  knL.p 1.7  knR.p 1.7  anL.p 0.2  anR.p 0.2
            """)
        c.at(0.8, .inOut, """
            root.y 0.34  chest.p 0.2  head.p -0.1  shL.p 2.7  shL.r 0.6  shR.p 2.7  shR.r 0.6
            elL.p 0.5  elR.p 0.5  hipL.p 1  hipR.p 1  knL.p 1.7  knR.p 1.7  anL.p 0.2  anR.p 0.2
            """)
        c.at(1.1, .accelerate, """
            chest.p 0.3  head.p -0.15  shL.p 0.6  shL.r 0.35  shR.p 0.6  shR.r 0.35  elL.p 0.5
            elR.p 0.5  hipL.p 0.6  hipL.r 0.2  hipR.p 0.6  hipR.r 0.2  knL.p 1.2  knR.p 1.2
            anL.p 0.6  anR.p 0.6
            """)
        c.at(1.3, .out, """
            lean.y 0.2  chest.p -0.12  head.p -0.1  head.r 0.12  shL.p 3  shL.r 0.1  shR.p 0.2
            shR.r 0.75  elL.p 0.35  elR.p 1.7  hipL.p 0.1  hipL.r 0.15  hipR.p 0.1  hipR.r 0.15
            knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.at(1.75, .inOut, """
            lean.y 0.2  chest.p -0.12  head.p -0.1  head.r 0.12  shL.p 3  shL.r 0.1  shR.p 0.2
            shR.r 0.75  elL.p 0.35  elR.p 1.7  hipL.p 0.1  hipL.r 0.15  hipR.p 0.1  hipR.r 0.15
            knL.p 0.2  knR.p 0.2  anL.p 0.1  anR.p 0.1
            """)
        c.event(1.1, .land)
        return c.build()
    }()

    static let wukongAngry: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.25, .out, """
            spine.p 0.1  chest.p 0.34  head.p -0.25  shL.p 0.55  shL.r 0.15  shR.p 0.55
            shR.r 0.15  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipL.r 0.32  hipR.p 0.55  hipR.r 0.32
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.at(0.5, .inOut, """
            spine.p 0.1  chest.p 0.34  head.p -0.25  shL.p 0.55  shL.r 0.15  shR.p 0.55
            shR.r 0.15  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipL.r 0.32  hipR.p 0.55  hipR.r 0.32
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.at(0.65, .out, """
            root.y 0.1  chest.p -0.2  head.p -0.2  shL.p 2.4  shL.r 0.4  shR.p 2.4  shR.r 0.4
            elL.p 0.5  elR.p 0.5  hipL.p 0.2  hipR.p 0.2  knL.p 0.4  knR.p 0.4  anL.p 0.2
            anR.p 0.2
            """)
        c.at(0.82, .snap, """
            chest.p 0.4  head.p 0.2  shL.p 0.4  shL.r 0.2  shR.p 0.4  shR.r 0.2  elL.p 1  elR.p 1
            hipL.p 0.5  hipR.p 0.5  knL.p 1  knR.p 1  anL.p 0.5  anR.p 0.5
            """)
        c.at(1.05, .out, """
            root.y 0.1  chest.p -0.2  head.p -0.2  shL.p 2.4  shL.r 0.4  shR.p 2.4  shR.r 0.4
            elL.p 0.5  elR.p 0.5  hipL.p 0.2  hipR.p 0.2  knL.p 0.4  knR.p 0.4  anL.p 0.2
            anR.p 0.2
            """)
        c.at(1.22, .snap, """
            chest.p 0.4  head.p 0.2  shL.p 0.4  shL.r 0.2  shR.p 0.4  shR.r 0.2  elL.p 1  elR.p 1
            hipL.p 0.5  hipR.p 0.5  knL.p 1  knR.p 1  anL.p 0.5  anR.p 0.5
            """)
        c.at(1.45, .out, """
            root.y 0.1  chest.p -0.2  head.p -0.2  shL.p 2.4  shL.r 0.4  shR.p 2.4  shR.r 0.4
            elL.p 0.5  elR.p 0.5  hipL.p 0.2  hipR.p 0.2  knL.p 0.4  knR.p 0.4  anL.p 0.2
            anR.p 0.2
            """)
        c.at(1.62, .snap, """
            chest.p 0.4  head.p 0.2  shL.p 0.4  shL.r 0.2  shR.p 0.4  shR.r 0.2  elL.p 1  elR.p 1
            hipL.p 0.5  hipR.p 0.5  knL.p 1  knR.p 1  anL.p 0.5  anR.p 0.5
            """)
        c.at(2, .inOut, """
            spine.p 0.1  chest.p 0.34  head.p -0.25  shL.p 0.55  shL.r 0.15  shR.p 0.55
            shR.r 0.15  elL.p 0.7  elR.p 0.7  hipL.p 0.55  hipL.r 0.32  hipR.p 0.55  hipR.r 0.32
            knL.p 1.1  knR.p 1.1  anL.p 0.55  anR.p 0.55
            """)
        c.event(0.82, .impact(0.5))
        c.event(1.22, .impact(0.5))
        c.event(1.62, .impact(0.7))
        return c.build()
    }()

    static let wukongGrumbleSoft: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.35, .out, """
            head.p 0.1  head.y 0.4  head.r 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55
            elL.p 2.3  elR.p 2.3
            """)
        c.at(1.4, .inOut, """
            head.y 0.45  head.r 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.9, .inOut, "head.y -0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()

    static let wukongGrumbleHard: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.3, .out, """
            head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3
            hipL.p 0.15  hipR.p 0.15  knL.p 0.3  knR.p 0.3  anL.p 0.15  anR.p 0.15
            """)
        c.at(0.7, .inOut, """
            head.p 0.2  head.y -0.4  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipL.p 0.15  hipR.p 0.15  knL.p 0.3  knR.p 0.3  anL.p 0.15  anR.p 0.15
            """)
        c.at(1, .inOut, """
            head.p 0.2  head.y 0.4  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3  hipL.p 0.15  hipR.p 0.15  knL.p 0.3  knR.p 0.3  anL.p 0.15  anR.p 0.15
            """)
        c.at(2, .inOut, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()

    static let standardSignature: Clip = {
        var c = ClipBuilder(2.75)
        c.at(0.3, .back, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.3
            """)
        c.at(0.55, .flow, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.9
            """)
        c.at(0.8, .flow, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.1
            """)
        c.at(1.05, .flow, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.9
            """)
        c.at(1.3, .flow, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.1
            """)
        c.at(1.55, .flow, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.9
            """)
        c.at(1.9, .inOut, """
            lean.r 0.02  chest.p -0.04  head.y -0.15  head.r 0.12  shR.p 0.2  shR.r 2.35
            elR.p 0.3
            """)
        c.at(2.3, .inOut, "head.p 0.1")
        return c.build()
    }()

    static let standardPleased: Clip = {
        var c = ClipBuilder(1.9)
        c.at(0.18, .inOut, """
            chest.p 0.12  shL.p 0.5  shR.p 0.5  elL.p 0.5  elR.p 0.5  hipL.p 0.25  hipR.p 0.25
            knL.p 0.5  knR.p 0.5  anL.p 0.25  anR.p 0.25
            """)
        c.at(0.4, .out, """
            root.y 0.22  chest.p -0.15  shL.p 2.6  shL.r 0.6  shR.p 2.6  shR.r 0.6  elL.p 0.3
            elR.p 0.3  hipL.p 0.3  hipR.p 0.3  knL.p 0.7  knR.p 0.7  anL.p -0.2  anR.p -0.2
            """)
        c.at(0.75, .accelerate, "root.y 0  shL.p 1.4  shL.r 0.5  shR.p 1.4  shR.r 0.5  elL.p 0.3  elR.p 0.3")
        c.at(0.88, .out, """
            shL.p 0.6  shR.p 0.6  elL.p 0.5  elR.p 0.5  hipL.p 0.25  hipR.p 0.25  knL.p 0.5
            knR.p 0.5  anL.p 0.25  anR.p 0.25
            """)
        c.at(1.1, .out, """
            root.y 0.24  chest.p -0.15  shL.p 2.6  shL.r 0.6  shR.p 2.6  shR.r 0.6  elL.p 0.3
            elR.p 0.3  hipL.p 0.3  hipR.p 0.3  knL.p 0.7  knR.p 0.7  anL.p -0.2  anR.p -0.2
            """)
        c.at(1.45, .accelerate, "root.y 0  shL.p 1.4  shL.r 0.4  shR.p 1.4  shR.r 0.4  elL.p 0.3  elR.p 0.3")
        c.event(0.75, .land)
        c.event(1.45, .land)
        return c.build()
    }()

    static let standardAngry: Clip = {
        var c = ClipBuilder(2.45)
        c.at(0.2, .inOut, """
            chest.y -0.15  shL.p 0.4  shL.r 0.1  shR.p 0.4  shR.r 0.1  elL.p 1.2  elR.p 1.2
            hipR.p 0.7  knR.p 1.1
            """)
        c.at(0.3, .snap, """
            chest.p 0.12  chest.y -0.15  shL.p 0.2  shL.r 0.1  shR.p 0.2  shR.r 0.1  elL.p 1.1
            elR.p 1.1  hipR.p 0.1
            """)
        c.at(0.52, .inOut, """
            chest.y 0.15  shL.p 0.4  shL.r 0.1  shR.p 0.4  shR.r 0.1  elL.p 1.2  elR.p 1.2
            hipL.p 0.7  knL.p 1.1
            """)
        c.at(0.62, .snap, """
            chest.p 0.12  chest.y 0.15  shL.p 0.2  shL.r 0.1  shR.p 0.2  shR.r 0.1  elL.p 1.1
            elR.p 1.1  hipL.p 0.1
            """)
        c.at(0.84, .inOut, """
            chest.y -0.15  shL.p 0.4  shL.r 0.1  shR.p 0.4  shR.r 0.1  elL.p 1.2  elR.p 1.2
            hipR.p 0.7  knR.p 1.1
            """)
        c.at(0.94, .snap, """
            chest.p 0.12  chest.y -0.15  shL.p 0.2  shL.r 0.1  shR.p 0.2  shR.r 0.1  elL.p 1.1
            elR.p 1.1  hipR.p 0.1
            """)
        c.at(1.3, .inOut, """
            head.p 0.25  head.y -0.4  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.6, .inOut, """
            head.p 0.25  head.y 0.4  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(2, .inOut, "head.p 0.2  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.event(0.3, .impact(0.5))
        c.event(0.62, .impact(0.5))
        c.event(0.94, .impact(0.7))
        return c.build()
    }()

    static let standardGrumbleSoft: Clip = {
        var c = ClipBuilder(2.4)
        c.at(0.4, .out, """
            head.p 0.1  head.y 0.4  head.r 0.12  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55
            elL.p 2.3  elR.p 2.3
            """)
        c.at(1.4, .inOut, """
            head.y 0.45  head.r 0.12  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3
            elR.p 2.3
            """)
        c.at(1.9, .inOut, "head.y -0.1  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()

    static let standardGrumbleHard: Clip = {
        var c = ClipBuilder(2.65)
        c.at(0.3, .out, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.at(0.5, .inOut, """
            head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3
            hipR.p 0.5  knR.p 0.9
            """)
        c.at(0.65, .accelerate, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.at(0.8, .inOut, """
            head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3
            hipR.p 0.5  knR.p 0.9
            """)
        c.at(0.95, .accelerate, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.at(1.1, .inOut, """
            head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3
            hipR.p 0.5  knR.p 0.9
            """)
        c.at(1.25, .accelerate, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.at(1.4, .inOut, """
            head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3
            hipR.p 0.5  knR.p 0.9
            """)
        c.at(1.55, .accelerate, "head.p 0.15  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        c.at(2.2, .inOut, "head.p 0.1  shL.p 0.95  shL.r -0.55  shR.p 0.95  shR.r -0.55  elL.p 2.3  elR.p 2.3")
        return c.build()
    }()
}
