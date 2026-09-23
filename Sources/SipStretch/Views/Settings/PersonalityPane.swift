import SwiftUI
import SipStretchCore

struct PersonalityPane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section("What should Drip call you?") {
                TextField("Nickname", text: $model.settings.nickname, prompt: Text("friend"))
            }

            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(Personality.allCases) { personality in
                        personalityCard(personality)
                    }
                }
                .padding(.vertical, 4)
                sampleBubble
            } header: {
                Text("Personality")
            }

            Section("Theme") {
                HStack(spacing: 14) {
                    ForEach(Theme.allCases) { theme in
                        Button {
                            model.settings.theme = theme
                        } label: {
                            VStack(spacing: 6) {
                                DripView(mood: model.settings.theme == theme ? .excited : .happy, theme: theme, size: 34, animated: model.settings.theme == theme)
                                Text(theme.displayName)
                                    .font(.rounded(11, model.settings.theme == theme ? .bold : .regular))
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(model.settings.theme == theme ? theme.deep : .clear, lineWidth: 2)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(theme.displayName) theme")
                        .accessibilityAddTraits(model.settings.theme == theme ? .isSelected : [])
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func personalityCard(_ personality: Personality) -> some View {
        let selected = model.settings.personality == personality
        let theme = model.settings.theme
        return Button {
            model.settings.personality = personality
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(personality.emoji)  \(personality.displayName)").font(.rounded(13, .bold))
                Text(personality.tagline)
                    .font(.rounded(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? theme.light.opacity(0.25) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? theme.deep : .clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var sampleBubble: some View {
        let pack = model.settings.personality.pack
        let sample = MessagePack.render(pack.waterReminders.first ?? "", name: model.settings.nickname, left: model.waterLeft)
        return HStack(alignment: .top, spacing: 10) {
            DripView(mood: .happy, theme: model.settings.theme, size: 36)
            Text(sample)
                .font(.rounded(13))
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(model.settings.theme.light.opacity(0.2)))
            Spacer(minLength: 0)
        }
    }
}
