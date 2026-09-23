import AppKit
import SwiftUI
import SipStretchCore

struct DNDPane: View {
    @Environment(AppModel.self) private var model

    private static let automationURLs: [(String, String)] = [
        ("sipstretch://dnd/on", "Quiet until turned off"),
        ("sipstretch://dnd?minutes=60", "Quiet for 60 minutes"),
        ("sipstretch://dnd/off", "End Do Not Disturb"),
    ]

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    DripView(mood: model.isDNDActive ? .sleepy : .happy, theme: model.settings.theme, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.isDNDActive ? "Shhh… Drip is napping" : "Drip is awake")
                            .font(.rounded(17, .bold))
                        Text(statusText)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if model.isDNDActive {
                        Button("Wake Drip up") { model.setDND(.off) }
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                ForEach(DNDPreset.allCases) { preset in
                    Button {
                        model.startDND(preset)
                    } label: {
                        HStack {
                            Text(preset.displayName)
                            Spacer()
                            if case .until(let end) = preset.state(from: model.now, schedule: model.settings.schedule) {
                                Text("until \(Format.moment(end, relativeTo: model.now))").foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Go quiet for…")
            } footer: {
                Text("Reminders that come due while it's quiet aren't lost: they wait, then show up about a minute after Do Not Disturb ends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(Self.automationURLs, id: \.0) { url, description in
                    LabeledContent(description) {
                        HStack {
                            Text(url).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(url, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("Copy")
                        }
                    }
                }
            } header: {
                Text("Sync with Focus, meetings, anything")
            } footer: {
                Text("Apps can't flip macOS Focus modes, but Shortcuts can open these links. Make a Shortcuts automation for when a Focus turns on or off with an Open URLs action, or use them from Raycast, Alfred, or the terminal (`open \"sipstretch://dnd/on\"`).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var statusText: String {
        guard model.isDNDActive else { return "Reminders are on." }
        if let end = model.dnd.endDate { return "Quiet until \(Format.moment(end, relativeTo: model.now))." }
        return "Quiet until you turn it off."
    }
}
