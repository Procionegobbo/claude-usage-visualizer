import Foundation

enum DataState: Equatable, Sendable {
    case loading
    case fresh(UsageData)
    case stale(UsageData, since: Date)
    case error(AppError)
}
