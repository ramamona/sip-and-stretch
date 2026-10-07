import AppKit
import SceneKit
import SipStretchCore

// Each character's body language: signature moves, how they celebrate, how they sulk.
//
// Axes: an arm pivot rotated about X swings forward when the angle is negative (-π/2 is straight out
// in front, about -3 is overhead). Rotated about Z, the right arm goes outward and up for positive
// angles (the left arm mirrors it).

enum WalkMood { case normal, happy, angry }

enum AvatarMove {
    /// Show off: swing the axe, do kung fu, spin the staff, smash.
    case signature
    /// You did it: celebrate in character.
    case pleased
    /// You skipped it: sulk, stomp, turn away.
    case angry
    /// Still waiting. Level 1 is a foot tap, 2 adds stomping, 3 is nearly furious.
    case grumble(Int)
}

private func turn(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ time: TimeInterval, _ mode: SCNActionTimingMode = .easeInEaseOut) -> SCNAction {
    let action = SCNAction.rotateTo(x: x, y: y, z: z, duration: time)
    action.timingMode = mode
    return action
}

private func wait(_ time: TimeInterval) -> SCNAction { SCNAction.wait(duration: time) }

private func hopAction(_ height: CGFloat, _ time: TimeInterval) -> SCNAction {
    let up = SCNAction.moveBy(x: 0, y: height, z: 0, duration: time / 2)
    let down = SCNAction.moveBy(x: 0, y: -height, z: 0, duration: time / 2)
    up.timingMode = .easeOut
    down.timingMode = .easeIn
    return SCNAction.sequence([up, down])
}

/// Spins a limb all the way around `turns` times, then snaps the angle back to 0 (no visible jump).
private func whirl(turns: CGFloat, time: TimeInterval, z: CGFloat) -> SCNAction {
    SCNAction.sequence([
        SCNAction.rotateTo(x: -turns * 2 * .pi, y: 0, z: z, duration: time),
        SCNAction.run { node in node.eulerAngles.x = 0 },
    ])
}

extension AvatarRig {
    /// How high (metres) the character can jump before its head leaves the stage.
    private var headroom: CGFloat { max(0.1, AvatarStage.visibleHeight - AvatarStage.groundInset - 0.1 - height) }

    private func hop(_ height: CGFloat, _ time: TimeInterval) -> SCNAction { hopAction(min(height, headroom), time) }

    private func restRight(_ time: TimeInterval = 0.25) -> SCNAction { turn(0, 0, armSplay, time) }
    private func restLeft(_ time: TimeInterval = 0.25) -> SCNAction { turn(0, 0, -armSplay, time) }

    /// Runs one list of actions per node, all starting now.
    private func play(_ tracks: [(SCNNode, [SCNAction])]) {
        for (node, actions) in tracks {
            node.removeAction(forKey: "move")
            node.runAction(SCNAction.sequence(actions), forKey: "move")
        }
    }

    /// Plays `move` and returns roughly how long it lasts, so the caller knows when it can stop rendering.
    @discardableResult
    func perform(_ move: AvatarMove) -> TimeInterval {
        stopActivities(settle: true)
        switch move {
        case .signature: return signature()
        case .pleased:
            setTint(nil)
            return pleased()
        case .angry: return angry(turnAway: true)
        case .grumble(let level): return grumble(level)
        }
    }

    // MARK: Tint

    /// Flushes the whole character a color (red when furious). `nil` restores the original look.
    func setTint(_ color: NSColor?, amount: CGFloat = 0.5) {
        root.enumerateHierarchy { node, _ in
            guard let materials = node.geometry?.materials else { return }
            for material in materials where material.lightingModel != .constant {
                let id = ObjectIdentifier(material)
                if tintBackup[id] == nil { tintBackup[id] = (material.emission.contents, material.emission.intensity) }
                if let color {
                    material.emission.contents = color
                    material.emission.intensity = amount
                } else if let backup = tintBackup[id] {
                    material.emission.contents = backup.contents
                    material.emission.intensity = backup.intensity
                }
            }
        }
        if color == nil { tintBackup.removeAll() }
    }

