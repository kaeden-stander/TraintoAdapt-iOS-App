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
                VStack(spacing: 24) {
                    header
                    oauthButtons
                    divider
                    modeSwitcher
                    formFields
                    messages
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 24)

                demoModeDisclosure
                    .padding(.bottom, 24)
            }
            .background(AuthBackground())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.25))
                    .frame(width: 108, height: 108)
                    .blur(radius: 14)

                Image("BrandMark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.brandPrimary.opacity(0.4), radius: 16, y: 6)
            }

            Text("TrainToAdapt")
                .font(Font.title.bold())
                .foregroundStyle(.white)
            Text("traintoadapt.co.uk")
                .font(Font.footnote)
                .foregroundStyle(Color.brandSecondary)
        }
        .padding(.bottom, 4)
    }

    private var oauthButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn) { request in
                liveAuth.prepareAppleRequest(request)
            } onCompletion: { result in
                Task { await liveAuth.handleAppleCompletion(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await liveAuth.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("Sign in with Google")
                        .font(Font.system(size: 17, weight: .medium))
                }
                .foregroundStyle(Color(red: 0.235, green: 0.251, blue: 0.263))
                .frame(maxWidth: .infinity)
            }
            .frame(height: 50)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private var divider: some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.brandSecondary.opacity(0.3)).frame(height: 1)
            Text("or sign in with email")
                .font(Font.footnote)
                .foregroundStyle(Color.brandSecondary)
                .fixedSize()
            Rectangle().fill(Color.brandSecondary.opacity(0.3)).frame(height: 1)
        }
    }

    private var modeSwitcher: some View {
        Picker("Mode", selection: $liveAuth.mode) {
            Text("Sign In").tag(LiveAuthViewModel.Mode.signIn)
            Text("Create Account").tag(LiveAuthViewModel.Mode.signUp)
        }
        .pickerStyle(.segmented)
    }

    private var formFields: some View {
        VStack(spacing: 12) {
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

            SecureField("Password", text: $liveAuth.password)
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
            .padding(.top, 4)

            if liveAuth.mode == .signIn {
                Button("Forgot password?") {
                    Task { await liveAuth.resetPassword() }
                }
                .font(Font.footnote)
                .foregroundStyle(Color.brandSecondary)
            }
        }
    }

    @ViewBuilder
    private var messages: some View {
        if let errorMessage = liveAuth.errorMessage {
            Text(errorMessage)
                .font(Font.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let infoMessage = liveAuth.infoMessage {
            Text(infoMessage)
                .font(Font.footnote)
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var demoModeDisclosure: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation { showingDemoMode.toggle() }
            } label: {
                Label(showingDemoMode ? "Hide demo mode" : "Explore in demo mode", systemImage: "eye")
                    .font(Font.caption)
                    .foregroundStyle(Color.brandSecondary.opacity(0.7))
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
        .padding(.horizontal, 24)
    }
}

/// The login screen's backdrop: the ink base, a cyan banner glow behind the
/// header, a couple of soft brand-coloured blobs for depth, and a faint dot
/// grid for texture — a bit more considered than a flat black rectangle.
private struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color.brandInk

            LinearGradient(
                colors: [Color.brandPrimary.opacity(0.32), Color.brandInk.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 380)
            .frame(maxHeight: .infinity, alignment: .top)

            Circle()
                .fill(Color.brandPrimary.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -130, y: -300)

            Circle()
                .fill(Color.brandSecondary.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: 150, y: 40)

            DotGridPattern()
                .opacity(0.05)
        }
        .ignoresSafeArea()
    }
}

private struct DotGridPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 22
            let dotSize: CGFloat = 2
            var y: CGFloat = spacing / 2
            while y < size.height {
                var x: CGFloat = spacing / 2
                while x < size.width {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.white))
                    x += spacing
                }
                y += spacing
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
