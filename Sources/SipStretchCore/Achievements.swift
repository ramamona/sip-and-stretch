import Foundation

public struct Achievement: Identifiable, Sendable {
    public let id: String
    public let emoji: String
    public let title: String
    public let detail: String
    let isEarned: @Sendable (Stats, _ goal: Int) -> Bool

    public static let all: [Achievement] = [
        Achievement(id: "first-sip", emoji: "🥇", title: "First Sip", detail: "Log your very first glass.") { s, _ in
            s.totalWater >= 1
        },
        Achievement(id: "goal-getter", emoji: "🎯", title: "Goal Getter", detail: "Hit your daily water goal.") { s, _ in
            s.bestStreak >= 1
        },
        Achievement(id: "on-fire", emoji: "🔥", title: "On Fire", detail: "Keep a 3-day water streak.") { s, _ in
            s.bestStreak >= 3
        },
        Achievement(id: "tidal-wave", emoji: "🌊", title: "Tidal Wave", detail: "Keep a 7-day water streak.") { s, _ in
            s.bestStreak >= 7
        },
        Achievement(id: "hydration-legend", emoji: "🏆", title: "Hydration Legend", detail: "Keep a 30-day water streak.") { s, _ in
            s.bestStreak >= 30
        },
        Achievement(id: "bendy", emoji: "🤸", title: "Bendy", detail: "Finish 10 stretch breaks.") { s, _ in
            s.totalStretches >= 10
        },
        Achievement(id: "noodle-mode", emoji: "🍜", title: "Noodle Mode", detail: "Finish 100 stretch breaks.") { s, _ in
            s.totalStretches >= 100
        },
        Achievement(id: "early-bird", emoji: "🐦", title: "Early Bird", detail: "Drink a glass before 8 AM.") { s, _ in
            s.days.values.contains { ($0.firstWaterMinute ?? .max) < 8 * 60 }
        },
        Achievement(id: "perfect-day", emoji: "✨", title: "Perfect Day", detail: "Hit your water goal and 5 stretch breaks in one day.") { s, goal in
            s.days.values.contains { $0.water >= max(1, goal) && $0.stretches >= 5 }
        },
        Achievement(id: "centurion", emoji: "💯", title: "Centurion", detail: "Drink 100 glasses in total.") { s, _ in
            s.totalWater >= 100
        },
        Achievement(id: "hawk-eyes", emoji: "🦅", title: "Hawk Eyes", detail: "Take 50 eye breaks.") { s, _ in
            s.totalEyeBreaks >= 50
        },
        Achievement(id: "wanderer", emoji: "🥾", title: "Wanderer", detail: "Go on 25 walks.") { s, _ in
            s.totalWalks >= 25
        },
        Achievement(id: "snooze-champion", emoji: "😴", title: "Snooze Button Champion", detail: "Hit snooze 25 times. We see you.") { s, _ in
            s.totalSnoozes >= 25
        },
    ]
}
