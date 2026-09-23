import Foundation

/// `sipstretch://` URLs, so Shortcuts, scripts, Raycast/Alfred, etc. can drive the app.
///
///     sipstretch://drink                 log a glass
///     sipstretch://undo-drink            remove the last glass
///     sipstretch://remind/water          show a reminder now (also: remind/stretch)
///     sipstretch://dnd?minutes=90        Do Not Disturb for 90 minutes
///     sipstretch://dnd/on                Do Not Disturb until turned off
///     sipstretch://dnd/off               end Do Not Disturb
///     sipstretch://settings              open Settings
public enum AutomationCommand: Equatable, Sendable {
    case drink
    case undoDrink
    case remind(ReminderKind)
    case dnd(minutes: Int?)
    case dndOff
    case openSettings

    static let maxMinutes = 365 * 24 * 60

    public init?(url: URL) {
        guard url.scheme?.lowercased() == "sipstretch" else { return nil }
        let action = url.host?.lowercased() ?? ""
        let argument = url.pathComponents.first { $0 != "/" }?.lowercased()
        let rawMinutes = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "minutes" }?.value

        switch (action, argument) {
        case ("drink", nil): self = .drink
        case ("undo-drink", nil): self = .undoDrink
        case ("remind", let kind?):
            guard let kind = ReminderKind(rawValue: kind) else { return nil }
            self = .remind(kind)
        case ("dnd", "off"): self = .dndOff
        case ("dnd", nil), ("dnd", "on"):
            guard let rawMinutes else {
                self = .dnd(minutes: nil)
                return
            }
            // A typo must not silently mean "forever"; cap at a year so the maths can't overflow.
            guard let minutes = Int(rawMinutes), (1...Self.maxMinutes).contains(minutes) else { return nil }
            self = .dnd(minutes: minutes)
        case ("settings", nil): self = .openSettings
        default: return nil
        }
    }
}
