import Foundation
import Testing
@testable import SipStretchCore

@Suite struct MotionTests {
    private func allClips() -> [(name: String, clip: Clip)] {
        var result: [(name: String, clip: Clip)] = []
        for style in MotionStyle.allCases {
            result.append(("\(style) signature", style.signature))
            result.append(("\(style) pleased", style.pleased))
            result.append(("\(style) angry", style.angry))
            result.append(("\(style) grumble 1", style.grumble(level: 1)))
            result.append(("\(style) grumble 2", style.grumble(level: 2)))
        }
        return result
    }

    @Test func jointCodesAreUniqueAndRoundTrip() {
        let codes = Joint.allCases.map(\.code)
        #expect(Set(codes).count == codes.count)
        for joint in Joint.allCases {
            #expect(Joint.named(joint.code) == joint)
            for (axis, letter) in [(PoseAxis.pitch, "p"), (.yaw, "y"), (.roll, "r")] {
                #expect(Pose.channel(named: "\(joint.code).\(letter)") == Pose.index(joint, axis))
            }
        }
        #expect(Pose.channel(named: "root.y") == Pose.rootY)
        #expect(Pose.channel(named: "lean.r") == Pose.leanRoll)
        #expect(Pose.channel(named: "tail.p") == nil)
        #expect(Pose.channel(named: "head") == nil)
    }

    @Test func everyClipIsWellFormedAndStartsAndEndsAtRest() {
        for (name, clip) in allClips() {
            #expect(clip.unrecognized.isEmpty, "\(name) mentions unknown channels: \(clip.unrecognized)")
            #expect(clip.duration > 1, "\(name)")
            #expect(clip.sample(at: 0) == Pose(), "\(name) must start at rest")
            #expect(clip.sample(at: clip.duration) == Pose(), "\(name) must end at rest")
            for event in clip.events {
                #expect(event.time > 0 && event.time < clip.duration, "\(name) has an event outside the clip")
            }
        }
    }

    @Test func clipsMoveTheBodyAndStayWithinHumanLimits() {
        for (name, clip) in allClips() {
            var largest = 0.0
            var peak = Pose()
            var time = 0.0
            while time <= clip.duration {
                let pose = clip.sample(at: time)
                for (i, value) in pose.values.enumerated() where abs(value) > abs(peak.values[i]) { peak.values[i] = value }
                largest = max(largest, pose.values.map { abs($0) }.max() ?? 0)
                time += 0.02
            }
            #expect(largest > 0.5, "\(name) barely moves")
            #expect(largest < 3.3, "\(name) bends a joint past a full overhead reach")
            #expect(abs(peak.values[Pose.rootY]) < 0.6, "\(name) jumps too far")
        }
    }

    @Test func sampledPosesAreContinuous() {
        // No clip should jump between two neighbouring frames (60 fps): at most a fast punch's worth of motion.
        // The speed limit is high because a slam really is quick, but it catches a keyframe typo.
        for (name, clip) in allClips() {
            var previous = clip.sample(at: 0)
            var time = 1.0 / 60
            while time <= clip.duration {
                let pose = clip.sample(at: time)
                let step = zip(pose.values, previous.values).map { abs($0 - $1) }.max() ?? 0
                #expect(step < 0.8, "\(name) jumps by \(step) at \(time)s")
                previous = pose
                time += 1.0 / 60
            }
        }
    }

    @Test func keyframeTextBuildsTheExpectedCurve() {
        var builder = ClipBuilder(2)
        builder.at(1, .linear, "head.y 1  shL.p 2")
        builder.event(0.5, .impact(1.5))
        let clip = builder.build()
        #expect(clip.unrecognized.isEmpty)
        #expect(clip.events == [ClipEvent(time: 0.5, kind: .impact(1.5))])
        #expect(abs(clip.sample(at: 0.5)[.head, .yaw] - 0.5) < 1e-9, "eases up from 0 at the start")
        #expect(abs(clip.sample(at: 1)[.head, .yaw] - 1) < 1e-9)
        #expect(abs(clip.sample(at: 1.5)[.shoulderL, .pitch] - 1) < 1e-9, "eases back down to 0 at the end")
        #expect(clip.duration == 2, "the tail after the last keyframe is already long enough")
        var tight = ClipBuilder(1)
        tight.at(0.9, .inOut, "head.y 1")
        #expect(tight.build().duration > 1.3, "a clip gets a settle time after its last keyframe")
        #expect(clip.sample(at: 0.5)[.hipL, .pitch] == 0)

        var typo = ClipBuilder(1)
        typo.at(0.5, .inOut, "headd.y 1  head.y 0.5")
        #expect(typo.build().unrecognized == ["headd.y"])
    }

