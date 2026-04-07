import Foundation

@MainActor
final class PollingScheduler {
    weak var viewModel: AppViewModel?

    private(set) var pollingTask: Task<Void, Never>?
    /// Stored in **seconds**. Callers convert from minutes (× 60) before passing.
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

    /// Update the polling interval without restarting the current task.
    /// The new interval takes effect on the next sleep cycle (no premature fetch).
    /// `newInterval` is in **seconds**.
    func updateInterval(_ newInterval: TimeInterval) {
        self.interval = newInterval
    }

    /// Stop polling and release the task.
    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
