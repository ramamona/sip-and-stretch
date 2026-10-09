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
            .kratos: .kratos, .kungFuPanda: .kungFuPanda, .wukong: .wukong, .hulk: .hulk, .robot: .robot,
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
        let openers = [Personality.kratos, .kungFuPanda, .wukong, .hulk].map { Set($0.pack.waterReminders) }
        #expect(openers[0].isDisjoint(with: openers[1]))
        #expect(openers[1].isDisjoint(with: openers[2]))
        #expect(openers[0].isDisjoint(with: openers[2]))
        #expect(openers[3].isDisjoint(with: openers[0]) && openers[3].isDisjoint(with: openers[1]) && openers[3].isDisjoint(with: openers[2]))
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
        settings.avatar.idle = .still
        settings.avatar.setModel(ModelSlot(character: .kratos, fileName: "model-kratos.usdz", displayName: "Kratos"), for: .kratos)
        settings.avatar.setModel(ModelSlot(character: .model, fileName: "model-model.usdz", displayName: "Hero"), for: .model)
        settings.avatar.setModelRotation(180, for: .kratos)
        settings.avatar.poseModelBody = false
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
        #expect(settings.avatar.poseModelBody, "imported models get real joint movement unless turned off")
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
        #expect(AvatarCharacter.allCases.filter(\.isFanMade).count == 4)
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
        for personality in [Personality.kratos, .kungFuPanda, .wukong, .hulk] {
            for kind in ReminderKind.allCases {
                #expect(kind.cardTitles(for: personality) != kind.cardTitles)
            }
        }
        #expect(ReminderKind.water.cardTitles(for: .cheerful) == ReminderKind.water.cardTitles)
    }

    @Test(arguments: Personality.allCases)
    func everyoneHasReactionsToBeingIgnored(_ personality: Personality) {
        for reaction in AvatarReaction.allCases {
            let lines = personality.reactionLines(reaction)
            #expect(lines.count >= 3)
            #expect(lines.allSatisfy { !$0.isEmpty && $0.count <= 110 && !$0.contains("{left}") })
        }
        #expect(personality.reactionTitle(.skipped).count <= 21 && personality.reactionTitle(.timedOut).count <= 21)
    }

    @Test func charactersReactInTheirOwnWords() {
        for personality in [Personality.kratos, .kungFuPanda, .wukong, .hulk] {
            for reaction in AvatarReaction.allCases {
                #expect(personality.reactionLines(reaction) != Personality.cheerful.reactionLines(reaction))
            }
        }
    }

    @Test func patienceTimelineGetsAngrierAndEnds() {
        var avatar = AvatarSettings()
        let timeline = avatar.patienceTimeline()
        #expect(timeline.timeout == 600)
        #expect(timeline.grumbles.count == 3)
        #expect(timeline.grumbles == timeline.grumbles.sorted())
        #expect(timeline.grumbles.allSatisfy { $0 > 0 && $0 < 600 })
        #expect(avatar.patienceTimeline(speedUp: 30).timeout == 20)
        avatar.patienceMinutes = 0
        #expect(avatar.patienceTimeline() == PatienceTimeline(grumbles: [], timeout: nil))
    }

    @Test func eachCharacterCanHaveItsOwnModel() {
        var avatar = AvatarSettings()
        #expect(avatar.activeModel == nil)
        avatar.setModel(ModelSlot(character: .kratos, fileName: "model-kratos.usdz", displayName: "Kratos"), for: .kratos)
        avatar.setModel(ModelSlot(character: .kungFuPanda, fileName: "model-kungFuPanda.usdz", displayName: "Po"), for: .kungFuPanda)
        #expect(avatar.modelSlots.count == 2)
        #expect(avatar.activeModel == nil, "Drip is selected and has no model")
        avatar.character = .kratos
        #expect(avatar.activeModel?.displayName == "Kratos")
        avatar.character = .kungFuPanda
        #expect(avatar.activeModel?.displayName == "Po")

        // Replacing keeps one slot per character; rotation is normalized; removing clears it.
        avatar.setModel(ModelSlot(character: .kungFuPanda, fileName: "model-kungFuPanda.usdc", displayName: "Po 2"), for: .kungFuPanda)
        #expect(avatar.modelSlots.count == 2 && avatar.activeModel?.displayName == "Po 2")
        avatar.setModelRotation(-90, for: .kungFuPanda)
        #expect(avatar.activeModel?.rotation == 270)
        avatar.setModel(nil, for: .kungFuPanda)
        #expect(avatar.activeModel == nil && avatar.modelSlots.count == 1)
        avatar.setModelRotation(90, for: .wukong) // no model: nothing happens
        #expect(avatar.modelSlots.count == 1)
    }

    @Test func modelSlotsSurviveTheSettingsMerge() throws {
        var settings = AppSettings()
        settings.avatar.setModel(ModelSlot(character: .kratos, fileName: "model-kratos.usdz", displayName: "Kratos", rotation: 90), for: .kratos)
        settings.avatar.setModel(ModelSlot(character: .kungFuPanda, fileName: "model-kungFuPanda.usdz", displayName: "Po"), for: .kungFuPanda)
        let data = try JSONEncoder().encode(settings)
        let decoded = AppSettings.decode(from: data)
        #expect(decoded.avatar.modelSlots == settings.avatar.modelSlots)
        #expect(decoded.avatar.modelSlot(for: .kratos)?.rotation == 90)
    }

    @Test func idleDefaultsToLivelyAndPersists() throws {
        #expect(AvatarSettings().idle == .lively)
        var settings = AppSettings()
        settings.avatar.idle = .still
        #expect(AppSettings.decode(from: try JSONEncoder().encode(settings)).avatar.idle == .still)
        #expect(AvatarIdle.allCases.allSatisfy { !$0.displayName.isEmpty })
    }

    @Test func skippingGrowsTheAvatarUpToACap() {
        let growth = (0...8).map { AvatarSettings.growth(forAnnoyance: $0) }
        #expect(growth[0] == 1 && growth == growth.sorted() && growth.last == 1.8)
        #expect(AvatarSettings.growth(forAnnoyance: -3) == 1)
        #expect(AvatarSettings.rage(forAnnoyance: 0) == 0 && AvatarSettings.rage(forAnnoyance: 9) == 1)
    }
}
