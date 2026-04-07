import Testing
@testable import ClaudeUsageWidget

@Suite("PollingScheduler")
@MainActor
struct PollingSchedulerTests {

    @Test("start(interval:) stores the interval in seconds")
    func startStoresInterval() {
        let scheduler = PollingScheduler()
        scheduler.start(interval: 300)
        #expect(scheduler.interval == 300)
    }

    @Test("start(interval:) creates a non-nil pollingTask")
    func startCreatesTask() {
        let scheduler = PollingScheduler()
        scheduler.start(interval: 300)
        #expect(scheduler.pollingTask != nil)
        scheduler.stop()
    }

    @Test("updateInterval(_:) updates interval without cancelling existing task")
    func updateIntervalKeepsTask() {
        let scheduler = PollingScheduler()
        scheduler.start(interval: 300)
        scheduler.updateInterval(600)
        #expect(scheduler.interval == 600)
        #expect(scheduler.pollingTask != nil)
        scheduler.stop()
    }

    @Test("stop() sets pollingTask to nil")
    func stopClearsTask() {
        let scheduler = PollingScheduler()
        scheduler.start(interval: 300)
        scheduler.stop()
        #expect(scheduler.pollingTask == nil)
    }

    @Test("restartImmediate() creates a non-nil pollingTask")
    func restartImmediateCreatesTask() {
        let scheduler = PollingScheduler()
        scheduler.restartImmediate()
        #expect(scheduler.pollingTask != nil)
        scheduler.stop()
    }

    @Test("start(interval:) uses default 5-minute interval when called without argument")
    func startDefaultInterval() {
        let scheduler = PollingScheduler()
        scheduler.start()
        #expect(scheduler.interval == 5 * 60)
        scheduler.stop()
    }
}
