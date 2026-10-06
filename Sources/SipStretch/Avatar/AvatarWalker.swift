import AppKit
import SceneKit
import SipStretchCore

/// Where the avatar stopped, so the card can line up above it.
struct WalkerStand {
    /// The avatar's (click-through) window, in screen coordinates.
    var frame: NSRect
    /// Screen y of the top of the avatar's head (or hat, feathers, staff…).
    var headTop: CGFloat
}

/// Walks the avatar across the bottom of the screen to where the reminder card will appear, waves,
/// stands there while the card is up, cheers when you finish, and walks off again.
///
/// Built to cost almost nothing:
/// - Nothing exists until a reminder is due; the window, scene and Metal resources are all released
///   once the avatar has left.
/// - The avatar lives in a small transparent window that slides across the screen on a timer capped at
///   the chosen frame rate, instead of a screen-wide overlay.
/// - While the avatar just stands there, SceneKit is paused (a still image, 0% CPU) until the next
///   gesture.
/// - The window ignores the mouse, so it can never get in the way of your work.
@MainActor
final class AvatarWalker {
    private enum Phase { case idle, walkingIn, standing, leaving }

    private static let baseWindowSide: CGFloat = 200
    private static let walkYaw: CGFloat = 0.95

    private var phase = Phase.idle
    private var panel: NudgePanel?
    private var view: SCNView?
    private var rig: AvatarRig?
    private var screen: NSScreen?
    private var settings = AvatarSettings()
    private var pointsPerMeter: CGFloat = 80
    private var moveTimer: Timer?
    private var pauseTask: Task<Void, Never>?
    private var stretching = false
    /// Bumped whenever a walk starts or ends so callbacks from an older walk can't act on a newer one.
    private var generation = 0

    var isStanding: Bool { phase == .standing }

    // MARK: Walking in

    /// Starts the avatar walking toward `standCenterX` (screen x of the spot it should stop at).
    /// `arrived` is called once it stands there, or right away if it's already standing from an earlier nudge.
    func walkIn(settings: AvatarSettings, theme: Theme, screen: NSScreen, standCenterX: CGFloat, arrived: @escaping (WalkerStand) -> Void) {
        if phase == .standing, let standingPanel = panel {
            unpause()
            stretching = false
            self.rig?.stopActivities(settle: true)
            if !reduceMotion { self.rig?.wave() }
            scheduleIdlePause(after: 3.2)
            arrived(stand(for: standingPanel.frame))
            return
        }
        tearDown()
        generation += 1
        let token = generation
        self.settings = settings
        self.screen = screen

        let look = AvatarLook(settings: settings, theme: theme)
        let newRig = AvatarStage.makeRig(look: look)
        let side = (Self.baseWindowSide * CGFloat(settings.size.scale)).rounded()
        pointsPerMeter = side / AvatarStage.visibleHeight

        let visible = screen.visibleFrame
        let y = visible.minY - AvatarStage.groundInset * pointsPerMeter
        let standX = min(max(standCenterX - side / 2, visible.minX - side / 4), visible.maxX - side * 3 / 4)
        let fromLeft: Bool = switch settings.entry {
        case .left: true
        case .right: false
        case .auto: standCenterX >= screen.frame.midX
        }
        let startX = fromLeft ? screen.frame.minX - side : screen.frame.maxX

        let newView = AvatarStage.makeView(rig: newRig, size: CGSize(width: side, height: side), fps: settings.quality.framesPerSecond)
        let newPanel = NudgePanel(size: CGSize(width: side, height: side))
        newPanel.ignoresMouseEvents = true
        newPanel.contentView = newView
        self.rig = newRig
        self.view = newView
        self.panel = newPanel
        newView.isPlaying = true

        if reduceMotion {
            newPanel.setFrameOrigin(NSPoint(x: standX, y: y))
            newPanel.alphaValue = 0
            newPanel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                newPanel.animator().alphaValue = 1
            }
            phase = .walkingIn
            arrive(token: token, arrived: arrived)
            return
        }

