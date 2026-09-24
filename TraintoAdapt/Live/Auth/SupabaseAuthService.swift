import Foundation
import AuthenticationServices
import UIKit

enum SignUpOutcome: Hashable {
    case signedIn
    case confirmationEmailSent
}

/// Talks to Supabase's GoTrue auth REST API directly (no Supabase SDK
/// dependency, matching the pattern the backend guide's own API examples
/// use). Supports email/password, native Sign in with Apple (id_token
/// grant) and Sign in with Google (PKCE browser flow via
/// ASWebAuthenticationSession), and persists the session in the Keychain.
@MainActor
final class SupabaseAuthService: NSObject, ObservableObject {
    static let shared = SupabaseAuthService()

    @Published private(set) var session: AuthSession?

    private let urlSession = URLSession(configuration: .ephemeral)
    private var webAuthSession: ASWebAuthenticationSession?

    override init() {
        super.init()
        session = KeychainTokenStore.load()
    }

    var isSignedIn: Bool { session != nil }

    /// Appends the current session's tokens to a `client.traintoadapt.co.uk`
    /// URL as a fragment, in the same shape Supabase's own auth redirects
    /// use (`#access_token=...&refresh_token=...`). Most Supabase-backed
    /// web apps auto-detect and sign in from this on page load, so opening
    /// the waiver or the client portal in Safari doesn't ask the person to
    /// log in again. Only applied to the app's own portal domain — Stripe
    /// checkout/billing-portal links are already pre-authenticated and are
    /// left untouched.
    func authenticatedURL(_ url: URL) -> URL {
        guard let session, url.host == AppConfig.portal.host,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        let expiresIn = max(1, Int(session.expiresAt.timeIntervalSinceNow))
        components.fragment = [
            "access_token=\(session.accessToken)",
            "refresh_token=\(session.refreshToken)",
            "expires_in=\(expiresIn)",
            "token_type=bearer"
        ].joined(separator: "&")
        return components.url ?? url
    }

    // MARK: - Email / password

    func signIn(email: String, password: String) async throws {
        let response: GoTrueTokenResponse = try await tokenRequest(
            grantType: "password",
            body: ["email": email, "password": password]
        )
        store(response)
    }

    func signUp(email: String, password: String, fullName: String) async throws -> SignUpOutcome {
        var request = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/signup"))
        request.httpMethod = "POST"
        applyCommonHeaders(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ])

        let (data, http) = try await send(request)
        try throwIfError(data: data, response: http)

