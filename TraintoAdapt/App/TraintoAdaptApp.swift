import SwiftUI

@main
struct TraintoAdaptApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var liveSession = LiveSessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(liveSession)
                .tint(Color.brandPrimary)
        }
    }
}
