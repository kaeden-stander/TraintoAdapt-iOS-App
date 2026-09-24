import Foundation

protocol BookingServiceProtocol {
    func bookings(forClient clientID: UUID) async -> [Booking]
    func bookings(forTrainer trainerID: UUID) async -> [Booking]
    func allBookings() async -> [Booking]
    @discardableResult
    func createBooking(
        clientID: UUID,
        trainerID: UUID,
        sessionType: SessionType,
        startDate: Date,
        durationMinutes: Int,
        location: String,
        notes: String?
    ) async throws -> Booking
    func cancelBooking(_ bookingID: UUID) async throws
    func markCompleted(_ bookingID: UUID) async throws
}

@MainActor
final class MockBookingService: BookingServiceProtocol {
    private let store: MockDataStore

    init(store: MockDataStore? = nil) {
        self.store = store ?? .shared
    }

    func bookings(forClient clientID: UUID) async -> [Booking] {
        store.bookings
            .filter { $0.clientID == clientID }
            .sorted { $0.startDate < $1.startDate }
    }

    func bookings(forTrainer trainerID: UUID) async -> [Booking] {
        store.bookings
            .filter { $0.trainerID == trainerID }
            .sorted { $0.startDate < $1.startDate }
    }

    func allBookings() async -> [Booking] {
        store.bookings.sorted { $0.startDate < $1.startDate }
    }

    @discardableResult
    func createBooking(
        clientID: UUID,
        trainerID: UUID,
        sessionType: SessionType,
        startDate: Date,
        durationMinutes: Int,
        location: String,
        notes: String?
    ) async throws -> Booking {
        let booking = Booking(
            clientID: clientID,
            trainerID: trainerID,
            sessionType: sessionType,
            startDate: startDate,
            durationMinutes: durationMinutes,
            location: location,
            status: .upcoming,
            notes: notes
        )
        store.bookings.append(booking)
        return booking
    }

    func cancelBooking(_ bookingID: UUID) async throws {
        guard let index = store.bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        store.bookings[index].status = .cancelled
    }

    func markCompleted(_ bookingID: UUID) async throws {
        guard let index = store.bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        store.bookings[index].status = .completed
    }
}
