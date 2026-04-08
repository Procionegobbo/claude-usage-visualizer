import Testing
import Foundation
@testable import ClaudeUsageWidget

// MARK: - crossingEvent

@Suite("NotificationManager — crossingEvent")
struct NotificationManagerCrossingEventTests {

    @Test("no crossing below threshold returns nil")
    func noCrossingBelowThreshold() {
        #expect(NotificationManager.crossingEvent(previous: 50, current: 79, threshold: 80) == nil)
    }

    @Test("exactly at threshold from below returns thresholdCrossed")
    func atThresholdFromBelow() {
        #expect(NotificationManager.crossingEvent(previous: 79, current: 80, threshold: 80) == .thresholdCrossed)
    }

    @Test("skipping over threshold returns thresholdCrossed")
    func skippingOverThreshold() {
        #expect(NotificationManager.crossingEvent(previous: 50, current: 95, threshold: 80) == .thresholdCrossed)
    }

    @Test("already above threshold returns nil (no re-fire)")
    func alreadyAboveThreshold() {
        #expect(NotificationManager.crossingEvent(previous: 81, current: 90, threshold: 80) == nil)
    }

    @Test("crossing 100 from just below returns limitCrossed")
    func crossingLimitFromJustBelow() {
        #expect(NotificationManager.crossingEvent(previous: 99, current: 100, threshold: 80) == .limitCrossed)
    }

    @Test("skipping to above 100 returns limitCrossed (limit priority over threshold)")
    func skippingToAbove100() {
        #expect(NotificationManager.crossingEvent(previous: 50, current: 110, threshold: 80) == .limitCrossed)
    }

    @Test("already at limit returns nil")
    func alreadyAtLimit() {
        #expect(NotificationManager.crossingEvent(previous: 100, current: 105, threshold: 80) == nil)
    }

    @Test("re-crossing threshold after drop returns thresholdCrossed")
    func reCrossingAfterDrop() {
        // Simulates: was above, dropped below, now crossing again
        #expect(NotificationManager.crossingEvent(previous: 75, current: 85, threshold: 80) == .thresholdCrossed)
    }
}

// MARK: - crossing sequence

@Suite("NotificationManager — crossing sequence")
struct NotificationManagerCrossingSequenceTests {

    @Test("first crossing produces event; subsequent above-threshold poll does not (AC5)")
    func exactlyOneCrossingEvent() {
        // First poll: utilization crosses threshold
        let first = NotificationManager.crossingEvent(previous: 79, current: 81, threshold: 80)
        #expect(first == .thresholdCrossed)

        // Second poll: still above threshold — no new crossing (no re-fire)
        let second = NotificationManager.crossingEvent(previous: 81, current: 82, threshold: 80)
        #expect(second == nil)
    }

    @Test("drop below then re-cross produces new event")
    func reCrossAfterDrop() {
        // Back below threshold
        let dropped = NotificationManager.crossingEvent(previous: 85, current: 75, threshold: 80)
        #expect(dropped == nil)
        // Cross again
        let reCrossed = NotificationManager.crossingEvent(previous: 75, current: 82, threshold: 80)
        #expect(reCrossed == .thresholdCrossed)
    }
}

// MARK: - resetSuffix

@Suite("NotificationManager — resetSuffix")
struct NotificationManagerResetSuffixTests {

    @Test("nil resetsAt returns empty string")
    func nilResetsAt() {
        #expect(NotificationManager.resetSuffix(from: nil) == "")
    }

    @Test("past date returns Resets soon")
    func pastDate() {
        let now = Date.now
        let past = now.addingTimeInterval(-60)
        #expect(NotificationManager.resetSuffix(from: past, relativeTo: now) == "Resets soon")
    }

    @Test("30 seconds in future returns Resets soon")
    func thirtySeconds() {
        let now = Date.now
        let soon = now.addingTimeInterval(30)
        #expect(NotificationManager.resetSuffix(from: soon, relativeTo: now) == "Resets soon")
    }

    @Test("exactly 60 seconds returns Resets in 1m (boundary)")
    func exactlySixtySeconds() {
        let now = Date.now
        let future = now.addingTimeInterval(60)
        #expect(NotificationManager.resetSuffix(from: future, relativeTo: now) == "Resets in 1m")
    }

    @Test("30 minutes returns Resets in 30m")
    func thirtyMinutes() {
        let now = Date.now
        let future = now.addingTimeInterval(30 * 60)
        #expect(NotificationManager.resetSuffix(from: future, relativeTo: now) == "Resets in 30m")
    }

    @Test("exactly 60 minutes returns Resets in 1h (no 0m suffix)")
    func exactlyOneHour() {
        let now = Date.now
        let future = now.addingTimeInterval(60 * 60)
        #expect(NotificationManager.resetSuffix(from: future, relativeTo: now) == "Resets in 1h")
    }

    @Test("90 minutes returns Resets in 1h 30m")
    func ninetyMinutes() {
        let now = Date.now
        let future = now.addingTimeInterval(90 * 60)
        #expect(NotificationManager.resetSuffix(from: future, relativeTo: now) == "Resets in 1h 30m")
    }
}
