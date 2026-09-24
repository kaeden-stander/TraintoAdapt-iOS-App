import Foundation

@MainActor
final class LiveBillingViewModel: ObservableObject {
    @Published var billing: BillingResponse?
    @Published var invoices: [Invoice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var portalURL: URL?
    @Published var isOpeningPortal = false

    private let api: RemoteAPIClient
    private let session: LiveSessionStore

    init(api: RemoteAPIClient? = nil, session: LiveSessionStore) {
        self.api = api ?? .shared
        self.session = session
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let fetchedBilling = api.billing()
            async let fetchedInvoices = api.receipts()
            billing = try await fetchedBilling
            invoices = try await fetchedInvoices
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openBillingPortal() async {
        isOpeningPortal = true
        errorMessage = nil
        defer { isOpeningPortal = false }
        do {
            portalURL = try await api.billingPortalURL()
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
