import Foundation

struct OAuthToken: Sendable, Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
}
