import SwiftUI

struct TrainerDashboardView: View {
    let trainer: User
    @StateObject private var viewModel: TrainerDashboardViewModel

    init(trainer: User) {
        self.trainer = trainer
        _viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(trainerID: trainer.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(trainer.firstName)")
                        .font(Font.largeTitle.bold())
                    Text("Here's what's on today")
                        .font(Font.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                statsRow

                SectionCard(title: "Today's Sessions") {
                    if viewModel.todaysSessions.isEmpty {
                        EmptyStateRow(systemImage: "checkmark.circle", message: "No sessions scheduled today.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.todaysSessions) { booking in
                                BookingRow(booking: booking, trainerName: trainer.fullName, clientName: clientName(for: booking))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(title: "Clients", value: "\(viewModel.clients.count)", systemImage: "person.2.fill")
            StatTile(title: "Upcoming", value: "\(viewModel.upcomingSessions.count + viewModel.todaysSessions.count)", systemImage: "calendar")
        }
        .padding(.horizontal)
    }

    private func clientName(for booking: Booking) -> String {
        viewModel.clients.first(where: { $0.id == booking.clientID })?.fullName ?? "Client"
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandPrimary)
            Text(value).font(Font.title2.bold())
            Text(title).font(Font.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
