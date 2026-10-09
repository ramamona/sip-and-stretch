import AppKit
import SceneKit
import simd
import SipStretchCore

/// Poses the skeleton of an imported model: finds the joints (see `SkeletonMapping`), lowers the arms
/// out of the T-pose, then bends them for each `Pose` the animation engine produces.
///
/// Every bone follows one joint. A joint rotates about its own pivot and carries the joints below it (a
/// shoulder carries the elbow, a hip the knee), so a pose is a short chain of matrix products, and each
/// bone's new place in the world is turned back into the local transform SceneKit wants. SceneKit then
/// skins the mesh to the moved bones as usual.
///
/// This is not tied to the main thread: `apply` runs on the render thread, once per frame, and only
/// touches the bone nodes.
final class SkeletonRig {
    private struct Bone {
        let node: SCNNode
        /// Index of the parent in `bones`, or -1 when the parent isn't one of the bones (then `fixedParentWorld` applies).
        let parent: Int
        let fixedParentWorld: simd_double4x4
        /// -1 for none, otherwise a `Joint.rawValue`.
        let region: Int
        /// Where the bone sits in the T-pose after the arms have been lowered, in the upright space.
        let restPosed: simd_double4x4
    }

    private let bones: [Bone]
    private let fromUpright: simd_double4x4
    /// Joint pivots after the arms have been lowered, by `Joint.rawValue`.
    private let pivots: [SIMD3<Double>]
    private let feet: SIMD3<Double>
    private let upperLeg: Double
    private let lowerLeg: Double
    private var lastPose: Pose?

    /// How long the legs are, in the model's own units.
    var legLength: Double { upperLeg + lowerLeg }
    /// What was found, for the debug log.
    let summary: String

    private init(bones: [Bone], fromUpright: simd_double4x4, pivots: [SIMD3<Double>], feet: SIMD3<Double>, upperLeg: Double, lowerLeg: Double, summary: String) {
        self.bones = bones
        self.fromUpright = fromUpright
        self.pivots = pivots
        self.feet = feet
        self.upperLeg = upperLeg
        self.lowerLeg = lowerLeg
        self.summary = summary
    }

    // MARK: Finding the skeleton

