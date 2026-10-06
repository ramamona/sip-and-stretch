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
            let pump = [turn(-1.2, 0, 0.3, 0.2), turn(0, 0, armSplay, 0.2)]
            let pumpLeft = [turn(-1.2, 0, -0.3, 0.2), turn(0, 0, -armSplay, 0.2)]
            play([
                (rightArm, pump + pump + pump + [restRight()]),
                (leftArm, [wait(0.2)] + pumpLeft + pumpLeft + pumpLeft + [restLeft()]),
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
            let beatRight = [turn(-0.9, 0, 0.45, 0.12), turn(-0.2, 0, 0.45, 0.12)]
            let beatLeft = [turn(-0.9, 0, -0.45, 0.12), turn(-0.2, 0, -0.45, 0.12)]
            play([
                (rightArm, [wait(0.1)] + beatRight + beatRight + beatRight + [turn(0, 0, 2.5, 0.2), wait(0.5), restRight()]),
                (leftArm, [wait(0.22)] + beatLeft + beatLeft + beatLeft + [turn(0, 0, -2.5, 0.2), wait(0.4), restLeft()]),
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
        setTint(NSColor(hex: 0xFF3B30), amount: 0.55)
        var right: [SCNAction] = [turn(0.1, 0, 0.9, 0.2), wait(1.8), restRight()]
        let left: [SCNAction] = [turn(0.1, 0, -0.9, 0.2), wait(1.8), restLeft()]
        var extra: [(SCNNode, [SCNAction])] = []
        var bob: [SCNAction] = [wait(0.1), hop(0.04, 0.2), hop(0.04, 0.2), hop(0.04, 0.2), hop(0.04, 0.2)]

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
            let stomp = [turn(-0.9, 0, 0, 0.14), turn(0, 0, 0, 0.14)]
            extra = [
                (rightLeg, [wait(0.2)] + stomp + [wait(0.1)] + stomp),
                (leftLeg, [wait(0.34)] + stomp + [wait(0.1)] + stomp),
            ]
        default:
            break
        }

        play([
            (rightArm, right),
            (leftArm, left),
            (bobNode, bob),
            (head, [turn(0, 0.6, 0, 0.12), turn(0, -0.6, 0, 0.12), turn(0, 0.6, 0, 0.12), turn(0, -0.6, 0, 0.12), turn(0, 0, 0, 0.12)]),
        ] + extra)
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
        let hulk = character == .hulk
        // Arms crossed over the chest, or fists on the hips for Hulk.
        let crossRight = hulk ? turn(0, 0, 0.9, 0.3) : turn(-1.0, 0, -0.9, 0.3)
        let crossLeft = hulk ? turn(0, 0, -0.9, 0.3) : turn(-1.0, 0, 0.9, 0.3)
        let tap = [turn(-0.5, 0, 0, 0.12), turn(0, 0, 0, 0.12)]
        var tracks: [(SCNNode, [SCNAction])] = [
            (rightArm, [crossRight, wait(1.7), restRight(0.3)]),
            (leftArm, [crossLeft, wait(1.7), restLeft(0.3)]),
            (rightLeg, [wait(0.35)] + tap + tap + tap + tap),
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
