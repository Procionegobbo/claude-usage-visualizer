import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.1: Structural tests — verifying AppError cases compile and are distinct.
// Full error mapping tests added in Story 3.4.

@Suite("AppError model")
struct AppErrorTests {

    @Test("AppError.tokenMissing is distinct")
    func tokenMissingCase() {
        let error = AppError.tokenMissing
        guard case .tokenMissing = error else {
            Issue.record("Expected tokenMissing"); return
        }
    }

    @Test("AppError.tokenExpired is distinct")
    func tokenExpiredCase() {
        let error = AppError.tokenExpired
        guard case .tokenExpired = error else {
            Issue.record("Expected tokenExpired"); return
        }
    }

    @Test("AppError.apiUnreachable carries optional lastSuccess")
    func apiUnreachableCase() {
        let now = Date()
        let error = AppError.apiUnreachable(lastSuccess: now)
        guard case let .apiUnreachable(last) = error else {
            Issue.record("Expected apiUnreachable"); return
        }
        #expect(last == now)
    }

    @Test("AppError.apiUnreachable accepts nil lastSuccess")
    func apiUnreachableNilCase() {
        let error = AppError.apiUnreachable(lastSuccess: nil)
        guard case let .apiUnreachable(last) = error else {
            Issue.record("Expected apiUnreachable with nil"); return
        }
        #expect(last == nil)
    }

    @Test("AppError.apiError carries status code")
    func apiErrorCase() {
        let error = AppError.apiError(statusCode: 500)
        guard case let .apiError(code) = error else {
            Issue.record("Expected apiError"); return
        }
        #expect(code == 500)
    }
}
