import Foundation

extension DateFormatter {
}

extension ISO8601DateFormatter {
    /// Parses Anthropic API dates: "2025-11-04T04:59:59.943648+00:00" (with fractional seconds).
    nonisolated(unsafe) static let anthropicApiDate: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Fallback for API dates without fractional seconds.
    nonisolated(unsafe) static let anthropicApiFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
