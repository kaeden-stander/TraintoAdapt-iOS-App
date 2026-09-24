import Foundation

/// The single source of truth for the real (non-demo) sign-in state:
/// whether the client is authenticated with the live backend, and their
/// `/me` snapshot (profile, waiver status, plan, subscription, credits).
/// `RootView` shows the live client experience whenever `isSignedIn` is
/// true, independent of the mock `AppState` used by Demo Mode.
@MainActor
final class LiveSessionStore: ObservableObject {
    let auth: SupabaseAuthService
    let api: RemoteAPIClient

    @Published private(set) var me: MeResponse?
    @Published var isLoadingMe = false
    @Published var loadError: String?

    init(auth: SupabaseAuthService? = nil, api: RemoteAPIClient? = nil) {
        self.auth = auth ?? .shared
        self.api = api ?? .shared
    }

    var isSignedIn: Bool { auth.isSignedIn }

    /// True once `/me` has been fetched and the client's waiver is missing —
    /// booking is blocked until they sign it on the website.
    var needsWaiver: Bool { me?.waiver.signed == false }

    func refreshMe() async {
        guard isSignedIn else { return }
        isLoadingMe = true
        loadError = nil
        defer { isLoadingMe = false }
        do {
            me = try await api.me()
        } catch let error as APIError {
            if await handleIfUnauthorized(error) { return }
            loadError = error.message
        } catch {
            loadError = error.localizedDescription
        }
    }

    func signOut() async {
        await auth.signOut()
        me = nil
    }

    /// Centralises the "unauthorized → sign the client out" rule from the
    /// backend guide's error table, so every view model that calls the API
    /// can share it instead of re-implementing the check.
    @discardableResult
    func handleIfUnauthorized(_ error: APIError) async -> Bool {
        guard error.code == KnownAPIErrorCode.unauthorized.rawValue else { return false }
        await signOut()
        return true
    }
}
