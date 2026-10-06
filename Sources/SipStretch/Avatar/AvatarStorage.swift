import AppKit

/// Where the photo-derived face and the imported 3D model live: `~/Library/Application Support/SipStretch/Avatar`.
/// Files stay on this Mac and are only read when the avatar is shown.
enum AvatarStorage {
    /// File types SceneKit can load without extra plugins.
    static let modelExtensions = ["usdz", "usd", "usda", "usdc", "scn", "dae", "obj", "abc", "ply", "stl"]
    /// Bigger models would make the avatar slow and hungry; the app is meant to stay light.
    static let maxModelBytes = 60 * 1_024 * 1_024

    enum StorageError: LocalizedError {
        case unsupportedType
        case tooLarge
        case unreadable

        var errorDescription: String? {
            switch self {
            case .unsupportedType: "That file type isn't supported. Use USDZ, DAE, SCN or OBJ."
            case .tooLarge: "That model is bigger than 60 MB. Pick a lighter one (the app is meant to stay small and quick)."
            case .unreadable: "Couldn't read that 3D model. Try exporting it as a .usdz file."
            }
        }
    }

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appending(path: "SipStretch/Avatar", directoryHint: .isDirectory)
    }

    static var facePhotoURL: URL { directory.appending(path: "face.png") }

    static func modelURL(_ fileName: String) -> URL { directory.appending(path: fileName) }

    private static func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: Face photo

    static func saveFacePhoto(_ png: Data) throws {
        try ensureDirectory()
        try png.write(to: facePhotoURL, options: .atomic)
    }

    static func removeFacePhoto() {
        try? FileManager.default.removeItem(at: facePhotoURL)
    }

    // The face is shown on every card, popover and preview, so decode it once per revision.
    @MainActor private static var cachedFace: (revision: Int, image: NSImage)?

    /// The cropped face for `revision`, or nil if there isn't one.
    @MainActor
    static func facePhoto(revision: Int) -> NSImage? {
        if let cachedFace, cachedFace.revision == revision { return cachedFace.image }
        guard let image = NSImage(contentsOf: facePhotoURL) else { return nil }
        cachedFace = (revision, image)
        return image
    }

    // MARK: 3D model

    /// Copies a model into the app's folder as the model for `character` (replacing any previous one)
    /// and returns the stored file name.
    static func importModel(from source: URL, for character: AvatarCharacter) throws -> String {
        let ext = source.pathExtension.lowercased()
        guard modelExtensions.contains(ext) else { throw StorageError.unsupportedType }
        let size = (try? source.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        guard size > 0 else { throw StorageError.unreadable }
        guard size <= maxModelBytes else { throw StorageError.tooLarge }

        try ensureDirectory()
        removeModel(for: character)
        let fileName = "\(modelPrefix(for: character)).\(ext)"
        try FileManager.default.copyItem(at: source, to: modelURL(fileName))
        return fileName
    }

    static func removeModel(for character: AvatarCharacter) {
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for url in urls where url.deletingPathExtension().lastPathComponent == modelPrefix(for: character) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func modelPrefix(for character: AvatarCharacter) -> String { "model-\(character.rawValue)" }
}
