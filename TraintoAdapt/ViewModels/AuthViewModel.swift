import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSigningIn = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isSigningIn
    }

    func signIn(into appState: AppState) async {
        guard canSubmit else { return }
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }
        do {
            let user = try await authService.signIn(email: email, password: password)
            appState.signIn(as: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Lets the login screen offer one-tap demo access to each role.
    func fillDemoCredentials(for role: UserRole) {
        switch role {
        case .client: email = "client@traintoadapt.co.uk"
        case .trainer: email = "trainer@traintoadapt.co.uk"
        case .admin: email = "admin@traintoadapt.co.uk"
        }
        password = "demo"
    }
}
