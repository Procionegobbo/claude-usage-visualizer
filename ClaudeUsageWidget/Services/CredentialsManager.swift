import Foundation

@MainActor
final class CredentialsManager {
    weak var viewModel: AppViewModel?

    private var hasStarted = false
    private var fileSource: DispatchSourceFileSystemObject?

    private let credentialsPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/.credentials.json"
    }()

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        // Warm start: token already in Keychain
        if let token = try? KeychainHelper.load(for: "oauthToken") {
            viewModel?.onCredentialsAvailable(token: token)
        } else {
            // Cold start: read from credentials file
            readCredentialsFile()
        }
        setupFileMonitor()
    }

    deinit {
        fileSource?.cancel()
    }

    func readCredentialsFile() {
        guard let data = FileManager.default.contents(atPath: credentialsPath) else {
            viewModel?.onCredentialsMissing()
            return
        }
        do {
            let file = try JSONDecoder().decode(CredentialsFile.self, from: data)
            let entry = file.claudeAiOauth
            let token = OAuthToken(
                accessToken: entry.accessToken,
                refreshToken: entry.refreshToken,
                expiresAt: entry.expiresAt.map { Date(timeIntervalSince1970: Double($0) / 1000.0) }
            )
            do {
                try KeychainHelper.save(token, for: "oauthToken")
            } catch {
                #if DEBUG
                print("[CredentialsManager] Keychain save failed: \(error)")
                #endif
            }
            viewModel?.onCredentialsAvailable(token: token)
        } catch {
            viewModel?.onCredentialsMissing()
        }
    }

    private func setupFileMonitor() {
        // Monitor the parent directory (~/.claude/) instead of the file itself.
        // This handles: atomic rename (Claude CLI credential rotation), file creation after launch.
        let dirPath = URL(fileURLWithPath: credentialsPath)
            .deletingLastPathComponent().path
        let fd = open(dirPath, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.readCredentialsFile()
                // Only signal change if a valid token was loaded
                if self.viewModel?.currentToken != nil {
                    self.viewModel?.onCredentialsChanged()
                }
            }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileSource = source
    }

    /// Attempts an OAuth refresh token grant. Saves the new token to Keychain on success.
    /// Throws on network error or non-200 response.
    func tryRefreshToken(_ refreshToken: String) async throws -> OAuthToken {
        guard let url = URL(string: "https://console.anthropic.com/v1/oauth/token") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // Percent-encode the refresh token to handle any special characters safely
        let encodedToken = refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? refreshToken
        let body = "grant_type=refresh_token&refresh_token=\(encodedToken)"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        let newToken = OAuthToken(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken ?? refreshToken,  // preserve if not rotated
            expiresAt: decoded.expiresIn.map { Date.now.addingTimeInterval(Double($0)) }
        )
        try? KeychainHelper.save(newToken, for: "oauthToken")
        return newToken
    }

    // MARK: - Private JSON schema

    private struct CredentialsFile: Decodable {
        let claudeAiOauth: OAuthEntry

        struct OAuthEntry: Decodable {
            let accessToken: String
            let refreshToken: String?
            let expiresAt: Int?
        }
    }

    private struct RefreshResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }
}
