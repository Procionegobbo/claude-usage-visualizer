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
        let fd = open(credentialsPath, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
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

    // MARK: - Private JSON schema

    private struct CredentialsFile: Decodable {
        let claudeAiOauth: OAuthEntry

        struct OAuthEntry: Decodable {
            let accessToken: String
            let refreshToken: String?
            let expiresAt: Int?
        }
    }
}
