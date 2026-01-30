import SwiftUI

/// Miro-inspired color palette for playful, colorful UI
enum MiroColors {
    // MARK: - Primary Brand Colors
    static let miroYellow = Color(hex: "FFD02F")
    static let miroBlue = Color(hex: "4262FF")
    static let miroTeal = Color(hex: "05A4AC")

    // MARK: - Status Colors (Traffic Light)
    static let statusGreen = Color(hex: "30C85E")
    static let statusYellow = Color(hex: "FFC700")
    static let statusRed = Color(hex: "F24726")
    static let statusGray = Color(hex: "8C8C8C")

    // MARK: - Behavior Ratings
    static let ratingFilled = Color(hex: "FFD02F")
    static let ratingEmpty = Color(hex: "3A3A4D")

    // MARK: - Card Backgrounds (Light, playful pastels)
    static let cardPurple = Color(hex: "E9DFFC")
    static let cardBlue = Color(hex: "D5E8FA")
    static let cardGreen = Color(hex: "D5F5E3")
    static let cardYellow = Color(hex: "FFF5CC")
    static let cardOrange = Color(hex: "FFE5D5")
    static let cardPink = Color(hex: "FCE4EC")

    // MARK: - Dark Mode Surfaces
    static let surfaceDark = Color(hex: "1A1A2E")
    static let cardDark = Color(hex: "252540")
    static let cardDarkHover = Color(hex: "2E2E4D")

    // MARK: - Text Colors
    static let textDark = Color(hex: "1A1A2E")
    static let textMuted = Color(hex: "6B6B7B")
    static let textLight = Color(hex: "FFFFFF")

    // MARK: - Phase Colors (Project Lifecycle)
    static let phaseBraindump = Color(hex: "A78BFA")
    static let phaseKickoff = Color(hex: "60A5FA")
    static let phaseEarlyConcept = Color(hex: "34D399")
    static let phaseSolutions = Color(hex: "FBBF24")
    static let phaseRelease = Color(hex: "F472B6")

    // MARK: - Trophy/Ranking Colors
    static let goldTrophy = Color(hex: "FFD700")
    static let silverTrophy = Color(hex: "C0C0C0")
    static let bronzeTrophy = Color(hex: "CD7F32")
}

// MARK: - Corner Radius (Miro uses generous rounding)
enum MiroRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 24
    static let card: CGFloat = 20
}