    // MARK: Effects

    /// A ring of dust racing outward from the feet, `delay` seconds from now.
    private func shockwave(after delay: TimeInterval) {
        let ring = ringNode(radius: 0.3, pipe: 0.035, 0xFFFFFF, at: vec(0, 0.03, 0))
        ring.opacity = 0
        root.addChildNode(ring)
        ring.runAction(SCNAction.sequence([
            wait(delay),
            SCNAction.fadeOpacity(to: 0.8, duration: 0),
            SCNAction.group([SCNAction.scale(to: 3.4, duration: 0.45), SCNAction.fadeOut(duration: 0.45)]),
            SCNAction.removeFromParentNode(),
        ]))
    }

    /// The ground jolts for a moment.
    private func quake(after delay: TimeInterval) {
        func jolt(_ dx: CGFloat) -> SCNAction { SCNAction.moveBy(x: dx, y: 0, z: 0, duration: 0.04) }
        root.runAction(SCNAction.sequence([wait(delay), jolt(0.04), jolt(-0.08), jolt(0.08), jolt(-0.08), jolt(0.04)]), forKey: "quake")
    }

    /// A somersault around the middle of the body (the Monkey King's cloud flip).
    private func flip() {
        let middle = height * 0.5
        bobNode.pivot = SCNMatrix4MakeTranslation(0, middle, 0)
        bobNode.position = vec(0, middle, 0)
        let rise = SCNAction.moveBy(x: 0, y: min(0.35, headroom), z: 0, duration: 0.35)
        let fall = SCNAction.moveBy(x: 0, y: -min(0.35, headroom), z: 0, duration: 0.35)
        rise.timingMode = .easeOut
        fall.timingMode = .easeIn
        let spin = SCNAction.rotateTo(x: -2 * .pi, y: 0, z: 0, duration: 0.7)
        let reset = SCNAction.run { node in
            node.pivot = SCNMatrix4Identity
            node.position = SCNVector3Zero
            node.eulerAngles = SCNVector3Zero
        }
        bobNode.runAction(SCNAction.sequence([SCNAction.group([SCNAction.sequence([rise, fall]), spin]), reset]), forKey: "move")
    }

    // MARK: Signature moves

