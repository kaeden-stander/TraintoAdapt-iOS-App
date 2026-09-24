import Foundation

/// The three account types the app supports. Every screen in `RootTabView`
/// branches on this value to decide which tab set and permissions to show.
enum UserRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case client
    case trainer
    case admin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .client: "Client"
        case .trainer: "Trainer"
        case .admin: "Admin"
        }
    }

    var systemImage: String {
        switch self {
        case .client: "figure.strengthtraining.traditional"
        case .trainer: "person.badge.clock"
        case .admin: "gearshape.2"
        }
    }
}
