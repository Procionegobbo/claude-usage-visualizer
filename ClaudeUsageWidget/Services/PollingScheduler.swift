import Foundation

@MainActor
final class PollingScheduler {
    weak var viewModel: AppViewModel?

    private(set) var pollingTask: Task<Void, Never>?
    private(set) var interval: TimeInterval = 5 * 60  // 5 minutes default

    /// Start (or restart) polling at the given interval.
    /// Cancels any existing task before starting a new one.
    func start(interval: TimeInterval = 5 * 60) {
        self.interval = interval
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await viewModel?.fetchUsage()
                do {
                    try await Task.sleep(for: .seconds(self.interval))
                } catch {
                    return
                }
            }
        }
    }

    /// Cancel current task and start a new one immediately (used on credential rotation).
    /// The new task fetches on the first iteration without waiting for the interval.
    func restartImmediate() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await viewModel?.fetchUsage()
                do {
                    try await Task.sleep(for: .seconds(self.interval))
                } catch {
                    return
                }
            }
        }
    }

    /// Stop polling and release the task.
    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
