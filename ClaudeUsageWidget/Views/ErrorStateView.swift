import AppKit
import SwiftUI

struct ErrorBannerView: View {
    let error: AppError

    // MARK: - Derived display properties

    private var icon: String {
        switch error {
        case .tokenMissing:  return "xmark.circle"
        case .tokenExpired:  return "xmark.circle"
        case .apiUnreachable: return "clock.badge.exclamationmark"
        case .apiError:      return "exclamationmark.triangle"
        }
    }

    private var title: String {
        switch error {
        case .tokenMissing:   return "Claude Code not found"
        case .tokenExpired:   return "Authentication required"
        case .apiUnreachable: return "Data unavailable"
        case .apiError:       return "API error"
        }
    }

    private var description: String {
        switch error {
        case .tokenMissing:
            return "Install Claude Code and log in to use this app."
        case .tokenExpired:
            return "Your Claude session has expired."
        case .apiUnreachable(let lastSuccess):
            return "API unreachable. \(Self.lastUpdatedText(from: lastSuccess))Will retry automatically."
        case .apiError(let statusCode):
            return "API returned an error (status \(statusCode)). Will retry automatically."
        }
    }

    private var hasCTA: Bool {
        if case .tokenExpired = error { return true }
        return false
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title). \(description)")

            if hasCTA {
                Button("Open Claude Code") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Claude.app"))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .font(.caption)
                .accessibilityLabel("Open Claude Code to re-authenticate")
                .accessibilityHint("Opens Claude Code application")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    /// Returns a "Last updated X minutes ago. " prefix string, or "" if date is nil.
    /// `internal static` so tests can call it directly without SwiftUI rendering.
    /// Clamps minutes to non-negative value to handle clock skew or test edge cases.
    internal static func lastUpdatedText(from date: Date?, relativeTo now: Date = .now) -> String {
        guard let date else { return "" }
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        return "Last updated \(minutes) minute\(minutes == 1 ? "" : "s") ago. "
    }
}
