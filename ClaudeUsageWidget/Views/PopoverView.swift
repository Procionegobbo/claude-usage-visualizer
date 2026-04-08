import SwiftUI

struct PopoverView: View {
    @Environment(AppViewModel.self) private var viewModel

    // Extract window data when available (fresh or stale), nil otherwise
    private var windows: (five: UsageWindow, seven: UsageWindow)? {
        switch viewModel.dataState {
        case .fresh(let data): return (data.fiveHour, data.sevenDay)
        case .stale(let data, _): return (data.fiveHour, data.sevenDay)
        default: return nil
        }
    }

    private var updateAvailableBanner: some View {
        Button(action: {
            if let url = URL(string: "https://github.com/anthropics/claude-usage-visualizer/releases") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                Text("New version available — Download on GitHub")
                    .font(.callout.weight(.medium))
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isUpdateAvailable {
                updateAvailableBanner
                Divider()
            }
            if case .error(let error) = viewModel.dataState {
                ErrorBannerView(error: error)
                Divider()
            }
            if case .stale(let data, _) = viewModel.dataState {
                StaleIndicatorView(fetchedAt: data.fetchedAt)
                Divider()
            }
            UsageCardView(
                title: "5-hour window",
                utilization: windows?.five.utilization ?? 0,
                resetsAt: windows?.five.resetsAt,
                dataState: viewModel.dataState,
                threshold: viewModel.preferencesStore.fiveHourThreshold
            )
            Divider()
            UsageCardView(
                title: "7-day window",
                utilization: windows?.seven.utilization ?? 0,
                resetsAt: windows?.seven.resetsAt,
                dataState: viewModel.dataState,
                threshold: viewModel.preferencesStore.sevenDayThreshold
            )
            if viewModel.isShowingPreferences {
                Divider()
                PreferencesView()
            }
            HStack {
                Spacer()
                Button { viewModel.isShowingPreferences.toggle() } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Preferences")
            }
        }
        .frame(width: 280)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - StaleIndicatorView

private struct StaleIndicatorView: View {
    let fetchedAt: Date

    private var minutesAgo: Int {
        Int(Date.now.timeIntervalSince(fetchedAt) / 60)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
            Text("Last updated \(minutesAgo) minute\(minutesAgo == 1 ? "" : "s") ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
