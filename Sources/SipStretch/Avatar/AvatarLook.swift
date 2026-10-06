import AppKit
import SipStretchCore

extension NSColor {
    /// 0xRRGGBB in sRGB.
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// Everything the 3D rig needs to know, resolved from `AvatarSettings` and the current theme.
/// Equatable, so views can tell when the avatar actually needs to be rebuilt.
struct AvatarLook: Equatable {
    var character: AvatarCharacter
    var gender: AvatarGender
    var skin: UInt32
    var hair: UInt32
    var top: UInt32
    var bottom: UInt32
    var hairStyle: HairStyle
    var outfit: OutfitStyle
    var accessories: Set<AvatarAccessory>
    /// Drip's body colors (the theme's gradient stops).
    var themeLight: UInt32
    var themeDeep: UInt32
    /// Set when the custom person should wear the photo on their face; the number is the photo revision.
    var photoRevision: Int?
    /// The imported model replacing this character's built-in shapes ("" for none).
    var modelFileName: String
    var modelRotation: Int
    /// Who is talking: imported models have no built-in body language, so their moves follow the voice.
    var voice: Personality

    init(app: AppSettings) {
        let settings = app.avatar
        let theme = app.theme
        voice = app.effectivePersonality
        character = settings.character
        gender = settings.gender
        skin = settings.skinHex
        hair = settings.hairHex
        top = settings.topHex
        bottom = settings.bottomHex
        hairStyle = settings.hairStyle
        outfit = settings.outfit
        accessories = settings.accessories
        themeLight = theme.hexStops.0
        themeDeep = theme.hexStops.1
        photoRevision = settings.showsPhotoFace ? settings.photoRevision : nil
        modelFileName = settings.activeModel?.fileName ?? ""
        modelRotation = settings.activeModel?.rotation ?? 0
    }

    /// The same look with every field a different character wouldn't use zeroed out, so changing
    /// (say) the hair color while Kratos is selected doesn't needlessly rebuild his scene.
    var normalized: AvatarLook {
        var look = self
        if character != .drip && character != .robot {
            look.themeLight = 0
            look.themeDeep = 0
        }
        if character != .human {
            look.gender = .nonBinary
            look.skin = 0
            look.hair = 0
            look.top = 0
            look.bottom = 0
            look.hairStyle = .bald
            look.outfit = .tShirt
            look.accessories = []
            look.photoRevision = nil
        }
        if modelFileName.isEmpty {
            look.modelRotation = 0
            look.voice = .cheerful
        }
        return look
    }
}
