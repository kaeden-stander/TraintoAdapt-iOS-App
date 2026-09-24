import Foundation

@MainActor
final class LiveBookingViewModel: ObservableObject {
    @Published var slots: [Slot] = []
    @Published var bookings: [RemoteBooking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false

    private let api: RemoteAPIClient
    private let session: LiveSessionStore

    init(api: RemoteAPIClient? = nil, session: LiveSessionStore) {
        self.api = api ?? .shared
        self.session = session
    }

    /// Only slots the backend hasn't already marked as taken — by another
    /// client's booking, or by something on Adam's Google Calendar, which
    /// is synced into this same field server-side.
    var openSlotsByDay: [(day: Date, slots: [Slot])] {
        let open = slots.filter { $0.status == .open }.sorted { $0.startsAt < $1.startsAt }
        let grouped = Dictionary(grouping: open) { Calendar.current.startOfDay(for: $0.startsAt) }
        return grouped.keys.sorted().map { day in (day, grouped[day]!.sorted { $0.startsAt < $1.startsAt }) }
    }

    var upcomingBookings: [RemoteBooking] {
        bookings
            .filter { $0.status == .pending || $0.status == .confirmed }
            .sorted { $0.startsAt < $1.startsAt }
    }

    var pastBookings: [RemoteBooking] {
        bookings
            .filter { $0.status == .completed || $0.status == .cancelled }
            .sorted { $0.startsAt > $1.startsAt }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let fetchedSlots = api.slots()
            async let fetchedBookings = api.bookings()
            slots = try await fetchedSlots
            bookings = try await fetchedBookings
            await SessionNotificationScheduler.shared.reschedule(for: bookings)
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return }
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func book(_ slot: Slot, notes: String?) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await api.createBooking(startsAt: slot.startsAt, endsAt: slot.endsAt, notes: notes)
            await load()
            return true
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return false }
            errorMessage = error.message
            if error.code == KnownAPIErrorCode.bookingRejected.rawValue {
                await load()
            }
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func cancel(_ booking: RemoteBooking) async {
        errorMessage = nil
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

    @discardableResult
    func reschedule(_ booking: RemoteBooking, to slot: Slot) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            try await api.rescheduleBooking(id: booking.id, startsAt: slot.startsAt, endsAt: slot.endsAt)
            await load()
            return true
        } catch let error as APIError {
            if await session.handleIfUnauthorized(error) { return false }
            errorMessage = error.message
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
