import Foundation

/// The signed-in state for the real backend: a Supabase (GoTrue) access
/// token pair, persisted in the Keychain so the client stays signed in
/// across launches.
struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userID: String
    var email: String?

    var isExpired: Bool {
        Date.now >= expiresAt
    }

    /// Refresh a little before the real expiry so a request never races a
    /// token that's about to lapse mid-flight.
    var needsRefresh: Bool {
        Date.now >= expiresAt.addingTimeInterval(-60)
    }
}
