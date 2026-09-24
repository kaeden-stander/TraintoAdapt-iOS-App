import SwiftUI

struct TrainerScheduleView: View {
    let trainer: User
    @StateObject private var viewModel: TrainerDashboardViewModel

    init(trainer: User) {
        self.trainer = trainer
        _viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(trainerID: trainer.id))
    }

    var body: some View {
        List {
            if viewModel.todaysSessions.isEmpty && viewModel.upcomingSessions.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "calendar", message: "No sessions on your schedule yet.")
            }

            if !viewModel.todaysSessions.isEmpty {
                Section("Today") {
                    ForEach(viewModel.todaysSessions) { booking in
                        row(for: booking)
                    }
                }
            }

            if !viewModel.upcomingSessions.isEmpty {
                Section("Upcoming") {
                    ForEach(viewModel.upcomingSessions) { booking in
                        row(for: booking)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Schedule")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private func row(for booking: Booking) -> some View {
        BookingRow(booking: booking, trainerName: trainer.fullName, clientName: clientName(for: booking))
            .swipeActions(edge: .trailing) {
                Button("Complete") {
                    Task { await viewModel.markCompleted(booking) }
                }
                .tint(.green)
                Button("Cancel", role: .destructive) {
                    Task { await viewModel.cancel(booking) }
                }
            }
    }

    private func clientName(for booking: Booking) -> String {
        viewModel.clients.first(where: { $0.id == booking.clientID })?.fullName ?? "Client"
    }
}
