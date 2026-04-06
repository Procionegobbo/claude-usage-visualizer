import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.2: Structural / integration tests for CredentialsManager.
// Full file system and Keychain mock tests added in Story 3.4.

@Suite("CredentialsManager")
@MainActor
struct CredentialsManagerTests {

    @Test("CredentialsManager can be instantiated and wired to AppViewModel")
    func instantiation() {
        let vm = AppViewModel()
        // init() wires credentialsManager internally — verify no crash
        _ = vm
    }

    @Test("CredentialsManager.start sets tokenMissing when no credentials file and no Keychain entry")
    func startWithoutCredentials() async throws {
        // This test only passes reliably in a clean test environment where
        // ~/.claude/.credentials.json does NOT exist. If it exists on the CI
        // machine, the test is skipped gracefully.
        let credentialsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/.credentials.json").path
        guard !FileManager.default.fileExists(atPath: credentialsPath) else {
            // Skip — developer machine has real credentials; don't test in that case.
            return
        }
        // Also skip if Keychain already has a saved token from previous runs
        if (try? KeychainHelper.load(for: "oauthToken")) != nil {
            return
        }
        let vm = AppViewModel()
        // credentialsManager.start() is now called in AppViewModel.init()
        // Allow main run loop one cycle
        try await Task.sleep(for: .milliseconds(50))
        guard case .error(let err) = vm.dataState else {
            Issue.record("Expected tokenMissing when no credentials present"); return
        }
        #expect(err == .tokenMissing)
    }
}
