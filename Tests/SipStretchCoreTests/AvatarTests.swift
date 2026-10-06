import Foundation
import Testing
@testable import SipStretchCore

@Suite struct AvatarTests {
    @Test func defaultsKeepDripAndTheChosenPersonality() {
        var settings = AppSettings()
        #expect(settings.avatar.character == .drip)
        #expect(settings.avatar.walkOnScreen)
        #expect(settings.effectivePersonality == settings.personality)
        settings.personality = .pirate
        #expect(settings.effectivePersonality == .pirate, "Drip has no voice of its own")
    }

    @Test func charactersWithASignatureVoiceOverridePersonality() {
        var settings = AppSettings()
        settings.personality = .pirate
        let voices: [AvatarCharacter: Personality] = [
            .kratos: .kratos, .kungFuPanda: .kungFuPanda, .wukong: .wukong, .robot: .robot,
        ]
        for (character, voice) in voices {
            settings.avatar.character = character
            #expect(settings.effectivePersonality == voice)
        }
        settings.avatar.matchVoiceToCharacter = false
        settings.avatar.character = .kratos
        #expect(settings.effectivePersonality == .pirate, "the user can keep their own personality")

        for character in [AvatarCharacter.drip, .human, .model] {
            settings.avatar.matchVoiceToCharacter = true
            settings.avatar.character = character
            #expect(settings.effectivePersonality == .pirate)
        }
    }

    @Test func characterVoicesAreDistinctFromEachOther() {
        let openers = [Personality.kratos, .kungFuPanda, .wukong].map { Set($0.pack.waterReminders) }
        #expect(openers[0].isDisjoint(with: openers[1]))
        #expect(openers[1].isDisjoint(with: openers[2]))
        #expect(openers[0].isDisjoint(with: openers[2]))
        #expect(Personality.kratos.speechPitch < Personality.wukong.speechPitch)
    }

    @Test func avatarChoicesSurviveARoundTrip() throws {
        var settings = AppSettings()
        settings.avatar.character = .human
        settings.avatar.gender = .female
        settings.avatar.hairStyle = .ponytail
        settings.avatar.hairHex = 0xE05CA3
        settings.avatar.accessories = [.glasses, .cap]
        settings.avatar.hasPhoto = true
        settings.avatar.photoRevision = 4
        settings.avatar.speed = .fast
        settings.avatar.size = .large
        settings.avatar.quality = .batterySaver
        settings.avatar.modelFileName = "model.usdz"
        settings.avatar.modelDisplayName = "Hero"
        settings.avatar.modelRotation = 180
        let data = try JSONEncoder().encode(settings)
        #expect(AppSettings.decode(from: data) == settings)
    }

    @Test func settingsFromBeforeTheAvatarExistedGetAvatarDefaults() {
        let json = #"{"personality":"zen","theme":"mint"}"#
        let settings = AppSettings.decode(from: Data(json.utf8))
        #expect(settings.personality == .zen)
        #expect(settings.theme == .mint)
        #expect(settings.avatar == AvatarSettings())
    }

    @Test func partialAvatarJSONKeepsChoicesAndFillsTheRest() {
        let json = #"{"avatar":{"character":"kratos","speed":"slow","accessories":["cap"],"somethingNew":1}}"#
        let settings = AppSettings.decode(from: Data(json.utf8))
        #expect(settings.avatar.character == .kratos)
        #expect(settings.avatar.speed == .slow)
        #expect(settings.avatar.accessories == [.cap])
        #expect(settings.avatar.size == .medium)
        #expect(settings.avatar.walkOnScreen)
    }

    @Test func photoFaceOnlyShowsOnTheCustomPerson() {
        var avatar = AvatarSettings()
        avatar.hasPhoto = true
        #expect(!avatar.showsPhotoFace, "Drip doesn't wear a face")
        avatar.character = .human
        #expect(avatar.showsPhotoFace)
        avatar.usePhotoFace = false
        #expect(!avatar.showsPhotoFace)
        avatar.usePhotoFace = true
        avatar.hasPhoto = false
        #expect(!avatar.showsPhotoFace)
    }

    @Test func paletteSnapsSampledColorsToThePresets() {
        // A slightly shadowed cheek still lands on the right skin tone.
        #expect(AvatarPalette.nearestSkin(to: 0xF3C9A5) == 0xF5CBA7)
        #expect(AvatarPalette.nearestSkin(to: 0x000000) == AvatarPalette.skinTones.last)
        #expect(AvatarPalette.nearestSkin(to: 0xFFFFFF) == AvatarPalette.skinTones.first)
        // Natural hair never snaps to the fun colors.
        #expect(AvatarPalette.nearestNaturalHair(to: 0x4C6FE0) != 0x4C6FE0)
        #expect(AvatarPalette.nearestNaturalHair(to: 0x201208) == 0x1B1B1B)
        #expect(AvatarPalette.nearest(to: 0x123456, in: []) == 0x123456)
    }

    @Test func speedAndSizeScaleSensibly() {
        let speeds = WalkSpeed.allCases.map(\.pointsPerSecond)
        #expect(speeds == speeds.sorted() && Set(speeds).count == speeds.count)
        let scales = AvatarSize.allCases.map(\.scale)
        #expect(scales == scales.sorted() && scales.contains(1))
        let fps = AvatarQuality.allCases.map(\.framesPerSecond)
        #expect(fps == fps.sorted() && fps.allSatisfy { (10...60).contains($0) })
    }

    @Test func everyCharacterHasDisplayText() {
        for character in AvatarCharacter.allCases {
            #expect(!character.displayName.isEmpty && !character.emoji.isEmpty && !character.tagline.isEmpty)
        }
        #expect(AvatarCharacter.allCases.filter(\.isFanMade).count == 3)
    }

    @Test(arguments: Personality.allCases)
    func cardTitlesFitOnOneLine(_ personality: Personality) {
        for kind in ReminderKind.allCases {
            let titles = kind.cardTitles(for: personality)
            #expect(titles.count >= 3)
            #expect(titles.allSatisfy { !$0.isEmpty && $0.count <= 21 }, "\(personality) \(kind) has a title that's too long")
        }
    }

    @Test func charactersHaveTheirOwnTitles() {
        for personality in [Personality.kratos, .kungFuPanda, .wukong] {
            for kind in ReminderKind.allCases {
                #expect(kind.cardTitles(for: personality) != kind.cardTitles)
            }
        }
        #expect(ReminderKind.water.cardTitles(for: .cheerful) == ReminderKind.water.cardTitles)
    }
}
