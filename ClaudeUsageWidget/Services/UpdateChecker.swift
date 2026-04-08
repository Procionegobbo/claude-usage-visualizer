import Foundation

@MainActor
final class UpdateChecker {
    private weak var viewModel: AppViewModel?
    private var isChecking = false

    init(viewModel: AppViewModel?) {
        self.viewModel = viewModel
    }

    func startChecking() {
        guard !isChecking else { return }
        isChecking = true

        Task {
            while true {
                await checkForUpdates()
                try? await Task.sleep(for: .seconds(24 * 60 * 60))
            }
        }
    }

    private func checkForUpdates() async {
        await checkForUpdates(session: URLSession.shared)
    }

    internal func checkForUpdates(session: URLSession) async {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        guard let url = URL(string: "https://api.github.com/repos/anthropics/claude-usage-visualizer/releases/latest") else {
            return
        }

        do {
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            let release = try decoder.decode(GitHubRelease.self, from: data)

            // Reject empty tag or pre-release versions (not semver-compliant)
            guard !release.tag_name.isEmpty && !release.tag_name.contains("-") else {
                return
            }

            let isNewer = isNewerVersion(release.tag_name, than: currentVersion)
            viewModel?.setUpdateAvailable(isNewer)
        } catch {
            // Silent failure on all errors: network, parse, 404, etc.
        }
    }

    private func isNewerVersion(_ remote: String, than local: String) -> Bool {
        // remote: "v1.2.3", local: "1.0.5"
        // Strip leading 'v' from remote
        let remoteVer = remote.hasPrefix("v") ? String(remote.dropFirst()) : remote

        let remoteParts = remoteVer.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }

        // Compare [major, minor, patch]
        let remoteTriple = (remoteParts.count > 0 ? remoteParts[0] : 0,
                            remoteParts.count > 1 ? remoteParts[1] : 0,
                            remoteParts.count > 2 ? remoteParts[2] : 0)
        let localTriple = (localParts.count > 0 ? localParts[0] : 0,
                           localParts.count > 1 ? localParts[1] : 0,
                           localParts.count > 2 ? localParts[2] : 0)

        if remoteTriple.0 != localTriple.0 { return remoteTriple.0 > localTriple.0 }
        if remoteTriple.1 != localTriple.1 { return remoteTriple.1 > localTriple.1 }
        return remoteTriple.2 > localTriple.2
    }

    private struct GitHubRelease: Decodable {
        let tag_name: String
    }
}
