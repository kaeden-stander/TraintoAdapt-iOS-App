import Foundation

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var allUsers: [User] = []
    @Published var allBookings: [Booking] = []
    @Published var allEvents: [Event] = []
    @Published var isLoading = false

    private let userService: UserServiceProtocol
    private let bookingService: BookingServiceProtocol
    private let eventService: EventServiceProtocol

    init(
        userService: UserServiceProtocol = MockUserService(),
        bookingService: BookingServiceProtocol = MockBookingService(),
        eventService: EventServiceProtocol = MockEventService()
    ) {
        self.userService = userService
        self.bookingService = bookingService
        self.eventService = eventService
    }

    var clients: [User] { allUsers.filter { $0.role == .client } }
    var trainers: [User] { allUsers.filter { $0.role == .trainer } }
    var admins: [User] { allUsers.filter { $0.role == .admin } }
    var upcomingBookingsCount: Int { allBookings.filter { $0.status == .upcoming }.count }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let users = userService.allUsers()
        async let bookings = bookingService.allBookings()
        async let events = eventService.upcomingEvents()
        allUsers = await users
        allBookings = await bookings
        allEvents = await events
    }

    func updateRole(_ user: User, to role: UserRole) async {
        await userService.updateRole(userID: user.id, role: role)
        await load()
    }

    func updateMembership(_ user: User, to status: MembershipStatus) async {
        await userService.updateMembershipStatus(userID: user.id, status: status)
        await load()
    }

    func assignTrainer(_ client: User, trainerID: UUID?) async {
        await userService.assignTrainer(clientID: client.id, trainerID: trainerID)
        await load()
    }

    func deleteUser(_ user: User) async {
        await userService.deleteUser(user.id)
        await load()
    }

    func createEvent(
        title: String,
        description: String,
        date: Date,
        location: String,
        capacity: Int,
        category: EventCategory,
        hostTrainerID: UUID?
    ) async {
        let event = Event(
            title: title,
            eventDescription: description,
            date: date,
            location: location,
            capacity: capacity,
            category: category,
            hostTrainerID: hostTrainerID
        )
        try? await eventService.createEvent(event)
        await load()
    }

    func deleteEvent(_ event: Event) async {
        try? await eventService.deleteEvent(event.id)
        await load()
    }
}
