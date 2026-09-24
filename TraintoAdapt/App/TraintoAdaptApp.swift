import SwiftUI

@main
struct TraintoAdaptApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .tint(Color.brandPrimary)
        }
    }
}
