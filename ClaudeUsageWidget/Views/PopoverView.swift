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

    var body: some View {
        VStack(spacing: 12) {
            UsageCardView(
                title: "5-hour window",
                utilization: windows?.five.utilization ?? 0,
                resetsAt: windows?.five.resetsAt,
                dataState: viewModel.dataState,
                threshold: 80.0
            )
            Divider()
            UsageCardView(
                title: "7-day window",
                utilization: windows?.seven.utilization ?? 0,
                resetsAt: windows?.seven.resetsAt,
                dataState: viewModel.dataState,
                threshold: 80.0
            )
        }
        .frame(width: 280)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
