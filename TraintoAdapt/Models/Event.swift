import Foundation

/// A gym-wide event that clients can sign up to, such as a workshop or challenge.
struct Event: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var eventDescription: String
    var date: Date
    var location: String
    var capacity: Int
    var attendeeIDs: [UUID]
    var category: EventCategory
    var hostTrainerID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        eventDescription: String,
        date: Date,
        location: String,
        capacity: Int,
        attendeeIDs: [UUID] = [],
        category: EventCategory,
        hostTrainerID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.date = date
        self.location = location
        self.capacity = capacity
        self.attendeeIDs = attendeeIDs
        self.category = category
        self.hostTrainerID = hostTrainerID
    }

    var spotsRemaining: Int { max(0, capacity - attendeeIDs.count) }
    var isFull: Bool { spotsRemaining == 0 }

    func isAttending(_ userID: UUID) -> Bool {
        attendeeIDs.contains(userID)
    }
}

enum EventCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case workshop = "Workshop"
    case challenge = "Challenge"
    case seminar = "Seminar"
    case social = "Social"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .workshop: "hammer.fill"
        case .challenge: "flag.checkered"
        case .seminar: "person.fill.checkmark"
        case .social: "party.popper.fill"
        }
    }
}
