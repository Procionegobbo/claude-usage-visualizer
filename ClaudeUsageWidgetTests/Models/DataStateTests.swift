import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.1: Structural tests — verifying DataState cases compile and are distinct.
// Full state transition tests added in Story 3.4.

@Suite("DataState model")
struct DataStateTests {

    @Test("DataState.loading is distinct")
    func loadingCase() {
        let state = DataState.loading
        guard case .loading = state else {
            Issue.record("Expected loading"); return
        }
    }

    @Test("DataState.fresh carries UsageData")
    func freshCase() {
        let now = Date()
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 50.0, resetsAt: now),
            sevenDay: UsageWindow(utilization: 75.0, resetsAt: now),
            fetchedAt: now
        )
        let state = DataState.fresh(data)
        guard case let .fresh(payload) = state else {
            Issue.record("Expected fresh"); return
        }
        #expect(payload.fiveHour.utilization == 50.0)
    }

    @Test("DataState.stale carries UsageData and since Date")
    func staleCase() {
        let now = Date()
        let data = UsageData(
            fiveHour: UsageWindow(utilization: 60.0, resetsAt: now),
            sevenDay: UsageWindow(utilization: 80.0, resetsAt: now),
            fetchedAt: now
        )
        let since = Date(timeIntervalSinceNow: -120)
        let state = DataState.stale(data, since: since)
        guard case let .stale(payload, staleSince) = state else {
            Issue.record("Expected stale"); return
        }
        #expect(payload.fiveHour.utilization == 60.0)
        #expect(staleSince == since)
    }

    @Test("DataState.error carries AppError")
    func errorCase() {
        let state = DataState.error(.tokenMissing)
        guard case let .error(err) = state else {
            Issue.record("Expected error"); return
        }
        #expect(err == .tokenMissing)
    }
}
