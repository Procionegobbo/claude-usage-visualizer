import Foundation

struct OAuthToken: Sendable, Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}

extension OAuthToken {
    /// Returns true if the token is known to be expired.
    /// nil expiresAt is treated as "never expires" → returns false.
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date.now >= expiresAt
    }
}
