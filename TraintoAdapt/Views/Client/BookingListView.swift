import SwiftUI

struct BookingListView: View {
    let client: User
    @StateObject private var viewModel: BookingViewModel
    @State private var showingNewBooking = false

    init(client: User) {
        self.client = client
        _viewModel = StateObject(wrappedValue: BookingViewModel(clientID: client.id))
    }

    var body: some View {
        List {
            if viewModel.upcomingBookings.isEmpty && viewModel.pastBookings.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "calendar", message: "No sessions yet. Tap + to book your first session.")
            }

            if !viewModel.upcomingBookings.isEmpty {
                Section("Upcoming") {
                    ForEach(viewModel.upcomingBookings) { booking in
                        BookingRow(booking: booking, trainerName: trainerName(for: booking))
                            .swipeActions {
                                Button("Cancel", role: .destructive) {
                                    Task { await viewModel.cancel(booking) }
                                }
                            }
                    }
                }
            }

            if !viewModel.pastBookings.isEmpty {
                Section("Past") {
                    ForEach(viewModel.pastBookings) { booking in
                        BookingRow(booking: booking, trainerName: trainerName(for: booking))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewBooking = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewBooking) {
            NavigationStack {
                NewBookingView(client: client)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private func trainerName(for booking: Booking) -> String {
        viewModel.trainers.first(where: { $0.id == booking.trainerID })?.fullName ?? "Trainer"
    }
}
