import AppKit
import SwiftUI
import SipStretchCore

/// Shows nudge cards one at a time in a floating panel that never takes keyboard focus.
@MainActor
final class NudgeController {
    weak var model: AppModel?

    private var panel: NudgePanel?
    private var queue: [Nudge] = []
    private(set) var current: Nudge?
    private var closingID: UUID?

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

    func close(_ nudge: Nudge) {
        guard current?.id == nudge.id, closingID != nudge.id, let panel else { return }
        closingID = nudge.id // cards can close themselves and be clicked at the same moment
        let slide = slideOffset
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
    func showNextIfIdle() {
        guard current == nil, let model else { return }
        let held = { (nudge: Nudge) in model.isQuiet && nudge.content.reminderKind != nil && !nudge.isPreview }
        guard let index = queue.firstIndex(where: { !held($0) }) else { return }
        let nudge = queue.remove(at: index)
        current = nudge

        let card = NudgeCardView(nudge: nudge) { [weak self] in self?.close(nudge) }
            .environment(model)
        let hosting = ClickThroughHostingView(rootView: card)
        let size = NudgeCardView.panelSize
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = self.panel ?? NudgePanel(size: size)
        self.panel = panel
        panel.contentView = hosting

        let target = targetFrame(size: size, position: model.settings.cardPosition)
        let slide = slideOffset
        panel.setFrame(target.offsetBy(dx: slide.width, dy: slide.height), display: false)
        panel.alphaValue = 0
        panel.orderFrontRegardless() // visible without activating the app or taking focus

        NSAnimationContext.runAnimationGroup { context in
            context.duration = reduceMotion ? 0.2 : 0.45
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.3, 0.4, 1) // a little overshoot
            panel.animator().alphaValue = 1
            panel.animator().setFrame(target, display: true)
        }

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

    private func targetFrame(size: CGSize, position: CardPosition) -> NSRect {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
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
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Buttons respond to the very first click, even while another app is active.
final class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
