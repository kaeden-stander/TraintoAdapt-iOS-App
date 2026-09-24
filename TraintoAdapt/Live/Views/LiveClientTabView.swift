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
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                LiveBookSessionView(session: session)
            }
            .tabItem { Label("Book", systemImage: "calendar") }

            NavigationStack {
                LivePlansView(session: session)
            }
            .tabItem { Label("Plans", systemImage: "tag.fill") }

            NavigationStack {
                LiveAccountView(session: session)
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .task { await session.refreshMe() }
    }
}
