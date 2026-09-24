import SwiftUI

struct TrainerClientDetailView: View {
    let trainer: User
    let client: User

    @StateObject private var bookingViewModel: BookingViewModel

    init(trainer: User, client: User) {
        self.trainer = trainer
        self.client = client
        _bookingViewModel = StateObject(wrappedValue: BookingViewModel(clientID: client.id))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    InitialsAvatar(initials: client.initials)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.fullName).font(Font.headline)
                        Text(client.email).font(Font.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Sessions") {
                if bookingViewModel.upcomingBookings.isEmpty {
                    Text("No upcoming sessions.").foregroundStyle(.secondary)
                } else {
                    ForEach(bookingViewModel.upcomingBookings) { booking in
                        BookingRow(booking: booking, trainerName: trainer.fullName)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(client.firstName)
        .task {
            await bookingViewModel.load()
        }
    }
}
