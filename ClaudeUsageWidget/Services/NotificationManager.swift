import Foundation
import UserNotifications

@MainActor
final class NotificationManager {

    private var fiveHourPreviousUtilization: Double? = nil
    private var sevenDayPreviousUtilization: Double? = nil

    internal enum CrossingEvent {
        case thresholdCrossed
        case limitCrossed
    }

    private struct NotificationSpec {
        let id: String
        let title: String
        let body: String
    }

    /// Pure function — fully testable without UNUserNotificationCenter.
    /// Limit crossing takes priority over threshold crossing.
    /// Returns nil if no crossing occurred (including when already above threshold).
    internal nonisolated static func crossingEvent(
        previous: Double,
        current: Double,
        threshold: Double
    ) -> CrossingEvent? {
        if previous < 100 && current >= 100 { return .limitCrossed }
        if previous < threshold && current >= threshold { return .thresholdCrossed }
        return nil
    }

    /// Formats a reset countdown for notification body. Returns "" if resetsAt is nil.
    internal nonisolated static func resetSuffix(from resetsAt: Date?, relativeTo now: Date = .now) -> String {
        guard let resetsAt else { return "" }
        let interval = resetsAt.timeIntervalSince(now)
        guard interval >= 60 else { return "Resets soon" }
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 60 { return "Resets in \(totalMinutes)m" }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m == 0 ? "Resets in \(h)h" : "Resets in \(h)h \(m)m"
    }

    /// Pure synchronous decision — determines what notification (if any) to send.
    /// Returns nil on baseline eval (previous == nil), disabled, or no crossing.
    private static func notificationSpec(
        previous: Double?,
        current: Double,
        resetsAt: Date?,
        threshold: Double,
        enabled: Bool,
        thresholdID: String,
        limitID: String,
        windowLabel: String
    ) -> NotificationSpec? {
        guard let previous else { return nil }
        guard enabled else { return nil }
        guard let event = crossingEvent(previous: previous, current: current, threshold: threshold) else { return nil }
        let suffix = resetSuffix(from: resetsAt)
        switch event {
        case .thresholdCrossed:
            let pct = min(100, Int(current.rounded()))
            return NotificationSpec(id: thresholdID, title: "\(windowLabel) usage at \(pct)%", body: suffix)
        case .limitCrossed:
            return NotificationSpec(id: limitID, title: "\(windowLabel) limit reached", body: suffix)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied: return false
        @unknown default: return false
        }
    }

    private func sendNotification(id: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        if !body.isEmpty { content.body = body }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func evaluate(data: UsageData, prefs: PreferencesStore) async {
        // Compute specs for both windows (pure, no side effects) before any async work.
        let fivePrev = fiveHourPreviousUtilization
        let fiveCurrent = data.fiveHour.utilization
        fiveHourPreviousUtilization = fiveCurrent
        let fiveSpec = Self.notificationSpec(
            previous: fivePrev,
            current: fiveCurrent,
            resetsAt: data.fiveHour.resetsAt,
            threshold: prefs.fiveHourThreshold,
            enabled: prefs.fiveHourNotificationsEnabled,
            thresholdID: NotificationID.fiveHourThreshold,
            limitID: NotificationID.fiveHourLimit,
            windowLabel: "5-hour"
        )

        let sevenPrev = sevenDayPreviousUtilization
        let sevenCurrent = data.sevenDay.utilization
        sevenDayPreviousUtilization = sevenCurrent
        let sevenSpec = Self.notificationSpec(
            previous: sevenPrev,
            current: sevenCurrent,
            resetsAt: data.sevenDay.resetsAt,
            threshold: prefs.sevenDayThreshold,
            enabled: prefs.sevenDayNotificationsEnabled,
            thresholdID: NotificationID.sevenDayThreshold,
            limitID: NotificationID.sevenDayLimit,
            windowLabel: "7-day"
        )

        guard fiveSpec != nil || sevenSpec != nil else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        if let spec = fiveSpec {
            await sendNotification(id: spec.id, title: spec.title, body: spec.body)
        }
        if let spec = sevenSpec {
            await sendNotification(id: spec.id, title: spec.title, body: spec.body)
        }
    }
}

enum NotificationID {
    private static let base = Bundle.main.bundleIdentifier ?? "com.procionegobbo.ClaudeUsageWidget"
    static let fiveHourThreshold = "\(base).fiveHour.threshold"
    static let fiveHourLimit     = "\(base).fiveHour.limit"
    static let sevenDayThreshold = "\(base).sevenDay.threshold"
    static let sevenDayLimit     = "\(base).sevenDay.limit"
}
