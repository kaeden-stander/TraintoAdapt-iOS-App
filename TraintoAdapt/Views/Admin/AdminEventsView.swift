import SwiftUI

struct AdminEventsView: View {
    let admin: User
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var showingNewEvent = false

    var body: some View {
        List {
            if viewModel.allEvents.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "star", message: "No events scheduled. Tap + to add one.")
            }
            ForEach(viewModel.allEvents) { event in
                VStack(alignment: .leading, spacing: 6) {
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
                    Text("\(event.attendeeIDs.count)/\(event.capacity) attending · \(event.location)")
                        .font(Font.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.deleteEvent(event) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Events")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewEvent = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNewEvent) {
            NavigationStack {
                AdminNewEventView(viewModel: viewModel)
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

struct AdminNewEventView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var location = "TrainToAdapt Studio, Manchester"
    @State private var capacity = 20
    @State private var category: EventCategory = .workshop
    @State private var hostTrainerID: UUID?
    @State private var isSaving = false

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
                Picker("Host Trainer", selection: $hostTrainerID) {
                    Text("None").tag(UUID?.none)
                    ForEach(viewModel.trainers) { trainer in
                        Text(trainer.fullName).tag(Optional(trainer.id))
                    }
                }
            }
        }
        .navigationTitle("New Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") { Task { await save() } }
                    .disabled(title.isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        await viewModel.createEvent(
            title: title,
            description: description,
            date: date,
            location: location,
            capacity: capacity,
            category: category,
            hostTrainerID: hostTrainerID
        )
        dismiss()
    }
}