    private func signature() -> TimeInterval {
        if isModel { return modelSignature() }
        switch character {
        case .kratos:
            // Axe over the head and down, blades of chaos lashing, then a whirl of both.
            play([
                (rightArm, [turn(-2.9, 0, armSplay, 0.35), wait(0.1), turn(0, 0, armSplay, 0.12, .easeIn), wait(0.3), whirl(turns: 2, time: 0.7, z: armSplay), restRight()]),
                (leftArm, [wait(0.55), turn(-1.6, 0, -0.3, 0.12), turn(0.4, 0, -0.3, 0.12), turn(-1.6, 0, -0.3, 0.12), turn(0.4, 0, -0.3, 0.12), whirl(turns: 2, time: 0.6, z: -armSplay), restLeft()]),
                (bobNode, [wait(0.45), hop(0.05, 0.25)]),
                (yawNode, [turn(0, 0.3, 0, 0.3), wait(0.6), turn(0, -0.25, 0, 0.35), turn(0, 0, 0, 0.4)]),
            ])
            shockwave(after: 0.5)
            return 2.3
        case .kungFuPanda:
            // Guard stance, a flurry of punches, then a high kick.
            play([
                (rightArm, [wait(0.3), turn(-1.55, 0, 0.15, 0.1), turn(-0.6, 0, 0.5, 0.12), wait(0.2), turn(-1.55, 0, 0.15, 0.1), turn(-0.6, 0, 0.5, 0.12), wait(0.3), restRight()]),
                (leftArm, [wait(0.3), turn(-0.6, 0, -0.5, 0.12), turn(-1.55, 0, -0.15, 0.1), turn(-0.6, 0, -0.5, 0.12), wait(0.2), turn(-0.9, 0, -0.9, 0.2), wait(0.45), restLeft()]),
                (rightLeg, [wait(1.0), turn(-1.5, 0, 0, 0.2), wait(0.2), turn(0, 0, 0, 0.2)]),
                (bobNode, [wait(0.95), hop(0.08, 0.5)]),
                (yawNode, [turn(0, 0.5, 0, 0.25), wait(0.7), turn(0, 0.9, 0, 0.2), wait(0.45), turn(0, 0, 0, 0.3)]),
            ])
            return 2.1
        case .wukong:
            // Staff held overhead and twirled like a windmill, then slammed down.
            play([
                (rightArm, [turn(-0.3, 0, 2.3, 0.3), wait(1.1), turn(-2.6, 0, 0.1, 0.2), turn(0, 0, armSplay, 0.16, .easeIn), wait(0.3), restRight()]),
                (leftArm, [turn(-0.5, 0, -0.7, 0.3), wait(1.1), turn(0, 0, -2.2, 0.2), wait(0.5), restLeft()]),
                (bobNode, [wait(1.6), hop(0.12, 0.3)]),
                (yawNode, [turn(0, 0.3, 0, 0.3), wait(1.1), turn(0, 0, 0, 0.4)]),
            ])
            prop?.runAction(SCNAction.sequence([
                wait(0.3),
                SCNAction.rotateTo(x: 0, y: 0, z: -4 * .pi, duration: 1.1),
                SCNAction.run { node in node.eulerAngles = SCNVector3Zero },
            ]), forKey: "move")
            shockwave(after: 1.7)
            return 2.4
        case .hulk:
            return hulkSmash(times: 1, thenJump: true)
        case .robot:
            // Robot dance: arms pump in turn, head scanning.
            let pump: [SCNAction] = [turn(-1.2, 0, 0.3, 0.2), turn(0, 0, armSplay, 0.2)]
            let pumpLeft: [SCNAction] = [turn(-1.2, 0, -0.3, 0.2), turn(0, 0, -armSplay, 0.2)]
            var rightTrack: [SCNAction] = []
            var leftTrack: [SCNAction] = [wait(0.2)]
            for _ in 0..<3 {
                rightTrack += pump
                leftTrack += pumpLeft
            }
            rightTrack.append(restRight())
            leftTrack.append(restLeft())
            play([
                (rightArm, rightTrack),
                (leftArm, leftTrack),
                (head, [turn(0, 0.6, 0, 0.3), turn(0, -0.6, 0, 0.5), turn(0, 0, 0, 0.3)]),
            ])
            return 1.7
        case .human:
            wave()
            play([(bobNode, [wait(0.4), hop(0.1, 0.3), hop(0.1, 0.3)])])
            return 2.3
        case .drip, .model:
            play([
                (yawNode, [turn(0, 2 * .pi, 0, 0.9), SCNAction.run { node in node.eulerAngles.y = 0 }]),
                (bobNode, [hop(0.3, 0.45), hop(0.3, 0.45)]),
                (rightArm, [turn(0, 0, 2.4, 0.2), wait(0.6), restRight(0.2)]),
                (leftArm, [turn(0, 0, -2.4, 0.2), wait(0.6), restLeft(0.2)]),
            ])
            return 1.2
        }
    }

