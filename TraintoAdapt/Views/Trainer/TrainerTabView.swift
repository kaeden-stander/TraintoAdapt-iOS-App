import SwiftUI

struct TrainerTabView: View {
    let trainer: User

    var body: some View {
        TabView {
            NavigationStack {
                TrainerDashboardView(trainer: trainer)
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                TrainerScheduleView(trainer: trainer)
            }
            .tabItem { Label("Schedule", systemImage: "calendar") }

            NavigationStack {
                TrainerClientsView(trainer: trainer)
            }
            .tabItem { Label("Clients", systemImage: "person.2.fill") }

            NavigationStack {
                AccountView(user: trainer)
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}
