import SwiftUI
import SipStretchCore

struct SchedulePane: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Toggle("Only remind me during active hours", isOn: $model.settings.schedule.isEnabled)
                Group {
                    DatePicker("From", selection: minuteBinding($model.settings.schedule.startMinute), displayedComponents: .hourAndMinute)
                    DatePicker("Until", selection: minuteBinding($model.settings.schedule.endMinute), displayedComponents: .hourAndMinute)
                    LabeledContent("On") { weekdayChips }
                }
                .disabled(!model.settings.schedule.isEnabled)
            } header: {
                Text("Active hours")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🗓️ \(model.settings.schedule.summary())").fontWeight(.medium)
                    Text("Outside these hours Drip sleeps. When your day starts, the countdown starts fresh, so the first reminder comes one interval later. Night owl? An end time earlier than the start (say 10 PM – 2 AM) makes an overnight window.")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Pause during calls and meetings", isOn: $model.settings.pauseDuringMeetings)
            } header: {
                Text("Meetings")
            } footer: {
                Text("While any app is using your camera or microphone, reminders wait and any card on screen tucks itself away (no surprise cards on a screen share). Drip only checks whether they're in use and never sees or hears anything.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Pause when I'm away", isOn: $model.settings.pauseWhenAway)
                Stepper(value: $model.settings.awayThresholdMinutes, in: 1...60) {
                    LabeledContent("Away after", value: "\(model.settings.awayThresholdMinutes) min without mouse or keyboard")
                }
                .disabled(!model.settings.pauseWhenAway)
            } header: {
                Text("Away detection")
            } footer: {
                Text("Reminders always wait while your screen is locked or your Mac is asleep. Coming back after a break resets the stretch, eye and walk countdowns 🚶 and any waiting water reminder pops up a minute later.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var weekdayChips: some View {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        let order = (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
        return HStack(spacing: 5) {
            ForEach(order, id: \.self) { day in
                let on = model.settings.schedule.weekdays.contains(day)
                Button(symbols[day - 1]) {
                    if on { model.settings.schedule.weekdays.remove(day) } else { model.settings.schedule.weekdays.insert(day) }
                }
                .buttonStyle(.pill(on ? .primary : .quiet, theme: model.settings.theme, compact: true))
                .help(calendar.weekdaySymbols[day - 1])
                .accessibilityLabel(calendar.weekdaySymbols[day - 1])
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    /// Bridges "minutes after midnight" to the Date a DatePicker wants.
    private func minuteBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: Date()) ?? Date()
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }
}
