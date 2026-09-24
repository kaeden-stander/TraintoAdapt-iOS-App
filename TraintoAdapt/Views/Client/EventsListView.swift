import SwiftUI

struct EventsListView: View {
    let currentUser: User
    @StateObject private var viewModel: EventsViewModel

    init(currentUser: User) {
        self.currentUser = currentUser
        _viewModel = StateObject(wrappedValue: EventsViewModel(currentUserID: currentUser.id))
    }

    var body: some View {
        List {
            if viewModel.events.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "star", message: "No upcoming events right now.")
            }
            ForEach(viewModel.events) { event in
                EventRow(event: event, isAttending: event.isAttending(currentUser.id)) {
                    Task { await viewModel.toggleRSVP(event) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Events")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Couldn't update RSVP", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK") { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }
}

struct EventRow: View {
    let event: Event
    let isAttending: Bool
    let onToggleRSVP: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(event.category.rawValue, systemImage: event.category.systemImage)
                    .font(Font.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                Spacer()
                Text(event.date.formatted(date: .abbreviated, time: .shortened))
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
            }

            Text(event.title).font(Font.headline)
            Text(event.eventDescription)
                .font(Font.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(Font.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(event.isFull ? "Full" : "\(event.spotsRemaining) spots left")
                    .font(Font.caption.weight(.medium))
                    .foregroundStyle(event.isFull ? .red : .secondary)
            }

            Button {
                onToggleRSVP()
            } label: {
                Text(isAttending ? "Going ✓" : "RSVP")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isAttending ? Color.brandSecondary : Color.brandPrimary)
            .disabled(!isAttending && event.isFull)
        }
        .padding(.vertical, 6)
    }
}
