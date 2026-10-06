import AppKit
import SceneKit
import SipStretchCore

// The characters themselves. Each is a few dozen primitives; see AvatarRig.swift for the shared parts.
//
// Kratos, Kung Fu Panda and Wukong are fan-made homages drawn from basic shapes and flat colors.
// No official models, textures or audio are included.

extension AvatarRig {

    // MARK: Drip

    func buildDrip(_ look: AvatarLook) {
        let light = look.themeLight
        let deep = look.themeDeep
        let radius: CGFloat = 0.36
        let legLength: CGFloat = 0.16
        let centerY = legLength + radius - 0.02

        head = SCNNode()
        head.position = vec(0, centerY, 0)
        head.addChildNode(sphereNode(radius, light))
        // A cone tangent to the sphere: apex 2 radii above the center makes a classic teardrop.
        head.addChildNode(coneNode(top: 0, bottom: 0.3118, height: 0.54, light, at: vec(0, 0.45, 0)))
        head.addChildNode(sphereNode(0.045, 0xFFFFFF, at: vec(-0.13, 0.14, 0.3), scale: vec(0.8, 1.5, 0.5), glow: 0.6))
        bobNode.addChildNode(head)
        addFace(radius: radius)

        for side in [CGFloat(-1), 1] {
            let arm = limb(radius: 0.05, length: 0.2, color: light)
            arm.position = vec(side * 0.35, centerY, 0)
            bobNode.addChildNode(arm)
            if side < 0 { leftArm = arm } else { rightArm = arm }

            let leg = limb(radius: 0.06, length: legLength, color: deep)
            leg.position = vec(side * 0.13, legLength, 0)
            leg.addChildNode(sphereNode(0.08, deep, at: vec(0, -legLength + 0.04, 0.04), scale: vec(1, 0.6, 1.4)))
            bobNode.addChildNode(leg)
            if side < 0 { leftLeg = leg } else { rightLeg = leg }
        }
        height = centerY + 0.72
        bounce = 0.07
        armSwing = 0.6
        armSplay = 0.35
    }

    // MARK: Custom person

    func buildHuman(_ look: AvatarLook, facePhoto: NSImage?) {
        let b: Biped
        switch look.gender {
        case .male:
            b = Biped(headRadius: 0.27, torsoWidth: 0.46, torsoHeight: 0.52, legLength: 0.52, legRadius: 0.085, armLength: 0.5, armRadius: 0.07)
        case .female:
            b = Biped(headRadius: 0.27, torsoWidth: 0.37, torsoHeight: 0.5, legLength: 0.54, legRadius: 0.075, armLength: 0.48, armRadius: 0.06)
        case .nonBinary:
            b = Biped(headRadius: 0.27, torsoWidth: 0.41, torsoHeight: 0.51, legLength: 0.53, legRadius: 0.08, armLength: 0.49, armRadius: 0.065)
        }
        let longSleeves = look.outfit != .tShirt && look.outfit != .dress
        assemble(
            b,
            headColor: look.skin,
            torsoColor: look.top,
            armColor: longSleeves ? look.top : look.skin,
            handColor: look.skin,
            legColor: look.outfit == .dress ? look.skin : look.bottom,
            shoeColor: 0x2B2B33
        )
        let r = b.headRadius

        // Outfit details
        switch look.outfit {
        case .tShirt:
            addSleeves(b, color: look.top)
        case .dress:
            addSleeves(b, color: look.top)
            let skirt = b.legLength * 0.6
            bobNode.addChildNode(coneNode(top: b.torsoWidth * 0.42, bottom: b.torsoWidth * 0.9, height: skirt, look.top, at: vec(0, b.legLength + 0.06 - skirt / 2, 0)))
        case .suit:
            bobNode.addChildNode(boxNode(0.05, b.torsoTall * 0.45, 0.02, 0xC0392B, at: vec(0, b.legLength + b.torsoTall * 0.62, b.torsoDepth / 2 + 0.004)))
        case .hoodie:
            bobNode.addChildNode(sphereNode(r * 0.75, look.top, at: vec(0, b.legLength + b.torsoTall + 0.02, -b.torsoDepth * 0.45), scale: vec(1, 0.7, 0.7)))
        case .tracksuit:
            for leg in [leftLeg, rightLeg] {
                let side: CGFloat = leg === leftLeg ? -1 : 1
                leg.addChildNode(boxNode(0.014, b.legLength * 0.85, b.legRadius * 1.3, 0xFFFFFF, at: vec(side * b.legRadius * 0.98, -b.legLength / 2, 0)))
            }
        }

        if let facePhoto { addPhotoFace(facePhoto, radius: r) } else { addFace(radius: r) }
        addHair(look.hairStyle, color: look.hair, radius: r)
        addAccessories(look.accessories, radius: r, biped: b, color: look.top)
    }

