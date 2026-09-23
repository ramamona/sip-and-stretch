import SwiftUI
import SipStretchCore

/// The status item: a droplet (or a moon during Do Not Disturb) plus optional text.
struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let symbol = model.isDNDActive ? "moon.zzz.fill" : model.inMeeting ? "video.fill" : "drop.fill"
        switch model.settings.menuBarDisplay {
        case .iconOnly:
            Image(systemName: symbol)
        case .countdown:
            if !model.isQuiet, let next = model.nextReminder, Calendar.current.isDate(next.date, inSameDayAs: model.now) {
                HStack(spacing: 3) {
                    Image(systemName: symbol)
                    Text(next.date > model.now ? Format.compactDuration(next.date.timeIntervalSince(model.now)) : "now")
                        .monospacedDigit()
                }
            } else {
                Image(systemName: symbol)
            }
        case .waterProgress:
            HStack(spacing: 3) {
                Image(systemName: symbol)
                Text("\(model.today.water)/\(model.settings.dailyWaterGoal)").monospacedDigit()
            }
        }
    }
}
