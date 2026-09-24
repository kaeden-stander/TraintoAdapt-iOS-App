import SwiftUI

/// The real, backend-connected client experience — shown whenever
/// `LiveSessionStore.isSignedIn` is true, independent of the mock
/// Client/Trainer/Admin tabs used in Demo Mode.
struct LiveClientTabView: View {
    @ObservedObject var session: LiveSessionStore

    var body: some View {
        TabView {
            NavigationStack {
                LiveHomeView(session: session)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                LiveBookSessionView(session: session)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Book", systemImage: "calendar") }

            NavigationStack {
                LivePlansView(session: session)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Plans", systemImage: "tag.fill") }

            NavigationStack {
                LiveEventsView(session: session)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Events", systemImage: "star.fill") }

            if session.me?.isAdmin == true {
                NavigationStack {
                    LiveAdminView(session: session)
                        .brandedNavigationBar()
                }
                .tabItem { Label("Admin", systemImage: "shield.fill") }
            }

            NavigationStack {
                LiveAccountView(session: session)
                    .brandedNavigationBar()
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .tint(Color.brandPrimary)
        .toolbarBackground(Color.brandInk, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .task { await session.refreshMe() }
    }
}
