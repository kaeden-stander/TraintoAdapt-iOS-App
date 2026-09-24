import SwiftUI

struct AdminDashboardView: View {
    let admin: User
    @StateObject private var viewModel = AdminDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Studio Overview")
                        .font(.largeTitle.bold())
                    Text("Welcome, \(admin.firstName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Clients", value: "\(viewModel.clients.count)", systemImage: "person.fill")
                    StatTile(title: "Trainers", value: "\(viewModel.trainers.count)", systemImage: "person.badge.clock")
                    StatTile(title: "Upcoming Sessions", value: "\(viewModel.upcomingBookingsCount)", systemImage: "calendar")
                    StatTile(title: "Upcoming Events", value: "\(viewModel.allEvents.count)", systemImage: "star.fill")
                }
                .padding(.horizontal)

                SectionCard(title: "Recent Bookings") {
                    if viewModel.allBookings.isEmpty {
                        EmptyStateRow(systemImage: "calendar", message: "No bookings yet.")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.allBookings.prefix(5)) { booking in
                                BookingRow(
                                    booking: booking,
                                    trainerName: name(for: booking.trainerID),
                                    clientName: name(for: booking.clientID)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Admin")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private func name(for id: UUID) -> String {
        viewModel.allUsers.first(where: { $0.id == id })?.fullName ?? "Unknown"
    }
}
