import Foundation

@MainActor
final class AccountViewModel: ObservableObject {
    @Published var user: User
    @Published var assignedTrainer: User?

    private let userService: UserServiceProtocol

    init(user: User, userService: UserServiceProtocol? = nil) {
        self.user = user
        self.userService = userService ?? MockUserService()
    }

    func load() async {
        if let trainerID = user.assignedTrainerID {
            assignedTrainer = await userService.user(id: trainerID)
        }
    }
}
