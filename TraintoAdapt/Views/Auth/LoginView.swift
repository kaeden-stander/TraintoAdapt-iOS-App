import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var liveAuth = LiveAuthViewModel()
    @StateObject private var demoAuth = AuthViewModel()
    @FocusState private var focusedField: Field?
    @State private var showingDemoMode = false

    private enum Field: Hashable {
        case fullName, email, password
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    modeSwitcher
                    formFields
                    messages
                    oauthButtons
                    demoModeDisclosure
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

    private var modeSwitcher: some View {
        Picker("Mode", selection: $liveAuth.mode) {
            Text("Sign In").tag(LiveAuthViewModel.Mode.signIn)
            Text("Create Account").tag(LiveAuthViewModel.Mode.signUp)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            if liveAuth.mode == .signUp {
                TextField("Full name", text: $liveAuth.fullName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .fullName)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            TextField("Email", text: $liveAuth.email)
                .textContentType(.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            SecureField("Password (min. 8 characters)", text: $liveAuth.password)
                .textContentType(liveAuth.mode == .signIn ? .password : .newPassword)
                .focused($focusedField, equals: .password)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                focusedField = nil
                Task { await liveAuth.submit() }
            } label: {
                if liveAuth.isSubmitting {
                    ProgressView().tint(.black).frame(maxWidth: .infinity)
                } else {
                    Text(liveAuth.mode == .signIn ? "Sign In" : "Create Account")
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brandPrimary)
            .controlSize(.large)
            .disabled(!liveAuth.canSubmit)

            if liveAuth.mode == .signIn {
                Button("Forgot password?") {
                    Task { await liveAuth.resetPassword() }
                }
                .font(Font.footnote)
                .foregroundStyle(Color.brandSecondary)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var messages: some View {
        if let errorMessage = liveAuth.errorMessage {
            Text(errorMessage)
                .font(Font.footnote)
                .foregroundStyle(.red)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let infoMessage = liveAuth.infoMessage {
            Text(infoMessage)
                .font(Font.footnote)
                .foregroundStyle(Color.brandPrimary)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var oauthButtons: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().fill(Color.brandSecondary.opacity(0.3)).frame(height: 1)
                Text("or").font(Font.caption).foregroundStyle(Color.brandSecondary)
                Rectangle().fill(Color.brandSecondary.opacity(0.3)).frame(height: 1)
            }

            SignInWithAppleButton(.signIn) { request in
                liveAuth.prepareAppleRequest(request)
            } onCompletion: { result in
                Task { await liveAuth.handleAppleCompletion(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await liveAuth.signInWithGoogle() }
            } label: {
                Label("Sign in with Google", systemImage: "globe")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }

    private var demoModeDisclosure: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation { showingDemoMode.toggle() }
            } label: {
                Label(showingDemoMode ? "Hide demo mode" : "Explore in demo mode", systemImage: "eye")
                    .font(Font.footnote)
                    .foregroundStyle(Color.brandSecondary)
            }

            if showingDemoMode {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Demo mode uses sample data — trainer and admin dashboards aren't backed by the real system yet.")
                        .font(Font.caption)
                        .foregroundStyle(Color.brandSecondary)

                    HStack(spacing: 10) {
                        ForEach(UserRole.allCases) { role in
                            Button {
                                demoAuth.fillDemoCredentials(for: role)
                                Task { await demoAuth.signIn(into: appState) }
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
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
