import SwiftUI

/// Brand palette sampled from the app icon's "IDK" wordmark
/// (blue → violet → coral). The global accent color lives in the asset
/// catalog (`AccentColor`) and tints controls app-wide automatically.
extension Color {
    static let brandBlue = Color(red: 0.27, green: 0.65, blue: 0.91)
    static let brandViolet = Color(red: 0.56, green: 0.49, blue: 0.91)
    static let brandCoral = Color(red: 1.00, green: 0.44, blue: 0.40)
}

extension LinearGradient {
    /// Left-to-right wordmark gradient for hero accents.
    static let brand = LinearGradient(
        colors: [.brandBlue, .brandViolet, .brandCoral],
        startPoint: .leading,
        endPoint: .trailing
    )
}
