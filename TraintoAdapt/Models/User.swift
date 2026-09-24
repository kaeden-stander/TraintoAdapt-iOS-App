import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var role: UserRole
    var phoneNumber: String?
    var joinedDate: Date
    var membershipStatus: MembershipStatus
    /// Trainer-only: areas of coaching expertise. Empty for clients and admins.
    var specialties: [String]
    /// Trainer-only: short biography shown to clients when booking.
    var bio: String?
    /// Client-only: the trainer assigned to this client, if any.
    var assignedTrainerID: UUID?

    var fullName: String { "\(firstName) \(lastName)" }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        role: UserRole,
        phoneNumber: String? = nil,
        joinedDate: Date = .now,
        membershipStatus: MembershipStatus = .active,
        specialties: [String] = [],
        bio: String? = nil,
        assignedTrainerID: UUID? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.phoneNumber = phoneNumber
        self.joinedDate = joinedDate
        self.membershipStatus = membershipStatus
        self.specialties = specialties
        self.bio = bio
        self.assignedTrainerID = assignedTrainerID
    }
}

enum MembershipStatus: String, Codable, CaseIterable, Hashable {
    case active
    case paused
    case cancelled

    var displayName: String {
        switch self {
        case .active: "Active"
        case .paused: "Paused"
        case .cancelled: "Cancelled"
        }
    }
}
