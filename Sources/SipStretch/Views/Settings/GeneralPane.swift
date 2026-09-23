import AppKit
import SwiftUI
import SipStretchCore

struct GeneralPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section("Startup") {
                Toggle("Launch Sip & Stretch at login", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if let error = model.launchAtLoginError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            Section {
                Picker("Remind me with", selection: $model.settings.delivery) {
                    ForEach(DeliveryStyle.allCases) { Text($0.displayName).tag($0) }
                }
                if model.settings.delivery != .card {
                    notificationStatusRow
                }
                Picker("Cards appear", selection: $model.settings.cardPosition) {
                    ForEach(CardPosition.allCases) { Text($0.displayName).tag($0) }
                }
                // Notification-only delivery still falls back to cards when notifications are blocked.
                .disabled(model.settings.delivery == .notification && model.notificationsAllowed)
                Toggle("Read reminders out loud", isOn: $model.settings.speakReminders)
            } header: {
                Text("Delivery")
            } footer: {
                Text("Nudge cards are Drip's animated pop-ups with guided stretches. They never steal your keyboard focus.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu bar") {
                Picker("Show next to the droplet", selection: $model.settings.menuBarDisplay) {
                    ForEach(MenuBarDisplay.allCases) { Text($0.displayName).tag($0) }
                }
            }

            Section("Try it out") {
                HStack {
                    ForEach(ReminderKind.allCases) { kind in
                        Button("\(kind.emoji) \(kind.title)") { model.preview(kind) }
                    }
                }
                Text("Stretch previews pick a random format (guided, roulette, breathing, challenge, posture), so try it a few times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task { await model.refreshNotificationStatus() }
    }

    @ViewBuilder
    private var notificationStatusRow: some View {
        switch model.notificationStatus {
        case .allowed:
            LabeledContent("Notifications") { Label("Allowed", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
        case .denied:
            LabeledContent("Notifications") {
                HStack {
                    Text("Blocked, so Drip uses cards instead").foregroundStyle(.secondary)
                    Button("Open System Settings…") {
                        let id = Bundle.main.bundleIdentifier ?? ""
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(id)") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        case .notDetermined, .unknown:
            LabeledContent("Notifications") {
                Button("Allow notifications…") { Task { await model.requestNotifications() } }
            }
        case .unavailable:
            LabeledContent("Notifications") {
                Text("Run the bundled app (make run) to use notifications").foregroundStyle(.secondary)
            }
        }
    }
}
