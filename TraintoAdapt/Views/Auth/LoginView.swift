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
                                .font(Font.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            focusedField = nil
                            Task { await viewModel.signIn(into: appState) }
                        } label: {
                            if viewModel.isSigningIn {
                                ProgressView()
                                    .tint(.black)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.brandPrimary)
                        .controlSize(.large)
                        .disabled(!viewModel.canSubmit)
                    }
                    .padding(.horizontal)

                    demoAccess
                }
                .padding(.vertical, 40)
            }
            .background(Color.brandInk.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.18))
                    .frame(width: 128, height: 128)
                    .blur(radius: 6)

                Image("BrandMark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Text("TrainToAdapt")
                .font(Font.largeTitle.bold())
                .foregroundStyle(.white)
            Text("traintoadapt.co.uk")
                .font(Font.subheadline)
                .foregroundStyle(Color.brandSecondary)
        }
    }

    private var demoAccess: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick demo access")
                .font(Font.caption)
                .foregroundStyle(Color.brandSecondary)
                .textCase(.uppercase)

            HStack(spacing: 10) {
                ForEach(UserRole.allCases) { role in
                    Button {
                        viewModel.fillDemoCredentials(for: role)
                        Task { await viewModel.signIn(into: appState) }
                    } label: {
                        Label(role.displayName, systemImage: role.systemImage)
                            .font(Font.footnote.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brandSecondary)
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
