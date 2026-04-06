import Foundation

enum AppError: Error, Equatable, Sendable {
    case tokenMissing
    case tokenExpired
    case apiUnreachable(lastSuccess: Date?)
    case apiError(statusCode: Int)
}
