import SwiftUI

struct AdminTabView: View {
    let admin: User

    var body: some View {
        TabView {
            NavigationStack {
                AdminDashboardView(admin: admin)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                AdminUsersView(role: .client, title: "Clients")
                    .brandedNavigationBar()
            }
            .tabItem { Label("Clients", systemImage: "person.fill") }

            NavigationStack {
                AdminUsersView(role: .trainer, title: "Trainers")
                    .brandedNavigationBar()
            }
            .tabItem { Label("Trainers", systemImage: "person.badge.clock") }

            NavigationStack {
                AdminEventsView(admin: admin)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Events", systemImage: "star.fill") }

            NavigationStack {
                AccountView(user: admin)
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
