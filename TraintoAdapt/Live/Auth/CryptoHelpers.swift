import Foundation
import CryptoKit
import Security

/// Small helpers for the Sign in with Apple nonce and the Google OAuth PKCE
/// exchange — both need a cryptographically random string and its SHA-256
/// digest, base64url-encoded with no external dependency.
enum CryptoHelpers {
    static func randomURLSafeString(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "Unable to generate secure random bytes")
        return base64URLEncode(Data(bytes))
    }

    static func sha256(_ input: String) -> Data {
        Data(SHA256.hash(data: Data(input.utf8)))
    }

    /// Apple's own Sign in with Apple sample code hex-encodes the nonce
    /// digest (not base64url) — `ASAuthorizationAppleIDRequest.nonce` must
    /// use this exact form so the hash embedded in Apple's identity token
    /// matches what the backend recomputes when verifying.
    static func sha256Hex(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
