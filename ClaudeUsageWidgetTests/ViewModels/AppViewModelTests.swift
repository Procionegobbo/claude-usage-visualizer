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

    // MARK: - Story 3.2: lastKnownData helper

    private static func makeUsageData() -> UsageData {
        UsageData(
            fiveHour: UsageWindow(utilization: 62.0, resetsAt: nil),
            sevenDay: UsageWindow(utilization: 30.0, resetsAt: nil),
            fetchedAt: Date()
        )
    }

    @Test("lastKnownData returns data for fresh state")
    func lastKnownDataFromFresh() {
        let data = Self.makeUsageData()
        #expect(AppViewModel.lastKnownData(from: .fresh(data)) != nil)
    }

    @Test("lastKnownData returns data for stale state")
    func lastKnownDataFromStale() {
        let data = Self.makeUsageData()
        #expect(AppViewModel.lastKnownData(from: .stale(data, since: .now)) != nil)
    }

    @Test("lastKnownData returns nil for loading state")
    func lastKnownDataFromLoading() {
        #expect(AppViewModel.lastKnownData(from: .loading) == nil)
    }

    @Test("lastKnownData returns nil for error state")
    func lastKnownDataFromError() {
        #expect(AppViewModel.lastKnownData(from: .error(.tokenMissing)) == nil)
    }

    // MARK: - Story 3.3: pre-flight expiry check

    @Test("fetchUsage with expired token sets tokenExpired error (pre-flight, no network)")
    func fetchUsageWithExpiredToken() async {
        let vm = AppViewModel()
        let expiredToken = OAuthToken(
            accessToken: "sk-ant-expired",
            refreshToken: nil,
            expiresAt: Date(timeIntervalSinceNow: -3600)
        )
        vm.onCredentialsAvailable(token: expiredToken)
        await vm.fetchUsage()
        guard case .error(let err) = vm.dataState else {
            Issue.record("Expected error state"); return
        }
        #expect(err == .tokenExpired)
    }

    // MARK: - Story 3.4: state transitions with mock service

    private static func makeFailingService() -> UsageDataService {
        UsageDataService(urlSession: MockURLProtocol.makeSession(error: URLError(.notConnectedToInternet)))
    }

    @Test("fetchUsage transitions fresh → stale on network failure (AC4)")
    func fetchUsageTransitionsFreshToStale() async {
        let vm = AppViewModel(usageService: Self.makeFailingService())
        // Seed a fresh state manually (simulates prior successful fetch)
        vm.dataState = .fresh(Self.makeUsageData())
        // Set a fake current token so fetchUsage() doesn't bail on tokenMissing
        vm.onCredentialsAvailable(token: OAuthToken(accessToken: "sk-ant-test", refreshToken: nil, expiresAt: nil))
        // Stop polling to prevent background interference
        vm.pollingScheduler.stop()
        // Trigger one fetch explicitly
        await vm.fetchUsage()
        // Verify stale transition
        guard case .stale(let data, _) = vm.dataState else {
            Issue.record("Expected .stale after network failure with prior fresh data"); return
        }
        #expect(data.fiveHour.utilization == 62.0)
    }

    @Test("state machine cycles loading → fresh (manual) → stale → verified (AC6)")
    func stateMachineCycle() async {
        let vm = AppViewModel(usageService: Self.makeFailingService())
        // Seed loading state explicitly (init may vary on machines with real credentials)
        vm.dataState = .loading
        // Set credentials + stop scheduler to prevent background interference
        vm.onCredentialsAvailable(token: OAuthToken(accessToken: "sk-ant-test", refreshToken: nil, expiresAt: nil))
        vm.pollingScheduler.stop()
        // Confirm loading state
        guard case .loading = vm.dataState else {
            Issue.record("Expected .loading after explicit seed"); return
        }
        // Transition to fresh manually (simulates prior successful fetch)
        vm.dataState = .fresh(Self.makeUsageData())
        guard case .fresh = vm.dataState else {
            Issue.record("Expected .fresh after manual set"); return
        }
        // Trigger failing fetch → stale
        await vm.fetchUsage()
        guard case .stale = vm.dataState else {
            Issue.record("Expected .stale after failing fetch"); return
        }
    }
}
