import AppKit
import CoreGraphics
import ImageIO
import SipStretchCore
import Vision

/// Turns a photo into avatar ingredients, entirely on this Mac (Vision runs on-device, nothing is uploaded):
/// a round 256 px crop of the face, plus a best guess at skin tone and hair color.
enum PhotoAvatar {
    struct Result {
        /// The round face as PNG data (transparent corners).
        var png: Data
        /// Nearest skin-tone preset, if it could be sampled.
        var skin: UInt32?
        /// Nearest natural hair color, if the area above the face looked like hair.
        var hair: UInt32?
        /// False when no face was detected and the middle of the photo was used instead.
        var foundFace: Bool
    }

    enum PhotoError: LocalizedError {
        case unreadable

        var errorDescription: String? { "Couldn't read that image. Try a JPEG or PNG." }
    }

    private static let outputSide = 256

    static func analyze(url: URL) async throws -> Result {
        try await Task.detached(priority: .userInitiated) { try process(url: url) }.value
    }

    private static func process(url: URL) throws -> Result {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw PhotoError.unreadable }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true, // respects the photo's rotation
            kCGImageSourceThumbnailMaxPixelSize: 1600,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { throw PhotoError.unreadable }
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        // The biggest face, in pixel coordinates with the origin at the top left.
        var face: CGRect?
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])
        let faces: [VNFaceObservation] = request.results ?? []
        if let biggest = faces.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }) {
            let box = biggest.boundingBox // normalized, origin at the bottom left
            face = CGRect(x: box.minX * width, y: (1 - box.maxY) * height, width: box.width * width, height: box.height * height)
        }
        let found = face != nil

        // A square crop around the face (or the middle of the photo), kept inside the image.
        let center = CGPoint(x: face?.midX ?? width / 2, y: face?.midY ?? height / 2)
        let wanted = face.map { max($0.width, $0.height) * 1.35 } ?? min(width, height)
        let side = min(wanted, min(width, height))
        let origin = CGPoint(
            x: min(max(0, center.x - side / 2), width - side),
            y: min(max(0, center.y - side / 2), height - side)
        )
        guard let cropped = image.cropping(to: CGRect(x: origin.x, y: origin.y, width: side, height: side).integral) else {
            throw PhotoError.unreadable
        }

        // Skin: the cheeks and nose area of the crop. Hair: a band just above the face.
        let cropWidth = CGFloat(cropped.width)
        let cropHeight = CGFloat(cropped.height)
        let skinRect = CGRect(x: cropWidth * 0.36, y: cropHeight * 0.48, width: cropWidth * 0.28, height: cropHeight * 0.16)
        let skin = averageColor(of: cropped, in: skinRect).map(AvatarPalette.nearestSkin(to:))

        var hair: UInt32?
        if let face {
            let band = CGRect(x: face.minX + face.width * 0.2, y: face.minY - face.height * 0.3, width: face.width * 0.6, height: face.height * 0.26)
            if let sampled = averageColor(of: image, in: band), brightness(of: sampled) < 0.88 {
                hair = AvatarPalette.nearestNaturalHair(to: sampled)
            }
        }

        return Result(png: try roundFacePNG(from: cropped), skin: skin, hair: hair, foundFace: found)
    }

    /// Scales the crop to `outputSide` px and cuts it into a circle.
    private static func roundFacePNG(from cropped: CGImage) throws -> Data {
        let side = CGFloat(outputSide)
        guard
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(data: nil, width: outputSide, height: outputSide, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw PhotoError.unreadable }
        context.interpolationQuality = .high
        context.addEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
        context.clip()
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let output = context.makeImage(), let png = NSBitmapImageRep(cgImage: output).representation(using: .png, properties: [:]) else {
            throw PhotoError.unreadable
        }
        return png
    }

    /// Average color of `rect` (pixel coordinates, top-left origin) as 0xRRGGBB, or nil if the area is empty.
    private static func averageColor(of image: CGImage, in rect: CGRect) -> UInt32? {
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let area = rect.integral.intersection(bounds)
        guard area.width >= 2, area.height >= 2, let patch = image.cropping(to: area) else { return nil }

        let size = 8
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        let drew: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard
                let space = CGColorSpace(name: CGColorSpace.sRGB),
                let context = CGContext(data: buffer.baseAddress, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.interpolationQuality = .high
            context.draw(patch, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drew else { return nil }

        var red = 0, green = 0, blue = 0
        for i in 0..<(size * size) {
            red += Int(pixels[i * 4])
            green += Int(pixels[i * 4 + 1])
            blue += Int(pixels[i * 4 + 2])
        }
        let count = size * size
        return UInt32(red / count) << 16 | UInt32(green / count) << 8 | UInt32(blue / count)
    }

    private static func brightness(of hex: UInt32) -> Double {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        return 0.299 * r + 0.587 * g + 0.114 * b
    }
}
