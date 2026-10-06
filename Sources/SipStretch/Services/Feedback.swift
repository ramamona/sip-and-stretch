import AppKit
import AVFoundation
import SipStretchCore

/// Sounds and (optional) spoken reminders.
@MainActor
final class Feedback {
    private let synthesizer = AVSpeechSynthesizer()

    func play(_ sound: AlertSound) {
        guard let name = sound.systemName, let nsSound = NSSound(named: NSSound.Name(name)) else { return }
        nsSound.stop() // restart if it's still playing from a previous nudge
        nsSound.play()
    }

    /// Reads `text` aloud, with the pitch and pace of whoever is talking (Kratos is gruff, the Monkey King squeaky).
    func speak(_ text: String, as personality: Personality = .cheerful) {
        // Emoji get read out by name ("droplet"), which is funny exactly once.
        let spoken = String(String.UnicodeScalarView(text.unicodeScalars.filter { $0.isASCII || !$0.properties.isEmoji }))
            .trimmingCharacters(in: .whitespaces)
        guard !spoken.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: spoken)
        utterance.pitchMultiplier = personality.speechPitch
        utterance.rate = personality.speechRate
        synthesizer.speak(utterance)
    }
}
