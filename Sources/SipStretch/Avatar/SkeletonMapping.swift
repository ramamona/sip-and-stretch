import Foundation
import SipStretchCore

/// Finds a person-shaped skeleton inside a model, without relying on what its bones are called
/// (exported rigs are often named `n1087`, `Bone.012`, or something in another language).
///
/// It works from the shape of the T-pose instead, in a space where the model stands upright (Y up)
/// facing the camera with its arms out along the X axis:
/// - the arms are the bones reaching furthest to either side, and each shoulder is the first bone on
///   the way in from the hand that is clear of the chest;
/// - the legs are the lowest bones on each side, and the hip is the top of their branch of the skeleton;
/// - the head is the heaviest bone high on the midline, with the neck as far below it as the skull is above.
///
/// The result says which joint each bone should follow, and where each joint pivots. It is plain data,
/// so it's cheap to compute and independent of SceneKit.
struct SkeletonMapping {
    /// For every bone, the `Joint.rawValue` it follows, or -1 if it stays with the body.
    var region: [Int]
    /// Where each joint pivots, by `Joint.rawValue`, in the T-pose.
    var pivot: [SIMD3<Double>]
    /// The fingertips, left then right, used to work out how far to lower the arms.
    var armTip: [SIMD3<Double>]
    /// Thigh and shin lengths.
    var upperLeg: Double
    var lowerLeg: Double
    /// The point on the ground the character stands on.
    var feet: SIMD3<Double>
    /// One line per finding, for the debug log.
    var summary: String

    var legLength: Double { upperLeg + lowerLeg }

