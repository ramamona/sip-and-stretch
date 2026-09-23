import SwiftUI
import SipStretchCore

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    static let dripInk = Color(hex: 0x1B2A4A)
    static let cheek = Color(hex: 0xFF7EA8)
}

extension Theme {
    var light: Color { Color(hex: hexStops.0) }
    var deep: Color { Color(hex: hexStops.1) }
    var gradient: LinearGradient {
        LinearGradient(colors: [light, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var confettiColors: [Color] { [light, deep, .yellow, .white, .cheek] }

    /// Theme-colored text that stays readable: the deep shade on light backgrounds, the light one on dark.
    func accent(for scheme: ColorScheme) -> Color { scheme == .dark ? light : deep }

    /// Text on a primary (gradient) button. The paler themes need dark text to be legible.
    var onPrimary: Color {
        switch self {
        case .ocean, .grape: .white
        case .mint, .sunset, .bubblegum: .dripInk
        }
    }
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Capsule buttons used on cards and in the popover. Custom-drawn (not AppKit-backed) so they
/// also show up in `ImageRenderer` snapshots.
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, quiet }

    var kind: Kind = .primary
    var theme: Theme
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rounded(compact ? 11.5 : 13, .semibold))
            .lineLimit(1)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 4 : 7)
            .foregroundStyle(kind == .primary ? AnyShapeStyle(theme.onPrimary) : kind == .secondary ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .background {
                switch kind {
                case .primary: Capsule().fill(theme.gradient)
                case .secondary: Capsule().fill(theme.light.opacity(0.22))
                case .quiet: Capsule().fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0.06))
                }
            }
            .overlay { Capsule().strokeBorder(.white.opacity(kind == .primary ? 0.3 : 0), lineWidth: 1) }
            .shadow(color: kind == .primary ? theme.deep.opacity(0.35) : .clear, radius: 5, y: 2)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static func pill(_ kind: PillButtonStyle.Kind = .primary, theme: Theme, compact: Bool = false) -> PillButtonStyle {
        PillButtonStyle(kind: kind, theme: theme, compact: compact)
    }
}

/// A squishy capsule switch.
struct JellyToggleStyle: ToggleStyle {
    var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer(minLength: 8)
                Capsule()
                    .fill(configuration.isOn ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.primary.opacity(0.15)))
                    .frame(width: 40, height: 24)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                            .padding(3)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

struct ProgressRing<Center: View>: View {
    var progress: Double
    var theme: Theme
    var lineWidth: CGFloat = 4
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle().stroke(theme.light.opacity(0.25), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(theme.gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            center
        }
    }
}

struct XPBar: View {
    var progress: Double
    var theme: Theme
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(theme.gradient)
                    .frame(width: max(height, geo.size.width * min(1, max(0, progress))))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            }
        }
        .frame(height: height)
    }
}

/// Rounded "section" background used in the popover.
struct Tile<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum Format {
    /// "23 min", "1 h 5 min".
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = max(1, Int((interval / 60).rounded(.up)))
        if minutes < 60 { return "\(minutes) min" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60) h" : "\(minutes / 60) h \(rest) min"
    }

    /// Compact version for the menu bar: "23m", "1h5m".
    static func compactDuration(_ interval: TimeInterval) -> String {
        let minutes = max(1, Int((interval / 60).rounded(.up)))
        if minutes < 60 { return "\(minutes)m" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h\(rest)m"
    }

    static func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

    /// "3:30 PM" today, otherwise "Tue 9:00 AM".
    static func moment(_ date: Date, relativeTo now: Date) -> String {
        if Calendar.current.isDate(date, inSameDayAs: now) { return time(date) }
        return date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}