    private func addSleeves(_ b: Biped, color: UInt32) {
        for arm in [leftArm, rightArm] {
            arm.addChildNode(capsuleNode(radius: b.armRadius * 1.14, height: b.armLength * 0.42, color, at: vec(0, -b.armLength * 0.21, 0)))
        }
    }

    private func addHair(_ style: HairStyle, color: UInt32, radius r: CGFloat) {
        let cap = { self.head.addChildNode(sphereNode(r * 1.07, color, at: vec(0, r * 0.1, -r * 0.14))) }
        switch style {
        case .bald:
            break
        case .short:
            cap()
        case .long:
            cap()
            head.addChildNode(capsuleNode(radius: r * 0.82, height: r * 2.2, color, at: vec(0, -r * 0.4, -r * 0.42)))
        case .ponytail:
            cap()
            let tail = capsuleNode(radius: r * 0.22, height: r * 1.3, color, at: vec(0, -r * 0.1, -r * 1.15))
            tail.eulerAngles = vec(0.5, 0, 0)
            head.addChildNode(tail)
        case .bun:
            cap()
            head.addChildNode(sphereNode(r * 0.36, color, at: vec(0, r * 1.12, -r * 0.2)))
        case .curly:
            cap()
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                head.addChildNode(sphereNode(r * 0.34, color, at: vec(cos(angle) * r * 0.8, r * 0.64, sin(angle) * r * 0.8 - r * 0.1)))
            }
            head.addChildNode(sphereNode(r * 0.38, color, at: vec(0, r * 1.0, -r * 0.1)))
        case .mohawk:
            for i in 0..<5 {
                let t = CGFloat(i)
                head.addChildNode(boxNode(r * 0.14, r * 0.4, r * 0.3, color, at: vec(0, r * (0.98 - 0.05 * abs(t - 2)), r * (0.5 - 0.3 * t))))
            }
        case .afro:
            head.addChildNode(sphereNode(r * 1.4, color, at: vec(0, r * 0.3, -r * 0.4)))
        }
    }

    private func addAccessories(_ accessories: Set<AvatarAccessory>, radius r: CGFloat, biped b: Biped, color: UInt32) {
        if accessories.contains(.glasses) {
            for side in [CGFloat(-1), 1] {
                let x = side * r * 0.36
                let y = r * 0.05
                let frame = ringNode(radius: r * 0.2, pipe: r * 0.026, 0x22252B, at: vec(x, y, surfaceDepth(r, x, y) + r * 0.03))
                frame.eulerAngles = vec(.pi / 2, 0, 0)
                head.addChildNode(frame)
            }
            head.addChildNode(boxNode(r * 0.18, r * 0.03, r * 0.03, 0x22252B, at: vec(0, r * 0.1, r * 0.98)))
        }
        if accessories.contains(.sunglasses) {
            for side in [CGFloat(-1), 1] {
                let x = side * r * 0.36
                let y = r * 0.05
                head.addChildNode(boxNode(r * 0.4, r * 0.26, r * 0.05, 0x111114, at: vec(x, y, surfaceDepth(r, x, y) + r * 0.04), chamfer: r * 0.04))
            }
            head.addChildNode(boxNode(r * 0.14, r * 0.04, r * 0.04, 0x111114, at: vec(0, r * 0.1, r * 0.98)))
        }
        if accessories.contains(.cap) {
            head.addChildNode(sphereNode(r * 1.06, color, at: vec(0, r * 0.52, -r * 0.05), scale: vec(1, 0.62, 1)))
            let brim = boxNode(r * 1.0, r * 0.06, r * 0.7, color, at: vec(0, r * 0.5, r * 0.82), chamfer: r * 0.02)
            brim.eulerAngles = vec(0.08, 0, 0)
            head.addChildNode(brim)
        }
        if accessories.contains(.headphones) {
            for side in [CGFloat(-1), 1] {
                let cup = cylinderNode(radius: r * 0.28, height: r * 0.2, 0x2F3640, at: vec(side * r * 1.0, 0, 0))
                cup.eulerAngles = vec(0, 0, .pi / 2)
                head.addChildNode(cup)
            }
            for i in 0..<7 {
                let angle = (10 + CGFloat(i) * 26.7) * .pi / 180
                head.addChildNode(sphereNode(r * 0.065, 0x2F3640, at: vec(cos(angle) * r * 1.06, sin(angle) * r * 1.06, 0)))
            }
        }
        if accessories.contains(.scarf) {
            let neckY = b.legLength + b.torsoTall - 0.02
            let wrap = ringNode(radius: b.torsoWidth * 0.4, pipe: 0.05, 0xE8505B, at: vec(0, neckY, 0))
            wrap.scale = vec(1, 1, 0.72)
            bobNode.addChildNode(wrap)
            bobNode.addChildNode(boxNode(0.08, 0.28, 0.03, 0xE8505B, at: vec(b.torsoWidth * 0.2, neckY - 0.15, b.torsoDepth / 2 + 0.03)))
        }
    }

    // MARK: Robo Buddy

    func buildRobot(_ look: AvatarLook) {
        let legLength: CGFloat = 0.45
        let torsoHeight: CGFloat = 0.5
        let steel: UInt32 = 0x7B8794
        let cyan: UInt32 = 0x4FF3FF

        torso = boxNode(0.5, torsoHeight, 0.36, steel, at: vec(0, legLength + torsoHeight / 2, 0), chamfer: 0.06)
        bobNode.addChildNode(torso)
        bobNode.addChildNode(boxNode(0.16, 0.16, 0.02, look.themeLight, at: vec(0, legLength + torsoHeight * 0.58, 0.19), glow: 0.9))

        head = SCNNode()
        head.position = vec(0, legLength + torsoHeight + 0.28, 0)
        head.addChildNode(boxNode(0.52, 0.42, 0.42, 0xC9D1D9, chamfer: 0.08))
        for side in [CGFloat(-1), 1] {
            head.addChildNode(boxNode(0.11, 0.14, 0.02, cyan, at: vec(side * 0.12, 0.03, 0.215), glow: 1))
            let ear = cylinderNode(radius: 0.06, height: 0.08, steel, at: vec(side * 0.28, 0, 0))
            ear.eulerAngles = vec(0, 0, .pi / 2)
            head.addChildNode(ear)
        }
        for i in 0..<4 {
            head.addChildNode(boxNode(0.05, 0.03, 0.02, cyan, at: vec(-0.09 + 0.06 * CGFloat(i), -0.11, 0.215), glow: 0.8))
        }
        head.addChildNode(cylinderNode(radius: 0.015, height: 0.14, steel, at: vec(0, 0.28, 0)))
        head.addChildNode(sphereNode(0.045, 0xFF5964, at: vec(0, 0.38, 0), glow: 0.9))
        bobNode.addChildNode(head)

        for side in [CGFloat(-1), 1] {
            let arm = SCNNode()
            arm.position = vec(side * 0.34, legLength + torsoHeight - 0.08, 0)
            arm.addChildNode(cylinderNode(radius: 0.055, height: 0.4, 0x9AA5B1, at: vec(0, -0.2, 0)))
            arm.addChildNode(sphereNode(0.08, 0xC9D1D9, at: vec(0, -0.42, 0)))
            bobNode.addChildNode(arm)
            if side < 0 { leftArm = arm } else { rightArm = arm }

            let leg = SCNNode()
            leg.position = vec(side * 0.13, legLength, 0)
            leg.addChildNode(cylinderNode(radius: 0.07, height: 0.4, steel, at: vec(0, -0.2, 0)))
            leg.addChildNode(boxNode(0.16, 0.07, 0.26, 0x5E6A75, at: vec(0, -0.415, 0.04), chamfer: 0.02))
            bobNode.addChildNode(leg)
            if side < 0 { leftLeg = leg } else { rightLeg = leg }
        }
        height = 1.65
        legSwing = 0.5
        bounce = 0.03
    }

    // MARK: Kratos (fan-made)

    func buildKratos() {
        let b = Biped(headRadius: 0.25, torsoWidth: 0.66, torsoHeight: 0.62, legLength: 0.55, legRadius: 0.105, armLength: 0.56, armRadius: 0.115)
        let ash: UInt32 = 0xCFC8BE
        let leather: UInt32 = 0x4A3322
        assemble(b, headColor: ash, torsoColor: ash, armColor: ash, handColor: ash, legColor: 0x3A312B, shoeColor: 0x2A221D)
        let r = b.headRadius
        let chestY = b.legLength + b.torsoTall * 0.72

        // A bull neck, heavy pecs and deltoids: Kratos is built like a wall.
        bobNode.addChildNode(cylinderNode(radius: 0.11, height: 0.14, ash, at: vec(0, b.legLength + b.torsoTall + 0.02, 0)))
        for side in [CGFloat(-1), 1] {
            bobNode.addChildNode(sphereNode(0.15, ash, at: vec(side * 0.15, chestY, b.torsoDepth / 2 - 0.035), scale: vec(1, 0.8, 0.7)))
            bobNode.addChildNode(sphereNode(0.1, 0xC2BAAE, at: vec(side * 0.1, b.legLength + b.torsoTall * 0.3, b.torsoDepth / 2 - 0.01), scale: vec(1, 0.6, 0.5)))
        }
        for arm in [leftArm, rightArm] {
            arm.addChildNode(sphereNode(b.armRadius * 1.4, ash, at: vec(0, 0.015, 0), scale: vec(1, 1.05, 1)))
            arm.addChildNode(cylinderNode(radius: b.armRadius * 1.2, height: 0.2, 0x6B4E2E, at: vec(0, -b.armLength * 0.72, 0)))
        }

        // A scowling face: heavy brow, white war paint down one side, a dark beard.
        addFace(radius: r, mouth: .flat, eyeColor: 0x1B1410, blush: false)
        addBrows(radius: r, color: 0x1B1410, angle: 0.45)
        let paint = ringNode(radius: r * 0.965, pipe: r * 0.065, 0xB0261E, at: vec(-r * 0.28, 0, 0))
        paint.eulerAngles = vec(0, 0, .pi / 2)
        head.addChildNode(paint)
        head.addChildNode(sphereNode(r * 0.66, 0x3E2F25, at: vec(0, -r * 0.5, r * 0.4), scale: vec(0.95, 0.8, 0.78)))
        head.addChildNode(sphereNode(r * 0.2, 0x3E2F25, at: vec(0, -r * 0.95, r * 0.5), scale: vec(0.8, 1.3, 0.7)))

        // Armor: belt, tassets, a leather chest strap and a fur-lined shoulder.
        let belt = ringNode(radius: b.torsoWidth / 2 + 0.005, pipe: 0.05, leather, at: vec(0, b.legLength + 0.04, 0))
        belt.scale = vec(1, 1, 0.72)
        bobNode.addChildNode(belt)
        bobNode.addChildNode(boxNode(0.32, 0.4, 0.03, 0x6E2B22, at: vec(0, b.legLength - 0.16, b.torsoDepth / 2 + 0.02)))
        bobNode.addChildNode(boxNode(0.32, 0.36, 0.03, 0x6E2B22, at: vec(0, b.legLength - 0.14, -b.torsoDepth / 2 - 0.02)))
        let strap = ringNode(radius: b.torsoWidth / 2 + 0.004, pipe: 0.032, leather, at: vec(0, b.legLength + b.torsoTall * 0.55, 0))
        strap.scale = vec(1, 1, 0.72)
        strap.eulerAngles = vec(0, 0, 0.55)
        bobNode.addChildNode(strap)
        leftArm.addChildNode(sphereNode(0.17, 0x5B4A3A, at: vec(0, 0.03, 0), scale: vec(1.15, 0.8, 1.05)))

        // The Leviathan Axe in the right hand (on a pivot so it can swing)...
        let axe = SCNNode()
        axe.position = vec(0, -b.armLength, 0)
        axe.addChildNode(cylinderNode(radius: 0.03, height: 0.85, 0x6B4A2B, at: vec(0, 0.13, 0)))
        axe.addChildNode(boxNode(0.32, 0.22, 0.04, 0xCFEFFF, at: vec(0.17, 0.4, 0), chamfer: 0.012, glow: 0.4))
        axe.addChildNode(boxNode(0.1, 0.12, 0.035, 0x8FB8CC, at: vec(-0.08, 0.4, 0)))
        for i in 0..<3 {
            axe.addChildNode(ringNode(radius: 0.034, pipe: 0.008, 0xCFEFFF, at: vec(0, 0.02 + CGFloat(i) * 0.06, 0)))
        }
        rightArm.addChildNode(axe)
        prop = axe

        // ...and the Blades of Chaos: chains wrapped round the left forearm, a flaming blade at the end.
        for i in 0..<4 {
            let coil = ringNode(radius: b.armRadius * 1.25, pipe: 0.014, 0x9A9A9A, at: vec(0, -b.armLength * (0.3 + 0.1 * CGFloat(i)), 0))
            leftArm.addChildNode(coil)
        }
        let blades = SCNNode()
        blades.position = vec(0, -b.armLength, 0)
        blades.addChildNode(cylinderNode(radius: 0.012, height: 0.34, 0x9A9A9A, at: vec(0.04, -0.17, 0.03)))
        blades.addChildNode(coneNode(top: 0.05, bottom: 0, height: 0.26, 0xFF8A2A, at: vec(0.04, -0.47, 0.03), glow: 0.9))
        leftArm.addChildNode(blades)
        leftProp = blades

        rightArmFactor = 0.25
        canWave = false
        armSplay = 0.2

        root.scale = vec(1.1, 1.1, 1.1)
        height = b.totalHeight * 1.1
        legSwing = 0.5
        armSwing = 0.45
        bounce = 0.03
    }

    // MARK: Kung Fu Panda (fan-made)

    func buildPanda() {
        let b = Biped(headRadius: 0.34, torsoWidth: 0.7, torsoHeight: 0.72, legLength: 0.3, legRadius: 0.11, armLength: 0.42, armRadius: 0.11)
        let white: UInt32 = 0xF7F5EE
        let black: UInt32 = 0x1C1C1F
        assemble(b, headColor: white, torsoColor: white, armColor: black, handColor: black, legColor: black, shoeColor: nil)
        let r = b.headRadius

        for side in [CGFloat(-1), 1] {
            head.addChildNode(sphereNode(r * 0.4, black, at: vec(side * r * 0.72, r * 0.8, -r * 0.12)))

            // Tilted eye patches with a white eye and a pupil on each.
            let px = side * r * 0.37
            let py = r * 0.08
            let patch = sphereNode(r * 0.24, black, at: vec(px, py, surfaceDepth(r, px, py) * 0.9), scale: vec(1, 1.45, 0.5))
            patch.eulerAngles = vec(0, 0, side * 0.45)
            head.addChildNode(patch)
            let ex = side * r * 0.36
            let ey = r * 0.1
            let eyeZ = surfaceDepth(r, ex, ey) * 0.97 + r * 0.05
            head.addChildNode(sphereNode(r * 0.085, 0xFFFFFF, at: vec(ex, ey, eyeZ), scale: vec(1, 1.15, 0.6)))
            head.addChildNode(sphereNode(r * 0.045, 0x000000, at: vec(ex, ey, eyeZ + r * 0.035), scale: vec(1, 1.1, 0.6)))
        }
        head.addChildNode(sphereNode(r * 0.1, black, at: vec(0, -r * 0.06, surfaceDepth(r, 0, -r * 0.06) * 0.99), scale: vec(1.3, 0.8, 0.7)))
        addFace(radius: r, mouth: .grin, eyes: false, blush: false)

        // Tan shorts, a red sash, black shoulders and feet.
        for leg in [leftLeg, rightLeg] {
            leg.addChildNode(cylinderNode(radius: b.legRadius * 1.14, height: b.legLength * 0.55, 0xD9BE8C, at: vec(0, -b.legLength * 0.28, 0)))
            leg.addChildNode(sphereNode(b.legRadius * 1.2, black, at: vec(0, -b.legLength + 0.04, 0.06), scale: vec(1, 0.6, 1.5)))
        }
        let sash = ringNode(radius: b.torsoWidth / 2 + 0.004, pipe: 0.045, 0xC8402B, at: vec(0, b.legLength + 0.1, 0))
        sash.scale = vec(1, 1, 0.72)
        bobNode.addChildNode(sash)
        for arm in [leftArm, rightArm] {
            arm.addChildNode(sphereNode(b.armRadius * 1.6, black))
        }

        // A dumpling in the right hand, naturally.
        let dumplingY = -b.armLength - 0.03
        rightArm.addChildNode(sphereNode(0.1, 0xFFF4DC, at: vec(0, dumplingY, 0.06), scale: vec(1.2, 0.8, 1)))
        rightArm.addChildNode(ringNode(radius: 0.07, pipe: 0.012, 0xE8D7B5, at: vec(0, dumplingY + 0.03, 0.06)))
        rightArmFactor = 0.6

        legSwing = 0.5
        armSwing = 0.4
        bounce = 0.05
        sway = 0.04
        root.scale = vec(0.95, 0.95, 0.95)
        height = (b.headCenterY + r * 1.2) * 0.95
    }

    // MARK: Wukong, the Monkey King (fan-made)

    func buildWukong() {
        let b = Biped(headRadius: 0.27, torsoWidth: 0.42, torsoHeight: 0.5, legLength: 0.5, legRadius: 0.078, armLength: 0.52, armRadius: 0.07)
        let fur: UInt32 = 0xC98F3A
        let gold: UInt32 = 0xE9B93A
        let peach: UInt32 = 0xF3CFA5
        assemble(b, headColor: fur, torsoColor: 0x8E2B2B, armColor: fur, handColor: fur, legColor: 0x6E1F1F, shoeColor: 0x3B2A1E)
        let r = b.headRadius

        // A pale face mask, with the features pushed out in front of it.
        head.addChildNode(sphereNode(r * 0.72, peach, at: vec(0, -r * 0.12, r * 0.55), scale: vec(1, 0.95, 0.75)))
        addFace(radius: r, mouth: .grin, eyeColor: 0x2B1A0A, blush: false, forward: 0.12)
        addBrows(radius: r, color: 0x7A4E1A, angle: 0.2, forward: 0.1)
        for side in [CGFloat(-1), 1] {
            head.addChildNode(sphereNode(r * 0.3, fur, at: vec(side * r * 1.0, r * 0.08, -r * 0.05), scale: vec(0.5, 1, 1)))
            head.addChildNode(sphereNode(r * 0.2, peach, at: vec(side * r * 1.08, r * 0.08, 0), scale: vec(0.4, 1, 1)))

            // Long red phoenix feathers sweeping back from the headband.
            let feather = coneNode(top: 0.004, bottom: 0.03, height: 0.5, 0xD9382B, at: vec(side * r * 0.45 + side * 0.03, r * 0.95 + 0.23, -r * 0.2 - 0.1))
            feather.eulerAngles = vec(-0.4, 0, -side * 0.3)
            head.addChildNode(feather)
        }
        head.addChildNode(ringNode(radius: r * 0.91, pipe: r * 0.05, gold, at: vec(0, r * 0.42, 0)))

        // Armor trim and a curly tail.
        for arm in [leftArm, rightArm] {
            arm.addChildNode(sphereNode(0.1, gold, scale: vec(1.1, 0.8, 1.1)))
            arm.addChildNode(cylinderNode(radius: b.armRadius * 1.2, height: 0.08, gold, at: vec(0, -b.armLength * 0.85, 0)))
        }
        for leg in [leftLeg, rightLeg] {
            leg.addChildNode(cylinderNode(radius: b.legRadius * 1.2, height: 0.2, gold, at: vec(0, -b.legLength * 0.72, 0)))
        }
        let waist = ringNode(radius: b.torsoWidth / 2 + 0.004, pipe: 0.03, gold, at: vec(0, b.legLength + 0.04, 0))
        waist.scale = vec(1, 1, 0.72)
        bobNode.addChildNode(waist)

        let tailNode = SCNNode()
        tailNode.position = vec(0, b.legLength + 0.05, -b.torsoDepth / 2)
        for i in 0..<7 {
            let t = CGFloat(i)
            tailNode.addChildNode(sphereNode(0.05 - 0.004 * t, fur, at: vec(0, 0.014 * t * t + 0.03 * t, -0.07 * t)))
        }
        bobNode.addChildNode(tailNode)
        tail = tailNode

        // The golden staff, planted like a walking stick (on a pivot at the hand so it can spin).
        let staff = SCNNode()
        staff.position = vec(0, -b.armLength, 0)
        staff.addChildNode(cylinderNode(radius: 0.032, height: 1.5, 0xB22A2A, at: vec(0, 0.4, 0)))
        staff.addChildNode(cylinderNode(radius: 0.047, height: 0.14, gold, at: vec(0, 1.15, 0)))
        staff.addChildNode(cylinderNode(radius: 0.047, height: 0.14, gold, at: vec(0, -0.35, 0)))
        staff.addChildNode(ringNode(radius: 0.036, pipe: 0.01, gold, at: vec(0, 0.55, 0)))
        staff.addChildNode(ringNode(radius: 0.036, pipe: 0.01, gold, at: vec(0, 0.25, 0)))
        rightArm.addChildNode(staff)
        prop = staff
        rightArmFactor = 0.2
        canWave = false

        height = b.headCenterY + r * 0.95 + 0.46
        legSwing = 0.55
    }

    // MARK: Hulk (fan-made)

    func buildHulk() {
        let b = Biped(headRadius: 0.21, torsoWidth: 0.86, torsoHeight: 0.8, legLength: 0.45, legRadius: 0.15, armLength: 0.6, armRadius: 0.16)
        let green: UInt32 = 0x5DAA3A
        let deepGreen: UInt32 = 0x4B9230
        let purple: UInt32 = 0x6E4B9E
        assemble(b, headColor: green, torsoColor: green, armColor: green, handColor: green, legColor: green, shoeColor: deepGreen)
        let r = b.headRadius
        let chestY = b.legLength + b.torsoTall * 0.72

        // Slabs of muscle: traps, pecs, abs and gigantic shoulders.
        for side in [CGFloat(-1), 1] {
            bobNode.addChildNode(sphereNode(0.2, green, at: vec(side * 0.2, b.legLength + b.torsoTall + 0.0, 0), scale: vec(1, 0.8, 0.9)))
            bobNode.addChildNode(sphereNode(0.2, green, at: vec(side * 0.2, chestY, b.torsoDepth / 2 - 0.05), scale: vec(1, 0.8, 0.6)))
            for row in 0..<3 {
                bobNode.addChildNode(sphereNode(0.075, deepGreen, at: vec(side * 0.075, b.legLength + b.torsoTall * 0.5 - CGFloat(row) * 0.14, b.torsoDepth / 2 - 0.005), scale: vec(1, 0.8, 0.5)))
            }
        }
        for arm in [leftArm, rightArm] {
            arm.addChildNode(sphereNode(b.armRadius * 1.45, green, at: vec(0, 0.0, 0)))
        }

        // Torn purple shorts.
        for leg in [leftLeg, rightLeg] {
            leg.addChildNode(cylinderNode(radius: b.legRadius * 1.12, height: b.legLength * 0.62, purple, at: vec(0, -b.legLength * 0.3, 0)))
        }
        let waist = ringNode(radius: b.torsoWidth / 2 + 0.005, pipe: 0.06, purple, at: vec(0, b.legLength + 0.06, 0))
        waist.scale = vec(1, 1, 0.72)
        bobNode.addChildNode(waist)

        // A small head with a heavy brow, a big jaw and wild dark hair.
        head.addChildNode(sphereNode(r * 0.8, green, at: vec(0, -r * 0.55, r * 0.15), scale: vec(1.15, 0.75, 0.9)))
        addFace(radius: r, mouth: .flat, eyeColor: 0xE6FFC4, blush: false)
        addBrows(radius: r, color: 0x1F2A18, angle: 0.6)
        head.addChildNode(sphereNode(r * 1.08, 0x1A1A1A, at: vec(0, r * 0.25, -r * 0.3), scale: vec(1, 0.85, 1)))
        for i in 0..<5 {
            head.addChildNode(sphereNode(r * 0.3, 0x1A1A1A, at: vec((CGFloat(i) - 2) * r * 0.32, r * 0.95, -r * 0.1 + CGFloat(i % 2) * r * 0.2)))
        }

        root.scale = vec(1.05, 1.05, 1.05)
        height = b.totalHeight * 1.05
        legSwing = 0.5
        armSwing = 0.35
        armSplay = 0.45
        bounce = 0.06
        sway = 0.03
    }

    // MARK: Imported model

    /// Loads a model file into a single node, or nil if SceneKit can't read it.
    static func loadModelNode(url: URL) -> SCNNode? {
        guard let scene = try? SCNScene(url: url, options: nil) else { return nil }
        let container = SCNNode()
        for child in scene.rootNode.childNodes { container.addChildNode(child) }
        guard !container.childNodes.isEmpty else { return nil }
        return container
    }

    /// Fits the model to the stage (about 1.5 m tall, feet on the ground, centered) and gives it a waddle.
    func buildModel(url: URL, rotationDegrees: Int) -> Bool {
        guard let container = Self.loadModelNode(url: url) else { return false }
        let (low, high) = container.boundingBox
        let modelHeight = high.y - low.y
        let modelWidth = max(high.x - low.x, high.z - low.z)
        guard modelHeight > 0.0001 else { return false }

        let targetHeight: CGFloat = 1.5
        var scale = targetHeight / modelHeight
        if modelWidth * scale > 1.6 { scale = 1.6 / modelWidth }
        container.scale = vec(scale, scale, scale)
        container.position = vec(-(low.x + high.x) / 2 * scale, -low.y * scale, -(low.z + high.z) / 2 * scale)

        let holder = SCNNode()
        holder.eulerAngles = vec(0, CGFloat(rotationDegrees) * .pi / 180, 0)
        holder.addChildNode(container)
        bobNode.addChildNode(holder)

        // Animations that ship inside the model (walk cycles, idle loops) play while the avatar is active.
        container.enumerateHierarchy { node, _ in
            for key in node.animationKeys {
                guard let player = node.animationPlayer(forKey: key) else { continue }
                player.animation.repeatCount = .infinity
                player.play()
            }
        }

        height = modelHeight * scale + 0.1
        sway = 0.07
        bounce = 0.05
        canWave = false
        return true
    }
}
