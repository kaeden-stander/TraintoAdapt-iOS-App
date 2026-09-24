import Foundation

/// Response shape from Supabase's GoTrue auth REST API
/// (`POST /auth/v1/token`, `/signup`, etc).
struct GoTrueTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: GoTrueUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct GoTrueUser: Decodable {
    let id: String
    let email: String?
}

struct GoTrueErrorResponse: Decodable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg
        case message
    }

    var displayMessage: String {
        message ?? msg ?? errorDescription ?? error ?? "Something went wrong. Please try again."
    }
}

struct AuthServiceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
