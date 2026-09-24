import SwiftUI

struct AccountView: View {
    let user: User
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: AccountViewModel

    init(user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: AccountViewModel(user: user))
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    InitialsAvatar(initials: user.initials)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName).font(Font.headline)
                        Text(user.email).font(Font.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Membership") {
                LabeledContent("Status", value: user.membershipStatus.displayName)
                LabeledContent("Member since", value: user.joinedDate.formatted(date: .abbreviated, time: .omitted))
                if let trainer = viewModel.assignedTrainer {
                    LabeledContent("Trainer", value: trainer.fullName)
                }
                if let phone = user.phoneNumber {
                    LabeledContent("Phone", value: phone)
                }
            }

            Section("Apple Watch & Health") {
                NavigationLink {
                    HealthSummaryView()
                } label: {
                    Label("Health & Activity Data", systemImage: "applewatch")
                }
            }

            Section {
                Button(role: .destructive) {
                    appState.signOut()
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Account")
        .task { await viewModel.load() }
    }
}

struct InitialsAvatar: View {
    let initials: String

    var body: some View {
        Circle()
            .fill(Color.brandPrimary.opacity(0.15))
            .overlay(
                Text(initials)
                    .font(Font.headline)
                    .foregroundStyle(Color.brandPrimary)
            )
    }
}
