import Foundation
import SipStretchCore
import UserNotifications

/// macOS system notifications with action buttons. Only used when the delivery style asks for it.
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    enum Action { case done, snooze, open }

    enum Status: Equatable {
        case unknown, notDetermined, allowed, denied
        /// Not running from an .app bundle (e.g. `swift run`): the notification center is off-limits.
        case unavailable
    }

    var onAction: ((ReminderKind, Action) -> Void)?

    /// `UNUserNotificationCenter.current()` crashes outside an app bundle, so guard every access.
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()
    }

    func activate() {
        guard let center else { return }
        center.delegate = self
        let snooze = UNNotificationAction(identifier: "snooze", title: "Snooze")
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: ReminderKind.water.rawValue,
                actions: [UNNotificationAction(identifier: "done", title: "💧 Drank it!"), snooze],
                intentIdentifiers: []
            ),
            UNNotificationCategory(
                identifier: ReminderKind.stretch.rawValue,
                actions: [
                    UNNotificationAction(identifier: "open", title: "🤸 Guide me", options: [.foreground]),
                    UNNotificationAction(identifier: "done", title: "Done!"),
                    snooze,
                ],
                intentIdentifiers: []
            ),
        ])
    }

    func status() async -> Status {
        guard let center else { return .unavailable }
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .allowed
        @unknown default: return .unknown
        }
    }

    func requestAuthorization() async {
        _ = try? await center?.requestAuthorization(options: [.alert, .sound])
    }

    func post(kind: ReminderKind, title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(kind.emoji) \(title)"
        content.body = body
        content.categoryIdentifier = kind.rawValue
        content.threadIdentifier = kind.rawValue
        // Sound is played by Feedback so it matches the user's pick in every delivery style.
        center.add(UNNotificationRequest(identifier: kind.rawValue, content: content, trigger: nil))
    }

    /// Clears a reminder that was already handled elsewhere (e.g. on the card).
    func removeDelivered(_ kind: ReminderKind) {
        center?.removeDeliveredNotifications(withIdentifiers: [kind.rawValue])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let kind = ReminderKind(rawValue: response.notification.request.content.categoryIdentifier) else { return }
        let action: Action? = switch response.actionIdentifier {
        case "done": .done
        case "snooze": .snooze
        case "open", UNNotificationDefaultActionIdentifier: .open
        default: nil
        }
        guard let action else { return }
        await MainActor.run { self.onAction?(kind, action) }
    }
}
