import Foundation
import Testing
@testable import SipStretchCore

@Suite struct AutomationCommandTests {
    private func parse(_ string: String) -> AutomationCommand? { AutomationCommand(url: URL(string: string)!) }

    @Test func parsesEveryCommand() {
        #expect(parse("sipstretch://drink") == .drink)
        #expect(parse("SipStretch://Drink") == .drink)
        #expect(parse("sipstretch://undo-drink") == .undoDrink)
        #expect(parse("sipstretch://remind/water") == .remind(.water))
        #expect(parse("sipstretch://remind/stretch") == .remind(.stretch))
        #expect(parse("sipstretch://dnd?minutes=90") == .dnd(minutes: 90))
        #expect(parse("sipstretch://dnd/on") == .dnd(minutes: nil))
        #expect(parse("sipstretch://dnd") == .dnd(minutes: nil))
        #expect(parse("sipstretch://dnd/off") == .dndOff)
        #expect(parse("sipstretch://settings") == .openSettings)
    }

    @Test func rejectsNonsense() {
        #expect(parse("https://drink") == nil)
        #expect(parse("sipstretch://remind/coffee") == nil)
        #expect(parse("sipstretch://remind") == nil)
        #expect(parse("sipstretch://dnd?minutes=0") == nil)
        #expect(parse("sipstretch://dnd?minutes=-5") == nil)
        #expect(parse("sipstretch://dance") == nil)
        // A typo must never silently mean "Do Not Disturb forever", and huge values must not overflow.
        #expect(parse("sipstretch://dnd?minutes=1.5") == nil)
        #expect(parse("sipstretch://dnd?minutes=30m") == nil)
        #expect(parse("sipstretch://dnd?minutes=200000000000000000") == nil)
        #expect(parse("sipstretch://dnd?minutes=525600") == .dnd(minutes: 525_600))
    }
}
