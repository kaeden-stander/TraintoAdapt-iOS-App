import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(spacing: 16) {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.password)
                            .focused($focusedField, equals: .password)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            focusedField = nil
                            Task { await viewModel.signIn(into: appState) }
                        } label: {
                            if viewModel.isSigningIn {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Sign In")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!viewModel.canSubmit)
                    }
                    .padding(.horizontal)

                    demoAccess
                }
                .padding(.vertical, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 44))
                .foregroundStyle(Color.brandPrimary)
                .padding(20)
                .background(Circle().fill(Color.brandPrimary.opacity(0.12)))

            Text("TrainToAdapt")
                .font(.largeTitle.bold())
            Text("traintoadapt.co.uk")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var demoAccess: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick demo access")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(UserRole.allCases) { role in
                    Button {
                        viewModel.fillDemoCredentials(for: role)
                        Task { await viewModel.signIn(into: appState) }
                    } label: {
                        Label(role.displayName, systemImage: role.systemImage)
                            .font(.footnote.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
