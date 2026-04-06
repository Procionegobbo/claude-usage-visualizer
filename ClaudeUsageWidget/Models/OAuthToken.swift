import Foundation

struct OAuthToken: Sendable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}
