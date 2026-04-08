import AppKit
import Observation

@Observable
@MainActor
final class AppViewModel {
    var dataState: DataState = .loading
    private(set) var currentToken: String? = nil
    private var storedToken: OAuthToken? = nil
    var isShowingPreferences: Bool = false
    var isUpdateAvailable: Bool = false
    /// Prevents concurrent token refresh attempts.
    /// Although Boolean assignment is not CPU-atomic, it is safe here because:
    /// - @MainActor serializes all mutations on the main thread
    /// - Multiple fetchUsage() calls (polling + manual) execute serially via MainActor
    /// - The check-and-set window cannot be interleaved
    private var isRefreshingToken = false
    /// Prevents infinite refresh loops: once refresh fails with .tokenExpired,
    /// don't attempt another until new credentials arrive via onCredentialsAvailable.
    /// Transient network errors do NOT set this flag — those retry on next poll.
    private var hasRefreshFailedForCurrentToken = false

    let preferencesStore = PreferencesStore()
    private let notificationManager = NotificationManager()
    private let credentialsManager = CredentialsManager()
    private let usageService: UsageDataService
    let pollingScheduler = PollingScheduler()
    private nonisolated(unsafe) var wakeObserver: NSObjectProtocol?
    private var pollingIntervalObservationTask: Task<Void, Never>?

    init(usageService: UsageDataService = UsageDataService()) {
        self.usageService = usageService
        credentialsManager.viewModel = self
        pollingScheduler.viewModel = self
        credentialsManager.start()
        let checker = UpdateChecker(viewModel: self)
        checker.startChecking()
        startObservingPollingInterval()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in self?.pollingScheduler.restartImmediate() }
        }
    }

    @MainActor deinit {
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        pollingIntervalObservationTask?.cancel()
        pollingScheduler.stop()
    }

    private func startObservingPollingInterval() {
        // Cancel prior observation task to prevent accumulating observers
        pollingIntervalObservationTask?.cancel()

        pollingIntervalObservationTask = Task { @MainActor in
            withObservationTracking {
                _ = preferencesStore.pollingInterval
            } onChange: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.pollingScheduler.updateInterval(self.preferencesStore.pollingInterval * 60)
                    self.startObservingPollingInterval()
                }
            }
        }
    }

    func onCredentialsAvailable(token: OAuthToken) {
        storedToken = token
        currentToken = token.accessToken
        hasRefreshFailedForCurrentToken = false
        switch dataState {
        case .error(.tokenMissing), .error(.tokenExpired):
            dataState = .loading
        default: break
        }
        // Start polling only on first credential arrival (not on FSEvents rotations,
        // which go through onCredentialsChanged → pollingScheduler.restartImmediate()).
        if pollingScheduler.pollingTask == nil {
            pollingScheduler.start(interval: preferencesStore.pollingInterval * 60)
        }
    }

    func onCredentialsMissing() {
        storedToken = nil
        currentToken = nil
        isRefreshingToken = false
        dataState = .error(.tokenMissing)
        pollingScheduler.stop()
    }

    func onCredentialsChanged() {
        // Triggered after FSEvents fires and a valid token was loaded.
        // Restart polling immediately so the new token is used right away.
        pollingScheduler.restartImmediate()
    }

    func setUpdateAvailable(_ available: Bool) {
        isUpdateAvailable = available
    }

    func fetchUsage() async {
        guard let token = currentToken else {
            dataState = .error(.tokenMissing)
            return
        }
        // Pre-flight: check local expiry before making a network call
        if let stored = storedToken, stored.isExpired {
            await handleTokenExpired()
            return
        }
        do {
            let data = try await usageService.fetchUsage(token: token)
            dataState = .fresh(data)
            await notificationManager.evaluate(data: data, prefs: preferencesStore)
        } catch let error as AppError {
            if case .tokenExpired = error {
                await handleTokenExpired()
            } else if let data = Self.lastKnownData(from: dataState) {
                dataState = .stale(data, since: .now)
            } else {
                dataState = .error(error)
            }
        } catch {
            // URLError or other non-AppError → stale if prior data exists, else apiUnreachable.
            if let data = Self.lastKnownData(from: dataState) {
                dataState = .stale(data, since: .now)
            } else {
                dataState = .error(.apiUnreachable(lastSuccess: nil))
            }
        }
    }

    private func handleTokenExpired() async {
        // Guard against re-entrant calls: if refresh is already in progress, don't retry.
        guard !isRefreshingToken else { return }
        // Guard against refresh loop: if refresh already failed for this token, don't retry.
        guard !hasRefreshFailedForCurrentToken else {
            dataState = .error(.tokenExpired)
            return
        }
        guard let refreshToken = storedToken?.refreshToken else {
            dataState = .error(.tokenExpired)
            return
        }
        isRefreshingToken = true
        defer { isRefreshingToken = false }

        do {
            let newToken = try await credentialsManager.tryRefreshToken(refreshToken)
            storedToken = newToken
            currentToken = newToken.accessToken
            // Retry the fetch once with the new token
            let data = try await usageService.fetchUsage(token: newToken.accessToken)
            dataState = .fresh(data)
            await notificationManager.evaluate(data: data, prefs: preferencesStore)
        } catch let error as AppError {
            // Mark as permanently failed only for auth-related AppErrors
            if case .tokenExpired = error {
                hasRefreshFailedForCurrentToken = true
            }
            dataState = .error(.tokenExpired)
        } catch {
            // Transient errors (network timeout, etc) — set error but don't mark as permanently failed.
            // Next poll will retry the refresh.
            dataState = .error(.tokenExpired)
        }
    }

    /// Returns the last known `UsageData` if the current state has one (`.fresh` or `.stale`), nil otherwise.
    /// `internal static` for direct testability without SwiftUI rendering.
    internal static func lastKnownData(from dataState: DataState) -> UsageData? {
        switch dataState {
        case .fresh(let data): return data
        case .stale(let data, _): return data
        default: return nil
        }
    }
}
