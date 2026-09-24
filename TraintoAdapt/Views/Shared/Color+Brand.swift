import SwiftUI

extension Color {
    /// TrainToAdapt's primary brand colour, matching `AccentColor` in the
    /// asset catalog. Kept as a separate constant so it can be referenced
    /// without pulling in the asset catalog symbol in previews/tests.
    static let brandPrimary = Color("AccentColor", bundle: .main)
}
