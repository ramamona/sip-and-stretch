import AppKit
import SwiftUI

@main
enum Main {
    static func main() {
        // `SipStretch --snapshots <dir>` renders README screenshots and exits (see Dev/Snapshots.swift).
        if let index = CommandLine.arguments.firstIndex(of: "--snapshots") {
            let arguments = CommandLine.arguments
            let directory = arguments.indices.contains(index + 1) ? arguments[index + 1] : "docs/screenshots"
            MainActor.assumeIsolated { Snapshots.render(to: URL(fileURLWithPath: directory)) }
            return
        }
        SipStretchApp.main()
    }
}

struct SipStretchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(model)
        } label: {
            MenuBarLabel()
                .environment(model)
        }
        .menuBarExtraStyle(.window)
    }
}
