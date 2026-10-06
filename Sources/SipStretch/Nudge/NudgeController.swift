import AppKit
import SwiftUI
import SipStretchCore

/// Shows nudge cards one at a time in a floating panel that never takes keyboard focus.
@MainActor
final class NudgeController {
    weak var model: AppModel?

    /// The 3D avatar that walks in ahead of reminder cards (see `AvatarWalker`).
    let walker = AvatarWalker()

    private var panel: NudgePanel?
    private var queue: [Nudge] = []
    private(set) var current: Nudge?
    private var closingID: UUID?
    /// Set while the avatar is still walking toward its spot; the card for this nudge isn't on screen yet.
    private var walkingID: UUID?
    /// How the current card slid in, so it can slide back out the same way.
    private var slide = CGSize.zero
    /// Lets the controller talk to the card on screen (a character's impatient lines, giving up).
    private var signals = CardSignals()
    /// Counts down while a walking character waits for an answer.
    private var patienceTask: Task<Void, Never>?

    func present(_ nudge: Nudge) {
        // One card per reminder kind: a second water reminder while one is waiting adds nothing.
        // Previews are counted separately so a forgotten preview can't swallow a real reminder.
        let pending = [current].compactMap { $0 } + queue
        if let kind = nudge.content.reminderKind,
           pending.contains(where: { $0.content.reminderKind == kind && $0.isPreview == nudge.isPreview }) {
            return
        }
        queue.append(nudge)
        showNextIfIdle()
    }

    /// Removes a reminder card that was handled somewhere else (e.g. from a notification).
    func dismiss(_ kind: ReminderKind) {
        queue.removeAll { $0.content.reminderKind == kind }
        if let current, current.content.reminderKind == kind { close(current) }
    }

    /// The user reacted to the card (started a stretch, snoozed…), so the character stops getting restless.
    func engaged() {
        patienceTask?.cancel()
        patienceTask = nil
    }

