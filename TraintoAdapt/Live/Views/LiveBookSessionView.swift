import SwiftUI

struct LiveBookSessionView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var viewModel: LiveBookingViewModel
    @State private var safariURL: URL?
    @State private var pendingSlot: Slot?
    @State private var notes: String = ""
    @State private var selectedDay: Date?

    init(session: LiveSessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: LiveBookingViewModel(session: session))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if session.needsWaiver {
                    WaiverBanner(waiverURL: session.me?.waiver.url, safariURL: $safariURL)
                        .padding(.horizontal)
                }

                if !viewModel.upcomingBookings.isEmpty {
                    upcomingSection
                }

                if !session.needsWaiver {
                    availabilitySection
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(Font.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.brandInk)
        .navigationTitle("Book")
        .task {
            await session.refreshMe()
            await viewModel.load()
            selectFirstAvailableDay()
        }
        .refreshable {
            await session.refreshMe()
            await viewModel.load()
        }
        .onChange(of: viewModel.openSlotsByDay.map(\.day)) { _, _ in
            selectFirstAvailableDay()
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

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Upcoming Sessions")
                .font(Font.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(viewModel.upcomingBookings) { booking in
                    LiveBookingRow(booking: booking)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .swipeActions {
                            Button("Cancel", role: .destructive) {
                                Task { await viewModel.cancel(booking) }
                            }
                        }
                    if booking.id != viewModel.upcomingBookings.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available Sessions")
                .font(Font.headline)
                .padding(.horizontal)

            if viewModel.openSlotsByDay.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "calendar", message: "No open slots in the next few weeks.")
                    .padding(.horizontal)
            } else {
                dayPicker

                if let selectedDay, let group = viewModel.openSlotsByDay.first(where: { $0.day == selectedDay }) {
                    timeGrid(for: group.slots)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.openSlotsByDay, id: \.day) { group in
                    Button {
                        selectedDay = group.day
                    } label: {
                        VStack(spacing: 4) {
                            Text(group.day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(Font.caption2.weight(.semibold))
                                .textCase(.uppercase)
                            Text(group.day.formatted(.dateTime.day()))
                                .font(Font.title3.bold())
                        }
                        .frame(width: 56, height: 64)
                        .background(
                            selectedDay == group.day ? Color.brandPrimary : Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .foregroundStyle(selectedDay == group.day ? .black : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private func timeGrid(for slots: [Slot]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 10)], spacing: 10) {
            ForEach(slots) { slot in
                Button {
                    pendingSlot = slot
                    notes = ""
                } label: {
                    Text(slot.startsAt.formatted(date: .omitted, time: .shortened))
                        .font(Font.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .tint(Color.brandPrimary)
            }
        }
    }

    private func selectFirstAvailableDay() {
        if selectedDay == nil || !viewModel.openSlotsByDay.contains(where: { $0.day == selectedDay }) {
            selectedDay = viewModel.openSlotsByDay.first?.day
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
