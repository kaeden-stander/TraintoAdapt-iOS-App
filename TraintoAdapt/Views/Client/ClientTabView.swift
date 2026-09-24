import SwiftUI

struct ClientTabView: View {
    let client: User

    var body: some View {
        TabView {
            NavigationStack {
                ClientHomeView(client: client)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                BookingListView(client: client)
            }
            .tabItem { Label("Book", systemImage: "calendar") }

            NavigationStack {
                EventsListView(currentUser: client)
            }
            .tabItem { Label("Events", systemImage: "star.fill") }

            NavigationStack {
                AccountView(user: client)
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}
