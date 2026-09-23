import AppKit
import SwiftUI

struct AboutPane: View {
    @Environment(AppModel.self) private var model

    private static let repo = URL(string: "https://github.com/ramamona/sip-and-stretch")!

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "dev"
        let build = info?["CFBundleVersion"] as? String
        return build.map { "\(short) (\($0))" } ?? short
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    DripView(mood: .excited, theme: model.settings.theme, size: 80)
                    Text("Sip & Stretch").font(.rounded(26, .heavy))
                    Text("Version \(version)").foregroundStyle(.secondary)
                    Text("Your tiny, slightly dramatic hydration & stretch buddy.")
                        .font(.rounded(13))
                        .multilineTextAlignment(.center)
                    HStack {
                        Link("GitHub", destination: Self.repo)
                        Text("·").foregroundStyle(.tertiary)
                        Link("Report a bug", destination: Self.repo.appending(path: "issues/new/choose"))
                        Text("·").foregroundStyle(.tertiary)
                        Link("MIT License", destination: Self.repo.appending(path: "blob/main/LICENSE"))
                    }
                    .font(.rounded(12))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }

            Section("Privacy") {
                Text("Everything stays on this Mac. No accounts, no network requests, no analytics. Your settings and stats live in UserDefaults (com.sipstretch.app).")
                    .font(.callout)
            }

            Section("Health note") {
                Text("Sip & Stretch is a friendly nudge, not medical advice. Stretches are gentle desk moves: go easy, and stop if anything hurts. Hydration needs vary, so pick a goal that suits you.")
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
    }
}
