import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "That email and password combination wasn't recognised."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signOut() async
}

/// Mock authentication. Any password is accepted for a seeded email address,
/// which lets the three roles be demoed without a real backend. Replace with
/// a networked implementation (e.g. Firebase Auth, or the company's own API)
/// by conforming a new type to `AuthServiceProtocol`.
@MainActor
final class MockAuthService: AuthServiceProtocol {
    private let store: MockDataStore

    init(store: MockDataStore? = nil) {
        self.store = store ?? .shared
    }

    func signIn(email: String, password: String) async throws -> User {
        try await Task.sleep(nanoseconds: 400_000_000)
        guard !password.isEmpty else { throw AuthError.invalidCredentials }
        guard let user = store.users.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw AuthError.invalidCredentials
        }
        return user
    }

    func signOut() async {
        _ = try? await Task.sleep(nanoseconds: 150_000_000)
    }
}
