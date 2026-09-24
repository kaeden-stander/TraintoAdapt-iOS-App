import SwiftUI

extension Color {
    /// TrainToAdapt's primary brand colour — the cyan from the logo mark,
    /// matching `AccentColor` in the asset catalog. Kept as a separate
    /// constant so it can be referenced without pulling in the asset
    /// catalog symbol in previews/tests.
    static let brandPrimary = Color("AccentColor", bundle: .main)

    /// The warm grey from the logo's "T", used for secondary/muted brand
    /// accents (e.g. the admin role, subtle borders) so the app doesn't
    /// lean on the cyan for everything.
    static let brandSecondary = Color("BrandSecondary", bundle: .main)

    /// The near-black used behind the logo mark. Used for brand moments
    /// (login screen) rather than as a general-purpose background, so the
    /// rest of the app keeps native light/dark mode support.
    static let brandInk = Color(red: 0.03, green: 0.03, blue: 0.03)
}
