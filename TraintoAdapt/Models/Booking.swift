import Foundation

/// A single training session, booked by a client with a trainer.
struct Booking: Identifiable, Codable, Hashable {
    let id: UUID
    var clientID: UUID
    var trainerID: UUID
    var sessionType: SessionType
    var startDate: Date
    var durationMinutes: Int
    var location: String
    var status: BookingStatus
    var notes: String?

    init(
        id: UUID = UUID(),
        clientID: UUID,
        trainerID: UUID,
        sessionType: SessionType,
        startDate: Date,
        durationMinutes: Int = 60,
        location: String,
        status: BookingStatus = .upcoming,
        notes: String? = nil
    ) {
        self.id = id
        self.clientID = clientID
        self.trainerID = trainerID
        self.sessionType = sessionType
        self.startDate = startDate
        self.durationMinutes = durationMinutes
        self.location = location
        self.status = status
        self.notes = notes
    }

    var endDate: Date {
        startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }
}

enum SessionType: String, Codable, CaseIterable, Identifiable, Hashable {
    case personalTraining = "Personal Training"
    case groupClass = "Group Class"
    case consultation = "Consultation"
    case assessment = "Fitness Assessment"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .personalTraining: "figure.strengthtraining.traditional"
        case .groupClass: "person.3.fill"
        case .consultation: "bubble.left.and.bubble.right.fill"
        case .assessment: "chart.line.uptrend.xyaxis"
        }
    }
}

enum BookingStatus: String, Codable, CaseIterable, Hashable {
    case upcoming
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .upcoming: "Upcoming"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
}