    /// Looks for a person-shaped skeleton in `container` (a model standing in a T-pose). Returns nil if it
    /// isn't one, in which case the caller falls back to moving the model as a whole.
    /// `rotationDegrees` is the turn that makes the model face the camera.
    static func make(container: SCNNode, rotationDegrees: Int, style: MotionStyle) -> SkeletonRig? {
        var skinners: [SCNSkinner] = []
        container.enumerateHierarchy { node, _ in
            if let skinner = node.skinner { skinners.append(skinner) }
        }
        guard !skinners.isEmpty else { return nil }

        // Every bone any skin uses, and the nodes in between (the skeleton's null joints).
        var members: [SCNNode] = []
        var known = Set<ObjectIdentifier>()
        func add(_ node: SCNNode) {
            if known.insert(ObjectIdentifier(node)).inserted { members.append(node) }
        }
        for skinner in skinners {
            for bone in skinner.bones { add(bone) }
        }
        guard members.count >= 12 else { return nil }
        let boneCount = members.count
        let topmost = lowestCommonAncestor(of: members, below: container)
        for index in 0..<boneCount {
            var node = members[index].parent
            while let current = node, current !== container, current !== topmost?.parent {
                add(current)
                node = current.parent
            }
        }

        // Parents first.
        func depth(_ node: SCNNode) -> Int {
            var d = 0
            var current = node.parent
            while let c = current, c !== container {
                d += 1
                current = c.parent
            }
            return d
        }
        let ordered = members.sorted { depth($0) < depth($1) }
        var indexOf: [ObjectIdentifier: Int] = [:]
        for (i, node) in ordered.enumerated() { indexOf[ObjectIdentifier(node)] = i }

        // How much of the skin each bone moves, to tell real bones from the null joints a rig hangs them on.
        var weights = Array(repeating: 0.0, count: ordered.count)
        var readWeights = true
        for skinner in skinners {
            if !accumulateWeights(of: skinner, indexOf: indexOf, into: &weights) { readWeights = false }
        }
        if !readWeights {
            for skinner in skinners {
                for bone in skinner.bones { if let i = indexOf[ObjectIdentifier(bone)] { weights[i] = 100 } }
            }
        }

        // Positions in the model's space, then in the upright space the animations are written in.
        let angle = Double(rotationDegrees) * Double.pi / 180
        let toUpright = rotationY(angle)
        let fromUpright = rotationY(-angle)
        let identity = matrix_identity_float4x4
        let restModel: [simd_double4x4] = ordered.map { toDouble($0.simdConvertTransform(identity, to: container)) }
        let restUpright = restModel.map { toUpright * $0 }
        let positions = restUpright.map { position(of: $0) }
        let parents = ordered.map { node -> Int in
            guard let p = node.parent else { return -1 }
            return indexOf[ObjectIdentifier(p)] ?? -1
        }
        // The model's extent, from its bounding box; if that doesn't agree with where the bones are (a rig
        // whose mesh and skeleton sit in different units), estimate it from the bones instead.
        let box = container.boundingBox
        var ground = Double(box.min.y)
        var top = Double(box.max.y)
        let boneHeights = zip(positions, weights).filter { $0.1 > 1.0 }.map { $0.0.y }
        if let lowest = boneHeights.min(), let highest = boneHeights.max(), highest > lowest {
            let span = highest - lowest
            if top - ground < span * 0.95 || top - ground > span * 1.6 {
                debugLog("bounding box (\(ground)…\(top)) doesn't match the bones (\(lowest)…\(highest)); using the bones")
                ground = lowest - 0.015 * span
                top = highest + 0.10 * span
            }
        }
        let names = ordered.map { $0.name ?? "-" }

        guard let mapping = SkeletonMapping.find(parent: parents, position: positions, weight: weights, names: names, ground: ground, top: top) else {
            debugLog("no person-shaped skeleton found in \(ordered.count) nodes (height \(top - ground))")
            return nil
        }

        // Lower the arms out of the T-pose to a natural hang.
        var lowering: [simd_double4x4] = [matrix_identity_double4x4, matrix_identity_double4x4]
        var pivots = mapping.pivot
        for s in 0..<2 {
            let sign = s == 0 ? 1.0 : -1.0
            let shoulderJoint = s == 0 ? Joint.shoulderL : .shoulderR
            let elbowJoint = s == 0 ? Joint.elbowL : .elbowR
            let shoulder = mapping.pivot[shoulderJoint.rawValue]
            let along = mapping.armTip[s] - shoulder
            let current = atan2(sign * along.x, -along.y)
            let turn = sign * (style.restAbduction - current)
            lowering[s] = translation(shoulder) * rotationZ(turn) * translation(-shoulder)
            pivots[elbowJoint.rawValue] = transform(mapping.pivot[elbowJoint.rawValue], by: lowering[s])
        }

        var built: [Bone] = []
        built.reserveCapacity(ordered.count)
        for (i, node) in ordered.enumerated() {
            let region = mapping.region[i]
            var posed = restUpright[i]
            if region == Joint.shoulderL.rawValue || region == Joint.elbowL.rawValue { posed = lowering[0] * posed }
            if region == Joint.shoulderR.rawValue || region == Joint.elbowR.rawValue { posed = lowering[1] * posed }
            var fixed = matrix_identity_double4x4
            if parents[i] < 0, let parent = node.parent, parent !== container {
                fixed = toDouble(parent.simdConvertTransform(identity, to: container))
            }
            built.append(Bone(node: node, parent: parents[i], fixedParentWorld: fixed, region: region, restPosed: posed))
        }

        let rig = SkeletonRig(
            bones: built,
            fromUpright: fromUpright,
            pivots: pivots,
            feet: mapping.feet,
            upperLeg: mapping.upperLeg,
            lowerLeg: mapping.lowerLeg,
            summary: mapping.summary
        )
        debugLog("skeleton found\n\(mapping.summary)")
        rig.apply(Pose())
        return rig
    }

