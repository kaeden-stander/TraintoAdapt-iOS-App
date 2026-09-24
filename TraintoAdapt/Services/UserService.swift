import Foundation

/// Admin-facing directory operations: managing the roster of clients and
/// trainers, and promoting/demoting accounts.
protocol UserServiceProtocol {
    func allUsers() async -> [User]
    func clients() async -> [User]
    func trainers() async -> [User]
    func user(id: UUID) async -> User?
    @discardableResult
    func createUser(_ user: User) async throws -> User
    func updateRole(userID: UUID, role: UserRole) async
    func updateMembershipStatus(userID: UUID, status: MembershipStatus) async
    func assignTrainer(clientID: UUID, trainerID: UUID?) async
    func deleteUser(_ userID: UUID) async
}

@MainActor
final class MockUserService: UserServiceProtocol {
    private let store: MockDataStore

    init(store: MockDataStore = .shared) {
        self.store = store
    }

    func allUsers() async -> [User] {
        store.users.sorted { $0.lastName < $1.lastName }
    }

    func clients() async -> [User] {
        store.users.filter { $0.role == .client }.sorted { $0.lastName < $1.lastName }
    }

    func trainers() async -> [User] {
        store.users.filter { $0.role == .trainer }.sorted { $0.lastName < $1.lastName }
    }

    func user(id: UUID) async -> User? {
        store.users.first { $0.id == id }
    }

    @discardableResult
    func createUser(_ user: User) async throws -> User {
        store.users.append(user)
        return user
    }

    func updateRole(userID: UUID, role: UserRole) async {
        guard let index = store.users.firstIndex(where: { $0.id == userID }) else { return }
        store.users[index].role = role
    }

    func updateMembershipStatus(userID: UUID, status: MembershipStatus) async {
        guard let index = store.users.firstIndex(where: { $0.id == userID }) else { return }
        store.users[index].membershipStatus = status
    }

    func assignTrainer(clientID: UUID, trainerID: UUID?) async {
        guard let index = store.users.firstIndex(where: { $0.id == clientID }) else { return }
        store.users[index].assignedTrainerID = trainerID
    }

    func deleteUser(_ userID: UUID) async {
        store.users.removeAll { $0.id == userID }
    }
}
