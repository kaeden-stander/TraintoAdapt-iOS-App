import Foundation

/// Exploratory: the backend guide only documents client-facing endpoints,
/// so this calls the same `/bookings` the client screens use and shows
/// whatever comes back. If the backend's row-level security scopes admin
/// accounts to see every client's bookings (not just their own), this
/// becomes a real schedule view for free; if not, it'll just show the
/// admin's own bookings like any client. Worth confirming either way with
/// a real admin sign-in.
@MainActor
final class LiveAdminViewModel: ObservableObject {
    @Published var bookings: [RemoteBooking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api: RemoteAPIClient
    private let session: LiveSessionStore

    init(api: RemoteAPIClient? = nil, session: LiveSessionStore) {
        self.api = api ?? .shared
        self.session = session
    }

    var bookingsByDay: [(day: Date, bookings: [RemoteBooking])] {
        let upcoming = bookings
            .filter { $0.status == .pending || $0.status == .confirmed }
            .sorted { $0.startsAt < $1.startsAt }
        let grouped = Dictionary(grouping: upcoming) { Calendar.current.startOfDay(for: $0.startsAt) }
        return grouped.keys.sorted().map { day in (day, grouped[day]!.sorted { $0.startsAt < $1.startsAt }) }
    }

    var upcomingCount: Int {
        bookings.filter { $0.status == .pending || $0.status == .confirmed }.count
    }

    /// True once loaded, if every booking looks like it belongs to the
    /// admin's own account only (no client name/email ever present) — used
    /// to show a note that this may just be the admin's own schedule.
    var likelyOwnBookingsOnly: Bool {
        !bookings.isEmpty && bookings.allSatisfy { $0.clientName == nil && $0.clientEmail == nil }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            bookings = try await api.bookings()
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel(_ booking: RemoteBooking) async {
        do {
            try await api.cancelBooking(id: booking.id)
            await load()
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
