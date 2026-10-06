import AppKit
import SwiftUI
import UniformTypeIdentifiers
import SipStretchCore

/// Pick who walks onto your screen, and how: a built-in character, a custom person (optionally with
/// your own face from a photo), or a 3D model you bring.
@MainActor
struct AvatarPane: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The live 3D preview only renders while this pane is on screen.
    @ViewState private var previewing = false
    @ViewState private var photoMessage: String? = nil
    @ViewState private var modelMessage: String? = nil
    @ViewState private var dropTargeted = false
    @ViewState private var busy = false

    private var avatar: AvatarSettings { model.settings.avatar }
    private var theme: Theme { model.settings.theme }

    var body: some View {
        Form {
            previewSection
            characterSection
            if avatar.character == .human { lookSection }
            photoSection
            modelSection
            voiceSection
            walkSection
        }
        .formStyle(.grouped)
        .onAppear { previewing = true }
        .onDisappear { previewing = false }
    }

    // MARK: Preview

    private var previewSection: some View {
        @Bindable var model = model
        return Section {
            HStack(alignment: .center, spacing: 18) {
                AvatarPreviewView(
                    look: AvatarLook(app: model.settings).normalized,
                    spinning: !reduceMotion,
                    playing: previewing
                )
                .frame(width: 190, height: 190)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(theme.light.opacity(0.16)))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("3D preview of \(avatar.character.displayName)")

                VStack(alignment: .leading, spacing: 8) {
                    Text("\(avatar.character.emoji)  \(avatar.character.displayName)").font(.rounded(19, .bold))
                    Text(avatar.character.tagline)
                        .font(.rounded(12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Toggle("Walk across the screen to remind me", isOn: $model.settings.avatar.walkOnScreen)
                    Button("▶︎  Preview a walk") { model.previewWalk() }
                        .disabled(!avatar.walkOnScreen)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Your avatar")
        } footer: {
            Text("When a reminder is due, your avatar walks in from the bottom-right corner of the main screen, shows off its signature move, and the card appears above it. Finish the task and it celebrates and leaves happy; skip it and it sulks and storms off; ignore the preview card for about 20 seconds to watch it get impatient. It never blocks clicks and uses no CPU while standing still.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Characters

    private var characterSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(AvatarCharacter.allCases.filter { $0 != .model || avatar.modelSlot(for: .model) != nil }) { character in
                    characterCard(character)
                }
            }
            .padding(.vertical, 4)
            if avatar.character != .human && avatar.character != .model {
                modelRow(for: avatar.character)
            }
        } header: {
            Text("Character")
        } footer: {
            Text("Kratos, Kung Fu Panda and Wukong are fan-made homages built from simple shapes. They aren't affiliated with or endorsed by the games and films they nod to. Each one prompts you in its own voice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func characterCard(_ character: AvatarCharacter) -> some View {
        let selected = avatar.character == character
        return Button {
            model.settings.avatar.character = character
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(character.emoji)  \(character.displayName)").font(.rounded(13, .bold))
                Text(character.tagline)
                    .font(.rounded(11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if character.isFanMade {
                    Text("FAN-MADE")
                        .font(.rounded(8.5, .heavy))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(selected ? theme.light.opacity(0.25) : Color.primary.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(selected ? theme.deep : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(character.displayName)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Custom person

    private var lookSection: some View {
        @Bindable var model = model
        return Section("Custom person") {
            Picker("Gender", selection: $model.settings.avatar.gender) {
                ForEach(AvatarGender.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            swatches("Skin tone", AvatarPalette.skinTones, \.skinHex)
            Picker("Hair style", selection: $model.settings.avatar.hairStyle) {
                ForEach(HairStyle.allCases) { Text($0.displayName).tag($0) }
            }
            if avatar.hairStyle != .bald {
                swatches("Hair color", AvatarPalette.hairColors, \.hairHex)
            }
            Picker("Outfit", selection: $model.settings.avatar.outfit) {
                ForEach(OutfitStyle.allCases) { Text($0.displayName).tag($0) }
            }
            swatches(avatar.outfit == .dress ? "Dress color" : "Top color", AvatarPalette.outfitColors, \.topHex)
            if avatar.outfit != .dress {
                swatches("Bottom color", AvatarPalette.outfitColors, \.bottomHex)
            }
            LabeledContent("Accessories") {
                HStack(spacing: 6) {
                    ForEach(AvatarAccessory.allCases) { accessory in
                        Toggle("\(accessory.emoji) \(accessory.displayName)", isOn: accessoryBinding(accessory))
                            .toggleStyle(.button)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    private func accessoryBinding(_ accessory: AvatarAccessory) -> Binding<Bool> {
        Binding(
            get: { model.settings.avatar.accessories.contains(accessory) },
            set: { on in
                if on { model.settings.avatar.accessories.insert(accessory) } else { model.settings.avatar.accessories.remove(accessory) }
            }
        )
    }

    /// A row of color dots plus a color picker for anything not in the presets.
    private func swatches(_ title: String, _ colors: [UInt32], _ keyPath: WritableKeyPath<AvatarSettings, UInt32>) -> some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                ForEach(colors, id: \.self) { hex in
                    let selected = model.settings.avatar[keyPath: keyPath] == hex
                    Button {
                        model.settings.avatar[keyPath: keyPath] = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().strokeBorder(selected ? Color.primary : Color.primary.opacity(0.18), lineWidth: selected ? 2.5 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(String(hex, radix: 16))")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                ColorPicker(title, selection: colorBinding(keyPath), supportsOpacity: false)
                    .labelsHidden()
            }
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<AvatarSettings, UInt32>) -> Binding<Color> {
        Binding(
            get: { Color(hex: model.settings.avatar[keyPath: keyPath]) },
            set: { model.settings.avatar[keyPath: keyPath] = Self.hex(of: $0) }
        )
    }

    private static func hex(of color: Color) -> UInt32 {
        guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return 0 }
        func byte(_ value: CGFloat) -> UInt32 { UInt32(max(0, min(255, (value * 255).rounded()))) }
        return byte(rgb.redComponent) << 16 | byte(rgb.greenComponent) << 8 | byte(rgb.blueComponent)
    }

    // MARK: Photo

    private var photoSection: some View {
        @Bindable var model = model
        return Section {
            HStack(spacing: 14) {
                facePreview
                VStack(alignment: .leading, spacing: 8) {
                    Text(avatar.hasPhoto
                        ? "Your face is on the custom person, with skin tone and hair color picked to match."
                        : "Upload a photo and the custom person gets your face, plus a matching skin tone and hair color. You can also drop a photo here.")
                        .font(.rounded(12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(avatar.hasPhoto ? "Choose another…" : "Choose a photo…") { choosePhoto() }
                            .disabled(busy)
                        if avatar.hasPhoto {
                            Button("Remove", role: .destructive) { removePhoto() }
                        }
                        if busy { ProgressView().controlSize(.small) }
                    }
                    if avatar.hasPhoto {
                        Toggle("Show my face on the avatar", isOn: $model.settings.avatar.usePhotoFace)
                    }
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(dropTargeted ? theme.light.opacity(0.25) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(dropTargeted ? theme.deep : .clear, style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
            .onDrop(of: [UTType.fileURL], isTargeted: $dropTargeted) { providers in handleDrop(providers) }
            if let photoMessage {
                Text(photoMessage).font(.caption).foregroundStyle(.secondary)
            }
        } header: {
            Text("Make it look like you")
        } footer: {
            Text("Photos are analysed on this Mac and never uploaded. Only a small round crop of the face is kept (in Application Support). Use photos you have the right to use.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var facePreview: some View {
        if avatar.hasPhoto, let image = AvatarStorage.facePhoto(revision: avatar.photoRevision) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(theme.deep.opacity(0.6), lineWidth: 2))
                .accessibilityLabel("Your face photo")
        } else {
            Circle()
                .strokeBorder(Color.primary.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 26)).foregroundStyle(.secondary))
                .accessibilityHidden(true)
        }
    }

    private func choosePhoto() {
        let panel = NSOpenPanel()
        panel.title = "Choose a photo of a face"
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        applyPhoto(from: url)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL? = (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) } ?? (item as? URL)
            guard let url else { return }
            Task { @MainActor in applyPhoto(from: url) }
        }
        return true
    }

    private func applyPhoto(from url: URL) {
        busy = true
        photoMessage = "Looking at the photo…"
        Task { @MainActor in
            defer { busy = false }
            do {
                let result = try await PhotoAvatar.analyze(url: url)
                try AvatarStorage.saveFacePhoto(result.png)
                var updated = model.settings.avatar
                updated.hasPhoto = true
                updated.usePhotoFace = true
                updated.photoRevision += 1
                updated.character = .human
                if let skin = result.skin { updated.skinHex = skin }
                if let hair = result.hair { updated.hairHex = hair }
                model.settings.avatar = updated
                photoMessage = result.foundFace
                    ? "Done! The colors are a best guess, so tweak them above if needed."
                    : "I couldn't find a face, so I used the middle of the photo."
            } catch {
                photoMessage = error.localizedDescription
            }
        }
    }

    private func removePhoto() {
        AvatarStorage.removeFacePhoto()
        model.settings.avatar.hasPhoto = false
        model.settings.avatar.photoRevision += 1
        photoMessage = nil
    }

    // MARK: 3D models

    /// Import (or replace, or remove) a detailed 3D model that stands in for `character`'s built-in look.
    /// The character keeps its voice, lines and attitude.
    private func modelRow(for character: AvatarCharacter) -> some View {
        let slot = avatar.modelSlot(for: character)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.map { "Using your model: \($0.displayName)" } ?? "Use a realistic 3D model for \(character.displayName)")
                        .font(.rounded(13, .semibold))
                    Text(slot == nil ? "USDZ, DAE, SCN or OBJ, up to 60 MB. Replaces the built-in shapes; the voice and attitude stay." : "Stored on this Mac. It moves with \(character.displayName)'s attitude: lunges, spins, somersaults.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(slot == nil ? "Import…" : "Replace…") { importModel(for: character) }
                if slot != nil {
                    Button("Remove", role: .destructive) { removeModel(for: character) }
                }
            }
            if slot != nil {
                Picker("Turn model", selection: rotationBinding(for: character)) {
                    ForEach([0, 90, 180, 270], id: \.self) { Text("\($0)°").tag($0) }
                }
                .pickerStyle(.segmented)
            }
            if let modelMessage {
                Text(modelMessage).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 6)
    }

    private func rotationBinding(for character: AvatarCharacter) -> Binding<Int> {
        Binding(
            get: { model.settings.avatar.modelSlot(for: character)?.rotation ?? 0 },
            set: { model.settings.avatar.setModelRotation($0, for: character) }
        )
    }

    private var modelSection: some View {
        Section {
            if avatar.modelSlot(for: .model) != nil || avatar.character == .model {
                modelRow(for: .model)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Any other character").font(.rounded(13, .semibold))
                        Text("USDZ, DAE, SCN or OBJ, up to 60 MB")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Import 3D model…") { importModel(for: .model) }
                }
            }
        } header: {
            Text("Bring your own 3D model")
        } footer: {
            Text("For a more realistic look than the built-in shapes, import a detailed model you made, bought or are licensed to use. Pick a character above to give it that character's own model, or import one here for anyone else (then choose its voice below). Models act with their whole body: they lean, lunge, spin, hop and somersault in the style of their voice. USDZ works best because textures are packed inside.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func importModel(for character: AvatarCharacter) {
        let panel = NSOpenPanel()
        panel.title = "Choose a 3D model for \(character.displayName)"
        panel.allowedContentTypes = AvatarStorage.modelExtensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let fileName = try AvatarStorage.importModel(from: url, for: character)
            guard AvatarRig.loadModelNode(url: AvatarStorage.modelURL(fileName)) != nil else {
                AvatarStorage.removeModel(for: character)
                throw AvatarStorage.StorageError.unreadable
            }
            var updated = model.settings.avatar
            updated.setModel(ModelSlot(character: character, fileName: fileName, displayName: url.deletingPathExtension().lastPathComponent), for: character)
            updated.character = character
            model.settings.avatar = updated
            modelMessage = "Imported. If it faces away from you, turn it above."
        } catch {
            modelMessage = error.localizedDescription
        }
    }

    private func removeModel(for character: AvatarCharacter) {
        AvatarStorage.removeModel(for: character)
        model.settings.avatar.setModel(nil, for: character)
        if character == .model, model.settings.avatar.character == .model { model.settings.avatar.character = .drip }
        modelMessage = nil
    }

    // MARK: Voice

    private var voiceSection: some View {
        @Bindable var model = model
        let voice = model.settings.effectivePersonality
        return Section {
            if avatar.character.voice != nil {
                Toggle("Talk like \(avatar.character.displayName)", isOn: $model.settings.avatar.matchVoiceToCharacter)
            }
            if avatar.character.voice == nil {
                Picker("Voice", selection: $model.settings.personality) {
                    ForEach(Personality.allCases) { Text("\($0.emoji)  \($0.displayName)").tag($0) }
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Text(voice.emoji).font(.system(size: 22))
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.displayName).font(.rounded(13, .semibold))
                    Text(MessagePack.render(voice.pack.waterReminders.first ?? "", name: model.settings.nickname, left: model.waterLeft))
                        .font(.rounded(12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } header: {
            Text("Voice")
        } footer: {
            Text(voiceFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var voiceFooter: String {
        if avatar.character.voice != nil, avatar.matchVoiceToCharacter {
            return "Reminders, cheers and read-aloud speech all use \(avatar.character.displayName)'s own voice."
        }
        return "Using the personality \(model.settings.personality.displayName), the same one as in Personality & Look. Give a custom person or your own 3D model the voice of Kratos, Kung Fu Panda, the Monkey King or Hulk by picking it here."
    }

    // MARK: Walking

    private var walkSection: some View {
        @Bindable var model = model
        return Section {
            Picker("Size", selection: $model.settings.avatar.size) {
                ForEach(AvatarSize.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Walking speed", selection: $model.settings.avatar.speed) {
                ForEach(WalkSpeed.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Gets annoyed after", selection: $model.settings.avatar.patienceMinutes) {
                Text("Never").tag(0)
                ForEach([2, 5, 10, 15, 30], id: \.self) { Text("\($0) minutes").tag($0) }
            }
            Picker("Animation", selection: $model.settings.avatar.quality) {
                ForEach(AvatarQuality.allCases) { Text($0.displayName).tag($0) }
            }
        } header: {
            Text("Walking")
        } footer: {
            Text("The avatar walks in from the bottom-right corner of your main screen only, even with several displays. If you ignore it, it gets more and more annoyed, then storms off after the time above. Lower frame rates use less CPU and battery; with Reduce Motion on, it fades in instead of walking.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