        newRig.face(yaw: fromLeft ? Self.walkYaw : -Self.walkYaw, duration: 0)
        newRig.startWalking(cycle: cycleTime)
        newPanel.setFrameOrigin(NSPoint(x: startX, y: y))
        newPanel.orderFrontRegardless()
        phase = .walkingIn
        move(from: startX, to: standX, y: y) { [weak self] in
            self?.arrive(token: token, arrived: arrived)
        }
    }

    private func arrive(token: Int, arrived: (WalkerStand) -> Void) {
        guard token == generation, phase == .walkingIn, let panel, let rig else { return }
        phase = .standing
        rig.stopActivities()
        rig.face(yaw: 0, duration: reduceMotion ? 0 : 0.35)
        if !reduceMotion { rig.wave() }
        scheduleIdlePause(after: reduceMotion ? 0.5 : 3.2)
        arrived(stand(for: panel.frame))
    }

    // MARK: Reacting

    /// The user finished the break: arms up and a hop or two.
    func cheer() {
        guard phase == .standing, let rig, !reduceMotion else { return }
        stretching = false
        unpause()
        rig.cheer()
        scheduleIdlePause(after: 2.2)
    }

    /// Stretch along with the user while a guided stretch is on screen.
    func setStretching(_ on: Bool) {
        guard phase == .standing, let rig, !reduceMotion, on != stretching else { return }
        stretching = on
        unpause()
        if on {
            rig.startStretching()
        } else {
            rig.stopActivities()
            scheduleIdlePause(after: 1.0)
        }
    }

    // MARK: Leaving

    /// Walks off toward the nearest edge, then frees everything.
    func leave() {
        guard phase == .standing, let panel, let rig else { return }
        phase = .leaving
        generation += 1
        let token = generation
        unpause()
        let frame = panel.frame
        let screenFrame = screen?.frame ?? frame
        if reduceMotion {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                panel.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, token == self.generation else { return }
                    self.tearDown()
                }
            })
            return
        }
        let toLeft = frame.midX < screenFrame.midX
        rig.stopActivities()
        rig.face(yaw: toLeft ? -Self.walkYaw : Self.walkYaw, duration: 0.2)
        rig.startWalking(cycle: cycleTime)
        let target = toLeft ? screenFrame.minX - frame.width : screenFrame.maxX
        move(from: frame.minX, to: target, y: frame.minY) { [weak self] in
            guard let self, token == self.generation else { return }
            self.tearDown()
        }
    }

    /// Removes the avatar immediately and releases its window and scene.
    func tearDown() {
        generation += 1
        moveTimer?.invalidate()
        moveTimer = nil
        pauseTask?.cancel()
        pauseTask = nil
        view?.isPlaying = false
        view?.scene = nil
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        view = nil
        rig = nil
        stretching = false
        phase = .idle
    }

    // MARK: Internals

    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    /// Seconds for two steps: quicker steps at higher speeds so feet don't skate.
    private var cycleTime: TimeInterval {
        let ratio = 200 / settings.speed.pointsPerSecond
        return min(0.8, max(0.35, 0.55 * ratio))
    }

    private func stand(for frame: NSRect) -> WalkerStand {
        let top = frame.minY + (AvatarStage.groundInset + (rig?.height ?? 1.6)) * pointsPerMeter
        return WalkerStand(frame: frame, headTop: top)
    }

    /// Slides the window horizontally at a constant speed. Ticks at the chosen frame rate and uses
    /// timer tolerance so macOS can coalesce wake-ups.
    private func move(from startX: CGFloat, to endX: CGFloat, y: CGFloat, completion: @escaping () -> Void) {
        moveTimer?.invalidate()
        let distance = abs(endX - startX)
        let duration = max(0.4, TimeInterval(distance) / settings.speed.pointsPerSecond)
        let interval = 1.0 / Double(settings.quality.framesPerSecond)
        let began = CACurrentMediaTime()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, let panel = self.panel else {
                    timer.invalidate()
                    return
                }
                let progress = min(1, (CACurrentMediaTime() - began) / duration)
                let x = startX + (endX - startX) * CGFloat(progress)
                panel.setFrameOrigin(NSPoint(x: x, y: y))
                if progress >= 1 {
                    timer.invalidate()
                    self.moveTimer = nil
                    completion()
                }
            }
        }
        timer.tolerance = interval / 4
        RunLoop.main.add(timer, forMode: .common)
        moveTimer = timer
    }

    private func unpause() {
        pauseTask?.cancel()
        pauseTask = nil
        view?.isPlaying = true
    }

    /// Once the gesture has finished, stop rendering altogether. The last frame stays on screen.
    private func scheduleIdlePause(after seconds: Double) {
        pauseTask?.cancel()
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.view?.isPlaying = false
        }
    }
}
