import Foundation

/// Holds the signed-in user for the lifetime of the app. `RootView` observes
/// this to decide between showing `LoginView` and `RootTabView`.
@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: User?

    var isSignedIn: Bool { currentUser != nil }

    func signIn(as user: User) {
        currentUser = user
    }

    func signOut() {
        currentUser = nil
    }
}
