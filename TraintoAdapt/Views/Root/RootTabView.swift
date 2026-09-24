import SwiftUI

/// Picks the tab bar for the signed-in user's role. Each role gets its own
/// dedicated set of tabs, all under this one entry point so navigation stays
/// centralised as roles are added to or removed from the app.
struct RootTabView: View {
    let user: User

    var body: some View {
        switch user.role {
        case .client:
            ClientTabView(client: user)
        case .trainer:
            TrainerTabView(trainer: user)
        case .admin:
            AdminTabView(admin: user)
        }
    }
}
