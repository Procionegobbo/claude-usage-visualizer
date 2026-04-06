import Testing
import SwiftUI
import Foundation
@testable import ClaudeUsageWidget

@Suite("UsageCardView")
struct UsageCardViewTests {

    // MARK: - countdownText

    @Test("nil resetsAt returns nil")
    func countdownNil() {
        #expect(UsageCardView.countdownText(from: nil) == nil)
    }

    @Test("past date returns Resets soon")
    func countdownPast() {
        let now = Date.now
        let past = now.addingTimeInterval(-60)
        #expect(UsageCardView.countdownText(from: past, relativeTo: now) == "Resets soon")
    }

    @Test("less than 5 minutes returns Resets soon")
    func countdownUnder5Min() {
        let now = Date.now
        let soon = now.addingTimeInterval(3 * 60)
        #expect(UsageCardView.countdownText(from: soon, relativeTo: now) == "Resets soon")
    }

    @Test("30 minutes returns Resets in 30m")
    func countdown30Min() {
        let now = Date.now
        let future = now.addingTimeInterval(30 * 60)
        #expect(UsageCardView.countdownText(from: future, relativeTo: now) == "Resets in 30m")
    }

    @Test("90 minutes returns Resets in 1h 30m")
    func countdown90Min() {
        let now = Date.now
        let future = now.addingTimeInterval(90 * 60)
        #expect(UsageCardView.countdownText(from: future, relativeTo: now) == "Resets in 1h 30m")
    }

    @Test("exactly 60 minutes returns Resets in 1h 0m")
    func countdown60Min() {
        let now = Date.now
        let future = now.addingTimeInterval(60 * 60)
        #expect(UsageCardView.countdownText(from: future, relativeTo: now) == "Resets in 1h 0m")
    }
}

// MARK: - semanticColor

@Suite("UsageCardView — semanticColor")
struct UsageCardViewColorTests {

    @Test("below threshold returns green")
    func belowThreshold() {
        #expect(UsageCardView.semanticColor(for: 50, threshold: 80) == .green)
    }

    @Test("at threshold returns orange")
    func atThreshold() {
        #expect(UsageCardView.semanticColor(for: 80, threshold: 80) == .orange)
    }

    @Test("above threshold below 100 returns orange")
    func aboveThresholdBelow100() {
        #expect(UsageCardView.semanticColor(for: 95, threshold: 80) == .orange)
    }

    @Test("at 100 returns red")
    func at100() {
        #expect(UsageCardView.semanticColor(for: 100, threshold: 80) == .red)
    }

    @Test("above 100 returns red")
    func above100() {
        #expect(UsageCardView.semanticColor(for: 110, threshold: 80) == .red)
    }

    @Test("zero utilization returns green")
    func zeroUtilization() {
        #expect(UsageCardView.semanticColor(for: 0, threshold: 80) == .green)
    }

    @Test("threshold 0 and any utilization returns orange (0 >= 0)")
    func thresholdZeroUtilizationAtThreshold() {
        // At threshold=0, utilization=0 satisfies >= threshold, so returns .orange (not .green).
        #expect(UsageCardView.semanticColor(for: 0, threshold: 0) == .orange)
    }

    @Test("threshold 0 and utilization 1 returns orange")
    func thresholdZeroUtilizationAbove() {
        #expect(UsageCardView.semanticColor(for: 1, threshold: 0) == .orange)
    }
}

// MARK: - accessibilityCountdownText

@Suite("UsageCardView — accessibilityCountdownText")
struct UsageCardViewAccessibilityCountdownTests {

    @Test("nil resetsAt returns nil")
    func accessibilityCountdownNil() {
        #expect(UsageCardView.accessibilityCountdownText(from: nil) == nil)
    }

    @Test("past date returns resets soon")
    func accessibilityCountdownPast() {
        let now = Date.now
        let past = now.addingTimeInterval(-60)
        #expect(UsageCardView.accessibilityCountdownText(from: past, relativeTo: now) == "resets soon")
    }

    @Test("less than 5 minutes returns resets soon")
    func accessibilityCountdownUnder5Min() {
        let now = Date.now
        let soon = now.addingTimeInterval(3 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: soon, relativeTo: now) == "resets soon")
    }

    @Test("30 minutes returns resets in 30 minutes")
    func accessibilityCountdown30Min() {
        let now = Date.now
        let future = now.addingTimeInterval(30 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 30 minutes")
    }

    @Test("6 minutes returns plural minutes")
    func accessibilityCountdown6Min() {
        let now = Date.now
        let future = now.addingTimeInterval(6 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 6 minutes")
    }

    @Test("exactly 5 minutes is not resets soon — boundary value")
    func accessibilityCountdownExactly5Min() {
        let now = Date.now
        let future = now.addingTimeInterval(5 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 5 minutes")
    }

    @Test("exactly 60 minutes returns 1 hour with no minutes suffix")
    func accessibilityCountdown60Min() {
        let now = Date.now
        let future = now.addingTimeInterval(60 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 1 hour")
    }

    @Test("61 minutes returns 1 hour 1 minute (singular)")
    func accessibilityCountdown61Min() {
        let now = Date.now
        let future = now.addingTimeInterval(61 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 1 hour 1 minute")
    }

    @Test("90 minutes returns 1 hour 30 minutes")
    func accessibilityCountdown90Min() {
        let now = Date.now
        let future = now.addingTimeInterval(90 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 1 hour 30 minutes")
    }

    @Test("120 minutes returns 2 hours with no minutes suffix")
    func accessibilityCountdown120Min() {
        let now = Date.now
        let future = now.addingTimeInterval(120 * 60)
        #expect(UsageCardView.accessibilityCountdownText(from: future, relativeTo: now) == "resets in 2 hours")
    }
}
