import SwiftUI

struct LiveBookSessionView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var viewModel: LiveBookingViewModel
    @State private var safariURL: URL?
    @State private var pendingSlot: Slot?
    @State private var notes: String = ""

    init(session: LiveSessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: LiveBookingViewModel(session: session))
    }

    var body: some View {
        List {
            if session.needsWaiver {
                Section {
                    WaiverBanner(waiverURL: session.me?.waiver.url, safariURL: $safariURL)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                }
            }

            if !viewModel.upcomingBookings.isEmpty {
                Section("Your Upcoming Sessions") {
                    ForEach(viewModel.upcomingBookings) { booking in
                        LiveBookingRow(booking: booking)
                            .swipeActions {
                                Button("Cancel", role: .destructive) {
                                    Task { await viewModel.cancel(booking) }
                                }
                            }
                    }
                }
            }

            if !session.needsWaiver {
                Section("Available Sessions") {
                    if viewModel.openSlotsByDay.isEmpty && !viewModel.isLoading {
                        EmptyStateRow(systemImage: "calendar", message: "No open slots in the next few weeks.")
                    }
                    ForEach(viewModel.openSlotsByDay, id: \.day) { group in
                        DisclosureGroup(group.day.formatted(date: .abbreviated, time: .omitted)) {
                            ForEach(group.slots) { slot in
                                Button {
                                    pendingSlot = slot
                                    notes = ""
                                } label: {
                                    HStack {
                                        Text(slot.startsAt.formatted(date: .omitted, time: .shortened))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(Font.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .buttonStyle(.plain)
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
        .navigationTitle("Book a Session")
        .task {
            await session.refreshMe()
            await viewModel.load()
        }
        .refreshable {
            await session.refreshMe()
            await viewModel.load()
        }
        .safariSheet($safariURL) {
            Task { await session.refreshMe() }
        }
        .sheet(item: $pendingSlot) { slot in
            NavigationStack {
                ConfirmBookingView(
                    slot: slot,
                    notes: $notes,
                    isSubmitting: viewModel.isSubmitting,
                    onConfirm: {
                        let ok = await viewModel.book(slot, notes: notes)
                        if ok { pendingSlot = nil }
                    },
                    onCancel: { pendingSlot = nil }
                )
            }
        }
    }
}

private struct ConfirmBookingView: View {
    let slot: Slot
    @Binding var notes: String
    let isSubmitting: Bool
    let onConfirm: () async -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            Section("Session") {
                LabeledContent("Date", value: slot.startsAt.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Time", value: slot.startsAt.formatted(date: .omitted, time: .shortened) + " – " + slot.endsAt.formatted(date: .omitted, time: .shortened))
            }
            Section("Notes for Adam (optional)") {
                TextField("Anything he should know?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Confirm Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSubmitting ? "Booking…" : "Book") {
                    Task { await onConfirm() }
                }
                .disabled(isSubmitting)
            }
        }
    }
}
