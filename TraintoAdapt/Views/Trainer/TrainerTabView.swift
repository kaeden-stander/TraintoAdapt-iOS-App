import SwiftUI

struct TrainerTabView: View {
    let trainer: User

    var body: some View {
        TabView {
            NavigationStack {
                TrainerDashboardView(trainer: trainer)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                TrainerScheduleView(trainer: trainer)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Schedule", systemImage: "calendar") }

            NavigationStack {
                TrainerClientsView(trainer: trainer)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Clients", systemImage: "person.2.fill") }

            NavigationStack {
                AccountView(user: trainer)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .tint(Color.brandPrimary)
        .toolbarBackground(Color.brandInk, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
