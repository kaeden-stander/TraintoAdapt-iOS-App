import SwiftUI
import SafariServices

/// Wraps `SFSafariViewController` for the flows the backend guide says must
/// open in Safari rather than a plain in-app browser: the waiver, the
/// Stripe billing portal, and checkout. Using the real Safari view (not a
/// custom WKWebView) keeps saved passwords/autofill and Apple/Google's own
/// sign-in cookies working.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

/// Presents `url` as a `.sheet` and calls `onDismiss` when the sheet closes
/// — the backend guide notes that after checkout or a billing change,
/// `/me` should be reloaded once the Safari view closes.
struct SafariSheetModifier: ViewModifier {
    @Binding var url: URL?
    var onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content.sheet(isPresented: Binding(
            get: { url != nil },
            set: { isPresented in if !isPresented { url = nil } }
        ), onDismiss: onDismiss) {
            if let url {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }
}

extension View {
    func safariSheet(_ url: Binding<URL?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(SafariSheetModifier(url: url, onDismiss: onDismiss))
    }
}
