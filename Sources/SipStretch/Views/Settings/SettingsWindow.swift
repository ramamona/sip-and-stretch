import AppKit
import Observation
import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, reminders, schedule, doNotDisturb, personality, trophies, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .reminders: "Reminders"
        case .schedule: "Active Hours"
        case .doNotDisturb: "Do Not Disturb"
        case .personality: "Personality & Look"
        case .trophies: "Trophies & Stats"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .reminders: "bell.badge.fill"
        case .schedule: "clock.fill"
        case .doNotDisturb: "moon.zzz.fill"
        case .personality: "theatermasks.fill"
        case .trophies: "trophy.fill"
        case .about: "info.circle.fill"
        }
    }
}

@MainActor
@Observable
final class SettingsNavigation {
    var selection: SettingsPane? = .general
}

/// Owns the Settings window. A plain AppKit window (rather than a SwiftUI `Settings` scene)
/// so a menu-bar-only app can reliably bring it to the front.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    let navigation = SettingsNavigation()
    private var window: NSWindow?

    func show(_ pane: SettingsPane? = nil) {
        if let pane { navigation.selection = pane }
        let window = window ?? makeWindow()
        self.window = window
        // Show a Dock icon while Settings is open so it's reachable with ⌘-Tab.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let root = SettingsView(navigation: navigation).environment(AppModel.shared)
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = []
        let window = NSWindow(contentViewController: hosting)
        window.title = "Sip & Stretch"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.setContentSize(NSSize(width: 780, height: 580))
        window.contentMinSize = NSSize(width: 700, height: 480)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        window = nil // free the whole view tree; it's rebuilt in a blink next time
    }
}

struct SettingsView: View {
    @Bindable var navigation: SettingsNavigation

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $navigation.selection) { pane in
                Label(pane.title, systemImage: pane.symbol).tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch navigation.selection ?? .general {
                case .general: GeneralPane()
                case .reminders: RemindersPane()
                case .schedule: SchedulePane()
                case .doNotDisturb: DNDPane()
                case .personality: PersonalityPane()
                case .trophies: TrophiesPane()
                case .about: AboutPane()
                }
            }
            .navigationTitle((navigation.selection ?? .general).title)
        }
    }
}
