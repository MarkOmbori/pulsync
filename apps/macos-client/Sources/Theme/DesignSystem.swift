import SwiftUI

// MARK: - Pulsync Design System

/// Central design system hub that provides unified access to all design tokens.
/// Import this file to access colors, typography, spacing, and component styles.
///
/// ## Usage
/// ```swift
/// Text("Hello")
///     .font(.pulsyncBody)
///     .foregroundColor(PulsyncColors.textPrimary)
///     .padding(PulsyncSpacing.md)
/// ```
enum DesignSystem {
    // MARK: - Animation Constants

    enum Animation {
        /// Instant feedback (50ms)
        static let instant: Double = 0.05

        /// Fast micro-interactions (150ms)
        static let fast: Double = 0.15

        /// Standard transitions (250ms)
        static let normal: Double = 0.25

        /// Slow, complex animations (400ms)
        static let slow: Double = 0.4

        /// Page transitions (600ms)
        static let slower: Double = 0.6

        /// Bouncy spring animation for likes, buttons
        static var bouncy: SwiftUI.Animation {
            .spring(response: 0.35, dampingFraction: 0.6)
        }

        /// Smooth easing for state transitions
        static var smooth: SwiftUI.Animation {
            .easeInOut(duration: normal)
        }

        /// Quick animation for micro-feedback
        static var quick: SwiftUI.Animation {
            .easeOut(duration: fast)
        }
    }
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply bouncy animation
    func bouncyAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Animation.bouncy, value: value)
    }

    /// Apply smooth animation
    func smoothAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Animation.smooth, value: value)
    }

    /// Apply quick animation
    func quickAnimation<V: Equatable>(value: V) -> some View {
        self.animation(DesignSystem.Animation.quick, value: value)
    }
}

// MARK: - Glass Effect Modifier

extension View {
    /// Apply frosted glass effect (Liquid Glass style)
    func glassBackground(cornerRadius: CGFloat = PulsyncRadius.lg) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .elevation(PulsyncElevation.level2)
    }

    /// Apply floating glass button style
    func glassButton() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .elevation(PulsyncElevation.level2)
    }
}

// MARK: - Text Readability

extension View {
    /// Add text shadow for readability over images
    func textReadability() -> some View {
        self.shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    /// Add stronger shadow for high contrast readability
    func textReadabilityStrong() -> some View {
        self.shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Action Button Style

/// Standard style for floating action buttons (like, comment, share)
struct ActionButtonStyle: ButtonStyle {
    let isActive: Bool
    let activeColor: Color
    let size: CGFloat

    init(
        isActive: Bool = false,
        activeColor: Color = PulsyncColors.primary,
        size: CGFloat = PulsyncSize.TouchTarget.recommended
    ) {
        self.isActive = isActive
        self.activeColor = activeColor
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(isActive ? activeColor.opacity(0.3) : Color.clear)
                    )
            )
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.Animation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Primary Button Style

/// Primary brand button style
struct PrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool

    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pulsyncLabel)
            .foregroundColor(.white)
            .padding(.horizontal, PulsyncSpacing.ml)
            .padding(.vertical, PulsyncSpacing.sm)
            .background(
                Capsule()
                    .fill(PulsyncColors.primary)
            )
            .opacity(isLoading ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// Secondary outline button style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.pulsyncLabel)
            .foregroundColor(PulsyncColors.textPrimary)
            .padding(.horizontal, PulsyncSpacing.ml)
            .padding(.vertical, PulsyncSpacing.sm)
            .background(
                Capsule()
                    .strokeBorder(PulsyncColors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == ActionButtonStyle {
    static func action(
        isActive: Bool = false,
        activeColor: Color = PulsyncColors.primary,
        size: CGFloat = PulsyncSize.TouchTarget.recommended
    ) -> ActionButtonStyle {
        ActionButtonStyle(isActive: isActive, activeColor: activeColor, size: size)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }

    static func primary(isLoading: Bool) -> PrimaryButtonStyle {
        PrimaryButtonStyle(isLoading: isLoading)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle {
        SecondaryButtonStyle()
    }
}

// MARK: - SF Symbols Mapping

/// Centralized SF Symbol names for consistency
enum PulsyncIcons {
    // Navigation
    static let home = "house"
    static let homeFilled = "house.fill"
    static let discover = "safari"
    static let discoverFilled = "safari.fill"
    static let define = "scope"
    static let deliver = "checkmark.circle"
    static let deliverFilled = "checkmark.circle.fill"

    // Actions
    static let like = "heart"
    static let likeFilled = "heart.fill"
    static let comment = "bubble.right"
    static let commentFilled = "bubble.right.fill"
    static let share = "square.and.arrow.up"
    static let bookmark = "bookmark"
    static let bookmarkFilled = "bookmark.fill"

    // User
    static let profile = "person.circle"
    static let profileFilled = "person.circle.fill"
    static let follow = "person.badge.plus"
    static let following = "person.badge.checkmark"

    // Utility
    static let settings = "gearshape"
    static let settingsFilled = "gearshape.fill"
    static let search = "magnifyingglass"
    static let close = "xmark"
    static let closeFilled = "xmark.circle.fill"
    static let more = "ellipsis"
    static let moreFilled = "ellipsis.circle.fill"
    static let back = "chevron.left"
    static let forward = "chevron.right"

    // Content
    static let play = "play.fill"
    static let pause = "pause.fill"
    static let music = "music.note"
    static let photo = "photo"
    static let video = "video"
    static let text = "text.alignleft"

    // Status
    static let checkmark = "checkmark"
    static let error = "exclamationmark.triangle"
    static let info = "info.circle"
    static let warning = "exclamationmark.circle"

    // AI/Chat
    static let ai = "sparkles"
    static let chat = "message"
    static let chatFilled = "message.fill"
    static let send = "paperplane.fill"
}

// MARK: - Accessibility

extension View {
    /// Apply minimum touch target size for accessibility
    func accessibleTouchTarget() -> some View {
        self.frame(
            minWidth: PulsyncSize.TouchTarget.minimum,
            minHeight: PulsyncSize.TouchTarget.minimum
        )
    }
}
