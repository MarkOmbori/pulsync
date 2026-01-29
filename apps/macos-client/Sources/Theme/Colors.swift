import SwiftUI

// MARK: - Color Hex Initializer

extension Color {
    /// Initialize color from hex string (e.g., "6366F1" or "#6366F1")
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
            (a, r, g, b) = (255, 128, 128, 128)
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

// MARK: - Legacy Color Names (for backwards compatibility)

extension Color {
    // Brand colors - now mapped to new design system
    static let electricViolet = Color(hex: "6366F1")  // Primary brand color
    static let pulsyncDark = Color(hex: "0A0A0B")     // Background dark
    static let pulsyncLight = Color.white

    // Action colors - mapped to semantic colors
    static let tikTokRed = Color(hex: "EF4444")       // Like color
    static let tikTokPink = Color(hex: "FF6B9D")

    // Action button colors
    static let actionButtonBackground = Color.white.opacity(0.15)
    static let actionButtonActive = Color.white.opacity(0.25)
}

// MARK: - PulsyncTheme (Legacy Bridge to New Design System)

/// Main theme configuration.
/// Uses the new design system tokens under the hood.
struct PulsyncTheme {
    // Brand
    static let primary = Color(hex: "6366F1")
    static let primaryLight = Color(hex: "818CF8")
    static let primaryDark = Color(hex: "4F46E5")
    static let secondary = Color(hex: "14B8A6")

    // Surfaces
    static let background = Color(hex: "0A0A0B")
    static let surface = Color(hex: "141416")
    static let surfaceElevated = Color(hex: "1C1C1E")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")
    static let textMuted = Color(hex: "6B7280")

    // Semantic Actions
    static let likeRed = Color(hex: "EF4444")
    static let followBlue = Color(hex: "3B82F6")
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // Borders
    static let border = Color.white.opacity(0.1)
    static let borderStrong = Color.white.opacity(0.2)
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
