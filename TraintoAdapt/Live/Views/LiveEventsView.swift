import SwiftUI

struct LiveEventsView: View {
    @ObservedObject var session: LiveSessionStore
    @StateObject private var viewModel = LiveEventsViewModel()
    @State private var showingNewEvent = false

    private var isAdmin: Bool { session.me?.isAdmin ?? false }
    private var currentUserID: UUID? { session.me.flatMap { UUID(uuidString: $0.profile.id) } }

    var body: some View {
        List {
            Section {
                Label(
                    "Events are stored on this device for now, until the backend adds an events API — they won't show up on other phones yet.",
                    systemImage: "info.circle"
                )
                .font(Font.footnote)
                .foregroundStyle(.secondary)
            }

            if viewModel.events.isEmpty {
                EmptyStateRow(systemImage: "star", message: "No events yet.")
            } else {
                ForEach(viewModel.events) { event in
                    EventRow(
                        event: event,
                        isAttending: currentUserID.map(event.isAttending) ?? false,
                        onToggleRSVP: {
                            guard let currentUserID else { return }
                            viewModel.toggleRSVP(event, userID: currentUserID)
                        }
                    )
                    .swipeActions {
                        if isAdmin {
                            Button("Delete", role: .destructive) {
                                viewModel.delete(event)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Events")
        .toolbar {
            if isAdmin {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewEvent = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showingNewEvent) {
            NavigationStack {
                LiveNewEventView(viewModel: viewModel)
            }
        }
        .onAppear { viewModel.load() }
    }
}

private struct LiveNewEventView: View {
    @ObservedObject var viewModel: LiveEventsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var location = "TrainToAdapt Studio, Manchester"
    @State private var capacity = 20
    @State private var category: EventCategory = .workshop

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...5)
                Picker("Category", selection: $category) {
                    ForEach(EventCategory.allCases) { category in
                        Label(category.rawValue, systemImage: category.systemImage).tag(category)
                    }
                }
            }

            Section("Logistics") {
                DatePicker("Date & Time", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                TextField("Location", text: $location)
                Stepper("Capacity: \(capacity)", value: $capacity, in: 5...200, step: 5)
            }
        }
        .navigationTitle("New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    viewModel.create(
                        title: title,
                        description: description,
                        date: date,
                        location: location,
                        capacity: capacity,
                        category: category
                    )
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
        }
    }
}
