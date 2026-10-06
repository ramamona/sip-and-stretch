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

/// How the avatar feels when it leaves: happy if you did the thing, grumpy if you didn't.
enum WalkerOutcome { case pleased, displeased }

/// Walks the avatar in from the bottom-right corner of the main screen, performs its signature move,
/// stands there while the card is up (sulking or growing impatient if you ignore it), cheers when you
/// finish, and walks back off the right edge, happily or angrily.
///
/// Built to cost almost nothing:
/// - Nothing exists until a reminder is due; the window, scene and Metal resources are all released
///   once the avatar has left.
/// - The avatar lives in a small transparent window that slides across a short stretch of the screen
///   on a timer capped at the chosen frame rate, instead of a screen-wide overlay.
/// - While the avatar just stands there, SceneKit is paused (a still image, 0% CPU); it wakes only for
///   a gesture and then sleeps again.
/// - The window ignores the mouse, so it can never get in the way of your work.
@MainActor
final class AvatarWalker {
    private enum Phase { case idle, walkingIn, standing, leaving }

    private static let baseWindowSide: CGFloat = 240
    private static let walkYaw: CGFloat = 0.95
    /// Frame rate for the quiet alive-and-breathing idle animation: slow enough to be nearly free.
    private static let idleFramesPerSecond = 12

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
    private var outcome = WalkerOutcome.pleased
    /// Bumped whenever a walk starts or ends so callbacks from an older walk can't act on a newer one.
    private var generation = 0

    var isStanding: Bool { phase == .standing }

    // MARK: Walking in

    /// Walks in from the right edge of `screen` (the main display) to its bottom-right corner, then does its
    /// signature move. `arrived` is called once it stands there, or right away if it's already standing.
    func walkIn(app: AppSettings, screen: NSScreen, arrived: @escaping (WalkerStand) -> Void) {
        if phase == .standing, let standingPanel = panel {
            outcome = .pleased
            stretching = false
            perform(.signature)
            arrived(stand(for: standingPanel.frame))
            return
        }
        tearDown()
        generation += 1
        let token = generation
        let settings = app.avatar
        self.settings = settings
        self.screen = screen
        outcome = .pleased

        let look = AvatarLook(app: app)
        let newRig = AvatarStage.makeRig(look: look)
        let side = (Self.baseWindowSide * CGFloat(settings.size.scale)).rounded()
        pointsPerMeter = side / AvatarStage.visibleHeight

        let visible = screen.visibleFrame
        let y = visible.minY - AvatarStage.groundInset * pointsPerMeter
        let standX = visible.maxX - side - 6
        let startX = screen.frame.maxX

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

        newRig.face(yaw: -Self.walkYaw, duration: 0) // walking left, into the screen
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
        rig.stopActivities(settle: true)
        rig.face(yaw: 0, duration: reduceMotion ? 0 : 0.3)
        if reduceMotion {
            scheduleIdlePause(after: 0.5)
        } else {
            perform(.signature)
        }
        arrived(stand(for: panel.frame))
    }

    /// Plays a move and goes back to sleep once it's over.
    private func perform(_ move: AvatarMove) {
        guard let rig, !reduceMotion else { return }
        unpause()
        let duration = rig.perform(move)
        scheduleIdlePause(after: duration + 0.4)
    }

    // MARK: Reacting

    /// You did it: celebrate in character, and leave happy.
    func celebrate() {
        guard phase == .standing else { return }
        outcome = .pleased
        stretching = false
        rig?.setTint(nil)
        perform(.pleased)
    }

    /// You skipped it: sulk, stomp, turn away, and leave angry.
    func sulk() {
        guard phase == .standing else { return }
        outcome = .displeased
        stretching = false
        perform(.angry)
    }

    /// You pushed it back: a grumble, and it leaves a little put out.
    func snoozed() {
        guard phase == .standing else { return }
        outcome = .displeased
        stretching = false
        perform(.grumble(2))
    }

    /// Still waiting for you. `level` 1…3 gets steadily more annoyed.
    func grumble(level: Int) {
        guard phase == .standing, !stretching else { return }
        perform(.grumble(level))
        if level >= 3 { outcome = .displeased }
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

    /// Walks off to the right, happily or angrily depending on how things went, then frees everything.
    func leave() {
        guard phase == .standing, let panel, let rig else { return }
        phase = .leaving
        generation += 1
        let token = generation
        unpause()
        let frame = panel.frame
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
        let angry = outcome == .displeased
        if angry { rig.setTint(NSColor(hex: 0xFF3B30), amount: 0.45) }
        rig.stopActivities(settle: true)
        rig.face(yaw: Self.walkYaw, duration: 0.2) // walking right, out of the screen
        rig.startWalking(cycle: angry ? cycleTime * 0.85 : cycleTime, mood: angry ? .angry : .happy)
        let target = (screen?.frame.maxX ?? frame.maxX) + 10
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
        let ratio = 110 / settings.speed.pointsPerSecond
        return min(0.8, max(0.35, 0.6 * ratio))
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
        view?.preferredFramesPerSecond = settings.quality.framesPerSecond
        view?.isPlaying = true
    }

    /// Once a gesture has finished, calm down: breathe and look around at a low frame rate, or (if the
    /// user prefers) stop rendering altogether so it costs nothing. The last frame stays on screen.
    private func scheduleIdlePause(after seconds: Double) {
        pauseTask?.cancel()
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.settle()
        }
    }

    private func settle() {
        guard let view else { return }
        if settings.idle == .lively, !reduceMotion, let rig {
            rig.startIdleLife()
            view.preferredFramesPerSecond = Self.idleFramesPerSecond
            view.isPlaying = true
        } else {
            view.isPlaying = false
        }
    }
}
