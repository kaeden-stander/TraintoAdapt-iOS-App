import SwiftUI

struct AdminTabView: View {
    let admin: User

    var body: some View {
        TabView {
            NavigationStack {
                AdminDashboardView(admin: admin)
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                AdminUsersView(role: .client, title: "Clients")
            }
            .tabItem { Label("Clients", systemImage: "person.fill") }

            NavigationStack {
                AdminUsersView(role: .trainer, title: "Trainers")
            }
            .tabItem { Label("Trainers", systemImage: "person.badge.clock") }

            NavigationStack {
                AdminEventsView(admin: admin)
            }
            .tabItem { Label("Events", systemImage: "star.fill") }

            NavigationStack {
                AccountView(user: admin)
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}
