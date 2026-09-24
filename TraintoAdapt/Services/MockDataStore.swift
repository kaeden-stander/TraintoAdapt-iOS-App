import Foundation

/// In-memory data used by every mock service. This stands in for a real
/// backend (Firebase, a REST API, CloudKit, etc.) so the app is fully
/// navigable and demoable today. Swap the service implementations for
/// network-backed ones later without touching any view or view model, since
/// every service is accessed through a protocol.
@MainActor
final class MockDataStore: ObservableObject {
    static let shared = MockDataStore()

    @Published var users: [User]
    @Published var bookings: [Booking]
    @Published var mealPlans: [MealPlan]
    @Published var events: [Event]

    /// The trainer signed in via `trainer@traintoadapt.co.uk`, used below to
    /// seed sample data owned by that trainer.
    let sampleTrainerID: UUID
    let sampleClientID: UUID

    private init() {
        let trainer = User(
            id: UUID(),
            firstName: "Sam",
            lastName: "Whitfield",
            email: "trainer@traintoadapt.co.uk",
            role: .trainer,
            phoneNumber: "+44 7700 900123",
            joinedDate: Calendar.current.date(byAdding: .year, value: -2, to: .now) ?? .now,
            specialties: ["Strength & Conditioning", "Injury Rehab", "Nutrition Coaching"],
            bio: "British Weight Lifting certified coach, 8 years experience helping adaptive and para athletes train safely and progressively."
        )
        let secondTrainer = User(
            firstName: "Priya",
            lastName: "Anand",
            email: "priya@traintoadapt.co.uk",
            role: .trainer,
            phoneNumber: "+44 7700 900456",
            joinedDate: Calendar.current.date(byAdding: .month, value: -14, to: .now) ?? .now,
            specialties: ["Mobility", "Wheelchair Fitness", "Group Classes"],
            bio: "REPs Level 3 PT specialising in inclusive group training and mobility work."
        )
        let admin = User(
            firstName: "Jordan",
            lastName: "Blake",
            email: "admin@traintoadapt.co.uk",
            role: .admin,
            phoneNumber: "+44 7700 900789",
            joinedDate: Calendar.current.date(byAdding: .year, value: -3, to: .now) ?? .now
        )
        let client = User(
            firstName: "Alex",
            lastName: "Morgan",
            email: "client@traintoadapt.co.uk",
            role: .client,
            phoneNumber: "+44 7700 900321",
            joinedDate: Calendar.current.date(byAdding: .month, value: -5, to: .now) ?? .now,
            membershipStatus: .active,
            assignedTrainerID: trainer.id
        )
        let secondClient = User(
            firstName: "Robin",
            lastName: "Clarke",
            email: "robin@example.com",
            role: .client,
            joinedDate: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now,
            membershipStatus: .active,
            assignedTrainerID: trainer.id
        )
        let thirdClient = User(
            firstName: "Taylor",
            lastName: "Reed",
            email: "taylor@example.com",
            role: .client,
            joinedDate: Calendar.current.date(byAdding: .day, value: -10, to: .now) ?? .now,
            membershipStatus: .paused,
            assignedTrainerID: secondTrainer.id
        )

        self.sampleTrainerID = trainer.id
        self.sampleClientID = client.id
        self.users = [trainer, secondTrainer, admin, client, secondClient, thirdClient]

        let cal = Calendar.current
        self.bookings = [
            Booking(
                clientID: client.id,
                trainerID: trainer.id,
                sessionType: .personalTraining,
                startDate: cal.date(byAdding: .day, value: 1, to: .now) ?? .now,
                durationMinutes: 60,
                location: "TrainToAdapt Studio, Manchester",
                status: .upcoming
            ),
            Booking(
                clientID: client.id,
                trainerID: trainer.id,
                sessionType: .assessment,
                startDate: cal.date(byAdding: .day, value: -6, to: .now) ?? .now,
                durationMinutes: 45,
                location: "TrainToAdapt Studio, Manchester",
                status: .completed
            ),
            Booking(
                clientID: secondClient.id,
                trainerID: trainer.id,
                sessionType: .groupClass,
                startDate: cal.date(byAdding: .day, value: 2, to: .now) ?? .now,
                durationMinutes: 50,
                location: "Studio B",
                status: .upcoming
            ),
            Booking(
                clientID: thirdClient.id,
                trainerID: secondTrainer.id,
                sessionType: .consultation,
                startDate: cal.date(byAdding: .day, value: 3, to: .now) ?? .now,
                durationMinutes: 30,
                location: "Video call",
                status: .upcoming
            )
        ]

        self.mealPlans = [
            MealPlan(
                clientID: client.id,
                createdByTrainerID: trainer.id,
                title: "Strength Phase — Weeks 1-4",
                startDate: cal.date(byAdding: .day, value: -3, to: .now) ?? .now,
                endDate: cal.date(byAdding: .day, value: 25, to: .now),
                dailyCalorieTarget: 2400,
                proteinTargetGrams: 160,
                carbsTargetGrams: 260,
                fatTargetGrams: 75,
                meals: [
                    Meal(name: "Greek yoghurt, berries & oats", type: .breakfast, calories: 420, proteinGrams: 28, carbsGrams: 55, fatGrams: 9),
                    Meal(name: "Chicken, rice & roasted veg", type: .lunch, calories: 650, proteinGrams: 48, carbsGrams: 70, fatGrams: 15),
                    Meal(name: "Salmon, sweet potato & greens", type: .dinner, calories: 700, proteinGrams: 45, carbsGrams: 60, fatGrams: 25),
                    Meal(name: "Protein shake & almonds", type: .snack, calories: 300, proteinGrams: 25, carbsGrams: 12, fatGrams: 16)
                ],
                notes: "Prioritise protein at each meal. Hydrate with 3L water daily."
            )
        ]

        self.events = [
            Event(
                title: "Adaptive Strength Workshop",
                eventDescription: "Hands-on session covering safe lifting technique adapted for a range of mobility needs. Open to all members.",
                date: cal.date(byAdding: .day, value: 5, to: .now) ?? .now,
                location: "TrainToAdapt Studio, Manchester",
                capacity: 20,
                attendeeIDs: [client.id],
                category: .workshop,
                hostTrainerID: trainer.id
            ),
            Event(
                title: "6-Week Consistency Challenge",
                eventDescription: "Sign up and commit to 3 sessions a week for 6 weeks. Prizes for top finishers.",
                date: cal.date(byAdding: .day, value: 10, to: .now) ?? .now,
                location: "TrainToAdapt Studio, Manchester",
                capacity: 40,
                attendeeIDs: [],
                category: .challenge,
                hostTrainerID: nil
            ),
            Event(
                title: "Nutrition for Performance Seminar",
                eventDescription: "A practical talk on fuelling training and recovery, run by our in-house nutrition coach.",
                date: cal.date(byAdding: .day, value: 14, to: .now) ?? .now,
                location: "Online — Zoom",
                capacity: 100,
                attendeeIDs: [],
                category: .seminar,
                hostTrainerID: secondTrainer.id
            ),
            Event(
                title: "Members Social & Open Day",
                eventDescription: "Meet other members, try a taster class and enjoy refreshments.",
                date: cal.date(byAdding: .day, value: 21, to: .now) ?? .now,
                location: "TrainToAdapt Studio, Manchester",
                capacity: 60,
                attendeeIDs: [],
                category: .social,
                hostTrainerID: nil
            )
        ]
    }
}