    /// Both fists up, a thunderous slam, then (optionally) bounding around.
    private func hulkSmash(times: Int, thenJump: Bool) -> TimeInterval {
        var right: [SCNAction] = []
        var left: [SCNAction] = []
        var bob: [SCNAction] = []
        var time: TimeInterval = 0
        for _ in 0..<times {
            right += [turn(-3.0, 0, 0.35, 0.35), wait(0.12), turn(0, 0, 0.35, 0.1, .easeIn), wait(0.2)]
            left += [turn(-3.0, 0, -0.35, 0.35), wait(0.12), turn(0, 0, -0.35, 0.1, .easeIn), wait(0.2)]
            bob += [wait(0.47), hopAction(0.06, 0.15), wait(0.2)]
            shockwave(after: time + 0.57)
            quake(after: time + 0.57)
            time += 0.77
        }
        if thenJump {
            right += [turn(0, 0, 2.5, 0.2), wait(0.8), restRight()]
            left += [turn(0, 0, -2.5, 0.2), wait(0.8), restLeft()]
            bob += [wait(0.2), hop(0.6, 0.5), hop(0.6, 0.5)]
            time += 1.25
        } else {
            right += [restRight()]
            left += [restLeft()]
            time += 0.25
        }
        play([
            (rightArm, right),
            (leftArm, left),
            (bobNode, bob),
            (head, [turn(-0.4, 0, 0, 0.3), wait(0.3), turn(0.15, 0, 0, 0.1), wait(0.3), turn(0, 0, 0, 0.3)]),
        ])
        return time + 0.3
    }

    // MARK: Pleased

    private func pleased() -> TimeInterval {
        if isModel { return modelPleased() }
        let front = (yawNode, [turn(0, 0, 0, 0.25)])
        switch character {
        case .kratos:
            // A curt nod and the axe raised in salute.
            play([
                (rightArm, [turn(-2.9, 0, armSplay, 0.3), wait(0.7), restRight(0.3)]),
                (head, [wait(0.2), turn(0.35, 0, 0, 0.25), wait(0.3), turn(0, 0, 0, 0.25)]),
                front,
            ])
            return 1.5
        case .wukong:
            // The cloud somersault, with a flourish.
            flip()
            play([
                (rightArm, [turn(0, 0, 2.6, 0.25), wait(0.7), restRight()]),
                (leftArm, [turn(0, 0, -2.6, 0.25), wait(0.7), restLeft()]),
                front,
            ])
            return 1.4
        case .hulk:
            // Chest beating, then a big happy bound.
            let beatRight: [SCNAction] = [turn(-0.9, 0, 0.45, 0.12), turn(-0.2, 0, 0.45, 0.12)]
            let beatLeft: [SCNAction] = [turn(-0.9, 0, -0.45, 0.12), turn(-0.2, 0, -0.45, 0.12)]
            var rightTrack: [SCNAction] = [wait(0.1)]
            var leftTrack: [SCNAction] = [wait(0.22)]
            for _ in 0..<3 {
                rightTrack += beatRight
                leftTrack += beatLeft
            }
            rightTrack += [turn(0, 0, 2.5, 0.2), wait(0.5), restRight()]
            leftTrack += [turn(0, 0, -2.5, 0.2), wait(0.4), restLeft()]
            play([
                (rightArm, rightTrack),
                (leftArm, leftTrack),
                (bobNode, [wait(1.6), hop(0.6, 0.5)]),
                (head, [turn(-0.35, 0, 0, 0.3), wait(1.3), turn(0, 0, 0, 0.3)]),
                front,
            ])
            return 2.4
        default:
            cheer()
            play([front])
            return 1.4
        }
    }

    // MARK: Angry