    func close(_ nudge: Nudge) {
        guard current?.id == nudge.id, closingID != nudge.id else { return }
        engaged()
        if walkingID == nudge.id {
            // Dismissed or stashed while the avatar was still walking in: no card is up yet, so stop the walk.
            walkingID = nil
            walker.tearDown()
            current = nil
            showNextIfIdle()
            return
        }
        guard let panel else { return }
        closingID = nudge.id // cards can close themselves and be clicked at the same moment
        let slide = self.slide
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = reduceMotion ? 0.15 : 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrame(panel.frame.offsetBy(dx: slide.width, dy: slide.height), display: true)
        }, completionHandler: {
            MainActor.assumeIsolated {
                panel.orderOut(nil)
                panel.contentView = nil
                self.current = nil
                self.closingID = nil
                self.showNextIfIdle()
            }
        })
    }

    /// Puts a showing reminder card back in the queue (hidden) while it's quiet, e.g. so it isn't
    /// on screen during a screen share. It reappears, fresh, when the quiet ends.
    func stashReminders() {
        guard let current, current.content.reminderKind != nil, !current.isPreview else { return }
        queue.insert(current, at: 0)
        close(current)
    }

    /// Shows the next queued card. Reminder cards wait in the queue while it's quiet (Do Not Disturb
    /// or a call); celebrations and previews (things the user just did) still show.
    ///
    /// With the walking avatar on, a reminder first sends the avatar across the screen and the card
    /// appears above it once it arrives. When nothing is left to show, the avatar walks off.
    func showNextIfIdle() {
        guard current == nil, let model else { return }
        let held = { (nudge: Nudge) in model.isQuiet && nudge.content.reminderKind != nil && !nudge.isPreview }
        guard let index = queue.firstIndex(where: { !held($0) }) else {
            walker.leave()
            return
        }
        let nudge = queue.remove(at: index)
        current = nudge

        // The avatar only ever walks on the main display (the one with the menu bar).
        guard usesWalker(nudge), let screen = NSScreen.screens.first else {
            walker.leave()
            display(nudge, standing: nil, on: nil)
            return
        }
        walkingID = nudge.id
        walker.walkIn(settings: model.settings.avatar, theme: model.settings.theme, screen: screen) { [weak self] stand in
            guard let self, self.walkingID == nudge.id, self.current?.id == nudge.id else { return }
            self.walkingID = nil
            self.display(nudge, standing: stand, on: screen)
        }
    }

    /// While a character waits for an answer it gets more and more restless, and finally storms off.
    /// Previews run 30 times faster so you can see it without waiting ten minutes.
    private func startWaiting(for nudge: Nudge) {
        patienceTask?.cancel()
        patienceTask = nil
        guard let model, nudge.content.reminderKind != nil else { return }
        let timeline = model.settings.avatar.patienceTimeline(speedUp: nudge.isPreview ? 30 : 1)
        guard !timeline.grumbles.isEmpty || timeline.timeout != nil else { return }
        let signals = self.signals
        patienceTask = Task { [weak self] in
            var elapsed: TimeInterval = 0
            for (index, time) in timeline.grumbles.enumerated() {
                try? await Task.sleep(for: .seconds(max(0, time - elapsed)))
                guard !Task.isCancelled, let self, self.current?.id == nudge.id else { return }
                elapsed = time
                signals.line = self.model?.reactionLine(.impatient)
                self.walker.grumble(level: index + 1)
            }
            guard let timeout = timeline.timeout else { return }
            try? await Task.sleep(for: .seconds(max(0, timeout - elapsed)))
            guard !Task.isCancelled, let self, self.current?.id == nudge.id else { return }
            signals.timedOut = true
        }
    }

    private func usesWalker(_ nudge: Nudge) -> Bool {
        guard let model, nudge.content.reminderKind != nil else { return false }
        let settings = model.settings
        // Notification-only delivery has no card for the avatar to stand under (previews always do).
        return settings.avatar.walkOnScreen && (nudge.isPreview || settings.delivery != .notification)
    }

    /// Puts the card in the panel and slides it in: at the chosen corner, or above the avatar when it's standing.
    private func display(_ nudge: Nudge, standing stand: WalkerStand?, on screen: NSScreen?) {
        guard let model else { return }
        let swipe = CardSwipe()
        signals = CardSignals()
        let card = NudgeCardView(nudge: nudge, swipe: swipe, signals: signals) { [weak self] in self?.close(nudge) }
            .environment(model)
        let hosting = ClickThroughHostingView(rootView: card)
        hosting.swipe = swipe
        let size = NudgeCardView.panelSize
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = self.panel ?? NudgePanel(size: size)
        self.panel = panel
        panel.contentView = hosting

        let target: NSRect
        if let stand, let screen {
            target = anchoredFrame(size: size, stand: stand, visible: screen.visibleFrame)
            slide = reduceMotion ? .zero : CGSize(width: 0, height: -30)
        } else {
            target = targetFrame(size: size, position: model.settings.cardPosition)
            slide = slideOffset
        }
        let offset = slide
        panel.setFrame(target.offsetBy(dx: offset.width, dy: offset.height), display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless() // visible without activating the app or taking focus

        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0.2 : 0.45
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.3, 0.4, 1) // a little overshoot
            panel.animator().alphaValue = 1
            panel.animator().setFrame(target, display: true)
        }

        if stand != nil { startWaiting(for: nudge) }

        // The panel never takes focus, so tell VoiceOver users what just appeared.
        if !model.settings.speakReminders, !nudge.message.isEmpty {
            NSAccessibility.post(
                element: NSApp as Any,
                notification: .announcementRequested,
                userInfo: [.announcement: "\(nudge.title) \(nudge.message)", .priority: NSAccessibilityPriorityLevel.high.rawValue]
            )
        }
    }

    private var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    /// Where cards slide in from / out to, based on the chosen corner (a plain fade with Reduce Motion).
    private var slideOffset: CGSize {
        if reduceMotion { return .zero }
        return switch model?.settings.cardPosition ?? .topRight {
        case .topRight, .bottomRight: CGSize(width: 40, height: 0)
        case .topLeft, .bottomLeft: CGSize(width: -40, height: 0)
        case .center: CGSize(width: 0, height: -30)
        }
    }

    /// The screen the mouse is on, where the user is probably working.
    private func activeScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func targetFrame(size: CGSize, position: CardPosition) -> NSRect {
        let visible = activeScreen()?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let inset: CGFloat = 4 // the panel already has shadow padding built in
        let origin: CGPoint = switch position {
        case .topRight: CGPoint(x: visible.maxX - size.width - inset, y: visible.maxY - size.height - inset)
        case .topLeft: CGPoint(x: visible.minX + inset, y: visible.maxY - size.height - inset)
        case .bottomRight: CGPoint(x: visible.maxX - size.width - inset, y: visible.minY + inset)
        case .bottomLeft: CGPoint(x: visible.minX + inset, y: visible.minY + inset)
        case .center: CGPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2 + visible.height * 0.12)
        }
        return NSRect(origin: origin, size: size)
    }

    /// A card just above the standing avatar's head, kept on screen.
    private func anchoredFrame(size: CGSize, stand: WalkerStand, visible: NSRect) -> NSRect {
        let inset: CGFloat = 4
        let x = min(max(stand.frame.midX - size.width / 2, visible.minX + inset), visible.maxX - size.width - inset)
        // The panel carries shadow padding, so overlap it a little to sit just above the head.
        let y = min(stand.headTop - NudgeCardView.shadowPadding + 6, visible.maxY - size.height - inset)
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}

/// Borderless, transparent, floats above other apps (including full-screen ones) and draggable.
/// It never becomes the key window, so typing always stays in the app you're using.
final class NudgePanel: NSPanel {
    init(size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false // the SwiftUI card draws its own
        isMovableByWindowBackground = false // dragging a card swipes it away instead
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Buttons respond to the very first click, even while another app is active.
/// Also turns a horizontal two-finger trackpad swipe into `CardSwipe` updates, like a notification banner.
final class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    var swipe: CardSwipe?
    private var swiping = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func scrollWheel(with event: NSEvent) {
        guard let swipe, event.hasPreciseScrollingDeltas, event.momentumPhase.isEmpty else {
            return super.scrollWheel(with: event)
        }
        if event.phase == .began { swiping = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) }
        guard swiping else { return super.scrollWheel(with: event) }
        // Follow the fingers whatever the "natural scrolling" setting is.
        let fingersX = event.isDirectionInvertedFromDevice ? event.scrollingDeltaX : -event.scrollingDeltaX
        switch event.phase {
        case .began, .changed:
            swipe.offset += fingersX
        case .ended, .cancelled:
            swiping = false
            swipe.releases += 1
        default:
            break
        }
    }
}

/// Live trackpad-swipe state shared between the panel (AppKit) and the card (SwiftUI).
/// Only ever touched on the main thread (event handling and view updates).
@Observable
final class CardSwipe {
    var offset: CGFloat = 0
    /// Bumped when the fingers lift, so the card can decide: dismiss or snap back.
    var releases = 0
}

/// What the controller wants to tell the card on screen. Only touched on the main thread.
@Observable
final class CardSignals {
    /// A line from the (restless) character that replaces the card's message.
    var line: String?
    /// The character ran out of patience.
    var timedOut = false
}
