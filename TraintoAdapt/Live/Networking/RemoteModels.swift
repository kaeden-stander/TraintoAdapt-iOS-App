import Foundation

// MARK: - /me

struct RemoteProfile: Decodable {
    let id: String
    let email: String
    let fullName: String
    let phone: String?
    let goals: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, goals
        case fullName = "full_name"
    }
}

struct WaiverInfo: Decodable {
    let signed: Bool
    let signedAt: Date?
    let url: URL?

    enum CodingKeys: String, CodingKey {
        case signed, url
        case signedAt = "signedAt"
    }
}

/// Covers both the plan summary embedded in `/me` and the fuller listing
/// returned by `/plans` — the backend guide notes `/plans` includes a few
/// extra fields (tagline, features, popularity), all modelled as optional
/// here since not every call site returns every field.
struct PlanDetails: Decodable, Identifiable, Hashable {
    let slug: String
    let name: String
    let tagline: String?
    let priceGbp: Double
    let billingInterval: String
    let monthlySessionCount: Int?
    let weeklySessions: Int?
    let isPopular: Bool?
    let features: [String]?

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug, name, tagline, features
        case priceGbp = "price_gbp"
        case billingInterval = "billing_interval"
        case monthlySessionCount = "monthly_session_count"
        case weeklySessions = "weekly_sessions"
        case isPopular = "is_popular"
    }

    static func == (lhs: PlanDetails, rhs: PlanDetails) -> Bool { lhs.slug == rhs.slug }
    func hash(into hasher: inout Hasher) { hasher.combine(slug) }
}

/// The four pricing tabs shown on the website, derived from
/// `PlanDetails.billingInterval`.
enum PlanCategory: String, CaseIterable, Identifiable, Hashable {
    case monthly = "month"
    case payAsYouGo = "session"
    case online = "online"
    case home = "home"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: "Monthly"
        case .payAsYouGo: "Pay as you go"
        case .online: "Online"
        case .home: "At your home"
        }
    }
}

struct SubscriptionInfo: Decodable {
    let status: String
    let currentPeriodEnd: Date?
    let cancelAtPeriodEnd: Bool?

    enum CodingKeys: String, CodingKey {
        case status
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
    }
}

struct CreditsInfo: Decodable {
    let remaining: Int
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case remaining
        case expiresAt = "expiresAt"
    }
}

struct MeResponse: Decodable {
    let profile: RemoteProfile
    let isAdmin: Bool
    let waiver: WaiverInfo
    let plan: PlanDetails?
    let subscription: SubscriptionInfo?
    let credits: CreditsInfo?
}

// MARK: - /slots

struct Slot: Decodable, Identifiable, Hashable {
    let startsAt: Date
    let endsAt: Date
    let status: SlotStatus

    var id: Date { startsAt }

    enum CodingKeys: String, CodingKey {
        case startsAt, endsAt, status
    }
}

enum SlotStatus: String, Decodable, Hashable {
    case open
    case booked
}

struct SlotsResponse: Decodable {
    let slots: [Slot]
}

// MARK: - /bookings

struct RemoteBooking: Decodable, Identifiable, Hashable {
    let id: String
    let startsAt: Date
    let endsAt: Date
    let status: RemoteBookingStatus
    let notes: String?
    /// Not documented in the client API guide — decoded only in case an
    /// admin-scoped call to the same endpoint includes them. `LiveAdminView`
    /// falls back to a generic label when these are absent.
    let clientName: String?
    let clientEmail: String?

    enum CodingKeys: String, CodingKey {
        case id, notes, status
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case clientName = "client_name"
        case clientEmail = "client_email"
    }

    static func == (lhs: RemoteBooking, rhs: RemoteBooking) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum RemoteBookingStatus: String, Decodable, Hashable {
    case pending
    case confirmed
    case cancelled
    case completed

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .confirmed: "Confirmed"
        case .cancelled: "Cancelled"
        case .completed: "Completed"
        }
    }
}

struct BookingsResponse: Decodable {
    let bookings: [RemoteBooking]
}

struct BookingEnvelope: Decodable {
    let booking: RemoteBooking
}

// MARK: - /billing

struct BillingBalance: Decodable {
    let granted: Int
    let rolledIn: Int
    let used: Int
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case granted, used
        case rolledIn = "rolled_in"
        case expiresAt = "expires_at"
    }
}

struct TopUpInfo: Decodable {
    let priceGbp: Double
    let twoPersonPriceGbp: Double

    enum CodingKeys: String, CodingKey {
        case priceGbp = "priceGbp"
        case twoPersonPriceGbp = "twoPersonPriceGbp"
    }
}

struct BillingResponse: Decodable {
    let subscription: SubscriptionInfo?
    let balance: BillingBalance?
    let plan: PlanDetails?
    let topup: TopUpInfo?
}

struct BillingPortalResponse: Decodable {
    let url: URL
}

// MARK: - /receipts

struct Invoice: Decodable, Identifiable {
    let id: String
    let status: String?
    let amountPaid: Int
    let currency: String
    let created: Date
    let description: String?
    let hostedInvoiceUrl: URL?
    let pdfUrl: URL?

    enum CodingKeys: String, CodingKey {
        case id, status, currency, description
        case amountPaid = "amount_paid"
        case created
        case hostedInvoiceUrl = "hosted_invoice_url"
        case pdfUrl = "pdf_url"
    }

    /// Stripe amounts are in the currency's minor unit (pence for GBP).
    var displayAmount: String {
        let pounds = Double(amountPaid) / 100
        return currency.uppercased() == "GBP" ? "£\(String(format: "%.2f", pounds))" : "\(pounds) \(currency.uppercased())"
    }
}

struct ReceiptsResponse: Decodable {
    let invoices: [Invoice]
}

// MARK: - /checkout

struct CheckoutResponse: Decodable {
    let url: URL
    let priceGbp: Double?

    enum CodingKeys: String, CodingKey {
        case url
        case priceGbp = "priceGbp"
    }
}

// MARK: - Errors

struct APIErrorEnvelope: Decodable {
    let error: APIError
}

struct APIError: Decodable, Error {
    let code: String
    let message: String
}

enum KnownAPIErrorCode: String {
    case unauthorized
    case waiverRequired = "waiver_required"
    case bookingRejected = "booking_rejected"
    case invalidInput = "invalid_input"
    case noBillingAccount = "no_billing_account"
    case notFound = "not_found"
    case planNotFound = "plan_not_found"
    case stripeError = "stripe_error"
    case serverError = "server_error"
}