    @Test func everyEasingHitsItsKeyframes() {
        for ease in [Ease.inOut, .out, .accelerate, .back, .snap, .linear, .flow] {
            var builder = ClipBuilder(3)
            builder.at(1, ease, "head.y 1")
            builder.at(2, ease, "head.y -1")
            let clip = builder.build()
            #expect(abs(clip.sample(at: 1)[.head, .yaw] - 1) < 1e-9, "\(ease)")
            #expect(abs(clip.sample(at: 2)[.head, .yaw] + 1) < 1e-9, "\(ease)")
        }
    }

    @Test func walkRepeatsEveryCycleWithLegsHalfACycleApart() {
        for style in MotionStyle.allCases {
            for mood in [GaitMood.normal, .happy, .angry] {
                for phase in stride(from: 0.0, to: 1.0, by: 0.07) {
                    let a = Motion.walk(phase: phase, style: style, mood: mood)
                    let b = Motion.walk(phase: phase + 1, style: style, mood: mood)
                    for (x, y) in zip(a.values, b.values) { #expect(abs(x - y) < 1e-9) }
                    let later = Motion.walk(phase: phase + 0.5, style: style, mood: mood)
                    #expect(abs(a[.hipL, .pitch] - later[.hipR, .pitch]) < 1e-9)
                    #expect(abs(a[.kneeL, .pitch] - later[.kneeR, .pitch]) < 1e-9)
                    #expect(abs(a[.shoulderL, .pitch] - later[.shoulderR, .pitch]) < 1e-9)
                }
            }
        }
    }

    @Test func walkBendsKneesOnlyForwardAndFollowsTheRequestedStride() {
        var widest = 0.0
        for phase in stride(from: 0.0, to: 1.0, by: 0.01) {
            let pose = Motion.walk(phase: phase, style: .kratos, stride: 0.2)
            #expect(pose[.kneeL, .pitch] >= 0 && pose[.kneeR, .pitch] >= 0, "knees don't bend backward")
            widest = max(widest, abs(pose[.hipL, .pitch] - 0.04))
        }
        #expect(abs(widest - 0.2) < 0.01)
    }

    @Test func idleAndStretchStayGentleAndLoop() {
        for style in MotionStyle.allCases {
            for time in stride(from: 0.0, to: 60.0, by: 0.5) {
                let pose = Motion.idle(time: time, style: style)
                #expect(pose.values.map { abs($0) }.max()! < 0.35)
            }
        }
        for time in stride(from: 0.0, to: 5.0, by: 0.2) {
            let a = Motion.stretch(time: time)
            let b = Motion.stretch(time: time + 4.8)
            for (x, y) in zip(a.values, b.values) { #expect(abs(x - y) < 1e-9) }
        }
        #expect(Motion.stretch(time: 0) == Pose())
    }

    @Test func eachCharacterGetsItsOwnStyle() {
        #expect(MotionStyle(personality: .kratos) == .kratos)
        #expect(MotionStyle(personality: .kungFuPanda) == .panda)
        #expect(MotionStyle(personality: .hulk) == .hulk)
        #expect(MotionStyle(personality: .wukong) == .wukong)
        #expect(MotionStyle(personality: .sassy) == .standard)
        let durations = [MotionStyle.kratos, .panda, .hulk, .wukong, .standard].map { $0.signature.duration }
        #expect(Set(durations).count == durations.count, "signature moves shouldn't be copies of each other")
    }
}
