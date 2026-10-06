import SwiftUI
import SipStretchCore

/// The little face on cards and in the popover: Drip when Drip is the avatar, otherwise a badge with the
/// character's emoji (or the user's face photo). A badge is just a circle and a glyph, so a card
/// never needs a 3D view of its own; the full 3D avatar walks around in its own window.
struct MascotView: View {
    @Environment(AppModel.self) private var model
    var mood: DripMood = .happy
    var size: CGFloat = 64
    var animated = true

    var body: some View {
        let avatar = model.settings.avatar
        if avatar.character == .drip {
            DripView(mood: mood, theme: model.settings.theme, size: size, animated: animated)
        } else {
            CharacterBadge(
                character: avatar.character,
                faceRevision: avatar.showsPhotoFace ? avatar.photoRevision : nil,
                theme: model.settings.theme,
                size: size
            )
        }
    }
}

struct CharacterBadge: View {
    var character: AvatarCharacter
    var faceRevision: Int?
    var theme: Theme
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(theme.gradient)
            if let faceRevision, let image = AvatarStorage.facePhoto(revision: faceRevision) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .padding(size * 0.05)
            } else {
                Text(character.emoji).font(.system(size: size * 0.5))
            }
            Circle().strokeBorder(.white.opacity(0.55), lineWidth: max(1.5, size * 0.03))
        }
        .shadow(color: theme.deep.opacity(0.3), radius: size * 0.06, y: size * 0.03)
        .frame(width: size * 0.96, height: size * 0.96)
        // Same footprint as DripView, so cards don't shift when the avatar changes.
        .frame(width: size, height: size * 1.18)
        .accessibilityElement()
        .accessibilityLabel(character.displayName)
    }
}
