import Foundation

// Stub — implemented in Story 1.2
enum KeychainError: Error {
    case notFound
    case saveFailed(OSStatus)
    case deleteFailed(OSStatus)
}

enum KeychainHelper {
    static func save(_ token: OAuthToken, for key: String) throws {
        #warning("Stub — must not ship unimplemented")
    }

    static func load(for key: String) throws -> OAuthToken {
        #warning("Stub — must not ship unimplemented")
        throw KeychainError.notFound
    }

    static func delete(for key: String) throws {
        #warning("Stub — must not ship unimplemented")
    }
}
