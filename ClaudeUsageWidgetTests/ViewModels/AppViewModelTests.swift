import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.1: Verify initial state of AppViewModel
// Full state transition tests added in Story 3.4
@Suite("AppViewModel")
@MainActor
struct AppViewModelTests {

    @Test("AppViewModel initial dataState is loading")
    func initialState() {
        let vm = AppViewModel()
        guard case .loading = vm.dataState else {
            Issue.record("Expected initial state to be .loading"); return
        }
    }
}
