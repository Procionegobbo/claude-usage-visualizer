import AppKit
import Observation

@Observable
@MainActor
final class AppViewModel {
    var dataState: DataState = .loading
    private(set) var currentToken: String? = nil
    var isShowingPreferences: Bool = false

    let preferencesStore = PreferencesStore()
    private let notificationManager = NotificationManager()
    private let credentialsManager = CredentialsManager()
    private let usageService = UsageDataService()
    private let pollingScheduler = PollingScheduler()
    private var wakeObserver: NSObjectProtocol?

    init() {
        credentialsManager.viewModel = self
        pollingScheduler.viewModel = self
        credentialsManager.start()
        startObservingPollingInterval()
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.pollingScheduler.restartImmediate()
            }
        }
    }

    private func startObservingPollingInterval() {
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

    func onCredentialsAvailable(token: OAuthToken) {
        currentToken = token.accessToken
        if case .error(.tokenMissing) = dataState {
            dataState = .loading
        }
        // Start polling only on first credential arrival (not on FSEvents rotations,
        // which go through onCredentialsChanged → pollingScheduler.restartImmediate()).
        if pollingScheduler.pollingTask == nil {
            pollingScheduler.start(interval: preferencesStore.pollingInterval * 60)
        }
    }

    func onCredentialsMissing() {
        currentToken = nil
        dataState = .error(.tokenMissing)
        pollingScheduler.stop()
    }

    func onCredentialsChanged() {
        // Triggered after FSEvents fires and a valid token was loaded.
        // Restart polling immediately so the new token is used right away.
        pollingScheduler.restartImmediate()
    }

    func fetchUsage() async {
        guard let token = currentToken else {
            dataState = .error(.tokenMissing)
            return
        }
        do {
            let data = try await usageService.fetchUsage(token: token)
            dataState = .fresh(data)
            await notificationManager.evaluate(data: data, prefs: preferencesStore)
        } catch let error as AppError {
            dataState = .error(error)
        } catch {
            // URLError or other non-AppError → treat as API unreachable.
            // Story 3.2 will refine this to transition to .stale when fresh data exists.
            dataState = .error(.apiUnreachable(lastSuccess: nil))
        }
    }
}
