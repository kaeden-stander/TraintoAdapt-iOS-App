import Foundation
import AuthenticationServices

/// Drives the real sign-in screen: email/password against Supabase, plus
/// native Sign in with Apple and the Google OAuth browser flow.
@MainActor
final class LiveAuthViewModel: ObservableObject {
    enum Mode: Hashable {
        case signIn
        case signUp
    }

    @Published var mode: Mode = .signIn
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    /// Set right before presenting the native Apple sign-in sheet, and
    /// consumed when it completes — see `LoginView`.
    private(set) var pendingAppleNonce: String?

    private let auth: SupabaseAuthService

    init(auth: SupabaseAuthService? = nil) {
        self.auth = auth ?? .shared
    }

    var canSubmit: Bool {
        guard !isSubmitting, !email.isEmpty, password.count >= 8 else { return false }
        return mode == .signIn || !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        infoMessage = nil
        defer { isSubmitting = false }
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                let outcome = try await auth.signUp(email: email, password: password, fullName: fullName)
                if outcome == .confirmationEmailSent {
                    infoMessage = "Check your email to confirm your account, then sign in below."
                    mode = .signIn
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email above first, then tap this again."
            return
        }
        isSubmitting = true
        errorMessage = nil
        infoMessage = nil
        defer { isSubmitting = false }
        do {
            try await auth.resetPassword(email: email)
            infoMessage = "Password reset email sent — check your inbox."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signInWithGoogle() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called from `SignInWithAppleButton`'s `onRequest` to attach a nonce
    /// Apple will embed (hashed) in the identity token it returns.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = CryptoHelpers.randomURLSafeString()
        pendingAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = CryptoHelpers.sha256Hex(nonce)
    }

    /// Called from `SignInWithAppleButton`'s `onCompletion`.
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        guard let rawNonce = pendingAppleNonce else { return }
        pendingAppleNonce = nil

        switch result {
        case .failure(let error):
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Apple sign-in didn't return a token. Please try again."
                return
            }
            isSubmitting = true
            errorMessage = nil
            defer { isSubmitting = false }
            do {
                try await auth.signInWithApple(idToken: idToken, rawNonce: rawNonce)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
