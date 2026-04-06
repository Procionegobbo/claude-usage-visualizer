import SwiftUI

struct UsageRingView: View {
    let utilization: Double  // 0–100
    let fillColor: Color
    let isDataAvailable: Bool  // false → show "—" regardless of utilization value

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { min(1.0, utilization / 100) }

    private var centerText: String {
        isDataAvailable ? "\(min(100, Int(utilization.rounded())))%" : "—"
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(lineWidth: 6)
                .foregroundStyle(.quaternary)

            // Fill arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .foregroundStyle(fillColor)
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(duration: 0.3), value: utilization)

            // Center percentage
            Text(centerText)
                .font(.title2.bold())
        }
        .frame(width: 56, height: 56)
    }
}
