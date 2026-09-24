import Foundation

/// Typed client for the TrainToAdapt client booking API
/// (`apiBase = https://client.traintoadapt.co.uk/api/public/mobile`), per
/// the backend team's integration guide. Every call attaches the current
/// Supabase access token (refreshing it first if it's close to expiring)
/// and decodes the `{ "error": { "code", "message" } }` envelope on failure.
@MainActor
final class RemoteAPIClient {
    static let shared = RemoteAPIClient()

    private let auth: SupabaseAuthService
    private let urlSession: URLSession

    init(auth: SupabaseAuthService? = nil) {
        self.auth = auth ?? .shared
        self.urlSession = URLSession(configuration: .ephemeral)
    }

    // MARK: - Profile

    func me() async throws -> MeResponse {
        try await request("me")
    }

    // MARK: - Plans

    func plans() async throws -> [PlanDetails] {
        try await request("plans")
    }

    // MARK: - Slots

    func slots(days: Int = 62, from: Date = .now) async throws -> [Slot] {
        let response: SlotsResponse = try await request(
            "slots",
            query: [
                URLQueryItem(name: "days", value: String(min(max(days, 1), 120))),
                URLQueryItem(name: "from", value: ISO8601DateFormatter().string(from: from))
            ]
        )
        return response.slots
    }

    // MARK: - Bookings

    func bookings() async throws -> [RemoteBooking] {
        let response: BookingsResponse = try await request("bookings")
        return response.bookings
    }

    @discardableResult
    func createBooking(startsAt: Date, endsAt: Date, notes: String?) async throws -> RemoteBooking {
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "startsAt": iso.string(from: startsAt),
            "endsAt": iso.string(from: endsAt)
        ]
        if let notes, !notes.isEmpty { body["notes"] = notes }
        let response: BookingEnvelope = try await request("bookings", method: "POST", jsonBody: body)
        return response.booking
    }

    func cancelBooking(id: String) async throws {
        let _: EmptyOK = try await request("bookings/\(id)/cancel", method: "POST")
    }

    @discardableResult
    func rescheduleBooking(id: String, startsAt: Date, endsAt: Date) async throws -> RemoteBooking {
        let iso = ISO8601DateFormatter()
        let body: [String: Any] = [
            "startsAt": iso.string(from: startsAt),
            "endsAt": iso.string(from: endsAt)
        ]
        let response: BookingEnvelope = try await request("bookings/\(id)/reschedule", method: "POST", jsonBody: body)
        return response.booking
    }

    // MARK: - Billing

    func billing() async throws -> BillingResponse {
        try await request("billing")
    }

    func billingPortalURL() async throws -> URL {
        let response: BillingPortalResponse = try await request("billing/portal", method: "POST")
        return response.url
    }

    func receipts() async throws -> [Invoice] {
        let response: ReceiptsResponse = try await request("receipts")
        return response.invoices
    }

    // MARK: - Checkout

    func checkoutPlan(slug: String) async throws -> CheckoutResponse {
        try await request("checkout", method: "POST", jsonBody: ["kind": "plan", "planSlug": slug])
    }

    func checkoutSession(people: Int) async throws -> CheckoutResponse {
        try await request("checkout", method: "POST", jsonBody: ["kind": "session", "people": people])
    }

    // MARK: - Core request plumbing

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        jsonBody: [String: Any]? = nil
    ) async throws -> T {
        var url = AppConfig.apiBase.appendingPathComponent(path)
        if !query.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = query
            url = components.url ?? url
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = method
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("Bearer \(try await auth.validAccessToken())", forHTTPHeaderField: "Authorization")
        if let jsonBody {
            httpRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        }

        let (data, response) = try await urlSession.data(for: httpRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(code: "server_error", message: "Unexpected response from the server.")
        }

        guard (200..<300).contains(http.statusCode) else {
            if let envelope = try? JSONDecoder.remoteAPI.decode(APIErrorEnvelope.self, from: data) {
                throw envelope.error
            }
            if http.statusCode == 429 {
                throw APIError(code: "rate_limited", message: "Too many requests. Please wait a moment and try again.")
            }
            throw APIError(code: "server_error", message: "Something went wrong (HTTP \(http.statusCode)). Please try again.")
        }

        return try JSONDecoder.remoteAPI.decode(T.self, from: data)
    }
}

/// Used for endpoints that just return `{ "ok": true }`.
private struct EmptyOK: Decodable {
    let ok: Bool?
}

extension JSONDecoder {
    /// All backend timestamps are ISO-8601 UTC; some endpoints include
    /// fractional seconds and some don't, so both are accepted.
    static let remoteAPI: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = withFractional.date(from: raw) ?? standard.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO-8601 date, got \(raw)"
            )
        }
        return decoder
    }()
}
