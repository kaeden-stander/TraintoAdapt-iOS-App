import SwiftUI

struct AdminUsersView: View {
    let role: UserRole
    let title: String
    @StateObject private var viewModel = AdminDashboardViewModel()

    private var users: [User] {
        switch role {
        case .client: viewModel.clients
        case .trainer: viewModel.trainers
        case .admin: viewModel.admins
        }
    }

    var body: some View {
        List {
            if users.isEmpty && !viewModel.isLoading {
                EmptyStateRow(systemImage: "person.slash", message: "No \(title.lowercased()) yet.")
            }
            ForEach(users) { user in
                NavigationLink {
                    AdminUserDetailView(user: user, viewModel: viewModel)
                } label: {
                    HStack(spacing: 12) {
                        InitialsAvatar(initials: user.initials)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName).font(.subheadline.weight(.medium))
                            Text(role == .client ? user.membershipStatus.displayName : (user.specialties.first ?? "Trainer"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

struct AdminUserDetailView: View {
    let user: User
    @ObservedObject var viewModel: AdminDashboardViewModel
    @State private var selectedTrainerID: UUID?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    InitialsAvatar(initials: user.initials)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName).font(.headline)
                        Text(user.email).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Role") {
                Picker("Role", selection: Binding(
                    get: { user.role },
                    set: { newRole in Task { await viewModel.updateRole(user, to: newRole) } }
                )) {
                    ForEach(UserRole.allCases) { role in
                        Text(role.displayName).tag(role)
                    }
                }
            }

            if user.role == .client {
                Section("Membership") {
                    Picker("Status", selection: Binding(
                        get: { user.membershipStatus },
                        set: { newStatus in Task { await viewModel.updateMembership(user, to: newStatus) } }
                    )) {
                        ForEach(MembershipStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }

                    Picker("Assigned Trainer", selection: Binding(
                        get: { user.assignedTrainerID },
                        set: { newTrainerID in Task { await viewModel.assignTrainer(user, trainerID: newTrainerID) } }
                    )) {
                        Text("None").tag(UUID?.none)
                        ForEach(viewModel.trainers) { trainer in
                            Text(trainer.fullName).tag(Optional(trainer.id))
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    Task { await viewModel.deleteUser(user) }
                } label: {
                    Text("Remove Account")
                }
            }
        }
        .navigationTitle(user.firstName)
    }
}
