import SwiftUI

@main
struct ClaudeUsageWidgetApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(appViewModel)
        } label: {
            Text("—")
        }
        .menuBarExtraStyle(.window)
    }
}
