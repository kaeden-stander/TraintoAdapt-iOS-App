import SwiftUI

/// Three states: signed in for real (Supabase-backed client experience),
/// signed in via Demo Mode (mock data, any role), or signed out.
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: SupabaseAuthService
    @EnvironmentObject private var liveSession: LiveSessionStore

    var body: some View {
        Group {
            if authService.isSignedIn {
                LiveClientTabView(session: liveSession)
                    .transition(.opacity)
            } else if let user = appState.currentUser {
                RootTabView(user: user)
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authService.isSignedIn)
        .animation(.easeInOut(duration: 0.25), value: appState.isSignedIn)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(SupabaseAuthService.shared)
        .environmentObject(LiveSessionStore())
}
