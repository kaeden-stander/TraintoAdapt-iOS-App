import SwiftUI

struct NewBookingView: View {
    let client: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BookingViewModel

    @State private var selectedTrainerID: UUID?
    @State private var sessionType: SessionType = .personalTraining
    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var duration: Int = 60
    @State private var location: String = "TrainToAdapt Studio, Manchester"
    @State private var notes: String = ""
    @State private var isSubmitting = false

    init(client: User) {
        self.client = client
        _viewModel = StateObject(wrappedValue: BookingViewModel(clientID: client.id))
    }

    var body: some View {
        Form {
            Section("Trainer") {
                Picker("Trainer", selection: $selectedTrainerID) {
                    Text("Any available").tag(UUID?.none)
                    ForEach(viewModel.trainers) { trainer in
                        Text(trainer.fullName).tag(Optional(trainer.id))
                    }
                }
            }

            Section("Session") {
                Picker("Type", selection: $sessionType) {
                    ForEach(SessionType.allCases) { type in
                        Label(type.rawValue, systemImage: type.systemImage).tag(type)
                    }
                }
                DatePicker("Date & Time", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                Picker("Duration", selection: $duration) {
                    Text("30 min").tag(30)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                    Text("90 min").tag(90)
                }
                TextField("Location", text: $location)
            }

            Section("Notes (optional)") {
                TextField("Anything your trainer should know?", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .navigationTitle("Book a Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Book") {
                    Task { await submit() }
                }
                .disabled(isSubmitting || viewModel.trainers.isEmpty)
            }
        }
        .task { await viewModel.load() }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        let trainerID = selectedTrainerID ?? client.assignedTrainerID ?? viewModel.trainers.first?.id
        guard let trainerID else { return }
        await viewModel.book(
            trainerID: trainerID,
            sessionType: sessionType,
            startDate: date,
            durationMinutes: duration,
            location: location,
            notes: notes.isEmpty ? nil : notes
        )
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}
