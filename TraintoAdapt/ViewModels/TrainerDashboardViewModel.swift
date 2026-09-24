import Foundation

@MainActor
final class TrainerDashboardViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var clients: [User] = []
    @Published var mealPlans: [MealPlan] = []
    @Published var isLoading = false

    private let bookingService: BookingServiceProtocol
    private let userService: UserServiceProtocol
    private let mealPlanService: MealPlanServiceProtocol
    let trainerID: UUID

    init(
        trainerID: UUID,
        bookingService: BookingServiceProtocol? = nil,
        userService: UserServiceProtocol? = nil,
        mealPlanService: MealPlanServiceProtocol? = nil
    ) {
        self.trainerID = trainerID
        self.bookingService = bookingService ?? MockBookingService()
        self.userService = userService ?? MockUserService()
        self.mealPlanService = mealPlanService ?? MockMealPlanService()
    }

    var todaysSessions: [Booking] {
        bookings
            .filter { Calendar.current.isDateInToday($0.startDate) && $0.status == .upcoming }
            .sorted { $0.startDate < $1.startDate }
    }

    var upcomingSessions: [Booking] {
        bookings
            .filter { $0.status == .upcoming && !Calendar.current.isDateInToday($0.startDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        async let fetchedBookings = bookingService.bookings(forTrainer: trainerID)
        async let allClients = userService.clients()
        async let fetchedPlans = mealPlanService.mealPlans(createdByTrainer: trainerID)
        bookings = await fetchedBookings
        let all = await allClients
        clients = all.filter { $0.assignedTrainerID == trainerID }
        mealPlans = await fetchedPlans
    }

    func markCompleted(_ booking: Booking) async {
        _ = try? await bookingService.markCompleted(booking.id)
        await load()
    }

    func cancel(_ booking: Booking) async {
        _ = try? await bookingService.cancelBooking(booking.id)
        await load()
    }
}
