import Foundation

struct UsageData: Equatable, Sendable {
    let fiveHour: UsageWindow
    let sevenDay: UsageWindow
    let fetchedAt: Date
}

struct UsageWindow: Equatable, Sendable {
    let utilization: Double  // 0.0–100.0
    let resetsAt: Date?
}
