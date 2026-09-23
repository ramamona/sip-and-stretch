import AppKit
import SwiftUI
import SipStretchCore

/// `SipStretch --snapshots <dir>` (or `make snapshots`) renders the README screenshots from real
/// views fed with demo data, so they never drift from the actual UI.
@MainActor
enum Snapshots {
    static func render(to directory: URL) {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 23, hour: 10, minute: 37)) ?? Date()
        let model = AppModel.demo(now: now)
        let pack = Personality.cheerful.pack
        func nudge(_ kind: ReminderKind, _ activity: BreakActivity, _ title: String, _ message: String) -> Nudge {
            Nudge(content: .reminder(kind, activity), title: title, message: MessagePack.render(message, name: "Sam", left: 7))
        }
        let stretches = ["owl-turns", "prayer-stretch"].compactMap { id in StretchLibrary.all.first { $0.id == id } }
        let water = nudge(.water, .drink, "Sip o'clock!", pack.waterReminders[1])
        let stretch = nudge(.stretch, .guided(stretches), "Wiggle time!", pack.stretchReminders[1])
        let roulette = nudge(.stretch, .roulette(.shoulders, stretches), "Stretch break!", pack.stretchReminders[0])
        let breathing = nudge(.stretch, .breathing(cycles: 4), "Unfold yourself!", pack.stretchReminders[2])
        let challenge = nudge(.stretch, .challenge(Challenge.all[0]), "Move it, move it!", pack.stretchReminders[3])
        let posture = nudge(.stretch, .postureCheck(Array(BreakPlanner.postureItems.prefix(4))), "Posture patrol!", pack.stretchReminders[4])
        let eyes = nudge(.eyes, .eyeRest(seconds: 20, tip: BreakPlanner.eyeTips[0]), "Eye break!", Personality.cheerful.eyeReminders[1])
        let walk = nudge(.walk, .walk(idea: BreakPlanner.walkIdeas[0]), "Walk break!", Personality.cheerful.walkReminders[1])
        let achievement = Nudge(content: .achievement(Achievement.all[3]), title: "Achievement unlocked!", message: "")

        for scheme in [ColorScheme.light, .dark] {
            let suffix = scheme == .dark ? "-dark" : ""
            let backdrop = scheme == .dark ? Color(white: 0.17) : Color(white: 0.97)

            save(
                MenuContentView(animated: false)
                    .background(backdrop)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(20)
                    .environment(model)
                    .environment(\.colorScheme, scheme),
                as: "popover\(suffix)", in: directory
            )
            let cards: [(Nudge, NudgeCardView.Phase, String)] = [
                (water, .ask, "water-card"),
                (stretch, .guide(0), "stretch-card"),
                (water, .celebrate("Hydration hero! Your cells are throwing a tiny party. 🎉", xp: 10), "celebrate-card"),
                (achievement, .ask, "achievement-card"),
                (roulette, .ask, "roulette-card"),
                (breathing, .activity, "breathing-card"),
                (challenge, .activity, "challenge-card"),
                (posture, .activity, "posture-card"),
                (eyes, .activity, "eyes-card"),
                (walk, .ask, "walk-card"),
            ]
            for (card, phase, name) in cards {
                save(self.card(card, phase: phase, model: model, scheme: scheme), as: name + suffix, in: directory)
            }
        }

        for pane in [SettingsPane.reminders, .personality, .trophies] {
            let navigation = SettingsNavigation()
            navigation.selection = pane
            saveWindow(SettingsView(navigation: navigation).environment(model), size: CGSize(width: 780, height: 580), as: "settings-\(pane.rawValue)", in: directory)
        }
        print("Snapshots written to \(directory.path)")
    }

    private static func card(_ nudge: Nudge, phase: NudgeCardView.Phase, model: AppModel, scheme: ColorScheme) -> some View {
        NudgeCardView(nudge: nudge, phase: phase) {}
            .environment(model)
            .environment(\.colorScheme, scheme)
    }

    private static func save(_ view: some View, as name: String, in directory: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else {
            print("✗ \(name): render failed")
            return
        }
        write(NSBitmapImageRep(cgImage: image), as: name, in: directory)
    }

    /// Native Form controls don't draw through ImageRenderer, so settings panes are captured
    /// from a real (offscreen) window instead.
    private static func saveWindow(_ view: some View, size: CGSize, as name: String, in directory: URL) {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hosting
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(1.0)) // let SwiftUI lay out and draw
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else { return }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        window.orderOut(nil)
        write(rep, as: name, in: directory)
    }

    private static func write(_ rep: NSBitmapImageRep, as name: String, in directory: URL) {
        guard let png = rep.representation(using: .png, properties: [:]) else { return }
        do {
            try png.write(to: directory.appending(path: "\(name).png"))
            print("✓ \(name).png")
        } catch {
            print("✗ \(name): \(error.localizedDescription)")
        }
    }
}
