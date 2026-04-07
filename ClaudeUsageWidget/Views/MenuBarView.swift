import SwiftUI

struct MenuBarView: View {
    @Environment(AppViewModel.self) private var viewModel

    private var labelText: String {
        guard case .fresh(let data) = viewModel.dataState else { return "5h —" }
        return "5h \(min(100, Int(data.fiveHour.utilization.rounded())))%"
    }

    private var labelColor: Color {
        guard case .fresh(let data) = viewModel.dataState else { return .gray }
        let utilization = data.fiveHour.utilization
        let threshold = viewModel.preferencesStore.fiveHourThreshold
        if utilization >= 100 { return .red }
        if utilization >= threshold { return .orange }
        return .green
    }

    private var accessibilityText: String {
        guard case .fresh(let data) = viewModel.dataState else {
            return "Claude 5-hour usage: unavailable"
        }
        return "Claude 5-hour usage: \(min(100, Int(data.fiveHour.utilization.rounded()))) percent"
    }

    var body: some View {
        Text(labelText)
            .font(.system(size: 12, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(labelColor)
            .accessibilityLabel(accessibilityText)
    }
}