        if let response = try? JSONDecoder.goTrue.decode(GoTrueTokenResponse.self, from: data) {
            store(response)
            return .signedIn
        }
        return .confirmationEmailSent
    }

    func resetPassword(email: String) async throws {
        var request = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/recover"))
        request.httpMethod = "POST"
        applyCommonHeaders(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        let (data, http) = try await send(request)
        try throwIfError(data: data, response: http)
    }

    // MARK: - Sign in with Apple (native)

    func signInWithApple(idToken: String, rawNonce: String) async throws {
        let response: GoTrueTokenResponse = try await tokenRequest(
            grantType: "id_token",
            body: ["provider": "apple", "id_token": idToken, "nonce": rawNonce]
        )
        store(response)
    }

    // MARK: - Sign in with Google (PKCE browser flow)

    func signInWithGoogle() async throws {
        let codeVerifier = CryptoHelpers.randomURLSafeString(length: 48)
        let codeChallenge = CryptoHelpers.base64URLEncode(CryptoHelpers.sha256(codeVerifier))

        var components = URLComponents(
            url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/authorize"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: AppConfig.authCallbackURL.absoluteString),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        let callbackURL = try await presentWebAuthSession(url: components.url!)
        let response = try await exchangePKCECode(from: callbackURL, codeVerifier: codeVerifier)
        store(response)
    }

    private func presentWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "traintoadapt"
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: AuthServiceError(
                        message: (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                            ? "Sign-in was cancelled."
                            : (error?.localizedDescription ?? "Sign-in failed.")
                    ))
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.webAuthSession = session
            session.start()
        }
    }

    private func exchangePKCECode(from callbackURL: URL, codeVerifier: String) async throws -> GoTrueTokenResponse {
        // PKCE returns ?code=... in the query string.
        if let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" })?.value {
            var request = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/token"))
            request.httpMethod = "POST"
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "grant_type", value: "pkce")]
            request.url = components.url
            applyCommonHeaders(&request)
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "auth_code": code,
                "code_verifier": codeVerifier
            ])
            let (data, http) = try await send(request)
            try throwIfError(data: data, response: http)
            return try JSONDecoder.goTrue.decode(GoTrueTokenResponse.self, from: data)
        }

        // Fall back to the implicit flow, in case PKCE isn't enabled for this project:
        // tokens arrive directly in the URL fragment instead of a code.
        if let fragment = callbackURL.fragment {
            let params = fragment
                .split(separator: "&")
                .reduce(into: [String: String]()) { result, pair in
                    let parts = pair.split(separator: "=", maxSplits: 1)
                    guard parts.count == 2 else { return }
                    result[String(parts[0])] = String(parts[1]).removingPercentEncoding
                }
            if let accessToken = params["access_token"],
               let refreshToken = params["refresh_token"],
               let expiresIn = params["expires_in"].flatMap(Int.init) {
                return GoTrueTokenResponse(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: expiresIn,
                    user: GoTrueUser(id: params["user_id"] ?? "", email: nil)
                )
            }
        }

        let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let description = queryItems.first(where: { $0.name == "error_description" })?.value {
            throw AuthServiceError(message: description.replacingOccurrences(of: "+", with: " "))
        }
        throw AuthServiceError(message: "Sign-in didn't complete. Please try again.")
    }

    // MARK: - Session lifecycle

    /// Returns a bearer token guaranteed valid for at least another minute,
    /// refreshing it first if needed. Used by `RemoteAPIClient` before every
    /// authenticated request.
    func validAccessToken() async throws -> String {
        guard let current = session else {
            throw AuthServiceError(message: "You're signed out. Please sign in again.")
        }
        guard current.needsRefresh else { return current.accessToken }

        let response: GoTrueTokenResponse = try await tokenRequest(
            grantType: "refresh_token",
            body: ["refresh_token": current.refreshToken]
        )
        store(response)
        return response.accessToken
    }

    func signOut() async {
        if let token = session?.accessToken {
            var request = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/logout"))
            request.httpMethod = "POST"
            applyCommonHeaders(&request)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await send(request)
        }
        session = nil
        KeychainTokenStore.clear()
    }

    // MARK: - Shared request plumbing

    private func tokenRequest(grantType: String, body: [String: Any]) async throws -> GoTrueTokenResponse {
        var request = URLRequest(url: AppConfig.supabaseURL.appendingPathComponent("auth/v1/token"))
        request.httpMethod = "POST"
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: grantType)]
        request.url = components.url
        applyCommonHeaders(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, http) = try await send(request)
        try throwIfError(data: data, response: http)
        return try JSONDecoder.goTrue.decode(GoTrueTokenResponse.self, from: data)
    }

    private func applyCommonHeaders(_ request: inout URLRequest) {
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthServiceError(message: "Unexpected response from the server.")
        }
        return (data, http)
    }

    private func throwIfError(data: Data, response: HTTPURLResponse) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        let message = (try? JSONDecoder().decode(GoTrueErrorResponse.self, from: data))?.displayMessage
        throw AuthServiceError(message: message ?? "Something went wrong. Please try again.")
    }

    private func store(_ response: GoTrueTokenResponse) {
        let newSession = AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date.now.addingTimeInterval(TimeInterval(response.expiresIn)),
            userID: response.user.id,
            email: response.user.email
        )
        session = newSession
        KeychainTokenStore.save(newSession)
    }
}

extension SupabaseAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}

private extension JSONDecoder {
    static let goTrue: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
