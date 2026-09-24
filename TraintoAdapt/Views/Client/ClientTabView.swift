import SwiftUI

struct ClientTabView: View {
    let client: User

    var body: some View {
        TabView {
            NavigationStack {
                ClientHomeView(client: client)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                BookingListView(client: client)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Book", systemImage: "calendar") }

            NavigationStack {
                EventsListView(currentUser: client)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Events", systemImage: "star.fill") }

            NavigationStack {
                AccountView(user: client)
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
