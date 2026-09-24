import SwiftUI

struct TrainerClientsView: View {
    let trainer: User
    @StateObject private var viewModel: TrainerDashboardViewModel

    init(trainer: User) {
        self.trainer = trainer
        _viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(trainerID: trainer.id))
    }

    var body: some View {
        List {
            if viewModel.clients.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "person.2", message: "No clients assigned yet.")
            }
            ForEach(viewModel.clients) { client in
                NavigationLink {
                    TrainerClientDetailView(trainer: trainer, client: client)
                } label: {
                    HStack(spacing: 12) {
                        InitialsAvatar(initials: client.initials)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.fullName).font(.subheadline.weight(.medium))
                            Text(client.membershipStatus.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Clients")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}
