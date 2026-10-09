import Foundation
import QuartzCore
import SipStretchCore

/// Plays a skeleton-driven character's body animation, one frame at a time.
///
/// There is always a *base* motion (walking, standing around alive, stretching) and, on top of it, at
/// most one *gesture* (a keyframed clip such as a signature move). Changing the base blends from where
/// the body was, so a walk settles into standing instead of snapping, and a gesture that gets cut off
/// fades out over a moment instead of vanishing.
///
/// `tick()` runs on SceneKit's render thread (it's driven by an action on the scene), while the rest is
/// called from the main thread, hence the lock.
final class PoseDriver {
    enum Base {
        case idle
        case walk(cycle: Double, mood: GaitMood, stride: Double?)
        case stretch
    }

    private struct Gesture {
        var clip: Clip
        var start: Double
        var speed: Double
        var intensity: Double
    }

    private let skeleton: SkeletonRig
    private let style: MotionStyle
    private let lock = NSLock()
    private var base = Base.idle
    private var baseStart = CACurrentMediaTime()
    /// The base motion as last shown: where a blend to the next one starts from.
    private var lastBase = Pose()
    private var blendFrom: Pose?
    private var blendStart = 0.0
    private var blendDuration = 0.35
    private var gesture: Gesture?
    private var fading: (gesture: Gesture, since: Double)?

    init(skeleton: SkeletonRig, style: MotionStyle) {
        self.skeleton = skeleton
        self.style = style
    }

    // MARK: Main thread

    /// Switches what the body does all the time, blending over `blend` seconds.
    func setBase(_ new: Base, blend: Double = 0.35) {
        lock.lock()
        defer { lock.unlock() }
        if case .idle = base, case .idle = new { return }
        let now = CACurrentMediaTime()
        blendFrom = lastBase
        blendStart = now
        blendDuration = blend
        base = new
        baseStart = now
    }

    /// Plays a gesture on top of the base motion. `speed` above 1 plays it faster, `intensity` above 1 exaggerates it.
    func play(_ clip: Clip, speed: Double = 1, intensity: Double = 1) {
        lock.lock()
        defer { lock.unlock() }
        let now = CACurrentMediaTime()
        if let current = gesture { fading = (current, now) }
        gesture = Gesture(clip: clip, start: now, speed: max(0.1, speed), intensity: intensity)
    }

    /// Lets the current gesture fade out.
    func stopGesture() {
        lock.lock()
        defer { lock.unlock() }
        if let current = gesture { fading = (current, CACurrentMediaTime()) }
        gesture = nil
    }

    // MARK: Render thread

    /// Works out this frame's pose and applies it to the skeleton.
    func tick() {
        lock.lock()
        defer { lock.unlock() }
        let now = CACurrentMediaTime()
        var pose = basePose(at: now)
        lastBase = pose

        if let leaving = fading {
            let fade = (now - leaving.since) / 0.25
            let time = (now - leaving.gesture.start) * leaving.gesture.speed
            if fade >= 1 || time >= leaving.gesture.clip.duration {
                fading = nil
            } else {
                leaving.gesture.clip.add(to: &pose, at: time, scale: leaving.gesture.intensity * (1 - fade))
            }
        }
        if let playing = gesture {
            let time = (now - playing.start) * playing.speed
            if time >= playing.clip.duration {
                gesture = nil
            } else {
                playing.clip.add(to: &pose, at: time, scale: playing.intensity)
            }
        }
        skeleton.apply(pose)
    }

    private func basePose(at now: Double) -> Pose {
        var pose: Pose
        switch base {
        case .idle:
            pose = Motion.idle(time: now, style: style)
        case .walk(let cycle, let mood, let stride):
            pose = Motion.walk(phase: (now - baseStart) / cycle, style: style, mood: mood, stride: stride)
        case .stretch:
            pose = Motion.stretch(time: now - baseStart)
        }
        if let from = blendFrom {
            let u = (now - blendStart) / blendDuration
            if u >= 1 {
                blendFrom = nil
            } else {
                pose = from.blended(to: pose, u * u * (3 - 2 * u))
            }
        }
        return pose
    }
}
