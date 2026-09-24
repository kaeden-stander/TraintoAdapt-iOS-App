import Foundation

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var trainers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let bookingService: BookingServiceProtocol
    private let userService: UserServiceProtocol
    private let clientID: UUID

    init(
        clientID: UUID,
        bookingService: BookingServiceProtocol? = nil,
        userService: UserServiceProtocol? = nil
    ) {
        self.clientID = clientID
        self.bookingService = bookingService ?? MockBookingService()
        self.userService = userService ?? MockUserService()
    }

    var upcomingBookings: [Booking] {
        bookings.filter { $0.status == .upcoming }.sorted { $0.startDate < $1.startDate }
    }

    var pastBookings: [Booking] {
        bookings.filter { $0.status != .upcoming }.sorted { $0.startDate > $1.startDate }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let fetchedBookings = bookingService.bookings(forClient: clientID)
        async let fetchedTrainers = userService.trainers()
        bookings = await fetchedBookings
        trainers = await fetchedTrainers
    }

    func book(
        trainerID: UUID,
        sessionType: SessionType,
        startDate: Date,
        durationMinutes: Int,
        location: String,
        notes: String?
    ) async {
        errorMessage = nil
        do {
            _ = try await bookingService.createBooking(
                clientID: clientID,
                trainerID: trainerID,
                sessionType: sessionType,
                startDate: startDate,
                durationMinutes: durationMinutes,
                location: location,
                notes: notes
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancel(_ booking: Booking) async {
        do {
            try await bookingService.cancelBooking(booking.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
