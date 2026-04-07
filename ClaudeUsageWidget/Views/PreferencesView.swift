import SwiftUI

struct PreferencesView: View {
    @Environment(AppViewModel.self) private var viewModel

    var body: some View {
        @Bindable var prefs = viewModel.preferencesStore

        VStack(alignment: .leading, spacing: 16) {

            // MARK: - 5-hour window
            VStack(alignment: .leading, spacing: 8) {
                Text("5-hour window")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Toggle("Notify at threshold", isOn: $prefs.fiveHourNotificationsEnabled)
                    .font(.caption)
                    .accessibilityLabel("5-hour: notify at threshold")
                HStack {
                    Text("0%").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $prefs.fiveHourThreshold, in: 0...100, step: 1)
                    Text("100%").font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            // MARK: - 7-day window
            VStack(alignment: .leading, spacing: 8) {
                Text("7-day window")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Toggle("Notify at threshold", isOn: $prefs.sevenDayNotificationsEnabled)
                    .font(.caption)
                    .accessibilityLabel("7-day: notify at threshold")
                HStack {
                    Text("0%").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $prefs.sevenDayThreshold, in: 0...100, step: 1)
                    Text("100%").font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            // MARK: - Polling interval
            VStack(alignment: .leading, spacing: 8) {
                Text("Polling interval")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("1 min").font(.caption).foregroundStyle(.secondary)
                    Slider(value: $prefs.pollingInterval, in: 1...30, step: 1)
                    Text("30 min").font(.caption).foregroundStyle(.secondary)
                }
                Text("5 minutes recommended. Lower values increase API usage.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
}
