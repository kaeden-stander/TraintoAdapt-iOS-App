import SwiftUI

/// Exploratory admin schedule view — see `LiveAdminViewModel` for why.
struct LiveAdminView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var viewModel: LiveAdminViewModel

    init(session: LiveSessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: LiveAdminViewModel(session: session))
    }

    var body: some View {
        List {
            if viewModel.likelyOwnBookingsOnly {
                Section {
                    Label(
                        "This looks like your own bookings only — the backend may not yet grant admin accounts a broader view. Worth checking with whoever built the API.",
                        systemImage: "info.circle"
                    )
                    .font(Font.footnote)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack(spacing: 12) {
                    StatTile(title: "Upcoming Sessions", value: "\(viewModel.upcomingCount)", systemImage: "calendar")
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }

            if viewModel.bookingsByDay.isEmpty && !viewModel.isLoading {
                Section {
                    EmptyStateRow(systemImage: "calendar", message: "No upcoming sessions.")
                }
            }

            ForEach(viewModel.bookingsByDay, id: \.day) { group in
                Section(group.day.formatted(date: .complete, time: .omitted)) {
                    ForEach(group.bookings) { booking in
                        AdminBookingRow(booking: booking)
                            .swipeActions {
                                Button("Cancel", role: .destructive) {
                                    Task { await viewModel.cancel(booking) }
                                }
                            }
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Admin")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct AdminBookingRow: View {
    let booking: RemoteBooking

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.clientName ?? booking.clientEmail ?? "Client")
                    .font(Font.subheadline.weight(.semibold))
                Text(booking.startsAt.formatted(date: .omitted, time: .shortened) + " – " + booking.endsAt.formatted(date: .omitted, time: .shortened))
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
                if let notes = booking.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Font.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            LiveStatusBadge(status: booking.status)
        }
        .padding(.vertical, 2)
    }
}