    /// Flushes red, shakes the head, stomps, and (when `turnAway`) turns their back on you.
    private func angry(turnAway: Bool) -> TimeInterval {
        setTint(NSColor(hex: 0xFF3B30), amount: min(0.9, 0.7 + 0.2 * rage))
        // A roar: swell up, then a shockwave and a jolt, every time (harder when it's already furious).
        bobNode.runAction(slamSquash(windUp: 0.25, hold: 0.1, impact: 0.12, recover: 0.4), forKey: "squash")
        shockwave(after: 0.35)
        quake(after: 0.35)
        if rage > 0.4 {
            shockwave(after: 0.9)
            quake(after: 0.9)
        }
        if isModel { return modelAngry(turnAway: turnAway) }
        var right: [SCNAction] = [turn(0.1, 0, 0.9, 0.2), wait(1.8), restRight()]
        let left: [SCNAction] = [turn(0.1, 0, -0.9, 0.2), wait(1.8), restLeft()]
        var extra: [(SCNNode, [SCNAction])] = []
        var bob: [SCNAction] = [wait(0.1), hop(0.08, 0.2), hop(0.08, 0.2), hop(0.08, 0.2), hop(0.08, 0.2)]

        switch character {
        case .kratos, .wukong:
            // Slam the weapon into the ground, twice.
            let raise: CGFloat = character == .wukong ? -2.6 : -2.9
            right = [turn(raise, 0, armSplay, 0.3), turn(0, 0, armSplay, 0.12, .easeIn), wait(0.25), turn(raise, 0, armSplay, 0.3), turn(0, 0, armSplay, 0.12, .easeIn), wait(0.5), restRight()]
            bob = [wait(0.4), hop(0.05, 0.2), wait(0.5), hop(0.05, 0.2)]
            shockwave(after: 0.42)
            shockwave(after: 1.1)
        case .hulk:
            let time = hulkSmash(times: 2, thenJump: false)
            if turnAway { yawNode.runAction(SCNAction.sequence([wait(time - 0.2), turn(0, 2.8, 0, 0.5)]), forKey: "move") }
            return time + 0.5
        case .kungFuPanda:
            // A proper tantrum: stamping from foot to foot.
            let stomp: [SCNAction] = [turn(-0.9, 0, 0, 0.14), turn(0, 0, 0, 0.14)]
            var rightStomps: [SCNAction] = [wait(0.2)]
            var leftStomps: [SCNAction] = [wait(0.34)]
            for _ in 0..<2 {
                rightStomps += stomp
                leftStomps += stomp
                rightStomps.append(wait(0.1))
                leftStomps.append(wait(0.1))
            }
            extra = [(rightLeg, rightStomps), (leftLeg, leftStomps)]
        default:
            break
        }

        var tracks: [(SCNNode, [SCNAction])] = [
            (rightArm, right),
            (leftArm, left),
            (bobNode, bob),
            (head, [turn(0, 0.8, 0, 0.1), turn(0, -0.8, 0, 0.1), turn(0, 0.8, 0, 0.1), turn(0, -0.8, 0, 0.1), turn(0, 0.8, 0, 0.1), turn(0, -0.8, 0, 0.1), turn(0, 0, 0, 0.1)]),
        ]
        tracks += extra
        play(tracks)
        if turnAway { yawNode.runAction(SCNAction.sequence([wait(1.1), turn(0, 2.8, 0, 0.5)]), forKey: "move") }
        return 2.2
    }

    // MARK: Waiting

