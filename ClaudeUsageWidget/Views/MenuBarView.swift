import SwiftUI

struct MenuBarView: View {
    @Environment(AppViewModel.self) private var viewModel

    private var labelText: String {
        switch viewModel.dataState {
        case .fresh(let data), .stale(let data, _):
            return "5h \(min(100, Int(data.fiveHour.utilization.rounded())))%"
        default:
            return "5h —"
        }
    }

    private var labelColor: Color {
        switch viewModel.dataState {
        case .fresh(let data):
            let utilization = data.fiveHour.utilization
            let threshold = viewModel.preferencesStore.fiveHourThreshold
            if utilization >= 100 { return .red }
            if utilization >= threshold { return .orange }
            return .green
        case .stale:
            // Stale data: gray to indicate data freshness concern
            return .gray
        default:
            return .gray
        }
    }

    private var accessibilityText: String {
        switch viewModel.dataState {
        case .fresh(let data):
            return "Claude 5-hour usage: \(min(100, Int(data.fiveHour.utilization.rounded()))) percent"
        case .stale(let data, _):
            return "Claude 5-hour usage: \(min(100, Int(data.fiveHour.utilization.rounded()))) percent, data may be outdated"
        default:
            return "Claude 5-hour usage: unavailable"
        }
    }

    var body: some View {
        Text(labelText)
            .font(.system(size: 12, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(labelColor)
            .accessibilityLabel(accessibilityText)
    }
}
