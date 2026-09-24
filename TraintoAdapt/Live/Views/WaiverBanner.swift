import SwiftUI

/// Shown wherever booking would otherwise be possible. The client has to be
/// signed in on the website to sign the waiver (per the backend guide), so
/// this opens it in Safari rather than trying to render it in-app.
struct WaiverBanner: View {
    let waiverURL: URL?
    @Binding var safariURL: URL?

    var body: some View {
        Button {
            safariURL = waiverURL.map { SupabaseAuthService.shared.authenticatedURL($0) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "signature")
                    .font(Font.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign your waiver to book sessions")
                        .font(Font.subheadline.weight(.semibold))
                    Text("Tap to open it and sign on the website.")
                        .font(Font.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Font.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(waiverURL == nil)
    }
}