    /// Impatience in bursts: foot tapping, arms crossed, then stomping and finally fuming.
    private func grumble(_ level: Int) -> TimeInterval {
        if level >= 3 {
            let time = angry(turnAway: false)
            return time
        }
        if isModel { return modelGrumble(level) }
        let hulk = character == .hulk
        // Arms crossed over the chest, or fists on the hips for Hulk.
        let crossRight = hulk ? turn(0, 0, 0.9, 0.3) : turn(-1.0, 0, -0.9, 0.3)
        let crossLeft = hulk ? turn(0, 0, -0.9, 0.3) : turn(-1.0, 0, 0.9, 0.3)
        let tap: [SCNAction] = [turn(-0.5, 0, 0, 0.12), turn(0, 0, 0, 0.12)]
        var tapping: [SCNAction] = [wait(0.35)]
        for _ in 0..<4 { tapping += tap }
        var tracks: [(SCNNode, [SCNAction])] = [
            (rightArm, [crossRight, wait(1.7), restRight(0.3)]),
            (leftArm, [crossLeft, wait(1.7), restLeft(0.3)]),
            (rightLeg, tapping),
        ]
        if level == 1 {
            tracks.append((head, [turn(0, 0, 0.25, 0.3), wait(1.4), turn(0, 0, 0, 0.3)]))
        } else {
            setTint(NSColor(hex: 0xFF3B30), amount: 0.25)
            tracks.append((head, [wait(0.3), turn(0, 0.5, 0, 0.12), turn(0, -0.5, 0, 0.12), turn(0, 0.5, 0, 0.12), turn(0, 0, 0, 0.12), wait(0.5), turn(0.25, 0, 0, 0.3), turn(0, 0, 0, 0.3)]))
            tracks.append((leftLeg, [wait(1.3), turn(-0.7, 0, 0, 0.12), turn(0, 0, 0, 0.12), turn(-0.7, 0, 0, 0.12), turn(0, 0, 0, 0.12)]))
            tracks.append((bobNode, [wait(1.3), hop(0.04, 0.24), hop(0.04, 0.24)]))
        }
        play(tracks)
        return 2.4
    }
}

// MARK: - Imported models
//
// A model from a file has a skeleton we can't safely guess at (bone names are often anonymous and
// it's usually frozen in a T-pose), so it acts with its whole body instead: leaning, lunging, hopping,
// spinning and somersaulting, in the style of whoever is talking.

extension AvatarRig {
    private func lean(_ angle: CGFloat, _ time: TimeInterval, _ mode: SCNActionTimingMode = .easeInEaseOut) -> SCNAction {
        turn(angle, 0, 0, time, mode)
    }

    /// A hop that stretches on the way up and squashes on landing (cartoon weight).
    private func bouncyHop(_ height: CGFloat, _ time: TimeInterval) -> (jump: SCNAction, squash: SCNAction) {
        let stretch = SCNAction.scaleX(to: 0.93, y: 1.1, z: 0.93, duration: time * 0.45)
        let land = SCNAction.scaleX(to: 1.14, y: 0.85, z: 1.14, duration: time * 0.12)
        let settle = SCNAction.scaleX(to: 1, y: 1, z: 1, duration: time * 0.43)
        stretch.timingMode = .easeOut
        settle.timingMode = .easeOut
        return (hop(height, time), SCNAction.sequence([stretch, land, settle]))
    }

    /// Squash and stretch for an overhead slam: stretch up while winding up, flatten on impact, spring back.
    private func slamSquash(windUp: TimeInterval, hold: TimeInterval, impact: TimeInterval, recover: TimeInterval) -> SCNAction {
        let up = SCNAction.scaleX(to: 0.94, y: 1.1, z: 0.94, duration: windUp)
        let flat = SCNAction.scaleX(to: 1.16, y: 0.84, z: 1.16, duration: impact)
        let back = SCNAction.scaleX(to: 1, y: 1, z: 1, duration: recover)
        up.timingMode = .easeOut
        back.timingMode = .easeOut
        return SCNAction.sequence([up, SCNAction.wait(duration: hold), flat, back])
    }

