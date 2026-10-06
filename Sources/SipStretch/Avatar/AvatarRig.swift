import AppKit
import SceneKit
import SipStretchCore

// A posable 3D character built from a handful of primitives (spheres, capsules, boxes). Nothing is
// loaded from disk (except an imported model or a face photo), so it costs a few KB of geometry and
// renders in well under a millisecond. Units are metres, feet at y = 0, the character faces +Z
// (toward the camera).

// MARK: - Small SceneKit helpers (CGFloat everywhere: that's what SCNVector3 uses on macOS)

func vec(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNVector3 { SCNVector3(x: x, y: y, z: z) }

private func material(_ hex: UInt32, glow: CGFloat = 0) -> SCNMaterial {
    let result = SCNMaterial()
    result.diffuse.contents = NSColor(hex: hex)
    // A touch of specular gives skin, fur and metal some sheen instead of flat toy plastic.
    result.lightingModel = .blinn
    result.specular.contents = NSColor(white: 0.22, alpha: 1)
    result.shininess = 0.2
    if glow > 0 {
        result.emission.contents = NSColor(hex: hex)
        result.emission.intensity = glow
    }
    return result
}

/// A node showing `geometry` in a flat color. `glow` makes it self-lit (eyes of a robot, a magic blade).
func shape(_ geometry: SCNGeometry, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero, glow: CGFloat = 0) -> SCNNode {
    geometry.materials = [material(hex, glow: glow)]
    let node = SCNNode(geometry: geometry)
    node.position = position
    return node
}

func sphereNode(_ radius: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero, scale: SCNVector3? = nil, glow: CGFloat = 0) -> SCNNode {
    let geometry = SCNSphere(radius: radius)
    geometry.segmentCount = 28
    let node = shape(geometry, hex, at: position, glow: glow)
    if let scale { node.scale = scale }
    return node
}

func capsuleNode(radius: CGFloat, height: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero) -> SCNNode {
    let geometry = SCNCapsule(capRadius: radius, height: max(height, radius * 2 + 0.001))
    geometry.radialSegmentCount = 24
    geometry.capSegmentCount = 12
    return shape(geometry, hex, at: position)
}

func boxNode(_ width: CGFloat, _ height: CGFloat, _ length: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero, chamfer: CGFloat = 0, glow: CGFloat = 0) -> SCNNode {
    shape(SCNBox(width: width, height: height, length: length, chamferRadius: chamfer), hex, at: position, glow: glow)
}

func cylinderNode(radius: CGFloat, height: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero, glow: CGFloat = 0) -> SCNNode {
    let geometry = SCNCylinder(radius: radius, height: height)
    geometry.radialSegmentCount = 20
    return shape(geometry, hex, at: position, glow: glow)
}

func coneNode(top: CGFloat, bottom: CGFloat, height: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero, glow: CGFloat = 0) -> SCNNode {
    let geometry = SCNCone(topRadius: top, bottomRadius: bottom, height: height)
    geometry.radialSegmentCount = 20
    return shape(geometry, hex, at: position, glow: glow)
}

/// A ring lying flat (axis = Y). Tilt or squash the node to wrap it around a body part.
func ringNode(radius: CGFloat, pipe: CGFloat, _ hex: UInt32, at position: SCNVector3 = SCNVector3Zero) -> SCNNode {
    let geometry = SCNTorus(ringRadius: radius, pipeRadius: pipe)
    geometry.ringSegmentCount = 28
    geometry.pipeSegmentCount = 8
    return shape(geometry, hex, at: position)
}

/// Depth of a sphere of radius `radius` at (x, y): where the front surface is, so features sit on it.
func surfaceDepth(_ radius: CGFloat, _ x: CGFloat, _ y: CGFloat) -> CGFloat {
    sqrt(max(0.0001, radius * radius - x * x - y * y))
}

/// Body measurements for the shared two-legged, two-armed build.
struct Biped {
    var headRadius: CGFloat
    var torsoWidth: CGFloat
    var torsoHeight: CGFloat
    var legLength: CGFloat
    var legRadius: CGFloat
    var armLength: CGFloat
    var armRadius: CGFloat

    /// The torso is a capsule, which must be at least as tall as it is wide.
    var torsoTall: CGFloat { max(torsoHeight, torsoWidth + 0.01) }
    var headCenterY: CGFloat { legLength + torsoTall + headRadius * 0.8 }
    var totalHeight: CGFloat { headCenterY + headRadius }
    var shoulderX: CGFloat { torsoWidth / 2 + armRadius * 0.35 }
    var shoulderY: CGFloat { legLength + torsoTall - armRadius * 1.3 }
    var hipX: CGFloat { torsoWidth * 0.22 }
    var torsoDepth: CGFloat { torsoWidth * 0.72 }
}

enum MouthStyle { case smile, grin, flat, none }

@MainActor
final class AvatarRig {
    /// Put this in a scene. Origin = the point on the ground between the feet.
    let root = SCNNode()
    /// Turns the whole body (3/4 view while walking, front-on while talking).
    let yawNode = SCNNode()
    /// Bounces the whole body up and down while walking.
    let bobNode = SCNNode()

    var head = SCNNode()
    var torso = SCNNode()
    var leftArm = SCNNode()
    var rightArm = SCNNode()
    var leftLeg = SCNNode()
    var rightLeg = SCNNode()
    var tail: SCNNode?
    /// What the right hand holds (axe, staff…), pivoting at the hand so it can spin or slam.
    var prop: SCNNode?
    /// What the left hand holds (Kratos's chained blades).
    var leftProp: SCNNode?
    private(set) var character = AvatarCharacter.drip
    var tintBackup: [ObjectIdentifier: (contents: Any?, intensity: CGFloat)] = [:]

    /// Top of the character in metres (props and feathers included), for framing.
    var height: CGFloat = 1.6
    var legSwing: CGFloat = 0.6
    var armSwing: CGFloat = 0.5
    /// Less than 1 when that hand carries something (a staff, an axe) that shouldn't flail around.
    var rightArmFactor: CGFloat = 1
    var bounce: CGFloat = 0.035
    /// Side-to-side waddle for models without limbs to animate.
    var sway: CGFloat = 0
    /// How far arms hang away from the body at rest (radians).
    var armSplay: CGFloat = 0.1
    /// Whether the right arm may wave (false when the hand is holding something big).
    var canWave = true

    private(set) var isWalking = false

    init(look: AvatarLook, facePhoto: NSImage?, modelURL: URL?) {
        character = look.character
        root.addChildNode(yawNode)
        yawNode.addChildNode(bobNode)

        let blob = cylinderNode(radius: 0.4, height: 0.004, 0x000000, at: vec(0, 0.002, 0))
        if let blobMaterial = blob.geometry?.firstMaterial {
            blobMaterial.diffuse.contents = NSColor(white: 0, alpha: 0.22)
            blobMaterial.lightingModel = .constant
            blobMaterial.writesToDepthBuffer = false
        }
        root.addChildNode(blob)

        switch look.character {
        case .drip: buildDrip(look)
        case .human: buildHuman(look, facePhoto: facePhoto)
        case .robot: buildRobot(look)
        case .kratos: buildKratos()
        case .kungFuPanda: buildPanda()
        case .wukong: buildWukong()
        case .hulk: buildHulk()
        case .model:
            if let modelURL, buildModel(url: modelURL, rotationDegrees: look.modelRotation) {
                break
            }
            character = .drip
            buildDrip(look) // the model went missing or can't be read: fall back to Drip
        }
        applyRestPose()
    }

    // MARK: Shared build blocks

    /// Torso, head, arms and legs from the measurements. Characters then dress these up.
    func assemble(_ b: Biped, headColor: UInt32, torsoColor: UInt32, armColor: UInt32, handColor: UInt32, legColor: UInt32, shoeColor: UInt32?, headShape: SCNNode? = nil) {
        torso = capsuleNode(radius: b.torsoWidth / 2, height: b.torsoTall, torsoColor, at: vec(0, b.legLength + b.torsoTall / 2, 0))
        torso.scale = vec(1, 1, 0.72)
        bobNode.addChildNode(torso)

        head = SCNNode()
        head.position = vec(0, b.headCenterY, 0)
        head.addChildNode(headShape ?? sphereNode(b.headRadius, headColor))
        bobNode.addChildNode(head)

        for side in [CGFloat(-1), 1] {
            let arm = limb(radius: b.armRadius, length: b.armLength, color: armColor)
            arm.position = vec(side * b.shoulderX, b.shoulderY, 0)
            arm.addChildNode(sphereNode(b.armRadius * 1.12, handColor, at: vec(0, -b.armLength, 0)))
            bobNode.addChildNode(arm)
            if side < 0 { leftArm = arm } else { rightArm = arm }

            let leg = limb(radius: b.legRadius, length: b.legLength, color: legColor)
            leg.position = vec(side * b.hipX, b.legLength, 0)
            if let shoeColor {
                leg.addChildNode(sphereNode(b.legRadius * 1.3, shoeColor, at: vec(0, -b.legLength + b.legRadius * 0.55, b.legRadius * 0.7), scale: vec(1, 0.6, 1.6)))
            }
            bobNode.addChildNode(leg)
            if side < 0 { leftLeg = leg } else { rightLeg = leg }
        }
        height = b.totalHeight
    }

    /// A pivot node at the shoulder/hip with a capsule hanging down from it.
    func limb(radius: CGFloat, length: CGFloat, color: UInt32) -> SCNNode {
        let pivot = SCNNode()
        pivot.addChildNode(capsuleNode(radius: radius, height: length, color, at: vec(0, -length / 2, 0)))
        return pivot
    }

    /// Eyes, cheeks and a mouth on a spherical head of `radius`, centered on `head`.
    /// `forward` pushes the features out (as a fraction of the radius) for heads with a bulging face mask.
    func addFace(radius r: CGFloat, mouth: MouthStyle = .smile, eyes: Bool = true, eyeColor: UInt32 = 0x1B2A4A, blush: Bool = true, forward: CGFloat = 0) {
        let push = r * forward
        if eyes {
            for side in [CGFloat(-1), 1] {
                let x = side * r * 0.36
                let y = r * 0.05
                let eye = sphereNode(r * 0.085, eyeColor, at: vec(x, y, surfaceDepth(r, x, y) * 0.97 + push), scale: vec(1, 1.25, 0.55))
                eye.addChildNode(sphereNode(r * 0.03, 0xFFFFFF, at: vec(r * 0.025, r * 0.04, r * 0.04), glow: 1))
                head.addChildNode(eye)
            }
        }
        if blush {
            for side in [CGFloat(-1), 1] {
                let x = side * r * 0.52
                let y = -r * 0.22
                head.addChildNode(sphereNode(r * 0.1, 0xFF7EA8, at: vec(x, y, surfaceDepth(r, x, y) * 0.98 + push), scale: vec(1, 0.6, 0.35)))
            }
        }
        switch mouth {
        case .smile, .grin:
            let spread: CGFloat = mouth == .grin ? 0.3 : 0.2
            let dot: CGFloat = mouth == .grin ? 0.038 : 0.03
            for i in 0..<5 {
                let u = CGFloat(i) / 2 - 1
                let x = u * spread * r
                let y = -r * 0.34 - r * 0.07 * (1 - u * u)
                head.addChildNode(sphereNode(dot * r, 0x1B2A4A, at: vec(x, y, surfaceDepth(r, x, y) * 0.985 + push)))
            }
        case .flat:
            head.addChildNode(boxNode(r * 0.34, r * 0.045, r * 0.04, 0x2B1D14, at: vec(0, -r * 0.36, surfaceDepth(r, 0, -r * 0.36) * 0.99 + push)))
        case .none:
            break
        }
    }

    func addBrows(radius r: CGFloat, color: UInt32, angle: CGFloat, forward: CGFloat = 0) {
        for side in [CGFloat(-1), 1] {
            let x = side * r * 0.36
            let y = r * 0.3
            let brow = boxNode(r * 0.34, r * 0.075, r * 0.05, color, at: vec(x, y, surfaceDepth(r, x, y) * 0.99 + r * forward))
            brow.eulerAngles = vec(0, 0, side * angle)
            head.addChildNode(brow)
        }
    }

    /// A pale cutout of the user's photo floating just in front of the face (see `PhotoAvatar`).
    func addPhotoFace(_ image: NSImage, radius r: CGFloat) {
        let plane = SCNPlane(width: r * 1.2, height: r * 1.2)
        let faceMaterial = SCNMaterial()
        faceMaterial.diffuse.contents = image
        faceMaterial.lightingModel = .constant
        faceMaterial.isDoubleSided = false
        plane.materials = [faceMaterial]
        let node = SCNNode(geometry: plane)
        node.position = vec(0, r * 0.02, r * 1.02)
        head.addChildNode(node)
    }

    // MARK: Poses and animation

    /// Neutral standing pose with arms slightly away from the body.
    func applyRestPose() {
        leftArm.eulerAngles = vec(0, 0, -armSplay)
        rightArm.eulerAngles = vec(0, 0, armSplay)
        leftLeg.eulerAngles = vec(0, 0, 0)
        rightLeg.eulerAngles = vec(0, 0, 0)
        bobNode.position = vec(0, 0, 0)
        bobNode.eulerAngles = vec(0, 0, 0)
        head.eulerAngles = vec(0, 0, 0)
        prop?.eulerAngles = vec(0, 0, 0)
        leftProp?.eulerAngles = vec(0, 0, 0)
    }

    /// Turns the body to `angle` radians (0 = facing the camera, ±1 = a 3/4 walking view).
    func face(yaw angle: CGFloat, duration: TimeInterval) {
        yawNode.removeAction(forKey: "face")
        if duration <= 0 {
            yawNode.eulerAngles = vec(0, angle, 0)
            return
        }
        let turn = SCNAction.rotateTo(x: 0, y: angle, z: 0, duration: duration, usesShortestUnitArc: true)
        turn.timingMode = .easeInEaseOut
        yawNode.runAction(turn, forKey: "face")
    }

    /// Starts the walk cycle. `cycle` is the time for two steps, in seconds.
    func startWalking(cycle: TimeInterval, mood: WalkMood = .normal) {
        stopActivities(settle: true)
        isWalking = true
        let half = max(0.2, cycle / 2)

        func swing(_ node: SCNNode, amplitude: CGFloat, positiveFirst: Bool, z: CGFloat) {
            let forward = SCNAction.rotateTo(x: amplitude, y: 0, z: z, duration: half, usesShortestUnitArc: true)
            let back = SCNAction.rotateTo(x: -amplitude, y: 0, z: z, duration: half, usesShortestUnitArc: true)
            forward.timingMode = .easeInEaseOut
            back.timingMode = .easeInEaseOut
            node.runAction(.repeatForever(.sequence(positiveFirst ? [forward, back] : [back, forward])), forKey: "walk")
        }
        // A happy walk bounces and swings; an angry one stomps with stiff, heavy steps.
        let legs = legSwing * (mood == .angry ? 1.25 : 1)
        let arms = armSwing * (mood == .happy ? 1.5 : mood == .angry ? 0.5 : 1)
        let hop = bounce * (mood == .happy ? 2.4 : mood == .angry ? 2.0 : 1)
        swing(leftLeg, amplitude: legs, positiveFirst: true, z: 0)
        swing(rightLeg, amplitude: legs, positiveFirst: false, z: 0)
        swing(leftArm, amplitude: arms, positiveFirst: false, z: -armSplay)
        swing(rightArm, amplitude: arms * rightArmFactor, positiveFirst: true, z: armSplay)

        let up = SCNAction.moveBy(x: 0, y: hop, z: 0, duration: half / 2)
        let down = SCNAction.moveBy(x: 0, y: -hop, z: 0, duration: half / 2)
        up.timingMode = .easeOut
        down.timingMode = .easeIn
        bobNode.runAction(.repeatForever(.sequence([up, down])), forKey: "bob")

        if sway > 0 {
            let left = SCNAction.rotateTo(x: 0, y: 0, z: sway, duration: half, usesShortestUnitArc: true)
            let right = SCNAction.rotateTo(x: 0, y: 0, z: -sway, duration: half, usesShortestUnitArc: true)
            left.timingMode = .easeInEaseOut
            right.timingMode = .easeInEaseOut
            bobNode.runAction(.repeatForever(.sequence([left, right])), forKey: "sway")
        }
        startTailSway(period: cycle)
    }

    private func startTailSway(period: TimeInterval) {
        guard let tail else { return }
        let a = SCNAction.rotateTo(x: 0, y: 0, z: 0.35, duration: period / 2, usesShortestUnitArc: true)
        let b = SCNAction.rotateTo(x: 0, y: 0, z: -0.35, duration: period / 2, usesShortestUnitArc: true)
        a.timingMode = .easeInEaseOut
        b.timingMode = .easeInEaseOut
        tail.runAction(.repeatForever(.sequence([a, b])), forKey: "tail")
    }

    /// Stops whatever is playing and eases back to the standing pose.
    func stopActivities(settle: Bool = false) {
        isWalking = false
        yawNode.removeAction(forKey: "move")
        root.removeAction(forKey: "quake")
        for node in [leftLeg, rightLeg, leftArm, rightArm, bobNode, tail, head, prop, leftProp].compactMap({ $0 }) { node.removeAllActions() }
        if settle {
            applyRestPose()
        } else {
            let ease = 0.18
            leftLeg.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: ease, usesShortestUnitArc: true))
            rightLeg.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: ease, usesShortestUnitArc: true))
            leftArm.runAction(.rotateTo(x: 0, y: 0, z: -armSplay, duration: ease, usesShortestUnitArc: true))
            rightArm.runAction(.rotateTo(x: 0, y: 0, z: armSplay, duration: ease, usesShortestUnitArc: true))
            bobNode.runAction(.group([
                .move(to: vec(0, 0, 0), duration: ease),
                .rotateTo(x: 0, y: 0, z: 0, duration: ease, usesShortestUnitArc: true),
            ]))
        }
    }

    /// Waves with the right hand a few times (about 2 s).
    func wave() {
        guard canWave else {
            nudgeBody()
            return
        }
        rightArm.removeAllActions()
        let raise = SCNAction.rotateTo(x: 0, y: 0, z: 2.5, duration: 0.3, usesShortestUnitArc: true)
        let outward = SCNAction.rotateTo(x: 0, y: 0, z: 2.9, duration: 0.2, usesShortestUnitArc: true)
        let inward = SCNAction.rotateTo(x: 0, y: 0, z: 2.1, duration: 0.2, usesShortestUnitArc: true)
        let lower = SCNAction.rotateTo(x: 0, y: 0, z: armSplay, duration: 0.35, usesShortestUnitArc: true)
        rightArm.runAction(.sequence([raise, SCNAction.repeat(.sequence([outward, inward]), count: 3), lower]), forKey: "wave")
    }

    /// For characters whose hands are full: a little hop instead of a wave.
    private func nudgeBody() {
        let hop = SCNAction.sequence([
            .moveBy(x: 0, y: 0.12, z: 0, duration: 0.15),
            .moveBy(x: 0, y: -0.12, z: 0, duration: 0.15),
        ])
        bobNode.runAction(SCNAction.repeat(hop, count: 2), forKey: "hop")
    }

    /// Both arms up and a couple of hops (about 1.3 s).
    func cheer() {
        for node in [leftArm, rightArm, bobNode] { node.removeAllActions() }
        let side: CGFloat = 2.7
        if canWave {
            leftArm.runAction(.sequence([
                .rotateTo(x: 0, y: 0, z: -side, duration: 0.25, usesShortestUnitArc: true),
                .wait(duration: 0.8),
                .rotateTo(x: 0, y: 0, z: -armSplay, duration: 0.3, usesShortestUnitArc: true),
            ]), forKey: "cheer")
            rightArm.runAction(.sequence([
                .rotateTo(x: 0, y: 0, z: side, duration: 0.25, usesShortestUnitArc: true),
                .wait(duration: 0.8),
                .rotateTo(x: 0, y: 0, z: armSplay, duration: 0.3, usesShortestUnitArc: true),
            ]), forKey: "cheer")
        } else {
            leftArm.runAction(.sequence([
                .rotateTo(x: 0, y: 0, z: -side, duration: 0.25, usesShortestUnitArc: true),
                .wait(duration: 0.8),
                .rotateTo(x: 0, y: 0, z: -armSplay, duration: 0.3, usesShortestUnitArc: true),
            ]), forKey: "cheer")
        }
        let up = SCNAction.moveBy(x: 0, y: 0.22, z: 0, duration: 0.2)
        let down = SCNAction.moveBy(x: 0, y: -0.22, z: 0, duration: 0.2)
        up.timingMode = .easeOut
        down.timingMode = .easeIn
        bobNode.runAction(.sequence([.wait(duration: 0.1), SCNAction.repeat(.sequence([up, down]), count: 2), .move(to: vec(0, 0, 0), duration: 0.05)]), forKey: "cheer")
    }

    /// Slow arms-up-and-down stretching, until `stopActivities` is called.
    func startStretching() {
        stopActivities(settle: true)
        let reach: CGFloat = 2.9
        func lift(_ node: SCNNode, side: CGFloat) {
            let up = SCNAction.rotateTo(x: 0, y: 0, z: side * reach, duration: 1.1, usesShortestUnitArc: true)
            let down = SCNAction.rotateTo(x: 0, y: 0, z: side * armSplay, duration: 1.1, usesShortestUnitArc: true)
            up.timingMode = .easeInEaseOut
            down.timingMode = .easeInEaseOut
            node.runAction(.repeatForever(.sequence([up, down])), forKey: "stretch")
        }
        lift(rightArm, side: 1)
        if canWave { lift(leftArm, side: -1) }
        let rise = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 1.1)
        rise.timingMode = .easeInEaseOut
        bobNode.runAction(.repeatForever(.sequence([rise, rise.reversed()])), forKey: "stretch")
    }
}
