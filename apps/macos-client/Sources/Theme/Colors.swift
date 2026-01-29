import SwiftUI

extension Color {
    // Brand colors
    static let electricViolet = Color(hex: "5F06E4")
    static let pulsyncDark = Color(hex: "0F111A")
    static let pulsyncLight = Color.white

    // TikTok-style colors
    static let tikTokRed = Color(hex: "FE2C55")
    static let tikTokPink = Color(hex: "FF6B9D")

    // Action button colors
    static let actionButtonBackground = Color.white.opacity(0.15)
    static let actionButtonActive = Color.white.opacity(0.25)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct PulsyncTheme {
    static let primary = Color.electricViolet
    static let background = Color.pulsyncDark
    static let surface = Color(hex: "1A1D2E")
    static let textPrimary = Color.white
    static let textSecondary = Color.gray

    // TikTok-style additions
    static let likeRed = Color.tikTokRed
    static let followBlue = Color(hex: "69C9D0")
}

// MARK: - Gradients

extension LinearGradient {
    /// Bottom gradient overlay for content cards (TikTok-style)
    static let bottomFade = LinearGradient(
        colors: [
            .clear,
            .black.opacity(0.3),
            .black.opacity(0.7)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Top gradient for floating tabs
    static let topFade = LinearGradient(
        colors: [
            .black.opacity(0.5),
            .black.opacity(0.2),
            .clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Animation Constants

struct PulsyncAnimation {
    /// Duration for like heart animation
    static let likeDuration: Double = 0.4

    /// Duration for button press feedback
    static let buttonPress: Double = 0.1

    /// Duration for follow button transition
    static let followTransition: Double = 0.25

    /// Spring animation for bouncy effects
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.6)

    /// Smooth animation for state changes
    static let smooth = Animation.easeInOut(duration: 0.25)

    /// Rotation duration for audio disc
    static let discRotation: Double = 3.0
}

// MARK: - Material Styles

extension ShapeStyle where Self == Material {
    /// Frosted glass effect for action buttons (YouTube Shorts style)
    static var frostedGlass: Material {
        .ultraThinMaterial
    }
}

// MARK: - Shadow Styles

extension View {
    /// Subtle drop shadow for floating elements
    func floatingShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    /// Text shadow for readability over images
    func textShadow() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }
}