    private static func lowestCommonAncestor(of nodes: [SCNNode], below container: SCNNode) -> SCNNode? {
        guard var candidate = nodes.first else { return nil }
        func isAncestor(_ a: SCNNode, of b: SCNNode) -> Bool {
            var current: SCNNode? = b
            while let c = current {
                if c === a { return true }
                current = c.parent
            }
            return false
        }
        while !nodes.allSatisfy({ isAncestor(candidate, of: $0) }) {
            guard let up = candidate.parent, up !== container else { return nil }
            candidate = up
        }
        return candidate
    }

    /// Adds up how much skin each bone moves, from the skin's per-vertex bone weights.
    private static func accumulateWeights(of skinner: SCNSkinner, indexOf: [ObjectIdentifier: Int], into totals: inout [Double]) -> Bool {
        let weightSource: SCNGeometrySource? = skinner.boneWeights
        let indexSource: SCNGeometrySource? = skinner.boneIndices
        guard let weights = weightSource, let indices = indexSource else { return false }
        let vertices = weights.vectorCount
        let perVertex = weights.componentsPerVector
        let indexSize = indices.bytesPerComponent
        guard vertices > 0, perVertex > 0, weights.usesFloatComponents, weights.bytesPerComponent == 4,
              indexSize == 1 || indexSize == 2, indices.componentsPerVector == perVertex, indices.vectorCount == vertices
        else { return false }
        let skinBones: [SCNNode] = skinner.bones
        let weightData = weights.data
        let indexData = indices.data
        weightData.withUnsafeBytes { (weightBytes: UnsafeRawBufferPointer) in
            indexData.withUnsafeBytes { (indexBytes: UnsafeRawBufferPointer) in
                for vertex in 0..<vertices {
                    for k in 0..<perVertex {
                        let weightOffset = weights.dataOffset + vertex * weights.dataStride + k * 4
                        let indexOffset = indices.dataOffset + vertex * indices.dataStride + k * indexSize
                        guard weightOffset + 4 <= weightBytes.count, indexOffset + indexSize <= indexBytes.count else { continue }
                        let weight = weightBytes.loadUnaligned(fromByteOffset: weightOffset, as: Float.self)
                        let bone: Int = indexSize == 1
                            ? Int(indexBytes.loadUnaligned(fromByteOffset: indexOffset, as: UInt8.self))
                            : Int(indexBytes.loadUnaligned(fromByteOffset: indexOffset, as: UInt16.self))
                        if bone < skinBones.count, let slot = indexOf[ObjectIdentifier(skinBones[bone])] { totals[slot] += Double(weight) }
                    }
                }
            }
        }
        return true
    }

    // MARK: Posing

    /// Poses the skeleton. Cheap enough to call every frame; it does nothing if the pose hasn't changed.
    func apply(_ pose: Pose) {
        if let lastPose, lastPose == pose { return }
        lastPose = pose

        // Each joint's motion, carrying the joints below it.
        var joints = [simd_double4x4](repeating: matrix_identity_double4x4, count: Joint.allCases.count)
        for joint in Joint.allCases {
            let base = joint.parent.map { joints[$0.rawValue] } ?? matrix_identity_double4x4
            let pivot = pivots[joint.rawValue]
            joints[joint.rawValue] = base * translation(pivot) * rotation(of: joint, in: pose) * translation(-pivot)
        }

        // The body itself: shifted, leaned about the feet, and held down on the ground as the legs fold.
        let unit = upperLeg + lowerLeg
        var legHeight = 0.0
        for (hip, knee) in [(Joint.hipL, Joint.kneeL), (Joint.hipR, Joint.kneeR)] {
            let h = pose[hip, .pitch]
            let k = pose[knee, .pitch]
            legHeight = max(legHeight, upperLeg * cos(h) + lowerLeg * cos(h - k))
        }
        let lift = pose.values[Pose.rootY]
        let plant = (legHeight - unit) * min(1, max(0, 1 - lift / 0.12))
        let shift = SIMD3<Double>(pose.values[Pose.rootX] * unit, lift * unit + plant, pose.values[Pose.rootZ] * unit)
        let tilt = rotationY(pose.values[Pose.leanYaw]) * rotationX(pose.values[Pose.leanPitch]) * rotationZ(pose.values[Pose.leanRoll])
        let body = translation(shift) * translation(feet) * tilt * translation(-feet)

        var worlds = [simd_double4x4](repeating: matrix_identity_double4x4, count: bones.count)
        for i in bones.indices {
            let bone = bones[i]
            var world = bone.restPosed
            if bone.region >= 0 { world = joints[bone.region] * world }
            world = fromUpright * body * world
            worlds[i] = world
            let parentWorld = bone.parent >= 0 ? worlds[bone.parent] : bone.fixedParentWorld
            bone.node.simdTransform = toFloat(parentWorld.inverse * world)
        }
    }

