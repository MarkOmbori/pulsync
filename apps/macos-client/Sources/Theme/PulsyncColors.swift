import SwiftUI

// MARK: - Pulsync Color System

/// Unified color palette for Pulsync design system.
/// Based on the master design spec with semantic naming.
enum PulsyncColors {
    // MARK: - Brand Colors

    /// Primary brand color - used for primary actions, links, and accents
    static let primary = Color(hex: "6366F1")

    /// Lighter variant of primary - used for hover states
    static let primaryLight = Color(hex: "818CF8")

    /// Darker variant of primary - used for active/pressed states
    static let primaryDark = Color(hex: "4F46E5")

    /// Secondary brand color - used for secondary actions
    static let secondary = Color(hex: "14B8A6")

    // MARK: - Surface Colors

    /// Main background color
    static let background = Color("Background")

    /// Card and content surface color
    static let surface = Color("Surface")

    /// Elevated surface (modals, popovers)
    static let surfaceElevated = Color("SurfaceElevated")

    /// Overlay color for modals/sheets
    static let overlay = Color.black.opacity(0.5)

    // MARK: - Text Colors

    /// Primary text color - highest emphasis
    static let textPrimary = Color("TextPrimary")

    /// Secondary text color - medium emphasis
    static let textSecondary = Color("TextSecondary")

    /// Muted text color - lowest emphasis (captions, metadata)
    static let textMuted = Color("TextMuted")

    /// Inverse text - for use on colored backgrounds
    static let textInverse = Color.white

    // MARK: - Semantic Action Colors

    /// Like/heart action color
    static let like = Color(hex: "EF4444")

    /// Follow action color
    static let follow = Color(hex: "3B82F6")

    /// Success state color
    static let success = Color(hex: "22C55E")

    /// Warning state color
    static let warning = Color(hex: "F59E0B")

    /// Error state color
    static let error = Color(hex: "EF4444")

    // MARK: - Border Colors

    /// Subtle border color
    static let border = Color("Border")

    /// Strong border color for more emphasis
    static let borderStrong = Color("BorderStrong")

    // MARK: - Fallback Colors (when asset catalog not available)

    enum Fallback {
        // Light mode
        static let backgroundLight = Color.white
        static let surfaceLight = Color(hex: "F8F9FA")
        static let surfaceElevatedLight = Color.white
        static let textPrimaryLight = Color.black
        static let textSecondaryLight = Color(hex: "6B7280")
        static let textMutedLight = Color(hex: "9CA3AF")
        static let borderLight = Color.black.opacity(0.1)
        static let borderStrongLight = Color.black.opacity(0.2)

        // Dark mode
        static let backgroundDark = Color(hex: "0A0A0B")
        static let surfaceDark = Color(hex: "141416")
        static let surfaceElevatedDark = Color(hex: "1C1C1E")
        static let textPrimaryDark = Color.white
        static let textSecondaryDark = Color(hex: "9CA3AF")
        static let textMutedDark = Color(hex: "6B7280")
        static let borderDark = Color.white.opacity(0.1)
        static let borderStrongDark = Color.white.opacity(0.2)
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Primary brand gradient
    static let primaryGradient = LinearGradient(
        colors: [PulsyncColors.primary, Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Bottom fade gradient for content cards
    static let contentFade = LinearGradient(
        colors: [
            .clear,
            .black.opacity(0.4),
            .black.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Top fade gradient for floating navigation
    static let navigationFade = LinearGradient(
        colors: [
            .black.opacity(0.6),
            .black.opacity(0.3),
            .clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Glass effect gradient
    static let glassGradient = LinearGradient(
        colors: [
            .white.opacity(0.1),
            .white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// NOTE: Color.init(hex:) is defined in Colors.swift to avoid duplication

// MARK: - Adaptive Colors (Computed based on color scheme)

extension PulsyncColors {
    /// Returns adaptive background color
    @MainActor
    static func adaptiveBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Fallback.backgroundDark : Fallback.backgroundLight
    }

    /// Returns adaptive surface color
    @MainActor
    static func adaptiveSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Fallback.surfaceDark : Fallback.surfaceLight
    }

    /// Returns adaptive text primary color
    @MainActor
    static func adaptiveTextPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Fallback.textPrimaryDark : Fallback.textPrimaryLight
    }

    /// Returns adaptive text secondary color
    @MainActor
    static func adaptiveTextSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Fallback.textSecondaryDark : Fallback.textSecondaryLight
    }
}
