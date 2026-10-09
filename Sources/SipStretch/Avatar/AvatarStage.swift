import AppKit
import SceneKit
import SwiftUI

/// The tiny "set" an avatar stands on: a camera, two lights and a transparent background.
/// Used by the walking overlay and the Settings preview, so both show the same thing.
@MainActor
enum AvatarStage {
    /// How many metres of scene the window shows top to bottom.
    static let visibleHeight: CGFloat = 2.7
    /// The feet stand this far (metres) above the bottom edge of the view, leaving room for the shadow.
    static let groundInset: CGFloat = 0.15
    private static let fieldOfView: CGFloat = 24
    private static let cameraName = "avatar-camera"

    static func makeRig(look: AvatarLook) -> AvatarRig {
        let face = look.photoRevision.flatMap { AvatarStorage.facePhoto(revision: $0) }
        let modelURL = look.modelFileName.isEmpty ? nil : AvatarStorage.modelURL(look.modelFileName)
        return AvatarRig(look: look, facePhoto: face, modelURL: modelURL)
    }

    static func makeScene(for rig: AvatarRig) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        scene.rootNode.addChildNode(rig.root)

        let camera = SCNCamera()
        camera.fieldOfView = fieldOfView
        camera.zNear = 0.5
        camera.zFar = 40
        let cameraNode = SCNNode()
        cameraNode.name = cameraName
        cameraNode.camera = camera
        // Slightly above and tilted down, so the ground shadow shows as an ellipse and limbs read as 3D.
        let distance = (visibleHeight / 2) / tan(fieldOfView / 2 * .pi / 180)
        let lift: CGFloat = 0.9
        cameraNode.position = vec(0, visibleHeight / 2 - groundInset + lift, distance)
        cameraNode.eulerAngles = vec(-atan2(lift, distance), 0, 0)
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 360
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let key = SCNLight()
        key.type = .directional
        key.intensity = 620
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = vec(-0.7, -0.5, 0)
        scene.rootNode.addChildNode(keyNode)

        // A cool rim light from behind-right separates the silhouette from any background, and a soft
        // fill from the left keeps the shadow side from going muddy.
        let rim = SCNLight()
        rim.type = .directional
        rim.intensity = 380
        rim.color = NSColor(hex: 0xBFD8FF)
        let rimNode = SCNNode()
        rimNode.light = rim
        rimNode.eulerAngles = vec(-0.4, 2.6, 0)
        scene.rootNode.addChildNode(rimNode)

        let fill = SCNLight()
        fill.type = .directional
        fill.intensity = 220
        let fillNode = SCNNode()
        fillNode.light = fill
        fillNode.eulerAngles = vec(-0.2, 0.9, 0)
        scene.rootNode.addChildNode(fillNode)
        return scene
    }

    /// A transparent, light-weight SceneKit view showing `rig`.
    static func makeView(rig: AvatarRig, size: CGSize, fps: Int) -> SCNView {
        let view = SCNView(frame: CGRect(origin: .zero, size: size))
        configure(view, fps: fps)
        show(rig, in: view)
        return view
    }

    static func configure(_ view: SCNView, fps: Int) {
        view.backgroundColor = .clear
        view.layer?.isOpaque = false
        view.antialiasingMode = .multisampling2X
        view.preferredFramesPerSecond = fps
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = false
        view.isJitteringEnabled = false
        view.showsStatistics = false
    }

    static func show(_ rig: AvatarRig, in view: SCNView) {
        let scene = makeScene(for: rig)
        view.scene = scene
        view.pointOfView = scene.rootNode.childNode(withName: cameraName, recursively: false)
    }
}

/// Live 3D preview for the Settings pane: a slow turntable at 15 fps that only runs while it's on screen.
struct AvatarPreviewView: NSViewRepresentable {
    var look: AvatarLook
    var spinning: Bool
    var playing: Bool

    final class Coordinator {
        var look: AvatarLook?
        var spinning = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        AvatarStage.configure(view, fps: 15)
        load(into: view, coordinator: context.coordinator)
        view.isPlaying = playing
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        if context.coordinator.look != look || context.coordinator.spinning != spinning {
            load(into: view, coordinator: context.coordinator)
        }
        if view.isPlaying != playing { view.isPlaying = playing }
    }

    static func dismantleNSView(_ view: SCNView, coordinator: Coordinator) {
        view.isPlaying = false
        view.scene = nil
    }

    private func load(into view: SCNView, coordinator: Coordinator) {
        let rig = AvatarStage.makeRig(look: look)
        if rig.usesSkeleton { rig.startIdleLife() }
        rig.face(yaw: spinning ? 0.5 : 0.35, duration: 0)
        if spinning {
            rig.yawNode.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10)), forKey: "turntable")
        }
        AvatarStage.show(rig, in: view)
        coordinator.look = look
        coordinator.spinning = spinning
    }
}
