import Foundation

enum AppError: Error, Equatable, Sendable {
    case tokenMissing
    case tokenExpired
    case apiUnreachable(lastSuccess: Date?)
    case apiError(statusCode: Int)
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .tokenMissing:
            return "Install Claude Code and log in to use this app."
        case .tokenExpired:
            return "Your Claude session has expired."
        case .apiUnreachable(let lastSuccess):
            let suffix = lastSuccess.map { d in
                Self.minutesSinceText(d) + " "
            } ?? ""
            return "API unreachable. \(suffix)Will retry automatically."
        case .apiError(let statusCode):
            return "API returned an error (status \(statusCode)). Will retry automatically."
        }
    }

    /// Formats "Last updated X minute(s) ago" with proper plural handling and non-negative bounds.
    private static func minutesSinceText(_ date: Date, relativeTo now: Date = .now) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        return "Last updated \(minutes) minute\(minutes == 1 ? "" : "s") ago."
    }
}