    private func lunge(_ distance: CGFloat, _ time: TimeInterval) -> SCNAction {
        SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0, z: distance, duration: time * 0.4),
            SCNAction.moveBy(x: 0, y: 0, z: -distance, duration: time * 0.6),
        ])
    }

    private func spinAround(_ time: TimeInterval) -> SCNAction {
        SCNAction.sequence([
            SCNAction.rotateTo(x: 0, y: 2 * .pi, z: 0, duration: time),
            SCNAction.run { node in node.eulerAngles.y = 0 },
        ])
    }

    private func playBody(_ tracks: [(SCNNode, [SCNAction])]) {
        for (node, actions) in tracks {
            node.removeAction(forKey: "move")
            node.runAction(SCNAction.sequence(actions), forKey: "move")
        }
    }

    fileprivate func modelSignature() -> TimeInterval {
        switch modelStyle {
        case .kratos:
            // Two heavy overhead chops that make the ground jump.
            playBody([
                (bobNode, [lean(-0.3, 0.3), SCNAction.wait(duration: 0.1), lean(0.5, 0.1, .easeIn), SCNAction.wait(duration: 0.35), lean(-0.3, 0.3), SCNAction.wait(duration: 0.05), lean(0.55, 0.1, .easeIn), SCNAction.wait(duration: 0.4), lean(0, 0.3)]),
                (yawNode, [turn(0, 0.35, 0, 0.3), SCNAction.wait(duration: 0.6), turn(0, -0.3, 0, 0.4), turn(0, 0, 0, 0.35)]),
            ])
            let chop = slamSquash(windUp: 0.3, hold: 0.1, impact: 0.1, recover: 0.3)
            bobNode.runAction(SCNAction.sequence([chop, SCNAction.wait(duration: 0.05), chop]), forKey: "squash")
            shockwave(after: 0.5)
            quake(after: 0.5)
            shockwave(after: 1.25)
            quake(after: 1.25)
            return 2.3
        case .kungFuPanda:
            // Guard stance, three quick punches (lunges), then a spinning kick and a bow.
            let punch: [SCNAction] = [SCNAction.moveBy(x: 0, y: 0, z: 0.2, duration: 0.07), SCNAction.moveBy(x: 0, y: 0, z: -0.2, duration: 0.1)]
            var body: [SCNAction] = [lean(0.25, 0.2)]
            body += punch
            body += punch
            body += punch
            let kick = bouncyHop(0.25, 0.6)
            body += [SCNAction.wait(duration: 0.1), kick.jump, lean(0.5, 0.25), SCNAction.wait(duration: 0.2), lean(0, 0.25)]
            playBody([
                (bobNode, body),
                (yawNode, [SCNAction.wait(duration: 0.9), spinAround(0.6)]),
            ])
            bobNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 0.94), kick.squash]), forKey: "squash")
            return 2.3
        case .wukong:
            // The cloud somersault, then a twirl.
            flip()
            playBody([(yawNode, [SCNAction.wait(duration: 0.9), spinAround(0.6)])])
            shockwave(after: 0.75)
            return 1.8
        case .hulk:
            // Rears back, smashes the ground, then bounds about.
            playBody([
                (bobNode, [lean(-0.35, 0.35), SCNAction.wait(duration: 0.1), lean(0.5, 0.1, .easeIn), SCNAction.wait(duration: 0.3), lean(0, 0.2), hop(0.6, 0.5), hop(0.6, 0.5)]),
                (yawNode, [turn(0, 0.2, 0, 0.35), SCNAction.wait(duration: 0.2), turn(0, -0.2, 0, 0.3), turn(0, 0, 0, 0.3)]),
            ])
            bobNode.runAction(slamSquash(windUp: 0.35, hold: 0.1, impact: 0.1, recover: 0.3), forKey: "squash")
            shockwave(after: 0.55)
            quake(after: 0.55)
            return 2.4
        default:
            let first = bouncyHop(0.3, 0.45)
            let second = bouncyHop(0.3, 0.45)
            playBody([
                (yawNode, [spinAround(0.9)]),
                (bobNode, [first.jump, second.jump]),
            ])
            bobNode.runAction(SCNAction.sequence([first.squash, second.squash]), forKey: "squash")
            return 1.2
        }
    }

    fileprivate func modelPleased() -> TimeInterval {
        let front = (yawNode, [turn(0, 0, 0, 0.25)])
        switch modelStyle {
        case .kratos:
            // A curt, respectful nod.
            playBody([(bobNode, [SCNAction.wait(duration: 0.2), lean(0.3, 0.35), SCNAction.wait(duration: 0.5), lean(0, 0.35)]), front])
            return 1.5
        case .wukong:
            flip()
            playBody([front])
            return 1.3
        case .kungFuPanda:
            let first = bouncyHop(0.25, 0.4)
            let second = bouncyHop(0.25, 0.4)
            playBody([(bobNode, [first.jump, second.jump, lean(0.5, 0.25), SCNAction.wait(duration: 0.2), lean(0, 0.25)]), (yawNode, [spinAround(0.8)])])
            bobNode.runAction(SCNAction.sequence([first.squash, second.squash]), forKey: "squash")
            return 1.8
        default:
            let first = bouncyHop(0.4, 0.5)
            let second = bouncyHop(0.4, 0.5)
            playBody([(bobNode, [first.jump, second.jump]), (yawNode, [spinAround(0.9)])])
            bobNode.runAction(SCNAction.sequence([first.squash, second.squash]), forKey: "squash")
            return 1.5
        }
    }

    fileprivate func modelAngry(turnAway: Bool) -> TimeInterval {
        var body: [SCNAction] = [SCNAction.wait(duration: 0.1), hop(0.08, 0.2), hop(0.08, 0.2), hop(0.08, 0.2), hop(0.08, 0.2)]
        switch modelStyle {
        case .kratos, .hulk:
            body = [lean(-0.3, 0.3), lean(0.55, 0.1, .easeIn), SCNAction.wait(duration: 0.25), lean(-0.3, 0.3), lean(0.55, 0.1, .easeIn), SCNAction.wait(duration: 0.4), lean(0, 0.3)]
            let chop = slamSquash(windUp: 0.3, hold: 0.0, impact: 0.1, recover: 0.25)
            bobNode.runAction(SCNAction.sequence([chop, SCNAction.wait(duration: 0.1), chop]), forKey: "squash")
            shockwave(after: 0.4)
            quake(after: 0.4)
            shockwave(after: 1.15)
            quake(after: 1.15)
        case .kungFuPanda:
            body = [hop(0.1, 0.25), hop(0.1, 0.25), hop(0.1, 0.25), hop(0.1, 0.25), SCNAction.wait(duration: 0.3)]
        default:
            break
        }
        let wobble: [SCNAction] = [turn(0, 0.4, 0, 0.12), turn(0, -0.4, 0, 0.12), turn(0, 0.4, 0, 0.12), turn(0, -0.4, 0, 0.12), turn(0, 0, 0, 0.12)]
        var yaw: [SCNAction] = [SCNAction.wait(duration: 0.1)]
        yaw += wobble
        if turnAway { yaw += [SCNAction.wait(duration: 0.5), turn(0, 2.8, 0, 0.5)] }
        playBody([(bobNode, body), (yawNode, yaw)])
        return 2.4
    }

    fileprivate func modelGrumble(_ level: Int) -> TimeInterval {
        let tap: [SCNAction] = [hop(0.03, 0.25), hop(0.03, 0.25), hop(0.03, 0.25), hop(0.03, 0.25)]
        var yaw: [SCNAction] = [turn(0, 0.2, 0, 0.3), SCNAction.wait(duration: 1.2), turn(0, 0, 0, 0.3)]
        if level >= 2 {
            setTint(NSColor(hex: 0xFF3B30), amount: 0.25)
            yaw = [SCNAction.wait(duration: 0.2), turn(0, 0.4, 0, 0.12), turn(0, -0.4, 0, 0.12), turn(0, 0.4, 0, 0.12), turn(0, 0, 0, 0.12), SCNAction.wait(duration: 0.8)]
        }
        var body: [SCNAction] = [SCNAction.wait(duration: 0.3)]
        body += tap
        playBody([(bobNode, body), (yawNode, yaw)])
        return 2.0
    }
}

extension AvatarRig {
    /// Puffs up a bit more every time it's skipped, up to a limit (the window is only so big).
    func swell() {
        guard root.scale.x < 1.5 else { return }
        root.runAction(SCNAction.scale(by: 1.2, duration: 0.4))
    }
}
