import SwiftUI

struct UsageCardView: View {
    let title: String
    let utilization: Double
    let resetsAt: Date?
    let dataState: DataState
    let threshold: Double

    /// Returns the semantic fill color for a given utilization and threshold.
    /// - Parameters:
    ///   - utilization: Current usage percentage (0–100+).
    ///   - threshold: Warning threshold percentage (e.g. 80.0).
    internal static func semanticColor(for utilization: Double, threshold: Double) -> Color {
        if utilization >= 100 { return .red }
        if utilization >= threshold { return .orange }
        return .green
    }

    private var ringFillColor: Color {
        switch dataState {
        case .fresh:
            return Self.semanticColor(for: utilization, threshold: threshold)
        case .stale:
            return .gray
        case .loading:
            return .gray.opacity(0.3)
        case .error:
            return .gray
        }
    }

    private var ringUtilization: Double {
        switch dataState {
        case .fresh, .stale:
            return utilization
        case .loading, .error:
            return 0
        }
    }

    private var isDataAvailable: Bool {
        switch dataState {
        case .fresh, .stale: return true
        case .loading, .error: return false
        }
    }

    private var accessibilityDescription: String {
        guard isDataAvailable else {
            return "\(title), unavailable"
        }
        let percent = min(100, Int(utilization.rounded()))
        let countdown = Self.accessibilityCountdownText(from: resetsAt) ?? ""
        return countdown.isEmpty
            ? "\(title), \(percent)% used"
            : "\(title), \(percent)% used, \(countdown)"
    }

    var body: some View {
        HStack(spacing: 12) {
            UsageRingView(utilization: ringUtilization, fillColor: ringFillColor, isDataAvailable: isDataAvailable)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                if let countdown = Self.countdownText(from: resetsAt) {
                    Text(countdown)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    /// Formats the reset countdown for display labels (abbreviated: "Resets in 1h 30m").
    /// Returns nil when resetsAt is nil (label hidden).
    internal static func countdownText(from resetsAt: Date?, relativeTo now: Date = .now) -> String? {
        guard let resetsAt else { return nil }
        let interval = resetsAt.timeIntervalSince(now)
        guard interval > 0 else { return "Resets soon" }
        if interval < 5 * 60 { return "Resets soon" }
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 60 {
            return "Resets in \(totalMinutes)m"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "Resets in \(hours)h \(minutes)m"
    }

    /// Formats the reset countdown for VoiceOver (spelled out: "resets in 1 hour 30 minutes").
    /// Returns nil when resetsAt is nil.
    internal static func accessibilityCountdownText(from resetsAt: Date?, relativeTo now: Date = .now) -> String? {
        guard let resetsAt else { return nil }
        let interval = resetsAt.timeIntervalSince(now)
        guard interval > 0 else { return "resets soon" }
        if interval < 5 * 60 { return "resets soon" }
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 60 {
            // totalMinutes is always >= 5 here (< 5 returns "resets soon"), so always plural.
            return "resets in \(totalMinutes) minutes"
        }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let hourWord = h == 1 ? "hour" : "hours"
        if m == 0 {
            return "resets in \(h) \(hourWord)"
        }
        return "resets in \(h) \(hourWord) \(m) \(m == 1 ? "minute" : "minutes")"
    }
}