    private func rotation(of joint: Joint, in pose: Pose) -> simd_double4x4 {
        let pitch = pose[joint, .pitch] * joint.pitchSign
        let yaw = pose[joint, .yaw]
        let roll = pose[joint, .roll]
        switch joint {
        case .spine, .chest, .head:
            return rotationY(yaw) * rotationX(pitch) * rotationZ(-roll)
        default:
            return rotationX(pitch) * rotationZ(joint.side * roll) * rotationY(joint.side * yaw)
        }
    }
}

// MARK: - Matrix helpers (column vectors, right-handed, like SceneKit)

private func translation(_ p: SIMD3<Double>) -> simd_double4x4 {
    var m = matrix_identity_double4x4
    m.columns.3 = SIMD4<Double>(p.x, p.y, p.z, 1)
    return m
}

private func rotationX(_ a: Double) -> simd_double4x4 {
    let c = cos(a)
    let s = sin(a)
    return simd_double4x4(columns: (SIMD4<Double>(1, 0, 0, 0), SIMD4<Double>(0, c, s, 0), SIMD4<Double>(0, -s, c, 0), SIMD4<Double>(0, 0, 0, 1)))
}

private func rotationY(_ a: Double) -> simd_double4x4 {
    let c = cos(a)
    let s = sin(a)
    return simd_double4x4(columns: (SIMD4<Double>(c, 0, -s, 0), SIMD4<Double>(0, 1, 0, 0), SIMD4<Double>(s, 0, c, 0), SIMD4<Double>(0, 0, 0, 1)))
}

private func rotationZ(_ a: Double) -> simd_double4x4 {
    let c = cos(a)
    let s = sin(a)
    return simd_double4x4(columns: (SIMD4<Double>(c, s, 0, 0), SIMD4<Double>(-s, c, 0, 0), SIMD4<Double>(0, 0, 1, 0), SIMD4<Double>(0, 0, 0, 1)))
}

private func position(of m: simd_double4x4) -> SIMD3<Double> {
    SIMD3<Double>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
}

private func transform(_ p: SIMD3<Double>, by m: simd_double4x4) -> SIMD3<Double> {
    let v = m * SIMD4<Double>(p.x, p.y, p.z, 1)
    return SIMD3<Double>(v.x, v.y, v.z)
}

private func toDouble(_ m: simd_float4x4) -> simd_double4x4 {
    func column(_ v: SIMD4<Float>) -> SIMD4<Double> { SIMD4<Double>(Double(v.x), Double(v.y), Double(v.z), Double(v.w)) }
    return simd_double4x4(columns: (column(m.columns.0), column(m.columns.1), column(m.columns.2), column(m.columns.3)))
}

private func toFloat(_ m: simd_double4x4) -> simd_float4x4 {
    func column(_ v: SIMD4<Double>) -> SIMD4<Float> { SIMD4<Float>(Float(v.x), Float(v.y), Float(v.z), Float(v.w)) }
    return simd_float4x4(columns: (column(m.columns.0), column(m.columns.1), column(m.columns.2), column(m.columns.3)))
}

/// Prints to stderr when `SIPSTRETCH_AVATAR_DEBUG` is set, to help work out why a model moves oddly.
func debugLog(_ message: @autoclosure () -> String) {
    guard ProcessInfo.processInfo.environment["SIPSTRETCH_AVATAR_DEBUG"] != nil else { return }
    FileHandle.standardError.write(Data(("[avatar] " + message() + "\n").utf8))
}