    /// - Parameters:
    ///   - parent: each bone's parent (an index into the same arrays), or -1.
    ///   - position: each bone's position in the T-pose.
    ///   - weight: how much skin each bone moves (0 for bones that move nothing).
    ///   - ground, top: lowest and highest point of the model.
    static func find(parent: [Int], position: [SIMD3<Double>], weight: [Double], names: [String], ground: Double, top: Double) -> SkeletonMapping? {
        let n = parent.count
        let height = top - ground
        guard n >= 12, position.count == n, weight.count == n, height > 1e-9 else { return nil }

        var children = Array(repeating: [Int](), count: n)
        for (i, p) in parent.enumerated() where p >= 0 { children[p].append(i) }
        func subtree(_ root: Int) -> [Int] {
            var found: [Int] = []
            var stack = [root]
            while let i = stack.popLast() {
                found.append(i)
                stack.append(contentsOf: children[i])
            }
            return found
        }
        let weighted = weight.map { $0 > 1.0 }
        func rel(_ i: Int) -> Double { (position[i].y - ground) / height }

        // Arms.
        var armTip: [Int] = []
        var armRoot: [Int] = []
        for sign in [1.0, -1.0] {
            var tip = -1
            var reach = -Double.infinity
            for i in 0..<n where weighted[i] && sign * position[i].x > 0.25 * height && rel(i) > 0.45 {
                if sign * position[i].x > reach {
                    reach = sign * position[i].x
                    tip = i
                }
            }
            guard tip >= 0 else { return nil }
            var root = -1
            var i = tip
            while i >= 0 && abs(position[i].x) >= 0.07 * height && rel(i) > 0.45 {
                root = i
                i = parent[i]
            }
            guard root >= 0 else { return nil }
            armTip.append(tip)
            armRoot.append(root)
        }
        var armBones = Set<Int>()
        for root in armRoot { armBones.formUnion(subtree(root)) }

        // Legs.
        var foot: [Int] = []
        var legRoot: [Int] = []
        for sign in [1.0, -1.0] {
            var lowest = Double.infinity
            var f = -1
            for i in 0..<n where weighted[i] && sign * position[i].x > 0.01 * height && !armBones.contains(i) {
                if position[i].y < lowest {
                    lowest = position[i].y
                    f = i
                }
            }
            guard f >= 0 else { return nil }
            var root = f
            while parent[root] >= 0 {
                let up = parent[root]
                if armBones.contains(up) { break }
                let staysOnOneSide = subtree(up).allSatisfy { !weighted[$0] || sign * position[$0].x > -0.01 * height }
                if !staysOnOneSide { break }
                root = up
            }
            foot.append(f)
            legRoot.append(root)
        }
        let legBones = legRoot.map { Set(subtree($0)) }
        let allLeg = legBones[0].union(legBones[1])
        let legWeighted = legRoot.map { subtree($0).filter { weighted[$0] } }
        guard !legWeighted[0].isEmpty, !legWeighted[1].isEmpty else { return nil }

        let hipY = legWeighted.map { bones in bones.map { position[$0].y }.max() ?? ground }.reduce(0, +) / 2
        let footY = (position[foot[0]].y + position[foot[1]].y) / 2
        let kneeY = (hipY + footY) / 2
        var hip: [SIMD3<Double>] = []
        for bones in legWeighted {
            let count = Double(bones.count)
            let x = bones.map { position[$0].x }.reduce(0, +) / count
            let z = bones.map { position[$0].z }.reduce(0, +) / count
            hip.append(SIMD3<Double>(x, hipY, z))
        }

        // Head and spine.
        let headCandidates = (0..<n).filter {
            weighted[$0] && rel($0) > 0.78 && abs(position[$0].x) < 0.1 * height && !armBones.contains($0) && !allLeg.contains($0)
        }
        guard let headBone = headCandidates.max(by: { weight[$0] < weight[$1] }) else { return nil }
        let neckY = max(position[headBone].y - (top - position[headBone].y), ground + 0.68 * height)
        var headRoot = headBone
        while parent[headRoot] >= 0 {
            let up = parent[headRoot]
            if position[up].y >= neckY - 0.03 * height && !armBones.contains(up) && !allLeg.contains(up) {
                headRoot = up
            } else {
                break
            }
        }
        let chestY = hipY + 0.45 * (neckY - hipY)
        let spineZ = (hip[0].z + hip[1].z) / 2

        // Joint pivots.
        var pivot = Array(repeating: SIMD3<Double>(0, 0, 0), count: Joint.allCases.count)
        pivot[Joint.spine.rawValue] = SIMD3<Double>(0, hipY, spineZ)
        pivot[Joint.chest.rawValue] = SIMD3<Double>(0, chestY, spineZ)
        pivot[Joint.head.rawValue] = SIMD3<Double>(position[headRoot].x, neckY, position[headRoot].z)

        var tips: [SIMD3<Double>] = []
        var upperLeg = 0.0
        var lowerLeg = 0.0
        for s in 0..<2 {
            let sign = s == 0 ? 1.0 : -1.0
            let shoulder = s == 0 ? Joint.shoulderL : .shoulderR
            let elbow = s == 0 ? Joint.elbowL : .elbowR
            let hipJoint = s == 0 ? Joint.hipL : .hipR
            let kneeJoint = s == 0 ? Joint.kneeL : .kneeR
            let ankleJoint = s == 0 ? Joint.ankleL : .ankleR

            let shoulderPos = position[armRoot[s]]
            let tipPos = position[armTip[s]]
            var elbowPos = shoulderPos + 0.45 * (tipPos - shoulderPos)
            // The elbow is wherever the arm's own bone is nearest to the middle of the arm, so that bone's helpers bend with it.
            let armCandidates = subtree(armRoot[s]).filter { weighted[$0] && abs(position[$0].x - shoulderPos.x) > 0.02 * height }
            if let nearest = armCandidates.min(by: { abs(sign * (position[$0].x - elbowPos.x)) < abs(sign * (position[$1].x - elbowPos.x)) }),
               abs(position[nearest].x - elbowPos.x) < 0.06 * height {
                elbowPos.x = position[nearest].x
            }
            tips.append(tipPos)
            pivot[shoulder.rawValue] = shoulderPos
            pivot[elbow.rawValue] = elbowPos

            let legBonesHere = legWeighted[s]
            let kneeBone = legBonesHere.min(by: { abs(position[$0].y - kneeY) < abs(position[$1].y - kneeY) }) ?? foot[s]
            let ky = abs(position[kneeBone].y - kneeY) < 0.06 * height ? position[kneeBone].y : kneeY
            let ankleTarget = position[foot[s]].y + 0.035 * height
            let ankleBone = legBonesHere.min(by: { abs(position[$0].y - ankleTarget) < abs(position[$1].y - ankleTarget) }) ?? foot[s]
            let ay = abs(position[ankleBone].y - ankleTarget) < 0.03 * height ? position[ankleBone].y : ankleTarget
            pivot[hipJoint.rawValue] = hip[s]
            pivot[kneeJoint.rawValue] = SIMD3<Double>(hip[s].x, ky, hip[s].z)
            pivot[ankleJoint.rawValue] = SIMD3<Double>(hip[s].x, ay, hip[s].z)
            upperLeg += (hipY - ky) / 2
            lowerLeg += (ky - ay) / 2
        }
        guard upperLeg > 1e-6, lowerLeg > 1e-6 else { return nil }

        // Which joint moves each bone: the deepest one wins.
        var region = Array(repeating: -1, count: n)
        for k in 0..<n where position[k].y >= hipY - 0.01 * height && !allLeg.contains(k) && !armBones.contains(k) {
            region[k] = position[k].y >= chestY ? Joint.chest.rawValue : Joint.spine.rawValue
        }
        for k in subtree(headRoot) { region[k] = Joint.head.rawValue }
        for s in 0..<2 {
            let sign = s == 0 ? 1.0 : -1.0
            let shoulder = s == 0 ? Joint.shoulderL : .shoulderR
            let elbow = s == 0 ? Joint.elbowL : .elbowR
            let hipJoint = s == 0 ? Joint.hipL : .hipR
            let kneeJoint = s == 0 ? Joint.kneeL : .kneeR
            let ankleJoint = s == 0 ? Joint.ankleL : .ankleR
            let elbowX = pivot[elbow.rawValue].x
            for k in subtree(armRoot[s]) {
                region[k] = shoulder.rawValue
                if sign * position[k].x >= sign * elbowX - 0.005 * height { region[k] = elbow.rawValue }
            }
            let kneeLimit = pivot[kneeJoint.rawValue].y + 0.005 * height
            let ankleLimit = pivot[ankleJoint.rawValue].y + 0.005 * height
            for k in legBones[s] {
                region[k] = hipJoint.rawValue
                if position[k].y <= kneeLimit { region[k] = kneeJoint.rawValue }
                if position[k].y <= ankleLimit { region[k] = ankleJoint.rawValue }
            }
        }

        func name(_ i: Int) -> String { i < names.count ? names[i] : "#\(i)" }
        var counts: [String] = []
        for joint in Joint.allCases {
            counts.append("\(joint.code)=\(region.filter { $0 == joint.rawValue }.count)")
        }
        let summary = """
            bones \(n), height \(String(format: "%.3f", height))
            arms: tips \(name(armTip[0])) / \(name(armTip[1])), shoulders \(name(armRoot[0])) / \(name(armRoot[1]))
            legs: feet \(name(foot[0])) / \(name(foot[1])), roots \(name(legRoot[0])) / \(name(legRoot[1])), hip \(String(format: "%.2f", (hipY - ground) / height))H, knee \(String(format: "%.2f", (kneeY - ground) / height))H
            head: bone \(name(headBone)), root \(name(headRoot)), neck \(String(format: "%.2f", (neckY - ground) / height))H
            bones per joint: \(counts.joined(separator: " "))
            """
        return SkeletonMapping(
            region: region,
            pivot: pivot,
            armTip: tips,
            upperLeg: upperLeg,
            lowerLeg: lowerLeg,
            feet: SIMD3<Double>(0, ground, spineZ),
            summary: summary
        )
    }
}
