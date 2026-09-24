import Foundation

@MainActor
final class LivePlansViewModel: ObservableObject {
    @Published var plans: [PlanDetails] = []
    /// This client's own pay-as-you-go pricing (some clients have a custom
    /// rate). Falls back to the public plan's price when unavailable, e.g.
    /// a brand-new client with no billing account yet.
    @Published var topup: TopUpInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var checkoutURL: URL?
    @Published var isCheckingOut = false

    private let api: RemoteAPIClient
    private let session: LiveSessionStore

    init(api: RemoteAPIClient? = nil, session: LiveSessionStore) {
        self.api = api ?? .shared
        self.session = session
    }

    func plans(in category: PlanCategory) -> [PlanDetails] {
        plans
            .filter { $0.billingInterval == category.rawValue }
            .sorted { $0.priceGbp < $1.priceGbp }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            plans = try await api.plans()
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }

        // A brand-new client with no billing account yet gets a 400
        // "no_billing_account" here — per the backend guide that just means
        // "show the plans", so fall back to the public price silently.
        do {
            topup = try await api.billing().topup
        } catch {
            topup = nil
        }
    }

    func startCheckout(planSlug: String) async {
        isCheckingOut = true
        errorMessage = nil
        defer { isCheckingOut = false }
        do {
            let response = try await api.checkoutPlan(slug: planSlug)
            checkoutURL = response.url
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startCheckout(people: Int) async {
        isCheckingOut = true
        errorMessage = nil
        defer { isCheckingOut = false }
        do {
            let response = try await api.checkoutSession(people: people)
            checkoutURL = response.url
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
