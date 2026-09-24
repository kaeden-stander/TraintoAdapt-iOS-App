import SwiftUI

/// Switches between the signed-out and signed-in experience. Once signed in,
/// `RootTabView` picks the tab set for the user's role.
struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if let user = appState.currentUser {
                RootTabView(user: user)
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isSignedIn)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
