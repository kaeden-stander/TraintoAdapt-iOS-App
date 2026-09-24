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

    /// The near-black used app-wide as the base background, matching the
    /// login screen so the whole app reads as one consistent, dark brand
    /// surface rather than switching to a lighter system background.
    static let brandInk = Color(red: 0.03, green: 0.03, blue: 0.03)

    /// A slightly-raised solid surface for cards and rows on top of
    /// `brandInk`. Solid rather than translucent material, since a black
    /// background makes `.thinMaterial`'s blur read muddy instead of crisp.
    static let brandSurface = Color(red: 0.11, green: 0.11, blue: 0.12)
}
