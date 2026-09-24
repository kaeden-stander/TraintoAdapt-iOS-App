import SwiftUI

/// Applies the TrainToAdapt cyan to each live screen's navigation bar, so
/// the brand shows up throughout the real client experience, not just on
/// the login screen. Dark (black) title/icon text since the cyan is light.
extension View {
    func brandedNavigationBar() -> some View {
        self
            .toolbarBackground(Color.brandPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }
}
