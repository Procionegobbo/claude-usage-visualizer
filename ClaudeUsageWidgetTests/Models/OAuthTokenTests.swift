import Testing
import Foundation
@testable import ClaudeUsageWidget

// Story 1.2: Verify OAuthToken Codable round-trip for Keychain storage.

@Suite("OAuthToken model")
struct OAuthTokenTests {

    @Test("OAuthToken encodes and decodes with all fields")
    func codableRoundTripFull() throws {
        let original = OAuthToken(
            accessToken: "sk-ant-test",
            refreshToken: "sk-ant-refresh",
            expiresAt: Date(timeIntervalSince1970: 1_712_345_678)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OAuthToken.self, from: data)
        #expect(decoded.accessToken == original.accessToken)
        #expect(decoded.refreshToken == original.refreshToken)
        #expect(decoded.expiresAt?.timeIntervalSince1970 == original.expiresAt?.timeIntervalSince1970)
    }

    @Test("OAuthToken encodes and decodes with optional fields nil")
    func codableRoundTripMinimal() throws {
        let original = OAuthToken(accessToken: "sk-ant-only", refreshToken: nil, expiresAt: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(OAuthToken.self, from: data)
        #expect(decoded.accessToken == original.accessToken)
        #expect(decoded.refreshToken == nil)
        #expect(decoded.expiresAt == nil)
    }

    @Test("OAuthToken decoding fails gracefully on missing accessToken")
    func decodingFailsWithoutAccessToken() {
        let json = Data(#"{"refreshToken":"abc"}"#.utf8)
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(OAuthToken.self, from: json)
        }
    }

    // MARK: - Story 3.3: isExpired

    @Test("isExpired returns false when expiresAt is nil")
    func isExpiredWithNilDate() {
        let token = OAuthToken(accessToken: "sk-ant", refreshToken: nil, expiresAt: nil)
        #expect(token.isExpired == false)
    }

    @Test("isExpired returns true for past expiresAt")
    func isExpiredWithPastDate() {
        let past = Date(timeIntervalSinceNow: -3600)
        let token = OAuthToken(accessToken: "sk-ant", refreshToken: nil, expiresAt: past)
        #expect(token.isExpired == true)
    }

    @Test("isExpired returns false for future expiresAt")
    func isExpiredWithFutureDate() {
        let future = Date(timeIntervalSinceNow: 3600)
        let token = OAuthToken(accessToken: "sk-ant", refreshToken: nil, expiresAt: future)
        #expect(token.isExpired == false)
    }
}
