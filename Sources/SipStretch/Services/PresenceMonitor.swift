import AppKit
import CoreGraphics

/// Knows whether anyone is actually at the Mac: screen locked, display or system asleep,
/// switched-out user session, or simply no keyboard/mouse input for a while.
@MainActor
final class PresenceMonitor {
    /// Called whenever lock/sleep state flips, so reminders can react right away.
    var onChange: (() -> Void)?

    /// Why the Mac is currently unattended (empty = someone's there, as far as system events go).
    private var reasons: Set<String> = []
    /// When the Mac became unattended.
    private(set) var inactiveSince: Date?
    private var tokens: [NSObjectProtocol] = []

    var isInactive: Bool { !reasons.isEmpty }

    /// Seconds since the last keyboard/mouse/trackpad event. No permissions required.
    var idleSeconds: TimeInterval {
        let anyInput = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }

    func start() {
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification, reason: "sleep", active: true)
        observe(workspace, NSWorkspace.didWakeNotification, reason: "sleep", active: false)
        observe(workspace, NSWorkspace.screensDidSleepNotification, reason: "display", active: true)
        observe(workspace, NSWorkspace.screensDidWakeNotification, reason: "display", active: false)
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification, reason: "session", active: true)
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification, reason: "session", active: false)

        let distributed = DistributedNotificationCenter.default()
        observe(distributed, Notification.Name("com.apple.screenIsLocked"), reason: "lock", active: true)
        observe(distributed, Notification.Name("com.apple.screenIsUnlocked"), reason: "lock", active: false)
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name, reason: String, active: Bool) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.set(reason, active: active) }
        }
        tokens.append(token)
    }

    private func set(_ reason: String, active: Bool) {
        let wasInactive = isInactive
        if active { reasons.insert(reason) } else { reasons.remove(reason) }
        if !wasInactive && isInactive { inactiveSince = Date() }
        if !isInactive { inactiveSince = nil }
        if wasInactive != isInactive { onChange?() }
    }
}
