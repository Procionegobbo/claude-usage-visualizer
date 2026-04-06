import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.1: Structural tests — verifying model types are defined correctly.
// Full JSON decoding tests added in Story 3.4 (NFR15 compliance).

@Suite("UsageData model")
struct UsageDataTests {

    @Test("UsageWindow stores utilization and resetsAt")
    func usageWindowProperties() {
        let now = Date()
        let window = UsageWindow(utilization: 42.0, resetsAt: now)
        #expect(window.utilization == 42.0)
        #expect(window.resetsAt == now)
    }

    @Test("UsageWindow accepts nil resetsAt")
    func usageWindowNilResetsAt() {
        let window = UsageWindow(utilization: 0.0, resetsAt: nil)
        #expect(window.resetsAt == nil)
    }

    @Test("UsageData stores fiveHour and sevenDay windows")
    func usageDataProperties() {
        let now = Date()
        let five = UsageWindow(utilization: 50.0, resetsAt: now)
        let seven = UsageWindow(utilization: 75.0, resetsAt: now)
        let data = UsageData(fiveHour: five, sevenDay: seven, fetchedAt: now)
        #expect(data.fiveHour.utilization == 50.0)
        #expect(data.sevenDay.utilization == 75.0)
        #expect(data.fetchedAt == now)
    }
}
