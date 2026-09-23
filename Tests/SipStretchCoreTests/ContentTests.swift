import Foundation
import Testing
@testable import SipStretchCore

@Suite struct ContentTests {
    @Test(arguments: Personality.allCases)
    func everyPersonalityHasEveryKindOfLine(_ personality: Personality) {
        let pack = personality.pack
        let fields = [
            pack.waterReminders, pack.stretchReminders, pack.waterCheers, pack.stretchCheers,
            pack.snoozes, pack.greetings, pack.goalReached,
        ]
        for lines in fields {
            #expect(lines.count >= 3)
            #expect(lines.allSatisfy { !$0.isEmpty && $0.count <= 120 })
        }
        #expect(!pack.stretchReminders.contains { $0.contains("{left}") }, "{left} only makes sense for water")
        for lines in [personality.eyeReminders, personality.walkReminders] {
            #expect(lines.count >= 5)
            #expect(lines.allSatisfy { !$0.isEmpty && $0.count <= 120 && !$0.contains("{left}") })
        }
    }

    @Test func renderFillsPlaceholders() {
        #expect(MessagePack.render("Hi {name}, {left} to go", name: "  Sam ", left: 3) == "Hi Sam, 3 to go")
        #expect(MessagePack.render("Hi {name}", name: "", left: 0) == "Hi friend")
        #expect(MessagePack.render("{left} left", name: "", left: -2) == "0 left")
    }

    @Test func pickAvoidsRepeatingTheLastLine() {
        var rng = SeededRNG(state: 42)
        let lines = ["a", "b"]
        for _ in 0..<20 { #expect(lines.pick(avoiding: "a", using: &rng) == "b") }
        #expect(["only"].pick(avoiding: "only", using: &rng) == "only")
        #expect([String]().pick(avoiding: nil, using: &rng) == "")
    }

    @Test func breakPlannerMatchesKindAndSettings() {
        var rng = SeededRNG(state: 3)
        var settings = AppSettings()
        #expect(BreakPlanner.plan(.water, settings: settings, using: &rng) == .drink)
        if case .eyeRest(let seconds, let tip) = BreakPlanner.plan(.eyes, settings: settings, using: &rng) {
            #expect(seconds == 20 && !tip.isEmpty)
        } else { Issue.record("eyes should plan an eye rest") }
        if case .walk(let idea) = BreakPlanner.plan(.walk, settings: settings, using: &rng) {
            #expect(BreakPlanner.walkIdeas.contains(idea))
        } else { Issue.record("walk should plan a walk") }

        // Only posture enabled → always a posture check with 4 distinct items.
        settings.stretchFormats = [.posture]
        for _ in 0..<10 {
            guard case .postureCheck(let items) = BreakPlanner.plan(.stretch, settings: settings, using: &rng) else {
                Issue.record("expected posture check"); return
            }
            #expect(items.count == 4 && Set(items).count == 4)
        }

        // Every format shows up eventually, and roulette respects focus areas.
        settings.stretchFormats = Set(StretchFormat.allCases)
        settings.stretchAreas = [.wrists]
        var seen = Set<String>()
        for _ in 0..<200 {
            let plan = BreakPlanner.plan(.stretch, settings: settings, using: &rng)
            switch plan {
            case .guided(let s): seen.insert("guided"); #expect(s.allSatisfy { $0.area == .wrists })
            case .roulette(let area, let s): seen.insert("roulette"); #expect(area == .wrists && s.allSatisfy { $0.area == .wrists })
            case .breathing: seen.insert("breathing")
            case .challenge: seen.insert("challenge")
            case .postureCheck: seen.insert("posture")
            default: Issue.record("unexpected \(plan)")
            }
        }
        #expect(seen.count == StretchFormat.allCases.count)
    }

    @Test func challengesAreWellFormed() {
        let ids = Challenge.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Challenge.all.allSatisfy { ($0.reps > 0) != ($0.seconds > 0) }, "either reps or a timed hold")
    }

    @Test func stretchLibraryIsWellFormed() {
        let ids = StretchLibrary.all.map(\.id)
        #expect(Set(ids).count == ids.count, "ids must be unique")
        for area in BodyArea.allCases {
            #expect(StretchLibrary.all.contains { $0.area == area }, "\(area) has no stretches")
        }
        #expect(StretchLibrary.all.allSatisfy { (10...60).contains($0.seconds) && !$0.steps.isEmpty })
    }

    @Test func stretchPickingRespectsAreasAndSpreadsThemOut() {
        var rng = SeededRNG(state: 7)
        let picks = StretchLibrary.pick(count: 3, areas: [.neck, .eyes, .wrists], using: &rng)
        #expect(picks.count == 3)
        #expect(Set(picks.map(\.id)).count == 3)
        #expect(Set(picks.map(\.area)) == [.neck, .eyes, .wrists])

        let recent = picks.map(\.id)
        let next = StretchLibrary.pick(count: 2, areas: [.neck], avoiding: recent, using: &rng)
        #expect(next.allSatisfy { $0.area == .neck && !recent.contains($0.id) })

        #expect(StretchLibrary.pick(count: 2, areas: [], using: &rng).count == 2, "empty selection means every area")
        #expect(StretchLibrary.pick(count: 500, areas: [.eyes], using: &rng).count == StretchLibrary.all.filter { $0.area == .eyes }.count)
    }
}
