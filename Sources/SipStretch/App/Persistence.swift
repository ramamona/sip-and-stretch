import Foundation
import SipStretchCore

/// JSON blobs in UserDefaults. To inspect them:
/// `defaults export com.sipstretch.app /tmp/sip.plist && /usr/libexec/PlistBuddy -c 'Print :stats.v1' /tmp/sip.plist`
struct Persistence {
    let defaults: UserDefaults

    static let standard = Persistence(defaults: .standard)

    private enum Key {
        static let settings = "settings.v1"
        static let stats = "stats.v1"
        static let dnd = "dnd.v1"
        static let onboarded = "onboarded.v1"
    }

    func loadSettings() -> AppSettings {
        defaults.data(forKey: Key.settings).map(AppSettings.decode(from:)) ?? AppSettings()
    }

    func save(_ settings: AppSettings) { write(settings, key: Key.settings) }

    func loadStats() -> Stats { read(Stats.self, key: Key.stats) ?? Stats() }

    func save(_ stats: Stats) { write(stats, key: Key.stats) }

    func loadDND() -> DNDState { read(DNDState.self, key: Key.dnd) ?? .off }

    func save(_ dnd: DNDState) { write(dnd, key: Key.dnd) }

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Key.onboarded) }
        nonmutating set { defaults.set(newValue, forKey: Key.onboarded) }
    }

    private func read<T: Decodable>(_ type: T.Type, key: String) -> T? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(type, from: $0) }
    }

    private func write<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
