import SwiftUI

struct ClientHomeView: View {
    let client: User

    @StateObject private var bookingViewModel: BookingViewModel
    @StateObject private var healthViewModel = HealthViewModel()

    init(client: User) {
        self.client = client
        _bookingViewModel = StateObject(wrappedValue: BookingViewModel(clientID: client.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(client.firstName)
                        .font(.largeTitle.bold())
                }
                .padding(.horizontal)

                nextSessionCard
                healthCard
                quickLinks
            }
            .padding(.vertical)
        }
        .navigationTitle("TrainToAdapt")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await bookingViewModel.load()
            await healthViewModel.refresh()
        }
        .refreshable {
            await bookingViewModel.load()
            await healthViewModel.refresh()
        }
    }

    @ViewBuilder
    private var nextSessionCard: some View {
        SectionCard(title: "Next Session") {
            if let next = bookingViewModel.upcomingBookings.first {
                BookingRow(booking: next, trainerName: trainerName(for: next))
            } else {
                EmptyStateRow(
                    systemImage: "calendar.badge.plus",
                    message: "No upcoming sessions booked yet."
                )
            }
        }
        .padding(.horizontal)
    }

    private var healthCard: some View {
        SectionCard(title: "Today's Activity") {
            HealthSummaryRow(summary: healthViewModel.summary)
        }
        .padding(.horizontal)
    }

    private var quickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                NavigationLink {
                    NewBookingView(client: client)
                } label: {
                    QuickLinkRow(systemImage: "calendar.badge.plus", title: "Book a Session")
                }
                Divider().padding(.leading, 52)

                NavigationLink {
                    MealPlanView(client: client)
                } label: {
                    QuickLinkRow(systemImage: "fork.knife", title: "View Meal Plan")
                }
                Divider().padding(.leading, 52)

                NavigationLink {
                    EventsListView(currentUser: client)
                } label: {
                    QuickLinkRow(systemImage: "star.fill", title: "Upcoming Events")
                }
            }
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private func trainerName(for booking: Booking) -> String {
        bookingViewModel.trainers.first(where: { $0.id == booking.trainerID })?.fullName ?? "Your Trainer"
    }
}
