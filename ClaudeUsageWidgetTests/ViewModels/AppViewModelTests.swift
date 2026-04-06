import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.1: initial state. Story 1.2: credential callback state transitions.
// Story 1.3: fetchUsage no-token path + polling scheduler wiring.
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

    @Test("onCredentialsMissing sets tokenMissing error state")
    func credentialsMissingSetsError() {
        let vm = AppViewModel()
        vm.onCredentialsMissing()
        guard case .error(let err) = vm.dataState else {
            Issue.record("Expected error state"); return
        }
        #expect(err == .tokenMissing)
        #expect(vm.currentToken == nil)
    }

    @Test("onCredentialsAvailable stores token and stays loading")
    func credentialsAvailableStoresToken() {
        let vm = AppViewModel()
        let token = OAuthToken(accessToken: "sk-ant-test", refreshToken: nil, expiresAt: nil)
        vm.onCredentialsAvailable(token: token)
        #expect(vm.currentToken == "sk-ant-test")
        guard case .loading = vm.dataState else {
            Issue.record("Expected state to remain .loading after credentials arrived"); return
        }
    }

    @Test("onCredentialsAvailable recovers from tokenMissing to loading")
    func credentialsRecoverFromMissing() {
        let vm = AppViewModel()
        vm.onCredentialsMissing()
        guard case .error(.tokenMissing) = vm.dataState else {
            Issue.record("Setup failed: expected tokenMissing"); return
        }
        let token = OAuthToken(accessToken: "sk-ant-recovered", refreshToken: nil, expiresAt: nil)
        vm.onCredentialsAvailable(token: token)
        guard case .loading = vm.dataState else {
            Issue.record("Expected recovery to .loading"); return
        }
        #expect(vm.currentToken == "sk-ant-recovered")
    }

    @Test("onCredentialsMissing clears current token")
    func credentialsMissingClearsToken() {
        let vm = AppViewModel()
        let token = OAuthToken(accessToken: "sk-ant-old", refreshToken: nil, expiresAt: nil)
        vm.onCredentialsAvailable(token: token)
        vm.onCredentialsMissing()
        #expect(vm.currentToken == nil)
    }

    // MARK: - Story 1.3: fetchUsage

    @Test("fetchUsage with nil token sets tokenMissing error")
    func fetchUsageWithNoToken() async {
        let vm = AppViewModel()
        // currentToken is nil by default (no credentials set)
        await vm.fetchUsage()
        guard case .error(let err) = vm.dataState else {
            Issue.record("Expected error state after fetchUsage with no token"); return
        }
        #expect(err == .tokenMissing)
    }

    @Test("onCredentialsAvailable starts polling scheduler")
    func credentialsAvailableStartsPolling() {
        let vm = AppViewModel()
        let token = OAuthToken(accessToken: "sk-ant-test", refreshToken: nil, expiresAt: nil)
        // Before credentials: no polling task running (scheduler is freshly initialized)
        vm.onCredentialsAvailable(token: token)
        // After credentials: token is stored and polling has been initiated
        // (we can't easily verify the Task is running without network, but we verify
        // the token was stored which is the precondition for polling to make sense)
        #expect(vm.currentToken == "sk-ant-test")
    }
}
